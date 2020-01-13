{ channel, date, commitHash, tarballHash, repo }:

rec {
  tag =
    "${channel}-${date}-${commitHash}";

  pinnedPkgs =
    builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${commitHash}.tar.gz";
      sha256 = tarballHash;
    };

  pkgs =
    import pinnedPkgs {};

  base =
    pkgs.callPackage ./base.nix { inherit pinnedPkgs tag; };

  derived =
    pkgs.callPackage ./derived.nix { inherit repo tag; };

  docker =
    pkgs.callPackage ./docker.nix { inherit repo tag base derived; };
}
