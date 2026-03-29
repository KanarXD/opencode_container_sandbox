ARG DEBIAN_VERSION=13.4
ARG OPENCODE_VERSION=1.3.3

FROM debian:${DEBIAN_VERSION}

# Install basic tools
RUN apt-get update && apt-get install -y npm git curl && apt-get clean

# Install OpenCode globally
RUN npm install -g opencode-ai@${OPENCODE_VERSION}

# Create a non-root user to match your host
ARG USER_ID
ARG GROUP_ID
RUN groupadd -g ${GROUP_ID} opencode && \
    useradd -u ${USER_ID} -g opencode -m opencode

USER opencode

# Create necessary directories for OpenCode configuration
RUN mkdir -p ~/.local/share/opencode ~/.config/opencode

# Copy the configuration file to the container
COPY --chown=${USER_ID}:${GROUP_ID} ./opencode.json /home/opencode/.config/opencode/opencode.json

WORKDIR /workspace

CMD ["opencode"]