{
  description = "mariadb-server distroless image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = builtins.currentSystem;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      mariadb-server-image = pkgs.dockerTools.buildLayeredImage {
        name = "mariadb-server";
        tag = "latest";
        contents = [ 
          pkgs.mariadb-server
        ];
        config = {
          ExposedPorts = {
            "3306/tcp" = {};
          };
          Volumes = {
            "/var/lib/mysql" = {};
          };

          # Distroless non‑root user
          User = "1000";

          Cmd = [ "${pkgs.mariadb-server}/bin/mariadb-server" ];
        };
      };
    };

    # Expose the mariadb-server version for CI workflows
    mariadb-serverVersion = pkgs.mariadb-server.version;

    defaultPackage.${system} = self.packages.${system}.mariadb-server-image;
  };
}
