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

Running `bash setup.sh` automatically creates template credential files at `~/.config/opencode-sandbox/` if they
don't already exist. Edit them with your actual tokens:

```bash
# GitHub — paste your classic PAT (token only, no URL)
vim ~/.config/opencode-sandbox/github/.git-credentials

# Gradle repositories — replace placeholders with your credentials
vim ~/.config/opencode-sandbox/gradle/gradle.properties
```

Template files with format examples are also available in the `credentials/` directory of this repository.

### GitHub PAT creation

1. Go to https://github.com/settings/tokens
2. Generate a new token (classic) with `repo` scope
3. Paste the token as the sole content of `~/.config/opencode-sandbox/github/.git-credentials`

### Azure Artifacts PAT creation

1. Go to your Azure DevOps organization → User Settings → Personal Access Tokens
2. Create a token with **Packaging (Read)** scope
3. Paste it into `~/.config/opencode-sandbox/gradle/gradle.properties`

### Azure CLI access

The sandbox can mount Azure CLI credentials read-only so the `az` CLI inside the container can reuse your existing
login session. Credentials are read from `~/.config/opencode-sandbox/azure/`, consistent with all other credential
types.

**Setup:**

1. Install the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) on your host
2. Run `az login` on your host to authenticate
3. Symlink your Azure config into the sandbox credentials directory:
   ```bash
   ln -s ~/.azure ~/.config/opencode-sandbox/azure
   ```
   Alternatively, copy only the files you need (e.g., `azureProfile.json` and `msal_token_cache.json`) into
   `~/.config/opencode-sandbox/azure/` if you prefer not to expose the entire `~/.azure/` directory.
4. Start the sandbox — your Azure session is automatically available

The container can run read-only commands such as:

```bash
az monitor app-insights query --app <app-id> --analytics-query "requests | take 10"
az monitor log-analytics query --workspace <workspace-id> --analytics-query "AzureActivity | take 10"
```

**Read-only enforcement:**

- The `azure/` directory is mounted read-only (`:ro`), preventing the container from modifying your token cache
- Destructive `az` commands (`create`, `delete`, `update`, `start`, `stop`, `restart`) are denied in the OpenCode
  configuration
- For additional protection, assign a read-only Azure role (e.g., **Monitoring Reader**) to your identity via Azure RBAC

**Note:** Since the mount is read-only, the `az` CLI inside the container cannot refresh expired tokens. If your session
expires (typically after ~1 hour), re-run `az login` on your host and restart the sandbox.

## Troubleshooting

- Make sure you have `~/.local/bin` in your `PATH` environment variable, as the `opencode_sandbox` command is installed
  there.
- If credential mounts fail, ensure the files exist at `~/.config/opencode-sandbox/`. Re-run `bash setup.sh` to
  regenerate templates.
