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


DOCKER_IMAGE=jenkins/jenkins:lts-alpine
docker pull ${DOCKER_IMAGE}

# https://github.com/jenkinsci/docker/blob/master/README.md
#
# automatically create 'jenkins_home' volume, survives stop/restart/deletion.
#
# NOTE: Avoid bind mount from a host folder to /var/jenkins_home, as this might
# result in file permission issues (the user used inside the container might
# not have rights to the folder on the host machine). If you really need to
# bind mount jenkins_home, ensure that the directory on the host is accessible
# by the jenkins user inside the container (jenkins user - uid 1000) or use -u
# some_other_user parameter with docker run.
#
#  docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
#
# this will run Jenkins in detached mode with port forwarding and volume added.
# You can access logs with command 'docker logs CONTAINER_ID' in order to check
# first login token. ID of container will be returned from output of command
# above.


DOCKER_PARAMS=(
    run
    -p 8080:8080
    -p 50000:50000
    ${DOCKER_IMAGE}
)

docker ${DOCKER_PARAMS[@]}

