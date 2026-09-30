FROM debian:bookworm

RUN apt-get update && \
	apt-get install -y --no-install-recommends redis-server && \
	rm -rf /var/lib/apt/lists/*

COPY conf/redis.cnf /etc/redis/redis.conf
COPY tools/entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh

EXPOSE 6379
ENTRYPOINT ["/usr/local/bin/entry.sh"]