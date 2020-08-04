#!/bin/bash -uex

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

INPUT_PACKAGE=sdk-package-34.bz2

RELEASE_DATE="UTC 2020-08-03 18:00:00"
RELEASE_VERSION="1.0"

ARCHIVE_SMALL=TRENTOS-M_SDK_no_docker_${RELEASE_VERSION}
ARCHIVE_BIG=TRENTOS-M_SDK_${RELEASE_VERSION}

WORKSPACE_CREATE=${TIMESTAMP}/pkg
WORKSPACE_VERIFY=${TIMESTAMP}/pkg_vfy

#-------------------------------------------------------------------------------
function do_tar()
{
    TAR_FILE=$1
    TAR_FOLDER=$2

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
    TAR_FILE=$1
    TAR_FOLDER=$2

    mkdir -p ${TAR_FOLDER}
    tar -xf ${TAR_FILE} -C ${TAR_FOLDER}
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
do_untar ${INPUT_PACKAGE} ${WORKSPACE_CREATE}/sdk

ln -s sdk/doc/pdf/TRENTOS-M_GettingStarted_SDK_V1.0.pdf ${WORKSPACE_CREATE}/GettingStarted.pdf
ls -l ${WORKSPACE_CREATE}

do_tar ${TIMESTAMP}/${ARCHIVE_SMALL}.bz2 ${WORKSPACE_CREATE}

do_untar ${TIMESTAMP}/${ARCHIVE_SMALL}.bz2 ${WORKSPACE_VERIFY}

diff -r ${WORKSPACE_CREATE} ${WORKSPACE_VERIFY}


rm -rf ${WORKSPACE_VERIFY}


mkdir ${WORKSPACE_CREATE}/docker

sha256sum \
    trentos_build_1.0.bz2 \
    trentos_test_1.0.bz2 \
    >${WORKSPACE_CREATE}/docker/trentos_1.0.sha256sums

cp \
    trentos_build_1.0.bz2 \
    trentos_test_1.0.bz2 \
    ${WORKSPACE_CREATE}/docker/


do_tar ${TIMESTAMP}/${ARCHIVE_BIG}.bz2 ${WORKSPACE_CREATE}

do_untar ${TIMESTAMP}/${ARCHIVE_BIG}.bz2 ${WORKSPACE_VERIFY}

diff -r ${WORKSPACE_CREATE} ${WORKSPACE_VERIFY}

(
    cd ${TIMESTAMP}
    sha256sum ${ARCHIVE_SMALL}.bz2 ${ARCHIVE_BIG}.bz2 > trentos_SDK_v1.0.sha256sums
)
