FROM debian:buster

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y wget
RUN apt-get install -y php7.3 \
php-fpm \
php-mysql \
mariadb-client \
php-mysqli

RUN rm -rf /etc/php/7.3/fpm/pool.d/www.conf
COPY ./conf/def.conf /etc/php/7.3/fpm/pool.d/www.conf

RUN mkdir 		-p /var/www/html
RUN adduser 	-u 82 www-data www-data
RUN chmod 777	-R /var/www/html
RUN chown 		-R www-data:www-data /var/www/html

COPY ./conf/wp-config.php ./
COPY ./conf/script.sh ./

RUN chmod +x ./script.sh
ENTRYPOINT ["./script.sh"]

EXPOSE 9000
