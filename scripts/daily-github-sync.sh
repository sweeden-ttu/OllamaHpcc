#!/bin/bash
# daily-github-sync.sh - Daily GitHub sync script
# Run this script daily to push local changes and pull remote updates

set -e

# Configuration
REPOS=(
    "brw-scan-print"
    "GlobPretect"
    "OllamaHpcc"
)

GIT_EMAIL="sweeden@ttu.edu"
GIT_NAME="sweeden-ttu"
PROJECTS_DIR="$HOME/projects"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check for uncommitted changes
check_changes() {
    local repo=$1
    local dir="$PROJECTS_DIR/$repo"
    
    if [ ! -d "$dir/.git" ]; then
        echo "Skipping $repo - not a git repo"
        return 1
    fi
    
    cd "$dir"
    
    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_warn "$repo has uncommitted changes"
        return 0
    fi
    
    return 2  # No changes
}

# Pull latest from remote
pull_remote() {
    local repo=$1
    local dir="$PROJECTS_DIR/$repo"
    
    cd "$dir"
    
    log_info "Pulling latest from $repo..."
    
    if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
        log_info "$repo: Pull successful"
    else
        log_warn "$repo: No remote or pull not needed"
    fi
}

# Push to remote
push_to_remote() {
    local repo=$1
    local dir="$PROJECTS_DIR/$repo"
    
    cd "$dir"
    
    log_info "Pushing $repo..."
    
    if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
        log_info "$repo: Push successful"
    else
        log_error "$repo: Push failed"
        return 1
    fi
}

# Commit pending changes
commit_pending() {
    local repo=$1
    local dir="$PROJECTS_DIR/$repo"
    local message="${2:-Daily update}"
    
    cd "$dir"
    
    # Check for changes
    if git diff --quiet && git diff --cached --quiet; then
        return 0  # No changes to commit
    fi
    
    # Add all changes
    git add -A
    
    # Commit
    git commit -m "$message" || true
    
    log_info "$repo: Committed changes"
}

# Main sync function
sync_repo() {
    local repo=$1
    local dir="$PROJECTS_DIR/$repo"
    
    if [ ! -d "$dir" ]; then
        log_error "Directory not found: $dir"
        return 1
    fi
    
    if [ ! -d "$dir/.git" ]; then
        log_error "Not a git repository: $repo"
        return 1
    fi
    
    echo ""
    log_info "=== Syncing $repo ==="
    
    # Pull first
    pull_remote "$repo"
    
    # Commit any pending changes
    commit_pending "$repo"
    
    # Push
    push_to_remote "$repo"
    
    log_info "=== $repo sync complete ==="
}

# Configure git if needed
configure_git() {
    git config --global user.email "$GIT_EMAIL" 2>/dev/null || true
    git config --global user.name "$GIT_NAME" 2>/dev/null || true
    git config --global url."git@github.com:".insteadOf "https://github.com/" 2>/dev/null || true
}

# Main execution
main() {
    log_info "Starting daily GitHub sync..."
    
    # Configure git
    configure_git
    
    # Sync each repository
    for repo in "${REPOS[@]}"; do
        sync_repo "$repo" || log_error "Failed to sync $repo"
    done
    
    log_info "Daily GitHub sync complete!"
}

# Run with date-based commit message
commit_with_date() {
    local date_msg=$(date +"%Y-%m-%d %H:%M")
    local message="Daily update - $date_msg"
    
    for repo in "${REPOS[@]}"; do
        commit_pending "$repo" "$message"
        push_to_remote "$repo"
    done
}

# If script is run with argument, use it as command
case "${1:-sync}" in
    sync)
        main
        ;;
    commit)
        commit_with_date
        ;;
    pull)
        for repo in "${REPOS[@]}"; do
            pull_remote "$repo"
        done
        ;;
    push)
        for repo in "${REPOS[@]}"; do
            push_to_remote "$repo"
        done
        ;;
    *)
        echo "Usage: $0 {sync|pull|push|commit}"
        exit 1
        ;;
esac
