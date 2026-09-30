#!/bin/bash
set -euo pipefail

CERT_DIR="${NGINX_SSL_DIR}"
mkdir -p "${CERT_DIR}"

if [ ! -f "${CERT_DIR}/privkey.pem" ] || [ ! -f "${CERT_DIR}/fullchain.pem" ]; then
	echo "NGINX: Generating self-signed certificate for ${DOMAIN_NAME}"
	openssl req -x509 -nodes -days 365 \
		-newkey rsa:2048 -keyout "${CERT_DIR}/privkey.pem" -out "${CERT_DIR}/fullchain.pem" \
		-subj "/CN=${DOMAIN_NAME}" -addext "subjectAltName=DNS:${DOMAIN_NAME}"
	chmod 600 "${CERT_DIR}/privkey.pem"
fi

envsubst '${PHP_FPM_PORT} ${SERVER_MAX_BODY}' < /etc/nginx/conf.d/site.conf.template > /etc/nginx/conf.d/default.conf

echo "NGINX: starting"
exec nginx -g 'daemon off;'
