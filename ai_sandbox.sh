#!/usr/bin/env bash

docker run -it --rm \
  -u "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace \
  opencode-agent $1

#  -v ~/.local/share/opencode:/home/opencode/.local/share/opencode \
#  -v ~/.config/opencode:/home/opencode/.config/opencode \
