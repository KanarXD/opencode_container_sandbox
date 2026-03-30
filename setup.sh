#!/usr/bin/env bash

# Build the Docker image
docker build \
  --build-arg USER_ID="$(id -u)" \
  -t opencode-agent ./image

# Create local directories for opencode data and configuration if they don't exist
mkdir -p ~/.local/share/opencode

chmod u+x ./bin/opencode_sandbox.sh
ln -sfn "$(pwd)/bin/opencode_sandbox.sh" ~/.local/bin/opencode_sandbox
