#!/bin/bash -uex

# if we are not running in a terminal, start one one and start us in there
if [ ! -t 1 ] ; then
    gnome-terminal -e ${0}
    exit $?
fi

#-------------------------------------------------------------------------------

SEL4_DOCKER_REPO=~/hensoldt/projekte/seos/_work/sel4-docker
#SEL4_DOCKER_REPO=~/data/Hensoldt/workspace/docker_env/src

#-------------------------------------------------------------------------------
#
# docker images
# docker image ls
# docker container ls
# docker exec -it --network none -u root [name] bash
#
# docker pull trustworthysystems/sel4
# docker pull trustworthysystems/camkes-riscv
# docker pull trustworthysystems/camkes
#
#-------------------------------------------------------------------------------

if [ ! -z "${1:-}" ]; then
  TARGET=${1}
  shift
else
    #TARGET=sel4                # build + run
    #TARGET=sel4-riscv          # build + run

    #TARGET=user_sel4           # run
    #TARGET=user_sel4-riscv     # run

    #TARGET=camkes              # build + run
    #TARGET=camkes-riscv        # build + run

    #TARGET=user_camkes         # run
    TARGET=user_camkes-riscv   # run


    # disable cache and rebuild everything

    #TARGET=rebuild_all
    #TARGET=rebuild_sel4
    #TARGET=rebuild_sel4-riscv
    #TARGET=rebuild_camkes-riscv
fi

#-------------------------------------------------------------------------------
# start the container
echo "running:   ${TARGET}"
echo ""
make -C ${SEL4_DOCKER_REPO} ${TARGET} HOST_DIR=$(pwd)
