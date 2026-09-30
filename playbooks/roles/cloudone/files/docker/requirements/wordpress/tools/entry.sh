#!/bin/bash
set -euo pipefail

DB_PASS="$(cat /run/secrets/db_user_pwd)"
ADMIN_PASS="$(cat /run/secrets/wp_admin_pwd)"
USER_PASS="$(cat /run/secrets/wp_user_pwd)"

DOCROOT="/var/www/html"

PHP_VERS=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
PHP_FPM_CONF="/etc/php/${PHP_VERS}/fpm/pool.d/www.conf"

mkdir -p "$DOCROOT"
chown -R www-data:www-data "$DOCROOT"

if [ ! -f "${DOCROOT}/wp-settings.php" ]; then
	echo "WP: fetching dependencies"
	curl -fsSL https://wordpress.org/wordpress-6.6.2.tar.gz -o /tmp/wp.tar.gz
	tar -xzf /tmp/wp.tar.gz -C /tmp
	rsync -a /tmp/wordpress/ "${DOCROOT}/"
	rm -rf /tmp/wp.tar.gz /tmp/wordpress
fi

if [ ! -f "${DOCROOT}/wp-config.php" ]; then
	echo "WP: generating config file"
	cp /wp/wp-config.template.php "${DOCROOT}/wp-config.php"

	sed -i "s/__DB_NAME__/${MYSQL_DATABASE}/" "${DOCROOT}/wp-config.php"
	sed -i "s/__DB_USER__/${MYSQL_USER}/" "${DOCROOT}/wp-config.php"
	sed -i "s/__DB_PASSWORD__/${DB_PASS}/" "${DOCROOT}/wp-config.php"
	sed -i "s/__DB_HOST__/mariadb/" "${DOCROOT}/wp-config.php"

	SALTS="$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/ || true)"
	if [ -n "$SALTS" ]; then
		awk -v r="$SALTS" '/AUTH_KEY/{print r; f=1; next} !f{print} f&&/define.*LOGGED_IN_SALT/{f=0}' "${DOCROOT}/wp-config.php" \
		> "${DOCROOT}/wp-config.php.new" && mv "${DOCROOT}/wp-config.php.new" "${DOCROOT}/wp-config.php"
	fi

	chown -R www-data:www-data "${DOCROOT}"
fi

echo "WP: waiting for db"
for i in {1..30}; do
	if mariadb -h mariadb -u"${MYSQL_USER}" -p"${DB_PASS}" -e "SELECT 1" >/dev/null 2>&1; then
		echo "WP: database ready"
		break
	fi
	sleep 2
done

if ! wp core is-installed --path="${DOCROOT}" --allow-root >/dev/null 2>&1; then
	echo "WP: installing dependencies"
	wp core install --path="${DOCROOT}" --url="https://${DOMAIN_NAME}" --title="${WP_TITLE}" \
	--admin_user="${WP_ADMIN_USER}" --admin_password="${ADMIN_PASS}" --admin_email="${WP_ADMIN_EMAIL}" \
	--locale="${WP_LOCALE}" --skip-email --allow-root

	wp user create "${WP_USER}" "${WP_USER_EMAIL}" --user_pass="${USER_PASS}" --role=author --path="${DOCROOT}" --allow-root
	wp plugin install redis-cache --activate --allow-root --path="${DOCROOT}"
	wp redis enable --allow-root --path="${DOCROOT}"
fi

sed -i "s|^listen = .*|listen = 0.0.0.0:${PHP_FPM_PORT}|" "$PHP_FPM_CONF"
sed -i "s|^;*clear_env = .*|clear_env = no|" "$PHP_FPM_CONF"

echo "WP: starting php-fpm"
exec php-fpm${PHP_VERS} -F
