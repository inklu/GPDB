# GPDB
Multinode Greenplum Database in Docker

#RUN
docker-compose up -d

#Connection
HOST = localhost
PORT = 5433
USER = gpadmin
PASSWORD = gparray

#Cluster by default
hosts: 
1) mdw - master
2) sdw1 - segment
3) sdw2 - segment
6 segments - 3 by each segment host
