# mariadb

Enhanced, drop-in replacement for MySQL.

Upstream: [MariaDB/server](https://github.com/MariaDB/server)  
Documentation: [mariadb.com/kb/en](https://mariadb.com/kb/en/)  
Docker image docs: [MariaDB Docker Official Image](https://hub.docker.com/_/mariadb)

## Ports

- `3306` — MySQL protocol

## Volumes

- `/var/lib/mysql` — Database storage

## Environment Variables

All `MARIADB_*` variables take precedence over their `MYSQL_*` equivalents. Most variables only take effect on **first initialization** when the data directory is empty.

### Authentication

| Variable | Default | Description |
| --- | --- | --- |
| `MARIADB_ROOT_PASSWORD` | _(none)_ | Root superuser password |
| `MARIADB_ROOT_PASSWORD_HASH` | _(none)_ | Pre-hashed root password (mutually exclusive with plain password) |
| `MARIADB_ALLOW_EMPTY_ROOT_PASSWORD` | _(none)_ | Set to any non-empty value to allow blank root password |
| `MARIADB_RANDOM_ROOT_PASSWORD` | _(none)_ | Set to any non-empty value to generate a random 32-char root password |

### User and Database

| Variable | Default | Description |
| --- | --- | --- |
| `MARIADB_DATABASE` | _(none)_ | Database to create on first start |
| `MARIADB_USER` | _(none)_ | Username to create |
| `MARIADB_PASSWORD` | _(none)_ | Password for `MARIADB_USER` |
| `MARIADB_PASSWORD_HASH` | _(none)_ | Pre-hashed password for `MARIADB_USER` |
| `MARIADB_USER_HOST` | `%` | Hostname portion of created user |
| `MARIADB_ROOT_HOST` | `%` | Hostname portion of root user |

### Healthcheck Users

| Variable | Default | Description |
| --- | --- | --- |
| `MARIADB_MYSQL_LOCALHOST_USER` | _(none)_ | Create `mysql@localhost` user (unix_socket auth) for health checks |
| `MARIADB_MYSQL_LOCALHOST_GRANTS` | `USAGE` | Global privileges for `mysql@localhost` |
| `MARIADB_HEALTHCHECK_GRANTS` | `USAGE` | Grants for auto-created `healthcheck` users |

### Initialization

| Variable | Default | Description |
| --- | --- | --- |
| `MARIADB_INITDB_SKIP_TZINFO` | _(none)_ | Skip loading timezone data |

### Upgrade

| Variable | Default | Description |
| --- | --- | --- |
| `MARIADB_AUTO_UPGRADE` | _(none)_ | Auto-run `mariadb-upgrade` on startup when needed |
| `MARIADB_DISABLE_UPGRADE_BACKUP` | _(none)_ | Skip creating backup before upgrade |

### Replication

| Variable | Default | Description |
| --- | --- | --- |
| `MARIADB_MASTER_HOST` | _(none)_ | Replication master hostname (sets container as replica) |
| `MARIADB_MASTER_PORT` | `3306` | Replication master port |
| `MARIADB_REPLICATION_USER` | _(none)_ | Replication user (created on master, used on replica) |
| `MARIADB_REPLICATION_PASSWORD` | _(none)_ | Replication user password |
| `MARIADB_REPLICATION_PASSWORD_HASH` | _(none)_ | Pre-hashed replication password (master only) |

### Docker Secrets (`_FILE` Variants)

Every sensitive variable has a `_FILE` counterpart that reads the value from a file path:

`MARIADB_ROOT_PASSWORD_FILE`, `MARIADB_ROOT_PASSWORD_HASH_FILE`, `MARIADB_ROOT_HOST_FILE`, `MARIADB_DATABASE_FILE`, `MARIADB_USER_FILE`, `MARIADB_PASSWORD_FILE`, `MARIADB_PASSWORD_HASH_FILE`, `MARIADB_REPLICATION_USER_FILE`, `MARIADB_REPLICATION_PASSWORD_FILE`, `MARIADB_REPLICATION_PASSWORD_HASH_FILE`, `MARIADB_MASTER_HOST_FILE`, `MARIADB_MASTER_PORT_FILE`

<a href="https://www.buymeacoffee.com/bhoehn" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
