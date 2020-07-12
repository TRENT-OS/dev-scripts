#!/bin/bash -uex

# get the directory the script is located in
#SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

TEST_SYSTEM=build-rpi3-Debug-test_filesystem
IMAGE=seos_tests/${TEST_SYSTEM}/images/os_image.bin

REMOTE_HOST=192.168.82.31
REMOTE_USER=root
REMOTE_DIR=/root/axehei01

scp ${IMAGE} ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}

ssh -t ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR}; ./ctrl-raspi.sh update"

