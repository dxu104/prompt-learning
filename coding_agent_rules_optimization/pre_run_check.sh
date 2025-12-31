#!/bin/bash
# Pre-run checklist script

echo "=========================================="
echo "Pre-run Checklist for Harness"
echo "=========================================="
echo ""

ERRORS=0

# 1. Check Node.js
echo "1. Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js: $NODE_VERSION"
else
    echo "   ❌ Node.js not installed"
    ERRORS=$((ERRORS + 1))
fi

# 2. Check npx and tsx
echo ""
echo "2. Checking npx and tsx..."
if command -v npx &> /dev/null; then
    echo "   ✅ npx installed"
    if npx tsx --version &> /dev/null; then
        echo "   ✅ tsx available"
    else
        echo "   ❌ tsx not available, run: npm install -g tsx"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ npx not installed"
    ERRORS=$((ERRORS + 1))
fi

# 3. Check grpcurl
echo ""
echo "3. Checking grpcurl..."
if command -v grpcurl &> /dev/null; then
    echo "   ✅ grpcurl installed"
else
    echo "   ❌ grpcurl not installed"
    echo "   Install: brew install grpcurl (macOS) or apt-get install grpcurl (Linux)"
    ERRORS=$((ERRORS + 1))
fi

# 4. Check ripgrep
echo ""
echo "4. Checking ripgrep..."
if command -v rg &> /dev/null; then
    echo "   ✅ ripgrep installed"
else
    echo "   ❌ ripgrep not installed"
    echo "   Install: brew install ripgrep (macOS) or apt-get install ripgrep (Linux)"
    ERRORS=$((ERRORS + 1))
fi

# 5. Check Python
echo ""
echo "5. Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "   ✅ Python: $PYTHON_VERSION"
    
    # Check if version >= 3.10
    PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
    PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 10 ]; then
        echo "   ✅ Python version >= 3.10"
    else
        echo "   ⚠️  Python version < 3.10, recommended to upgrade"
    fi
else
    echo "   ❌ Python3 not installed"
    ERRORS=$((ERRORS + 1))
fi

# 6. Check Python dependencies
echo ""
echo "6. Checking Python dependencies..."
python3 -c "import swebench" 2>/dev/null && echo "   ✅ swebench" || { echo "   ❌ swebench not installed"; ERRORS=$((ERRORS + 1)); }
python3 -c "import pandas" 2>/dev/null && echo "   ✅ pandas" || { echo "   ❌ pandas not installed"; ERRORS=$((ERRORS + 1)); }
python3 -c "import datasets" 2>/dev/null && echo "   ✅ datasets" || { echo "   ❌ datasets not installed"; ERRORS=$((ERRORS + 1)); }

# 7. Check environment variables
echo ""
echo "7. Checking environment variables..."
if [ -n "$OPENAI_API_KEY" ]; then
    echo "   ✅ OPENAI_API_KEY is set"
else
    echo "   ❌ OPENAI_API_KEY not set"
    echo "   Set: export OPENAI_API_KEY='your-api-key'"
    ERRORS=$((ERRORS + 1))
fi

# 8. Check Cline configuration
echo ""
echo "8. Checking Cline configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from constants import CLINE_REPO_PATH, MATERIALIZED_REPOS_PATH
    from pathlib import Path
    
    cline_path = Path(CLINE_REPO_PATH)
    workspaces_path = Path(MATERIALIZED_REPOS_PATH)
    
    print(f'   CLINE_REPO_PATH: {cline_path}')
    if cline_path.exists():
        print(f'   ✅ Cline path exists')
        
        # Check compiled files
        core_js = cline_path / 'dist-standalone/cline-core.js'
        descriptor = cline_path / 'dist-standalone/proto/descriptor_set.pb'
        
        if core_js.exists():
            print(f'   ✅ cline-core.js exists')
        else:
            print(f'   ❌ cline-core.js not found, run: npm run compile-standalone')
            sys.exit(1)
            
        if descriptor.exists():
            print(f'   ✅ descriptor_set.pb exists')
        else:
            print(f'   ❌ descriptor_set.pb not found, run: npm run compile-standalone')
            sys.exit(1)
    else:
        print(f'   ❌ Cline path does not exist')
        sys.exit(1)
    
    print(f'   MATERIALIZED_REPOS_PATH: {workspaces_path}')
    if workspaces_path.exists():
        print(f'   ✅ Workspaces path exists')
    else:
        print(f'   ⚠️  Workspaces path does not exist, will be created automatically')
    
    # Check ripgrep symlink
    rg_link = cline_path / 'dist-standalone/rg'
    if rg_link.exists() || rg_link.is_symlink():
        print(f'   ✅ ripgrep symlink exists')
    else:
        print(f'   ⚠️  ripgrep symlink does not exist')
        print(f'   Create: cd {cline_path} && ln -sf \"\$(command -v rg)\" dist-standalone/rg')
    
except Exception as e:
    print(f'   ❌ Configuration check failed: {e}')
    sys.exit(1)
" || ERRORS=$((ERRORS + 1))

# 9. Check Docker
echo ""
echo "9. Checking Docker..."
if command -v docker &> /dev/null; then
    if docker ps &> /dev/null; then
        echo "   ✅ Docker is running"
        
        # Check images
        ENV_IMAGES=$(docker images | grep '^sweb.env' | wc -l)
        EVAL_IMAGES=$(docker images | grep '^sweb.eval' | wc -l)
        echo "   📊 Environment images: $ENV_IMAGES"
        echo "   📊 Evaluation images: $EVAL_IMAGES"
        
        if [ "$ENV_IMAGES" -lt 40 ]; then
            echo "   ⚠️  Few environment images (expected ~51)"
        fi
        
        if [ "$EVAL_IMAGES" -lt 250 ]; then
            echo "   ⚠️  Few evaluation images (expected ~300)"
            echo "   💡 Some image build failures are normal"
            echo "   ✅ Code automatically skips instances with missing images, skipped instances will be shown during runtime"
        fi
    else
        echo "   ❌ Docker is not running"
        echo "   Start: Docker Desktop (macOS) or sudo systemctl start docker (Linux)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ Docker not installed"
    ERRORS=$((ERRORS + 1))
fi

# 10. Check result directories
echo ""
echo "10. Checking result directories..."
cd "$SCRIPT_DIR/cline_act_mode" 2>/dev/null || cd "$SCRIPT_DIR"
for dir in act_results act_rulesets ui_messages logs; do
    if [ -d "$dir" ]; then
        echo "   ✅ $dir/ exists"
    else
        echo "   ⚠️  $dir/ does not exist, will be created automatically"
        mkdir -p "$dir"
    fi
done

# Summary
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed! Ready to run"
    echo ""
    echo "Run command:"
    echo "  cd cline_act_mode"
    echo "  python main.py"
else
    echo "❌ Found $ERRORS issues, please fix them first"
    echo ""
    echo "Common solutions:"
    echo "  1. Install missing tools (see hints above)"
    echo "  2. Set OPENAI_API_KEY: export OPENAI_API_KEY='your-key'"
    echo "  3. Compile Cline: cd ~/cline && npm run compile-standalone"
    echo "  4. Configure paths in constants.py"
fi
echo "=========================================="

exit $ERRORS

