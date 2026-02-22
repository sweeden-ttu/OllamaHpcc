# GEMINI.md - Gemini AI Development Guide

This document provides guidance for Gemini AI when working on this project.

## Project Context

**OllamaHpcc** - Ollama server and client for HPCC RedRaider GPU clusters
- Deploys Ollama on GPU nodes (matador/toreador)
- Client libraries for LangChain, LangGraph, LangSmith
- VS Code/Cursor integration with Ollama toolsets

## Fixed Ollama Ports (VPN Required)

**IMPORTANT**: Always use fixed ports 55077 or 66044. Never use default port 11434.

| Port | Model | Agent Role |
|------|-------|------------|
| 55077 | granite4 | Agentic - high-level decision making, tool selection |
| 55088 | deepseek-r1 | Large - complex reasoning, deep thinking |
| 66044 | qwen-coder | Coding - code generation, debugging |
| 66033 | codellama | Plain English - communication, documentation |

## Gemini-Specific Guidelines

### Model Selection by Task

```python
# For LangChain integration analysis
port = 55088  # deepseek-r1 - complex reasoning about chain logic

# For code generation
port = 66044  # qwen-coder - code implementation

# For documentation
port = 66033  # codellama - plain English explanations

# For general tasks
port = 55077  # granite4 - stable, reliable
```

### HPCC GPU Tasks

When working with Slurm/GPU jobs:
1. Use port 55088 for complex GPU job debugging
2. Use port 66044 for batch script generation
3. Use port 66033 for documentation

### LangChain/LangGraph Tasks

```python
# Complex chain reasoning
port = 55088

# Code implementation
port = 66044
```

## GitHub Integration

**Repository**: github.com/sweeden-ttu/OllamaHpcc

```bash
git clone git@github.com:sweeden-ttu/OllamaHpcc.git
cd OllamaHpcc
git config user.email "sweeden@ttu.edu"
git config user.name "sweeden-ttu"
```

## Development Workflow

1. **Analyze requirements** - Use port 55088
2. **Generate code** - Use port 66044
3. **Create documentation** - Use port 66033
4. **Test implementations** - Use port 55077

## Important Notes

- VPN must be active for Ollama operations
- Fixed ports: 55077 (granite4), 66044 (qwen-coder)
- Never use default port 11434
- Container base: docker.io/autosubmit/slurm-openssh-container:latest
