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
