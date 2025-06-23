#!/bin/bash

# deal.II Development Environment Build Script
# Usage: ./build.sh [build|run|shell|help]

set -e

IMAGE_NAME="dealii-lab"
IMAGE_TAG="latest"
CONTAINER_NAME="dealii-dev"
JUPYTER_PORT="8888"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=====================================\033[0m"
    echo -e "${BLUE}  deal.II Development Environment\033[0m"
    echo -e "${BLUE}=====================================\033[0m"
}

print_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build     Build the Docker image"
    echo "  run       Run Jupyter Lab server (default)"
    echo "  shell     Start interactive shell"
    echo "  stop      Stop running container"
    echo "  clean     Remove container and image"
    echo "  help      Show this help message"
    echo ""
    echo "Options:"
    echo "  --port PORT     Port for Jupyter Lab (default: 8888)"
    echo "  --name NAME     Container name (default: dealii-dev)"
    echo "  --workspace DIR Local workspace directory (default: current directory)"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 run --port 9999"
    echo "  $0 shell --workspace /path/to/project"
}

build_image() {
    echo -e "${YELLOW}🏗️  Building deal.II development environment...${NC}"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed or not available${NC}"
        exit 1
    fi
    
    # Build the image
    docker build \
        --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
        --progress=plain \
        .
    
    echo -e "${GREEN}✅ Build completed successfully!${NC}"
    echo -e "${BLUE}Image: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
}

run_jupyter() {
    local workspace_dir=${1:-$(pwd)}
    local port=${2:-$JUPYTER_PORT}
    local name=${3:-$CONTAINER_NAME}
    
    echo -e "${YELLOW}🚀 Starting deal.II Jupyter Lab environment...${NC}"
    
    # Stop existing container if running
    if docker ps -q -f name="$name" | grep -q .; then
        echo -e "${YELLOW}⚠️  Stopping existing container...${NC}"
        docker stop "$name" > /dev/null
        docker rm "$name" > /dev/null
    fi
    
    # Check if port is available
    if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}❌ Port $port is already in use${NC}"
        echo "Please choose a different port with --port option"
        exit 1
    fi
    
    # Run the container
    docker run \
        --name "$name" \
        --rm \
        -p "$port:8888" \
        -v "$workspace_dir:/workspace" \
        -e JUPYTER_PORT=8888 \
        "$IMAGE_NAME:$IMAGE_TAG"
}

run_shell() {
    local workspace_dir=${1:-$(pwd)}
    local name="${2:-$CONTAINER_NAME}-shell"
    
    echo -e "${YELLOW}🐚 Starting interactive shell...${NC}"
    
    docker run \
        --name "$name" \
        --rm \
        -it \
        -v "$workspace_dir:/workspace" \
        "$IMAGE_NAME:$IMAGE_TAG" \
        bash
}

stop_container() {
    local name=${1:-$CONTAINER_NAME}
    
    if docker ps -q -f name="$name" | grep -q .; then
        echo -e "${YELLOW}⏹️  Stopping container $name...${NC}"
        docker stop "$name"
        echo -e "${GREEN}✅ Container stopped${NC}"
    else
        echo -e "${BLUE}ℹ️  No running container named $name${NC}"
    fi
}

clean_all() {
    local name=${1:-$CONTAINER_NAME}
    
    echo -e "${YELLOW}🧹 Cleaning up containers and images...${NC}"
    
    # Stop and remove container
    if docker ps -aq -f name="$name" | grep -q .; then
        docker stop "$name" 2>/dev/null || true
        docker rm "$name" 2>/dev/null || true
    fi
    
    # Remove image
    if docker images -q "$IMAGE_NAME:$IMAGE_TAG" | grep -q .; then
        docker rmi "$IMAGE_NAME:$IMAGE_TAG"
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    else
        echo -e "${BLUE}ℹ️  No image to remove${NC}"
    fi
}

check_requirements() {
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is required but not installed${NC}"
        echo "Please install Docker from https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker daemon is not running${NC}"
        echo "Please start Docker daemon"
        exit 1
    fi
    
    # Check available memory
    available_memory=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
    if [ "$available_memory" -lt 2000000000 ]; then  # 2GB in bytes
        echo -e "${YELLOW}⚠️  Warning: Less than 2GB memory available for Docker${NC}"
        echo "deal.II compilation requires significant memory"
    fi
}

# Parse command line arguments
COMMAND="run"
WORKSPACE_DIR=$(pwd)
PORT=$JUPYTER_PORT
NAME=$CONTAINER_NAME

while [[ $# -gt 0 ]]; do
    case $1 in
        build|run|shell|stop|clean|help)
            COMMAND=$1
            shift
            ;;
        --port)
            PORT=$2
            shift 2
            ;;
        --name)
            NAME=$2
            shift 2
            ;;
        --workspace)
            WORKSPACE_DIR=$2
            shift 2
            ;;
        -h|--help)
            COMMAND="help"
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Main execution
print_header

case $COMMAND in
    build)
        check_requirements
        build_image
        ;;
    run)
        check_requirements
        # Check if image exists
        if ! docker images -q "$IMAGE_NAME:$IMAGE_TAG" | grep -q .; then
            echo -e "${YELLOW}📦 Image not found, building first...${NC}"
            build_image
        fi
        run_jupyter "$WORKSPACE_DIR" "$PORT" "$NAME"
        ;;
    shell)
        check_requirements
        # Check if image exists
        if ! docker images -q "$IMAGE_NAME:$IMAGE_TAG" | grep -q .; then
            echo -e "${YELLOW}📦 Image not found, building first...${NC}"
            build_image
        fi
        run_shell "$WORKSPACE_DIR" "$NAME"
        ;;
    stop)
        stop_container "$NAME"
        ;;
    clean)
        clean_all "$NAME"
        ;;
    help)
        print_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        print_usage
        exit 1
        ;;
esac 