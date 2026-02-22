# OllamaHpcc - Ollama on HPCC GPU Clusters

OllamaHpcc provides LLM inference on HPCC RedRaider GPU nodes using containerized Ollama servers with Slurm job scheduling.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Local Development Machine                     │
│                    (MacBook / Rocky Linux)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              GlobPretect VPN (SSH Tunnels)                       │
│              Port forwards to HPCC compute nodes                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  HPCC RedRaider Cluster                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  autosubmit/slurm-openssh-container                    │   │
│  │  (Slurm + SSH + Podman/Docker)                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│         ┌────────────────────┼────────────────────┐             │
│         ▼                    ▼                    ▼             │
│  ┌──────────┐         ┌──────────┐         ┌──────────┐      │
│  │ granite4 │         │deepseek-r1│         │qwen-coder│      │
│  │  55077   │         │  55088   │         │  66044   │      │
│  └──────────┘         └──────────┘         └──────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## Docker Base Image

This project uses `autosubmit/slurm-openssh-container` as the base Docker image.

### Image Details

- **Source**: [Docker Hub](https://hub.docker.com/r/autosubmit/slurm-openssh-container)
- **Maintainer**: Barcelona Supercomputing Center (BSC)
- **Purpose**: Single-container Slurm cluster for CI/CD testing
- **Size**: ~269 MB
- **Base**: Rocky Linux

### Why This Image?

1. **Slurm Integration**: Built-in Slurm client for job submission
2. **SSH Server**: Enables SSH tunnels for port forwarding
3. **Podman Support**: Works with Podman on HPCC
4. **Lightweight**: Minimal footprint compared to full Slurm cluster
5. **Active Maintenance**: Updated regularly by BSC

### Alternative Images

For reference, other Slurm Docker images:
- `giovtorres/slurm-docker-cluster` - Full Slurm cluster
- `pitt-crc/Slurm-Test-Environment` - Testing environment
- `schedmd/slurm` - Official Slurm containers

## Quick Start

### 1. Connect to HPCC

```bash
# Via GlobPretect VPN
ssh -i ~/projects/GlobPretect/id_ed25519_sweeden sweeden@login.hpcc.ttu.edu
```

### 2. Submit Ollama Job

```bash
cd ~/projects/OllamaHpcc

# Submit to matador partition (V100 GPUs)
./scripts/start-hpcc.sh matador 1 04:00:00 55077 granite4

# Submit to toreador partition (A100 GPUs)
./scripts/start-hpcc.sh toreador 2 08:00:00 66044 qwen2.5-coder
```

### 3. Create SSH Tunnel

```bash
# From local machine
ssh -L 55077:localhost:55077 -L 55088:localhost:55088 \
    -i ~/projects/GlobPretect/id_ed25519_sweeden \
    sweeden@login.hpcc.ttu.edu -N
```

### 4. Use Ollama

```bash
# Check available models
curl http://localhost:55077/api/tags

# Test inference
curl -X POST http://localhost:55077/api/generate \
    -d '{"model": "granite4", "prompt": "Hello"}'
```

## Fixed Ports

| Port  | Model        | Purpose      |
|-------|--------------|--------------|
| 55077 | granite4     | Agentic tasks|
| 55088 | deepseek-r1  | Reasoning    |
| 66044 | qwen2.5-coder| Coding       |
| 66033 | codellama    | Plain English|

## Project Structure

```
OllamaHpcc/
├── docs/
│   ├── AGENTS.md          # Multi-agent documentation
│   ├── CURSOR.md         # Cursor IDE setup
│   ├── GITHUB_AUTOMATION.md
│   ├── DOCKER.md         # Docker image details
│   └── setup/
│       └── MINICONDA.md  # Miniconda setup
├── scripts/
│   ├── start-hpcc.sh     # Submit job to HPCC
│   ├── start-local.sh   # Local containers
│   └── daily-github-sync.sh
└── src/python/
    └── ollamahpcc/
        └── __init__.py   # Python client
```

## Usage Examples

### Python Client

```python
from ollamahpcc import OllamaClient

# Connect to HPCC Ollama
client = OllamaClient("granite", port=55077)

# Generate response
response = client.generate("Explain quantum computing")
print(response)
```

### LangChain Integration

```python
from langchain_community.llms import Ollama
from langchain.schema import HumanMessage

llm = Ollama(model="granite4", base_url="http://localhost:55077")
messages = [HumanMessage(content="What is 2+2?")]
response = llm.invoke(messages)
print(response)
```

## HPCC Partitions

### Matador (V100 GPUs)
- 1 GPU per node
- Max 4 hours
- For testing/development

### Toreador (A100 GPUs)
- 2 GPUs per node
- Max 8 hours
- For production workloads

## Troubleshooting

### Job Not Starting
```bash
# Check job status
squeue -u $USER

# Check job output
cat ollama-granite4.o<job_id>
```

### Connection Issues
```bash
# Verify VPN is active
ping login.hpcc.ttu.edu

# Check port forwarding
netstat -an | grep 55077
```

### Container Issues
```bash
# Check container logs
podman logs ollama-granite4

# Restart container
podman restart ollama-granite4
```

## Resources

- [Autosubmit Documentation](https://autosubmit.readthedocs.io/)
- [HPCC User Guide](https://www.hpcc.ttu.edu/)
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Slurm Documentation](https://slurm.schedmd.com/)

## License

GPL-3.0 - See LICENSE file
