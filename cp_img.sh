#!/bin/bash -uex

# Copyright (C) 2020-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net

# get the directory the script is located in
SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

SEOS_TEST=${SCRIPT_DIR}/../seos_tests

SD_MUX_CTRL=${SEOS_TEST}/src/ta/common/board_automation/bin/sd-mux-ctrl
SD_MUX_SN=202005170006

SD_MOUNT=/media/axehei01/00F0-D515

#TEST_SYSTEM=build-rpi3-Debug-test_filesystem
TEST_SYSTEM=build-nitrogen6sx-Debug-test_network_api

# IMAGE=seos_tests/${TEST_SYSTEM}/images/os_image.bin
IMAGE=${SEOS_TEST}/${TEST_SYSTEM}/images/os_image.bin

#REMOTE_HOST=192.168.82.31
#REMOTE_USER=root
#REMOTE_DIR=/root/axehei01
#scp ${IMAGE} ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}
#ssh -t ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR}; ./ctrl-raspi.sh update"


${SD_MUX_CTRL} -e ${SD_MUX_SN} -s
sleep 2
cp ${IMAGE} ${SD_MOUNT}/
ls -l ${SD_MOUNT}
sync
umount ${SD_MOUNT}
${SD_MUX_CTRL} -e ${SD_MUX_SN} -d
