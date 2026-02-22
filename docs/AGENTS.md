# AGENTS.md - OllamaHpcc Multi-Agent Development Guide

This document provides guidance for autonomous agent systems working on OllamaHpcc - Ollama server and client libraries for HPCC GPU clusters.

## Project Overview

**OllamaHpcc** provides LLM inference on:
- Local development machines (MacBook/Rocky)
- HPCC RedRaider GPU nodes (matador/toreador)
- Via SSH tunnels through GlobPretect VPN

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent Coordinator                            │
└─────────────────────────────────────────────────────────────────┘
          │              │              │              │
    ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐
    │  Server    │  │  Client   │  │ LangChain │  │  Testing  │
    │  Agent     │  │  Agent    │  │  Agent    │  │  Agent    │
    └───────────┘  └───────────┘  └───────────┘  └───────────┘
```

## Agent Responsibilities

### Agent 1: Server Deployment
- **Goal**: Deploy Ollama on HPCC GPU nodes
- **Tasks**:
  1. Container image management
  2. Slurm job submission
  3. GPU resource allocation
  4. Model downloading

### Agent 2: Client Library
- **Goal**: Python client for Ollama
- **Tasks**:
  1. Connection management
  2. Model selection
  3. Streaming responses
  4. Error handling

### Agent 3: LangChain Integration
- **Goal**: LangChain/LangGraph/LangSmith integration
- **Tasks**:
  1. Ollama LLM wrapper
  2. Tool definitions
  3. Agent templates
  4. Tracing setup

### Agent 4: Testing & QA
- **Goal**: Comprehensive testing
- **Tasks**:
  1. Unit tests
  2. Integration tests
  3. Performance benchmarks
  4. Model evaluation

## Fixed Ports (VPN Required)

| Port | Service | Model | Purpose |
|------|---------|-------|---------|
| 55077 | Ollama | granite4 | Agentic tasks |
| 66044 | Ollama | qwen2.5-coder | Code generation |

## Container Base

**HPCC Interconnect**: `docker.io/autosubmit/slurm-openssh-container:latest`

```dockerfile
FROM docker.io/autosubmit/slurm-openssh-container:latest
RUN dnf install -y ollama
CMD ["ollama", "serve"]
```

## Slurm Job Templates

### Matador GPU (V100)
```bash
#!/bin/bash
#SBATCH -J ollama-granite4
#SBATCH -p matador
#SBATCH --gpus-per-node=1
#SBATCH -t 04:00:00

podman run -d -p 55077:55077 --name ollama-granite4 \
  -v ollama:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:55077 \
  quay.io/ollama/ollama serve
```

### Toreador GPU (A100)
```bash
#!/bin/bash
#SBATCH -J ollama-qwen
#SBATCH -p toreador
#SBATCH --gpus-per-node=2
#SBATCH -t 08:00:00

podman run -d -p 66044:66044 --name ollama-qwen \
  -v ollama:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:66044 \
  quay.io/ollama/ollama serve
```

## LangChain Integration

```python
from ollamahpcc import OllamaClient

# Create clients for different models
granite = OllamaClient("granite")
qwen = OllamaClient("qwen")
think = OllamaClient("think")

# Use with LangChain
from langchain.schema import HumanMessage
response = granite.llm.chat([HumanMessage(content="Hello")])
```

## File Structure

```
OllamaHpcc/
├── docs/
│   ├── CLAUDE.md
│   ├── AGENTS.md          # This file
│   └── SETUP/INSTALL.md
├── scripts/
│   ├── start-local.sh
│   ├── start-hpcc.sh
│   └── test-connection.sh
├── src/python/ollamahpcc/
│   ├── __init__.py
│   ├── server.py
│   ├── client.py
│   └── langchain.py
└── test/python/
    └── test_ollama.py
```

## Communication Protocol

Agents communicate via:
1. **Shared state**: JSON state files
2. **Environment variables**: PORTS, MODELS
3. **Log files**: Track operations

## Next Steps

1. Deploy Ollama to HPCC
2. Build client library
3. Integrate with LangChain
4. Add comprehensive tests
5. Benchmark model performance
