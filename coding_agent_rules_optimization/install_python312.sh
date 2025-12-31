#!/bin/bash
# Install Python 3.12 on Ubuntu/Debian
# Run with: bash install_python312.sh

set -e

echo "=========================================="
echo "Installing Python 3.12 on Ubuntu/Debian"
echo "=========================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "This script needs sudo privileges to install Python 3.12"
    echo "Please run: sudo bash install_python312.sh"
    exit 1
fi

echo "1. Updating package list..."
apt update

echo ""
echo "2. Installing prerequisites..."
apt install -y software-properties-common

echo ""
echo "3. Adding deadsnakes PPA (provides Python 3.12)..."
add-apt-repository -y ppa:deadsnakes/ppa

echo ""
echo "4. Updating package list again..."
apt update

echo ""
echo "5. Installing Python 3.12 and venv..."
apt install -y python3.12 python3.12-venv python3.12-dev python3.12-distutils

echo ""
echo "6. Installing pip for Python 3.12..."
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12

echo ""
echo "=========================================="
echo "✅ Python 3.12 installed successfully!"
echo "=========================================="
echo ""
echo "Verify installation:"
echo "  python3.12 --version"
echo ""
echo "Now you can run:"
echo "  cd ~/prompt-learning/coding_agent_rules_optimization"
echo "  ./setup_python312.sh"

