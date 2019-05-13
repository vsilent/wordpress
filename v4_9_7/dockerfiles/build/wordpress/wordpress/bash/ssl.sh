#!/usr/bin/env bash

# ===============================================================================
#  Bash Script - Install and Deploy normal SSL.
#
# This script is used in the case that the SSL has been generated before hands.
#
# The procedure includes:
#
# - Copy SSL to **Nginx** folder
# - Add SSL to **Nginx** config file.
# - Reload Nginx.
#
# ===============================================================================

SSL_TRUSTED_CERT_FILE=${SSL_TRUSTED_CERT_FILE:-/ssl_fullchain.pem}
SSL_CERT_FILE=${SSL_CERT_FILE:-/ssl_fullchain.pem}
SSL_CERT_KEY_FILE=${SSL_CERT_KEY_FILE:-/ssl_privkey.pem}

# ----------------------------------------------------------
# Copy SSL to **Nginx** folder
#

mkdir -p /etc/nginx/ssl/$SERVER_NAME/
cp $SSL_TRUSTED_CERT_FILE /etc/nginx/ssl/$SERVER_NAME/fullchain.pem
cp $SSL_CERT_FILE /etc/nginx/ssl/$SERVER_NAME/cert.pem
cp $SSL_CERT_KEY_FILE /etc/nginx/ssl/$SERVER_NAME/privkey.pem

# ----------------------------------------------------------
# Add SSL to Nginx config
#
cp /etc/nginx/ssl-template.conf /etc/nginx/ssl.$SERVER_NAME.conf
# Generate a stronger Diffie-Hellman parameter for DHE ciphersuites, recommended 2048 bits.
# @link https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
openssl dhparam -out /etc/nginx/dhparam.pem 2048

sed -i -e "
/ssl_certificate_key/s/ssl_configuration_placeholder/\/etc\/nginx\/ssl\/$SERVER_NAME\/privkey.pem/
/ssl_certificate/s/ssl_configuration_placeholder/\/etc\/nginx\/ssl\/$SERVER_NAME\/cert.pem/
/ssl_trusted_certificate/s/ssl_configuration_placeholder/\/etc\/nginx\/ssl\/$SERVER_NAME\/fullchain.pem/" \
/etc/nginx/ssl.$SERVER_NAME.conf


# Reload
nginx -t && service nginx reload
