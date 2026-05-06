FROM debian:buster

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt install -y nginx openssl

RUN mkdir /etc/nginx/ssl
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt \
-keyout /etc/nginx/ssl/inception.key \
-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=vpac.42.fr/UID=vpac"

RUN mkdir -p /run/nginx

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf


RUN chmod 777 /var/www/html
RUN chown -R www-data:www-data /var/www/html

EXPOSE 443

CMD [ "nginx", "-g", "daemon off;" ]



