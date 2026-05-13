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
    };

    imageConfig = {
      Entrypoint = [ "${pkg}/bin/mariadbd" ];
      Cmd = [ "--datadir=/var/lib/mysql" ];
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
        maxLayers = 5;
        config = imageConfig;
      };

      mariadb-debug-image = n2c.buildImage {
        name = "mariadb";
        tag = "latest-debug";
        fromImage = base.packages.${system}.base-debug-image;
        maxLayers = 5;
        config = imageConfig;
      };

      mariadb = pkg;

      default = self.packages.${system}.mariadb-image;
    };

    mariadbVersion = version;
  };
}
