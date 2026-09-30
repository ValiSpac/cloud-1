# Cloud-1 / Ansible Correction Guide

> Repo scope: `floppy727/cloud-1`  
> Goal: explain how the repo deploys a WordPress stack to a remote server using Ansible + Docker Compose, and what you should know for correction.

---

## 1. Correction pitch in 30 seconds

This project automates an Inception-like WordPress infrastructure on a remote Ubuntu server.

The deployment flow is:

```text
Local machine
  └─ runs deploy.sh
      └─ installs/checks Ansible dependencies
      └─ reads inventory + variables
      └─ SSHs into the server as root
          └─ installs base packages
          └─ installs Docker + Docker Compose v2
          └─ configures UFW firewall
          └─ copies Docker Compose project to /opt/cloudone
          └─ writes .env + Docker secret files
          └─ builds and starts containers
```

Runtime architecture:

```text
Browser
  └─ HTTP/HTTPS :80/:443
      └─ nginx container
          └─ FastCGI :9000
              └─ wordpress/php-fpm container
                  ├─ MariaDB :3306, internal Docker network only
                  └─ Redis :6379, internal Docker network only

phpMyAdmin
  └─ exposed only on 127.0.0.1:8081 on the remote server
  └─ reached through SSH tunnel from your local machine
```

Main correction sentence:

> “Ansible is my automation layer. It prepares the remote server, installs Docker, applies firewall rules, deploys the Compose project, injects secrets from environment variables, starts the containers, and verifies that MariaDB and WordPress are reachable.”

---

## 2. How to set up and run

### 2.1 Local prerequisites

On your local machine:

```bash
python3 --version
pip3 --version
pip3 install ansible
```

You also need:

```bash
ssh root@$SERVER_IP
```

to work manually before running Ansible.

The repo expects the SSH key to be available locally. Default:

```bash
~/.ssh/id_ed25519
```

Override it with:

```bash
export SSH_KEY_PATH="$HOME/.ssh/your_key"
```

### 2.2 Required environment variables

The repo deliberately avoids committing passwords. You export them before running the playbook:

```bash
export SERVER_IP="your.server.ip"

export DB_ROOT_PASSWORD="strong_root_password"
export DB_PASSWORD="strong_db_user_password"

export WP_ADMIN_PASSWORD="strong_wp_admin_password"
export WP_USER_PASSWORD="strong_wp_author_password"
```

Optional:

```bash
export DOMAIN_NAME="yourdomain.duckdns.org"
export SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
```

If `DOMAIN_NAME` is not set, the project falls back to the server IP for the domain-related variables.

### 2.3 Recommended first checks

```bash
chmod +x deploy.sh destroy.sh
ansible-inventory -i inventory/hosts.yml --list
ansible all -i inventory/hosts.yml -m ping
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --syntax-check
```

Expected behavior:

- `ansible-inventory` shows host `cloud1`.
- `ansible ping` returns `pong`.
- `--syntax-check` returns no YAML/playbook syntax error.

### 2.4 Main commands

```bash
./deploy.sh deploy
```

Full deployment: setup + Docker + firewall + app.

```bash
./deploy.sh setup
```

Only server preparation: base packages, Docker, firewall.

```bash
./deploy.sh app
```

Only application deployment: copy Compose project, write secrets, start containers. Use after setup.

```bash
./deploy.sh status
```

SSHs into the remote server and displays container status.

```bash
./deploy.sh destroy
```

Runs the destroy playbook. This removes containers, volumes, `/opt/cloudone`, and `/opt/cloudone/data`.

### 2.5 Access after deployment

WordPress:

```text
https://$DOMAIN_NAME
https://$DOMAIN_NAME/wp-admin
```

If no domain:

```text
https://$SERVER_IP
```

phpMyAdmin:

```bash
ssh -L 8081:localhost:8081 root@$SERVER_IP
```

Then open locally:

```text
http://localhost:8081
```

### 2.6 Useful validation commands

On the remote server:

```bash
docker ps
docker compose -f /opt/cloudone/docker-compose.yml ps
docker logs nginx
docker logs wordpress
docker logs mariadb
docker logs redis
docker logs phpmyadmin
ufw status verbose
ls -la /opt/cloudone
ls -la /opt/cloudone/secrets
ls -la /opt/cloudone/data
```

From local:

```bash
curl -kI https://$DOMAIN_NAME
curl -kI https://$SERVER_IP
```

`-k` is needed because the repo generates a self-signed certificate.

---

## 3. Repo map

```text
cloud-1/
├── README.md
├── CORRECTION_PREP.md
├── ROADMAP.md
├── ansible.cfg
├── deploy.sh
├── destroy.sh
├── inventory/
│   ├── hosts.yml
│   └── group_vars/
│       └── all.yml
└── playbooks/
    ├── site.yml
    ├── setup.yml
    ├── deploy.yml
    ├── destroy.yml
    └── roles/
        ├── common/
        ├── docker/
        ├── firewall/
        └── cloudone/
            ├── tasks/
            ├── templates/
            └── files/docker/
                ├── docker-compose.yml
                └── requirements/
                    ├── nginx/
                    ├── mariadb/
                    ├── wordpress/
                    └── bonus/
                        ├── redis/
                        └── phpmyadmin/
```

Important point: roles are inside `playbooks/roles/`, so Ansible can resolve them relative to the playbook directory.

---

## 4. Ansible concepts you must know

### 4.1 Control node and managed node

- **Control node**: your local machine running Ansible.
- **Managed node**: the remote cloud server.
- Ansible usually works over SSH.
- No Ansible agent is installed on the server.

In this project, Ansible connects as `root`.

### 4.2 Inventory

The inventory is the list of servers Ansible manages.

File:

```text
inventory/hosts.yml
```

It defines:

```yaml
all:
  hosts:
    cloud1:
      ansible_host: "{{ lookup('env', 'SERVER_IP') | default('CHANGE_ME', true) }}"
      ansible_user: root
      ansible_ssh_private_key_file: "{{ lookup('env', 'SSH_KEY_PATH') | default('~/.ssh/id_ed25519', true) }}"
```

What to say:

> “The inventory defines my target server. I use environment variables so I can change the server IP or SSH key without editing the repository.”

To add a second server:

```yaml
all:
  hosts:
    cloud1:
      ansible_host: "{{ lookup('env', 'SERVER_IP') }}"
      ansible_user: root
    cloud2:
      ansible_host: "{{ lookup('env', 'SERVER2_IP') }}"
      ansible_user: root
```

Because the playbooks use `hosts: all`, Ansible would run the deployment on both.

Important nuance:

> This gives parallel deployment to multiple servers, but not high availability by itself. Each server gets its own independent stack unless you also add a load balancer, shared storage, external DB replication, etc.

### 4.3 Variables

Main variable file:

```text
inventory/group_vars/all.yml
```

It defines shared values for every host:

- app paths: `/opt/cloudone`, `/opt/cloudone/data`
- Docker Compose project name
- database names/users
- WordPress admin/user settings
- Nginx/PHP/Redis ports
- firewall ports
- persistent data paths

Examples:

```yaml
app_root: /opt/cloudone
data_root: /opt/cloudone/data

mysql_database: wordpress
mysql_user: wpuser

domain_name: "{{ lookup('env', 'DOMAIN_NAME') | default(ansible_host, true) }}"
```

What to say:

> “I centralized configuration in `group_vars/all.yml` so tasks and templates do not hardcode paths, ports, domain, or credentials.”

### 4.4 Playbooks

A playbook is the ordered automation file.

Your main playbooks:

| File | Purpose |
|---|---|
| `playbooks/site.yml` | Full deployment |
| `playbooks/setup.yml` | Server setup only |
| `playbooks/deploy.yml` | App deployment only |
| `playbooks/destroy.yml` | Teardown |

### 4.5 Roles

A role is a reusable folder that groups tasks, handlers, templates, files, and defaults.

Your roles:

| Role | Responsibility |
|---|---|
| `common` | Base system packages, Python Docker libs, folders |
| `docker` | Docker CE + Compose plugin installation |
| `firewall` | UFW rules |
| `cloudone` | Application deployment with Docker Compose |

What to say:

> “Roles keep the project readable: server basics, Docker, firewall, and application deployment are separated.”

### 4.6 Tasks and modules

A task calls an Ansible module.

Examples in your repo:

| Module | Used for |
|---|---|
| `apt` | install/update packages |
| `pip` | install Python Docker libraries |
| `file` | create directories, set permissions |
| `copy` | copy files or write secret files |
| `template` | render `.env` from Jinja2 |
| `systemd` | start/enable Docker services |
| `ufw` | configure firewall |
| `uri` | test HTTP/HTTPS response |
| `assert` | validate required variables |
| `community.docker.docker_compose_v2` | run Docker Compose v2 |

### 4.7 Templates

Templates are files with variables inside.

Your template:

```text
playbooks/roles/cloudone/templates/env.j2
```

It becomes:

```text
/opt/cloudone/.env
```

on the remote server.

Example idea:

```jinja2
DOMAIN_NAME={{ domain_name }}
MYSQL_DATABASE={{ mysql_database }}
MYSQL_USER={{ mysql_user }}
```

What to say:

> “The template lets Ansible generate a server-specific `.env` file from inventory variables and local environment variables.”

### 4.8 Handlers

A handler is a task triggered only when notified by another task.

Your Docker role has:

```text
playbooks/roles/docker/handlers/main.yml
```

It restarts Docker when `daemon.json` changes.

What to say:

> “The Docker daemon is restarted only when its config file changes, not every run.”

### 4.9 Facts

`gather_facts: yes` collects system information from the remote server.

Examples of useful facts:

- OS family
- architecture
- network interfaces
- Python info
- distribution version

Your repo also manually gets architecture and Ubuntu codename for Docker’s APT repo.

### 4.10 Idempotence

Idempotence means rerunning the playbook should converge the server to the same desired state without duplicating work.

Examples in your repo:

- `apt state: present` only installs missing packages.
- `file state: directory` only creates missing directories.
- Docker/systemd tasks ensure services are started/enabled.
- WordPress and MariaDB entry scripts check whether data/config already exists.

Nuance:

- The `cloudone` role first stops the existing Compose stack and rebuilds images, so application deployment is more “redeploy-style” than purely no-change idempotent.
- It is still predictable: rerunning it recreates the stack from the desired files while preserving bind-mounted data.

### 4.11 `register`, `until`, `retries`, `delay`

Your repo uses:

```yaml
register: mariadb_health
until: mariadb_health.stdout == 'healthy'
retries: 30
delay: 5
```

Meaning:

> “Run this command repeatedly until MariaDB reports healthy, or fail after 30 attempts.”

This is important because containers may start before the service inside is actually ready.

### 4.12 `changed_when`

Example:

```yaml
changed_when: false
```

This tells Ansible:

> “This command is only a check. Do not report the playbook as changed because of it.”

Useful for commands like `docker ps`, `docker info`, `ufw status`.

### 4.13 `no_log`

Your secret-writing task uses:

```yaml
no_log: true
```

Meaning:

> “Do not print secret values in Ansible output.”

Correction caveat:

> The repo protects the secret-copy task output, but secrets also appear inside `/opt/cloudone/.env` on the server with mode `0600`. That is acceptable for this project, but in production I would use Ansible Vault or a proper secret manager.

### 4.14 Tags

`site.yml` tags roles like:

```yaml
tags: [common, setup]
tags: [docker, setup]
tags: [firewall, security]
tags: [cloudone, deploy]
```

Possible commands:

```bash
ansible-playbook playbooks/site.yml --tags setup
ansible-playbook playbooks/site.yml --tags deploy
ansible-playbook playbooks/site.yml --list-tags
ansible-playbook playbooks/site.yml --list-tasks
```

---

## 5. `ansible.cfg` explained

File:

```text
ansible.cfg
```

### `[defaults]`

```ini
inventory = inventory/hosts.yml
```

Default inventory file. This lets you run:

```bash
ansible-playbook playbooks/site.yml
```

without always passing `-i inventory/hosts.yml`.

```ini
remote_user = root
```

Default SSH user.

```ini
host_key_checking = False
```

Disables SSH known-host verification.

What to say:

> “This avoids first-connection prompts during correction on a fresh cloud server. In production I would keep host key checking enabled.”

```ini
retry_files_enabled = False
```

Disables old `.retry` files.

```ini
stdout_callback = yaml
```

Makes Ansible output easier to read.

```ini
deprecation_warnings = False
```

Hides deprecation warnings.

```ini
interpreter_python = auto_silent
```

Lets Ansible auto-detect remote Python quietly.

### `[ssh_connection]`

```ini
pipelining = True
```

Reduces SSH round trips and speeds up execution.

```ini
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null
```

- Reuses SSH connections.
- Keeps them open briefly.
- Avoids writing host keys to `known_hosts`.

### `[privilege_escalation]`

```ini
become = True
become_method = sudo
become_user = root
```

Tasks run with elevated privileges.

Because the SSH user is already root, this is mostly harmless redundancy. It would matter more if you changed to a non-root sudo user.

---

## 6. Playbooks explained

### 6.1 `playbooks/site.yml`

Full deployment.

Flow:

1. Targets `hosts: all`.
2. Runs as root with `become: yes`.
3. Gathers facts.
4. Validates required environment variables with `assert`.
5. Displays deployment information.
6. Runs roles:
   - `common`
   - `docker`
   - `firewall`
   - `cloudone`
7. Runs post-checks:
   - `docker ps`
   - displays running containers
   - prints final URLs and credentials info

What to say:

> “`site.yml` is the one-command deployment. It validates secrets first, prepares the server, deploys the app, then verifies containers.”

### 6.2 `playbooks/setup.yml`

Runs only:

- `common`
- `docker`
- `firewall`

Use it when you want the server ready but do not want to deploy the app yet.

### 6.3 `playbooks/deploy.yml`

Runs only:

- `cloudone`

It still validates passwords first.

Use it when Docker and firewall are already configured and you only changed application files.

### 6.4 `playbooks/destroy.yml`

Teardown playbook.

It:

1. Prompts for `yes`.
2. Stops/removes Compose containers.
3. Removes Docker volumes.
4. Removes `/opt/cloudone`.
5. Removes `/opt/cloudone/data`.
6. Prunes unused Docker resources.

Important warning:

> This deletes persistent WordPress and database data. Do not run it if you need to keep the site.

---

## 7. Roles explained

## 7.1 `common` role

File:

```text
playbooks/roles/common/tasks/main.yml
```

Responsibilities:

1. Waits for SSH connection.
2. Updates APT cache.
3. Optionally upgrades packages if `upgrade_packages` is true.
4. Installs base packages:
   - HTTPS APT support
   - certificates
   - curl
   - gnupg
   - Python 3 + pip
   - git/vim/htop/tree
5. Installs Python Docker modules.
6. Sets timezone to UTC.
7. Creates directories:
   - `/opt/cloudone`
   - `/opt/cloudone/data`
   - `/opt/cloudone/data/db`
   - `/opt/cloudone/data/wp`
8. Sets permissions.

Correction answer:

> “The common role makes the remote VM usable for the rest of the deployment and creates persistent host folders for database and WordPress data.”

## 7.2 `docker` role

File:

```text
playbooks/roles/docker/tasks/main.yml
```

Responsibilities:

1. Checks whether Docker is already installed.
2. Removes old Docker packages if Docker is absent.
3. Creates `/etc/apt/keyrings`.
4. Downloads Docker’s GPG key.
5. Detects architecture with `dpkg --print-architecture`.
6. Detects Ubuntu codename with `lsb_release -cs`.
7. Adds the official Docker APT repository.
8. Installs:
   - `docker-ce`
   - `docker-ce-cli`
   - `containerd.io`
   - `docker-buildx-plugin`
   - `docker-compose-plugin`
9. Starts/enables Docker and containerd.
10. Waits for `docker info` to succeed.
11. Writes `/etc/docker/daemon.json`.
12. Notifies the Docker restart handler if config changed.

Docker daemon config:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

Correction answer:

> “The Docker role installs Docker Engine and Compose v2 from Docker’s APT repository, enables the services on boot, and configures log rotation to avoid unlimited container logs.”

## 7.3 `firewall` role

File:

```text
playbooks/roles/firewall/tasks/main.yml
```

Responsibilities:

1. Installs UFW.
2. Resets existing UFW rules.
3. Denies incoming traffic by default.
4. Allows outgoing traffic.
5. Allows SSH on 22.
6. Allows public ports from `firewall_allowed_tcp_ports`:
   - 22
   - 80
   - 443
7. Optional FTP rules if enabled.
8. Enables UFW logging.
9. Displays firewall status.

Correction answer:

> “The firewall exposes only SSH, HTTP, and HTTPS publicly. Database, Redis, WordPress FPM, and phpMyAdmin are not directly public.”

Important nuance:

- phpMyAdmin is not opened in UFW.
- It is bound to `127.0.0.1:8081` in Docker Compose.
- Access requires SSH tunneling.

## 7.4 `cloudone` role

File:

```text
playbooks/roles/cloudone/tasks/main.yml
```

Responsibilities:

1. Stops existing Compose containers.
2. Prunes unused Docker resources.
3. Copies the Docker Compose project from the repo to `/opt/cloudone`.
4. Creates `/opt/cloudone/requirements`.
5. Creates `/opt/cloudone/secrets` with mode `0700`.
6. Writes secret files:
   - `db_root_pwd`
   - `db_user_pwd`
   - `wp_admin_pwd`
   - `wp_user_pwd`
7. Renders `.env` from `env.j2`.
8. Ensures data directories exist.
9. Builds and starts Docker Compose services using `community.docker.docker_compose_v2`.
10. Waits for MariaDB healthcheck.
11. Checks WordPress via HTTPS.
12. Prints final access information.

Correction answer:

> “This is the app deployment role. It transfers the Compose project, injects runtime configuration and secrets, starts the containers, and waits until the stack is actually usable.”

---

## 8. Docker Compose stack

File:

```text
playbooks/roles/cloudone/files/docker/docker-compose.yml
```

### 8.1 Services

| Service | Public? | Role |
|---|---:|---|
| `nginx` | yes, 80/443 | TLS termination, HTTP redirect, serves WordPress |
| `wordpress` | no | PHP-FPM + WordPress |
| `mariadb` | no | WordPress database |
| `redis` | no | WordPress cache |
| `phpmyadmin` | localhost only | DB admin through SSH tunnel |

### 8.2 Network

All services join the same Docker bridge network:

```yaml
networks:
  cloudone:
    driver: bridge
```

Inside the network, containers resolve each other by service/container name:

- `wordpress` connects to `mariadb`
- `wordpress` connects to `redis`
- `nginx` connects to `wordpress:9000`
- `phpmyadmin` connects to `mariadb`

### 8.3 Ports

Public ports:

```yaml
nginx:
  ports:
    - "443:443"
    - "80:80"
```

Local-only phpMyAdmin:

```yaml
phpmyadmin:
  ports:
    - "127.0.0.1:8081:8080"
```

Internal-only services:

```yaml
mariadb:
  expose:
    - "3306"

wordpress:
  expose:
    - "${PHP_FPM_PORT}"

redis:
  expose:
    - "6379"
```

`expose` makes the port visible to other containers on the Docker network, not to the public internet.

### 8.4 Persistence

Volumes:

```yaml
db-data -> /opt/cloudone/data/db
wp-data -> /opt/cloudone/data/wp
```

This means:

- Database files survive container recreation.
- WordPress files/uploads survive container recreation.

### 8.5 Secrets

Compose secret files:

```yaml
secrets:
  db_root_pwd:
    file: ./secrets/db_root_pwd
  db_user_pwd:
    file: ./secrets/db_user_pwd
  wp_admin_pwd:
    file: ./secrets/wp_admin_pwd
  wp_user_pwd:
    file: ./secrets/wp_user_pwd
```

Containers read them from:

```text
/run/secrets/...
```

Correction nuance:

> Passwords are passed from your local environment to Ansible, then written as secret files on the remote server. The repo does not commit secrets.

---

## 9. Containers explained

## 9.1 MariaDB

Files:

```text
requirements/mariadb/Dockerfile
requirements/mariadb/conf/mariadb.cnf
requirements/mariadb/tools/entry.sh
```

Dockerfile:

- Uses Debian Bookworm.
- Installs `mariadb-server`.
- Copies MariaDB config.
- Copies entry script.
- Exposes 3306.

Config:

```ini
bind-address = 0.0.0.0
port = 3306
datadir = /var/lib/mysql
```

Why `0.0.0.0` is okay here:

> It listens inside the container/network, but Docker Compose does not publish port 3306 to the host, so it is not public.

Entry script:

1. Reads DB passwords from Docker secrets.
2. Creates `/run/mysqld`.
3. If the DB is not initialized:
   - runs `mariadb-install-db`
   - starts a temporary local DB
   - sets root password
   - creates WordPress database
   - creates WordPress DB user
   - grants privileges
4. Starts MariaDB in the foreground.

### 9.2 WordPress / PHP-FPM

Files:

```text
requirements/wordpress/Dockerfile
requirements/wordpress/conf/wp-config.php
requirements/wordpress/tools/entry.sh
```

Dockerfile:

- Uses Debian Bookworm.
- Installs PHP-FPM and required PHP extensions.
- Downloads WP-CLI.
- Copies config template and entry script.
- Exposes 9000.

Entry script:

1. Reads passwords from Docker secrets.
2. Downloads WordPress if not already present.
3. Generates `wp-config.php` if missing.
4. Replaces DB placeholders.
5. Fetches WordPress salts if possible.
6. Waits for MariaDB.
7. Runs `wp core install` if WordPress is not installed.
8. Creates the extra author user.
9. Installs/enables Redis cache plugin.
10. Configures PHP-FPM to listen on `0.0.0.0:${PHP_FPM_PORT}`.
11. Starts PHP-FPM in the foreground.

Correction answer:

> “The WordPress container is not Apache. It runs PHP-FPM, and Nginx forwards PHP requests to it using FastCGI.”

### 9.3 Nginx

Files:

```text
requirements/nginx/Dockerfile
requirements/nginx/conf/nginx.cnf
requirements/nginx/tools/entry.sh
```

Dockerfile:

- Uses Debian Bookworm.
- Installs Nginx, OpenSSL, and `envsubst`.
- Copies Nginx config template.
- Exposes 80 and 443.

Entry script:

1. Creates certificate directory.
2. Generates self-signed TLS cert if missing.
3. Uses `envsubst` to inject PHP port and max upload body size.
4. Starts Nginx in foreground.

Nginx config:

- Redirects HTTP to HTTPS.
- Enables TLS 1.2 and TLS 1.3.
- Adds security headers.
- Serves `/var/www/html`.
- Sends `.php` requests to:

```text
wordpress:${PHP_FPM_PORT}
```

Correction caveat:

> The certificate is self-signed, so browsers will show a warning. In production, I would use Let’s Encrypt.

### 9.4 Redis

Files:

```text
requirements/bonus/redis/Dockerfile
requirements/bonus/redis/conf/redis.cnf
requirements/bonus/redis/tools/entry.sh
```

Redis:

- Runs on port 6379.
- Is exposed only to the Docker network.
- Is used by the WordPress Redis plugin.

### 9.5 phpMyAdmin

Files:

```text
requirements/bonus/phpmyadmin/Dockerfile
requirements/bonus/phpmyadmin/tools/entry.sh
```

phpMyAdmin:

- Downloads latest phpMyAdmin.
- Generates `config.inc.php` dynamically.
- Connects to host `mariadb`.
- Runs PHP built-in server on 8080 inside the container.
- Is exposed on remote `127.0.0.1:8081`, not publicly.

Access:

```bash
ssh -L 8081:localhost:8081 root@$SERVER_IP
```

Then:

```text
http://localhost:8081
```

---

## 10. `deploy.sh` explained

File:

```text
deploy.sh
```

It uses:

```bash
set -euo pipefail
```

Meaning:

- `-e`: exit on error
- `-u`: fail on unset variables
- `-o pipefail`: fail if any command in a pipe fails

Functions:

| Function | Purpose |
|---|---|
| `check_dependencies` | verifies `ansible` and `ansible-galaxy` exist |
| `install_ansible_collections` | installs `community.docker` and `ansible.posix` |
| `check_env_vars` | validates required env vars |
| `run_playbook` | runs selected playbook |
| `usage` | prints command help |
| `main` | parses command and dispatches |

Commands:

| Command | Playbook/action |
|---|---|
| `deploy` | `playbooks/site.yml` |
| `setup` | `playbooks/setup.yml` |
| `app` | `playbooks/deploy.yml` |
| `destroy` | `playbooks/destroy.yml` |
| `status` | direct SSH command to show Docker status |

Correction answer:

> “The shell script is just a convenience wrapper. The real automation is in Ansible. The script checks prerequisites, installs required collections, validates environment variables, then calls the right playbook.”

---

## 11. `destroy.sh` explained

File:

```text
destroy.sh
```

It:

1. Warns the user.
2. Asks for confirmation.
3. Runs:

```bash
ansible-playbook playbooks/destroy.yml -i inventory/hosts.yml
```

You can also destroy via:

```bash
./deploy.sh destroy
```

Correction warning:

> “Destroy removes persistent data. It is intentionally protected by confirmation.”

---

## 12. Security model

### 12.1 What is protected

- Only ports 22, 80, and 443 are public.
- MariaDB is internal only.
- Redis is internal only.
- WordPress PHP-FPM is internal only.
- phpMyAdmin is bound to remote localhost only.
- Secrets are not stored in Git.
- Secret copy task uses `no_log: true`.
- Secret files are mode `0600`.
- Secret directory is mode `0700`.

### 12.2 What is acceptable for 42 but not ideal for production

| Choice | Why it is okay here | Production improvement |
|---|---|---|
| `host_key_checking = False` | avoids SSH prompt on fresh correction VM | keep host key checking enabled |
| SSH as `root` | simple cloud bootstrap | non-root sudo user |
| Self-signed cert | easy HTTPS without DNS dependency | Let’s Encrypt |
| Passwords in `.env` | standard Compose pattern, mode `0600` | Vault/secret manager |
| `docker system prune` | cleans old resources | avoid broad prune on shared servers |
| `phpMyAdmin-latest` | convenient | pin exact version |
| WordPress tarball fixed at 6.6.2 | reproducible-ish | update/pin intentionally |

---

## 13. Troubleshooting

### 13.1 Ansible cannot connect

Check:

```bash
echo "$SERVER_IP"
echo "$SSH_KEY_PATH"
ssh -i "$SSH_KEY_PATH" root@"$SERVER_IP"
ansible all -i inventory/hosts.yml -m ping -vv
```

Common causes:

- Wrong IP.
- SSH key not added to server.
- SSH key path wrong.
- Cloud firewall blocks port 22.
- Server still booting.

### 13.2 Missing environment variables

Run:

```bash
env | grep -E 'SERVER_IP|DB_|WP_|DOMAIN_NAME|SSH_KEY_PATH'
```

The required ones are:

```text
SERVER_IP
DB_ROOT_PASSWORD
DB_PASSWORD
WP_ADMIN_PASSWORD
WP_USER_PASSWORD
```

### 13.3 Docker Compose module missing

Run:

```bash
ansible-galaxy collection list | grep community.docker
ansible-galaxy collection install community.docker --force
```

The repo’s `deploy.sh` already does this for `deploy` and `setup`.

### 13.4 Website not reachable

Check:

```bash
ssh root@$SERVER_IP "docker ps"
ssh root@$SERVER_IP "ufw status verbose"
ssh root@$SERVER_IP "docker logs nginx"
curl -kI https://$SERVER_IP
```

Common causes:

- Cloud provider firewall/security group blocks 80/443.
- DNS does not point to server.
- Nginx container failed.
- WordPress container not ready.

### 13.5 MariaDB unhealthy

Check:

```bash
ssh root@$SERVER_IP "docker logs mariadb"
ssh root@$SERVER_IP "docker inspect mariadb --format='{{.State.Health.Status}}'"
```

Possible causes:

- Wrong secret files.
- Old broken DB data in `/opt/cloudone/data/db`.
- Permission issue on bind-mounted data directory.

### 13.6 WordPress install failed

Check:

```bash
ssh root@$SERVER_IP "docker logs wordpress"
ssh root@$SERVER_IP "docker logs mariadb"
```

Possible causes:

- DB not ready.
- Wrong DB password.
- WordPress tarball download failed.
- WP-CLI command failed.

### 13.7 phpMyAdmin not opening

Correct access is not public.

Use:

```bash
ssh -L 8081:localhost:8081 root@$SERVER_IP
```

Then open:

```text
http://localhost:8081
```

Do not use:

```text
http://$SERVER_IP:8081
```

because it is bound to `127.0.0.1` on the remote server.

---

## 14. Correction questions and answers

### Q: What is Ansible?

Ansible is an automation tool used here to configure a remote server over SSH. It installs packages, manages files, configures services, applies firewall rules, and deploys the Docker Compose application.

### Q: Why use Ansible instead of a shell script?

A shell script is imperative: “run this command.” Ansible is declarative/idempotent: “ensure this package exists, ensure this service is enabled, ensure this file has this content.” It also structures the project with inventories, variables, roles, modules, templates, handlers, and checks.

In this repo, `deploy.sh` only wraps Ansible; it does not replace it.

### Q: What does `ansible.cfg` do?

It sets default behavior: inventory path, SSH user, host key behavior, output format, Python interpreter detection, SSH pipelining, and privilege escalation.

### Q: What is the inventory?

`inventory/hosts.yml` lists the target server(s). It uses environment variables to inject the server IP and SSH key path.

### Q: How do you deploy to multiple servers?

Add more hosts under `all.hosts` in `inventory/hosts.yml`. The playbooks target `hosts: all`, so Ansible runs on every listed host, often in parallel.

### Q: Where are the passwords?

Locally, they are environment variables. On the server, Ansible writes them into `/opt/cloudone/secrets/*` and also renders the `.env` file required by Compose. They are not committed to Git.

### Q: How does the project avoid exposing the database?

MariaDB uses `expose: 3306`, not `ports`. That means other containers can reach it on the Docker network, but the host does not publish it publicly. UFW also only allows 22, 80, and 443.

### Q: Why is phpMyAdmin not public?

It is mapped as:

```yaml
127.0.0.1:8081:8080
```

So it only listens on localhost of the remote server. You must use SSH tunneling.

### Q: What is the role of Nginx?

Nginx is the public entrypoint. It redirects HTTP to HTTPS, serves static WordPress files, and forwards PHP requests to the WordPress PHP-FPM container.

### Q: What is PHP-FPM?

PHP-FPM is a process manager for running PHP applications. Here, WordPress runs in the PHP-FPM container, and Nginx sends PHP requests to it using FastCGI on port 9000.

### Q: What happens if the server reboots?

Docker and containerd are enabled with systemd. Containers use `restart: unless-stopped`, so they should come back automatically.

### Q: What happens if you run the playbook twice?

It should converge back to the expected state. Setup tasks are mostly idempotent. The app role intentionally stops and recreates the Compose stack while preserving persistent bind-mounted data.

### Q: Where is persistent data stored?

On the remote host:

```text
/opt/cloudone/data/db
/opt/cloudone/data/wp
```

Docker volumes bind to these paths.

### Q: Why use `community.docker.docker_compose_v2`?

Because the server installs Docker Compose as the modern Docker CLI plugin. The Ansible module manages Compose projects through Docker Compose v2.

### Q: Why use `assert` in playbooks?

To fail early if required secrets are missing, before partially deploying the application.

### Q: Why use `wait_for_connection`?

Fresh cloud servers may take time to become SSH-ready. This prevents immediate failure while the server finishes booting.

### Q: Why use healthchecks?

Container “running” does not always mean the service inside is ready. MariaDB has a healthcheck, and Ansible waits for it before validating WordPress.

### Q: Is this production-ready?

It is good for the 42 Cloud-1 scope: automated deployment, remote server setup, Dockerized services, basic firewall, secrets not committed, and multi-host-ready inventory.

For real production, improve:

- real TLS with Let’s Encrypt
- Ansible Vault / secret manager
- non-root SSH user
- backups
- monitoring
- pinned phpMyAdmin version
- external DB or replication
- load balancer if multi-server
- shared WordPress media storage

---

## 15. What to demo during correction

Use this order:

```bash
# 1. Show variables are set
env | grep -E 'SERVER_IP|DOMAIN_NAME|DB_|WP_'

# 2. Show inventory resolves
ansible-inventory -i inventory/hosts.yml --list

# 3. Show Ansible can connect
ansible all -i inventory/hosts.yml -m ping

# 4. Run deployment
./deploy.sh deploy

# 5. Check containers
./deploy.sh status

# 6. Check firewall
ssh root@$SERVER_IP "ufw status verbose"

# 7. Check public site
curl -kI https://$DOMAIN_NAME

# 8. Show phpMyAdmin tunnel
ssh -L 8081:localhost:8081 root@$SERVER_IP
```

Be ready to explain:

- why only Nginx is public
- why DB and Redis are internal
- why phpMyAdmin needs a tunnel
- where data persists
- what each role does
- how adding another host works
- why secrets are environment variables

---

## 16. Official Ansible references to read

Read these if you want the theory behind what the repo uses:

- Ansible inventory: https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html
- Ansible variables: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html
- Ansible playbooks: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks.html
- Ansible configuration settings: https://docs.ansible.com/projects/ansible/latest/reference_appendices/config.html
- `community.docker.docker_compose_v2`: https://docs.ansible.com/projects/ansible/latest/collections/community/docker/docker_compose_v2_module.html

---

## 17. One-page mental model

```text
deploy.sh
  └─ validates local env + launches Ansible

ansible.cfg
  └─ tells Ansible how to connect and where inventory is

inventory/hosts.yml
  └─ tells Ansible which server to control

inventory/group_vars/all.yml
  └─ central config used by all playbooks/roles/templates

playbooks/site.yml
  └─ full orchestration
      ├─ common role
      │   └─ base packages + app directories
      ├─ docker role
      │   └─ Docker Engine + Compose plugin
      ├─ firewall role
      │   └─ UFW: only 22/80/443 public
      └─ cloudone role
          └─ copy Compose files + write secrets + build/start containers

Docker Compose
  ├─ nginx public on 80/443
  ├─ wordpress internal on 9000
  ├─ mariadb internal on 3306
  ├─ redis internal on 6379
  └─ phpmyadmin localhost-only on 8081
```

Final sentence to remember:

> “Ansible brings the server to the desired state; Docker Compose runs the application state; the firewall and port mappings decide what is public.”
