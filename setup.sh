#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CREDENTIALS_DIR="$HOME/.config/opencode-sandbox"
VERSIONS_FILE="$SCRIPT_DIR/versions.env"

if [ ! -f "$VERSIONS_FILE" ]; then
  echo "Error: $VERSIONS_FILE not found"
  exit 1
fi

# Read versions.env and build --build-arg flags dynamically
BUILD_ARGS=(--build-arg "USER_ID=$(id -u)")
while IFS='=' read -r KEY VALUE; do
  [[ -z "$KEY" || "$KEY" == \#* ]] && continue
  BUILD_ARGS+=(--build-arg "${KEY}=${VALUE}")
done < "$VERSIONS_FILE"

# Build the Docker image
docker build \
  "${BUILD_ARGS[@]}" \
  -t opencode-agent ./image

# Create local directories for opencode data and configuration if they don't exist
mkdir -p ~/.local/share/opencode

# Create credential directories
mkdir -p "$CREDENTIALS_DIR/github"
mkdir -p "$CREDENTIALS_DIR/gradle"

# Copy example credential files if actual files don't exist yet
if [ ! -f "$CREDENTIALS_DIR/github/.gitconfig" ]; then
  cp "$SCRIPT_DIR/credentials/github/.gitconfig.example" "$CREDENTIALS_DIR/github/.gitconfig"
  echo "Created $CREDENTIALS_DIR/github/.gitconfig — please edit with your settings"
fi

if [ ! -f "$CREDENTIALS_DIR/github/.git-credentials" ]; then
  cp "$SCRIPT_DIR/credentials/github/.git-credentials.example" "$CREDENTIALS_DIR/github/.git-credentials"
  chmod 600 "$CREDENTIALS_DIR/github/.git-credentials"
  echo "Created $CREDENTIALS_DIR/github/.git-credentials — paste your GitHub classic PAT (https://github.com/settings/tokens) as the sole content"
fi

if [ ! -f "$CREDENTIALS_DIR/gradle/gradle.properties" ]; then
  cp "$SCRIPT_DIR/credentials/gradle/gradle.properties.example" "$CREDENTIALS_DIR/gradle/gradle.properties"
  chmod 600 "$CREDENTIALS_DIR/gradle/gradle.properties"
  echo "Created $CREDENTIALS_DIR/gradle/gradle.properties — please edit with your repository tokens"
fi

chmod u+x ./bin/opencode_sandbox.sh
ln -sfn "$(pwd)/bin/opencode_sandbox.sh" ~/.local/bin/opencode_sandbox

echo ""
echo "Setup complete!"
echo "Credential files are stored in: $CREDENTIALS_DIR"
echo "Edit them with your tokens before running opencode_sandbox."
