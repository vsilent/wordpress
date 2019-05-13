#!/usr/bin/env bash

# ===============================================================================
#  Bash Script - Install and Deploy `letsencrypt` SSL.
#
#
# The procedure includes:
#
# - Download the ACME Client for letsencrypt.
# - Create `webroot`
# - Change the site's config in **Nginx** to prepare ACME challenge - `/.well-known/acme-challenge/xxxxxxxxxxx`
#   It is under "80" port, not "443" port.
# - Reload Nginx.
# - Set up the `ini` file
# - Run `letsencrypt-auto` to install and generate the SSL.
# - Add SSL to **Nginx** config file.
# - Reload Nginx.
#
#
# @link https://letsencrypt.org/ | letsencrypt
# @link https://github.com/letsencrypt/letsencrypt | ACME Client
# ACME - Automatic Certificate Management Environment (https://letsencrypt.github.io/acme-spec/)
#
# -----------------------
# ## NOTE:
# Before running it, be sure the DNS (A record) for the domain is set up correctly.
# 
# ===============================================================================

LE_WEBROOT=${LE_WEBROOT:-/tmp/letsencrypt-auto}
LE_INI_FILE=${LE_INI_FILE:-/letsencrypt-le.ini}
LE_ACME_FILE=${LE_ACME_FILE:-/nginx-acme.challenge.le.conf}

# ----------------------------------------------------------
# Download the code of the ACME Client from Github.
#
cd /
git clone https://github.com/letsencrypt/letsencrypt

# ----------------------------------------------------------
# Switch the site's config in Nginx to SSL ready 
# 
cp /etc/nginx/nginx-site-https.conf /etc/nginx/sites-available/default
cp $LE_ACME_FILE /etc/nginx/acme.challenge.le.conf

# Create a folder as the "web root" folder of letsencrypt
mkdir -p $LE_WEBROOT

# Reload
nginx -t && service nginx reload

# ----------------------------------------------------------
# Install letsencrypt and generate SSL.
#

mkdir -p /etc/letsencrypt/
cp $LE_INI_FILE /etc/letsencrypt/cli.ini

# Start the installation and generate the SSL cert
cd /letsencrypt
./letsencrypt-auto certonly -c /etc/letsencrypt/cli.ini
# Once successful, the cert files will be under `/etc/letsencrypt/live/domain.com/`,
# including teh file `fullchain.pem` and `privkey.pem`


# ----------------------------------------------------------
# Add `letsencrypt` SSL to Nginx config
#
cp /etc/nginx/ssl-template.conf /etc/nginx/ssl.$SERVER_NAME.conf
# Generate a stronger Diffie-Hellman parameter for DHE ciphersuites, recommended 2048 bits.
# @link https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
openssl dhparam -out /etc/nginx/dhparam.pem 2048

sed -i -e "
/ssl_certificate_key/s/ssl_configuration_placeholder/\/etc\/letsencrypt\/live\/$SERVER_NAME\/privkey.pem/
/ssl_certificate/s/ssl_configuration_placeholder/\/etc\/letsencrypt\/live\/$SERVER_NAME\/cert.pem/
/ssl_trusted_certificate/s/ssl_configuration_placeholder/\/etc\/letsencrypt\/live\/$SERVER_NAME\/fullchain.pem/" \
/etc/nginx/ssl.$SERVER_NAME.conf

# Reload
nginx -t && service nginx reload
