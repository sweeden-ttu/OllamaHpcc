# SETUP.md - OllamaHpcc Miniconda Environment

## Quick Start

```bash
# Install Miniconda (if not already)
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
source $HOME/miniconda3/etc/profile.d/conda.sh

# Create environment with LangChain/LangSmith support
conda create -n ollama python=3.12 pip -y
conda activate ollama

# Install dependencies
pip install langchain langchain-community langsmith ollama python-dotenv requests

# Install ollamahpcc
cd ~/projects/OllamaHpcc
pip install -e .
```

## GPU Environment (CUDA)

```bash
# Create environment with CUDA support
conda create -n ollama-gpu python=3.12 pip cudatoolkit=11.8 -y
conda activate ollama-gpu

# Install PyTorch with CUDA
pip install torch --index-url https://download.pytorch.org/whl/cu118

# Install Ollama dependencies
pip install langchain langchain-community langsmith ollama python-dotenv requests
```

## HPCC GPU Setup

```bash
#!/bin/bash
#SBATCH -J ollama-gpu
#SBATCH -p matador
#SBATCH --gpus-per-node=1
#SBATCH -t 04:00:00

# Load system modules
module load gcc cuda

# Initialize conda
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate ollama-gpu

# Verify GPU
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Run Ollama operations
python -c "
from ollamahpcc import OllamaServer
server = OllamaServer()
print(server.get_status())
"
```

## Environment Dependencies

| Package | Purpose |
|---------|---------|
| langchain | LLM chaining framework |
| langchain-community | Community integrations |
| langsmith | Tracing and evaluation |
| ollama | Ollama Python client |
| python-dotenv | Environment variables |
| requests | HTTP API calls |
| torch | GPU support (optional) |

## Verify Installation

```bash
# Basic test
python -c "from ollamahpcc import OllamaServer, OllamaClient; print('OK')"

# GPU test
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# Test Ollama connection
curl http://localhost:55077/api/tags
```

## Ollama Ports

| Port | Model | Purpose |
|------|-------|---------|
| 55077 | granite4 | Agentic |
| 55088 | deepseek-r1 | Large/Reasoning |
| 66044 | qwen-coder | Coding |
| 66033 | codellama | Plain English |

## VS Code / Cursor Integration

1. Open project in VS Code/Cursor
2. Select interpreter: `Cmd+Shift+P` → "Python: Select Interpreter"
3. Choose: `~/miniconda3/envs/ollama/bin/python`
