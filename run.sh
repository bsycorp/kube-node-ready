#!/bin/bash
set -e
error_trap() {
    echo "Error on line $1"
}
trap 'error_trap $LINENO' ERR
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

if [ -z "$CHECK_INTERVAL" ]; then
	CHECK_INTERVAL=60
fi

while true; do
	$SCRIPT_PATH/check.sh | ts
	sleep $CHECK_INTERVAL
done
