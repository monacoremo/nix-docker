
# Custom Docker images with the Nix package manager

[![CircleCI](https://circleci.com/gh/monacoremo/nix-docker.svg?style=svg)](https://circleci.com/gh/monacoremo/nix-docker)

This repository is used to build custom Docker images that contain the
[Nix](https://nixos.org/nix) package manager. Whereas the [official docker
images for Nix](https://hub.docker.com/r/nixos/nix/) are currently based on
Alpine, the images from this repository are built from scratch and look a lot
more like [NixOS](https://nixos.org/nixos).

## Building images

To build the images and tag them in your Docker instance, run `nix-shell --run
nix-docker-build`.

`nix-shell --run nix-docker` will take care of building the images, pushing them
to DockerHub and cleaning up the tags in Docker.

## Versions

All images are pinned to a specific version of
[`nixpks-unstable`](https://github.com/NixOS/nixpkgs/tree/nixpkgs-unstable), as
identified by the Git commit hash and, for convenenience, the date when that
version was pinned. All versions that have been pinned are tracked in the
[versions](./versions) directory. To add a new version based on the current
HEAD of `nixpkgs-unstable`, run the [`./update.sh`](update.sh) script
(optionally in `nix-shell`, which provides the dependencies on `curl` and `jq`).

To build specific versions of the images, provide your version file as an
argument to `nix-shell`. For example: `nix-shell --arg version
versions/2020-01-14-f9c81b5c.nix`. A version
file should contain a Nix expression that returns a set with the attributes
`date`, `rev` and `tarballHash`.

While you probably will not depend on the version of `nixpkgs` that is pinned
in the container and you are [pining your own
version](https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs) in your projects, having
the same version in pinned both will make spinning up the container with your
project much quicker.

## Image variants

Several kinds of images are built in this repository:

* The base image contains Nix, bash and coreutils, which are installed in a
  system profile that is linked to
  `/run/current-system/sw`. The only global paths are `/bin/sh` and
  `/usr/bin/env`.
* **userenv** images are intended for interactive use.
* **circleci** images are intended as an efficient base for
  [CircleCI](https://circleci.com/) jobs that depend on Nix packages.

## Using the images

To use the images you can, for example, run `nix-shell` in them with your
project or install additional packages to the container's enviroment:

```Dockerfile
FROM monacoremo/nix:2020-01-14-f9c81b5c

RUN nix-env -iA \
 nixpkgs.curl \
 nixpkgs.jq

```
