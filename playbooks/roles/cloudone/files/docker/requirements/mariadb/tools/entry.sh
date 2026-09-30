#!/bin/bash
set -euo pipefail

DB_DIR="/var/lib/mysql"
SOCKET_DIR="/run/mysqld"

USR_PWD="$(cat /run/secrets/db_user_pwd)"
ROOT_PWD="$(cat /run/secrets/db_root_pwd)"

mkdir -p "$SOCKET_DIR"
chown -R mysql:mysql "$SOCKET_DIR" "$DB_DIR"

if [ ! -d "${DB_DIR}/mysql" ]; then
	echo "MARIADB: initializing database"
	mariadb-install-db --user=mysql --datadir="${DB_DIR}" --rpm > /dev/null

	mariadbd --user=mysql --datadir="${DB_DIR}" --skip-networking &
	TEMP_PID=$!

	for i in $(seq 1 30); do
		if mariadb -u root -e "SELECT 1" >/dev/null 2>&1; then
			break
		fi
		sleep 1
	done

	mariadb -u root <<SQL
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PWD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${USR_PWD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

	kill "$TEMP_PID"
	wait "$TEMP_PID" 2>/dev/null || true
fi

echo "MARIADB: starting server"
exec mariadbd --user=mysql --console