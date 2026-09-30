FROM debian:bookworm

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	nginx openssl ca-certificates gettext-base && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html /etc/nginx/conf.d /etc/nginx/certs

COPY conf/nginx.cnf /etc/nginx/conf.d/site.conf.template
COPY tools/entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh

EXPOSE 443 80
ENTRYPOINT ["/usr/local/bin/entry.sh"]
