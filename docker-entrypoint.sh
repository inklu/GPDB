#!/bin/bash

# Load environment variables
source ~/.bashrc
source /usr/local/greenplum-db/greenplum_path.sh

# Start SSH service
#sudo /usr/sbin/sshd
sudo service ssh start
cd ~

# Configure passwordless SSH logins between hosts
if [ -f ~/hostfiles/hostfile_exkeys ]; then
    sleep 3
    echo "Passwordless SSH access configuring..."
    ssh-keyscan -t rsa -f ~/hostfiles/hostfile_exkeys >> ~/.ssh/known_hosts
    /usr/local/greenplum-db/bin/gpssh-exkeys -f ~/hostfiles/hostfile_exkeys
fi

# Configure storage for master or standbymaster
if [ "$GPDB_HOST_TYPE" == "master" -o "$GPDB_HOST_TYPE" == "standbymaster" ] && [ ! -d "/data/master" ]; then
    echo "Master Storage Configuring..."
    sudo mkdir -p /data/master
    sudo chown gpadmin:gpadmin /data/master
fi

# Configure storage for primary and mirror segments
if [ "$GPDB_HOST_TYPE" == "segment" ] && [ ! -d "/data/primary" -o ! -d "/data/mirror" ]; then
    echo "Segment Storage Configuring..."
    sudo mkdir -p /data/primary /data/mirror
    sudo chown -R gpadmin:gpadmin /data/*
fi

# GPINIT on master host and GPSTART
if [ "$GPDB_HOST_TYPE" == "master" -o "$GPDB_HOST_TYPE" == "standbymaster" ] && [ ! -f ~/gpconfigs/gpinitsystem_config ]; then
	echo "Making a copy of configs from hostfiles to master..."
	if [ ! -d ~/gpconfigs ]; then
		mkdir ~/gpconfigs
	fi
	cp ~/hostfiles/hostfile_gpinitsystem ~/gpconfigs/
	cp ~/hostfiles/gpinitsystem_config ~/gpconfigs/
	echo "GPDB Initializing..."
	/usr/local/greenplum-db/bin/gpinitsystem -a \
		-c ~/gpconfigs/gpinitsystem_config \
		-h ~/gpconfigs/hostfile_gpinitsystem
#		-O ~/gpconfigs/config_template
	echo "Finilizing GPDB initialization..."
	echo 'host     all         all             0.0.0.0/0             trust' >> /data/master/gpseg-1/pg_hba.conf
	export MASTER_DATA_DIRECTORY=/data/master/gpseg-1
	echo "export MASTER_DATA_DIRECTORY=/data/master/gpseg-1" >> ~/.bashrc
#	/usr/local/greenplum-db/bin/gpconfig -s TimeZone
#	/usr/local/greenplum-db/bin/gpconfig -c TimeZone -v 'US/Pacific'
	/usr/local/greenplum-db/bin/gpstop -ra
fi

# START DBMS
if [ "$GPDB_HOST_TYPE" == "master" ]; then
    if [ -z "$MASTER_DATA_DIRECTORY" ]; then
        export MASTER_DATA_DIRECTORY=/data/master/gpseg-1
    fi
    echo "Starting Greenplum DBMS..."
    /usr/local/greenplum-db/bin/gpstart -a --verbose
fi

# START PXF
if [ "$GPDB_PXF_ENABLED" == "true" -a "$GPDB_HOST_TYPE" == "master" ]; then
    echo "Starting PXF as a cluster..."
    /usr/local/pxf-gp6/bin/pxf cluster start
fi

# Infinite loop for background container running
if [ $# -gt 0 ]; then
    exec "$@"
else
    exec /home/gpadmin/infinite_loop.sh
fi
