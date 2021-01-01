# Unmaintained

I stopped using SOGo some time ago. This repository and the image is not maintained any more.

# SOGo for Docker

[SOGo](http://www.sogo.nu) is fully supported and trusted groupware server with a focus on scalability and open standards. SOGo is released under the GNU GPL/LGPL v2 and above. 

This Dockerfile packages SOGo as packaged by Inverse, SOGo's creators, together with Apache 2 and memcached.

There are different flavors of this Docker image, added as tags. To checkout a specific flavor, use `jenserat/docker:[tag]` as image name. By default, `latest` wil be used.

  - **latest**: normal SOGo release
  - **nightly**: nightly builds, rebuild automatically
  - **activesync**: like latest, but includes ActiveSync module
  
    Please be aware that ActiveSync uses patented technology and might require negotiating with Microsoft. From the [SOGo documentation](http://www.sogo.nu/files/docs/SOGo%20Installation%20Guide.pdf):

    > In order to use the SOGo ActiveSync support code in production
    > environments, you need to get a proper usage license from Microsoft.
    > Please contact them directly to negotiate the fees associated to your
    > user base.

  - **activesync-nightly**: like nightly, but includes ActiveSync module

## Setup

The image stores configuration, logs and backups in `/srv`, which you should persist somewhere. Example configuration is copied during each startup of the container, which you can adjust for your own use. For creating the initial directory hierarchy and example configuration, simply run the container with the `/srv` volume already exposed or linked, for example using

    docker run -v /srv/sogo:/srv jenserat/sogo

As soon as the files are created, stop the image again. You will now find following files:

    .
    ├── etc
    │   ├── apache-SOGo.conf.orig
    │   └── sogo.conf.orig
    └── lib
        └── sogo
            └── GNUstep
                ├── Defaults
                └── Library

Create copies of the configuration files named `apache-SOGo.conf` and `sogo.conf.orig`. Don't change or link the `.orig` files, as they will be overwritten each time the container is started. They can also be used to see differences on your configuration after SOGo upgrades.

### Database

A separate database is required, for example a PostgreSQL container as provided by the Docker image [`paintedfox/postgresql`](https://registry.hub.docker.com/u/paintedfox/postgresql/), but also any other database management system SOGo supports can be used. Follow the _Database Configuration_ chapter of the SOGo documentation on these steps, and modify the sogo.conf` file accordingly. The following documentation will expect the database to be available with the SOGo default credentials given by the official documentation, adjust them as needed. If you link a database container, remember that it will be automatically added to the hosts file and be available under the chosen name.

For a container named `sogo-postgresql` linked as `db` using `--link="sogo-postgresql:db"` with default credentials, you would use following lines in the `sogo.conf`:

    SOGoProfileURL = "postgresql://sogo:sogo@db:5432/sogo/sogo_user_profile";
    OCSFolderInfoURL = "postgresql://sogo:sogo@db:5432/sogo/sogo_folder_info";
    OCSSessionsFolderURL = "postgresql://sogo:sogo@db:5432/sogo/sogo_sessions_folder";

SOGo performs schema initialziation lazily on startup, thus no database initialization scripts must be run.

### memcached

As most users will not want to separate memcached, there is a built-in daemon. It can be controled by setting the environment variable `memcached`. If set to `false`, the built-in memcached will not start, make sure to configure an external one. Otherwise, the variable holds the amount of memory dedicated to memcached in MiB. If unset, a default of 64MiB will be used.

### Sending Mail

For convenience reasons, the gateway is added to the hostsfile as host `GATEWAY` before starting the SOGo daemon. This enables you to use a local MTA in the host machine to forward mail using

    SOGoMailingMechanism = "smtp";
    SOGoSMTPServer = "GATEWAY";
 
For further details in MTA configuration including SMTP auth, refer to SOGo's documentation.

### Apache and HTTPs

As already given above, the default Apache configuration is already available under `etc/apache-SOGo.conf.orig`. The container exposes HTTP (80), HTTPS (443) and 8800, which is used by Apple devices, and 20000, the default port the SOGo daemon listens on. You can either directly include the certificates within the container, or use an external proxy for this. Make sure to only map the required ports to not unnecessarily expose daemons.

You need to adjust the `<Proxy ...>` section and include port, server name and url to match your setup.

    <Proxy http://127.0.0.1:20000/SOGo>
    ## adjust the following to your configuration
      RequestHeader set "x-webobjects-server-port" "443"
      RequestHeader set "x-webobjects-server-name" "sogo.example.net"
      RequestHeader set "x-webobjects-server-url" "https://sogo.example.net"

If you want to support iOS-devices, add appropriate `.well-known`-rewrites in either the Apache configuration or an external proxy.

For ActiveSync support, additionally add/uncomment the following lines:

    ProxyPass /Microsoft-Server-ActiveSync \
      http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync \
      retry=60 connectiontimeout=5 timeout=360


### Cron-Jobs: Backup, Session Timeout, Sieve

SOGo heavily relies on cron jobs for different purposes. The image provides SOGo's original cron file as `./etc/cron.orig`. Copy and edit it as `./etc/cron`. The backup script is available and made executable at the predefined location `/usr/share/doc/sogo/sogo-backup.sh`, so backup is fully functional immediately after uncommenting the respective cron job.

### Further Configuration

Unlike the Debian and probably other SOGo packages, the number of worker processes is not set in `/etc/default/sogo`, but the normal `sogo.conf`. Remember to start a reasonable number of worker processes matching to your needs (8 will not be enough for medium and larger instances):

    WOWorkersCount = 8;

ActiveSync requires one worker per concurrent connection.

All other configuration options have no special considerations.

## Running a Container

Run the image in a container, expose ports as needed and making `/srv` permanent. An example run command, which links to a database container named `db` and uses an external HTTP proxy for wrapping in HTTPS might be

    docker run -d \
      --name='sogo' \
      --publish='127.0.0.1:80:80' \
      --link='sogo-postgresql:db' \
      --volume='/srv/sogo:/srv' \
      jenserat/sogo

## Upgrading and Maintenance

Most of the time, no special action must be performed for upgrading SOGo. Read the _Upgrading_ section of the [Installation Manual](http://www.sogo.nu/files/docs/SOGo%20Installation%20Guide.pdf) prior upgrading the container to verify whether anything special needs to be considered.

As the image builds on [`phusion/baseimage`](https://github.com/phusion/baseimage-docker), you can get a shell for running update scripts when necessary or perform similar maintenance operations by adding `/sbin/my_init -- /bin/bash` as run command and subsequently attaching to the container:

    docker run -t -i -d \
      --name='sogo' \
      --publish='127.0.0.1:80:80' \
      --link='sogo-postgresql:db' \
      --volume='/srv/sogo:/srv' \
      jenserat/sogo /sbin/my_init -- /bin/bash

This is fine for running update scripts on the database. To be able to perform persistent changes to the file system (without creating new containers), red the [`phusion/baseimage`](https://github.com/phusion/baseimage-docker) documentation on attaching to the container.
