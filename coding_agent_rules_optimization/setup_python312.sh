#!/bin/bash
# Setup Python 3.12 environment for prompt-learning
# Run this script on your server: bash setup_python312.sh

set -e

echo "=========================================="
echo "Setting up Python 3.12 environment"
echo "=========================================="
echo ""

# Check if conda is available
if [ ! -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
    echo "❌ Conda not found at /opt/anaconda3"
    echo "Please adjust the path or install Anaconda/Miniconda first"
    exit 1
fi

# Source conda
source /opt/anaconda3/etc/profile.d/conda.sh

ENV_NAME="prompt-learning-py312"

echo "1. Creating conda environment with Python 3.12..."
conda create -n $ENV_NAME python=3.12 -y

echo ""
echo "2. Activating environment..."
conda activate $ENV_NAME

echo ""
echo "3. Upgrading pip..."
pip install --upgrade pip

echo ""
echo "4. Installing required packages..."
pip install \
    arize-phoenix \
    arize-phoenix-evals \
    arize-phoenix-client \
    swebench \
    pandas \
    datasets \
    tiktoken \
    openai \
    arize-toolkit \
    scikit-learn \
    nest-asyncio \
    click \
    requests \
    pydantic \
    httpx \
    rich

echo ""
echo "5. Installing project in editable mode..."
cd ~/prompt-learning
pip install -e .

echo ""
echo "=========================================="
echo "✅ Setup complete!"
echo "=========================================="
echo ""
echo "To use this environment:"
echo "  source /opt/anaconda3/etc/profile.d/conda.sh"
echo "  conda activate $ENV_NAME"
echo "  cd ~/prompt-learning/coding_agent_rules_optimization/cline_act_mode"
echo "  python main.py"
echo ""
echo "Or add to your ~/.bashrc or ~/.zshrc:"
echo "  source /opt/anaconda3/etc/profile.d/conda.sh"
echo "  conda activate $ENV_NAME"

