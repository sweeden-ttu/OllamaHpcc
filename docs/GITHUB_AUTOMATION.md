# GITHUB_AUTOMATION.md - Daily GitHub Sync Instructions

This document describes how to set up automated daily GitHub synchronization for all projects.

## Repositories

| Project | GitHub URL |
|---------|------------|
| brw-scan-print | github.com/sweeden-ttu/brw-scan-print |
| GlobPretect | github.com/sweeden-ttu/GlobPretect |
| OllamaHpcc | github.com/sweeden-ttu/OllamaHpcc |

## Manual Sync

### Run Daily Sync Script

```bash
# Navigate to any project
cd ~/projects/brw-scan-print

# Run the sync script
./scripts/daily-github-sync.sh

# Or use specific commands
./scripts/daily-github-sync.sh pull   # Pull only
./scripts/daily-github-sync.sh push   # Push only
./scripts/daily-github-sync.sh commit  # Commit with date message
```

### Commands

| Command | Description |
|---------|-------------|
| `./daily-github-sync.sh` | Pull + Commit + Push all repos |
| `./daily-github-sync.sh pull` | Pull from remote only |
| `./daily-github-sync.sh push` | Push to remote only |
| `./daily-github-sync.sh commit` | Commit with date and push |

## Automated Sync (Cron)

### Setup Cron Job

```bash
# Edit crontab
crontab -e

# Add daily sync at 6 AM
0 6 * * * /home/sdw3098/projects/brw-scan-print/scripts/daily-github-sync.sh >> /home/sdw3098/logs/github-sync.log 2>&1

# Or twice daily (6 AM and 6 PM)
0 6,18 * * * /home/sdw3098/projects/brw-scan-print/scripts/daily-github-sync.sh >> /home/sdw3098/logs/github-sync.log 2>&1
```

### Verify Cron

```bash
# List cron jobs
crontab -l

# Check logs
cat ~/logs/github-sync.log
```

## GitHub Actions (Alternative)

### Create Workflow File

Create `.github/workflows/daily-sync.yml`:

```yaml
name: Daily Sync
on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          ssh-key: ${{ secrets.GITHUB_SSH_KEY }}
      
      - name: Pull Latest
        run: |
          git fetch origin
          git pull origin main || git pull origin master
      
      - name: Commit Changes
        run: |
          git add -A
          git -c user.email="sweeden@ttu.edu" \
              -c user.name="sweeden-ttu" \
              commit -m "Daily update $(date +%Y-%m-%d)" || true
      
      - name: Push Changes
        run: git push origin main || true
```

## SSH Key Setup

### Generate GitHub SSH Key

```bash
# Create dedicated GitHub key
ssh-keygen -t ed25519 -C "sweeden@ttu.edu" -f ~/projects/GlobPretect/id_ed25519_sweeden

# Add to GitHub:
# 1. Go to github.com/settings/keys
# 2. Add new SSH key
# 3. Paste contents of ~/projects/GlobPretect/id_ed25519_sweeden.pub
```

### Configure Git

```bash
# Set up git config
git config --global user.email "sweeden@ttu.edu"
git config --global user.name "sweeden-ttu"
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Add SSH key to agent
ssh-add ~/projects/GlobPretect/id_ed25519_sweeden
```

## Troubleshooting

### Issue: Permission denied

```bash
# Test SSH connection
ssh -T git@github.com

# Regenerate key if needed
ssh-keygen -t ed25519 -C "sweeden@ttu.edu" -f ~/projects/GlobPretect/id_ed25519_sweeden
```

### Issue: Merge conflicts

```bash
# Resolve manually
git pull origin main
# Fix conflicts
git add -A
git commit -m "Resolve conflicts"
git push origin main
```

### Issue: Cron not running

```bash
# Check cron status
systemctl status cron

# Start cron
sudo systemctl start cron
```

## Best Practices

1. **Run daily** - Sync at least once per day
2. **Pull before push** - Always pull remote changes first
3. **Commit meaningful messages** - Use date-based messages for automated commits
4. **Check logs** - Review cron logs regularly
5. **Handle conflicts** - Resolve promptly to avoid build issues

## Quick Reference

```bash
# One-time setup
ssh-keygen -t ed25519 -C "sweeden@ttu.edu" -f ~/projects/GlobPretect/id_ed25519_sweeden
# Add pub key to GitHub

# Daily manual sync
cd ~/projects/brw-scan-print && ./scripts/daily-github-sync.sh

# Setup automated cron
crontab -e
# Add: 0 6 * * * /home/sdw3098/projects/brw-scan-print/scripts/daily-github-sync.sh
```
