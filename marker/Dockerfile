# Multi-stage build for Marker PDF to Markdown converter with Streamlit app
FROM python:3.11-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Poetry
RUN pip install --no-cache-dir poetry==1.8.4

# Set Poetry configuration
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VENV_IN_PROJECT=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

# Clone marker repository
RUN git clone https://github.com/VikParuchuri/marker.git . && \
    git checkout master

# Install dependencies
RUN poetry install --only=main && \
    poetry run pip install streamlit streamlit-ace && \
    rm -rf $POETRY_CACHE_DIR

# Production stage
FROM python:3.11-slim AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user with static UID/GID
RUN groupadd -g 10001 -S markergroup && \
    useradd -u 10000 -S markeruser -G markergroup && \
    mkdir -p /app /data /output && \
    chown -R markeruser:markergroup /app /data /output

WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder --chown=markeruser:markergroup /app/.venv /app/.venv

# Copy application code
COPY --from=builder --chown=markeruser:markergroup /app /app

# Make sure we use venv
ENV PATH="/app/.venv/bin:$PATH"

# Set environment variables for marker
ENV TORCH_DEVICE=cpu \
    PYTHONPATH=/app \
    STREAMLIT_SERVER_PORT=8501 \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

# Create directories for data persistence
VOLUME ["/data", "/output"]

# Switch to non-root user
USER markeruser:markergroup

# Expose Streamlit port
EXPOSE 8501

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Add metadata
LABEL maintainer="marker-docker@example.com" \
      version="1.0.0" \
      description="Marker PDF to Markdown converter with Streamlit interface" \
      org.opencontainers.image.source="https://github.com/VikParuchuri/marker" \
      org.opencontainers.image.title="Marker PDF Converter" \
      org.opencontainers.image.description="Convert PDF to markdown with high accuracy using Streamlit interface"

# Start Streamlit app
CMD ["streamlit", "run", "marker_app.py", "--server.port=8501", "--server.address=0.0.0.0"] 