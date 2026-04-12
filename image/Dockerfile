ARG DEBIAN_VERSION

FROM debian:${DEBIAN_VERSION}

ARG JAVA_VERSION
ARG TERRAFORM_VERSION

# Install basic tools and configurable Java version
RUN apt-get update && apt-get install -y npm git curl gpg openjdk-${JAVA_VERSION}-jdk chromium && apt-get clean

RUN ln -s /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-$(dpkg --print-architecture) /usr/lib/jvm/java-openjdk && \
    rm -rf /usr/lib/jvm/openjdk-${JAVA_VERSION}
ENV JAVA_HOME=/usr/lib/jvm/java-openjdk
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

# Install Azure CLI
ARG AZURE_CLI_VERSION
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ bookworm main" \
      > /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && apt-get install -y azure-cli=${AZURE_CLI_VERSION}-1~bookworm && apt-get clean

# Install Gradle
ARG GRADLE_VERSION
RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
      -o /tmp/gradle.zip && \
    unzip /tmp/gradle.zip -d /opt/ && \
    ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle.zip
ENV GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}

# Install OpenCode globally (placed late to maximize layer caching when version changes)
ARG OPENCODE_VERSION
RUN npm install -g opencode-ai@${OPENCODE_VERSION}

# Install Angular CLI globally
ARG ANGULAR_CLI_VERSION
RUN npm install -g @angular/cli@${ANGULAR_CLI_VERSION}

# Install Playwright CLI globally and Chromium browser with system dependencies
ARG PLAYWRIGHT_CLI_VERSION
RUN npm install -g @playwright/cli@${PLAYWRIGHT_CLI_VERSION} && \
    npx playwright install --with-deps chromium

# Playwright CLI configuration for headless Docker environment
ENV PLAYWRIGHT_MCP_HEADLESS=true
ENV PLAYWRIGHT_MCP_NO_SANDBOX=true
ENV PLAYWRIGHT_MCP_BROWSER=chromium
ENV PLAYWRIGHT_MCP_OUTPUT_DIR=/tmp/playwright-output

# Create a non-root user to match your host
ARG GROUP_ID=1000
ARG USER_ID
RUN groupadd -g ${GROUP_ID} opencode && \
    useradd -u ${USER_ID} -g opencode -m opencode

USER opencode

WORKDIR /home/opencode

# Create necessary directories for OpenCode configuration
RUN mkdir -p ~/.local/share/opencode ~/.agents ~/.gradle ~/.azure

# Install Playwright CLI skill files to ~/.agents/skills/playwright-cli/
RUN playwright-cli install --skills=agents

# Copy the configuration file to the container
COPY --chown=${USER_ID}:${GROUP_ID} .config /home/opencode/.config

WORKDIR /workspace

ENTRYPOINT ["opencode"]