#!/bin/bash
set -e

echo "🐍 Conway Server Container Setup Starting..."
echo "=============================================="

# Update package list and install system dependencies
echo "📦 Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y wget curl build-essential

# Install Miniconda if not already present
if [ ! -d "/home/vscode/miniconda3" ]; then
    echo "🐍 Installing Miniconda..."
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p /home/vscode/miniconda3
    rm /tmp/miniconda.sh
    echo "✅ Miniconda installed"
else
    echo "✅ Miniconda already installed"
fi

# Add conda to PATH and initialize
export PATH="/home/vscode/miniconda3/bin:$PATH"
eval "$(/home/vscode/miniconda3/bin/conda shell.bash hook)"

# Initialize conda for bash
echo "🔧 Initializing conda..."
/home/vscode/miniconda3/bin/conda init bash

# Create or update conda environment
CONDA_ENV="conway-cuda"
if ! /home/vscode/miniconda3/bin/conda info --envs | grep -q "$CONDA_ENV"; then
    echo "🚀 Creating conda environment: $CONDA_ENV"
    /home/vscode/miniconda3/bin/conda create -n "$CONDA_ENV" python=3.11 -y
else
    echo "✅ Conda environment '$CONDA_ENV' already exists"
fi

# Activate environment and install packages
echo "📦 Installing Python packages..."
eval "$(/home/vscode/miniconda3/bin/conda shell.bash hook)"
conda activate "$CONDA_ENV"

# Install core packages via conda (better CUDA integration)
conda install -c conda-forge numba numpy scipy -y

# Install additional packages via pip
pip install websockets

# Install CuPy if CUDA is available
if command -v nvidia-smi &> /dev/null; then
    echo "🎮 NVIDIA GPU detected, installing CuPy..."
    pip install cupy-cuda12x
else
    echo "ℹ️  No GPU detected, skipping CuPy installation"
fi

# Install project requirements if available
if [ -f "/workspaces/conway-server/requirements.txt" ]; then
    echo "📋 Installing project requirements..."
    pip install -r /workspaces/conway-server/requirements.txt
else
    echo "ℹ️  No requirements.txt found, skipping"
fi

# Set up conda activation in bashrc
echo "🔧 Configuring shell environment..."
if ! grep -q "conda activate $CONDA_ENV" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Auto-activate Conway conda environment" >> ~/.bashrc
    echo "eval \"\$(/home/vscode/miniconda3/bin/conda shell.bash hook)\"" >> ~/.bashrc
    echo "conda activate $CONDA_ENV" >> ~/.bashrc
fi

# Test the installation
echo "🧪 Testing installation..."
python -c "import numpy; print(f'✅ NumPy {numpy.__version__}')" || echo "❌ NumPy failed"
python -c "import scipy; print(f'✅ SciPy {scipy.__version__}')" || echo "❌ SciPy failed"
python -c "import numba; print(f'✅ Numba {numba.__version__}')" || echo "❌ Numba failed"

# Test CUDA if available
if command -v nvidia-smi &> /dev/null; then
    python -c "
try:
    from numba import cuda
    print(f'✅ Numba CUDA support: {len(cuda.gpus.lst) if hasattr(cuda.gpus, \"lst\") else \"Unknown\"} devices')
except Exception as e:
    print(f'⚠️  Numba CUDA: {e}')
" || echo "ℹ️  CUDA test skipped"

    python -c "
try:
    import cupy as cp
    print(f'✅ CuPy {cp.__version__}')
except ImportError:
    print('ℹ️  CuPy not available')
except Exception as e:
    print(f'⚠️  CuPy: {e}')
" || echo "ℹ️  CuPy test skipped"
fi

echo ""
echo "🎉 Conway Server Container Setup Complete!"
echo "=========================================="
echo "🐍 Conda environment: $CONDA_ENV"
echo "📍 Working directory: /workspaces/conway-server"
echo "💡 To activate: conda activate $CONDA_ENV"
echo "🚀 To start server: python server.py --dev"
echo ""

# Keep the container running
echo "⏳ Container ready, keeping alive..."
exec sleep infinity 