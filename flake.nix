{
  description = "mariadb distroless image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = builtins.currentSystem;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      mariadb-image = pkgs.dockerTools.buildLayeredImage {
        name = "mariadb";
        tag = "latest";
        contents = [ 
          pkgs.mariadb
        ];
        config = {
          ExposedPorts = {
            "3306/tcp" = {};
          };
          Volumes = {
            "/var/lib/mysql" = {};
          };

          # Distroless non‑root user

          Cmd = [ "${pkgs.mariadb}/bin/mariadb" ];
        };
      };
    };

    # Expose the mariadb version for CI workflows
    mariadbVersion = pkgs.mariadb.version;

    defaultPackage.${system} = self.packages.${system}.mariadb-image;
  };
}
