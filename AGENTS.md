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
  .config/opencode/          #   OpenCode runtime config (opencode.json)
  Dockerfile                 #   Debian-based image with Java, Node, gh, Chromium
setup.sh                     # One-time setup: builds image, creates credentials
```

## Build / Setup Commands

### Build the Docker image and install the CLI

```bash
bash setup.sh
```

This script:
1. Builds the Docker image tagged `opencode-agent` from `image/Dockerfile`
2. Creates credential template files at `~/.config/opencode-sandbox/`
3. Symlinks `bin/opencode_sandbox.sh` to `~/.local/bin/opencode_sandbox`

### Build the Docker image only

```bash
docker build --build-arg USER_ID="$(id -u)" -t opencode-agent ./image
```

### Run the sandbox

```bash
opencode_sandbox
# or directly:
bash bin/opencode_sandbox.sh
```

## Testing

There is no automated test suite. This is a Bash/Docker infrastructure project.
To verify changes:

1. **Dockerfile changes**: Rebuild the image and confirm it starts correctly.
   ```bash
   docker build --build-arg USER_ID="$(id -u)" -t opencode-agent ./image
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

- Pin versions via `ARG` at the top of the file
  (`DEBIAN_VERSION`, `OPENCODE_VERSION`, `JAVA_VERSION`).
- Minimize layers: combine related `apt-get` commands into single `RUN`
  instructions and always end with `apt-get clean`.
- Use the non-root user pattern: create a user matching the host UID/GID.
- Use `COPY --chown` for correct file ownership.
- Never bake secrets or credentials into the image.

### Security Conventions

- **Credentials are never baked into the Docker image.** They are mounted as
  read-only volumes (`:ro`) at container runtime.
- Credential files must have restricted permissions (`chmod 600`).
- The OpenCode config (`image/.config/opencode/opencode.json`) explicitly
  denies `git push*` and `git commit*` to prevent accidental pushes from the
  sandbox.

### Configuration (opencode.json)

The runtime config lives at `image/.config/opencode/opencode.json`. Key settings:
- Provider: `github-copilot` only
- Model: `github-copilot/claude-opus-4.6`
- Permissions: all tools allowed (`"*": "allow"`) except `git push` and
  `git commit` in bash (denied)
- Sharing: disabled

## Key Files to Know

| File | Purpose |
|---|---|
| `setup.sh` | Main setup script — build image, create creds, install CLI |
| `bin/opencode_sandbox.sh` | Runtime launcher — mounts volumes, runs container |
| `image/Dockerfile` | Docker image definition (Debian + Java + Node + tools) |
| `image/.config/opencode/opencode.json` | OpenCode agent configuration |
| `credentials/` | Template files for GitHub/Gradle credentials |

## Common Modification Scenarios

### Adding a new tool to the Docker image

Edit `image/Dockerfile`. Add the package to the existing `apt-get install` line
or add a new `RUN` block. Pin versions via `ARG` when possible. Rebuild with
`bash setup.sh`.

### Adding a new credential type

1. Create an example template in `credentials/<type>/`
2. Add directory creation and file copy logic in `setup.sh`
3. Add the volume mount in `bin/opencode_sandbox.sh`
4. Document it in `README.md` under the credentials table

### Changing the OpenCode version

Update the `OPENCODE_VERSION` ARG in `image/Dockerfile` and rebuild.

### Changing the Java version

Update the `JAVA_VERSION` ARG in `image/Dockerfile` and rebuild.

## Git Workflow

- No CI/CD pipeline is configured.
- No branch protection or PR rules.
- The `.gitignore` excludes `.idea/` (JetBrains IDE files).
- Commit messages should be clear and descriptive of what changed and why.
