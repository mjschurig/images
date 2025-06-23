#!/bin/bash

set -e

echo "🚀 Starting deal.II Development Environment"

# Activate conda environment
source /opt/conda/etc/profile.d/conda.sh
conda activate dealii-dev

# Ensure deal.II environment is properly set
export DEAL_II_DIR=/usr/local
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# Create Jupyter config directory if it doesn't exist
mkdir -p /home/dealii/.jupyter

# Generate secure token if not provided
if [ -z "$JUPYTER_TOKEN" ]; then
    JUPYTER_TOKEN=$(python -c "import secrets; print(secrets.token_urlsafe(32))")
    export JUPYTER_TOKEN
fi

# Verify deal.II installation
echo "🔍 Verifying deal.II installation..."
if [ -f "/usr/local/share/deal.II/VERSION" ]; then
    echo "✅ deal.II version: $(cat /usr/local/share/deal.II/VERSION)"
else
    echo "⚠️  deal.II version file not found, but installation directory exists"
fi

# Test C++ kernel availability
echo "🔍 Checking C++ kernel..."
jupyter kernelspec list | grep -q "xcpp" && echo "✅ C++ kernel (xeus-cling) available" || echo "⚠️  C++ kernel not found"

# Display connection information
echo ""
echo "📊 Environment Ready!"
echo "🌐 Jupyter Lab will be available at:"
echo "   http://localhost:8888"
echo "   Token: $JUPYTER_TOKEN"
echo ""
echo "📁 Workspace: /workspace"
echo "🔧 deal.II: $DEAL_II_DIR"
echo "👤 Running as user: $(whoami)"
echo ""

# Handle different startup modes
if [ "$1" = "bash" ] || [ "$1" = "shell" ]; then
    echo "🐚 Starting interactive shell..."
    exec /bin/bash
elif [ "$1" = "help" ] || [ "$1" = "--help" ]; then
    echo "Usage: docker run [OPTIONS] dealii-lab [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  (default)    Start Jupyter Lab server"
    echo "  bash|shell   Start interactive bash shell"
    echo "  help         Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  JUPYTER_TOKEN    Custom token for Jupyter Lab (auto-generated if not set)"
    echo "  JUPYTER_PORT     Port for Jupyter Lab (default: 8888)"
    echo ""
    echo "Examples:"
    echo "  docker run -p 8888:8888 dealii-lab"
    echo "  docker run -p 8888:8888 -e JUPYTER_TOKEN=mytoken dealii-lab"
    echo "  docker run -it dealii-lab bash"
    exit 0
else
    # Start Jupyter Lab (default behavior)
    echo "🎯 Starting Jupyter Lab..."
    exec jupyter lab \
        --ip=0.0.0.0 \
        --port=${JUPYTER_PORT:-8888} \
        --no-browser \
        --allow-root \
        --token="$JUPYTER_TOKEN" \
        --ServerApp.terminado_settings='{"shell_command": ["/bin/bash"]}' \
        --ServerApp.allow_origin='*' \
        --ServerApp.disable_check_xsrf=True \
        --config=/home/dealii/.jupyter/jupyter_lab_config.py 