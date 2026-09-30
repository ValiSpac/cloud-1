# Cloud-1: Automated Inception Deployment

> Automated deployment of a WordPress infrastructure on a remote cloud server using Ansible.

## Overview

Deploys a WordPress site with supporting services (MariaDB, Nginx, Redis, phpMyAdmin) to a remote Ubuntu 20.04 LTS server. Each service runs in its own container, orchestrated via `docker-compose.yml` and deployed entirely through Ansible.

### Services

| Service | Port | Access |
|---------|------|--------|
| **Nginx** | 443, 80 | Public (HTTP redirects to HTTPS) |
| **WordPress** | 9000 | Internal (via Nginx) |
| **MariaDB** | 3306 | Internal only |
| **Redis** | 6379 | Internal only |
| **phpMyAdmin** | 8081 | SSH tunnel only |

## Quick Start

### Prerequisites

- Python 3 + pip
- Ansible (`pip3 install ansible`)
- SSH key added to your 42 profile

### 1. Set Environment Variables

```bash
export SERVER_IP="your.server.ip"
export DB_ROOT_PASSWORD="secure_root_password"
export DB_PASSWORD="secure_db_password"
export WP_ADMIN_PASSWORD="secure_admin_password"
export WP_USER_PASSWORD="secure_user_password"

# Optional
export DOMAIN_NAME="yoursite.duckdns.org"
```

### 2. Deploy

```bash
./deploy.sh deploy
```

### 3. Access Your Site

- **WordPress**: `https://YOUR_DOMAIN`
- **Admin Panel**: `https://YOUR_DOMAIN/wp-admin`
- **phpMyAdmin** (via SSH tunnel): `ssh -L 8081:localhost:8081 root@SERVER_IP` then open `http://localhost:8081`

## Project Structure

```
cloud-1/
├── deploy.sh              # Main deployment script
├── destroy.sh             # Teardown script
├── ansible.cfg            # Ansible configuration
├── inventory/
│   ├── hosts.yml          # Server inventory (multi-host ready)
│   └── group_vars/
│       └── all.yml        # Variables (domain, ports, paths)
├── playbooks/
│   ├── site.yml           # Full deployment (setup + deploy)
│   ├── setup.yml          # Server setup only
│   ├── deploy.yml         # App deployment only
│   └── destroy.yml        # Teardown
└── roles/
    ├── common/            # Base packages, directories, timezone
    ├── docker/            # Docker CE installation + daemon config
    ├── firewall/          # UFW rules (22, 80, 443 only)
    └── cloudone/          # App deployment (compose, env, secrets)
```

## Ansible Roles

| Role | Purpose |
|------|---------|
| **common** | Installs base packages, creates app directories, installs Python Docker module |
| **docker** | Adds Docker APT repo, installs Docker CE + Compose plugin, configures daemon |
| **firewall** | Configures UFW: deny all incoming, allow SSH/HTTP/HTTPS only |
| **cloudone** | Copies Docker files, templates `.env`, writes secrets, runs `docker compose up` |

## Security

- UFW firewall: only ports 22, 80, 443 open
- MariaDB/Redis not exposed to the internet
- phpMyAdmin accessible only via SSH tunnel
- Secrets passed as environment variables, written to Docker secrets files on the server
- HTTP automatically redirects to HTTPS
- No credentials stored in the repository

## Commands

| Command | Description |
|---------|-------------|
| `./deploy.sh deploy` | Full deployment |
| `./deploy.sh setup` | Server setup only |
| `./deploy.sh app` | App deployment only |
| `./deploy.sh status` | Check deployment status |
| `./deploy.sh destroy` | Remove everything |

## Notes

1. **Never commit secrets** — use environment variables
2. **Data persists in** `/opt/cloudone/data` on the server
3. **Services auto-restart** on server reboot (`restart: unless-stopped`)
4. Multi-server: add hosts to `inventory/hosts.yml`, all playbooks target `hosts: all`
