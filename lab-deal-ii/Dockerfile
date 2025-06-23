FROM ubuntu:20.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Create non-root user with static UID/GID
RUN groupadd -g 10001 dealii && \
    useradd -u 10000 -g dealii -m -s /bin/bash dealii

# Set up basic system and install dependencies in single layer
RUN apt-get update && apt-get install -y \
    # Basic build tools
    build-essential \
    gfortran \
    git \
    wget \
    curl \
    pkg-config \
    # MPI support
    libopenmpi-dev \
    openmpi-bin \
    openmpi-common \
    # Math libraries
    liblapack-dev \
    libblas-dev \
    libmetis-dev \
    libparmetis-dev \
    # Additional dependencies
    zlib1g-dev \
    libomp-dev \
    # Utilities
    vim \
    nano \
    htop \
    # For health checks
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Install CMake 3.23 (latest stable 3.23.x, minimum for trilinos)
RUN wget -qO- https://github.com/Kitware/CMake/releases/download/v3.23.5/cmake-3.23.5-linux-x86_64.tar.gz | tar -xzC /opt && \
    ln -sf /opt/cmake-3.23.5-linux-x86_64/bin/* /usr/local/bin/ && \
    rm -rf /tmp/*

# Install Miniconda
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda clean -a -y && \
    chown -R dealii:dealii $CONDA_DIR

# Copy dependency files first for better layer caching
COPY --chown=dealii:dealii environment.yml /tmp/environment.yml

# Create conda environment for deal.II development
RUN conda env create -f /tmp/environment.yml && \
    conda clean -a -y && \
    rm /tmp/environment.yml

# Install deal.II using candi
WORKDIR /tmp/candi-install
RUN git clone https://github.com/dealii/candi.git && \
    cd candi && \
    # Create custom configuration for deal.II + PETSc + p4est (disable trilinos)
    cp candi.cfg candi.cfg.backup && \
    sed -i 's/#PACKAGES="${PACKAGES} petsc"/PACKAGES="${PACKAGES} petsc"/' candi.cfg && \
    sed -i 's/#PACKAGES="${PACKAGES} p4est"/PACKAGES="${PACKAGES} p4est"/' candi.cfg && \
    # Explicitly disable trilinos to avoid CMake conflicts
    sed -i 's/PACKAGES="${PACKAGES} trilinos"/#PACKAGES="${PACKAGES} trilinos"/' candi.cfg && \
    # Verify CMake version before building
    cmake --version && \
    # Run installation
    ./candi.sh --yes --prefix=/usr/local && \
    # Clean up build files and sources to reduce image size
    rm -rf /tmp/candi-install && \
    ldconfig

# Set up environment variables
ENV DEAL_II_DIR=/usr/local
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# Create workspace directory and set permissions
WORKDIR /workspace
RUN chown dealii:dealii /workspace

# Create Jupyter config directory and set permissions
RUN mkdir -p /home/dealii/.jupyter && \
    chown -R dealii:dealii /home/dealii/.jupyter

# Copy configuration files
COPY --chown=dealii:dealii jupyter_config.py /home/dealii/.jupyter/jupyter_lab_config.py
COPY --chown=dealii:dealii entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER dealii:dealii

# Activate conda environment by default
RUN echo "source activate dealii-dev" >> /home/dealii/.bashrc
ENV PATH=/opt/conda/envs/dealii-dev/bin:$PATH

# Expose Jupyter port
EXPOSE 8888

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8888/api || exit 1

# Add metadata
LABEL maintainer="deal.II Development Team"
LABEL version="1.0.0"
LABEL description="Complete deal.II development environment with Jupyter Lab"
LABEL org.opencontainers.image.source="https://github.com/mjschurig/images"

# Default command
CMD ["/entrypoint.sh"] 