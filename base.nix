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
, shadow
, stdenv
, tag
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
        shadow
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

      exportReferencesGraph =
        map (drv: [("closure-" + baseNameOf drv) drv])
          [
            path
            pinnedPkgs
          ];

      installPhase = ''
        mkdir -p $out/{bin,var,usr/bin,sbin,etc/ssl,etc/nix,run/current-system}

        ln -s ${stdenv.shell} $out/bin/sh
        ln -s ${coreutils}/bin/env $out/usr/bin/env
        ln -s /run $out/var/run
        ln -s ${path} $out/run/current-system/sw
        ln -s ${cacert}/etc/ssl/certs $out/etc/ssl/certs

        echo '${nixconf}' > $out/etc/nix/nix.conf
        echo '${passwd}' > $out/etc/passwd
        echo '${group}' > $out/etc/group
        echo '${nsswitch}' > $out/etc/nsswitch.conf

        printRegistration=1 ${perl}/bin/perl ${pathsFromGraph} closure-* > $out/.reginfo
      '';
    };
in
rec {
  name = "nix-docker-base-image";

  image =
    dockerTools.buildImage rec {
      inherit tag contents name;

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
    };

  docker =
    writeTextDir "Dockerfile"
      ''
        FROM ${name}:${tag}

        RUN nix-store --init \
          && nix-store --load-db < /.reginfo \
          && rm /.reginfo \
          && mkdir -m 1777 -p /tmp \
          && mkdir -p \
              /nix/var/nix/gcroots \
              /nix/var/nix/profiles/per-user/root \
              /root/.nix-defexpr \
              /var/empty \
          && ln -s ${path} /nix/var/nix/gcroots/booted-system \
          && ln -s /nix/var/nix/profiles/per-user/root/profile /root/.nix-profile \
          && ln -s ${pinnedPkgs} /root/.nix-defexpr/nixos \
          && ln -s ${pinnedPkgs} /root/.nix-defexpr/nixpkgs \
          && nix-store --optimize \
          && nix-store --verify --check-contents
      '';
}
