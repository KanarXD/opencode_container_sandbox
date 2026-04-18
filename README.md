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

### run the sandbox on a specific Docker network

Use the `-n` flag to attach the container to a Docker network. This is useful
when the sandbox needs to communicate with services running in other containers
on a custom network.

```bash
opencode_sandbox -n my-network
```

The `-n` flag can be combined with a branch name:

```bash
opencode_sandbox -n my-network my-feature
```

### run the sandbox with Docker access

Use the `-d` flag to mount the host's Docker socket into the container, allowing
OpenCode to run Docker commands. Read-only commands (`docker ps`, `docker images`,
`docker logs`, `docker inspect`, etc.) are auto-allowed; all other Docker
commands require user approval before execution.

```bash
opencode_sandbox -d
```

The `-d` flag can be combined with other flags:

```bash
opencode_sandbox -d -n my-network my-feature
```

### run the sandbox on a separate branch (git worktree)

Pass a branch name as an argument to automatically create a
[git worktree](https://git-scm.com/docs/git-worktree) for that branch. The
sandbox container will work inside the worktree, leaving the main branch
untouched.

```bash
opencode_sandbox my-feature
```

This will:

1. Create a new branch `my-feature` from your current HEAD (or reuse it if the
   branch already exists)
2. Create a worktree at `.worktrees/my-feature/` inside the repository
3. Start the container with the working directory set to the worktree

The worktree is preserved after the container exits so you can review changes,
commit, or push from the host. If you run `opencode_sandbox my-feature` again,
the existing worktree is reused.

#### Cleaning up worktrees

```bash
git worktree remove .worktrees/my-feature
# optionally delete the branch too:
git branch -d my-feature
```

To list all active worktrees:

```bash
git worktree list
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

Update `PLAYWRIGHT_CLI_VERSION` in `versions.env` and rebuild with `bash setup.sh`.

## Credentials

The sandbox supports read-only access to private repositories via tokens. Credentials are stored on your host at
`~/.config/opencode-sandbox/` and mounted into the container as read-only volumes at runtime — they are never baked
into the Docker image.

### Supported credential types

| Type | File | Purpose |
|---|---|---|
| GitHub PAT | `github/.git-credentials` | Read at startup and passed as `GH_TOKEN` env var (file itself is not mounted) |
| Git config | `github/.gitconfig` | Git credential helper configuration |
| Nexus/Artifactory | `gradle/gradle.properties` | Resolve dependencies from private Maven repos |
| Azure Artifacts | `gradle/gradle.properties` | Resolve dependencies from Azure Artifacts Maven feeds |
| Azure CLI | `azure/` | Symlink to `~/.azure/` for `az` CLI access to Azure resources (mounted read-write so the CLI can refresh token caches) |

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

Symlinks your Azure login session into the sandbox for access to Azure resources (Monitor, Insights, Log
Analytics, etc.):

```bash
ln -sf ~/.azure ~/.config/opencode-sandbox/azure
```

If you haven't authenticated yet, run `az login` on your host first.

Alternatively, create the directory and copy only specific files (e.g., `azureProfile.json` and `msal_token_cache.json`)
if you prefer not to expose the entire `~/.azure/` directory:

```bash
mkdir -p ~/.config/opencode-sandbox/azure
cp ~/.azure/azureProfile.json ~/.azure/msal_token_cache.json ~/.config/opencode-sandbox/azure/
```

## Shared State

The sandbox maintains its own state directory at `~/.local/share/opencode-sandbox/` on the host, **separate** from the
host's OpenCode state at `~/.local/share/opencode/`. Sessions, history, and other OpenCode data created inside the
sandbox do not interfere with your host installation and vice versa.

This directory is mounted into every container, so state persists across container restarts. When multiple sandbox
containers run concurrently, they share this directory. A long-lived infra container (`opencode-infra`) provides shared
PID and IPC namespaces to ensure correct SQLite locking between containers.

Only `auth.json` is taken from the host's OpenCode installation (`~/.local/share/opencode/auth.json`), and it is mounted
read-only.

## Troubleshooting

- Make sure you have `~/.local/bin` in your `PATH` environment variable, as the `opencode_sandbox` command is installed
  there.
- If credential mounts fail, ensure the files exist at `~/.config/opencode-sandbox/`. Re-run `bash setup.sh` to
  regenerate templates.
