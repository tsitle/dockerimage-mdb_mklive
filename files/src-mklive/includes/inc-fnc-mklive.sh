#!/bin/bash

#
# by TS, Apr 2019
#

# ----------------------------------------------------------

# Outputs string
#
# @param string $1 Input string
# @param string $2 Variable name
# @param string $3 Value
#
# @return void
function mklive_replaceVarInString() {
	echo -n "$1" | sed -e "s/<$2>/$3/g"
}

# @param string $1 Input filename
# @param string $2 Variable name
# @param string $3 Value
#
# @return int EXITCODE
function mklive_replaceVarInFile() {
	local TMP_SED_VAL="$(echo -n "$3" | sed -e 's/\//\\\//g')"
	case "$OSTYPE" in
		linux*)
			sed -e "s/<$2>/$TMP_SED_VAL/g" -i "$1" || return 1
			;;
		darwin*)
			sed -e "s/<$2>/$TMP_SED_VAL/g" -i '' "$1" || return 1
			;;
		*)
			echo "$VAR_MYNAME: Error: Unknown OSTYPE '$OSTYPE'" >/dev/stderr
			return 1
			;;
	esac
	return 0
}

# @param string $1 Variable name
#
# @return int EXITCODE
function mklive_checkConfigVars_isBool() {
	([ -z "${!1}" ] || \
			! ( [ "${!1}" = "true" ] || [ "${!1}" = "false" ])) && {
		echo "$VAR_MYNAME: Error: ${1} empty or not true|false. Aborting." >/dev/stderr
		return 1
	}
	return 0
}

# @param string $1 Variable name
#
# @return int EXITCODE
function mklive_checkConfigVars_isEmpty() {
	[ -z "${!1}" ] && {
		echo "$VAR_MYNAME: Error: ${1} empty. Aborting." >/dev/stderr
		return 0
	}
	return 1
}

# @return int EXITCODE
function mklive_checkConfigVars() {
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_MDB_RELASE_DI_NAME" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_DOCK_IMG_INSTALL_VERS" && return 1
	if [ "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS" != "latest" ]; then
		mklive_checkConfigVars_isEmpty "CFG_MKLIVE_DOCK_IMG_INSTALL_VERS" && return 1
		echo -n "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS" | grep -q -E "^[0-9]*[\.][0-9]*$" || {
			echo "$VAR_MYNAME: Error: Invalid value of CFG_MKLIVE_DOCK_IMG_INSTALL_VERS. Aborting." >/dev/stderr
			return 1
		}
	fi
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_DOCK_IMG_LIVE" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_NGINX_DOCKERIMAGE" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_MARIADB_DOCKERIMAGE" && return 1

	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_MDB_DOCKERCONTAINER" && return 1

	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_PATH_BUILDTEMP" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_PATH_BUILDOUTPUT" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_IMG" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST_SUB_MARIADB" && return 1

	mklive_checkConfigVars_isBool "CFG_MKLIVE_DEBUG_DONT_EXPORT_FINAL_IMG" || return 1

	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_MARIADB_DOCKERCONTAINER" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_MARIADB_MODO_FN_TEMPL" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_MARIADB_AMAV_FN_TEMPL" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_MARIADB_SPAM_FN_TEMPL" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_MARIADB_ACCESS_ALLOWED_SOURCE_NETWORK" && return 1

	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_DOCK_NET_NAME" && return 1
	echo -n "$CFG_MKLIVE_DOCK_NET_PREFIX" | grep -q -E "^([0-9]{1,3}[\.]){2}[0-9]{1,3}$" || {
		echo "$VAR_MYNAME: Error: Invalid value of CFG_MKLIVE_DOCK_NET_PREFIX. Aborting." >/dev/stderr
		return 1
	}

	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_CUSTOMIZE_MODO_LCONF_PY_SCRIPT_FN" && return 1

	mklive_checkConfigVars_isEmpty "CFG_MKLIVE_DOCKERCOMPOSE_TEMPLATE" && return 1

	# --------------

	mklive_checkConfigVars_isEmpty "CFG_MDB_APACHE_SERVER_HTTP_PORT_ON_HOST" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MDB_APACHE_SERVER_HTTPS_PORT_ON_HOST" && return 1

	mklive_checkConfigVars_isEmpty "CFG_MDB_MARIADB_SERVER_PORT_ON_HOST" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MDB_MARIADB_MODOBOA_DBS_PREFIX" && return 1

	mklive_checkConfigVars_isEmpty "CFG_MDB_TIMEZONE" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MDB_LANGUAGE" && return 1

	mklive_checkConfigVars_isEmpty "CFG_MDB_DAVHOSTNAME" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MDB_MAILHOSTNAME" && return 1
	mklive_checkConfigVars_isEmpty "CFG_MDB_MAILDOMAIN" && return 1

	#[ $(( ${#CFG_MDB_MAILHOSTNAME} + ${#CFG_MDB_MAILDOMAIN} )) -gt 64 ] && {
	#	# OpenSSL allows max. 64 chars for CN in keys/certs
	#	echo "$VAR_MYNAME: Error: Mail-FQDN may not be longer than 64 chars. Aborting." > /dev/stderr
	#	return 1
	#}
	[ $(( ${#CFG_MDB_MAILHOSTNAME} + ${#CFG_MDB_MAILDOMAIN} )) -gt 50 ] && {
		# DB-Table modoboa.django_site allows max. 50 chars for field 'name'
		echo "$VAR_MYNAME: Error: Mail-FQDN may not be longer than 50 chars. Aborting." > /dev/stderr
		return 1
	}

	[ $(( ${#CFG_MDB_DAVHOSTNAME} + ${#CFG_MDB_MAILDOMAIN} )) -gt 50 ] && {
		echo "$VAR_MYNAME: Error: DAV-FQDN may not be longer than 50 chars. Aborting." > /dev/stderr
		return 1
	}

	[ "$CFG_MDB_MAILHOSTNAME" = "$CFG_MDB_DAVHOSTNAME" ] && {
		echo "$VAR_MYNAME: Error: DAV-Hostname must differ from Mail-Hostname. Aborting." > /dev/stderr
		return 1
	}

	echo -n "$CFG_MDB_DOCK_NET_INCL_BITMASK" | grep -q -E "^([0-9]{1,3}[\.]){3}[0-9]{1,3}/[0-9]{1,2}$" || {
		echo "$VAR_MYNAME: Error: Invalid value of CFG_MDB_DOCK_NET_INCL_BITMASK. Aborting." >/dev/stderr
		return 1
	}

	mklive_checkConfigVars_isBool "CFG_MDB_MODOBOA_CSRF_PROTECTION_ENABLE" || return 1
	mklive_checkConfigVars_isBool "CFG_MDB_CLAMAV_CONF_ENABLE" || return 1

	return 0
}

# @return int EXITCODE
function mklive_checkBaseImages() {
	dck_getDoesDockerImageExist "$VAR_MDB_DOCK_IMG_INSTALL_INPUT" "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Docker Image ${VAR_MDB_DOCK_IMG_INSTALL_INPUT}:${CFG_MKLIVE_DOCK_IMG_INSTALL_VERS} does not exist. Aborting." >/dev/stderr
		return 1
	fi

	dck_getDoesDockerImageExist "$CFG_MKLIVE_MARIADB_DOCKERIMAGE" "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Docker Image ${CFG_MKLIVE_MARIADB_DOCKERIMAGE}:${CFG_MKLIVE_DOCK_IMG_INSTALL_VERS} does not exist. Aborting." >/dev/stderr
		return 1
	fi

	dck_getDoesDockerImageExist "$CFG_MKLIVE_NGINX_DOCKERIMAGE" "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Docker Image ${CFG_MKLIVE_NGINX_DOCKERIMAGE}:${CFG_MKLIVE_DOCK_IMG_INSTALL_VERS} does not exist. Aborting." >/dev/stderr
		return 1
	fi
	return 0
}

# Outputs a generated random password
#
# @param int $1 MAX_LENGTH
#
# @return int EXITCODE
function mklive__generatePassword_sub() {
	local TMP_MAXLEN="$1"
	[ -z "$TMP_MAXLEN" ] && TMP_MAXLEN=64

	# now we can execute commands without stdout/stderr being polluted
	#echo "$VAR_MYNAME: exec..." >/dev/stderr
	docker exec -t "$CFG_MKLIVE_MDB_DOCKERCONTAINER" \
			/root/pwgen.sh "$TMP_MAXLEN"
}

# Outputs a generated random password
#
# @param int $1 MAX_LENGTH
# @param bool $2 optional: FULLFILL_EXTRA_REQUIREMENTS
#
# @return int EXITCODE
function mklive_generatePassword() {
	local TMP_MAXLEN="$1"
	[ -z "$TMP_MAXLEN" ] && TMP_MAXLEN=64
	local TMP_FULLFILL_EXTRA_REQUIREMENTS="$2"
	[ -z "$TMP_FULLFILL_EXTRA_REQUIREMENTS" -o \
			"$TMP_FULLFILL_EXTRA_REQUIREMENTS" != "true" ] && TMP_FULLFILL_EXTRA_REQUIREMENTS=false

	local TMP_STARTCONT=true
	dck_getDoesDockerContainerIsRunning "$CFG_MKLIVE_MDB_DOCKERCONTAINER"
	[ $? -eq 0 ] && TMP_STARTCONT=false

	if [ "$TMP_STARTCONT" = "true" ]; then
		# we need to start the container as daemon since it will print some logs upon start
		local TMP_RUNDI="$VAR_MDB_DOCK_IMG_INSTALL_INPUT:$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
		#echo "$VAR_MYNAME: start Docker Container '$CFG_MKLIVE_MDB_DOCKERCONTAINER'..." >/dev/stderr
		docker run \
				--name "$CFG_MKLIVE_MDB_DOCKERCONTAINER" \
				--rm \
				-d \
				-it \
				"$TMP_RUNDI" \
				/bin/bash >/dev/null
		if [ $? -ne 0 ]; then
			echo "$VAR_MYNAME: Error: Could not start Docker Container '$CFG_MKLIVE_MDB_DOCKERCONTAINER'. Aborting." >/dev/stderr
			return 1
		fi
	fi

	#
	local TMP_RES=0
	if [ "$TMP_FULLFILL_EXTRA_REQUIREMENTS" = "false" ]; then
		mklive__generatePassword_sub "$TMP_MAXLEN"
		TMP_RES=$?
	else
		local TMP_PW_TEST="$(mklive__generatePassword_sub "$TMP_MAXLEN")"
		local TMP_RUNS=1
		while [ $TMP_RUNS -lt 100 ]; do
			echo -n "$TMP_PW_TEST" | grep -q "[a-z]"
			local TMP_HAS_LOW=$?
			echo -n "$TMP_PW_TEST" | grep -q "[A-Z]"
			local TMP_HAS_UPP=$?
			echo -n "$TMP_PW_TEST" | grep -q "[0-9]"
			local TMP_HAS_NUM=$?
			test $TMP_HAS_LOW -ne 0 -o $TMP_HAS_UPP -ne 0 -o $TMP_HAS_NUM -ne 0 && {
				echo "$VAR_MYNAME:   (pw not good enough: '$TMP_PW_TEST')" >/dev/stderr
				echo "$VAR_MYNAME:   (need to generate another password)" >/dev/stderr
				TMP_PW_TEST="$(mklive__generatePassword_sub "$TMP_MAXLEN")"
			} || break
			TMP_RUNS=$(( TMP_RUNS + 1 ))
		done
		[ $TMP_RUNS -eq 100 ] && {
			#echo "$VAR_MYNAME:   (runs:$TMP_RUNS fail)" >/dev/stderr
			TMP_PW_TEST=""
			TMP_RES=1
		} || {
			#echo "$VAR_MYNAME:   (runs:$TMP_RUNS ok)" >/dev/stderr
			echo -n "$TMP_PW_TEST"
		}
	fi

	#
	if [ "$TMP_STARTCONT" = "true" ]; then
		#echo "$VAR_MYNAME: stop..." >/dev/stderr
		docker container stop "$CFG_MKLIVE_MDB_DOCKERCONTAINER" >/dev/null 2>&1
	fi
	return $TMP_RES
}

# @return int EXITCODE
function mklive_createDockerNet() {
	[ -z "$CFG_MKLIVE_DOCK_NET_NAME" ] && {
		echo "$VAR_MYNAME: Error: mklive_createDockerNet(): Empty CFG_MKLIVE_DOCK_NET_NAME. Aborting." >/dev/stderr
		return 1
	}
	[ -z "$CFG_MKLIVE_DOCK_NET_PREFIX" ] && {
		echo "$VAR_MYNAME: Error: mklive_createDockerNet(): Empty CFG_MKLIVE_DOCK_NET_PREFIX. Aborting." >/dev/stderr
		return 1
	}
	echo -n "$CFG_MKLIVE_DOCK_NET_PREFIX" | grep -q -E "^([0-9]{1,3}[\.]){2}[0-9]{1,3}$" || {
		echo "$VAR_MYNAME: Error: mklive_createDockerNet(): Invalid value of CFG_MKLIVE_DOCK_NET_PREFIX. Aborting." >/dev/stderr
		return 1
	}

	docker network ls | grep -q " $CFG_MKLIVE_DOCK_NET_NAME " || {
		echo "$VAR_MYNAME: Creating Docker Network $CFG_MKLIVE_DOCK_NET_NAME..."
		docker network create -d bridge --subnet ${CFG_MKLIVE_DOCK_NET_PREFIX}.0/24 \
				--gateway ${CFG_MKLIVE_DOCK_NET_PREFIX}.1 $CFG_MKLIVE_DOCK_NET_NAME || {
			echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
			return 1
		}
	}
	return 0
}

# @return int EXITCODE
function mklive_removeDockerNet() {
	[ -z "$CFG_MKLIVE_DOCK_NET_NAME" ] && {
		echo "$VAR_MYNAME: Error: mklive_removeDockerNet(): Empty CFG_MKLIVE_DOCK_NET_NAME. Aborting." >/dev/stderr
		return 1
	}

	docker network ls | grep -q " $CFG_MKLIVE_DOCK_NET_NAME " && {
		echo "$VAR_MYNAME: Removing Docker Network $CFG_MKLIVE_DOCK_NET_NAME..."
		docker network rm $CFG_MKLIVE_DOCK_NET_NAME || {
			echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
			return 1
		}
	}
	return 0
}

# @param string $1 Docker Image Name
# @param string $2 Docker Container Name
#
# @return int EXITCODE
function mklive_runModoboaDockerContainer_withNewEnvVars_daemon() {
	local TMP_DI_DAEMON="$1:$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
	local TMP_DC_DAEMON="$2"

	echo -e "\n$VAR_MYNAME: Starting Docker Container for Image '$TMP_DI_DAEMON' in background..."
	docker run \
			--rm \
			-d \
			-i \
			-e CF_AUTO_UPDATE_CONFIG=false \
			-e CF_MARIADB_DOCKERHOST="$CFG_MKLIVE_MARIADB_DOCKERCONTAINER" \
			-e CF_DAVHOSTNAME="$CFG_MDB_DAVHOSTNAME" \
			-e CF_MAILHOSTNAME="$CFG_MDB_MAILHOSTNAME" \
			-e CF_MAILDOMAIN="$CFG_MDB_MAILDOMAIN" \
			-e CF_TIMEZONE="$CFG_MDB_TIMEZONE" \
			-e CF_LANGUAGE="$CFG_MDB_LANGUAGE" \
			-e CF_MODOBOA_CONF_DBNAME_AND_DBUSER="$LCFG_MODOBOA_CONF_DBNAME_AND_DBUSER" \
			-e CF_MODOBOA_CONF_DBPASS="$LCFG_MODOBOA_CONF_DBPASS" \
			-e CF_AMAVIS_CONF_DBNAME_AND_DBUSER="$LCFG_AMAVIS_CONF_DBNAME_AND_DBUSER" \
			-e CF_AMAVIS_CONF_DBPASS="$LCFG_AMAVIS_CONF_DBPASS" \
			-e CF_SPAMASSASS_CONF_DBNAME_AND_DBUSER="$LCFG_SPAMASSASS_CONF_DBNAME_AND_DBUSER" \
			-e CF_SPAMASSASS_CONF_DBPASS="$LCFG_SPAMASSASS_CONF_DBPASS" \
			-e CF_MODOBOA_INSTALLER_DBUSER="" \
			-e CF_MODOBOA_INSTALLER_DBPASS="" \
			--network="$CFG_MKLIVE_DOCK_NET_NAME" \
			--name "$TMP_DC_DAEMON" \
			"$TMP_DI_DAEMON" \
			/bin/bash
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Could not start Docker Container '$TMP_DC_DAEMON' in background. Aborting." >/dev/stderr
		return 1
	fi
	echo "$VAR_MYNAME: Docker Container '$TMP_DC_DAEMON' running"
	return 0
}

# @return int EXITCODE
function mklive_checkDbConnection() {
	dck_getDoesDockerContainerAlreadyExist "$VAR_DB_FNCS_DC_MDB"
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Docker Container '$VAR_DB_FNCS_DC_MDB' not running. Aborting." >/dev/stderr
		return 1
	fi

	#
	local TMP_MP_BASE="${CF_MKLIVE_MOUNTPOINTS_BASE_ON_HOST:-$VAR_MYDIR}"
	#echo -e "\n$VAR_MYNAME: Starting DB-Server (rootPw='$VAR_DB_FNCS_MARIADB_ROOT_PASS',cont='$CFG_MKLIVE_MARIADB_DOCKERCONTAINER',mpBase='$TMP_MP_BASE')..."
	echo -e "\n$VAR_MYNAME: Starting DB-Server (mpBase='$TMP_MP_BASE')..."

	local TMP_DI_MARIADB="$CFG_MKLIVE_MARIADB_DOCKERIMAGE:$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"

	local TMP_MP="$TMP_MP_BASE/$CFG_MKLIVE_PATH_BUILDTEMP/$CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST/$CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST_SUB_MARIADB"
	[ -d "$TMP_MP" ] || mkdir -p "$TMP_MP"

	docker run \
			--rm \
			-d \
			--network="$CFG_MKLIVE_DOCK_NET_NAME" \
			--name "$CFG_MKLIVE_MARIADB_DOCKERCONTAINER" \
			-v "$TMP_MP":/var/lib/mysql:delegated \
			-e MYSQL_ROOT_PASSWORD="$VAR_DB_FNCS_MARIADB_ROOT_PASS" \
			"$TMP_DI_MARIADB"
	# to access the DB-Server from the host add this line to the arguments above:
	#		-p ${CFG_MDB_MARIADB_SERVER_PORT_ON_HOST}:3306 \
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Starting DB-Server failed. Aborting." >/dev/stderr
		return 1
	fi
	echo -e "$VAR_MYNAME: DB-Server started. Waiting 5s..."
	sleep 5

	local TMP_WAIT_CNT=0
	while [ $TMP_WAIT_CNT -lt 100 ]; do
		[ "$VAR_TRAPPED_INT" = "true" ] && {
			TMP_WAIT_CNT=100
			break
		}

		dck_getDoesDockerContainerIsRunning "$VAR_DB_FNCS_DC_MARIADB"
		if [ $? -ne 0 ]; then
			echo "$VAR_MYNAME: Error: DB-Server stopped running. Aborting." >/dev/stderr
			return 1
		fi

		db_checkDbConnection && break
		TMP_WAIT_CNT=$(( TMP_WAIT_CNT + 1 ))
		echo "$VAR_MYNAME: DB-Server not ready yet. Waiting 5s..."
		sleep 5
	done
	if [ $TMP_WAIT_CNT -eq 100 ]; then
		echo "$VAR_MYNAME: Error: Could not connect to DB-Server. Aborting." >/dev/stderr
		return 1
	fi
	echo -e "\n$VAR_MYNAME: Connection to DB-Server OK\n"
	return 0
}

# @return int EXITCODE
function mklive_stopDbServer() {
	echo "$VAR_MYNAME: Stopping DB-Server..."
	docker container stop "$CFG_MKLIVE_MARIADB_DOCKERCONTAINER"
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
		return 1
	fi
	return 0
}

# Outputs the value of the ENV variable
#
# @param string $1 Docker Container Name
# @param string $2 Name of variable
#
# @return int EXITCODE
function mklive_getEnvVarFromDockerContainer() {
	docker exec \
		"$1" \
		/bin/bash -c "(echo -n "\$$2")"
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Could not read ENV var '$2' from Docker Container '$1'. Aborting." >/dev/stderr
		return 1
	fi
	return 0
}
