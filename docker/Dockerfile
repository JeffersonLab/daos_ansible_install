# Dockerfile revised based on the DAOS v2.4 release at
# https://github.com/daos-stack/daos/blob/release/2.4/utils/docker/vcluster/daos-client/el8/Dockerfile

# Command to build it
# podman/docker build -t 

#
# 'recipe' for building a RHEL variant docker image of a DAOS client node
#
# This Dockerfile accept the following input build arguments:
# - BASE_IMAGE                      Base docker image to use (default "rockylinux")
# - ROCKY_VERSION                   Rocky Version of the base docker image to use (default "8.8")
# - DAOS_AUTH                      Enable DAOS authentication when set to "yes" (default "yes")
# - DAOS_ADMIN_USER                Name or uid of the daos administrattor user (default "root")
# - DAOS_ADMIN_GROUP               Name or gid of the daos administrattor group (default "root")
# - DAOS_AGENT_IFACE_CFG           Enable manual configuration of the interface to use by the agent
#                                  (default "yes")
# - DAOS_AGENT_IFACE_NUMA_NODE     Numa node of the interface to use by the agent (default "0")
# - DAOS_AGENT_IFACE_NAME          Name of the interface to use by the agent (default "eth0")
# - DAOS_AGENT_IFACE_DOMAIN_NAME   Domain name of the interface to use by the agent (default "eth0")


# Pull base image
# ARG BASE_IMAGE=docker.io/library/rockylinux
ARG BASE_IMAGE=rockylinux/rockylinux
ARG	ROCKY_VERSION=8.8
FROM $BASE_IMAGE:$ROCKY_VERSION as base
LABEL maintainer="xmei@jlab.org"
LABEL description="The docker file to set up EJFAT tesbed nodes for DAOS client."

# Install the Infiniband kernels and drivers on host OS.
# sudo apt install infiniband-diags ibutils ibverbs-utils rdmacm-utils libibverbs-dev

# Install Infiniband utilities in docker image.
RUN dnf update -y && dnf install -y infiniband-diags perftest rdma-core libibverbs

# Install necessary tools for debugging and testing.
RUN yum update && yum install -y wget iputils iproute net-tools 

# Configure access to the DAOS package repository
# SSL certification error in JLab network
# COPY daos-packages.repo /etc/yum.repos.d/daos-packages.repo
RUN wget -O /etc/yum.repos.d/daos-packages.repo \
	https://packages.daos.io/v2.4/EL8/packages/x86_64/daos_packages.repo && \
	rpm --import https://packages.daos.io/RPM-GPG-KEY && \
	yum install -y epel-release

# Install DAOS client package
RUN dnf install -y daos-client && \
        dnf clean all && \
	systemctl enable daos_agent

# # Install certificates
# # This part has to match the testbed node hardware status
# ARG	DAOS_AUTH=yes
# ARG	DAOS_ADMIN_USER=root
# ARG	DAOS_ADMIN_GROUP=root
# ARG	DAOS_AGENT_IFACE_CFG="yes"
# ARG	DAOS_AGENT_IFACE_NUMA_NODE="0"
# ARG	DAOS_AGENT_IFACE_NAME="eth0"
# ARG	DAOS_AGENT_IFACE_DOMAIN_NAME="eth0"
# COPY	daos_agent.yml.in /tmp/daos_agent.yml.in
# RUN	if [ "$DAOS_AUTH" == yes ] ; then                                                          \
# 		sed --in-place --regexp-extended                                                   \
# 			--expression '/^@DAOS_NOAUTH_SECTION_BEGIN@$/,/^@DAOS_NOAUTH_SECTION_END@/d' \
# 			--expression '/(^@DAOS_AUTH_SECTION_BEGIN@$)|(^@DAOS_AUTH_SECTION_END@$)/d' \
# 			/tmp/daos_agent.yml.in &&                                                  \
# 		chmod 644 /root/daosCA/certs/daosCA.crt &&                                         \
# 		chmod 644 /root/daosCA/certs/agent.crt &&                                          \
# 		chmod 600 /root/daosCA/certs/agent.key &&                                          \
# 		chown "$DAOS_ADMIN_USER:$DAOS_ADMIN_GROUP" /root/daosCA/certs/daosCA.crt &&        \
# 		chown daos_agent:daos_agent /root/daosCA/certs/agent.crt &&                        \
# 		chown daos_agent:daos_agent /root/daosCA/certs/agent.key &&                        \
# 		mv /root/daosCA/certs/daosCA.crt /etc/daos/certs/. &&                              \
# 		mv /root/daosCA/certs/agent.crt /etc/daos/certs/. &&                               \
# 		mv /root/daosCA/certs/agent.key /etc/daos/certs/. &&                               \
# 		rm -fr /root/daosCA ;                                                              \
# 	else                                                                                       \
# 		sed --in-place --regexp-extended                                                   \
# 			--expression '/^@DAOS_AUTH_SECTION_BEGIN@$/,/^@DAOS_AUTH_SECTION_END@/d'   \
# 			--expression '/(^@DAOS_NOAUTH_SECTION_BEGIN@$)|(^@DAOS_NOAUTH_SECTION_END@$)/d' \
# 			/tmp/daos_agent.yml.in ;                                                   \
# 	fi &&                                                                                      \
# 	if [[ "${DAOS_AGENT_IFACE_CFG}" == yes ]] ; then                                           \
# 		for it in DAOS_AGENT_IFACE_NUMA_NODE DAOS_AGENT_IFACE_NAME DAOS_AGENT_IFACE_DOMAIN_NAME ; do \
# 			if eval "[[ -z \"\$$it\" ]]" ; then                                        \
# 				echo "[ERROR] Docker build argument $it is not defined" ;          \
# 				exit 1 ;                                                           \
# 			fi ;                                                                       \
# 		done ;                                                                             \
# 		sed --in-place --regexp-extended                                                   \
# 			--expression '/(^@DAOS_IFACE_SECTION_BEGIN@$)|(^@DAOS_IFACE_SECTION_END@$)/d' \
# 			--expression "s/@DAOS_IFACE_NUMA_NODE@/${DAOS_AGENT_IFACE_NUMA_NODE}/"     \
# 			--expression "s/@DAOS_IFACE_NAME@/${DAOS_AGENT_IFACE_NAME}/"               \
# 			--expression "s/@DAOS_IFACE_DOMAIN_NAME@/${DAOS_AGENT_IFACE_DOMAIN_NAME}/" \
# 			/tmp/daos_agent.yml.in ;                                                   \
# 	else                                                                                       \
# 		sed --in-place --regexp-extended                                                   \
# 			--expression '/^@DAOS_IFACE_SECTION_BEGIN@$/,/^@DAOS_IFACE_SECTION_END@/d' \
# 			/tmp/daos_agent.yml.in ;                                                   \
# 	fi &&                                                                                      \
# 	mv -f /tmp/daos_agent.yml.in /etc/daos/daos_agent.yml
