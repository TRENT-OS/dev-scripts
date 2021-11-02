#!/bin/bash -uex

RELEASE_VERSION="1.3"
INPUT_ID=36

#-------------------------------------------------------------------------------
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

INPUT_PACKAGE="sdk-package-v${RELEASE_VERSION}-${INPUT_ID}.tar.bz2"

DOCKER_IAMGES=(
    trentos_build_${RELEASE_VERSION}.bz2 \
    trentos_test_${RELEASE_VERSION}.bz2 \
)

ARCHIVE_SMALL=TRENTOS_SDK_no_docker_${RELEASE_VERSION}
ARCHIVE_BIG=TRENTOS_SDK_${RELEASE_VERSION}

#-------------------------------------------------------------------------------
function do_tar()
{
    local TAR_FILE=$1
    local TAR_FOLDER=$2

    # fix file order and timestamps
    tar -cjf ${TAR_FILE} \
        --sort=name \
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

mkdir ${TIMESTAMP}
cd ${TIMESTAMP}
do_untar ../${INPUT_PACKAGE} pkg/sdk

ln -s "sdk/doc/pdf/TRENTOS_GettingStarted_SDK_V*.pdf" pkg/GettingStarted.pdf
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
