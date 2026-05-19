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

    initScript = pkgs.writeShellScriptBin "mariadb-entrypoint" ''
      set -e
      DATADIR="/var/lib/mysql"
      SOCKET="/var/lib/mysql/mysqld.sock"

      if [ ! -d "$DATADIR/mysql" ]; then
        echo "Initializing MariaDB data directory..."
        ${pkg}/bin/mariadb-install-db --basedir=${pkg} --datadir="$DATADIR" --skip-test-db

        echo "Starting temporary MariaDB server for initialization..."
        ${pkg}/bin/mariadbd --datadir="$DATADIR" --skip-networking --socket="$SOCKET" --skip-grant-tables &
        TEMP_PID=$!

        echo "Waiting for temporary server to be ready..."
        if ! ${pkg}/bin/mariadb-admin --socket="$SOCKET" --wait=30 ping; then
          echo "ERROR: Temporary MariaDB server failed to start"
          kill $TEMP_PID 2>/dev/null || true
          exit 1
        fi

        if [ -n "$MARIADB_ROOT_PASSWORD" ]; then
          echo "Setting root password..."
          ${pkg}/bin/mariadb --socket="$SOCKET" --database=mysql \
            -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';"
        fi

        if [ -n "$MARIADB_DATABASE" ]; then
          echo "Creating database: $MARIADB_DATABASE"
          ${pkg}/bin/mariadb --socket="$SOCKET" \
            -e "CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\`;"
        fi

        if [ -n "$MARIADB_USER" ] && [ -n "$MARIADB_PASSWORD" ]; then
          echo "Creating user: $MARIADB_USER"
          ${pkg}/bin/mariadb --socket="$SOCKET" \
            -e "CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD';"
          if [ -n "$MARIADB_DATABASE" ]; then
            echo "Granting privileges on $MARIADB_DATABASE to $MARIADB_USER"
            ${pkg}/bin/mariadb --socket="$SOCKET" \
              -e "GRANT ALL PRIVILEGES ON \`$MARIADB_DATABASE\`.* TO '$MARIADB_USER'@'%';"
          fi
        fi

        echo "Stopping temporary server..."
        ${pkg}/bin/mariadb-admin --socket="$SOCKET" shutdown
        wait $TEMP_PID
        echo "MariaDB initialization complete."
      fi

      echo "Starting MariaDB server..."
      exec ${pkg}/bin/mariadbd --datadir="$DATADIR" --skip-name-resolve --bind-address=0.0.0.0 --socket="$SOCKET"
    '';

    imageConfig = {
      Entrypoint = [
        "${initScript}/bin/mariadb-entrypoint"
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
        copyToRoot = [ dataDir initScript ];
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
        copyToRoot = [ dataDir initScript ];
        perms = [
          { path = dataDir; regex = "/var/lib/mysql"; mode = "0777"; }
          { path = dataDir; regex = "/run/mysqld"; mode = "1777"; }
          { path = dataDir; regex = "/config"; mode = "0777"; }
        ];
        maxLayers = 5;
        config = imageConfig;
      };

      mariadb = pkg;
      mariadb-entrypoint = initScript;

      default = self.packages.${system}.mariadb-image;
    };

    mariadbVersion = version;
  };
}
