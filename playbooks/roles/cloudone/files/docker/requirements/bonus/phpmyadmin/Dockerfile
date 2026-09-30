FROM debian:bookworm

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	php php-mysql php-cli php-curl php-xml php-mbstring \
	ca-certificates wget && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/phpmyadmin /var/lib/phpmyadmin/tmp && \
	wget -q https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
		-O /tmp/pma.tar.gz && \
	tar -xzf /tmp/pma.tar.gz --strip-components=1 -C /var/www/phpmyadmin && \
	rm -f /tmp/pma.tar.gz && \
	chown -R www-data:www-data /var/www/phpmyadmin /var/lib/phpmyadmin

WORKDIR /var/www/phpmyadmin

COPY tools/entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entry.sh"]