#!/usr/bin/env bash

echo "Starting AI Sandbox with OpenCode Agent..."

CREDENTIALS_DIR="$HOME/.config/opencode-sandbox"

CREDENTIAL_MOUNTS=""

# Mount GitHub credentials if they exist
if [ -f "$CREDENTIALS_DIR/github/.gitconfig" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/github/.gitconfig:/home/opencode/.gitconfig:ro"
fi

# Read GitHub PAT from .git-credentials and expose as GH_TOKEN for gh CLI
if [ -f "$CREDENTIALS_DIR/github/.git-credentials" ]; then
  GH_TOKEN="$(cat "$CREDENTIALS_DIR/github/.git-credentials")"
  if [ -n "$GH_TOKEN" ]; then
    CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -e GH_TOKEN=$GH_TOKEN"
  fi
fi

# Mount Gradle credentials if they exist
if [ -f "$CREDENTIALS_DIR/gradle/gradle.properties" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/gradle/gradle.properties:/home/opencode/.gradle/gradle.properties:ro"
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

docker run -it --rm \
  -u "$(id -u):1000" \
  -v "$HOME/.local/share/opencode/auth.json:/home/opencode/.local/share/opencode/auth.json:ro" \
  -v "$(pwd):/workspace" \
  $CREDENTIAL_MOUNTS \
  opencode-agent:latest
