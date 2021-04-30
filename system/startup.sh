#!/bin/sh
set -e

cat >/etc/httpd/conf.d/server-name.conf <<END
ServerName https://$ENDPOINT_HOST:443
UseCanonicalName On
END

/usr/local/bin/generate_shibboleth_config.py

exec supervisord -c /etc/supervisor/supervisord.conf
