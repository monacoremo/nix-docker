#!/usr/bin/env bash

set -e

refUrl="https://api.github.com/repos/nixos/nixpkgs/git/ref/heads/nixpkgs-unstable"
githubV3Header="Accept: application/vnd.github.v3+json"
commitHash="$(curl "$refUrl" -H "$githubV3Header" | jq -r .object.sha)"
shortCommitHash="$(echo "$commitHash" | cut -c1-8)"
tarballUrl="https://github.com/nixos/nixpkgs/archive/${commitHash}.tar.gz"
tarballHash="$(nix-prefetch-url --unpack "$tarballUrl")"
currentDate="$(date --iso)"

mkdir -p versions

cat > "versions/$currentDate-$shortCommitHash.nix" << EOF
{
  date = "$currentDate";
  rev = "$commitHash";
  tarballHash = "$tarballHash";
}
EOF
