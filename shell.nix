{ version ? versions/2020-01-14-f9c81b5c.nix
, repo ? "monacoremo/nix"
}:

let
  config =
    import version;

  pinnedPkgs =
    builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${config.rev}.tar.gz";
      sha256 = config.tarballHash;
    };

  pkgs =
    import pinnedPkgs {};

  base =
    pkgs.callPackage ./base.nix { inherit pinnedPkgs; };

  tag =
    "${config.date}-${builtins.substring 0 8 config.rev}";

  build =
    pkgs.writeShellScriptBin "nix-docker-build"
      ''
        set -e

        echo "Importing base image..."
        docker load < ${base}

        docker tag nix-docker-base ${repo}:${tag}

        echo "Building variants..."
        for variant in $(ls variants); do
            docker build -t "${repo}:${tag}-$variant" "variants/$variant"
        done
      '';

  push =
    pkgs.writeShellScriptBin "nix-docker-push"
      ''
        docker push ${repo}:${tag}

        for variant in $(ls variants); do
            docker push "${repo}:${tag}-$variant"
        done
      '';

  clean =
    pkgs.writeShellScriptBin "nix-docker-clean"
      ''
        docker rmi nix-docker-base

        for variant in $(ls variants); do
            docker rmi "${repo}:${tag}-$variant"
        done
      '';

  all =
    pkgs.writeShellScriptBin "nix-docker-all"
      ''
        ${build}/bin/nix-docker-build
        ${push}/bin/nix-docker-push
        ${clean}/bin/nix-docker-clean
      '';
in
pkgs.stdenv.mkDerivation {
  name = "nix-docker";

  buildInputs = [
    pkgs.jq
    pkgs.curl
    all
    build
    push
    clean
  ];
}
