ARG OPENCODE_VERSION=1.3.3

FROM debian:13.4

# Install basic tools and OpenCode
RUN apt-get update && apt-get install -y npm git curl && \
    npm install -g opencode-ai@${OPENCODE_VERSION} && \
    apt-get clean


# Create a non-root user to match your host
ARG USER_ID
ARG GROUP_ID
RUN groupadd -g ${GROUP_ID} opencode && \
    useradd -u ${USER_ID} -g opencode -m opencode

USER opencodeuser
WORKDIR /workspace

CMD ["opencode"]