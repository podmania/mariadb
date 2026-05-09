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
    imageConfig = {
      ExposedPorts = {
        "3306/tcp" = {};
      };
      Volumes = {
        "/var/lib/mysql" = {};
      };
      Cmd = [ "${pkgs.mariadb}/bin/mariadb" ];
    };
  in {
    packages.${system} = {
      mariadb-image = n2c.buildImage {
        name = "mariadb";
        tag = "latest";
        fromImage = base.packages.${system}.base-image;
        config = imageConfig;
      };

      mariadb-debug-image = n2c.buildImage {
        name = "mariadb";
        tag = "latest-debug";
        fromImage = base.packages.${system}.base-debug-image;
        config = imageConfig;
      };

      mariadb = pkgs.mariadb;

      default = self.packages.${system}.mariadb-image;
    };

    mariadbVersion = pkgs.mariadb.version;
  };
}
