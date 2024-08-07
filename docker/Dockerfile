# Dockerfile revised based on the DAOS v2.4 release at
# https://github.com/daos-stack/daos/blob/release/2.4/utils/docker/vcluster/daos-client/el8/Dockerfile

# Command to build it
# $ podman/docker build -t <tag> [--no-cache] .
#
# Command to run the container:
#   Ref: https://docs.daos.io/v2.4/QSG/docker/#running-the-daos-containers
# $ docker run --detach --privileged --name=daos-client --hostname=daos-client \
#     --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
#     --network=host <docker_image>
#
# Before running this docker image, remember to setup the IPoIB address for the corresponding IB devices.
#
# 'recipe' for building a RHEL variant docker image of a DAOS client node
#
# This Dockerfile accept the following input build arguments:
# - BASE_IMAGE                     	Base docker image to use (default "rockylinux/rockylinux")
# - ROCKY_VERSION                   Rocky Version of the base docker image to use (default "8.8")
# - DAOS_AUTH                      	Enable DAOS authentication when set to "yes" (default "yes")
# - DAOS_ADMIN_USER                	Name or uid of the daos administrattor user (default "root")
# - DAOS_ADMIN_GROUP               	Name or gid of the daos administrattor group (default "root")
# - DAOS_AGENT_IFACE_CFG           	Enable manual configuration of the interface to use by the agent (default "yes")
# - DAOS_AGENT_IFACE_NUMA_NODE     	Numa node of the interface to use by the agent (default "0")
# - DAOS_AGENT_IFACE_NAME          	Name of the interface to use by the agent (default "ib1")
# - DAOS_AGENT_IFACE_DOMAIN_NAME   	Domain name of the interface to use by the agent (default "mlx5_1")

# Pull base image
ARG BASE_IMAGE=rockylinux/rockylinux
ARG	ROCKY_VERSION=8.8
FROM $BASE_IMAGE:$ROCKY_VERSION as base
LABEL maintainer="xmei@jlab.org"
LABEL description="The docker file to set up EJFAT tesbed nodes for DAOS client."

## Install the Infiniband kernels and drivers on host OS.
# sudo apt install infiniband-diags ibutils ibverbs-utils rdmacm-utils libibverbs-dev

## Install Infiniband utilities tools in docker image.
RUN yum update -y && yum install -y rdma-core libibverbs

## Install dependencies
# wget and ucx are must-haves. ucx is for dRPC.
RUN yum install -y wget epel-release ucx ucx-devel

# Install necessary tools for BW debugging and testing. In production mode we can remove them.
RUN yum install -y iputils iproute net-tools perftest infiniband-diags daos-devel && yum clean all

## Install DAOS client package
# Configure access to the DAOS package repository
# In JLab network, use the EJFAT nodes to build it. Otherwise you may encounter SSL \
# certification error on personal PCs.
RUN wget -O /etc/yum.repos.d/daos-packages.repo \
	https://packages.daos.io/v2.4/EL8/packages/x86_64/daos_packages.repo && \
	rpm --import https://packages.daos.io/RPM-GPG-KEY

RUN dnf install -y daos-client && \
	dnf clean all && \
	systemctl enable daos_agent

# Install certificates

## Copy the certifications to the LOCAL_CERTS_LOCATION path first.
## For security issues, DO NOT push the certifications to Github!!!
## LOCAL_CERTS_LOCATION is for docker build and is error prone!
ARG LOCAL_CERTS_LOCATION="daosCA/certs"
ARG TEMP_CERTS_LOCATION="/root/daosCA"
COPY ${LOCAL_CERTS_LOCATION} ${TEMP_CERTS_LOCATION}

# This part has to match the testbed node hardware status.

ARG	DAOS_AUTH=yes

## TODO: search for better solutions here.
## To use the Infiniband interface, we must launch the image as "root",
## thus the daos pool has to be created with sudo dmg.
ARG	DAOS_ADMIN_USER=daos_agent
ARG	DAOS_ADMIN_GROUP=daos_daemons
ARG	DAOS_AGENT_IFACE_CFG="yes"

## Use "daos_agent net-scan" to get the corresponding NUMA and IB device interfaces.
## NUMA node "2" for ejfat-6 and "0"/"1" for daosfs nodes.
ARG	DAOS_AGENT_IFACE_NUMA_NODE="2"
ARG	DAOS_AGENT_IFACE_NAME="ibp65s0f1"
ARG	DAOS_AGENT_IFACE_DOMAIN_NAME="ibp65s0f1"

## Configuration for daosfs nodes
# ARG	DAOS_AGENT_IFACE_NUMA_NODE_0="0"
# ARG	DAOS_AGENT_IFACE_NUMA_NODE_1="1"
# # "iface_name" is got from "daos_agent net-scan". 
# # For daosfs nodes, "ib1" is for NUMA_NODE "0" and "ib3" is for "1".
# ARG	DAOS_AGENT_IFACE_NAME_0="ib1"
# ARG	DAOS_AGENT_IFACE_NAME_1="ib3"
# # For daosfs nodes, "mlx5_1" is for NUMA_NODE "0" and "mlx5_3" is for "1"
# ARG	DAOS_AGENT_IFACE_DOMAIN_NAME_0="mlx5_1"
# ARG	DAOS_AGENT_IFACE_DOMAIN_NAME_1="mlx5_3"

## Update this based on your enviroment
ARG DAOS_YML_INPUT_FILE="daos_agent-ejfat-6.yml.in"
COPY ${DAOS_YML_INPUT_FILE} /tmp/daos_agent.yml.in

# Configure the cert files
## mode 664: owner & group RW
RUN	if [ "$DAOS_AUTH" == yes ] ; then \
		sed --in-place --regexp-extended \
			--expression '/^@DAOS_NOAUTH_SECTION_BEGIN@$/,/^@DAOS_NOAUTH_SECTION_END@/d' \
			--expression '/(^@DAOS_AUTH_SECTION_BEGIN@$)|(^@DAOS_AUTH_SECTION_END@$)/d' \
			/tmp/daos_agent.yml.in && \
		chmod 664 ${TEMP_CERTS_LOCATION}/certs/daosCA.crt && \
		chmod 644 ${TEMP_CERTS_LOCATION}/certs/agent.crt && \
		chmod 400 ${TEMP_CERTS_LOCATION}/certs/agent.key && \
		chown "$DAOS_ADMIN_USER:$DAOS_ADMIN_GROUP" ${TEMP_CERTS_LOCATION}/certs/daosCA.crt && \
		chown daos_agent:daos_agent ${TEMP_CERTS_LOCATION}/certs/agent.crt && \
		chown daos_agent:daos_agent ${TEMP_CERTS_LOCATION}/certs/agent.key && \
		mv ${TEMP_CERTS_LOCATION}/certs/daosCA.crt /etc/daos/certs/. && \
		mv ${TEMP_CERTS_LOCATION}/certs/agent.crt /etc/daos/certs/. && \
		mv ${TEMP_CERTS_LOCATION}/certs/agent.key /etc/daos/certs/. && \
		rm -fr ${TEMP_CERTS_LOCATION} ; \
	else \
		sed --in-place --regexp-extended \
			--expression '/^@DAOS_AUTH_SECTION_BEGIN@$/,/^@DAOS_AUTH_SECTION_END@/d' \
			--expression '/(^@DAOS_NOAUTH_SECTION_BEGIN@$)|(^@DAOS_NOAUTH_SECTION_END@$)/d' \
			/tmp/daos_agent.yml.in ; \
	fi

## Set /etc/daos/daos_agent.yml
RUN	if [[ "${DAOS_AGENT_IFACE_CFG}" == yes ]] ; then \
		for it in DAOS_AGENT_IFACE_NUMA_NODE DAOS_AGENT_IFACE_NAME DAOS_AGENT_IFACE_DOMAIN_NAME ; do \
			if eval "[[ -z \"\$$it\" ]]" ; then \
				echo "[ERROR] Docker build argument $it is not defined" ; \
				exit 1 ; \
			fi ; \
		done ; \
		sed --in-place --regexp-extended \
			--expression '/(^@DAOS_IFACE_SECTION_BEGIN@$)|(^@DAOS_IFACE_SECTION_END@$)/d' \
			--expression "s/@DAOS_IFACE_NUMA_NODE@/${DAOS_AGENT_IFACE_NUMA_NODE}/" \
			--expression "s/@DAOS_IFACE_NAME@/${DAOS_AGENT_IFACE_NAME}/" \
			--expression "s/@DAOS_IFACE_DOMAIN_NAME@/${DAOS_AGENT_IFACE_DOMAIN_NAME}/" \
			/tmp/daos_agent.yml.in ; \
	else \
		sed --in-place --regexp-extended \
			--expression '/^@DAOS_IFACE_SECTION_BEGIN@$/,/^@DAOS_IFACE_SECTION_END@/d' \
			/tmp/daos_agent.yml.in ; \
	fi && \
	mv -f /tmp/daos_agent.yml.in /etc/daos/daos_agent.yml

# Setup entrypoint
RUN mkdir -p /var/run/daos_agent && \
	chown "daos_agent:daos_agent" /var/run/daos_agent && \
	chmod 777 /var/run/daos_agent

## Donot use systemctl start daos_agent. See the error below.
## [root@daos-client /]# systemctl start daos_agent
## System has not been booted with systemd as init system (PID 1). Can't operate.
## Failed to connect to bus: Host is down
CMD bash
