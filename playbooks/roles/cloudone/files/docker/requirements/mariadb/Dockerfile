FROM debian:bookworm

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	mariadb-server ca-certificates tzdata && \
	rm -rf /var/lib/apt/lists/* && \
	rm -f /etc/mysql/mariadb.conf.d/50-server.cnf && \
	rm -rf /var/lib/mysql/*


COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh && mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/entry.sh"]