#!/bin/sh

# Copy distribution config files to /srv as example
mkdir -p /srv/etc
cp /etc/apache2/conf-available/SOGo.conf /srv/etc/apache-SOGo.conf.orig

# Copy back and enable administrator's configuration
cp /srv/etc/apache-SOGo.conf /etc/apache2/conf-enabled/SOGo.conf

# Run apache in foreground
APACHE_ARGUMENTS="-DNO_DETACH" exec /usr/sbin/apache2ctl start
