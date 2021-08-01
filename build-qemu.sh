#!/bin/bash -uex

BUILD_SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

function download_and_build_tag()
{
    local QEMU_VERSION=$1
    local QEMU_TARGET_LIST=$2

    QEMU_BASE_DIR=qemu-${QEMU_VERSION}

    QEMU_TAG=v${QEMU_VERSION}
    QEMU_ARCHIVE=qemu-${QEMU_VERSION}.tar.xz

    QEMU_CONFIG=(
        --target-list=${QEMU_TARGET_LIST}
        # don't require shared librarie libgtk-3.so.0
        --disable-gtk
        # don't require shared librarie libpulse.so.0
        --audio-drv-list=""
    )

    # (
    #     cd ${QEMU_SRC}
    #     git checkout v${QEMU_TAG}
    #     git submodule update --init --recursive --jobs 16
    # )

    if [ ! -d ${QEMU_TAG} ]; then
        mkdir ${QEMU_BASE_DIR}
    fi

    (
        cd ${QEMU_BASE_DIR}

        if [ ! -f ${QEMU_ARCHIVE} ]; then
            wget https://download.qemu.org/${QEMU_ARCHIVE}
        fi

        if [ ! -d src ]; then
            mkdir src
            tar -xvf ${QEMU_ARCHIVE} -C src
        fi
        QEMU_SRC=$(cd src/qemu-${QEMU_VERSION}; pwd)

        if [ ! -d build ]; then
            mkdir build
        fi

        (
            cd build
            ${QEMU_SRC}/configure ${QEMU_CONFIG[@]}
            make -j 8
        )
    )
}

#download_and_build_tag 5.2.0 riscv32-softmmu,riscv64-softmmu
download_and_build_tag 6.0.0 riscv32-softmmu,riscv64-softmmu
