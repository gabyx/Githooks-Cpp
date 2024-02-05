# syntax = docker/dockerfile:1.2
FROM alpine:3.19 as githooks-cpp-base
LABEL name=githooks-cpp

COPY configs/requirements.txt /container-setup/

RUN apk add git tar curl xz bash coreutils findutils grep sed parallel && \
    apk add python3 py3-pip && \
    python -m pip install --break-system-packages -r /container-setup/requirements.txt && \
    apk add --no-cache clang17-extra-tools

RUN git config --system --add safe.directory "*"

VOLUME [ "/mnt/workspace" ]
VOLUME [ "/mnt/shared" ]

FROM githooks-cpp-base as githooks-cpp-user
ARG ROOT_ACCESS=false

ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=githooks

# Install MatchHostFsOwner.
# See https://github.com/FooBarWidget/matchhostfsowner/releases
ADD https://github.com/FooBarWidget/matchhostfsowner/releases/download/v1.0.0/matchhostfsowner-1.0.0-x86_64-linux.gz /sbin/matchhostfsowner.gz
RUN gunzip /sbin/matchhostfsowner.gz && \
  chown root: /sbin/matchhostfsowner && \
  chmod +x,+s /sbin/matchhostfsowner
# Use user 'githooks' for MatchHostFsOwner.
RUN mkdir -p /etc/matchhostfsowner && \
    echo -e "app_account: githooks\napp_group: githooks" > /etc/matchhostfsowner/config.yml && \
    cat /etc/matchhostfsowner/config.yml && \
    chown -R root: /etc/matchhostfsowner && \
    chmod 700 /etc/matchhostfsowner && \
    chmod 600 /etc/matchhostfsowner/*

# Make optional root access. (testing)
RUN [ "${ROOT_ACCESS:-}" = "false" ] || { \
    echo "WARNING: Enabling root access."; \
    mkdir -p /etc/sudoers.d; \
    echo "$USER_NAME ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"; \
    chmod 0440 "/etc/sudoers.d/$USER_NAME"; \
    apk add sudo; \
}

RUN adduser "$USER_NAME" -s /bin/zsh \
    -D \
    -u "$USER_UID" -g "$USER_GID" \
    -h "/home/$USER_NAME"

USER "$USER_NAME"
RUN mkdir -p ~/.parallel && touch ~/.parallel/will-cite

ENTRYPOINT [ "/sbin/matchhostfsowner" ]
CMD [ "bash" ]
