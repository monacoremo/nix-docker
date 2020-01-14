FROM nix-docker-base

RUN chmod 1777 /tmp \
  && chmod o+xr /root

RUN nix-env -f '<nixpkgs>' -iA \
  gnutar \
  gzip \
  git \
  openssh \
  su-exec \
 && nix-store --gc
