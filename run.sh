#!/bin/bash
set -e
error_trap() {
    echo "Error on line $1"
}
trap 'error_trap $LINENO' ERR
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

while true; do
	$SCRIPT_PATH/check.sh
	sleep 60
done