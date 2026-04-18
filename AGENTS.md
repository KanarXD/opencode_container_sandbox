# AGENTS.md

## Project Overview

This is **OpenCode Docker Sandbox** — an infrastructure project that provides a
Docker-based isolated environment for running the OpenCode AI coding agent. The
project consists entirely of Bash scripts, a Dockerfile, and configuration files.
There is no application source code in a compiled or interpreted language.

## Project Structure

```
bin/                         # CLI entrypoint script (opencode_sandbox.sh)
credentials/                 # Example credential templates
  github/                   #   GitHub PAT and gitconfig examples
  gradle/                   #   Gradle/Maven repository credential examples
image/                       # Docker image definition
  .config/opencode/          #   OpenCode runtime config and container AGENTS.md
    opencode.json            #     OpenCode agent configuration
    AGENTS.md                #     Container-side agent instructions
  Dockerfile                 #   Debian-based image with Java, Node, Gradle, Angular CLI, gh, Azure CLI, Chromium, Playwright CLI
versions.env                 # Pinned tool/base image versions (single source of truth)
setup.sh                     # One-time setup: builds image, creates credentials
.gitignore                   # Excludes .idea/ (JetBrains IDE files)
README.md                    # Project documentation
```

## Build / Setup Commands

### Build the Docker image and install the CLI

```bash
bash setup.sh
```

This script:
1. Builds the Docker image tagged `opencode-agent` from `image/Dockerfile`
2. Creates `~/.local/share/opencode/` for OpenCode auth data
3. Creates credential template files at `~/.config/opencode-sandbox/`
   (including `github/` and `gradle/` subdirectories; Azure credentials are
   handled separately — the user symlinks `~/.azure` into the directory)
4. Symlinks `bin/opencode_sandbox.sh` to `~/.local/bin/opencode_sandbox`
5. Adds `~/.local/bin` to `PATH` in the user's shell RC file if not already present

### Build the Docker image only

All version arguments are defined in `versions.env` and passed automatically by
`setup.sh`. To build manually, source the versions file and pass `--build-arg`
values directly:

```bash
source versions.env
docker build \
  --build-arg USER_ID="$(id -u)" \
  --build-arg DEBIAN_VERSION="$DEBIAN_VERSION" \
  --build-arg JAVA_VERSION="$JAVA_VERSION" \
  --build-arg TERRAFORM_VERSION="$TERRAFORM_VERSION" \
  --build-arg GRADLE_VERSION="$GRADLE_VERSION" \
  --build-arg ANGULAR_CLI_VERSION="$ANGULAR_CLI_VERSION" \
  --build-arg AZURE_CLI_VERSION="$AZURE_CLI_VERSION" \
  --build-arg OPENCODE_VERSION="$OPENCODE_VERSION" \
  --build-arg PLAYWRIGHT_CLI_VERSION="$PLAYWRIGHT_CLI_VERSION" \
  -t opencode-agent ./image
```

### Run the sandbox

```bash
opencode_sandbox
# or directly:
bash bin/opencode_sandbox.sh
```

### Run the sandbox on a separate branch (git worktree)

```bash
opencode_sandbox my-feature
# or directly:
bash bin/opencode_sandbox.sh my-feature
```

This creates a git worktree at `.worktrees/my-feature/` inside the repository
and starts the container with its working directory set to the worktree. The
main branch is left untouched. The worktree is preserved after the container
exits. Running the same command again reuses the existing worktree.

Clean up with: `git worktree remove .worktrees/my-feature`

## Runtime Architecture

### Infra container and shared namespaces

When the sandbox starts, it launches (or reuses) a long-lived **infra container**
(`opencode-infra`) based on `busybox`. The agent container joins this infra
container's PID and IPC namespaces (`--pid=container:opencode-infra`,
`--ipc=container:opencode-infra`). This enables SQLite locking to work correctly
across multiple concurrent sandbox containers sharing the same state directory.

### Shared state directory

A host directory `~/.local/share/opencode-sandbox/` is bind-mounted at
`/home/opencode/.local/share/opencode` inside every container. This persists
OpenCode state (sessions, history, etc.) across container restarts and survives
Docker uninstallation. The user's `auth.json` is mounted read-only on top of
this directory from the host.

### Prerequisites

- `~/.local/share/opencode/auth.json` must exist before running the sandbox.
  The script exits with an error if this file is missing. Authenticate with
  OpenCode on the host first, or copy a valid `auth.json` into place.

### Container naming

Containers are named `opencode-<dir>-<branch>-<random>`, where `<dir>` is the
current directory basename, `<branch>` is the git branch (or `nobranch`), and
`<random>` is 4 random hex bytes. The name is lowercased and sanitised for
Docker compatibility.

### Host skills mounting

The launcher mounts host-side skill directories into the container if they exist:
- `~/.agents/skills/` → `/home/opencode/.claude/skills/` (read-only)
- `~/.config/opencode/skills/` → `/home/opencode/.config/opencode/skills/` (read-only)

## Testing

There is no automated test suite. This is a Bash/Docker infrastructure project.
To verify changes:

1. **Dockerfile changes**: Rebuild the image and confirm it starts correctly.
   ```bash
   bash setup.sh
   docker run -it --rm opencode-agent:latest bash -c "echo ok"
   ```
2. **Script changes**: Run `bash -n <script>` for syntax checking, then test manually.
   ```bash
   bash -n setup.sh
   bash -n bin/opencode_sandbox.sh
   ```
3. **ShellCheck** (if available): `shellcheck setup.sh bin/opencode_sandbox.sh`

## Linting / Formatting

No linting or formatting tools are configured. If adding shell linting, use
[ShellCheck](https://www.shellcheck.net/).

## Code Style Guidelines

### Bash Scripts

- **Shebang**: Always use `#!/usr/bin/env bash` (portable form).
- **Error handling**: Use `set -e` at the top of setup/build scripts to exit on
  first error. For runtime scripts, use explicit checks with informative error
  messages and `exit 1`.
- **Variable naming**: `UPPER_SNAKE_CASE` for all variables
  (e.g., `SCRIPT_DIR`, `CREDENTIALS_DIR`, `CREDENTIAL_MOUNTS`).
- **Variable quoting**: Always double-quote variables and command substitutions
  (`"$HOME"`, `"$(pwd)"`). This prevents word splitting on paths with spaces.
- **Comments**: Use `#` with a single space. Describe intent/purpose, not
  mechanics (e.g., `# Mount GitHub credentials if they exist`).
- **User-facing output**: Use `echo` for informational messages. Include the
  relevant file path in error messages for debuggability.

### Dockerfile

- Declare version `ARG`s without defaults — all versions are supplied via
  `versions.env` and passed as `--build-arg` by `setup.sh`.
- Minimize layers: combine related `apt-get` commands into single `RUN`
  instructions and always end with `apt-get clean`.
- Use the non-root user pattern: create a user matching the host UID/GID.
- Use `COPY --chown` for correct file ownership.
- Never bake secrets or credentials into the image.

### Security Conventions

- **Credentials are never baked into the Docker image.** They are mounted as
  read-only volumes (`:ro`) at container runtime, except for Azure credentials
  which are mounted read-write (the Azure CLI needs to update token caches).
- Credential files must have restricted permissions (`chmod 600`).
- The OpenCode config (`image/.config/opencode/opencode.json`) explicitly
  denies `git push*` and destructive Azure CLI commands (`az * create`,
  `az * delete`, `az login`, etc.) to prevent accidental pushes and
  infrastructure changes from the sandbox.

### Configuration (opencode.json)

The runtime config lives at `image/.config/opencode/opencode.json`. Key settings:
- Provider: `github-copilot` only
- Model: `github-copilot/claude-opus-4.6`
- Permissions: all tools allowed (`"*": "allow"`) except `git push*` and
  destructive Azure CLI commands (`az * create/delete/update/start/stop/restart`,
  `az * set-policy`, `az login`, `az logout`) in bash (denied)
- Sharing: disabled

## Key Files to Know

| File | Purpose |
|---|---|
| `setup.sh` | Main setup script — build image, create creds, install CLI |
| `bin/opencode_sandbox.sh` | Runtime launcher — mounts volumes, runs container |
| `image/Dockerfile` | Docker image definition (Debian + Java + Node + Gradle + Angular CLI + Terraform + Azure CLI + tools) |
| `image/.config/opencode/opencode.json` | OpenCode agent configuration |
| `versions.env` | Pinned tool/base image versions (single source of truth) |
| `credentials/` | Template files for GitHub/Gradle credentials |
| `README.md` | Project documentation |

## Common Modification Scenarios

### Browser Automation (Playwright CLI)

The Docker image includes `playwright-cli` (`@playwright/cli`) for browser
automation. OpenCode discovers it automatically via the `playwright-cli` skill
(installed at `~/.agents/skills/playwright-cli/SKILL.md`).

- Runs headless Chromium inside the container (no display server needed).
- Configured via environment variables: `PLAYWRIGHT_MCP_HEADLESS`,
  `PLAYWRIGHT_MCP_NO_SANDBOX`, `PLAYWRIGHT_MCP_BROWSER`,
  `PLAYWRIGHT_MCP_EXECUTABLE_PATH`, `PLAYWRIGHT_MCP_OUTPUT_DIR`.
- Use `playwright-cli open <url>` to start a browser session.
- Use `playwright-cli snapshot` to inspect page state (preferred over screenshots).
- Use `playwright-cli click <ref>` to interact with elements from the snapshot.
- The version is pinned via `PLAYWRIGHT_CLI_VERSION` ARG in the Dockerfile.

### Adding a new tool to the Docker image

1. Add a version variable to `versions.env`
2. Add a matching `ARG` declaration (without default) and `RUN` install block
   in `image/Dockerfile`
3. Rebuild with `bash setup.sh`

### Adding a new credential type

1. Create an example template in `credentials/<type>/`
2. Add directory creation and file copy logic in `setup.sh`
3. Add the volume mount in `bin/opencode_sandbox.sh`
4. Document it in `README.md` under the credentials table

### Changing the OpenCode version

Update the `OPENCODE_VERSION` in `versions.env` and rebuild.

### Changing the Java version

Update the `JAVA_VERSION` in `versions.env` and rebuild.

### Changing any pinned tool version

All tool and base image versions are defined in `versions.env`. Update the
relevant variable and rebuild with `bash setup.sh`. Available variables:
`DEBIAN_VERSION`, `JAVA_VERSION`, `TERRAFORM_VERSION`, `GRADLE_VERSION`,
`ANGULAR_CLI_VERSION`, `AZURE_CLI_VERSION`, `OPENCODE_VERSION`,
`PLAYWRIGHT_CLI_VERSION`.

## Git Workflow

- No CI/CD pipeline is configured.
- No branch protection or PR rules.
- The `.gitignore` excludes `.idea/` (JetBrains IDE files).
- Commit messages should be clear and descriptive of what changed and why.
