# GPDB
Multinode Greenplum Database in Docker

Based on ubuntu:18.04 docker image and greenplum-6.20.0 

# RUN
`$ docker-compose up -d`
or you can use `docker pull trueknight/gpdb:tagname` with tagname `latest` and `pxf`. `latest` exludes PXF

# Connection
HOST `localhost`

PORT `5433`

USER `gpadmin`

PASSWORD `gparray`

DATABASE `template1`

If connections outside of localhost are not allowed, modify `/data/master/gpseg-1/pg_hba.conf` on the master host (mdw container) and restart the server.
For instance add a line `host  all  all  0.0.0.0/0  trust` to pg_hba.conf

# Cluster by default
hosts: 
1) mdw - master
2) sdw1 - segment
3) sdw2 - segment

6 segments (3 on each segment host)

no standbymaster and no one mirror were configured by default

# Cluster initialization
Before the first run modify configuration files in folder `hostfile/`
1. `gpinitsystem_config` - `DATA_DIRECTORY=(/data/primary /data/primary /data/primary)` determine a number of segments on a one segment host
2. `hostfile_exkeys` - all of hosts of the cluster
3. `hostfile_gpinitsystem` - only segment hosts of the cluster

Make changes to `docker-compose.yml` - define your own number of docker services with its data volumes

# Using `gpfdist`
`gpfdist` is started on each host on port 8081. Files must be placed in `./staging` directory attached to each host as docker volume.

Example of typing `LOCATION ('gpfdist://mdw:8081/*.txt')` - mdw is a docker service name of the master host by default

# PXF
It can be enabled using `gpdb:pxf` image build from Dockerfile_PXF. It depends on `pxf-gp6-6.3.0-2-ubuntu18.04-amd64.deb` which can be downloaded from https://network.pivotal.io/products/pivotal-gpdb/ 

`$PXF_HOME=/usr/local/pxf-gp6`

`$PXF_BASE=$PXF_HOME/base`

`$PXF_LOADER_PATH=$PXF_BASE/lib`

`$PXF_PORT=5998` (standard 5888 was occupied in my deployment)
