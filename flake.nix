{
  description = "mariadb distroless image using nix2container";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix2container.url = "github:nlewo/nix2container";
    base.url = "github:podmania/base";
  };

  outputs = { self, nixpkgs, nix2container, base }: let
    system = builtins.currentSystem;
    pkgs = nixpkgs.legacyPackages.${system};
    n2c = nix2container.outputs.packages.${system}.nix2container;
    version = "11.4.9";
    srcHash = "sha256-jkgcoptadARE1FRRyOotk3Ec9SXW+l0nvJUSz4lzsHU=";
    pkg = pkgs.mariadb.overrideAttrs (old: {
      inherit version;
      src = pkgs.fetchurl {
        urls = [ "https://archive.mariadb.org/mariadb-${version}/source/mariadb-${version}.tar.gz" ];
        hash = srcHash;
      };
    });

    # Pre-create /var/lib/mysql with world-writable permissions so any
    # running user can write to it and take ownership at startup.
    dataDir = pkgs.runCommand "mariadb-data" {} ''
      mkdir -p $out/var/lib/mysql
    '';

    # Simple entrypoint: take ownership of the data directory, then exec mariadbd.
    # Works whether the container runs via userns_mode or user: PUID:PGID.
    entrypoint = pkgs.writeScriptBin "entrypoint" ''
      #!${pkgs.bashInteractive}/bin/bash
      set -e
      mkdir -p /var/lib/mysql
      chown "$(id -u):$(id -g)" /var/lib/mysql
      chmod 0700 /var/lib/mysql
      exec ${pkg}/bin/mariadbd --user="$(id -un)" --datadir=/var/lib/mysql "$@"
    '';

    imageConfig = {
      Entrypoint = [ "${entrypoint}/bin/entrypoint" ];
      ExposedPorts = {
        "3306/tcp" = {};
      };
      Volumes = {
        "/var/lib/mysql" = {};
      };
    };
  in {
    packages.${system} = {
      mariadb-image = n2c.buildImage {
        name = "mariadb";
        tag = "latest";
        fromImage = base.packages.${system}.base-image;
        copyToRoot = [ dataDir ];
        perms = [
          { path = dataDir; regex = "var/lib/mysql"; mode = "0777"; }
        ];
        maxLayers = 5;
        config = imageConfig;
      };

      mariadb-debug-image = n2c.buildImage {
        name = "mariadb";
        tag = "latest-debug";
        fromImage = base.packages.${system}.base-debug-image;
        copyToRoot = [ dataDir ];
        perms = [
          { path = dataDir; regex = "var/lib/mysql"; mode = "0777"; }
        ];
        maxLayers = 5;
        config = imageConfig;
      };

      mariadb = pkg;

      default = self.packages.${system}.mariadb-image;
    };

    mariadbVersion = version;
  };
}
