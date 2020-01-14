{ buildEnv
, bashInteractive
, cacert
, coreutils
, dockerTools
, lib
, nix
, pathsFromGraph
, perl
, pinnedPkgs
, stdenv
, writeTextDir
}:

let
  path =
    buildEnv {
      name = "system-path";
      paths = [
        bashInteractive
        coreutils
        nix
      ];
    };

  nixconf =
    ''
      build-users-group = nixbld
      sandbox = false
    '';

  passwd =
    ''
      root:x:0:0::/root:/run/current-system/sw/bin/bash
      user:x:1000:1000::/home/user:/run/current-system/sw/bin/bash
      ${lib.concatStringsSep "\n" (lib.genList (i: "nixbld${toString (i+1)}:x:${toString (i+30001)}:30000::/var/empty:/run/current-system/sw/bin/nologin") 32)}
    '';

  group =
    ''
      root:x:0:
      user:x:1000:user
      nogroup:x:65534:
      nixbld:x:30000:${lib.concatStringsSep "," (lib.genList (i: "nixbld${toString (i+1)}") 32)}
    '';

  nsswitch =
    ''
      hosts: files dns myhostname mymachines
    '';

  contents =
    stdenv.mkDerivation {
      name = "user-environment";
      phases = [ "installPhase" "fixupPhase" ];

      installPhase = ''
        mkdir -p \
          $out/tmp \
          $out/bin \
          $out/etc/nix \
          $out/etc/ssl \
          $out/root/.nix-defexpr \
          $out/run/current-system \
          $out/sbin \
          $out/usr/bin \
          $out/var \
          $out/var/empty

        ln -s /run $out/var/run
        ln -s ${path} $out/run/current-system/sw
        ln -s ${stdenv.shell} $out/bin/sh
        ln -s ${coreutils}/bin/env $out/usr/bin/env
        ln -s ${cacert}/etc/ssl/certs $out/etc/ssl/certs
        ln -s ${pinnedPkgs} $out/root/.nix-defexpr/nixos
        ln -s ${pinnedPkgs} $out/root/.nix-defexpr/nixpkgs

        echo '${nixconf}' > $out/etc/nix/nix.conf
        echo '${passwd}' > $out/etc/passwd
        echo '${group}' > $out/etc/group
        echo '${nsswitch}' > $out/etc/nsswitch.conf
      '';
    };
in
dockerTools.buildImage {
  inherit contents;

  name = "nix-docker-base";
  tag = "latest";

  config.Cmd = [ "${bashInteractive}/bin/bash" ];
  config.Env =
    [
      "PATH=/root/.nix-profile/bin:/run/current-system/sw/bin"
      "MANPATH=/root/.nix-profile/share/man:/run/current-system/sw/share/man"
      "NIX_PAGER=cat"
      "NIX_PATH=nixpkgs=${pinnedPkgs}"
      "NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  config.WorkingDir = "/root";
}
