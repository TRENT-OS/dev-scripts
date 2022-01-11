#!/bin/bash -ue

SCRIPT_DIR=$(cd `dirname $0` && pwd)

# if we are not running in a terminal, start one one and start us in there
if [ ! -t 1 ] ; then
    gnome-terminal -e ${0}
    #exit $?
fi

SEOS_TESTS=(
    #test_demo_fs_as_libs.py
    test_demo_hello_world.py
    #test_partition_manager.py # test_network_api.py #test_keystore.py
    #test_keystore.py
    #test_chanmux.py
    #test_cryptoserver.py
    #test_keystore_preprovisioned.py
    #test_demo_iot_app.py
    #test_logserver.py
    #test_cryptoserver.py
    #test_network_api.py
)

#-------------------------------------------------------------------------------
function docker_manual()
{
    CONTAINER_REPO="docker:5000"
    CONTAINER_NAME="trentos_test"

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
function sdk_docker_test()
{
    (
        cd seos_tests
        src/seos_sandbox/scripts/open_trentos_test_env.sh "$@"
    )
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

if [[ ${1:-} == "prepare" ]]; then
    shift
    sdk_docker_test src/build.sh test-prepare
    if [ "$#" -eq 0 ]; then
        exit
    fi
fi

if [ "$#" -ne 0 ]; then
    SEOS_TESTS="$@"
fi

sdk_docker_test src/build.sh test-run ${SEOS_TESTS} --capture=no #  -k [1024]
