#!/bin/bash

#
# by TS, Apr 2019
#

# @param string $1 Path
# @param int $2 Recursion level
#
# @return string Absolute path
function realpath_osx() {
	local TMP_RP_OSX_RES=
	[[ $1 = /* ]] && TMP_RP_OSX_RES="$1" || TMP_RP_OSX_RES="$PWD/${1#./}"

	if [ -h "$TMP_RP_OSX_RES" ]; then
		TMP_RP_OSX_RES="$(readlink "$TMP_RP_OSX_RES")"
		# possible infinite loop...
		local TMP_RP_OSX_RECLEV=$2
		[ -z "$TMP_RP_OSX_RECLEV" ] && TMP_RP_OSX_RECLEV=0
		TMP_RP_OSX_RECLEV=$(( TMP_RP_OSX_RECLEV + 1 ))
		if [ $TMP_RP_OSX_RECLEV -gt 20 ]; then
			# too much recursion
			TMP_RP_OSX_RES="--error--"
		else
			TMP_RP_OSX_RES="$(realpath_osx "$TMP_RP_OSX_RES" $TMP_RP_OSX_RECLEV)"
		fi
	fi
	echo "$TMP_RP_OSX_RES"
}

# @param string $1 Path
#
# @return string Absolute path
function realpath_poly() {
	command -v realpath >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		realpath "$1"
	else
		realpath_osx "$1"
	fi
}

VAR_MYNAME="$(basename "$0")"
VAR_MYDIR="$(realpath_poly "$0")"
VAR_MYDIR="$(dirname "$VAR_MYDIR")"

# ----------------------------------------------------------

cd "$VAR_MYDIR" || exit 1

. "config-modoboa.sh" || exit 1

. "config-mklive.sh" || exit 1

. "includes/inc-fnc-db.sh" || exit 1

. "includes/inc-fnc-docker.sh" || exit 1

. "includes/inc-fnc-mklive.sh" || exit 1

# ----------------------------------------------------------

function printUsageAndExit() {
	echo "Usage: $VAR_MYNAME" >/dev/stderr
	exit 1
}

# ----------------------------------------------------------

VAR_EXITCODE=0

VAR_TRAPPED_INT=false

VAR_TEMPFILE_PREFIX=""

# ----------------------------------------------------------

function mklive_trapCallback_int() {
	echo "$VAR_MYNAME: Trapped CTRL-C. Deleting temp files..." >/dev/stderr
	[ -n "$VAR_TEMPFILE_PREFIX" ] && rm "$VAR_TEMPFILE_PREFIX"* 2>/dev/null
	VAR_TRAPPED_INT=true
}

# trap ctrl-c (INTERRUPT signal)
trap mklive_trapCallback_int INT

# ----------------------------------------------------------

mklive_checkConfigVars || exit 1

# ----------------------------------------------------------

VAR_TEMPFILE_PREFIX="$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDTEMP/tmp.mklive.$$-"

VAR_DB_FNCS_DC_MDB="$CFG_MKLIVE_MDB_DOCKERCONTAINER"
VAR_DB_FNCS_DC_MARIADB="$CFG_MKLIVE_MARIADB_DOCKERCONTAINER"
VAR_DB_FNCS_MARIADB_ROOT_PASS=""

VAR_MARIADB_DB_DIR_TAR_FN="mariadb-dbs-vanilla.tgz"

VAR_DOCKERCOMPOSE_OUTP_FN="docker-compose.yaml"

VAR_MDB_DOCK_IMG_INSTALL_INPUT="$CFG_MKLIVE_MDB_RELASE_DI_NAME"

VAR_MDB_DOCK_IMG_LIVE_OUTPUT="$CFG_MKLIVE_DOCK_IMG_LIVE"

VAR_DCMDB_SCR_FN="dc-mdb.sh"

# ----------------------------------------------------------

mklive_checkBaseImages || exit 1

# ----------------------------------------------------------

TMP_CHECK_FN="$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT/$VAR_MARIADB_DB_DIR_TAR_FN"
[ -f "$TMP_CHECK_FN" ] && rm "$TMP_CHECK_FN"

TMP_CHECK_FN="$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT/$VAR_DOCKERCOMPOSE_OUTP_FN"
[ -f "$TMP_CHECK_FN" ] && rm "$TMP_CHECK_FN"

TMP_CHECK_FN="$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT/$VAR_DCMDB_SCR_FN"
[ -f "$TMP_CHECK_FN" ] && rm "$TMP_CHECK_FN"

# ----------------------------------------------------------

LVAR_DI_LIVE_OUTPUT="$VAR_MDB_DOCK_IMG_LIVE_OUTPUT:$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
LVAR_DI_LIVE_OUTPUT_EXPORT_FN="$(echo -n "$LVAR_DI_LIVE_OUTPUT" | tr ":" "-").tgz"

TMP_CHECK_FN="$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_IMG/$LVAR_DI_LIVE_OUTPUT_EXPORT_FN"
[ -f "$TMP_CHECK_FN" ] && rm "$TMP_CHECK_FN"

#
dck_getDoesDockerImageExist "$VAR_MDB_DOCK_IMG_LIVE_OUTPUT" "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
if [ $? -eq 0 ]; then
	echo -e "$VAR_MYNAME: Removing Docker Image $VAR_MDB_DOCK_IMG_LIVE_OUTPUT:$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS...\n"
	dck_removeDockerImage "$VAR_MDB_DOCK_IMG_LIVE_OUTPUT" "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
	VAR_EXITCODE=$?
	[ $VAR_EXITCODE -eq 1 ] && VAR_EXITCODE=0
	[ $VAR_EXITCODE -ne 0 ] && {
		echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
		exit 1
	}
	echo
fi

# ----------------------------------------------------------

TMP_CHECK_DIR="$CFG_MKLIVE_PATH_BUILDOUTPUT"
[ -d "$VAR_MYDIR/$TMP_CHECK_DIR" ] || {
	mkdir "$VAR_MYDIR/$TMP_CHECK_DIR" || {
		echo "$VAR_MYNAME: Error: Creating directory '$TMP_CHECK_DIR' failed. Aborting." >/dev/stderr
		exit 1
	}
}

TMP_CHECK_DIR="$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT"
[ -d "$VAR_MYDIR/$TMP_CHECK_DIR" ] || {
	mkdir "$VAR_MYDIR/$TMP_CHECK_DIR" || {
		echo "$VAR_MYNAME: Error: Creating directory '$TMP_CHECK_DIR' failed. Aborting." >/dev/stderr
		exit 1
	}
}

TMP_CHECK_DIR="$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_IMG"
[ -d "$VAR_MYDIR/$TMP_CHECK_DIR" ] || {
	mkdir "$VAR_MYDIR/$TMP_CHECK_DIR" || {
		echo "$VAR_MYNAME: Error: Creating directory '$TMP_CHECK_DIR' failed. Aborting." >/dev/stderr
		exit 1
	}
}

TMP_CHECK_DIR="$CFG_MKLIVE_PATH_BUILDTEMP"
[ -d "$VAR_MYDIR/$TMP_CHECK_DIR" ] || {
	mkdir "$VAR_MYDIR/$TMP_CHECK_DIR" || {
		echo "$VAR_MYNAME: Error: Creating directory '$TMP_CHECK_DIR' failed. Aborting." >/dev/stderr
		exit 1
	}
}

TMP_CHECK_DIR="$CFG_MKLIVE_PATH_BUILDTEMP/$CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST"
[ -d "$VAR_MYDIR/$TMP_CHECK_DIR" ] || {
	mkdir "$VAR_MYDIR/$TMP_CHECK_DIR" || {
		echo "$VAR_MYNAME: Error: Creating directory '$TMP_CHECK_DIR' failed. Aborting." >/dev/stderr
		exit 1
	}
}

# ----------------------------------------------------------

echo "$VAR_MYNAME: Generating DB-Server root-User Password..."
VAR_DB_FNCS_MARIADB_ROOT_PASS="$(mklive_generatePassword 16)"
[ -z "$VAR_DB_FNCS_MARIADB_ROOT_PASS" -o ${#VAR_DB_FNCS_MARIADB_ROOT_PASS} -ne 16 ] && {
	echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	exit 1
}
echo -e "$VAR_MYNAME:    * PW='$VAR_DB_FNCS_MARIADB_ROOT_PASS'\n"

# ----------------------------------------------------------
# Generate Configuration variables

LVAR_MODOBOA_CONF_DBNAME_AND_DBUSER="${CFG_MDB_MARIADB_MODOBOA_DBS_PREFIX}modoboa"
LVAR_AMAVIS_CONF_DBNAME_AND_DBUSER="${CFG_MDB_MARIADB_MODOBOA_DBS_PREFIX}amavis"
LVAR_SPAMASSASS_CONF_DBNAME_AND_DBUSER="${CFG_MDB_MARIADB_MODOBOA_DBS_PREFIX}spamassassin"
LVAR_OPENDKIM_CONF_DBNAME_AND_DBUSER="${CFG_MDB_MARIADB_MODOBOA_DBS_PREFIX}opendkim"

echo "$VAR_MYNAME: Generating other DB-Server User Passwords..."

LVAR_MODOBOA_CONF_DBPASS="$(mklive_generatePassword 16)"
[ -z "$LVAR_MODOBOA_CONF_DBPASS" ] && {
	echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	exit 1
}
echo -e "$VAR_MYNAME:    * PW ModoDb: '$LVAR_MODOBOA_CONF_DBPASS'"
LVAR_AMAVIS_CONF_DBPASS="$(mklive_generatePassword 16)"
[ -z "$LVAR_AMAVIS_CONF_DBPASS" ] && {
	echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	exit 1
}
echo -e "$VAR_MYNAME:    * PW AmavDb: '$LVAR_AMAVIS_CONF_DBPASS'"
LVAR_SPAMASSASS_CONF_DBPASS="$(mklive_generatePassword 16)"
[ -z "$LVAR_SPAMASSASS_CONF_DBPASS" ] && {
	echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	exit 1
}
echo -e "$VAR_MYNAME:    * PW SpamDb: '$LVAR_SPAMASSASS_CONF_DBPASS'"
LVAR_OPENDKIM_CONF_DBPASS="$(mklive_generatePassword 16)"
[ -z "$LVAR_OPENDKIM_CONF_DBPASS" ] && {
	echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	exit 1
}
echo -e "$VAR_MYNAME:    * PW DkimDb: '$LVAR_OPENDKIM_CONF_DBPASS'\n"

echo "$VAR_MYNAME: Generating Modoboa Passwords/Keys..."

LVAR_MODOBOA_CONF_DEFUSERPW="$(mklive_generatePassword 16 "true")"
[ -z "$LVAR_MODOBOA_CONF_DEFUSERPW" ] && {
	echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	exit 1
}
echo -e "$VAR_MYNAME:    * PW Modo Def: '$LVAR_MODOBOA_CONF_DEFUSERPW'"
LVAR_MODOBOA_CONF_SECRETKEY="$(mklive_generatePassword 32)"
[ -z "$LVAR_MODOBOA_CONF_SECRETKEY" ] && {
	echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	exit 1
}
echo -e "$VAR_MYNAME:    * Modo SecKey: '$LVAR_MODOBOA_CONF_SECRETKEY'\n"

# ----------------------------------------------------------

mklive_createDockerNet || exit 1

# ----------------------------------------------------------
# Start Modoboa Docker Container

dck_getDoesDockerContainerIsRunning "$CFG_MKLIVE_MDB_DOCKERCONTAINER"
if [ $? -eq 0 ]; then
	echo "$VAR_MYNAME: Stopping Docker Container '$CFG_MKLIVE_MDB_DOCKERCONTAINER'..."
	docker container stop "$CFG_MKLIVE_MDB_DOCKERCONTAINER"
	sleep 1
	#
	dck_getDoesDockerContainerAlreadyExist "$CFG_MKLIVE_MDB_DOCKERCONTAINER"
	[ $? -eq 0 ] && {
		echo "$VAR_MYNAME: Removing Docker Container '$CFG_MKLIVE_MDB_DOCKERCONTAINER'..."
		docker container rm "$CFG_MKLIVE_MDB_DOCKERCONTAINER"
		sleep 1
		dck_getDoesDockerContainerAlreadyExist "$CFG_MKLIVE_MDB_DOCKERCONTAINER"
		[ $? -eq 0 ] && {
			echo "$VAR_MYNAME: Error: Could not remove Docker Container '$CFG_MKLIVE_MDB_DOCKERCONTAINER'. Aborting." >/dev/stderr
			VAR_EXITCODE=1
		}
	}
fi

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	mklive_runModoboaDockerContainer_withNewEnvVars_daemon "$VAR_MDB_DOCK_IMG_INSTALL_INPUT" "$CFG_MKLIVE_MDB_DOCKERCONTAINER" || {
		VAR_EXITCODE=1
	}
fi

# ----------------------------------------------------------
# Read ENV variables from mdb-install

LVAR_DENV__CF_MODOBOA_VERSION=""

LVAR_DENV__CF_OPENDKIM_CONF_ENABLE=false

LVAR_DENV__CF_CLAMAV_CONF_ENABLE=false

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	echo -e "\n$VAR_MYNAME: Getting Modoboa Version from Docker Image..."
	LVAR_DENV__CF_MODOBOA_VERSION="$(mklive_getEnvVarFromDockerContainer "$CFG_MKLIVE_MDB_DOCKERCONTAINER" "CF_MODOBOA_VERSION")"
	[ -z "$LVAR_DENV__CF_MODOBOA_VERSION" ] && {
		echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
		VAR_EXITCODE=1
	} || {
		echo "$VAR_MYNAME:     * Version=$LVAR_DENV__CF_MODOBOA_VERSION"
	}
fi

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	echo -e "\n$VAR_MYNAME: Getting OpenDKIM-Enabled? from Docker Image..."
	LVAR_DENV__CF_OPENDKIM_CONF_ENABLE="$(mklive_getEnvVarFromDockerContainer "$CFG_MKLIVE_MDB_DOCKERCONTAINER" "CF_OPENDKIM_CONF_ENABLE")"
	[ -z "$LVAR_DENV__CF_OPENDKIM_CONF_ENABLE" ] && {
		echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
		VAR_EXITCODE=1
	} || {
		echo "$VAR_MYNAME:     * Is OpenDKIM enabled=$LVAR_DENV__CF_OPENDKIM_CONF_ENABLE"
	}
fi

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	echo -e "\n$VAR_MYNAME: Getting ClamAV-Enabled? from Docker Image..."
	LVAR_DENV__CF_CLAMAV_CONF_ENABLE="$(mklive_getEnvVarFromDockerContainer "$CFG_MKLIVE_MDB_DOCKERCONTAINER" "CF_CLAMAV_CONF_ENABLE")"
	[ -z "$LVAR_DENV__CF_CLAMAV_CONF_ENABLE" ] && {
		echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
		VAR_EXITCODE=1
	} || {
		echo "$VAR_MYNAME:     * Is ClamAV enabled=$LVAR_DENV__CF_CLAMAV_CONF_ENABLE"
	}
fi

# ----------------------------------------------------------

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	[ -d "$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDTEMP" ] || {
		mkdir "$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDTEMP" || {
			echo "$VAR_MYNAME: Error: Creating directory '$CFG_MKLIVE_PATH_BUILDTEMP' failed. Aborting." >/dev/stderr
			VAR_EXITCODE=1
		}
	}
fi

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	LVAR_DB_MODO_FN="$(mklive_replaceVarInString "$CFG_MKLIVE_MARIADB_MODO_FN_TEMPL" "MODOBOA_VERSION" "$LVAR_DENV__CF_MODOBOA_VERSION")"
	LVAR_DB_AMAV_FN="$(mklive_replaceVarInString "$CFG_MKLIVE_MARIADB_AMAV_FN_TEMPL" "MODOBOA_VERSION" "$LVAR_DENV__CF_MODOBOA_VERSION")"
	LVAR_DB_SPAM_FN="$(mklive_replaceVarInString "$CFG_MKLIVE_MARIADB_SPAM_FN_TEMPL" "MODOBOA_VERSION" "$LVAR_DENV__CF_MODOBOA_VERSION")"

	#echo "$VAR_MYNAME:     * DB_MODO_FN=$LVAR_DB_MODO_FN"
	#echo "$VAR_MYNAME:     * DB_AMAV_FN=$LVAR_DB_AMAV_FN"
	#echo "$VAR_MYNAME:     * DB_SPAM_FN=$LVAR_DB_SPAM_FN"
fi

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	mklive_checkDbConnection || VAR_EXITCODE=1
fi

# ----------------------------------------------------------
# Init DB

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	echo -e "\n$VAR_MYNAME: Creating Database, DB-Users and DB-Privileges...\n"

	# Create Database-Users for Modoboa/Amavis/Spamassassin
	db_createModoDbUser "$LVAR_MODOBOA_CONF_DBNAME_AND_DBUSER" "$LVAR_MODOBOA_CONF_DBPASS" \
			"$LVAR_MODOBOA_CONF_DBNAME_AND_DBUSER" "${CFG_MKLIVE_MARIADB_ACCESS_ALLOWED_SOURCE_NETWORK}"
	db_createModoDbUser "$LVAR_AMAVIS_CONF_DBNAME_AND_DBUSER" "$LVAR_AMAVIS_CONF_DBPASS" \
			"$LVAR_AMAVIS_CONF_DBNAME_AND_DBUSER" "${CFG_MKLIVE_MARIADB_ACCESS_ALLOWED_SOURCE_NETWORK}"
	db_createModoDbUser "$LVAR_SPAMASSASS_CONF_DBNAME_AND_DBUSER" "$LVAR_SPAMASSASS_CONF_DBPASS" \
			"$LVAR_SPAMASSASS_CONF_DBNAME_AND_DBUSER" "${CFG_MKLIVE_MARIADB_ACCESS_ALLOWED_SOURCE_NETWORK}"
	# Grant OpenDKIM-DB-User SELECT on Modo-DB in table 'dkim'
	if [ "$LVAR_DENV__CF_OPENDKIM_CONF_ENABLE" = "true" ]; then
		db_createModoDbUser "$LVAR_OPENDKIM_CONF_DBNAME_AND_DBUSER" "$LVAR_OPENDKIM_CONF_DBPASS" \
				"$LVAR_OPENDKIM_CONF_DBNAME_AND_DBUSER" "${CFG_MKLIVE_MARIADB_ACCESS_ALLOWED_SOURCE_NETWORK}"
		db_grantDbUserSelectIfExists \
				"$LVAR_OPENDKIM_CONF_DBNAME_AND_DBUSER" \
				"${CFG_MKLIVE_MARIADB_ACCESS_ALLOWED_SOURCE_NETWORK}" \
				"$LVAR_MODOBOA_CONF_DBNAME_AND_DBUSER" || return 1
	fi
	#
	db_runFlushPrivs

	# Import DBs
	echo -e "\n$VAR_MYNAME: Importing Modoboa DBs...\n"
	db_createAndImportDb "$LVAR_MODOBOA_CONF_DBNAME_AND_DBUSER" "/root/$LVAR_DB_MODO_FN" || {
		VAR_EXITCODE=1
	}
	if [ $VAR_EXITCODE -eq 0 ]; then
		db_createAndImportDb "$LVAR_AMAVIS_CONF_DBNAME_AND_DBUSER" "/root/$LVAR_DB_AMAV_FN" || {
			VAR_EXITCODE=1
		}
	fi
	if [ $VAR_EXITCODE -eq 0 ]; then
		db_createAndImportDb "$LVAR_SPAMASSASS_CONF_DBNAME_AND_DBUSER" "/root/$LVAR_DB_SPAM_FN" || {
			VAR_EXITCODE=1
		}
	fi
	if [ $VAR_EXITCODE -eq 0 ]; then
		docker exec "$CFG_MKLIVE_MDB_DOCKERCONTAINER" \
				rm \
						"/root/${LVAR_DB_MODO_FN}.gz" \
						"/root/${LVAR_DB_AMAV_FN}.gz" \
						"/root/${LVAR_DB_SPAM_FN}.gz" || {
			VAR_EXITCODE=1
		}
	fi
	if [ $VAR_EXITCODE -ne 0 ]; then
		echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	fi
fi

# ----------------------------------------------------------
# Customize Modoboa 

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	echo -e "\n$VAR_MYNAME: Customizing Modoboa Localconf in DB...\n"

	echo "$VAR_MYNAME: < reading Modo Localconf from DB"
	TMP_JSON="$(db_readModoLocalconf "$LVAR_MODOBOA_CONF_DBNAME_AND_DBUSER")"

	TMP_JSON_MOD="$(echo -n "$TMP_JSON" | docker exec -i "$CFG_MKLIVE_MDB_DOCKERCONTAINER" \
			"/root/$CFG_MKLIVE_CUSTOMIZE_MODO_LCONF_PY_SCRIPT_FN" \
					--mailhost "$CFG_MDB_MAILHOSTNAME" \
					--maildomain "$CFG_MDB_MAILDOMAIN" \
					--default_password "$LVAR_MODOBOA_CONF_DEFUSERPW" \
					--secret_key "$LVAR_MODOBOA_CONF_SECRETKEY" \
					inst -)"
	[ -z "$TMP_JSON_MOD" ] && {
		echo "$VAR_MYNAME: Error: Customizing failed. Aborting." >/dev/stderr
		VAR_EXITCODE=1
	}

	if [ $VAR_EXITCODE -eq 0 ]; then
		echo "$VAR_MYNAME: > writing customized Modo Localconf to DB"
		db_writeModoLocalconf "$LVAR_MODOBOA_CONF_DBNAME_AND_DBUSER" "$TMP_JSON_MOD" || {
			echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
			VAR_EXITCODE=1
		}
	fi
fi

# ----------------------------------------------------------
# Build output Docker Image

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	echo -e "\n$VAR_MYNAME: Creating Docker Image '$VAR_MDB_DOCK_IMG_LIVE_OUTPUT'...\n"
	docker commit "$CFG_MKLIVE_MDB_DOCKERCONTAINER" "$VAR_MDB_DOCK_IMG_LIVE_OUTPUT:$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
	VAR_EXITCODE=$?

	if [ $VAR_EXITCODE -eq 0 ]; then
		echo -e "\n$VAR_MYNAME: Done."
	else
		echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
	fi
fi

# ----------------------------------------------------------
# Export mdb-live image

if [ "$CFG_MKLIVE_DEBUG_DONT_EXPORT_FINAL_IMG" != "true" ]; then
	if [ "$LVAR_DENV__CF_OPENDKIM_CONF_ENABLE" != "true" -o \
			"$LVAR_DENV__CF_CLAMAV_CONF_ENABLE" != "true" ]; then
		echo -en "\n$VAR_MYNAME: Not exporting Docker Image because "
		[ "$LVAR_DENV__CF_OPENDKIM_CONF_ENABLE" != "true" ] && echo -n "LVAR_DENV__CF_OPENDKIM_CONF_ENABLE!=true "
		[ "$LVAR_DENV__CF_CLAMAV_CONF_ENABLE" != "true" ] && echo -n "LVAR_DENV__CF_CLAMAV_CONF_ENABLE!=true "
		echo
	else
		TMP_OUTP_FULL_PATH="$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_IMG/$LVAR_DI_LIVE_OUTPUT_EXPORT_FN"
		if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
			echo -e "\n$VAR_MYNAME: Exporting Docker Image to '$TMP_OUTP_FULL_PATH'..."
			docker save "$LVAR_DI_LIVE_OUTPUT" | gzip -c > "$VAR_MYDIR/$TMP_OUTP_FULL_PATH"
			VAR_EXITCODE=$?
			[ $VAR_EXITCODE -ne 0 ] && echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
		fi

		if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
			# remove image and then import the image from file again to eliminate the dependency on the MDB-INSTALL image
			echo -e "$VAR_MYNAME: Removing Docker Image $VAR_MDB_DOCK_IMG_LIVE_OUTPUT:$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS...\n"
			dck_removeDockerImage "$VAR_MDB_DOCK_IMG_LIVE_OUTPUT" "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"
			VAR_EXITCODE=$?
		fi

		if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
			echo -e "\n$VAR_MYNAME: Importing Docker Image from '$TMP_OUTP_FULL_PATH'..."
			docker load --input "$VAR_MYDIR/$TMP_OUTP_FULL_PATH"
			VAR_EXITCODE=$?
			[ $VAR_EXITCODE -ne 0 ] && echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
		fi
	fi
fi

# ----------------------------------------------------------

echo -e "\n$VAR_MYNAME: Stopping Docker Container..."
docker container stop "$CFG_MKLIVE_MDB_DOCKERCONTAINER"

mklive_stopDbServer

mklive_removeDockerNet

# ----------------------------------------------------------
# Save Databases as tarball

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	TMP_OUTP_FULL_PATH="$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT/$VAR_MARIADB_DB_DIR_TAR_FN"
	echo -e "\n$VAR_MYNAME: Saving Databases to '$TMP_OUTP_FULL_PATH'..."

	cd "$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDTEMP/" || {
		VAR_EXITCODE=1
	}
	if [ $VAR_EXITCODE -eq 0 ]; then
		tar czf "$VAR_MYDIR/$TMP_OUTP_FULL_PATH" "$CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST/$CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST_SUB_MARIADB" || {
			echo "$VAR_MYNAME: Error: Failed. Aborting." >/dev/stderr
			VAR_EXITCODE=1
		}
	fi

	cd "$VAR_MYDIR"
fi

[ -n "$VAR_MYDIR" -a -n "$CFG_MKLIVE_PATH_BUILDTEMP" -a \
		-d "$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDTEMP" ] && rm -r "$VAR_MYDIR/$CFG_MKLIVE_PATH_BUILDTEMP"/* 2>/dev/null

# ----------------------------------------------------------

# @param string $1 Variable name
# @param string $2 Value
#
# @return int EXITCODE
function _mklive_replaceVarInDcTempl() {
	mklive_replaceVarInFile "$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT/$VAR_DOCKERCOMPOSE_OUTP_FN" \
			"$1" "$2"
}

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	TMP_OUTP_FULL_PATH="$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT/$VAR_DOCKERCOMPOSE_OUTP_FN"
	echo -e "\n$VAR_MYNAME: Creating Docker-Compose file '$TMP_OUTP_FULL_PATH'..."
	cp "$CFG_MKLIVE_DOCKERCOMPOSE_TEMPLATE" "$TMP_OUTP_FULL_PATH" || {
		VAR_EXITCODE=1
	}

	# Modoboa
	_mklive_replaceVarInDcTempl "CFG_MDB_DAVHOSTNAME" "$CFG_MDB_DAVHOSTNAME"
	_mklive_replaceVarInDcTempl "CFG_MDB_MAILHOSTNAME" "$CFG_MDB_MAILHOSTNAME"
	_mklive_replaceVarInDcTempl "CFG_MDB_MAILDOMAIN" "$CFG_MDB_MAILDOMAIN"
	_mklive_replaceVarInDcTempl "CFG_MKLIVE_DOCK_IMG_LIVE" "$VAR_MDB_DOCK_IMG_LIVE_OUTPUT"
	_mklive_replaceVarInDcTempl "CFG_MDB_APACHE_SERVER_HTTP_PORT_ON_HOST" "$CFG_MDB_APACHE_SERVER_HTTP_PORT_ON_HOST"
	_mklive_replaceVarInDcTempl "CFG_MDB_APACHE_SERVER_HTTPS_PORT_ON_HOST" "$CFG_MDB_APACHE_SERVER_HTTPS_PORT_ON_HOST"
	_mklive_replaceVarInDcTempl "GENERATED_MODOBOA_CONF_DBNAME_AND_DBUSER" "$LVAR_MODOBOA_CONF_DBNAME_AND_DBUSER"
	_mklive_replaceVarInDcTempl "GENERATED_MODOBOA_CONF_DBPASS" "$LVAR_MODOBOA_CONF_DBPASS"
	_mklive_replaceVarInDcTempl "GENERATED_AMAVIS_CONF_DBNAME_AND_DBUSER" "$LVAR_AMAVIS_CONF_DBNAME_AND_DBUSER"
	_mklive_replaceVarInDcTempl "GENERATED_AMAVIS_CONF_DBPASS" "$LVAR_AMAVIS_CONF_DBPASS"
	_mklive_replaceVarInDcTempl "GENERATED_SPAMASSASS_CONF_DBNAME_AND_DBUSER" "$LVAR_SPAMASSASS_CONF_DBNAME_AND_DBUSER"
	_mklive_replaceVarInDcTempl "GENERATED_SPAMASSASS_CONF_DBPASS" "$LVAR_SPAMASSASS_CONF_DBPASS"
	_mklive_replaceVarInDcTempl "GENERATED_OPENDKIM_CONF_DBNAME_AND_DBUSER" "$LVAR_OPENDKIM_CONF_DBNAME_AND_DBUSER"
	_mklive_replaceVarInDcTempl "GENERATED_OPENDKIM_CONF_DBPASS" "$LVAR_OPENDKIM_CONF_DBPASS"
	_mklive_replaceVarInDcTempl "CFG_MDB_TIMEZONE" "$CFG_MDB_TIMEZONE"
	_mklive_replaceVarInDcTempl "CFG_MDB_LANGUAGE" "$CFG_MDB_LANGUAGE"
	_mklive_replaceVarInDcTempl "CFG_MDB_MODOBOA_CSRF_PROTECTION_ENABLE" "$CFG_MDB_MODOBOA_CSRF_PROTECTION_ENABLE"
	_mklive_replaceVarInDcTempl "HAS_OPENDKIM_SUPPORT" "$LVAR_DENV__CF_OPENDKIM_CONF_ENABLE"

	TMP_CLAMAV_ENABLED=$LVAR_DENV__CF_CLAMAV_CONF_ENABLE
	[ "$TMP_CLAMAV_ENABLED" = "true" ] && TMP_CLAMAV_ENABLED=$CFG_MDB_CLAMAV_CONF_ENABLE
	_mklive_replaceVarInDcTempl "CFG_MDB_CLAMAV_CONF_ENABLE" "$TMP_CLAMAV_ENABLED"

	# Nginx
	_mklive_replaceVarInDcTempl "CFG_MKLIVE_NGINX_DOCKERIMAGE" "$CFG_MKLIVE_NGINX_DOCKERIMAGE"

	# DB-Server
	_mklive_replaceVarInDcTempl "CFG_MKLIVE_MARIADB_DOCKERIMAGE" "$CFG_MKLIVE_MARIADB_DOCKERIMAGE"
	_mklive_replaceVarInDcTempl "CFG_MDB_MARIADB_SERVER_PORT_ON_HOST" "$CFG_MDB_MARIADB_SERVER_PORT_ON_HOST"
	_mklive_replaceVarInDcTempl "CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST" "$CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST"
	_mklive_replaceVarInDcTempl "CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST_SUB_MARIADB" "$CFG_MKLIVE_PATH_MNTPOINTS_DB_HOST_SUB_MARIADB"
	_mklive_replaceVarInDcTempl "GENERATED_MARIADB_ROOT_PASS" "$VAR_DB_FNCS_MARIADB_ROOT_PASS"

	# Docker Image Versions
	_mklive_replaceVarInDcTempl "CFG_MKLIVE_DOCK_IMG_INSTALL_VERS" "$CFG_MKLIVE_DOCK_IMG_INSTALL_VERS"

	# Docker Network
	_mklive_replaceVarInDcTempl "CFG_MDB_DOCK_NET_INCL_BITMASK" "$CFG_MDB_DOCK_NET_INCL_BITMASK"
fi

# ----------------------------------------------------------

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	TMP_OUTP_FULL_PATH="$CFG_MKLIVE_PATH_BUILDOUTPUT/$CFG_MKLIVE_PATH_BUILDOUTPUT_SUB_CONT/$VAR_DCMDB_SCR_FN"
	echo -e "\n$VAR_MYNAME: Copying Docker-Compose script to '$TMP_OUTP_FULL_PATH'..."
	cp "includes/$VAR_DCMDB_SCR_FN" "$VAR_MYDIR/$TMP_OUTP_FULL_PATH" || {
		VAR_EXITCODE=1
	}
	chmod 755 "$VAR_MYDIR/$TMP_OUTP_FULL_PATH"
fi

# ----------------------------------------------------------

if [ $VAR_EXITCODE -eq 0 -a "$VAR_TRAPPED_INT" != "true" ]; then
	echo -e "$VAR_MYNAME: Done."
fi

exit $VAR_EXITCODE
