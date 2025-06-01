# Docker Images Repository

This repository contains Docker images that can be deployed using GitHub Actions.

## 📁 Available Images

- **marker**: PDF to Markdown converter with Streamlit interface

## 🚀 Deployment Pipeline

The deployment pipeline uses GitHub Actions to build and publish Docker images manually. You can choose which image to deploy and where to publish it.

### How to Deploy

1. Go to the **Actions** tab in your GitHub repository
2. Click on **Deploy Docker Image** workflow
3. Click **Run workflow**
4. Configure the deployment:
   - **Image name**: Select the folder name (e.g., `marker`)
   - **Registry**: Choose where to publish:
     - `ghcr.io` - GitHub Container Registry (default)
     - `docker.io` - Docker Hub
     - `both` - Publish to both registries

### 🔧 Setup Requirements

#### For GitHub Container Registry (ghcr.io)
No additional setup required - uses `GITHUB_TOKEN` automatically.

#### For Docker Hub (docker.io)
Add the following secrets to your repository:
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub password or access token

### 📋 Features

- ✅ Manual deployment trigger
- ✅ Choose specific image to deploy
- ✅ Support for multiple registries
- ✅ Multi-platform builds (linux/amd64, linux/arm64)
- ✅ Build caching for faster builds
- ✅ Artifact attestations for supply chain security
- ✅ Automatic validation of image directories
- ✅ Rich deployment summaries

### 🏷️ Image Tagging

Images are automatically tagged with:
- `latest` (for default branch)
- Branch name (for feature branches)
- Timestamp (YYYYMMDD-HHmmss)
- Git SHA with branch prefix

### 📊 Example Usage

After deployment, your images will be available at:

**GitHub Container Registry:**
```bash
docker pull ghcr.io/mjschurig/images/marker:latest
```

**Docker Hub:**
```bash
docker pull your-username/marker:latest
```

### 🛠️ Adding New Images

To add a new Docker image:

1. Create a new directory in the root with your image name
2. Add a `Dockerfile` in that directory
3. The image will automatically be available for deployment

### 🔍 Monitoring

Check the Actions tab for deployment status and logs. Each deployment includes:
- Build logs
- Push confirmation
- Deployment summary with tags and digest
- Artifact attestations (for ghcr.io)

---

Based on [GitHub's Docker publishing documentation](https://docs.github.com/en/actions/use-cases-and-examples/publishing-packages/publishing-docker-images). 