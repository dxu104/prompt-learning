#!/bin/bash
# Setup Python 3.12 environment for prompt-learning
# Run this script on your server: bash setup_python312.sh

set -e

echo "=========================================="
echo "Setting up Python 3.12 environment"
echo "=========================================="
echo ""

# Try to find conda
CONDA_PATH=""
if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
    CONDA_PATH="/opt/anaconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    CONDA_PATH="$HOME/anaconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    CONDA_PATH="$HOME/miniconda3/etc/profile.d/conda.sh"
elif command -v conda &> /dev/null; then
    # Try to find conda from PATH
    CONDA_BASE=$(conda info --base 2>/dev/null || echo "")
    if [ -n "$CONDA_BASE" ] && [ -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
        CONDA_PATH="$CONDA_BASE/etc/profile.d/conda.sh"
    fi
fi

if [ -z "$CONDA_PATH" ]; then
    echo "❌ Conda not found. Trying alternative methods..."
    echo ""
    echo "Option 1: Install using pyenv (recommended if conda unavailable)"
    echo "  curl https://pyenv.run | bash"
    echo "  export PATH=\"\$HOME/.pyenv/bin:\$PATH\""
    echo "  eval \"\$(pyenv init -)\""
    echo "  pyenv install 3.12.0"
    echo "  pyenv virtualenv 3.12.0 prompt-learning-py312"
    echo ""
    echo "Option 2: Install Miniconda first"
    echo "  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    echo "  bash Miniconda3-latest-Linux-x86_64.sh"
    echo ""
    echo "Option 3: Use system Python 3.12 (if available)"
    echo "  python3.12 -m venv ~/prompt-learning-py312"
    echo "  source ~/prompt-learning-py312/bin/activate"
    echo "  pip install -e ~/prompt-learning"
    exit 1
fi

echo "✅ Found conda at: $CONDA_PATH"
source "$CONDA_PATH"

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

