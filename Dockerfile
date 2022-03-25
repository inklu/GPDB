FROM ubuntu:18.04
#Set Locale 
ARG LANG=en_US
ARG LOCALE="${LANG}.UTF-8"
#RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
#    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
#ENV LANG en_US.utf8
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i $LANG -c -f UTF-8 -A /usr/share/locale/locale.alias $LOCALE
ENV LANG $LOCALE

#Configure /etc/systl.conf parameters
RUN set -e;\
	{ \
		echo "kernel.shmall = $(expr $(getconf _PHYS_PAGES) / 2)"; \
		echo "kernel.shmax = $(expr $(getconf _PHYS_PAGES) / 2 \* $(getconf PAGE_SIZE))"; \
		echo "kernel.shmmni = 4096"; \
		echo "vm.overcommit_memory = 2"; \
		echo "vm.overcommit_ratio = 95"; \
		echo "net.ipv4.ip_local_port_range = 10000 65535"; \
		echo "kernel.sem = 500 2048000 200 4096"; \
		echo "kernel.sysrq = 1"; \
		echo "kernel.core_uses_pid = 1"; \
		echo "kernel.msgmnb = 65536"; \
		echo "kernel.msgmax = 65536"; \
		echo "kernel.msgmni = 2048"; \
		echo "net.ipv4.tcp_syncookies = 1"; \
		echo "net.ipv4.conf.default.accept_source_route = 0"; \
		echo "net.ipv4.tcp_max_syn_backlog = 4096"; \
		echo "net.ipv4.conf.all.arp_filter = 1"; \
		echo "net.core.netdev_max_backlog = 10000"; \
		echo "net.core.rmem_max = 2097152"; \
		echo "net.core.wmem_max = 2097152"; \
		echo "vm.swappiness = 10"; \
		echo "vm.zone_reclaim_mode = 0"; \
		echo "vm.dirty_expire_centisecs = 500"; \
		echo "vm.dirty_writeback_centisecs = 100"; \
		echo "vm.dirty_background_ratio = 3 #less than 64GB Memory"; \
		echo "vm.dirty_ratio = 10 #less than 64GB Memory"; \
		echo "#vm.dirty_background_bytes = 1610612736 #more than 64GB Memory"; \
		echo "#vm.dirty_bytes = 4294967296 #more than 64GB Memory"; \
		awk 'BEGIN {OFMT = "%.0f";} /MemTotal/ {print "vm.min_free_kbytes =", $2 * .03;}' /proc/meminfo; \
	} >> /etc/systcl.conf

#Configure System Resources Limits - /etc/security/limits.conf
RUN set -e;\
	{ \
		echo "* soft nofile 524288"; \
		echo "* hard nofile 524288"; \
		echo "* soft nproc 131072"; \
		echo "* hard nproc 131072"; \
	} >> /etc/security/limits.conf

#Installation of SSH, sudo
RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends openssh-server openssh-client sudo wget; \
	rm -rf /var/lib/apt/lists/*
#Configure SSH
RUN set -e;\
	{ \
		echo "MaxStartups 200"; \
		echo "MaxSessions 200"; \
	} >> /etc/ssh/sshd_config

# CUE GPADMIN USER and Configure sudo
RUN set -e; \
  groupadd -g 8000 gpadmin; \
  useradd -m -s /bin/bash -d /home/gpadmin -g gpadmin -u 8000 gpadmin; \
  echo "gpadmin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#Installation of GPDB
#VOLUME /data
WORKDIR /home/gpadmin
#COPY ./greenplum-db-6.20.0-ubuntu18.04-amd64.deb ./
#RUN mkdir -p /data; chown -R gpadmin:gpadmin /data; \
RUN set -ex; \
	wget --no-check-certificate \
	  https://github.com/greenplum-db/gpdb/releases/download/6.20.0/greenplum-db-6.20.0-ubuntu18.04-amd64.deb; \
	apt-get update; \
	apt-get install -y --no-install-recommends ./greenplum-db-6.20.0-ubuntu18.04-amd64.deb; \
	rm -rf /var/lib/apt/lists/*; \
        rm ./greenplum-db-6.20.0-ubuntu18.04-amd64.deb; \
	chown -R gpadmin:gpadmin /usr/local/greenplum*

USER gpadmin

RUN set -e;\
	/bin/bash -c 'source /usr/local/greenplum-db/greenplum_path.sh'; \
  	echo "source /usr/local/greenplum-db/greenplum_path.sh" >> ./.bashrc

#RUN service ssh and prepare folders for configs and external data files
RUN mkdir ./.ssh/ ./hostfiles ./staging && \
  ssh-keygen -t rsa -q -f ./.ssh/id_rsa -P "" && \
  cat ./.ssh/id_rsa.pub >> ./.ssh/authorized_keys
#ssh-keyscan -t rsa -f hostfile_exkeys >> ./.ssh/known_hosts

#CMD docker-entrypoint.sh with gpfdist run as cmd parameter
COPY --chown=gpadmin:gpadmin ./*.sh ./
RUN chmod +x ./docker-entrypoint.sh ./infinite_loop.sh
ENTRYPOINT ["/home/gpadmin/docker-entrypoint.sh"]
CMD ["~/infinite_loop.sh"]
#CMD ["/usr/bin/greenplum-db/bin/gpfdist -d ~/staging -p 8081"]

#ENTRYPOINT ["/bin/bash"]
