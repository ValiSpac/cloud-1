#!/bin/bash

sleep 5

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

chmod +x wp-cli.phar
mv -f wp-cli.phar /usr/local/bin/wp
rm -f /var/www/html/wp-config.php
cp ./wp-config.php /var/www/html/wp-config.php

wp core download --allow-root --path='/var/www/html'

wp core install --allow-root \
				--path='/var/www/html' \
				--url=$WP_HOST \
				--title=$WP_TITLE \
				--admin_user=$WP_ADMIN_USER \
				--admin_password=$WP_ADMIN_PASSWORD \
				--admin_email=$WP_ADMIN_EMAIL \
				--skip-email

wp plugin update --allow-root --all

wp user create --allow-root \
				--path='/var/www/html' \
				${WP_USER} \
				${WP_EMAIL} \
				--role=author \
				--user_pass=${WP_PASSWORD}

mkdir -p /run/php
exec php-fpm7.3 -F
