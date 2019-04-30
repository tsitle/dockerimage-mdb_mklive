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

printUsageAndExit() {
	echo "Usage: $VAR_MYNAME <COMMAND> ..." >/dev/stderr
	echo "Examples: $VAR_MYNAME up" >/dev/stderr
	echo "          $VAR_MYNAME start" >/dev/stderr
	echo "          $VAR_MYNAME start modo" >/dev/stderr
	echo "          $VAR_MYNAME stop" >/dev/stderr
	echo "          $VAR_MYNAME stop modo" >/dev/stderr
	echo "          $VAR_MYNAME restart modo" >/dev/stderr
	echo "          $VAR_MYNAME ps" >/dev/stderr
	echo "          $VAR_MYNAME rm" >/dev/stderr
	echo "          $VAR_MYNAME down" >/dev/stderr
	echo "          $VAR_MYNAME logs -f" >/dev/stderr
	echo "          $VAR_MYNAME logs -f modo" >/dev/stderr
	echo "          $VAR_MYNAME exec modo bash" >/dev/stderr
	echo "            or simply" >/dev/stderr
	echo "          $VAR_MYNAME bash modo" >/dev/stderr
	exit 1
}

cd "$VAR_MYDIR" || exit 1

if [ $# -lt 1 ]; then
	printUsageAndExit
fi

OPT_CMD="$1"
shift

# ----------------------------------------------------------

VAR_DCY_INP="docker-compose.yaml"

VAR_PROJNAME="mdb"

VAR_MARIADB_TAR_FN="mariadb-dbs-vanilla.tgz"

[ -f "$VAR_DCY_INP" ] || {
	echo "$VAR_MYNAME: Error: File '$VAR_DCY_INP' not found. Aborting." >/dev/stderr
	exit 1
}

if [ -f "$VAR_MARIADB_TAR_FN" ]; then
	echo "$VAR_MYNAME: Extracting '$VAR_MARIADB_TAR_FN'..."
	tar xf "$VAR_MARIADB_TAR_FN" || exit 1
	rm "$VAR_MARIADB_TAR_FN"
fi

# ----------------------------------------------------------

TMP_ADDITIONAL_OPT=
if [ "$OPT_CMD" = "up" ]; then
	# prevent Docker Compose from running in foreground
	TMP_ADDITIONAL_OPT="--no-start"
fi

if [ "$OPT_CMD" = "bash" ]; then
	OPT_SERVICE="$1"
	shift
	docker-compose -p "$VAR_PROJNAME" -f "$VAR_DCY_INP" exec "$OPT_SERVICE" "$OPT_CMD" $@ || exit 1
else
	docker-compose -p "$VAR_PROJNAME" -f "$VAR_DCY_INP" "$OPT_CMD" $TMP_ADDITIONAL_OPT $@ || exit 1
fi

if [ "$OPT_CMD" = "up" ]; then
	sleep 2
	# now start services in background
	docker-compose -p "$VAR_PROJNAME" -f "$VAR_DCY_INP" start
fi
