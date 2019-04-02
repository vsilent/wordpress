# Dockerized Nginx + Cache + Wordpress with SSL

[![](https://badge.imagelayers.io/cowfox/docker-wordpress-nginx-fpm-cache-ssl:latest.svg)](https://imagelayers.io/?images=cowfox/docker-wordpress-nginx-fpm-cache-ssl:latest 'Get your own badge on imagelayers.io')

Docker file with related **scripts** and **config** files to help build a Docker container that runs the following pieces **out-of-the-box**:

- PHP-FPM.
- Nginx with `fastcgi-cache` and `fastcgi_cache_purge`.
- Opcache.
- Wordpress with the **latest** version.

Also, it provides the following **scripts:

- Add **existing** SSL cert files into Nginx config.
- Auto-generate SSL cert and add into Nginx config. It is done through **letsencrypt** ([https://letsencrypt.org/](https://letsencrypt.org/))
- Auto-download a pre-defined list of Wordpress plugins.

## No DB included

This docker image does not have any DB included, in order to simplify the **configuration** process. It is recommended to use a separate **Mysql** docker container and it is very easy to configure.


## Usage

The docker image comes with the default **CMD script** - `init.sh`, which mainly does:

- Set up **default** env. variables, such as **DB host name**, **DB access info**, etc.
- Modify the `wp-config.php` based on the **env. variables**.
- Update **Server Name** to all other config files.
- Start [supervisord](http://supervisord.org/) service.

It takes five **env. variables**:

- `SERVER_NAME` - the server name that serves the Wordpress.
- `DB_HOSTNAME` - the host name of Mysql DB.
- `DB_DATABASE` - the database name of the Mysql DB that Wordpress uses.
- `DB_USER` - the Mysql username that accesses to the database.
- `DB_PASSWORD` - the password of the Mysql username that accesses to the database.

If using `docker run` CMD to build the container, be sure to use `--env` to add these variables.

### Docker Compose

When using `docker compose` config file `docker-compose.yml` to build the containers, it would be much simpler. If using `link` between **wordpress** and **mysql** containers, the `init.sh` script can automatically get the **DB access info** by using the **[link environment variables](https://docs.docker.com/compose/link-env-deprecated/)**.

> Seems that `link` can only work with **version 1** of docker compose config file.

The docker compose config file would be like this.

```
mysql:
  image: mysql:5.7
  environment:
    MYSQL_ROOT_PASSWORD: yourpassword
    MYSQL_DATABASE: wordpress
    MYSQL_USER: sample
    MYSQL_PASSWORD: yourpassword

wordpress:
  image: optimum/wp-nginx-fpm-ssl
  #build: .
  #  For now only manual execution inside docker will install certificates
  #  docker exec your_container  sh /addon/ssl.sh

  environment:
    SERVER_NAME: demo.loc
    SSL_TRUSTED_CERT_FILE: /ssl/trust.pem
    SSL_CERT_KEY_FILE: /ssl/key.pem
    SSL_CERT_FILE: /ssl/crt.pem
    DB_HOSTNAME: db
    DB_DATABASE: wordpress
    DB_USER: sample
    DB_PASSWORD: yourpassword
  ports:
    - "80:80"
    - "443:443"
  links:
    # NOTES: Be sure to keep the "alias" as `db`.
    # This alias will be used as "prefix" of **exposed ENV. variables** from DB server.
    - mysql:db
  volumes:
    - ./ssl:/ssl:ro
```

> Please note: when linking the mysql DB, be sure to assign it with an alias **db**, since `init.sh` script uses it to load the **link environment variables**.

IMPORTANT
> Do not forget to execute command: docker exec your_container  sh /addon/ssl.sh


## Scripts

When container being built, all the **three** scripts will be copied to `/addon/` folder inside the container.

- `/addon/wp-install-plugins.sh` - It helps download a **pre-defined** list of Wordpress plugins, in the variable `PLUGINS`. By default, it only has `nginx-helper` in the list. When using this script, it is recommended to modify this script (you can grab it from Github) and then **mount** it back to the container when building it.
- `/addon/ssl.sh` - It helps add **existing** SSL cert file to Nginx config. The script uses there **ENV. variables**.
	- `SSL_TRUSTED_CERT_FILE` - The **file path** to the **trusted cert file**. The path must be **inside** the container.
	- `SSL_CERT_FILE` - The **file path** to the **cert file**.
	- `SSL_CERT_KEY_FILE` - The **file path** to the **private key file**.
- `/addon/letsencrypt/ssl-letsencrypt.sh` - It help auto-generate the `letsencrypt` SSL cert and add to Nginx config. The script uses there **ENV. variables**.
	- `LE_WEBROOT` - The **web root** that `letsencrypt` uses. By default, it is `/tmp/letsencrypt-auto`.
	- `LE_INI_FILE` - The **file path** to the **ini** files that used to generate the SSL cert. By default, it is `/letsencrypt-le.ini`.
	- `LE_ACME_FILE` - The **file path** to the **location block of ACME Challenge** that `letsencrypt` uses. By default, it is `/nginx-acme.challenge.le.conf`.

For the file `letsencrypt-le.ini` and `nginx-acme.challenge.le.conf`, you can check the Github repo (`/config/addon/`) for example.


## Customize it

Besides the above scripts and sample files, Github repo also ships with the **config** files that Nginx uses, like `nginx.conf`, site config, SSL config, etc. If needed to modify them, just `git clone` from Github, modify them and then do docker image build on your side.

## License

MIT




