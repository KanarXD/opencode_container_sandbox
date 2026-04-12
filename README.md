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

## Browser Automation

The sandbox includes [Playwright CLI](https://github.com/microsoft/playwright-cli)
(`@playwright/cli`), which gives OpenCode the ability to see and interact with web
pages. OpenCode discovers this capability automatically via the built-in
`playwright-cli` skill.

- Runs headless Chromium inside the container (no display server required)
- OpenCode can open URLs, inspect page structure, click elements, fill forms,
  take screenshots, and more
- Useful for testing web applications, verifying UI changes, and debugging
  frontend issues

### Changing the Playwright CLI version

Update the `PLAYWRIGHT_CLI_VERSION` ARG in `image/Dockerfile` and rebuild.

## Credentials

The sandbox supports read-only access to private repositories via tokens. Credentials are stored on your host at
`~/.config/opencode-sandbox/` and mounted into the container as read-only volumes at runtime — they are never baked
into the Docker image.

### Supported credential types

| Type | File | Purpose |
|---|---|---|
| GitHub PAT | `github/.git-credentials` | Passed as `GH_TOKEN` env var for `gh` CLI authentication |
| Git config | `github/.gitconfig` | Git credential helper configuration |
| Nexus/Artifactory | `gradle/gradle.properties` | Resolve dependencies from private Maven repos |
| Azure Artifacts | `gradle/gradle.properties` | Resolve dependencies from Azure Artifacts Maven feeds |
| Azure CLI | `azure/` | Symlink to `~/.azure/` for read-only `az` CLI access to Azure resources |

### Setup

Running `bash setup.sh` creates template credential files at `~/.config/opencode-sandbox/`. Copy your existing host
credentials into the sandbox with the commands below.

#### Git config

Copies your git identity (user.name, user.email, etc.) into the sandbox:

```bash
cp ~/.gitconfig ~/.config/opencode-sandbox/github/.gitconfig
```

#### GitHub PAT

Exports your existing `gh` CLI token for use inside the sandbox:

```bash
gh auth token > ~/.config/opencode-sandbox/github/.git-credentials
```

If you don't have `gh` installed, create a token manually at https://github.com/settings/tokens (classic token with
`repo` scope) and paste it as the sole content of `~/.config/opencode-sandbox/github/.git-credentials`.

#### Gradle / Maven repository credentials

Copies your Gradle properties (Nexus, Artifactory, or Azure Artifacts tokens) into the sandbox:

```bash
cp ~/.gradle/gradle.properties ~/.config/opencode-sandbox/gradle/gradle.properties
```

For Azure Artifacts specifically, the token needs **Packaging (Read)** scope. Create one at your Azure DevOps
organization → User Settings → Personal Access Tokens.

#### Azure CLI

Symlinks your Azure login session into the sandbox for read-only access to Azure resources (Monitor, Insights, Log
Analytics, etc.):

```bash
ln -sf ~/.azure ~/.config/opencode-sandbox/azure
```

If you haven't authenticated yet, run `az login` on your host first.

Alternatively, copy only specific files (e.g., `azureProfile.json` and `msal_token_cache.json`) into
`~/.config/opencode-sandbox/azure/` if you prefer not to expose the entire `~/.azure/` directory.

## Troubleshooting

- Make sure you have `~/.local/bin` in your `PATH` environment variable, as the `opencode_sandbox` command is installed
  there.
- If credential mounts fail, ensure the files exist at `~/.config/opencode-sandbox/`. Re-run `bash setup.sh` to
  regenerate templates.
