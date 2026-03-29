#!/usr/bin/env bash

# Build the Docker image
docker build \
  --build-arg USER_ID="$(id -u)" \
  --build-arg GROUP_ID="$(id -g)" \
  -t opencode-agent ./image

# Create local directories for opencode data and configuration if they don't exist
mkdir -p ~/.local/share/opencode
