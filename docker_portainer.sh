#!/bin/bash -ex

# Copyright (C) 2020-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net

if [ ! -t 1 ] ; then
    gnome-terminal --window -- bash ${0}
    exit 0
fi

DOCKER_IMAGE=portainer/portainer

# docker volume create portainer_data

docker pull ${DOCKER_IMAGE}

DOCKER_PARAMS=(
    run
    -d  # --detach: run container in background and print container ID
        # containers started in detached mode exit when the root process used
        # to run the container exits. If -d with --rm is used, the container
        # is removed when it exits or when the daemon exits, whichever happens
        # first.
    -p 8000:8000
    -p 9000:9000
    -v /var/run/docker.sock:/var/run/docker.sock
    -v portainer_data:/data
    ${DOCKER_IMAGE}
)

docker ${DOCKER_PARAMS[@]}
