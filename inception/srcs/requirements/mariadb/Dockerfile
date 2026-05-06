FROM debian:buster

ARG SQL_DATABASE
ARG SQL_USER
ARG SQL_PASSWORD
ARG SQL_ROOT_PASSWORD

RUN apt update -y
RUN apt upgrade -y
RUN apt-get install mariadb-server -y

RUN mkdir -p /var/run/mysql
RUN chown -R mysql:mysql /var/run/mysql

RUN chmod -R ug+rw /var/lib/mysql
RUN chown -R mysql:mysql /var/lib/mysql


RUN service mysql start && mysql -u root -e "CREATE DATABASE IF NOT EXISTS $SQL_DATABASE; \
ALTER USER 'root'@'localhost' IDENTIFIED BY '$SQL_ROOT_PASSWORD'; \
CREATE USER IF NOT EXISTS '$SQL_USER'@'localhost' IDENTIFIED BY '$SQL_PASSWORD'; \
GRANT ALL PRIVILEGES ON $SQL_DATABASE.* TO '$SQL_USER'@'%' IDENTIFIED BY '$SQL_PASSWORD'; FLUSH PRIVILEGES;"

COPY conf/50-server.cnf	/etc/mysql/mariadb.conf.d/50-server.cnf

CMD ["mysqld", "--bind-address=0.0.0.0"]

EXPOSE 3306

