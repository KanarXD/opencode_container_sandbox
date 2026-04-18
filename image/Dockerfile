ARG DEBIAN_VERSION

FROM debian:${DEBIAN_VERSION}

ARG JAVA_VERSION
ARG TERRAFORM_VERSION
ARG GRADLE_VERSION

# Install all apt packages in a single layer: basic tools, Node.js/npm, headless JDK,
# Chromium, and GitHub CLI.  Adding the GitHub CLI apt repo first so that everything
# is resolved in one apt-get install call.  Azure CLI is installed via pip (see below)
# because the Debian-packaged version is too old for Python 3.13.
RUN curl_deps="ca-certificates curl gnupg unzip" && \
    apt-get update && \
    apt-get install -y --no-install-recommends ${curl_deps} && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    curl -fsSL https://download.docker.com/linux/debian/gpg \
      -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      npm git \
      openjdk-${JAVA_VERSION}-jdk-headless \
      chromium \
      gcc libc6-dev \
      gh jq \
      python3-pip \
      docker-ce-cli \
      locales && \
    sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && \
    locale-gen && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Azure CLI via pip — the Debian-packaged version (2.74.0) bundles
# antlr4-python3-runtime 4.9.2, which is incompatible with Python 3.13.
# Version 2.77.0+ includes the fix; we pin to the exact version from versions.env.
ARG AZURE_CLI_VERSION
RUN pip install --break-system-packages azure-cli==${AZURE_CLI_VERSION} && \
    pip cache purge

# Java and Chromium environment
RUN ln -s /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-$(dpkg --print-architecture) /usr/lib/jvm/java-openjdk && \
    rm -rf /usr/lib/jvm/openjdk-${JAVA_VERSION}
ENV JAVA_HOME=/usr/lib/jvm/java-openjdk
ENV PATH=${JAVA_HOME}/bin:${PATH}
ENV CHROME_BIN=/usr/bin/chromium
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install Terraform and Gradle in a single layer (binary downloads)
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_$(dpkg --print-architecture).zip \
      -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin/ && \
    rm /tmp/terraform.zip && \
    curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
      -o /tmp/gradle.zip && \
    unzip /tmp/gradle.zip -d /opt/ && \
    ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle.zip
ENV GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}

# JVM and Gradle performance tuning for containerised builds
ENV JAVA_TOOL_OPTIONS="-Xmx2g"
ENV GRADLE_OPTS="-Dorg.gradle.parallel=true -Dorg.gradle.caching=true -Dorg.gradle.welcome=never -Dorg.gradle.jvmargs=-Xmx2g"

# Install all npm global packages in a single layer and clean the cache once
ARG OPENCODE_VERSION
ARG ANGULAR_CLI_VERSION
ARG PLAYWRIGHT_CLI_VERSION
RUN npm install -g \
      opencode-ai@${OPENCODE_VERSION} \
      @angular/cli@${ANGULAR_CLI_VERSION} \
      @playwright/cli@${PLAYWRIGHT_CLI_VERSION} && \
    npm cache clean --force

# Playwright CLI configuration for headless Docker environment
ENV PLAYWRIGHT_MCP_HEADLESS=true
ENV PLAYWRIGHT_MCP_NO_SANDBOX=true
ENV PLAYWRIGHT_MCP_BROWSER=chromium
ENV PLAYWRIGHT_MCP_EXECUTABLE_PATH=/usr/bin/chromium
ENV PLAYWRIGHT_MCP_OUTPUT_DIR=/tmp

# Create non-root user, home directories, and install Playwright skill files
ARG GROUP_ID=1000
ARG USER_ID
RUN groupadd -g ${GROUP_ID} opencode && \
    useradd -u ${USER_ID} -g opencode -m opencode && \
    mkdir -p /home/opencode/.local/share/opencode \
             /home/opencode/.agents \
             /home/opencode/.gradle \
             /home/opencode/.azure && \
    chown -R opencode:opencode /home/opencode

USER opencode

WORKDIR /home/opencode

# Install Rust toolchain and cargo tools
ARG RUST_VERSION
ENV PATH="/home/opencode/.cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION} && \
    rustup target add wasm32-unknown-unknown && \
    cargo install cargo-binstall && \
    cargo binstall wasm-bindgen-cli wasm-opt jwt-cli --no-confirm && \
    rm -rf /home/opencode/.cargo/registry /home/opencode/.cargo/git

# Install Playwright CLI skill files (must run as opencode user)
RUN PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 playwright-cli install --skills=agents

# Copy the configuration file to the container
COPY --chown=${USER_ID}:${GROUP_ID} .config /home/opencode/.config

WORKDIR /workspace

ENTRYPOINT ["opencode"]
