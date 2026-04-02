ARG DEBIAN_VERSION=13.4
ARG OPENCODE_VERSION=1.3.3
ARG JAVA_VERSION=21

FROM debian:${DEBIAN_VERSION}

ARG OPENCODE_VERSION
ARG JAVA_VERSION

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

# Install OpenCode globally
RUN npm install -g opencode-ai@${OPENCODE_VERSION}

# Create a non-root user to match your host
ARG GROUP_ID=1000
ARG USER_ID
RUN groupadd -g ${GROUP_ID} opencode && \
    useradd -u ${USER_ID} -g opencode -m opencode

USER opencode

# Create necessary directories for OpenCode configuration
RUN mkdir -p ~/.local/share/opencode ~/.agents ~/.gradle

# Copy the configuration file to the container
COPY --chown=${USER_ID}:${GROUP_ID} .config /home/opencode/.config

WORKDIR /workspace

ENTRYPOINT ["opencode"]