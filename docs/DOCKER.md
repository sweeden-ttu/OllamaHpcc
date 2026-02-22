# DOCKER.md - OllamaHpcc Docker Configuration

This document details the Docker container configuration for running Ollama on HPCC using the Slurm-openssh-container base image.

## Base Image: autosubmit/slurm-openssh-container

### Overview

- **Image**: `docker.io/autosubmit/slurm-openssh-container:latest`
- **Alternative Tag**: `autosubmit/slurm-openssh-container:25-05-0-1`
- **Registry**: Docker Hub
- **Size**: ~269 MB
- **OS Base**: Rocky Linux

### Source Information

- **Maintainer**: Barcelona Supercomputing Center (BSC-ES)
- **Website**: https://www.bsc.es/earth-sciences
- **GitHub**: https://github.com/BSC-ES/autosubmit
- **Purpose**: Single-container Slurm cluster for CI/CD testing

### Image Capabilities

1. **Slurm Client**: Built-in Slurm commands (sbatch, squeue, scancel)
2. **SSH Server**: Openssh-server for remote access
3. **Munge**: Authentication service for Slurm
4. **Podman/Docker**: Container runtime support
5. **MongoDB**: Database for Autosubmit workflow manager

### Why Use This Image?

```
┌─────────────────────────────────────────────────────────────┐
│                    Traditional HPC                          │
│  ┌──────────────┐    ┌──────────────┐    ┌─────────────┐ │
│  │  Login Node  │───▶│ Compute Node │───▶│   GPU Node  │ │
│  └──────────────┘    └──────────────┘    └─────────────┘ │
│         │                                       │          │
│      SSH Tunnel                              Container     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              With slurm-openssh-container                  │
│  ┌──────────────┐    ┌──────────────────────────────────┐  │
│  │  Login Node  │───▶│  Container (Slurm + SSH + Ollama)│  │
│  └──────────────┘    └──────────────────────────────────┘  │
│         │                         │                          │
│      SSH Tunnel              Port Forward                   │
└─────────────────────────────────────────────────────────────┘
```

## Dockerfiles

### Option 1: Direct Container (Recommended)

Use the base image directly with Ollama:

```bash
# Pull base image
podman pull docker.io/autosubmit/slurm-openssh-container:latest

# Run Ollama container
podman run -d --name ollama-granite4 \
  -p 55077:55077 \
  -v ollama:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:55077 \
  quay.io/ollama/ollama serve
```

### Option 2: Custom Dockerfile

Create a custom image with Ollama pre-installed:

```dockerfile
# Dockerfile.ollama
FROM docker.io/autosubmit/slurm-openssh-container:latest

USER root
RUN dnf install -y ollama && dnf clean all

USER slurm
CMD ["ollama", "serve"]
```

Build and push:
```bash
podman build -f Dockerfile.ollama -t ollama-hpcc:latest .
podman push ollama-hpcc:latest
```

### Option 3: Slurm Job with Container

Submit Slurm job with containerized Ollama:

```bash
#!/bin/bash
#SBATCH -J ollama-granite4
#SBATCH -p matador
#SBATCH --gpus-per-node=1
#SBATCH -t 04:00:00

# Load required modules
module load gcc cuda podman

# Pull Ollama image
podman pull quay.io/ollama/ollama:latest

# Run Ollama container
podman run -d --name ollama-granite4 \
  -p 55077:55077 \
  -v ollama:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:55077 \
  quay.io/ollama/ollama serve

# Pull model
podman exec ollama-granite4 ollama pull granite4

echo "Ollama started on port 55077"
```

## Port Configuration

### Fixed Ports

| Port  | Service    | Model        | Purpose        |
|-------|------------|--------------|----------------|
| 55077 | Ollama API | granite4     | Agentic tasks  |
| 55088 | Ollama API | deepseek-r1  | Reasoning      |
| 66044 | Ollama API | qwen2.5-coder| Coding        |
| 66033 | Ollama API | codellama    | Plain English  |

### Network Configuration

```bash
# Host network mode (recommended for GPU access)
podman run --network host ...

# Or port mapping (use same port on host and container)
podman run -p 55077:55077 ...
```

## Volume Mounts

### Required Volumes

```bash
# Ollama models storage
-v ollama:/root/.ollama

# Project files (optional)
-v $HOME/projects:/home/sdw3098/projects

# SSH keys (for GitHub)
-v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK
```

### Persistent Storage

```bash
# Create persistent volume
podman volume create ollama-models

# Use volume
podman run -v ollama-models:/root/.ollama ...
```

## Environment Variables

```bash
# Set environment variables (use fixed ports: 55077 or 66044)
-e OLLAMA_HOST=0.0.0.0:55077
-e OLLAMA_MODELS=/root/.ollama/models
-e OLLAMA_NUM_PARALLEL=4
-e OLLAMA_MAX_LOADED_MODELS=2
```

## Health Checks

```bash
# Check if Ollama is running
curl http://localhost:55077/api/tags

# Check container health
podman healthcheck run ollama-granite4

# View logs
podman logs -f ollama-granite4
```

## Resource Limits

### GPU Allocation

```bash
# Request GPU
#SBATCH --gpus-per-node=1

# Or for multi-GPU
#SBATCH --gpus-per-node=2
```

### Memory Limits

```bash
# Add to podman run
--memory=16g
--memory-swap=32g
```

### CPU Limits

```bash
# Limit CPUs
--cpus=8
--cpu-shares=2048
```

## Security Considerations

### Non-Root User

```dockerfile
FROM docker.io/autosubmit/slurm-openssh-container:latest

# Create non-root user
RUN useradd -m -s /bin/bash ollamauser

# Switch to non-root
USER ollamauser
WORKDIR /home/ollamauser

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

CMD ["ollama", "serve"]
```

### Read-Only Root Filesystem

```bash
podman run --read-only ...
```

## Troubleshooting

### Container Won't Start

```bash
# Check podman logs
podman logs ollama-granite4

# Check system logs
journalctl -xe

# Verify GPU is available
nvidia-smi
```

### Network Issues

```bash
# Check port is listening
ss -tlnp | grep 55077

# Test connectivity
curl -v http://localhost:55077/api/tags
```

### Permission Denied

```bash
# Fix volume permissions
podman unshare chown -R 1000:1000 /path/to/volume

# Run with privileged mode (not recommended)
podman run --privileged ...
```

## Alternative Images

### Similar Projects

| Image | Purpose | Size |
|-------|---------|------|
| `giovtorres/slurm-docker-cluster` | Full Slurm cluster | ~1 GB |
| `pitt-crc/Slurm-Test-Environment` | Testing environment | ~500 MB |
| `schedmd/slurm-ubuntu` | Official Slurm | ~300 MB |

### Custom Base

If you need a smaller image, consider:

```dockerfile
FROM rockylinux:9

RUN dnf install -y \
    openssh-server \
    slurm \
    munge \
    podman \
    && dnf clean all

CMD ["/usr/sbin/sshd", "-D"]
```

## References

- [Autosubmit GitHub](https://github.com/BSC-ES/autosubmit)
- [Docker Hub - slurm-openssh-container](https://hub.docker.com/r/autosubmit/slurm-openssh-container)
- [Slurm Documentation](https://slurm.schedmd.com/)
- [Ollama GitHub](https://github.com/ollama/ollama)
- [Podman Documentation](https://docs.podman.io/)
