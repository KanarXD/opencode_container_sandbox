#!/usr/bin/env bash

docker run -it --rm \
  -u "$(id -u):$(id -g)" \
  -v ~/.local/share/opencode:/home/opencode/.local/share/opencode \
  -v "$(pwd)":/workspace \
  opencode-agent "$1"
