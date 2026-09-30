FROM debian:bookworm

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	php-fpm php-cli php-mysql php-json php-opcache php-gd php-curl php-xml php-mbstring \
	ca-certificates curl less mariadb-client tar rsync && \
	rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp && \
	chmod +x /usr/local/bin/wp

WORKDIR /var/www/html

COPY conf/wp-config.php /wp/wp-config.template.php
COPY tools/entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entry.sh"]