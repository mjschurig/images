# Marker PDF to Markdown Converter - Docker

This Docker container provides a Streamlit web interface for the [Marker](https://github.com/VikParuchuri/marker) PDF to Markdown converter, which converts PDF documents to markdown with high accuracy using deep learning models.

## Features

- **High Accuracy**: Converts PDF to markdown with superior accuracy compared to other tools
- **Streamlit Interface**: Easy-to-use web interface for interactive PDF conversion
- **Multi-format Support**: Supports PDF, images, PPTX, DOCX, XLSX, HTML, EPUB files
- **Table & Equation Support**: Properly formats tables and converts equations to LaTeX
- **Image Extraction**: Extracts and saves images from documents
- **Security**: Runs as non-root user with minimal attack surface
- **Production Ready**: Multi-stage build with optimized layers and health checks

## Quick Start

### Build the Image

```bash
docker build -t marker-streamlit .
```

building might take a while, use

```bash
docker build --progress=plain -t marker-streamlit .
```

for displaying progress.

### Run the Container

```bash
docker run -d \
  --name marker-app \
  -p 8501:8501 \
  -v $(pwd)/data:/data \
  -v $(pwd)/output:/output \
  marker-streamlit
```

### Access the Application

Open your browser and navigate to: `http://localhost:8501`

## Usage

### Basic Usage

1. **Upload PDF**: Use the Streamlit interface to upload your PDF file
2. **Configure Options**: Set conversion parameters (optional)
3. **Convert**: Click convert to process your document
4. **Download**: Download the generated markdown and extracted images

### Advanced Usage with Environment Variables

```bash
docker run -d \
  --name marker-app \
  -p 8501:8501 \
  -v $(pwd)/data:/data \
  -v $(pwd)/output:/output \
  -e TORCH_DEVICE=cuda \
  -e STREAMLIT_SERVER_PORT=8501 \
  marker-streamlit
```

### GPU Support

For GPU acceleration (requires NVIDIA Docker runtime):

```bash
docker run -d \
  --name marker-app \
  --gpus all \
  -p 8501:8501 \
  -v $(pwd)/data:/data \
  -v $(pwd)/output:/output \
  -e TORCH_DEVICE=cuda \
  marker-streamlit
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TORCH_DEVICE` | `cpu` | PyTorch device (cpu, cuda, mps) |
| `STREAMLIT_SERVER_PORT` | `8501` | Streamlit server port |
| `STREAMLIT_SERVER_ADDRESS` | `0.0.0.0` | Streamlit server address |
| `PYTHONPATH` | `/app` | Python path for marker modules |

### Volumes

| Path | Description |
|------|-------------|
| `/data` | Input directory for PDF files |
| `/output` | Output directory for converted files |

### Ports

| Port | Description |
|------|-------------|
| `8501` | Streamlit web interface |

## Docker Compose

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  marker:
    build: .
    ports:
      - "8501:8501"
    volumes:
      - ./data:/data
      - ./output:/output
    environment:
      - TORCH_DEVICE=cpu
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8501/_stcore/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

Run with:

```bash
docker-compose up -d
```

## Performance Considerations

### CPU vs GPU

- **CPU**: Works well for most documents, slower processing
- **GPU**: Significantly faster, requires NVIDIA GPU and Docker runtime
- **Memory**: Requires ~4GB RAM for optimal performance

### Optimization Tips

1. **Batch Processing**: Process multiple files together for better efficiency
2. **GPU Memory**: Monitor GPU memory usage with multiple workers
3. **File Size**: Large PDFs may require more processing time and memory

## Troubleshooting

### Common Issues

1. **Out of Memory**: Reduce batch size or use CPU instead of GPU
2. **Slow Processing**: Enable GPU support or increase container resources
3. **Permission Issues**: Ensure volumes have correct permissions (UID 10000)

### Health Check

The container includes a health check that monitors the Streamlit service:

```bash
# Check container health
docker ps

# View health check logs
docker inspect marker-app | grep Health -A 10
```

### Logs

View container logs:

```bash
# View real-time logs
docker logs -f marker-app

# View recent logs
docker logs --tail 100 marker-app
```

## Security

This Docker image follows security best practices:

- **Non-root User**: Runs as user `markeruser` (UID 10000)
- **Minimal Base**: Uses Python slim image
- **No Secrets**: No hardcoded secrets or credentials
- **Read-only**: Application files are owned by non-root user
- **Network**: Only exposes necessary port (8501)

## Development

### Building for Development

```bash
# Build with development dependencies
docker build --target builder -t marker-dev .

# Run development container
docker run -it --rm \
  -v $(pwd):/workspace \
  -p 8501:8501 \
  marker-dev bash
```

### Customization

To customize the Dockerfile:

1. Modify the `Dockerfile` following the best practices guide
2. Update environment variables as needed
3. Rebuild the image

## License

This Docker configuration is provided under the same license as the Marker project. Please refer to the [original Marker repository](https://github.com/VikParuchuri/marker) for licensing details.

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes following the Dockerfile best practices
4. Test your changes
5. Submit a pull request

## Support

For issues related to:
- **Marker functionality**: Visit the [Marker GitHub repository](https://github.com/VikParuchuri/marker)
- **Docker configuration**: Open an issue in this repository
- **Streamlit interface**: Check the [Streamlit documentation](https://docs.streamlit.io/)

## Acknowledgments

- [Marker](https://github.com/VikParuchuri/marker) by VikParuchuri for the excellent PDF conversion tool
- [Streamlit](https://streamlit.io/) for the web interface framework
- Docker community for containerization best practices