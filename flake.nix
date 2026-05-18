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
    dataDir = pkgs.runCommand "data-dir" {} ''
      mkdir -p $out/var/lib/mysql
      mkdir -p $out/run/mysqld
      mkdir -p $out/config
    '';
    version = "11.4.9";
    srcHash = "sha256-jkgcoptadARE1FRRyOotk3Ec9SXW+l0nvJUSz4lzsHU=";
    pkg = pkgs.mariadb.overrideAttrs (old: {
      inherit version;
      src = pkgs.fetchurl {
        urls = [ "https://archive.mariadb.org/mariadb-${version}/source/mariadb-${version}.tar.gz" ];
        hash = srcHash;
      };
    });

    execline = pkgs.execline;
    initPath = pkgs.lib.makeBinPath [
      pkgs.gnused
      pkg
    ];
    imageConfig = {
      Entrypoint = [
        "${execline}/bin/execlineb" "-c"
        "export PATH ${initPath} ifthenelse { ${execline}/bin/eltest -d /var/lib/mysql/mysql } { } { ${pkg}/bin/mariadb-install-db --basedir=${pkg} --datadir=/var/lib/mysql --skip-test-db } ${pkg}/bin/mariadbd --skip-name-resolve --bind-address=0.0.0.0 --socket=/var/lib/mysql/mysqld.sock"
      ];
      ExposedPorts = {
        "3306/tcp" = {};
      };
      Volumes = {
        "/var/lib/mysql" = {};
      };
      Healthcheck = {
        Test = ["CMD" "${pkg}/bin/mariadb-admin" "ping" "-h" "127.0.0.1"];
        Interval = 30000000000;
        Timeout = 10000000000;
        Retries = 3;
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
          { path = dataDir; regex = "/var/lib/mysql"; mode = "0777"; }
          { path = dataDir; regex = "/run/mysqld"; mode = "1777"; }
          { path = dataDir; regex = "/config"; mode = "0777"; }
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
          { path = dataDir; regex = "/var/lib/mysql"; mode = "0777"; }
          { path = dataDir; regex = "/run/mysqld"; mode = "1777"; }
          { path = dataDir; regex = "/config"; mode = "0777"; }
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
