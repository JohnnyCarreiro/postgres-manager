# Postgres Containers Manager
One source for controlling postgres containers for all projects.

When create volumes in the project use:

```bash
    sudo chown -R 1001:1001 ~/Dev/multiledgers/multiledgers-track-2.0/.cache/pgdata
```

### Add new project
To add project just insert new project in the `db-configs.yaml` file.
Example:
```yaml
conecta:
  container_name: postgres-conecta
  db_name: conecta_database
  db_user: conecta_user
  db_password: postgres
  db_port: 5432
  volume_path: ~/Dev/consolidados/projects/conecta-compras/server/.cache/pgdata

```

### Aliases
```bash
    alias docker-up='~/Dev/postgres-manager/docker-db.sh up'
    alias docker-down='~/Dev/postgres-manager/docker-db.sh down'
    alias docker-restart='~/Dev/postgres-manager/docker-db.sh restart'
    alias docker-status='~/Dev/postgres-manager/docker-db.sh status'
    alias docker-logs='~/Dev/postgres-manager/docker-db.sh logs'
    alias docker-list='~/Dev/postgres-manager/docker-db.sh list'
```
### Usage
```bash
    docker-up [project]
    docker-down [project]
    docker-restart [project]
    docker-status [project]
    docker-logs [project]
    docker-list
```
