{ writeTextDir, repo, tag }:

{ latest =
    writeTextDir "Dockerfile"
      ''
        FROM ${repo}:${tag}

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
      '';

  circleci =
    writeTextDir "Dockerfile"
      ''
        FROM ${repo}:${tag}

        RUN nix-env -f '<nixpkgs>' -iA \
            gnutar \
            gzip \
            git \
            openssh \
            su-exec \
         && nix-store --gc
      '';
}
