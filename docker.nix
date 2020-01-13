{ writeShellScriptBin, repo, tag, base, derived }:

rec {
  build =
    writeShellScriptBin "nix-docker-build"
      ''
        set -e

        echo "importing root image..." >&2
        docker load < ${base.image}

        trap "docker rmi ${base.name}:${tag}" exit

        echo "building ${tag} images..." >&2

        docker build -t ${repo}:${tag} ${base.docker}
        docker build -t ${repo}:latest-${tag} ${derived.latest}
        docker build -t ${repo}:circleci-${tag} ${derived.circleci}
      '';

  push =
    writeShellScriptBin "nix-docker-push"
      ''
        docker push ${repo}:${tag}
        docker push ${repo}:latest-${tag}
        docker push ${repo}:circleci-${tag}
      '';

  clean =
    writeShellScriptBin "nix-docker-clean"
      ''
        docker rmi ${repo}:${tag}
        docker rmi ${repo}:latest-${tag}
        docker rmi ${repo}:circleci-${tag}
      '';

  main =
    writeShellScriptBin "nix-docker"
      ''
        ${build}/bin/nix-docker-build
        ${push}/bin/nix-docker-push
        ${clean}/bin/nix-docker-clean
      '';
}
