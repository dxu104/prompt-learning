import argparse
import json
import os
import socket
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import pandas as pd
from swebench.harness.utils import load_swebench_dataset
from swebench.harness.test_spec.test_spec import make_test_spec
from swebench.harness.docker_build import (
    build_env_images,
    build_container,
    setup_logger,
    close_logger,
)
from swebench.harness.docker_utils import cleanup_container
import docker
import random

sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from cline_helpers import run_cline_for_instance
from container_helpers import docker_image_exists
from constants import CLINE_REPO_PATH, MATERIALIZED_REPOS_PATH


class ImageNotFoundError(Exception):
    """Raised when a Docker image is not found."""
    pass

cline_repo = Path(CLINE_REPO_PATH)
workspaces_root = Path(MATERIALIZED_REPOS_PATH)


def act_one(instance: dict, idx: int, ruleset: str) -> tuple[str, Path]:
    """
    Allocates ports for the Cline server, runs Cline for one instance of SWE Bench, and returns the path to the patch Cline generated.
    
    Raises:
        ImageNotFoundError: If the Docker image for this instance does not exist.
    """
    instance_id = instance["instance_id"]
    image_tag = make_test_spec(instance).instance_image_key

    # Check if Docker image exists before proceeding
    if not docker_image_exists(image_tag):
        print(f"[SKIP] Docker image not found for instance {instance_id}: {image_tag}")
        raise ImageNotFoundError(f"Docker image not found: {image_tag}")

    # unique ports per job (avoid clashes)
    base = 27000 + idx * 10
    proto_port = base + 1
    hostbridge_port = base + 2

    ruleset = ""

    res = run_cline_for_instance(
        instance_id=instance_id,
        image_tag=image_tag,
        cline_repo=cline_repo,
        workspaces_root=workspaces_root,
        task_text=instance["problem_statement"],
        host="127.0.0.1",
        proto_port=proto_port,
        hostbridge_port=hostbridge_port,
        mode="act",
        wait_seconds=300,
        ruleset_text=ruleset,
    )
    return instance_id, Path(res["predictions_path"])  # type: ignore


def run_act(
    run_id: str,
    dataset_name: str = "SWE-bench/SWE-bench_Lite",
    instance_ids: list[str] | None = None,
    ruleset: str = "",
    workers: int = 16,
    count: int | None = None,  # number of instances to run
) -> pd.DataFrame:
    """
    Runs Cline Act Mode on a dataset.

    Args:
        run_id: The ID of the run. You can view the results of the run in the logs directory. Make sure that the run_id is unique - otherwise, you will reuse the results of the previous run, instead of creating a new one.
        dataset_name: The name of the dataset to run Cline on.
        instance_ids: The IDs of the instances to run Cline on. If you don't want to run Cline on specific instances, you can set the instance_ids to None.
        ruleset: The ruleset to use for Cline.
        workers: The level of concurrency you want to use for Cline runs. Configure this relative to your machine's capabilities and your LLM rate limits.
        count: The number of instances to run Cline on. This is useful if you want to run Cline on a random subset of the instances in the dataset.

    This function will trigger Cline runs in parallel.
    It then uses the SWE Bench evaluator to run unit tests for each row of the dataset, testing Cline's generated patches.

    Returns:
        A pandas DataFrame with the results of the run.
    """
    dataset = load_swebench_dataset(dataset_name, "test", instance_ids)
    if not dataset:
        print("No instances found.")
        return

    # Select the instances to run Cline on
    predictions_by_id: dict[str, Path] = {}
    if count:
        dataset = random.sample(dataset, count)
        selected_ids = [inst["instance_id"] for inst in dataset]
    elif instance_ids:
        dataset = [inst for inst in dataset if inst["instance_id"] in instance_ids]
        selected_ids = instance_ids
    else:
        selected_ids = [inst["instance_id"] for inst in dataset]

    # Run Cline ACT across instances in parallel -> collect predictions
    skipped_instances = []
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futures = {
            ex.submit(act_one, inst, i, ruleset): inst for i, inst in enumerate(dataset)
        }
        for f in as_completed(futures):
            inst = futures[f]
            try:
                iid, p = f.result()
                predictions_by_id[iid] = p
            except ImageNotFoundError as e:
                skipped_instances.append(inst["instance_id"])
                print(f"[SKIP] Skipping instance {inst['instance_id']}: {e}")
            except Exception as e:
                print(f"[ERROR] Failed to process instance {inst['instance_id']}: {e}")
                skipped_instances.append(inst["instance_id"])
    
    if skipped_instances:
        print(f"\n[INFO] Skipped {len(skipped_instances)} instances due to missing Docker images:")
        for iid in skipped_instances:
            print(f"  - {iid}")
        print(f"[INFO] Proceeding with {len(predictions_by_id)} instances that have Docker images.\n")
    
    # If all instances were skipped, return empty DataFrame
    if not predictions_by_id:
        print("[WARNING] All instances were skipped due to missing Docker images. Returning empty results.")
        return pd.DataFrame(columns=[
            "instance_id", "problem_statement", "ground_truth_patch", 
            "test_patch", "coding_agent_patch", "pass_or_fail"
        ])

    # Combine predictions into one JSONL
    combined_preds = Path(os.getenv("TMPDIR", "/tmp")).joinpath(
        f"cline_preds_{run_id}.jsonl"
    )
    with combined_preds.open("w", encoding="utf-8") as out:
        for p in predictions_by_id.values():
            content = Path(p).read_text(encoding="utf-8")
            out.write(content)
            if not content.endswith("\n"):
                out.write("\n")

    subprocess.run(
        [
            "/opt/anaconda3/envs/cline/bin/python3",
            "-m",
            "pip",
            "install",
            "--upgrade",
            "swebench",
            "requests",
        ]
    )

    # Run official evaluator
    cmd = [
        sys.executable,
        "-m",
        "swebench.harness.run_evaluation",
        "--dataset_name",
        dataset_name,
        "--split",
        "test",
        "--predictions_path",
        str(combined_preds),
        "--run_id",
        run_id,
        "--namespace",
        "none",
        "--max_workers",
        str(workers),
    ]
    # Restrict evaluation strictly to the selected subset
    if selected_ids:
        cmd += ["--instance_ids", *selected_ids]
    subprocess.run(cmd, check=True)

    by_id = {inst["instance_id"]: inst for inst in dataset}
    rows: list[dict] = []
    # Only process instances that were successfully processed (not skipped)
    # Only include instances that have predictions (i.e., were not skipped)
    processed_ids = [iid for iid in selected_ids if iid in predictions_by_id]
    for iid in processed_ids:
        if iid not in by_id:
            continue
        inst = by_id[iid]
        cline_patch = ""
        pred_path = predictions_by_id.get(iid)
        if pred_path and pred_path.exists():
            try:
                line = pred_path.read_text(encoding="utf-8").splitlines()[0]
                obj = json.loads(line)
                cline_patch = obj.get("model_patch", "")
            except Exception:
                cline_patch = ""
        report_path = Path("logs").joinpath(
            "run_evaluation", run_id, "cline", iid, "report.json"
        )
        result = "fail"
        if report_path.exists():
            data = json.loads(report_path.read_text(encoding="utf-8"))
            resolved = bool((data.get(iid) or {}).get("resolved"))
            result = "pass" if resolved else "fail"
        rows.append(
            {
                "instance_id": iid,
                "problem_statement": inst.get("problem_statement", ""),
                "ground_truth_patch": inst.get("patch", ""),
                "test_patch": inst.get("test_patch", ""),
                "coding_agent_patch": cline_patch,
                "pass_or_fail": result,
            }
        )
    df = pd.DataFrame(rows)
    return df


if __name__ == "__main__":
    # Example usage
    rows = run_act(
        run_id="act_sympy_14308",
        # count=1,
        instance_ids=["sympy__sympy-14308"],
    )
    rows.to_csv("14308.csv", index=False)
