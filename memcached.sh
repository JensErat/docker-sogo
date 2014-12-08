#!/bin/sh
exec /sbin/setuser memcache /usr/bin/memcached -m ${memcached:-64} >>/var/log/memcached.log 2>&1
