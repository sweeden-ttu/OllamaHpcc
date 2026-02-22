# CLAUDE.md - OllamaHpcc Development Guide

This document provides guidance for Claude AI when working on OllamaHpcc - Ollama server and client libraries for running LLM inference on RedRaider GPU clusters and local development.

## Project Overview

**OllamaHpcc** provides:
- Ollama server deployment on HPCC RedRaider GPU nodes
- Client libraries for LangChain, LangGraph, LangSmith integration
- VS Code and Cursor IDE integration with Ollama toolsets
- Multi-model management (granite4, deepseek-r1, qwen-coder, codellama)

## Fixed Ollama Ports (VPN Required)

**IMPORTANT**: Always use fixed ports 55077 or 66044. Never use default port 11434.

| Variable | Port | Model | Purpose |
|----------|------|-------|---------|
| GRANITE_URL | 55077 | granite4 | Stable general model |
| THINK_URL | 55088 | deepseek-r1 | Dynamic thinking/reasoning |
| QWEN_URL | 66044 | qwen-coder | Code generation |
| CODE_URL | 66033 | codellama | Generic coding |

## Container Base Image

**HPCC Interconnect**: `docker.io/autosubmit/slurm-openssh-container:latest`

This container provides SLURM/OpenSSH integration for HPCC connectivity.

```bash
# Pull base image
podman pull docker.io/autosubmit/slurm-openssh-container:latest

# Build Ollama on top
podman build -t ollama-hpcc:latest -f Dockerfile <<EOF
FROM docker.io/autosubmit/slurm-openssh-container:latest
RUN dnf install -y ollama && \
    ollama serve
CMD ["ollama", "serve"]
EOF
```

## musl vs glibc Builds

**IMPORTANT**: Different environments use different C libraries:

| Environment | C Library | Use For |
|------------|-----------|---------|
| HPCC RedRaider | glibc | musl cross-compilation, GPU builds |
| Rocky Linux 10 | glibc | Standard builds only |
| MacBook | libSystem | Native builds only |

**musl binary compilations ONLY work on HPCC cluster** because:
- HPCC runs Rocky Linux (glibc) which can cross-compile for musl targets
- musl is used by Alpine Linux containers
- MacBooks use BSD-based libSystem (incompatible)
- Rocky Linux 10 uses glibc (not musl-compatible)

**When to use musl builds**:
- Create Alpine Linux Docker images
- Ultra-lightweight containers
- Embedded systems

**Build on HPCC**:
```bash
# In Slurm job
module load gcc cuda

# Cross-compile for musl
CC=musl-gcc ./configure
make

# Or use Alpine container on HPCC
podman run -it alpine:latest musl-gcc -o output mycode.c
```

## Environments

### Environment 1: MacBook (owner@owner)
- **Host**: 192.168.0.14/24
- **Shell**: zsh
- **Container**: Podman/Colima
- **Models**: Local inference for development

### Environment 2: Rocky Linux 10 (sdw3098@quay)
- **Host**: 192.168.0.15/24
- **Shell**: bash
- **Container**: Podman (sudo)
- **Models**: Local inference for development

### Environment 3: HPCC RedRaider (sweeden@login.hpcc.ttu.edu)
- **Login**: login.hpcc.ttu.edu
- **GPU Nodes**: matador (V100), toreador (A100)
- **Partition**: matador for V100, toreador for A100

## HPCC Slurm Integration

### Interactive Session
```bash
# GPU node (V100)
srun -p matador --gpus-per-node=1 -t 02:00:00 --pty bash

# GPU node (A100)
srun -p toreador --gpus-per-node=2 -t 04:00:00 --pty bash
```

### Batch Job Script
```bash
#!/bin/bash
#SBATCH -J ollama-granite4
#SBATCH -o %x.o%j
#SBATCH -e %x.e%j
#SBATCH -p matador
#SBATCH --gpus-per-node=1
#SBATCH -t 04:00:00

module load gcc cuda podman

podman run -d --name ollama-granite4 \
  -p 55077:55077 \
  -v ollama:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:55077 \
  quay.io/ollama/ollama serve

podman exec ollama-granite4 ollama pull granite4
```

## Ollama Server Library

```python
# src/python/ollamahpcc/__init__.py
import os
import subprocess
import requests
from typing import Optional, List, Dict

class OllamaServer:
    """Manages Ollama server instances on HPCC or local."""
    
    PORTS = {
        "granite": 55077,
        "think": 55088,
        "qwen": 66044,
        "code": 66033
    }
    
    MODELS = {
        "granite": "granite4",
        "think": "deepseek-r1", 
        "qwen": "qwen2.5-coder",
        "code": "codellama"
    }
    
    def __init__(self, host: str = "localhost"):
        self.host = host
        self.base_url = f"http://{host}"
        
    def check_health(self, port: int) -> bool:
        """Check if Ollama is running on port."""
        try:
            resp = requests.get(f"{self.base_url}:{port}/api/tags", timeout=2)
            return resp.status_code == 200
        except:
            return False
        
    def start_local(self, model_type: str, container_name: str = None):
        """Start local Ollama container."""
        port = self.PORTS[model_type]
        model = self.MODELS[model_type]
        name = container_name or f"ollama-{model_type}"
        
        cmd = [
            "podman", "run", "-d",
            "--name", name,
            "-p", f"{port}:{port}",
            "-v", "ollama:/root/.ollama",
            "-e", f"OLLAMA_HOST=0.0.0.0:{port}",
            "quay.io/ollama/ollama", "serve"
        ]
        subprocess.run(cmd)
        
        # Pull model
        subprocess.run(["podman", "exec", name, "ollama", "pull", model])
        
    def generate(self, model_type: str, prompt: str, **kwargs) -> str:
        """Generate text with specified model."""
        port = self.PORTS[model_type]
        model = self.MODELS[model_type]
        
        resp = requests.post(
            f"{self.base_url}:{port}/api/generate",
            json={"model": model, "prompt": prompt, **kwargs}
        )
        return resp.json().get("response", "")
    
    def list_models(self, port: int) -> List[str]:
        """List available models."""
        resp = requests.get(f"{self.base_url}:{port}/api/tags")
        return [m["name"] for m in resp.json().get("models", [])]
```

## LangChain/LangSmith Integration

```python
import os
from dotenv import load_dotenv
from langchain_community.llms import Ollama
from langchain.schema import HumanMessage
from langsmith import traceable

load_dotenv(dotenv_path=os.path.expanduser("~/ssapikeys.mine.donotlook"))

PORTS = {
    "granite": "http://localhost:55077",
    "think": "http://localhost:55088",
    "qwen": "http://localhost:66044", 
    "code": "http://localhost:66033"
}

MODELS = {
    "granite": "granite4",
    "think": "deepseek-r1",
    "qwen": "qwen2.5-coder",
    "code": "codellama"
}

class OllamaClient:
    """LangChain-compatible Ollama client."""
    
    def __init__(self, model_type: str):
        self.base_url = PORTS[model_type]
        self.model = MODELS[model_type]
        self.llm = Ollama(model=self.model, base_url=self.base_url)
        
    @traceable
    def invoke(self, prompt: str) -> str:
        return self.llm.invoke(prompt)
    
    @traceable  
    def chat(self, messages: list) -> str:
        return self.llm.chat(messages)

# Usage examples
granite_client = OllamaClient("granite")
think_client = OllamaClient("think")
qwen_client = OllamaClient("qwen")
code_client = OllamaClient("code")

# Reasoning tasks
result = think_client.invoke("Explain the math behind transformers")

# Coding tasks  
result = qwen_client.invoke("Write a Python function to merge two sorted arrays")

# General tasks
result = granite_client.invoke("Summarize the history of LLMs")
```

## LangGraph Integration

```python
from langgraph.prebuilt import create_react_agent
from langchain.tools import tool

@tool
def query_ollama(prompt: str, model: str = "granite") -> str:
    """Query Ollama model."""
    client = OllamaClient(model)
    return client.invoke(prompt)

# Create agent with Ollama tools
agent = create_react_agent(
    OllamaClient("granite").llm,
    [query_ollama]
)

result = agent.invoke({
    "messages": [("user", "Use the Ollama tool to explain quantum computing")]
})
```

## VS Code / Cursor Integration

### Ollama Extension Configuration
```json
{
  "ollama.modelList": [
    {
      "name": "granite4",
      "endpoint": "http://localhost:55077"
    },
    {
      "name": "deepseek-r1", 
      "endpoint": "http://localhost:55088"
    },
    {
      "name": "qwen2.5-coder",
      "endpoint": "http://localhost:66044"
    },
    {
      "name": "codellama",
      "endpoint": "http://localhost:66033"
    }
  ]
}
```

### Remote SSH to HPCC
1. Install "Remote - SSH" extension
2. Connect to: `sweeden@login.hpcc.ttu.edu`
3. Use SSH key: `~/projects/GlobPretect/id_ed25519_sweeden`

### Cursor IDE
1. Settings → Models → Ollama
2. Add endpoints for each port
3. Use @cursor to select model per task

## Testing

```python
# test/test_ollama.py
import unittest
from ollamahpcc import OllamaServer, OllamaClient

class TestOllamaServer(unittest.TestCase):
    def setUp(self):
        self.server = OllamaServer()
        
    def test_check_health(self):
        """Test Ollama health check."""
        for port in [55077, 55088, 66044, 66033]:
            health = self.server.check_health(port)
            self.assertIsInstance(health, bool)
            
    def test_generate(self):
        """Test text generation."""
        try:
            result = self.server.generate("granite", "Hello")
            self.assertIsInstance(result, str)
        except:
            self.skipTest("Ollama not running")

class TestOllamaClient(unittest.TestCase):
    def test_granite_client(self):
        try:
            client = OllamaClient("granite")
            result = client.invoke("Hi")
            self.assertIsInstance(result, str)
        except:
            self.skipTest("Ollama not running")
```

## File Structure

```
OllamaHpcc/
├── docs/
│   ├── CLAUDE.md          # This file
│   ├── AGENTS.md          # Multi-agent guide
│   ├── GEMINI.md          # Gemini-specific guidance
│   ├── README.md          # Project overview
│   └── SETUP/
│       └── INSTALL.md     # Installation guide
├── scripts/
│   ├── start-local.sh     # Start local Ollama containers
│   ├── start-hpcc.sh      # Start HPCC Ollama job
│   └── test-connection.sh # Test connectivity
├── src/python/
│   └── ollamahpcc/
│       ├── __init__.py    # Main module
│       ├── server.py      # Server management
│       ├── client.py      # Client library
│       └── langchain.py   # LangChain integration
└── test/python/
    └── test_ollama.py     # Unit tests
```

## Common Issues

### Issue: Connection refused
**Solution**: Check VPN is active
```bash
# Test ports
for port in 55077 55088 66044 66033; do
    nc -zv localhost $port
done
```

### Issue: Model not found
**Solution**: Pull model
```bash
podman exec ollama-granite4 ollama pull granite4
```

### Issue: GPU not available on HPCC
**Solution**: Request correct partition
```bash
srun -p matador --gpus-per-node=1 -t 02:00:00 --pty bash
```

## Development Workflow

1. **Local Development** (MacBook/Rocky)
   - Start Ollama containers locally
   - Test prompts and code
   - Validate LangChain integration

2. **HPCC Testing**
   - Submit batch job to matador
   - Test with small models
   - Verify GPU utilization

3. **Production**
   - Deploy to toreador for A100
   - Set up monitoring
   - Configure LangSmith tracing

## Next Steps

1. Set up local Ollama containers
2. Test LangChain integration
3. Submit HPCC job for GPU testing
4. Configure VS Code Remote SSH
5. Set up LangSmith tracing
