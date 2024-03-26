#!/bin/bash -ue

# Copyright (C) 2020-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net

function export_image()
{
    local IMAGE_ID=${1}
    local IMAGE_ARCHIVE=${2}

    echo "saving ${IMAGE_ID} to ${IMAGE_ARCHIVE} ..."
    docker inspect --format='{{.Config.Image}}' ${IMAGE_ID}

    # docker save ${IMAGE_ID} | pv > ${IMAGE_ARCHIVE}

    # docker save ${IMAGE_ID} | pv | gzip > ${IMAGE_ARCHIVE}.gz

    docker save ${IMAGE_ID} | pv | bzip2 > ${IMAGE_ARCHIVE}.bz2
    #docker save ${IMAGE_ID} | pv | pbzip2 > ${IMAGE_ARCHIVE}.bz2

    # docker save ${IMAGE_ID} | pv | pxz > ${IMAGE_ARCHIVE}.xz
}


#-------------------------------------------------------------------------------
function pull_and_archive_image()
{
    local IMAGE_ID=${1}

    echo "container: ${IMAGE_ID}"

    # docker pull ${IMAGE_ID}
    docker inspect --format='{{.Config.Image}}' ${IMAGE_ID}

    # remove "docker:5000/" prefix
    local STAND_ALONE_IMAGE_ID=${IMAGE_ID#*/}
    echo "stand alone ID: ${STAND_ALONE_IMAGE_ID}"
    docker tag ${IMAGE_ID} ${STAND_ALONE_IMAGE_ID}

    # "trentos_build:trentos_0.9" -> "trentos_build-0.9"
    IMAGE_ARCHIVE=${STAND_ALONE_IMAGE_ID%:*}_${STAND_ALONE_IMAGE_ID##*_}
    export_image ${STAND_ALONE_IMAGE_ID} ${IMAGE_ARCHIVE}
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

pull_and_archive_image docker:5000/trentos_test:trentos_0.9
pull_and_archive_image docker:5000/trentos_build:trentos_0.9

