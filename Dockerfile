FROM            phusion/baseimage
MAINTAINER	Jens Erat <email@jenserat.de>

# Install some very basic administrative tools
RUN apt-get update
RUN apt-get install -y gettext-base vim

# Baseimage init process
ENTRYPOINT ["/sbin/my_init"]

# Install Apache
RUN apt-get install -y apache2
RUN a2enmod headers proxy proxy_http rewrite ssl

# Install SOGo from repository
RUN echo "deb http://inverse.ca/ubuntu trusty trusty" > /etc/apt/sources.list.d/inverse.list
RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-key FE9E84327B18FF82B0378B6719CDA6A9810273C4
RUN apt-get update
RUN apt-get install -y sogo sope4.9-gdl1-postgresql

# Fix memcached not listening on IPv6
RUN sed -i -e 's/^-l.*/-l localhost/' /etc/memcached.conf

# Move SOGo's data directory to /srv
RUN usermod --home /srv/lib/sogo sogo

# SOGo daemons
RUN mkdir /etc/service/sogod /etc/service/apache2 /etc/service/memcached
ADD sogod.sh /etc/service/sogod/run
ADD apache2.sh /etc/service/apache2/run
ADD memcached.sh /etc/service/memcached/run

# Make GATEWAY host available
RUN mkdir -p /etc/my_init.d
ADD gateway.sh /etc/my_init.d/
# https://github.com/phusion/baseimage-docker#workaroud_modifying_etc_hosts
RUN /usr/bin/workaround-docker-2267

# Interface the environment
VOLUME /srv
EXPOSE 80 443 8800

# Clean up for smaller image
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
