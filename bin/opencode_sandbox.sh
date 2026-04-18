#!/usr/bin/env bash

BRANCH_NAME="${1:-}"
CREDENTIALS_DIR="$HOME/.config/opencode-sandbox"
WORKTREE_DIR=".worktrees"
CONTAINER_WORKDIR="/workspace"

# --- Git worktree setup (only when a branch name is provided) ---
if [ -n "$BRANCH_NAME" ]; then
  # Verify current directory is a git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Current directory is not a git repository"
    exit 1
  fi

  # Add .worktrees/ to .git/info/exclude if not already there (local-only, no repo changes)
  EXCLUDE_FILE="$(git rev-parse --git-dir)/info/exclude"
  if ! grep -qx '.worktrees/' "$EXCLUDE_FILE" 2>/dev/null; then
    echo '.worktrees/' >> "$EXCLUDE_FILE"
  fi

  WORKTREE_PATH="$WORKTREE_DIR/$BRANCH_NAME"

  if [ -d "$WORKTREE_PATH" ]; then
    echo "Reusing existing worktree at $WORKTREE_PATH (branch '$BRANCH_NAME')"
  else
    mkdir -p "$WORKTREE_DIR"

    # Create the worktree: use -b if branch doesn't exist yet, otherwise attach to existing branch
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
      echo "Creating worktree for existing branch '$BRANCH_NAME'..."
      git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
    else
      echo "Creating worktree with new branch '$BRANCH_NAME' from $(git rev-parse --abbrev-ref HEAD)..."
      git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
    fi

    # Rewrite .git file and gitdir back-reference to use relative paths
    # so they resolve correctly when mounted inside the container at /workspace
    REPO_GIT_DIR="$(git rev-parse --git-dir)"
    echo "gitdir: ../../.git/worktrees/$BRANCH_NAME" > "$WORKTREE_PATH/.git"
    echo "../../../$WORKTREE_DIR/$BRANCH_NAME/.git" > "$REPO_GIT_DIR/worktrees/$BRANCH_NAME/gitdir"
  fi

  CONTAINER_WORKDIR="/workspace/$WORKTREE_PATH"
  echo "Working on branch '$BRANCH_NAME' in worktree at $WORKTREE_PATH/"
fi

# --- Container name ---
DIR_NAME="$(basename "$(pwd)")"
if [ -n "$BRANCH_NAME" ]; then
  GIT_BRANCH="$BRANCH_NAME"
elif git rev-parse --abbrev-ref HEAD > /dev/null 2>&1; then
  GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
else
  GIT_BRANCH="nobranch"
fi
RANDOM_SUFFIX="$(head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n')"
CONTAINER_NAME="opencode-${DIR_NAME}-${GIT_BRANCH}-${RANDOM_SUFFIX}"
CONTAINER_NAME="$(echo "$CONTAINER_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g')"

# --- Infra container for shared PID/IPC namespace (enables SQLite locking across containers) ---
BUSYBOX_IMAGE="busybox:1.37.0"
INFRA_CONTAINER_NAME="opencode-infra"
STATE_VOLUME_NAME="opencode-agent-state"

# Create named volume for shared OpenCode state if it doesn't exist
if ! docker volume inspect "$STATE_VOLUME_NAME" > /dev/null 2>&1; then
  echo "Creating shared state volume '$STATE_VOLUME_NAME'..."
  docker volume create "$STATE_VOLUME_NAME"
fi

# Start infra container if not already running
if ! docker inspect --format '{{.State.Running}}' "$INFRA_CONTAINER_NAME" 2>/dev/null | grep -q true; then
  # Remove stopped infra container if it exists
  docker rm "$INFRA_CONTAINER_NAME" 2>/dev/null || true
  echo "Starting infra container '$INFRA_CONTAINER_NAME' for shared PID/IPC namespace..."
  docker run -d --rm --init --ipc=shareable \
    --name "$INFRA_CONTAINER_NAME" \
    "$BUSYBOX_IMAGE" \
    sleep infinity
fi

echo "Starting AI Sandbox with OpenCode Agent..."

# --- Credential mounts ---
CREDENTIAL_MOUNTS=""

# Mount GitHub credentials if they exist
if [ -f "$CREDENTIALS_DIR/github/.gitconfig" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/github/.gitconfig:/home/opencode/.gitconfig:ro"
fi

# Read GitHub PAT from .git-credentials and expose as GH_TOKEN for gh CLI
if [ -f "$CREDENTIALS_DIR/github/.git-credentials" ]; then
  GH_TOKEN="$(tr -d '[:space:]' < "$CREDENTIALS_DIR/github/.git-credentials")"
  if [ -n "$GH_TOKEN" ] && [ "$GH_TOKEN" != "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
    CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -e GH_TOKEN=$GH_TOKEN"
  fi
fi

# Mount Gradle credentials if they exist
if [ -f "$CREDENTIALS_DIR/gradle/gradle.properties" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/gradle/gradle.properties:/home/opencode/.gradle/gradle.properties:ro"
fi

# Mount Azure CLI credentials if they exist (user symlinks or copies ~/.azure into this directory)
if [ -d "$CREDENTIALS_DIR/azure" ]; then
  AZURE_DIR="$(realpath "$CREDENTIALS_DIR/azure")"
  echo "Azure mount: -v $AZURE_DIR:/home/opencode/.azure"
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $AZURE_DIR:/home/opencode/.azure"
else
  echo "Azure credentials not found at $CREDENTIALS_DIR/azure (does not exist or is not a directory)"
fi

# Mount host agent skills into ~/.claude/skills/ (avoids overriding image's ~/.agents/skills/)
if [ -d "$HOME/.agents/skills" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $HOME/.agents/skills/:/home/opencode/.claude/skills/:ro"
fi

# Mount host OpenCode skills if directory exists
if [ -d "$HOME/.config/opencode/skills" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $HOME/.config/opencode/skills/:/home/opencode/.config/opencode/skills/:ro"
fi

if [ ! -f "$HOME/.local/share/opencode/auth.json" ]; then
  echo "Error: Missing $HOME/.local/share/opencode/auth.json"
  exit 1
fi

docker run -it --rm --name "$CONTAINER_NAME" \
  --pid="container:$INFRA_CONTAINER_NAME" \
  --ipc="container:$INFRA_CONTAINER_NAME" \
  -u "$(id -u):1000" \
  -v "$STATE_VOLUME_NAME:/home/opencode/.local/share/opencode" \
  -v "$HOME/.local/share/opencode/auth.json:/home/opencode/.local/share/opencode/auth.json:ro" \
  -v "$(pwd):/workspace:delegated" \
  -w "$CONTAINER_WORKDIR" \
  $CREDENTIAL_MOUNTS \
  opencode-agent:latest
