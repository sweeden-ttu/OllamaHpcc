# CURSOR.md - Cursor IDE Configuration Guide

This document provides Cursor IDE configuration, skillsets, rulesets, and GitHub integration for this project.

## Project Repositories

| Project | GitHub URL |
|---------|------------|
| brw-scan-print | github.com/sweeden-ttu/brw-scan-print |
| GlobPretect | github.com/sweeden-ttu/GlobPretect |
| OllamaHpcc | github.com/sweeden-ttu/OllamaHpcc |

## Cursor Setup

### Installation

1. Download from [cursor.sh](https://cursor.sh)
2. Install on MacBook / Rocky Linux
3. Sign in with GitHub account

### SSH Key Configuration

```bash
# Add SSH key to Cursor
# Settings → Keys → Add SSH Key
# Copy: ~/projects/GlobPretect/id_ed25519_sweeden.pub
```

## Cursor Rules

### Create Project Rules

Create `.cursor/rules/` directory and add rules:

```
.cursor/rules/
├── PROJECT.mdc          # Main project rules
├── CODING_STYLE.mdc     # Coding conventions
├── PYTHON_GUIDE.mdc     # Python specific
└── OLLAMA_GUIDE.mdc    # Ollama integration
```

### Sample Rule: PROJECT.mdc

```markdown
# Project Rules

This project uses:
- Python with Miniconda for virtual environments
- Fixed Ollama ports: 55077, 55088, 66044, 66033
- VPN (GlobPretect) must be active for Ollama
- GitHub: github.com/sweeden-ttu/{repo_name}

## Environment
- Rocky Linux 10 (glibc)
- HPCC RedRaider for GPU builds
- Miniconda for Python environments

## Key Libraries
- langchain, langsmith, ollama
- paramiko, requests, python-dotenv
```

## Ollama Integration

### Configure Ollama Endpoints

In Cursor Settings → Models → Ollama:

```json
{
  "ollama.endpoints": [
    {"name": "granite4", "url": "http://localhost:55077"},
    {"name": "deepseek-r1", "url": "http://localhost:55088"},
    {"name": "qwen-coder", "url": "http://localhost:66044"},
    {"name": "codellama", "url": "http://localhost:66033"}
  ]
}
```

### Using Ollama in Cursor

```python
# In Cursor Terminal or AI Chat
# Use port 66044 for coding tasks
# Use port 55088 for reasoning
# Use port 55077 for general tasks
```

## MCP Servers

### Configure MCP

Create `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"],
      "env": {
        "ALLOWED_DIRECTORIES": "/home/sdw3098/projects"
      }
    }
  }
}
```

### Available MCP Servers

| Server | Purpose |
|--------|---------|
| github | GitHub API, issues, PRs |
| filesystem | File operations |
| sequential-thinking | Reasoning chains |
| brave-search | Web search |

## Cursor Modes

### Ask Mode
- Quick questions
- Code explanations
- No file modifications

### Edit Mode
- Single file changes
- Inline edits
- Refactoring

### Agent Mode (Cursor 2.0)
- Multi-file operations
- Complex implementations
- Full project changes
- Up to 8 parallel agents

## GitHub Integration

### Clone Repository

```bash
# In Cursor Terminal
git clone git@github.com:sweeden-ttu/brw-scan-print.git
cd brw-scan-print
```

### Push Changes

```bash
git add -A
git commit -m "Your message"
git push origin main
```

### Create Feature Branch

```bash
git checkout -b feature/your-feature
# Make changes
git push -u origin feature/your-feature
```

## Skillsets

### Python Development

```python
# Activate conda environment
conda activate projectname

# Install dependencies
pip install langchain langsmith ollama

# Run tests
pytest test/
```

### Ollama Operations

```bash
# Check Ollama status
curl http://localhost:55077/api/tags

# Test connection
./scripts/test-ports.sh
```

### HPCC Operations

```bash
# SSH to HPCC
ssh -i ~/projects/GlobPretect/id_ed25519_sweeden sweeden@login.hpcc.ttu.edu

# Submit job
sbatch script.sh

# Check queue
squeue -u $USER
```

## Workflow Recommendations

### Daily Routine

1. Open Cursor → Pull latest from GitHub
2. Make changes in Agent/Edit mode
3. Test locally
4. Commit and push
5. Run daily sync script

### Using AI Agents

```
# For coding tasks
Use port 66044 (qwen-coder)

# For reasoning tasks  
Use port 55088 (deepseek-r1)

# For documentation
Use port 66033 (codellama)
```

## Configuration Files

### .gitignore

```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.conda/

# IDE
.idea/
.vscode/
.cursor/

# OS
.DS_Store
Thumbs.db
```

### requirements.txt

```
langchain>=0.1.0
langchain-community>=0.0.10
langsmith>=0.1.0
ollama>=0.1.0
python-dotenv>=1.0.0
requests>=2.31.0
```

## Troubleshooting

### Issue: Cannot connect to Ollama

```
1. Check VPN is active
2. Verify ports: 55077, 55088, 66044, 66033
3. Run: ./scripts/test-ports.sh
```

### Issue: GitHub permission denied

```
1. Add SSH key to GitHub
2. Run: ssh-add ~/projects/GlobPretect/id_ed25519_sweeden
3. Test: ssh -T git@github.com
```

### Issue: MCP not working

```
1. Check Settings → Features → MCP
2. Restart Cursor
3. Verify npm/node installed
```
