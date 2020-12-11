#!/bin/bash -uex

RELEASE_VERSION="1.1"
RELEASE_DATE="UTC 2020-12-11 18:00:00"

INPUT_ID=18

#-------------------------------------------------------------------------------
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

INPUT_PACKAGE="sdk-package-v${RELEASE_VERSION}-${INPUT_ID}.bz2"

ARCHIVE_SMALL=TRENTOS-M_SDK_no_docker_${RELEASE_VERSION}
ARCHIVE_BIG=TRENTOS-M_SDK_${RELEASE_VERSION}

WORKSPACE_CREATE=${TIMESTAMP}/pkg
WORKSPACE_VERIFY=${TIMESTAMP}/pkg_vfy

DOCKER_IAMGES=(
    trentos_build_${RELEASE_VERSION}.bz2 \
    trentos_test_${RELEASE_VERSION}.bz2 \
)

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

ln -s sdk/doc/pdf/TRENTOS-M_GettingStarted_SDK_V${RELEASE_VERSION}.pdf ${WORKSPACE_CREATE}/GettingStarted.pdf
ls -l ${WORKSPACE_CREATE}

do_tar ${TIMESTAMP}/${ARCHIVE_SMALL}.bz2 ${WORKSPACE_CREATE}
do_untar ${TIMESTAMP}/${ARCHIVE_SMALL}.bz2 ${WORKSPACE_VERIFY}
diff -r ${WORKSPACE_CREATE} ${WORKSPACE_VERIFY}

rm -rf ${WORKSPACE_VERIFY}

OUT_BASE_DOCKER=${WORKSPACE_CREATE}/docker
mkdir -p ${OUT_BASE_DOCKER}
sha256sum ${DOCKER_IAMGES[@]} >${OUT_BASE_DOCKER}/trentos_${RELEASE_VERSION}.sha256sums
cp ${DOCKER_IAMGES[@]} ${OUT_BASE_DOCKER}

do_tar ${TIMESTAMP}/${ARCHIVE_BIG}.bz2 ${WORKSPACE_CREATE}
do_untar ${TIMESTAMP}/${ARCHIVE_BIG}.bz2 ${WORKSPACE_VERIFY}
diff -r ${WORKSPACE_CREATE} ${WORKSPACE_VERIFY}

(
    cd ${TIMESTAMP}
    sha256sum ${ARCHIVE_SMALL}.bz2 ${ARCHIVE_BIG}.bz2 > trentos_SDK_v${RELEASE_VERSION}.sha256sums
)
