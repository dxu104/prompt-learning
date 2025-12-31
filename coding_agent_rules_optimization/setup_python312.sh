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
    echo "❌ Conda not found. Checking for alternative Python installations..."
    echo ""
    
    # Check if python3.12 is available (try multiple ways)
    PYTHON312=""
    if command -v python3.12 &> /dev/null; then
        PYTHON312="python3.12"
    elif [ -f "/usr/bin/python3.12" ]; then
        PYTHON312="/usr/bin/python3.12"
    elif [ -f "/usr/local/bin/python3.12" ]; then
        PYTHON312="/usr/local/bin/python3.12"
    fi
    
    if [ -n "$PYTHON312" ]; then
        echo "✅ Found python3.12 at: $PYTHON312"
        echo "   Version: $($PYTHON312 --version 2>&1)"
        echo ""
        ENV_NAME="prompt-learning-py312"
        ENV_PATH="$HOME/$ENV_NAME"
        
        echo "1. Creating virtual environment with Python 3.12..."
        $PYTHON312 -m venv "$ENV_PATH"
        
        echo ""
        echo "2. Activating environment..."
        source "$ENV_PATH/bin/activate"
        
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
        echo "  source $ENV_PATH/bin/activate"
        echo "  cd ~/prompt-learning/coding_agent_rules_optimization/cline_act_mode"
        echo "  python main.py"
        exit 0
    fi
    
    echo "❌ Python 3.12 not found. Please choose one of the following options:"
    echo ""
    echo "Option 1: Install Miniconda (recommended)"
    echo "  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    echo "  bash Miniconda3-latest-Linux-x86_64.sh"
    echo "  # Then re-run this script"
    echo ""
    echo "Option 2: Install Python 3.12 from source or package manager"
    echo "  # Ubuntu/Debian:"
    echo "  sudo apt update"
    echo "  sudo apt install software-properties-common"
    echo "  sudo add-apt-repository ppa:deadsnakes/ppa"
    echo "  sudo apt update"
    echo "  sudo apt install python3.12 python3.12-venv"
    echo "  # Then re-run this script"
    echo ""
    echo "Option 3: Use pyenv"
    echo "  curl https://pyenv.run | bash"
    echo "  export PATH=\"\$HOME/.pyenv/bin:\$PATH\""
    echo "  eval \"\$(pyenv init -)\""
    echo "  pyenv install 3.12.0"
    echo "  pyenv virtualenv 3.12.0 prompt-learning-py312"
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

