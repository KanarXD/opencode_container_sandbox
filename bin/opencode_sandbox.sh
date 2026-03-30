#!/usr/bin/env bash

echo "Starting AI Sandbox with OpenCode Agent..."

docker run -it --rm \
  -u "$(id -u):1000" \
  -v ~/.local/share/opencode:/home/opencode/.local/share/opencode \
  -v "$(pwd)":/workspace \
  opencode-agent:latest
