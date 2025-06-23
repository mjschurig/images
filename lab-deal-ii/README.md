# deal.II Development Environment

A complete, containerized development environment for [deal.II](https://dealii.org/) finite element computations with Jupyter Lab integration.

## 🚀 Features

- **Complete deal.II Installation**: Latest deal.II with PETSc and p4est support
- **Jupyter Lab Environment**: Interactive development with C++ and Python kernels
- **Scientific Stack**: NumPy, SciPy, Matplotlib, VTK, and more
- **C++ Development**: Full C++ toolchain with CMake, GCC, and development libraries
- **Visualization Tools**: PyVista, Mayavi, and matplotlib for scientific visualization
- **MPI Support**: OpenMPI for parallel computations
- **Security**: Runs as non-root user with configurable authentication

## 📦 What's Included

| Component | Version | Purpose |
|-----------|---------|---------|
| deal.II | Latest | Finite element library |
| Ubuntu | 22.04 | Base operating system |
| Python | 3.9 | Scientific computing |
| CMake | 3.23.5 | Build system |
| GCC | Latest | C++ compiler |
| OpenMPI | Latest | Parallel computing |
| Jupyter Lab | Latest | Interactive development |
| xeus-cling | Latest | C++ kernel for Jupyter |

## 🏁 Quick Start

### Prerequisites

- Docker installed on your system
- At least 4GB RAM available
- Port 8888 available (or configure a different port)

### Basic Usage

1. **Run the container**:
   ```bash
   docker run -p 8888:8888 -v $(pwd):/workspace dealii-lab
   ```

2. **Access Jupyter Lab**:
   - Open your browser to `http://localhost:8888`
   - Use the token displayed in the terminal output

3. **Start developing**:
   - Create new notebooks with Python or C++ kernels
   - Access your files from the `/workspace` directory

## 📖 Usage Examples

### Basic Jupyter Lab Server

```bash
# Run with default settings
docker run -p 8888:8888 -v $(pwd):/workspace dealii-lab

# Run with custom token
docker run -p 8888:8888 -e JUPYTER_TOKEN=mytoken -v $(pwd):/workspace dealii-lab

# Run on different port
docker run -p 9999:9999 -e JUPYTER_PORT=9999 -v $(pwd):/workspace dealii-lab
```

### Interactive Shell Access

```bash
# Start interactive bash shell
docker run -it -v $(pwd):/workspace dealii-lab bash

# Run shell with mounted source code
docker run -it -v /path/to/your/project:/workspace dealii-lab shell
```

### Development Workflow

```bash
# Terminal 1: Start Jupyter Lab
docker run -p 8888:8888 -v $(pwd):/workspace --name dealii-dev dealii-lab

# Terminal 2: Access running container for command line work
docker exec -it dealii-dev bash

# Terminal 3: Monitor logs
docker logs -f dealii-dev
```

### With Docker Compose

Create a `docker-compose.yml`:

```yaml
version: '3.8'
services:
  dealii-lab:
    image: dealii-lab
    ports:
      - "8888:8888"
    volumes:
      - ./workspace:/workspace
    environment:
      - JUPYTER_TOKEN=dev-token
    restart: unless-stopped
```

Run with:
```bash
docker-compose up -d
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `JUPYTER_TOKEN` | auto-generated | Authentication token for Jupyter Lab |
| `JUPYTER_PORT` | 8888 | Port for Jupyter Lab server |
| `DEAL_II_DIR` | /usr/local | deal.II installation directory |

### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `./workspace` | `/workspace` | Your project files |
| `./config` | `/home/dealii/.jupyter` | Jupyter configuration (optional) |

### Port Mapping

| Container Port | Purpose |
|----------------|---------|
| 8888 | Jupyter Lab web interface |

## 🛠️ Development Guide

### Creating a deal.II Project

1. **Start the container**:
   ```bash
   docker run -it -v $(pwd):/workspace dealii-lab bash
   ```

2. **Create a simple deal.II program**:
   ```cpp
   // hello_dealii.cpp
   #include <deal.II/base/logstream.h>
   #include <deal.II/grid/tria.h>
   #include <deal.II/grid/grid_generator.h>
   
   using namespace dealii;
   
   int main() {
       Triangulation<2> triangulation;
       GridGenerator::hyper_cube(triangulation);
       triangulation.refine_global(4);
       
       std::cout << "Number of active cells: "
                 << triangulation.n_active_cells()
                 << std::endl;
       return 0;
   }
   ```

3. **Create CMakeLists.txt**:
   ```cmake
   cmake_minimum_required(VERSION 3.23)
   project(hello_dealii)
   
   find_package(deal.II 9.0 REQUIRED)
   deal_ii_initialize_cached_variables()
   
   add_executable(hello_dealii hello_dealii.cpp)
   deal_ii_setup_target(hello_dealii)
   ```

4. **Build and run**:
   ```bash
   mkdir build && cd build
   cmake ..
   make
   ./hello_dealii
   ```

### Using Jupyter Notebooks

1. **Python with deal.II**:
   ```python
   # Install Python bindings if needed
   import subprocess
   import sys
   
   # Use matplotlib for visualization
   import matplotlib.pyplot as plt
   import numpy as np
   
   # Your deal.II Python code here
   ```

2. **C++ Kernel**:
   ```cpp
   #include <deal.II/grid/tria.h>
   #include <deal.II/grid/grid_generator.h>
   #include <iostream>
   
   using namespace dealii;
   
   Triangulation<2> tria;
   GridGenerator::hyper_cube(tria);
   tria.refine_global(2);
   
   std::cout << "Cells: " << tria.n_active_cells() << std::endl;
   ```

## 🏗️ Building from Source

### Prerequisites

- Docker installed
- At least 8GB RAM for building
- Stable internet connection

### Build Steps

```bash
# Clone the repository
git clone <repository-url>
cd lab-deal-ii

# Build the image
docker build -t dealii-lab .

# Run the built image
docker run -p 8888:8888 -v $(pwd):/workspace dealii-lab
```

### Build Arguments

```bash
# Build with specific versions
docker build \
  --build-arg UBUNTU_VERSION=22.04 \
  --build-arg CMAKE_VERSION=3.23.5 \
  -t dealii-lab .
```

## 📊 Performance Considerations

### Resource Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 2GB | 8GB+ |
| CPU | 2 cores | 4+ cores |
| Storage | 5GB | 10GB+ |

### Optimization Tips

1. **Memory**: Increase Docker memory limit for large computations
2. **CPU**: Use `--cpus` flag to allocate more cores
3. **Storage**: Use bind mounts instead of volumes for better I/O performance

```bash
# Optimized run command
docker run \
  --cpus="4.0" \
  --memory="8g" \
  --shm-size="2g" \
  -p 8888:8888 \
  -v $(pwd):/workspace \
  dealii-lab
```

## 🔍 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Check what's using port 8888
lsof -i :8888

# Use different port
docker run -p 9999:9999 -e JUPYTER_PORT=9999 dealii-lab
```

#### Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER ./workspace

# Or run with user mapping
docker run --user $(id -u):$(id -g) -v $(pwd):/workspace dealii-lab
```

#### Memory Issues
```bash
# Increase Docker memory limit
docker run --memory="8g" dealii-lab

# Monitor memory usage
docker stats
```

#### Container Won't Start
```bash
# Check container logs
docker logs <container-id>

# Run in interactive mode for debugging
docker run -it dealii-lab bash
```

### Health Check

The container includes a health check that verifies Jupyter Lab is running:

```bash
# Check container health
docker ps
# Look for (healthy) status

# Manual health check
docker exec <container-id> curl -f http://localhost:8888/api
```

## 🤝 Contributing

### Reporting Issues

1. Check existing issues first
2. Provide system information (Docker version, OS)
3. Include container logs
4. Describe expected vs actual behavior

### Development Setup

```bash
# Fork and clone
git clone <your-fork>
cd lab-deal-ii

# Make changes
# Test locally
docker build -t dealii-lab-dev .
docker run -it dealii-lab-dev bash

# Submit pull request
```

### Testing

```bash
# Run basic tests
docker run --rm dealii-lab help

# Test Jupyter startup
docker run -d -p 8888:8888 dealii-lab
curl -f http://localhost:8888/api

# Test deal.II installation
docker run --rm dealii-lab bash -c "ls -la /usr/local/share/deal.II/"
```

## 📝 License

This project is licensed under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- [deal.II Project](https://dealii.org/) for the excellent finite element library
- [candi](https://github.com/dealii/candi) for the installation scripts
- [Jupyter Project](https://jupyter.org/) for the interactive development environment

## 📞 Support

- 📖 [deal.II Documentation](https://dealii.org/developer/doxygen/deal.II/index.html)
- 💬 [deal.II Forum](https://groups.google.com/g/dealii)
- 🐛 [Report Issues](https://github.com/mjschurig/images/issues)

---

**Happy Computing with deal.II! 🧮✨** 