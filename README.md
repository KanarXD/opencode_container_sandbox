# OpenCode docker sandbox

## Description

This repository provides a Docker-based sandbox environment for OpenCode, allowing developers to easily set up and test
their code in an isolated environment. The sandbox includes all necessary dependencies and tools to run OpenCode
applications without affecting the host system.

OpenCode has access to your copilot authorization, so you can use all your models and features in the sandbox
environment.

## Usage

### setup docker image and cli

```bash
bash setup.sh
```

### run the opencode sandbox inside current directory

```bash
opencode_sandbox
```

## Troubleshooting

- Make sure you have `~/.local/bin` in your `PATH` environment variable, as the `opencode_sandbox` command is installed
  there.
