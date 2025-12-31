import pandas as pd
import asyncio
import sys
import os

# Add parent directory to path to import evals
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from evals import evaluate_results as async_evaluate_results


def evaluate_results(results: pd.DataFrame, model: str = "gpt-5") -> pd.DataFrame:
    """
    Synchronous wrapper for async evaluate_results function.
    """
    return asyncio.run(async_evaluate_results(results, model=model))

