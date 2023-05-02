#!/bin/bash -uex

# Script to download and build QEMU.
# See https://www.qemu.org/download/#source for more details


#-------------------------------------------------------------------------------
function build_qemu()
{
    QEMU_SRC=$1
    QEMU_BUILD=$2
    QEMU_BIN_ARCHIVE=$3

    QEMU_TARGETS=(
        #i386
        #x86_64
        arm
        aarch64
        #riscv32
        #riscv64
        #microblazeel
    )

    QEMU_VERSION=$(cat ${QEMU_SRC}/VERSION)

    QEMU_CFG=(
        --static # aim for a stand-alone binary with few library dependencies
        --target-list=$(IFS=,; echo "${QEMU_TARGETS[*]/%/-softmmu}")
        --enable-capstone
        --audio-drv-list="" # don't require libpulse
        --disable-brlapi
        --disable-gio
        --disable-gtk
        --disable-kvm
        --disable-libiscsi
        --disable-libnfs
        --disable-pa
        --disable-rbd
        --disable-sdl
        --disable-snappy
        --disable-vnc
        --disable-xen
        --with-pkgversion="qemu-${QEMU_VERSION}-hc"
        --prefix="/opt/hc"
    )

    if [ ! -e ${QEMU_BUILD} ]; then
        mkdir ${QEMU_BUILD}
    fi
    (
        cd ${QEMU_BUILD}
        ../${QEMU_SRC}/configure ${QEMU_CFG[@]}
        make -j
    )

    TAR_PARAMS=(
        -cvjf ${QEMU_BIN_ARCHIVE}
        --sort=name     # ensure files are sorted
        --numeric-owner # don't expose local user/group strings
        --owner=0       # no owner (current user will be used when extracting)
        --group=0       # no group (current user's primary group will be used when extracting)
        # QEMU binaries
        ${QEMU_TARGETS[@]/#/${QEMU_BUILD}/qemu-system-}
        # QEMU tools
        ${QEMU_BUILD}/qemu-bridge-helper
        ${QEMU_BUILD}/qemu-edid
        ${QEMU_BUILD}/qemu-img
        ${QEMU_BUILD}/qemu-io
        ${QEMU_BUILD}/qemu-nbd
        ${QEMU_BUILD}/qemu-pr-helper
    )
    tar "${TAR_PARAMS[@]}"
}


#-------------------------------------------------------------------------------
function get_and_build_qemu()
{
    VER=$1
    QEMU_ARCHIVE=qemu-${VER}.tar.xz
    QEMU_SRC=qemu-${VER}
    QEMU_BUILD=build-qemu-${VER}
    QEMU_BIN_ARCHIVE=qemu-bin-${VER}.tar.bz2

    if [ ! -d ${QEMU_SRC} ]; then
        if [ ! -e ${QEMU_ARCHIVE} ]; then
            wget https://download.qemu.org/${QEMU_ARCHIVE}
        fi
        tar -xf ${QEMU_ARCHIVE}
    fi

    build_qemu ${QEMU_SRC} ${QEMU_BUILD} ${QEMU_BIN_ARCHIVE}
}

#-------------------------------------------------------------------------------
#function get_and_build_xilinx-qemu()
#{
#    # releases are available from
#    # https://github.com/Xilinx/qemu/archive/refs/tagsxilinx_v${VER}.tar.gz
#
#    # prepare environment
#    PACKAGES=(
#        autoconf
#        automake
#        bison
#        flex
#        libtool
#        libpixman-1-dev
#        libglib2.0-dev
#        libgcrypt20-dev
#        zlib1g-dev
#    )
#    sudo apt install ${PACKAGES[@]}
#    #
#    git clone ssh://git@github.com/Xilinx/qemu.git .
#    TAG=xilinx_v2022.1
#    git checkout tags/${TAG}
#    git submodule update --init --recursive --jobs 16
#    build_qemu ${TAG}
#}

#-------------------------------------------------------------------------------

if [ "$#" -eq 3 ]; then
    build_qemu "$@"
else
    #get_and_build_qemu 2.2.0
    #get_and_build_qemu 2.2.1
    #get_and_build_qemu 2.3.0
    #get_and_build_qemu 2.3.1
    #get_and_build_qemu 2.4.0
    #get_and_build_qemu 2.4.0.1
    #get_and_build_qemu 2.4.1
    #get_and_build_qemu 2.5.0
    #get_and_build_qemu 2.5.1
    #get_and_build_qemu 2.5.1.1
    #get_and_build_qemu 2.6.0
    #get_and_build_qemu 2.6.1
    #get_and_build_qemu 2.6.2
    #get_and_build_qemu 2.7.0
    #get_and_build_qemu 2.7.1
    #get_and_build_qemu 2.8.0
    #get_and_build_qemu 2.8.1
    #get_and_build_qemu 2.8.1.1
    #get_and_build_qemu 2.9.0
    #get_and_build_qemu 2.9.1
    #get_and_build_qemu 2.10.0
    #get_and_build_qemu 2.10.1
    #get_and_build_qemu 2.10.2
    #get_and_build_qemu 2.11.0
    #get_and_build_qemu 2.11.1
    #get_and_build_qemu 2.11.2
    #get_and_build_qemu 2.12.0
    #get_and_build_qemu 2.12.1
    #get_and_build_qemu 3.0.0
    #get_and_build_qemu 3.0.1
    #get_and_build_qemu 3.1.0
    #get_and_build_qemu 3.1.1
    #get_and_build_qemu 3.1.1.1
    #get_and_build_qemu 4.0.0
    #get_and_build_qemu 4.0.1
    #get_and_build_qemu 4.1.0
    #get_and_build_qemu 4.1.1
    #get_and_build_qemu 4.2.0
    #get_and_build_qemu 4.2.1
    #get_and_build_qemu 5.0.0
    #get_and_build_qemu 5.0.1
    #get_and_build_qemu 5.1.0
    #get_and_build_qemu 5.2.0
    #get_and_build_qemu 6.0.0
    #get_and_build_qemu 6.0.1
    #get_and_build_qemu 6.1.0
    #get_and_build_qemu 6.1.1
    #get_and_build_qemu 6.2.0
    #get_and_build_qemu 7.0.0
    #get_and_build_qemu 7.1.0
    #get_and_build_qemu 7.2.0
    get_and_build_qemu 8.0.0
fi
