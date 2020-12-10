#!/bin/bash -ue

function pull_and_archive_image()
{
    local IMAGE_ID=${1}

    docker pull ${IMAGE_ID}

    echo "Container Details:"

    echo "Container ID"
    docker inspect --format='{{.Id}}' ${IMAGE_ID}

    echo "Repository tag"
    docker inspect --format='{{.RepoDigests}}' ${IMAGE_ID}

    local IMAGE_SHORT_ID=${IMAGE_ID#*/}
    # "trentos_build:trentos_0.9" -> "trentos_build-0.9"
    IMAGE_ARCHIVE=${IMAGE_SHORT_ID%:*}_${IMAGE_SHORT_ID##*_}

    # create new tag without registry name
    docker tag ${IMAGE_ID} ${IMAGE_SHORT_ID}

    # remove the tag containing the registry name
    docker rmi ${IMAGE_ID}

    echo "saving image to ${IMAGE_ARCHIVE} ..."

    # docker save ${IMAGE_SHORT_ID} | pv | gzip > ${IMAGE_ARCHIVE}.gz
    docker save ${IMAGE_SHORT_ID} | pv | bzip2 > ${IMAGE_ARCHIVE}.bz2
    # docker save ${IMAGE_SHORT_ID} | pv | pbzip2 > ${IMAGE_ARCHIVE}.bz2
    # docker save ${IMAGE_SHORT_ID} | pv | pxz > ${IMAGE_ARCHIVE}.xz

    sha256sum ${IMAGE_ARCHIVE}.bz2

}

pull_and_archive_image docker:5000/trentos_test:trentos_1.1
pull_and_archive_image docker:5000/trentos_build:trentos_1.1
