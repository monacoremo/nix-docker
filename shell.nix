let
  config = {
    channel = "unstable";
    date = "2020-01-02";
    commitHash = "7e8454fb856573967a70f61116e15f879f2e3f6a";
    tarballHash = "0lnbjjvj0ivpi9pxar0fyk8ggybxv70c5s0hpsqf5d71lzdpxpj8";
    repo = "monacoremo/nix";
  };

  nixDocker =
    import ./default.nix config;

  pinnedPkgs =
    builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${config.commitHash}.tar.gz";
      sha256 = config.tarballHash;
    };

  pkgs =
    import pinnedPkgs {};
in
pkgs.stdenv.mkDerivation {
  name = "nix-docker";

  buildInputs = [
    nixDocker.docker.main
    nixDocker.docker.build
    nixDocker.docker.push
    nixDocker.docker.clean
  ];
}
