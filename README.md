# GPDB
Multinode Greenplum Database in Docker

Based on ubuntu:18.04 docker image and greenplum-6.20.0 

# RUN
$ docker-compose up -d

# Connection
HOST localhost

PORT 5433

USER gpadmin

PASSWORD gparray

DATABASE gpadmin

# Cluster by default
hosts: 
1) mdw - master
2) sdw1 - segment
3) sdw2 - segment

6 segments - 3 by each segment host

no standbymaster and no one mirror configured by default

# Cluster configuration
Before the first run make changes to configuration files in folder hostfile/
1) gpinitsystem_config - DATA_DIRECTORY=(/data/primary /data/primary /data/primary) determine a number of segments on a one segment host
2) hostfile_exkeys - all of hosts of the cluster
3) hostfile_gpinitsystem - only segment hosts of the cluster

Make changes to docker-compose.yml
1) define your own number of docker segment services with own data volume
