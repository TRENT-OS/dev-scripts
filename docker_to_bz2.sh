#!/bin/bash -ue

function pull_and_archive_image()
{
    local IMAGE_ID=${1}

    docker pull ${IMAGE_ID}

    echo "Container Details:"
    docker inspect --format='{{.Config.Image}}' ${IMAGE_ID}

    local IMAGE_SHORT_ID=${IMAGE_ID#*/}
    # "trentos_build:trentos_0.9" -> "trentos_build-0.9"
    IMAGE_ARCHIVE=${IMAGE_SHORT_ID%:*}_${IMAGE_SHORT_ID##*_}

    echo "saving image to ${IMAGE_ARCHIVE} ..."

    # docker save ${IMAGE_ID} | pv | gzip > ${IMAGE_ARCHIVE}.gz
    docker save ${IMAGE_ID} | pv | bzip2 > ${IMAGE_ARCHIVE}.bz2
    # docker save ${IMAGE_ID} | pv | pxz > ${IMAGE_ARCHIVE}.xz

    sha256sum ${IMAGE_ARCHIVE}.bz2

}

pull_and_archive_image docker:5000/trentos_test:trentos_1.0
pull_and_archive_image docker:5000/trentos_build:trentos_1.0
