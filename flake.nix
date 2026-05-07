{
  description = "<% name.capitalize() %> distroless image";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = builtins.currentSystem;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      <% name %>-image = pkgs.dockerTools.buildLayeredImage {
        name = "<% name %>";
        tag = "latest";
        contents = [ 
          pkgs.<% name %>
        ];
        config = {
          ExposedPorts = {
            "1234/tcp" = {};
          };
          Volumes = {
            "/config" = {};
            "/data" = {};
          };

          Cmd = [ "${pkgs.<% name %>}/bin/<% name %>" ];
          # Distroless non‑root user
          User = "1000";
          WorkingDir = "/config";
        };
      };
    };

    # Expose the <% name %> version for CI workflows
    <% name %>Version = pkgs.<% name %>.version;

    defaultPackage.${system} = self.packages.${system}.<% name %>-image;
  };
}
