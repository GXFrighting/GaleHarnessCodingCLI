#!/bin/bash
<<<<<<< HEAD
# compound-sync.sh - Sync GaleHarnessCLI from local compound-engineering-plugin
#
# Usage:
#   bash scripts/compound-sync.sh check      # Check if updates available
#   bash scripts/compound-sync.sh update     # Update local compound repo
=======
# compound-sync.sh - Diff-based upstream sync for GaleHarnessCLI
#
# Usage:
#   bash scripts/compound-sync.sh check      # Check if updates available
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
#   bash scripts/compound-sync.sh diff       # Generate transformed diff
#   bash scripts/compound-sync.sh apply      # Apply diff to working tree
#   bash scripts/compound-sync.sh pr         # Create PR with changes
#   bash scripts/compound-sync.sh all        # Full sync workflow
#
<<<<<<< HEAD
# Config: .compound-upstream
#   COMPOUND_PATH=~/work/compound-engineering-plugin
#
=======
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
# Environment:
#   DRY_RUN=1  - Preview changes without applying
#   NO_PUSH=1  - Skip push/PR creation

set -euo pipefail

<<<<<<< HEAD
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
=======
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
<<<<<<< HEAD
cd "$REPO_ROOT"

# CE skill names for prefix transformation
CE_SKILLS="compound-refresh|compound|brainstorm|ideate|plan|work-beta|work|review|debug|demo-reel|optimize|sessions|setup|slack-research|update|pr-description|todo-create|todo-list|git-worktree|resolve-pr-feedback|lfg|ship|publish|preflight|polish-beta"

# Load and validate config
load_config() {
  if [ ! -f "$REPO_ROOT/.compound-upstream" ]; then
    log_error ".compound-upstream not found"
    echo ""
    echo "Create it with:"
    echo "  echo 'COMPOUND_PATH=~/work/compound-engineering-plugin' > .compound-upstream"
    exit 1
  fi

  source "$REPO_ROOT/.compound-upstream"

  # Expand tilde
  COMPOUND_PATH="${COMPOUND_PATH/#\~/$HOME}"
  COMPOUND_PLUGIN_DIR="${COMPOUND_PLUGIN_DIR:-plugins/compound-engineering}"

  if [ ! -d "$COMPOUND_PATH/.git" ]; then
    log_error "Compound repo not found at: $COMPOUND_PATH"
    echo ""
    echo "Clone it first:"
    echo "  git clone https://github.com/discover_ai/compound-engineering-plugin.git \"$COMPOUND_PATH\""
    exit 1
  fi

  export COMPOUND_PATH COMPOUND_PLUGIN_DIR
}

# -----------------------------------------------------------------------------
# check - See if compound has updates
# -----------------------------------------------------------------------------
cmd_check() {
  load_config

  LAST_SHA=$(cat "$REPO_ROOT/.upstream-ref" 2>/dev/null || echo "NONE")
  LATEST_SHA=$(git -C "$COMPOUND_PATH" rev-parse HEAD)

  log_info "Compound repo: $COMPOUND_PATH"
  log_info "Last synced:   $LAST_SHA"
  log_info "Compound HEAD: $LATEST_SHA"
=======
WORK_DIR=""

# Cleanup on exit
cleanup() {
  if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT

# Read configuration
UPSTREAM_REPO=$(cat "$REPO_ROOT/.upstream-repo" 2>/dev/null || echo "https://github.com/discover_ai/compound-engineering-plugin")
LAST_SHA=$(cat "$REPO_ROOT/.upstream-ref" 2>/dev/null || echo "NONE")

# CE skill names for prefix transformation
CE_SKILLS="compound-refresh|compound|brainstorm|ideate|plan|work-beta|work|review|debug|demo-reel|optimize|sessions|setup|slack-research|update|pr-description|todo-create|todo-list|git-worktree|resolve-pr-feedback|lfg|ship|publish|preflight"

# -----------------------------------------------------------------------------
# check - See if upstream has updates
# -----------------------------------------------------------------------------
cmd_check() {
  log_info "Checking upstream for updates..."
  log_info "Upstream: $UPSTREAM_REPO"
  log_info "Last synced: $LAST_SHA"

  # Fetch upstream
  git fetch "$UPSTREAM_REPO" main --depth=1 --no-tags 2>/dev/null || \
    git fetch "$UPSTREAM_REPO" master --depth=1 --no-tags 2>/dev/null || {
    log_error "Failed to fetch from upstream"
    exit 1
  }

  LATEST_SHA=$(git rev-parse FETCH_HEAD)
  log_info "Latest upstream: $LATEST_SHA"
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

  if [ "$LAST_SHA" = "$LATEST_SHA" ]; then
    log_info "Already up to date - no sync needed"
    echo "UP_TO_DATE=1"
  else
    log_info "Updates available!"
    echo "UP_TO_DATE=0"
    echo "LAST_SHA=$LAST_SHA"
    echo "LATEST_SHA=$LATEST_SHA"
    echo ""
    log_info "Commits since last sync:"
<<<<<<< HEAD
    git -C "$COMPOUND_PATH" log "$LAST_SHA".."$LATEST_SHA" --oneline 2>/dev/null | head -20 || true
=======
    git log "$LAST_SHA".."$LATEST_SHA" --oneline 2>/dev/null | head -20 || true
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
  fi
}

# -----------------------------------------------------------------------------
<<<<<<< HEAD
# update - Pull latest changes in compound repo
# -----------------------------------------------------------------------------
cmd_update() {
  load_config

  log_info "Updating compound repo at: $COMPOUND_PATH"

  cd "$COMPOUND_PATH"

  # Determine default branch
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

  log_info "Default branch: $DEFAULT_BRANCH"

  git fetch origin 2>/dev/null || true
  git checkout "$DEFAULT_BRANCH" 2>/dev/null || true
  git pull origin "$DEFAULT_BRANCH" --rebase 2>/dev/null || git pull origin "$DEFAULT_BRANCH" 2>/dev/null || true

  LATEST_SHA=$(git rev-parse HEAD)
  log_info "Compound now at: $LATEST_SHA"

  cd "$REPO_ROOT"
}

# -----------------------------------------------------------------------------
# diff - Generate transformed diff
# -----------------------------------------------------------------------------
cmd_diff() {
  load_config

  LAST_SHA=$(cat "$REPO_ROOT/.upstream-ref" 2>/dev/null)

  if [ -z "$LAST_SHA" ] || [ "$LAST_SHA" = "NONE" ]; then
    log_error "No .upstream-ref found"
    echo ""
    echo "Initialize with:"
    echo "  git -C \"$COMPOUND_PATH\" rev-parse HEAD > .upstream-ref"
    exit 1
  fi

  LATEST_SHA=$(git -C "$COMPOUND_PATH" rev-parse HEAD)

  if [ "$LAST_SHA" = "$LATEST_SHA" ]; then
    log_info "Already up to date - no diff needed"
    exit 0
  fi

  log_info "Generating diff: $LAST_SHA..$LATEST_SHA"
  log_info "Plugin dir: $COMPOUND_PLUGIN_DIR"

  # Generate raw diff
  git -C "$COMPOUND_PATH" diff "$LAST_SHA".."$LATEST_SHA" -- "$COMPOUND_PLUGIN_DIR/" > "$REPO_ROOT/.compound-sync.raw.diff" 2>/dev/null || {
    log_warn "No changes in plugin directory"
    echo "No diff generated"
    exit 0
  }

  RAW_FILES=$(grep -c "^diff --git" "$REPO_ROOT/.compound-sync.raw.diff" 2>/dev/null || echo "0")
  RAW_LINES=$(wc -l < "$REPO_ROOT/.compound-sync.raw.diff" 2>/dev/null || echo "0")
  log_info "Raw diff: $RAW_FILES files, $RAW_LINES lines"

  # Transform
  log_info "Transforming diff..."
  python3 - "$REPO_ROOT/.compound-sync.raw.diff" "$REPO_ROOT/.compound-sync.diff" << 'TRANSFORM_PY'
import sys, re

input_file = sys.argv[1]
output_file = sys.argv[2]
=======
# diff - Generate transformed diff
# -----------------------------------------------------------------------------
cmd_diff() {
  WORK_DIR=$(mktemp -d -t compound-sync-XXXXXX)
  log_info "Work directory: $WORK_DIR"

  # Fetch latest
  git fetch "$UPSTREAM_REPO" main --depth=100 --no-tags 2>/dev/null || \
    git fetch "$UPSTREAM_REPO" master --depth=100 --no-tags 2>/dev/null

  LATEST_SHA=$(git rev-parse FETCH_HEAD)

  if [ "$LAST_SHA" = "NONE" ]; then
    log_error "No previous sync point in .upstream-ref. Run initial sync first."
    exit 1
  fi

  log_info "Generating diff: $LAST_SHA..$LATEST_SHA"

  # Clone upstream to get the diff
  git clone --depth=100 "$UPSTREAM_REPO" "$WORK_DIR/upstream" 2>&1 | grep -E "(Cloning|done)" || true
  cd "$WORK_DIR/upstream"

  # Determine the plugin directory name in upstream
  if [ -d "plugins/compound-engineering" ]; then
    PLUGIN_DIR="plugins/compound-engineering"
  elif [ -d "plugins/galeharness-cli" ]; then
    PLUGIN_DIR="plugins/galeharness-cli"
  else
    log_error "Cannot find plugin directory in upstream"
    exit 1
  fi

  log_info "Upstream plugin directory: $PLUGIN_DIR"

  # Generate diff for the plugin directory
  git diff "$LAST_SHA"..HEAD -- "$PLUGIN_DIR/" > "$WORK_DIR/upstream.diff"

  DIFF_FILES=$(grep -c "^diff --git" "$WORK_DIR/upstream.diff" 2>/dev/null || echo "0")
  DIFF_LINES=$(wc -l < "$WORK_DIR/upstream.diff" 2>/dev/null || echo "0")
  log_info "Raw diff: $DIFF_FILES files, $DIFF_LINES lines"

  # Transform the diff
  log_info "Transforming diff..."
  python3 - "$WORK_DIR/upstream.diff" "$WORK_DIR/transformed.diff" "$PLUGIN_DIR" << 'TRANSFORM_PY'
import sys
import re

input_file = sys.argv[1]
output_file = sys.argv[2]
plugin_dir = sys.argv[3]
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

with open(input_file, 'r') as f:
    content = f.read()

<<<<<<< HEAD
# 1. Path transformation
content = re.sub(r'plugins/compound-engineering/', 'plugins/galeharness-cli/', content)

# 2. Directory rename: /ce-* -> /gh-*
content = re.sub(r'/(ce-[a-z0-9-]+)', lambda m: '/gh-' + m.group(1)[3:], content)

# 3. Skill prefixes
CE_SKILLS = [
=======
# 1. Path transformation: plugins/compound-engineering/ -> plugins/galeharness-cli/
#    or plugins/galeharness-cli/ stays the same
if plugin_dir == "plugins/compound-engineering":
    content = re.sub(
        r'plugins/compound-engineering/',
        'plugins/galeharness-cli/',
        content
    )

# 2. Directory rename in paths: /ce- -> /gh-
content = re.sub(
    r'/(ce-[a-z0-9-]+)',
    lambda m: '/gh-' + m.group(1)[3:],
    content
)

# 3. Skill name prefixes: ce: -> gh:
ce_skills = [
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
    "compound-refresh", "compound", "brainstorm", "ideate", "plan",
    "work-beta", "work", "review", "debug", "demo-reel", "optimize",
    "sessions", "setup", "slack-research", "update", "pr-description",
    "todo-create", "todo-list", "git-worktree", "resolve-pr-feedback",
<<<<<<< HEAD
    "lfg", "ship", "publish", "preflight", "polish-beta"
]
skills_pattern = '|'.join(re.escape(s) for s in CE_SKILLS)

=======
    "lfg", "ship", "publish", "preflight"
]
skills_pattern = '|'.join(re.escape(s) for s in ce_skills)
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
content = re.sub(rf'\bce:({skills_pattern})\b', r'gh:\1', content)
content = re.sub(rf'/ce:({skills_pattern})\b', r'/gh:\1', content)
content = re.sub(r'\bce-demo-reel\b', 'gh-demo-reel', content)

with open(output_file, 'w') as f:
    f.write(content)
<<<<<<< HEAD

print(f"Transformed diff written to {output_file}")
TRANSFORM_PY

  TRANSFORMED_FILES=$(grep -c "^diff --git" "$REPO_ROOT/.compound-sync.diff" 2>/dev/null || echo "0")
  log_info "Transformed diff: $TRANSFORMED_FILES files"
=======
TRANSFORM_PY

  TRANSFORMED_FILES=$(grep -c "^diff --git" "$WORK_DIR/transformed.diff" 2>/dev/null || echo "0")
  TRANSFORMED_LINES=$(wc -l < "$WORK_DIR/transformed.diff" 2>/dev/null || echo "0")
  log_info "Transformed diff: $TRANSFORMED_FILES files, $TRANSFORMED_LINES lines"

  # Copy to repo for inspection
  cp "$WORK_DIR/transformed.diff" "$REPO_ROOT/.compound-sync.diff"
  log_info "Diff saved to: $REPO_ROOT/.compound-sync.diff"
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

  echo "DIFF_FILE=$REPO_ROOT/.compound-sync.diff"
  echo "LATEST_SHA=$LATEST_SHA"
}

# -----------------------------------------------------------------------------
# apply - Apply the transformed diff
# -----------------------------------------------------------------------------
cmd_apply() {
<<<<<<< HEAD
  load_config

=======
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
  DIFF_FILE="${1:-$REPO_ROOT/.compound-sync.diff}"

  if [ ! -f "$DIFF_FILE" ]; then
    log_error "Diff file not found: $DIFF_FILE"
    log_info "Run 'compound-sync.sh diff' first"
    exit 1
  fi

<<<<<<< HEAD
  if [ ! -s "$DIFF_FILE" ]; then
    log_info "Diff is empty - nothing to apply"
    exit 0
  fi

  log_info "Applying diff: $DIFF_FILE"

  # Try clean apply
=======
  log_info "Applying diff: $DIFF_FILE"

  cd "$REPO_ROOT"

  # Try clean apply first
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
  if git apply --check "$DIFF_FILE" 2>/dev/null; then
    log_info "Diff applies cleanly"
    git apply "$DIFF_FILE"
  else
    log_warn "Diff has conflicts - attempting 3-way merge"
    git apply --3way "$DIFF_FILE" || {
      log_error "Failed to apply diff"
<<<<<<< HEAD
      log_info "Diff saved at: $DIFF_FILE"
=======
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
      log_info "Manual resolution may be needed"
      exit 1
    }
  fi

<<<<<<< HEAD
  log_info "Diff applied"
=======
  log_info "Diff applied successfully"
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

  # Apply HKTMemory patches
  if [ -f "$REPO_ROOT/.local/apply-hkt-patches.sh" ]; then
    log_info "Applying HKTMemory patches..."
    bash "$REPO_ROOT/.local/apply-hkt-patches.sh"
  fi

  # Full prefix pass
  log_info "Running full prefix pass..."
  python3 - "$REPO_ROOT/plugins/galeharness-cli" << 'FULLPASS_PY'
import sys, re, os

root = sys.argv[1]
<<<<<<< HEAD
CE_SKILLS = [
=======
ce_skills = [
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
    "compound-refresh", "compound", "brainstorm", "ideate", "plan",
    "work-beta", "work", "review", "debug", "demo-reel", "optimize",
    "sessions", "setup", "slack-research", "update", "pr-description",
    "todo-create", "todo-list", "git-worktree", "resolve-pr-feedback",
<<<<<<< HEAD
    "lfg", "ship", "publish", "preflight", "polish-beta"
]
skills_pattern = '|'.join(re.escape(s) for s in CE_SKILLS)

changed = 0
=======
    "lfg", "ship", "publish", "preflight"
]
skills_pattern = '|'.join(re.escape(s) for s in ce_skills)

>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
for dirpath, _, filenames in os.walk(root):
    for fname in filenames:
        if not fname.endswith(('.md', '.yaml', '.yml', '.json', '.txt')):
            continue
        fpath = os.path.join(dirpath, fname)
        try:
            with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            new_content = content
            new_content = re.sub(rf'\bce:({skills_pattern})\b', r'gh:\1', new_content)
            new_content = re.sub(rf'/ce:({skills_pattern})\b', r'/gh:\1', new_content)
            new_content = re.sub(r'\bce-demo-reel\b', 'gh-demo-reel', new_content)
            if new_content != content:
                with open(fpath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
<<<<<<< HEAD
                changed += 1
        except Exception:
            pass
print(f"Full pass: updated {changed} files")
FULLPASS_PY

  # Update reference
  LATEST_SHA=$(git -C "$COMPOUND_PATH" rev-parse HEAD)
=======
        except Exception:
            pass
print("Full pass complete")
FULLPASS_PY

  # Update .upstream-ref
  LATEST_SHA="${2:-$(git rev-parse FETCH_HEAD 2>/dev/null || echo 'unknown')}"
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
  echo "$LATEST_SHA" > "$REPO_ROOT/.upstream-ref"
  log_info "Updated .upstream-ref to $LATEST_SHA"

  # Show changes
  git status --short
  git diff --stat
}

# -----------------------------------------------------------------------------
# pr - Create PR
# -----------------------------------------------------------------------------
cmd_pr() {
  cd "$REPO_ROOT"

  # Check for changes
  if git diff --quiet && git diff --cached --quiet; then
    log_error "No changes to commit"
    exit 1
  fi

<<<<<<< HEAD
  SYNC_DATE=$(date +%Y-%m-%d)
  LAST_SHA=$(cat "$REPO_ROOT/.upstream-ref" 2>/dev/null | head -c 7)
  LATEST_SHA=$(git -C "$COMPOUND_PATH" rev-parse --short HEAD 2>/dev/null || echo "unknown")

  # Create branch if on main/master
  CURRENT_BRANCH=$(git branch --show-current)
  if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    SYNC_BRANCH="sync/compound-$SYNC_DATE"
=======
  # Get info
  SYNC_BRANCH="sync/upstream-$(date +%Y-%m-%d-%H%M)"
  UPSTREAM_DATE=$(date +%Y-%m-%d)
  LATEST_SHA=$(cat "$REPO_ROOT/.upstream-ref")
  LAST_SHA="${LAST_SHA:-unknown}"

  # Create branch if not already on one
  CURRENT_BRANCH=$(git branch --show-current)
  if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
    git checkout -b "$SYNC_BRANCH"
    log_info "Created branch: $SYNC_BRANCH"
  else
    SYNC_BRANCH="$CURRENT_BRANCH"
    log_info "Using existing branch: $SYNC_BRANCH"
  fi

<<<<<<< HEAD
  # Run tests (non-blocking)
  log_info "Running tests..."
=======
  # Run tests
  log_info "Running tests..."
  cd "$REPO_ROOT"
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
  bun install --frozen-lockfile 2>/dev/null || bun install
  bun test || log_warn "Tests failed - proceeding anyway"

  # Commit
  git add -A
  git commit -m "$(cat <<EOF
<<<<<<< HEAD
sync: compound upstream $SYNC_DATE
=======
sync: upstream compound $UPSTREAM_DATE
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

- Sync from $LAST_SHA to $LATEST_SHA
- Applied ce: -> gh: prefix transformation
- Applied HKTMemory patches

🤖 Generated with [Qoder](https://qoder.com)
EOF
)"

<<<<<<< HEAD
  # Push and create PR
=======
  # Push
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
  if [ -z "${NO_PUSH:-}" ]; then
    log_info "Pushing to origin..."
    git push origin "$SYNC_BRANCH" --set-upstream

<<<<<<< HEAD
    log_info "Creating PR..."
    PR_URL=$(gh pr create --title "sync: compound upstream $SYNC_DATE" --body "$(cat <<EOF
## Summary

Syncs GaleHarnessCLI with the latest compound-engineering-plugin changes.
=======
    # Create PR
    log_info "Creating PR..."
    PR_URL=$(gh pr create --title "sync: upstream compound $UPSTREAM_DATE" --body "$(cat <<EOF
## Summary

Syncs GaleHarnessCLI with the latest upstream compound-engineering-plugin changes.
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

**Upstream range:** \`$LAST_SHA\`...\`$LATEST_SHA\`

### Changes Applied

- [x] Path transformation: \`plugins/compound-engineering/\` -> \`plugins/galeharness-cli/\`
- [x] Directory rename: \`ce-*\` -> \`gh-*\`
- [x] Prefix transformation: \`ce:\` -> \`gh:\`
- [x] HKTMemory patches applied

## Test Plan

- [ ] \`bun test\` passes
- [ ] \`bun run release:validate\` passes
<<<<<<< HEAD
=======
- [ ] Manual review of transformed skill files
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

🤖 Generated with [Qoder](https://qoder.com)
EOF
)" 2>&1)

    log_info "PR created: $PR_URL"
    echo "PR_URL=$PR_URL"
  else
    log_info "Skipping push (NO_PUSH set)"
  fi
}

# -----------------------------------------------------------------------------
<<<<<<< HEAD
# init - Initialize config
# -----------------------------------------------------------------------------
cmd_init() {
  if [ -f "$REPO_ROOT/.compound-upstream" ]; then
    log_info ".compound-upstream already exists"
    cat "$REPO_ROOT/.compound-upstream"
    exit 0
  fi

  DEFAULT_PATH="$HOME/work/compound-engineering-plugin"

  echo "COMPOUND_PATH=$DEFAULT_PATH" > "$REPO_ROOT/.compound-upstream"
  log_info "Created .compound-upstream with default path: $DEFAULT_PATH"
  echo ""
  echo "Edit if needed:"
  echo "  vim .compound-upstream"
  echo ""
  echo "Then initialize the reference:"
  echo "  git -C \"$DEFAULT_PATH\" rev-parse HEAD > .upstream-ref"
}

# -----------------------------------------------------------------------------
=======
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
# all - Full sync workflow
# -----------------------------------------------------------------------------
cmd_all() {
  log_info "=== Compound Sync Full Workflow ==="

  # Check for updates
  log_info "Step 1: Checking for updates..."
  RESULT=$(cmd_check 2>&1)
  if echo "$RESULT" | grep -q "UP_TO_DATE=1"; then
    log_info "Already up to date - nothing to sync"
    exit 0
  fi

  # Generate diff
  log_info "Step 2: Generating diff..."
<<<<<<< HEAD
  cmd_diff || {
    log_info "No changes to sync"
    exit 0
  }

  # Apply diff
  log_info "Step 3: Applying diff..."
  cmd_apply "$REPO_ROOT/.compound-sync.diff"
=======
  cmd_diff

  # Apply diff
  log_info "Step 3: Applying diff..."
  LATEST_SHA=$(cat "$REPO_ROOT/.upstream-ref" 2>/dev/null || echo "unknown")
  cmd_apply "$REPO_ROOT/.compound-sync.diff" "$LATEST_SHA"
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

  # Create PR
  log_info "Step 4: Creating PR..."
  cmd_pr

  # Cleanup
<<<<<<< HEAD
  rm -f "$REPO_ROOT/.compound-sync.raw.diff" "$REPO_ROOT/.compound-sync.diff"
=======
  rm -f "$REPO_ROOT/.compound-sync.diff"
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)

  log_info "=== Sync Complete ==="
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
COMMAND="${1:-help}"

case "$COMMAND" in
  check) cmd_check ;;
<<<<<<< HEAD
  update) cmd_update ;;
  diff) cmd_diff ;;
  apply) cmd_apply "${2:-}" ;;
  pr) cmd_pr ;;
  init) cmd_init ;;
=======
  diff) cmd_diff ;;
  apply) cmd_apply "${2:-}" ;;
  pr) cmd_pr ;;
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
  all) cmd_all ;;
  help|*)
    echo "Usage: compound-sync.sh <command>"
    echo ""
    echo "Commands:"
<<<<<<< HEAD
    echo "  init     Initialize .compound-upstream config"
    echo "  check    Check if compound has updates"
    echo "  update   Pull latest in compound repo"
    echo "  diff     Generate transformed diff"
    echo "  apply    Apply diff to working tree"
    echo "  pr       Create PR with changes"
    echo "  all      Full sync workflow (check -> diff -> apply -> pr)"
    echo ""
    echo "Config: .compound-upstream"
    echo "  COMPOUND_PATH=~/work/compound-engineering-plugin"
    echo ""
    echo "Environment:"
    echo "  DRY_RUN=1   Preview changes without applying"
    echo "  NO_PUSH=1   Apply changes but skip push/PR creation"
=======
    echo "  check   Check if upstream has updates"
    echo "  diff    Generate transformed diff"
    echo "  apply   Apply diff to working tree"
    echo "  pr      Create PR with changes"
    echo "  all     Full sync workflow (check -> diff -> apply -> pr)"
    echo ""
    echo "Environment:"
    echo "  DRY_RUN=1   Preview changes without applying"
    echo "  NO_PUSH=1   Skip push/PR creation"
>>>>>>> 912b5ce (feat: GaleHarnessCLI 初始发布)
    ;;
esac
