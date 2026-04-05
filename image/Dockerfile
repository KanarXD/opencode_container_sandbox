ARG DEBIAN_VERSION=13.4
ARG JAVA_VERSION=21
ARG TERRAFORM_VERSION=1.12.0
ARG PLAYWRIGHT_CLI_VERSION=0.1.5

FROM debian:${DEBIAN_VERSION}

ARG JAVA_VERSION
ARG TERRAFORM_VERSION

# Install basic tools and configurable Java version
RUN apt-get update && apt-get install -y npm git curl openjdk-${JAVA_VERSION}-jdk chromium && apt-get clean

ENV JAVA_HOME=/etc/alternatives/java_home
ENV PATH=${JAVA_HOME}/bin:${PATH}
ENV CHROME_BIN=/usr/bin/chromium

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && apt-get clean

# Install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_$(dpkg --print-architecture).zip \
      -o /tmp/terraform.zip && \
    apt-get update && apt-get install -y unzip && apt-get clean && \
    unzip /tmp/terraform.zip -d /usr/local/bin/ && \
    rm /tmp/terraform.zip

# Install OpenCode globally (placed late to maximize layer caching when version changes)
ARG OPENCODE_VERSION=1.3.15
RUN npm install -g opencode-ai@${OPENCODE_VERSION}

# Install Playwright CLI globally and Chromium browser with system dependencies
ARG PLAYWRIGHT_CLI_VERSION
RUN npm install -g @playwright/cli@${PLAYWRIGHT_CLI_VERSION} && \
    npx playwright install --with-deps chromium

# Playwright CLI configuration for headless Docker environment
ENV PLAYWRIGHT_MCP_HEADLESS=true
ENV PLAYWRIGHT_MCP_NO_SANDBOX=true
ENV PLAYWRIGHT_MCP_BROWSER=chromium

# Create a non-root user to match your host
ARG GROUP_ID=1000
ARG USER_ID
RUN groupadd -g ${GROUP_ID} opencode && \
    useradd -u ${USER_ID} -g opencode -m opencode

USER opencode

WORKDIR /home/opencode

# Create necessary directories for OpenCode configuration
RUN mkdir -p ~/.local/share/opencode ~/.agents ~/.gradle

# Install Playwright CLI skill files to ~/.agents/skills/playwright-cli/
RUN playwright-cli install --skills=agents

# Copy the configuration file to the container
COPY --chown=${USER_ID}:${GROUP_ID} .config /home/opencode/.config

WORKDIR /workspace

ENTRYPOINT ["opencode"]