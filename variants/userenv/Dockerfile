FROM nix-docker-base

RUN nix-env -f '<nixpkgs>' -iA \
    curl \
    findutils \
    git \
    glibc \
    gnugrep \
    gnused \
    gnutar \
    gzip \
    jq \
    procps \
    vim \
    which \
    xz \
 && nix-store --gc
