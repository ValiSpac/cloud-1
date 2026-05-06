# Inception

## Description
Inception is a project that involves setting up a small infrastructure using Docker and Docker Compose. The goal is to create and configure multiple services while following specific rules to ensure security, scalability, and best practices.

## Technologies Used
- Docker
- Docker Compose
- NGINX
- WordPress with PHP-FPM
- MariaDB
- Alpine/Debian (latest stable version excluding the latest tag)

## Project Structure
```
project_root/
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   ├── db_root_password.txt
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   ├── requirements/
│   │   ├── mariadb/
│   │   │   ├── Dockerfile
│   │   │   ├── conf/
│   │   │   ├── tools/
│   │   ├── nginx/
│   │   │   ├── Dockerfile
│   │   │   ├── conf/
│   │   │   ├── tools/
│   │   ├── wordpress/
│   │   │   ├── Dockerfile
│   │   │   ├── conf/
│   │   │   ├── tools/
```

## Services
### 1. **NGINX**
- Acts as a reverse proxy.
- Uses TLSv1.2 or TLSv1.3 only.
- Listens only on port 443.

### 2. **WordPress with PHP-FPM**
- Installed and configured in a separate container.
- No NGINX inside this container.
- Stores website files in a persistent volume.

### 3. **MariaDB**
- Acts as the database server.
- Runs in its own container.
- Uses a persistent volume to store data.
- Two users exist: one admin (with restricted naming) and one regular user.

### 4. **Volumes**
- `/home/<login>/data/mariadb/` for database persistence.
- `/home/<login>/data/wordpress/` for WordPress files.

### 5. **Networking**
- Containers communicate over a dedicated Docker network.
- `network: host`, `--link`, and `links:` are strictly forbidden.

## Installation & Usage
### Prerequisites
- Docker
- Docker Compose

### Setup
1. Clone the repository:
   ```sh
   git clone https://github.com/yourusername/inception.git
   cd inception
   ```
2. Configure your `.env` file:
   ```sh
   DOMAIN_NAME=yourlogin.42.fr
   MYSQL_USER=youruser
   MYSQL_PASSWORD=yourpassword
   ```
3. Build and start the services:
   ```sh
   make up
   ```
4. Access the WordPress website via:
   ```sh
   https://yourlogin.42.fr
   ```

## Available Commands
| Command   | Description |
|-----------|-------------|
| `make up` | Build and start containers |
| `make stop` | Stop containers |
| `make start` | Restart stopped containers |
| `make restart` | Restart all services |
| `make down` | Stop and remove containers, images, and volumes |
| `make clean` | Remove all Docker resources |
| `make prune` | Perform a system-wide Docker cleanup |
| `make fclean` | Completely remove all volumes and clean up |
