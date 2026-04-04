#!/usr/bin/env bash

echo "Starting AI Sandbox with OpenCode Agent..."

CREDENTIALS_DIR="$HOME/.config/opencode-sandbox"

CREDENTIAL_MOUNTS=""

# Mount GitHub credentials if they exist
if [ -f "$CREDENTIALS_DIR/github/.gitconfig" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/github/.gitconfig:/home/opencode/.gitconfig:ro"
fi

if [ -f "$CREDENTIALS_DIR/github/.git-credentials" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/github/.git-credentials:/home/opencode/.git-credentials:ro"
fi

# Mount Gradle credentials if they exist
if [ -f "$CREDENTIALS_DIR/gradle/gradle.properties" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/gradle/gradle.properties:/home/opencode/.gradle/gradle.properties:ro"
fi

if [ ! -f "$HOME/.local/share/opencode/auth.json" ]; then
  echo "Error: Missing $HOME/.local/share/opencode/auth.json"
  exit 1
fi

docker run -it --rm \
  -u "$(id -u):1000" \
  -v "$HOME/.local/share/opencode/auth.json:/home/opencode/.local/share/opencode/auth.json:ro" \
  -v ~/.agents/:/home/opencode/.agents \
  -v "$(pwd)":/workspace \
  $CREDENTIAL_MOUNTS \
  opencode-agent:latest
