#!/usr/bin/env python
# -*- coding: utf-8 -*-

import time
import docker
import requests

client = docker.from_env()

time.sleep(10)
for c in client.containers.list():
    assert c.status == 'running'


# NGINX
nginx = client.containers.get('nginx')
nginx_cfg = nginx.exec_run("/usr/sbin/nginx -T")
assert nginx.status == 'running'
# assert 'server_name _;' in nginx_cfg.output.decode()
# assert "error_log /proc/self/fd/2" in nginx_cfg.output.decode()
# assert "location = /.well-known/acme-challenge/" in nginx_cfg.output.decode()
assert 'HTTP/1.1" 500' not in nginx.logs()

# test restart
nginx.restart()
time.sleep(3)
assert nginx.status == 'running'

# Symfony PHP
php = client.containers.get('wordpress')
assert php.status == 'running'
php_conf = php.exec_run("php-fpm7.0 -t")
# assert 'configuration file /usr/local/etc/php-fpm.conf test is successful' in php_conf.output.decode()
# php_proc = php.exec_run("ps aux |grep php-fpm")
# assert 'php-fpm: master process (/usr/local/etc/php-fpm.conf)' in php_proc.output.decode()
assert 'fpm is running, pid' in php.logs()
# response = requests.get("http://localhost")
# assert response.status_code == 200

mysql = client.containers.get('wpdb')
assert mysql.status == 'running'
mycnf = mysql.exec_run("/usr/sbin/mysqld --verbose  --help")
assert '/usr/sbin/mysqld  Ver 5.7.26' in mycnf.output.decode()
mysql_log = mysql.logs()
assert "Ready to accept connections" in mysql_log.decode()
