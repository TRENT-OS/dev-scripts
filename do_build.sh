#!/bin/bash -ue

SCRIPT_DIR=$(cd `dirname $0` && pwd)

# if we are not running in a terminal, start one one and start us in there
if [ ! -t 1 ] ; then
    gnome-terminal -e ${0}
    #exit $?
fi

# docker images
# docker image ls
# docker container ls
# docker exec -it --network none -u root [name] bash

#-------------------------------------------------------------------------------
function docker_data61()
{
    # docker pull trustworthysystems/sel4
    # docker pull trustworthysystems/camkes
    # docker pull trustworthysystems/sel4-riscv
    # docker pull trustworthysystems/camkes-riscv

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

    # start the container
    echo "running:   ${TARGET}"
    echo ""
    SEL4_DOCKER_REPO=/home/axel/hensoldt/projekte/seos/_work/sel4-docker
    make -C ${SEL4_DOCKER_REPO} ${TARGET} HOST_DIR=$(pwd)
}


#-------------------------------------------------------------------------------
function docker_manual()
{
    CONTAINER_REPO="docker:5000"
    CONTAINER_NAME="trentos_build"

    #CONTAINER_TAG="trentos_0.9"
    CONTAINER_TAG="20200428"

    CONTAINER="${CONTAINER_REPO}/${CONTAINER_NAME}:${CONTAINER_TAG}"

    # docker pull ${CONTAINER}
    # docker tag ${CONTAINER} ${CONTAINER_NAME}:${CONTAINER_TAG}

    # docker load -i seos_build_env_20200404_192017.gz

    DOCKER_PARAMS=(
        run
        -i  # --interactive     Keep STDIN open even if not attached
        -t  # --tty             Allocate a pseudo-TTY
        #--rm    # Automatically remove the container when it exits
        --hostname "build-container"
        # do not use this: -u $(id -u):$(id -g)
        -u $(id -u)
        #--group-add=1001
        -v $(pwd):/host
        -v /etc/localtime:/etc/localtime:ro
        -w /host
        ${CONTAINER}
        bash    # start bash process in the container
    )
    docker ${DOCKER_PARAMS[@]}
}


#-------------------------------------------------------------------------------
function docker_sdk()
{
    (
        cd seos_tests
        src/seos_sandbox/scripts/open_trentos_build_env.sh $@
    )
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

docker_sdk src/build.sh $@
