#!/bin/bash

# ----------------------------------------------------------

# Docker Image Name for input
CFG_MKLIVE_MDB_RELASE_DI_NAME="mdb-install"

# Release Version of Docker Image mdb-install
CFG_MKLIVE_DOCK_IMG_INSTALL_VERS="${CF_MKLIVE_DOCK_IMG_INSTALL_VERS:-latest}"

# Docker Image Name for output
CFG_MKLIVE_DOCK_IMG_LIVE="mdb-live"

# Docker Image Name of Nginx Reverse Proxy
CFG_MKLIVE_NGINX_DOCKERIMAGE="mdb-nginx"

# Docker Image Name of MariaDB Server
CFG_MKLIVE_MARIADB_DOCKERIMAGE="mdb-mariadb"

# ----------------------------------------------------------

CFG_MKLIVE_MDB_DOCKERCONTAINER="mdb-mklive-install-$(echo -n "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS" | tr -d ".")-btcnt"

# ----------------------------------------------------------

CFG_MKLIVE_PATH_BUILDTEMP="build-temp"

CFG_MKLIVE_PATH_BUILDOUTPUT="build-output"
CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT="dockercontainer"
CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_IMG="dockerimage"

CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST="mountpoints-dbhost"
CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST_SUB_MARIADB="mariadb"

# ----------------------------------------------------------

# may be "true" or "false":
CFG_MKLIVE_DEBUG_DONT_EXPORT_FINAL_IMG=${CF_MKLIVE_DEBUG_DONT_EXPORT_FINAL_IMG:-false}

# ----------------------------------------------------------

CFG_MKLIVE_MARIADB_DOCKERCONTAINER="mdb-mklive-mariadb-$(echo -n "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS" | tr -d ".")-cnt"

CFG_MKLIVE_MARIADB_MODO_FN_TEMPL="modo-<MODOBOA_VERSION>-db_modoboa.sql"
CFG_MKLIVE_MARIADB_AMAV_FN_TEMPL="modo-<MODOBOA_VERSION>-db_amavis.sql"
CFG_MKLIVE_MARIADB_SPAM_FN_TEMPL="modo-<MODOBOA_VERSION>-db_spamassassin.sql"

# since the DB Server cannot be accessed from outside the Docker Network
# by default we don't need to restrict the source network here
CFG_MKLIVE_MARIADB_ACCESS_ALLOWED_SOURCE_NETWORK="%"

# ----------------------------------------------------------
# Docker Network for build process

# For the building process only:
CFG_MKLIVE_DOCK_NET_NAME="mklivemdb"

# For the building process only:
# the first 3 numbers of the network address (e.g. 100.50.25)
# IP range for private networks: 172.16.0.0 - 172.31.255.255
CFG_MKLIVE_DOCK_NET_PREFIX="${CF_MKLIVE_DOCK_NET_PREFIX:-172.29.21}"

# ----------------------------------------------------------

CFG_MKLIVE_CUSTOMIZE_MODO_LCONF_PY_SCRIPT_FN="customize_modo_lconf.py"

# ----------------------------------------------------------

CFG_MKLIVE_DOCKERCOMPOSE_TEMPLATE="docker-compose-template.yaml"
