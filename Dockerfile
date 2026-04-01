FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    wget \
    git \
    ca-certificates \
    tini \
    build-essential \
    file \
    bash \
    unzip \
    zip \
    jq \
    tree \
    less \
    nano \
    python3 \
    python3-pip \
    openssh-client \
    rsync \
    tmux \
    htop \
    && rm -rf /var/lib/apt/lists/*

RUN userdel -r ubuntu 2>/dev/null; \
    useradd -m -s /bin/sh -u 1000 devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R devuser:devuser /home/linuxbrew

USER devuser
RUN curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
ENV HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
ENV HOMEBREW_CELLAR=/home/linuxbrew/.linuxbrew/Cellar
ENV HOMEBREW_REPOSITORY=/home/linuxbrew/.linuxbrew/Homebrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH

RUN brew install gh

RUN curl -fsSL https://bun.sh/install | bash
ENV PATH=/home/devuser/.bun/bin:$PATH

RUN bun install -g opencode-ai@1.2.27 && \
    bun install -g @openchamber/web@1.9.1 && \
    bun install -g @fission-ai/openspec && \
    ln -sf /home/devuser/.bun/bin/bun /home/devuser/.bun/bin/node

USER root
RUN mkdir -p /home/devuser/workspace \
             /home/devuser/.local/share/opencode \
             /home/devuser/.config && \
    chown -R devuser:devuser /home/devuser

COPY --chown=devuser:devuser entrypoint.d/ /entrypoint.d/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /entrypoint.d/*.sh

USER devuser
ENV HOME=/home/devuser
ENV PATH=/home/devuser/.local/bin:/home/devuser/.bun/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV OPENCODE_CONFIG='{"autoupdate": false}'

WORKDIR /home/devuser/workspace

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD ["/bin/sh", "-c", "openchamber serve && openchamber logs"]
