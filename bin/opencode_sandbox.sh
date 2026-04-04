#!/usr/bin/env bash

echo "Starting AI Sandbox with OpenCode Agent..."

CREDENTIALS_DIR="$HOME/.config/opencode-sandbox"

CREDENTIAL_MOUNTS=""
GH_TOKEN_FLAG=""

# Mount GitHub credentials if they exist
if [ -f "$CREDENTIALS_DIR/github/.gitconfig" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/github/.gitconfig:/home/opencode/.gitconfig:ro"
fi

if [ -f "$CREDENTIALS_DIR/github/.git-credentials" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/github/.git-credentials:/home/opencode/.git-credentials:ro"

  # Extract GitHub PAT from .git-credentials for gh CLI authentication
  GH_TOKEN=$(grep 'github\.com' "$CREDENTIALS_DIR/github/.git-credentials" | sed -n 's|.*://oauth2:\(.*\)@github\.com.*|\1|p' | head -1)
  if [ -n "$GH_TOKEN" ]; then
    GH_TOKEN_FLAG="-e GH_TOKEN=$GH_TOKEN"
  fi
fi

# Mount Gradle credentials if they exist
if [ -f "$CREDENTIALS_DIR/gradle/gradle.properties" ]; then
  CREDENTIAL_MOUNTS="$CREDENTIAL_MOUNTS -v $CREDENTIALS_DIR/gradle/gradle.properties:/home/opencode/.gradle/gradle.properties:ro"
fi

docker run -it --rm \
  -u "$(id -u):1000" \
  -v ~/.local/share/opencode:/home/opencode/.local/share/opencode \
  -v ~/.agents/:/home/opencode/.agents \
  -v "$(pwd)":/workspace \
  $CREDENTIAL_MOUNTS \
  $GH_TOKEN_FLAG \
  opencode-agent:latest
