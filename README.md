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

### run the sandbox with Azure CLI access

Use the `-a` flag to mount your Azure CLI credentials into the container,
allowing OpenCode to run `az` commands. Without this flag, Azure credentials
are not mounted even if they exist on the host.

```bash
opencode_sandbox -a
```

The `-a` flag can be combined with other flags:

```bash
opencode_sandbox -a -d -n my-network my-feature
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

### mount additional directories into the container

Use the `-v` flag to mount a host directory into the container at
`/volumes/<basename>`. This is useful when the sandbox needs access to files
outside the current repository (e.g., shared libraries, configuration, or other
projects).

```bash
opencode_sandbox -v ./some/path/app
```

This resolves the path to an absolute path on the host and mounts it at
`/volumes/app` inside the container. The flag is repeatable:

```bash
opencode_sandbox -v /opt/shared-libs -v ../other-project
```

If multiple paths share the same basename, a numeric suffix is appended
automatically (e.g., `/volumes/app`, `/volumes/app-2`).

The `-v` flag can be combined with other flags:

```bash
opencode_sandbox -v ./libs -d -n my-network my-feature
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

## Desktop Applications

The sandbox can run desktop GUI applications (e.g., Rust Bevy, Java Swing, GTK)
headlessly using a virtual X11 display and software Vulkan rendering. OpenCode
can take screenshots of the running app and interact with it via synthetic mouse
clicks and keyboard input.

### How it works

- **Xvfb** provides a virtual X11 framebuffer — no physical display or GPU needed
- **Mesa lavapipe** provides a CPU-based Vulkan implementation for wgpu/Bevy apps
- **xdotool** sends mouse clicks and keyboard input to the running app
- **ImageMagick** (`import`) captures screenshots of the virtual display

### Included dependencies

Bevy and other GUI frameworks require various system libraries that are
pre-installed in the image:

- X11 development libraries (`libx11-dev`, `libxcursor-dev`, `libxrandr-dev`,
  `libxi-dev`, `libxinerama-dev`)
- ALSA audio (`libasound2-dev`)
- udev input (`libudev-dev`)

## Cargo Target Directory

The Docker image sets `CARGO_TARGET_DIR=target-container` so that Cargo builds inside the container use
`target-container/` instead of the default `target/`. This prevents Cargo fingerprint conflicts between host and
container — different `rustc` binary paths/hashes cause mutual cache invalidation when sharing the same target
directory.

The launcher script automatically adds `target-container/` to `.git/info/exclude` (local-only, no repo changes) so
it doesn't appear as untracked. Multiple containers from the same image can safely share `target-container/` since
they use the same `rustc` binary.

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
Analytics, etc.). Azure credentials are only mounted when the `-a` flag is passed to `opencode_sandbox`:

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
