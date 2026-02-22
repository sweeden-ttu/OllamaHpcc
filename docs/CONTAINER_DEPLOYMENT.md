# CONTAINER_DEPLOYMENT.md - Podman Container Deployment Guide

This document provides comprehensive instructions for deploying and managing the OllamaHpcc and GlobPretect containers on HPCC RedRaider.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Container Overview](#container-overview)
3. [Deployment Steps](#deployment-steps)
4. [VPN Connection Management](#vpn-connection-management)
5. [Ollama Access](#ollama-access)
6. [Interoperability](#interoperability)
7. [Module Toolchain Integration](#module-toolchain-integration)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **OS**: Rocky Linux 10 (glibc)
- **Access**: HPCC RedRaider cluster login
- **Tools**: podman, slurm, ssh
- **GPU**: NVIDIA GPU (for Ollama containers)

### Environment Setup

```bash
# Load required modules on HPCC
module load gcc cuda podman

# Verify podman is available
podman --version

# Check GPU availability
nvidia-smi
```

---

## Container Overview

### Container Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                     HPCC RedRaider Cluster                             │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │          GlobPretect Container (SSH Tunnels)                    │  │
│  │  - Manages VPN connection                                       │  │
│  │  - Creates SSH tunnels to compute nodes                        │  │
│  │  - Port forwarding: 55077, 66044                              │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                │                                        │
│                                ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │              OllamaHpcc Containers (GPU)                        │  │
│  │  ┌──────────┐ ┌──────────┐                                     │  │
│  │  │ granite4 │ │ qwen-coder│                                     │  │
│  │  │  :55077  │ │  :66044  │                                     │  │
│  │  └──────────┘ └──────────┘                                     │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

### Container Definitions

| Container | Base Image | Port | Model | Purpose |
|-----------|------------|------|-------|---------|
| ollama-granite4 | slurm-openssh-container | **55077** | granite4 | Agentic tasks |
| ollama-qwen | slurm-openssh-container | **66044** | qwen2.5-coder | Code generation |
| globpretect | slurm-openssh-container | 22 | - | VPN/Tunnels |

---

## Deployment Steps

### Step 1: Connect to HPCC

```bash
# Connect to HPCC login node
ssh -i ~/projects/GlobPretect/id_ed25519_sweeden sweeden@login.hpcc.ttu.edu
```

### Step 2: Load Required Modules

```bash
# Load GCC, CUDA, and Podman
module load gcc cuda podman

# Verify GPU availability
nvidia-smi
```

### Step 3: Create Persistent Volumes

```bash
# Create volumes for persistent storage
podman volume create ollama-granite4
podman volume create ollama-deepseek
podman volume create ollama-qwen
podman volume create ollama-codellama
podman volume create ssh-keys

# List volumes
podman volume ls
```

### Step 4: Deploy GlobPretect Container (First!)

```bash
# Deploy GlobPretect container for SSH tunnels
podman run -d \
  --name globpretect \
  -p 22:22 \
  -v ssh-keys:/root/.ssh \
  -v /home/sdw3098/projects:/projects \
  -e SSH_PORT=22 \
  -e TUNNEL_MODE=true \
  docker.io/autosubmit/slurm-openssh-container:latest \
  /usr/sbin/sshd -D -e
```

### Step 5: Deploy Ollama Containers

```bash
# Deploy granite4 (Agentic tasks) on port 55077
podman run -d \
  --name ollama-granite4 \
  -p 55077:55077 \
  -v ollama-granite4:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:55077 \
  quay.io/ollama/ollama serve

# Pull the model
podman exec ollama-granite4 ollama pull granite4

# Deploy qwen-coder (Code generation) on port 66044
podman run -d \
  --name ollama-qwen \
  -p 66044:66044 \
  -v ollama-qwen:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:66044 \
  quay.io/ollama/ollama serve

podman exec ollama-qwen ollama pull qwen2.5-coder
```

### Step 5: Verify Containers

```bash
# Check container status
podman ps

# Test Ollama endpoints
curl http://localhost:55077/api/tags
curl http://localhost:66044/api/tags
```

---

## VPN Connection Management

### Understanding VPN vs SSH Tunnels

```
┌────────────────────────────────────────────────────────────────────────┐
│                        VPN Connection Options                          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Option 1: Traditional VPN (GlobPretect)                             │
│  ┌──────────────┐   ┌─────────────┐    ┌──────────────────┐        │
│  │ MacBook      │──▶│ GlobPretect │───▶│  HPCC Login Node │        │
│  │  Laptop      │   │   VPN      │    │                  │        │
│  └──────────────┘   └─────────────┘    └──────────────────┘        │
│                           │                                            │
│                           ▼                                            │
│                      Direct access to internal network                 │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Option 2: SSH Tunnels (Recommended for Ollama)                      │
│  ┌──────────────┐   ┌─────────────┐    ┌──────────────────┐        │
│  │Rocky Linux   │──▶│ SSH Tunnel  │───▶│ HPCC Compute Node│        │
│  │  Desktop     │   │             │    │  (Ollama Port)   │        │
│  └──────────────┘   └─────────────┘    └──────────────────┘        │
│                           │                                            │
│                           ▼                                            │
│                  Port forwarding to localhost                          │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Starting VPN (Traditional)

```bash
# Activate GlobPretect VPN
# This provides access to HPCC internal network

# Using the GlobPretect GUI or CLI
# See ~/projects/GlobPretect/docs/ for details

# Verify VPN is active
ip addr | grep -E "(tun|tap)"
ping -c 1 login.hpcc.ttu.edu
```

### Starting SSH Tunnels (Recommended for Ollama)

```bash
# Create SSH tunnel from local machine
# This forwards Ollama ports through SSH

ssh -L 55077:localhost:55077 \
    -L 66044:localhost:66044 \
    -i ~/projects/GlobPretect/id_ed25519_sweeden \
    sweeden@login.hpcc.ttu.edu -N

# Or use the GlobPretect tunnel script
~/projects/GlobPretect/scripts/start-tunnels.sh
```

### Stopping Connections

```bash
# Stop SSH tunnel
# Press Ctrl+C in the terminal running the tunnel

# Or find and kill the process
pkill -f "ssh.*-L.*55077"

# Disconnect VPN
# Use GlobPretect GUI or CLI to disconnect
```

---

## Ollama Access

### Accessing Ollama from Local Machine

Once VPN or SSH tunnel is active:

```bash
# granite4 (Agentic tasks) - Port 55077
curl http://localhost:55077/api/tags
curl -X POST http://localhost:55077/api/generate \
  -d '{"model": "granite4", "prompt": "Hello"}'

# qwen-coder (Code generation) - Port 66044
curl http://localhost:66044/api/tags
curl -X POST http://localhost:66044/api/generate \
  -d '{"model": "qwen2.5-coder", "prompt": "Write a Python function"}'
```

### Python Client Access

```python
# Using OllamaHpcc client library
from ollamahpcc import OllamaClient

# Connect to deployed models
granite = OllamaClient("granite4", port=55077)
qwen = OllamaClient("qwen2.5-coder", port=66044)

# Generate response
response = granite.generate("Your prompt here")
print(response)
```

### LangChain Integration

```python
from langchain_community.llms import Ollama
from langchain.schema import HumanMessage

# Deployed model endpoints
models = {
    "granite4": "http://localhost:55077",
    "qwen-coder": "http://localhost:66044"
}

# Use a specific model
llm = Ollama(model="granite4", base_url=models["granite4"])
response = llm.invoke([HumanMessage(content="Your prompt")])
```

---

## Interoperability

### How OllamaHpcc and GlobPretect Work Together

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Interoperability Flow                            │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  1. GlobPretect establishes network connectivity                      │
│     - Provides VPN or SSH tunnel to HPCC                               │
│     - Maps remote ports to localhost                                   │
│                                                                        │
│  2. OllamaHpcc provides LLM inference                                  │
│     - Runs on HPCC GPU nodes                                          │
│     - Exposes API on fixed ports                                      │
│                                                                        │
│  3. Local client connects via localhost                                │
│     - Thinks it's connecting to localhost                             │
│     - Traffic forwarded through VPN/tunnel                            │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Container Communication

```bash
# From GlobPretect container to Ollama containers
podman exec globpretect curl http://ollama-granite4:55077/api/tags
podman exec globpretect curl http://ollama-qwen:66044/api/tags

# From Ollama container to GlobPretect
podman exec ollama-granite4 ping -c 1 globpretect

# Network inspection
podman network ls
podman network inspect podman
```

### Shared Filesystem

```bash
# Share project files between containers
podman run -v /home/sdw3098/projects:/projects ...

# Access from any container
podman exec ollama-granite4 ls /projects
podman exec globpretect ls /projects
```

---

## Module Toolchain Integration

### Overview

The module-toolchain system manages development environments and provides:
- **Server Libraries**: OllamaHpcc for LLM inference
- **Client Libraries**: GlobPretect for VPN/tunnel management
- **Container Definitions**: Unified container configurations

### Using Module Toolchain for Ollama

```bash
# Source the module toolchain
source ~/module-toolchain/module.sh

# Check system info
module system

# The toolchain can detect HPCC and load appropriate modules
python3 -c "
from module_toolchain import EnvironmentManager
em = EnvironmentManager()
print(f'On HPCC: {em.is_on_hpcc()}')
print(f'Available modules: {em.get_available_modules()}')
"
```

### Client Library Setup

```bash
# Install GlobPretect client library
cd ~/projects/GlobPretect
pip install -e .

# Install OllamaHpcc client library
cd ~/projects/OllamaHpcc
pip install -e .
```

### Using Both Libraries Together

```python
"""
Example: Using both GlobPretect and OllamaHpcc together
"""

from globpretect import TunnelManager
from ollamahpcc import OllamaClient

# 1. Establish connection (if not already connected)
tunnel_mgr = TunnelManager()
tunnel_mgr.start_tunnels(
    ports=[55077, 55088, 66044, 66033],
    hpcc_host="login.hpcc.ttu.edu"
)

# 2. Use Ollama models
client = OllamaClient("granite4", port=55077)
response = client.generate("Your prompt")

# 3. Cleanup when done
tunnel_mgr.stop_tunnels()
```

### Container Definition Integration

The module-toolchain now includes container definitions for:

```json
{
  "ollama-granite4": {
    "port": 55077,
    "models": ["granite4"],
    "purpose": "Agentic task processing"
  },
  "ollama-deepseek": {
    "port": 55088,
    "models": ["deepseek-r1"],
    "purpose": "Reasoning"
  },
  "ollama-qwen": {
    "port": 66044,
    "models": ["qwen2.5-coder"],
    "purpose": "Code generation"
  },
  "globpretect": {
    "port": 22,
    "purpose": "VPN/Tunnels"
  }
}
```

---

## Troubleshooting

### Container Issues

```bash
# Check container status
podman ps -a

# View container logs
podman logs ollama-granite4
podman logs globpretect

# Restart container
podman restart ollama-granite4

# Remove and recreate container
podman rm -f ollama-granite4
podman run -d ... ollama-granite4 ...
```

### Network Issues

```bash
# Check port bindings
ss -tlnp | grep -E "(55077|55088|66044|66033)"

# Test connectivity
curl -v http://localhost:55077/api/tags

# Check firewall
firewall-cmd --list-all
```

### GPU Issues

```bash
# Check GPU availability
nvidia-smi

# Verify CUDA in container
podman exec ollama-granite4 nvidia-smi

# Check CUDA errors
podman logs ollama-granite4 | grep -i cuda
```

### SSH Tunnel Issues

```bash
# Test SSH connection
ssh -v -i ~/projects/GlobPretect/id_ed25519_sweeden sweeden@login.hpcc.ttu.edu

# Check tunnel process
ps aux | grep ssh

# Kill stale tunnels
pkill -f "ssh.*-L"
```

### VPN Issues

```bash
# Check GlobPretect status
systemctl status globpretect

# Check network interfaces
ip addr

# Restart VPN
# See GlobPretect documentation
```

---

## Quick Reference

### Deployment Commands

```bash
# Full deployment script
cat > deploy-containers.sh << 'EOF'
#!/bin/bash
module load gcc cuda podman

# Start GlobPretect first
podman run -d --name globpretect \
  -p 22:22 -v ssh-keys:/root/.ssh \
  docker.io/autosubmit/slurm-openssh-container:latest \
  /usr/sbin/sshd -D

# Start Ollama containers
for port in 55077 66044; do
  podman run -d --name ollama-$port \
    -p $port:$port \
    -v ollama-$port:/root/.ollama \
    -e OLLAMA_HOST=0.0.0.0:$port \
    quay.io/ollama/ollama serve
done
EOF

chmod +x deploy-containers.sh
```

### Connection Checklist

- [ ] Connected to HPCC login node
- [ ] Loaded modules: `module load gcc cuda podman`
- [ ] GPUs available: `nvidia-smi`
- [ ] GlobPretect container running
- [ ] Ollama containers running
- [ ] VPN active OR SSH tunnel established
- [ ] Ports accessible locally: `curl localhost:55077/api/tags`

### Port Reference

| Port | Service | Model | Local URL |
|------|---------|-------|-----------|
| 55077 | Ollama API | granite4 | http://localhost:55077 |
| 55088 | Ollama API | deepseek-r1 | http://localhost:55088 |
| 66044 | Ollama API | qwen2.5-coder | http://localhost:66044 |
| 66033 | Ollama API | codellama | http://localhost:66033 |

---

## References

- [Autosubmit Container](https://hub.docker.com/r/autosubmit/slurm-openssh-container)
- [Ollama Documentation](https://github.com/ollama/ollama)
- [HPCC User Guide](https://www.hpcc.ttu.edu/)
- [module-toolchain](../module-toolchain/README.md)
