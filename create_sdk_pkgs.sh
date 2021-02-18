#!/bin/bash -uex

RELEASE_VERSION="1.2"
RELEASE_DATE="UTC 2021-02-18 18:00:00"

INPUT_ID=26

#-------------------------------------------------------------------------------
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

INPUT_PACKAGE="sdk-package-v${RELEASE_VERSION}-${INPUT_ID}.tar.bz2"

DOCKER_IAMGES=(
    trentos_build_${RELEASE_VERSION}.bz2 \
    trentos_test_${RELEASE_VERSION}.bz2 \
)

ARCHIVE_SMALL=TRENTOS-M_SDK_no_docker_${RELEASE_VERSION}
ARCHIVE_BIG=TRENTOS-M_SDK_${RELEASE_VERSION}


#-------------------------------------------------------------------------------
function export_image()
{
    local IMAGE_ID=${1}
    local IMAGE_ARCHIVE=${2}

    echo "saving ${IMAGE_ID} to ${IMAGE_ARCHIVE} ..."
    docker inspect --format='{{.Config.Image}}' ${IMAGE_ID}
    docker save ${IMAGE_ID} | pv | bzip2 > ${IMAGE_ARCHIVE}.bz2
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
function do_tar()
{
    local TAR_FILE=$1
    local TAR_FOLDER=$2

    # fix file order and timestamps
    tar -cjf ${TAR_FILE} \
        --sort=name \
        --mtime="${RELEASE_DATE}" \
        -C ${TAR_FOLDER} \
        .
}

#-------------------------------------------------------------------------------
function do_untar()
{
    local TAR_FILE=$1
    local TAR_FOLDER=$2

    mkdir -p ${TAR_FOLDER}
    tar -xf ${TAR_FILE} -C ${TAR_FOLDER}
}

#-------------------------------------------------------------------------------
function do_repackage()
{
    local ARCHIVE_NAME=${1}

    do_tar ${ARCHIVE_NAME}.tar.bz2 pkg
    do_untar ${ARCHIVE_NAME}.tar.bz2 ${ARCHIVE_NAME}
    diff -r pkg ${ARCHIVE_NAME}
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

#pull_and_archive_image docker:5000/trentos_test:trentos_${RELEASE_VERSION}
#pull_and_archive_image docker:5000/trentos_build:trentos_${RELEASE_VERSION}

#export_image trentos_test:trentos_${RELEASE_VERSION} trentos_test_${RELEASE_VERSION}
#export_image trentos_build:trentos_${RELEASE_VERSION} trentos_build_${RELEASE_VERSION}


mkdir ${TIMESTAMP}
cd ${TIMESTAMP}
do_untar ../${INPUT_PACKAGE} pkg/sdk

ln -s sdk/doc/pdf/TRENTOS-M_GettingStarted_SDK_V${RELEASE_VERSION}.pdf pkg/GettingStarted.pdf
ls -l pkg/sdk

do_repackage ${ARCHIVE_SMALL}

mkdir -p pkg/docker
(
    cd pkg/docker
    cp ${DOCKER_IAMGES[@]/#/../../../} .
    sha256sum ${DOCKER_IAMGES[@]} >trentos_${RELEASE_VERSION}.sha256sums
)

do_repackage ${ARCHIVE_BIG}

sha256sum \
    ${ARCHIVE_SMALL}.tar.bz2 \
    ${ARCHIVE_BIG}.tar.bz2 \
    > trentos_SDK_v${RELEASE_VERSION}.sha256sums
