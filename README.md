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

## Credentials

The sandbox supports read-only access to private repositories via tokens. Credentials are stored on your host at
`~/.config/opencode-sandbox/` and mounted into the container as read-only volumes at runtime — they are never baked
into the Docker image.

### Supported credential types

| Type | File | Purpose |
|---|---|---|
| GitHub git access | `github/.git-credentials` | Clone/fetch private GitHub repos |
| GitHub API (gh CLI) | `github/.git-credentials` | Read issues, PRs, etc. via `gh` CLI |
| Git config | `github/.gitconfig` | Git credential helper configuration |
| Nexus/Artifactory | `gradle/gradle.properties` | Resolve dependencies from private Maven repos |
| Azure Artifacts | `gradle/gradle.properties` | Resolve dependencies from Azure Artifacts Maven feeds |

### Setup

Running `bash setup.sh` automatically creates template credential files at `~/.config/opencode-sandbox/` if they
don't already exist. Edit them with your actual tokens:

```bash
# GitHub — replace <YOUR_GITHUB_PAT> with a read-only PAT
vim ~/.config/opencode-sandbox/github/.git-credentials

# Gradle repositories — replace placeholders with your credentials
vim ~/.config/opencode-sandbox/gradle/gradle.properties
```

Template files with format examples are also available in the `credentials/` directory of this repository.

### GitHub PAT creation

1. Go to https://github.com/settings/tokens
2. Generate a new token (classic) with `repo` (read) scope
3. Paste it into `~/.config/opencode-sandbox/github/.git-credentials`

### Azure Artifacts PAT creation

1. Go to your Azure DevOps organization → User Settings → Personal Access Tokens
2. Create a token with **Packaging (Read)** scope
3. Paste it into `~/.config/opencode-sandbox/gradle/gradle.properties`

## Troubleshooting

- Make sure you have `~/.local/bin` in your `PATH` environment variable, as the `opencode_sandbox` command is installed
  there.
- If credential mounts fail, ensure the files exist at `~/.config/opencode-sandbox/`. Re-run `bash setup.sh` to
  regenerate templates.
