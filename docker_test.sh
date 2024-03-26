#!/bin/bash -uex

# Copyright (C) 2020-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net

# if we are not running in a terminal, start one one and start us in there
if [ ! -t 1 ] ; then
    gnome-terminal --window -- bash ${0}
    exit $?
fi

# unzip seos_test_env_20191010.tar.gz
# docker load -i seos_test_env_20191010.tar


#DOCKER_CONTAINER=seos_test_env:20191117_174040
DOCKER_CONTAINER=seos_test_env_20191010


DOCKER_PARAMS=(
    run
    -i  # --interactive     Keep STDIN open even if not attached
    -t  # --tty             Allocate a pseudo-TTY
    --hostname in-container
    --rm    # Automatically remove the container when it exits
    -u $(id -u):$(id -g)
    -v /etc/localtime:/etc/localtime:ro
    -v $(pwd):/host
    -w /host
    # for netwrok tests
    --device=/dev/net/tun
    --cap-add=NET_ADMIN
    --network=host
    ${DOCKER_CONTAINER}
    bash    # start bash process in the container
)

docker ${DOCKER_PARAMS[@]}
