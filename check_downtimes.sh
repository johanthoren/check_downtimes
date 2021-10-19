#!/usr/bin/env bash

usage() {
	cat <<EOF
Usage: $0 -h | [-v]

	   -d Print debug output
	   -h Print this text
	   -i Invert (don't filter unique, for testing purposes only)
	   -v Verbose output
EOF
	exit "$1"
}

query() {
	mon node ctrl --type=peer --self \
	"mon query ls downtimes -c author,host_name,service_description,entry_time,start_time,end_time,fixed,triggered_by"
}

filter_and_sort() {
	grep '^[a-zA-Z].*[0-1]$' <<< "$@" | sort
}

debug=0
invert=0
verbose=0

while getopts "dhiv" opt
   do
	 case $opt in
		d) debug=1;;
		h) usage 0;;
		i) invert= 1;;
		v) verbose=1;;
		*) usage 1;;
	 esac
done

RESULTS=$(query)

if [ $debug -eq 1 ]; then
	echo "$RESULTS"
fi

if [[ $RESULTS == *"No UNIX socket"* ]]; then
	echo "UNKNOWN: Cannot connect to Livestatus socket"
	exit 3
fi

if [[ $RESULTS == *"ssh exited with return code"* ]]; then
	echo "UNKNOWN: One or more remote nodes didn't exit with status code 0"
	exit 3
fi

if [ $invert -eq 0 ]; then
	DOWNTIMES=$(filter_and_sort "$RESULTS" | uniq -u)
else
	DOWNTIMES=$(filter_and_sort "$RESULTS")
fi

if [ -z "$DOWNTIMES" ]; then
	echo "OK: No unique downtimes found"
	exit 0
else
	echo "CRITICAL: Unique downtimes found"
	if [ $debug -eq 1 ] || [ $verbose -eq 1 ]; then
		echo "$DOWNTIMES"
	fi
	exit 2
fi
