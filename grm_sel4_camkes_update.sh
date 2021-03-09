#!/bin/bash -ue

#-------------------------------------------------------------------------------
#
# GIT Repo Manager
#
#-------------------------------------------------------------------------------

# get the directory the script is located in
SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

REPOS=(
    capdl,seL4/capdl
    kernel,seL4/seL4
    libs/musllibc,seL4/musllibc sel4
    libs/projects_libs,seL4/projects_libs
    libs/sel4_global_components,seL4/global-components
    libs/sel4_libs,seL4/seL4_libs
    libs/sel4_projects_libs,seL4/seL4_projects_libs
    libs/sel4_util_libs,seL4/util_libs
    libs/sel4runtime,seL4/sel4runtime
    tools/camkes,seL4/camkes-tool
    tools/nanopb,nanopb/nanopb trentos
    tools/seL4,seL4/seL4_tools
    tools/riscv-pk,seL4/riscv-pk
)

#-------------------------------------------------------------------------------
function checkout_from_remote()
{
    local SUBDIR=$1
    local REMOTE=$2
    local SPEC=$3

    local TYPE=${SPEC%:*}
    local NAME=${SPEC#*:}
    local CHECKOUT_PARAMS=()

    if [ "${NAME}" = "${SPEC}" ] || [ "${TYPE}" = "b" ]; then
        # branch
        CHECKOUT_PARAMS=(
            --no-track
            -B ${NAME}
            refs/remotes/${REMOTE}/${NAME}
        )

    elif [ "${TYPE}" = "c" ]; then
        # commit ID
        CHECKOUT_PARAMS=(
            --detach
            ${NAME}
        )

    elif [ "${TYPE}" = "t" ]; then
        # explicit tag
        CHECKOUT_PARAMS=(
            --detach
            refs/tags/${NAME}
        )

    else
        echo "SPEC error: ${SPEC}"
        exit 1
    fi

    (
        cd ${SUBDIR}
        git remote -v
        git fetch --all
        set -x
        git checkout ${CHECKOUT_PARAMS[@]}
    )
}


#-------------------------------------------------------------------------------
function checkout_from_github()
{
    local SUBDIR=$1
    local SPEC=$2

    echo ""
    echo "-----------------------------------------------------------------"
    echo "${SUBDIR} -> github ${SPEC}"
    echo "-----------------------------------------------------------------"

    for e in "${REPOS[@]}"; do
        local REPO_SUBDIR=${e%,*}
        local GITHUB_REPO=${e#*,}
        if [ "${REPO_SUBDIR}" != "${SUBDIR}" ]; then
            continue
        fi

        (
            cd ${SUBDIR}
            set -x
            git remote add github https://github.com/${GITHUB_REPO}.git || true
        )

        checkout_from_remote ${SUBDIR} github ${SPEC}

        local TYPE=${SPEC%:*}
        local NAME=${SPEC#*:}
        if [ "${NAME}" = "${SPEC}" ] || [ "${TYPE}" = "b" ]; then
            (
                cd ${SUBDIR}
                set -x
                git push origin ${NAME}
            )
        fi
    done
}


#-------------------------------------------------------------------------------
function sel4_camkes_update_RELEASE_old()
{
    checkout_from_github capdl "t:0.1.0"
    checkout_from_github kernel "t:11.0.0"

    checkout_from_github libs/musllibc "11.0.x-compatible"
    checkout_from_github libs/projects_libs "11.0.x-compatible"
    checkout_from_github libs/sel4_global_components "camkes-3.8.x-compatible"
    checkout_from_github libs/sel4_libs "11.0.x-compatible"
    checkout_from_github libs/sel4_projects_libs "11.0.x-compatible"
    checkout_from_github libs/sel4_util_libs "11.0.x-compatible"
    checkout_from_github libs/sel4runtime "11.0.x-compatible"

    checkout_from_github tools/camkes "t:camkes-3.8.0"
    checkout_from_github tools/nanopb "c:847ac296b50936a8b13d1434080cef8edeba621c"
    checkout_from_github tools/seL4 "11.0.x-compatible"
    checkout_from_github tools/riscv-pk "11.0.x-compatible"
}

#-------------------------------------------------------------------------------
function sel4_camkes_update_RELEASE_2020_11()
{
    checkout_from_github capdl "t:0.2.0"
    checkout_from_github kernel "t:12.0.0"

    checkout_from_github libs/musllibc "12.0.x-compatible"
    checkout_from_github libs/projects_libs "12.0.x-compatible"
    checkout_from_github libs/sel4_global_components "camkes-3.9.x-compatible"
    checkout_from_github libs/sel4_libs "12.0.x-compatible"
    checkout_from_github libs/sel4_projects_libs "12.0.x-compatible"
    checkout_from_github libs/sel4_util_libs "12.0.x-compatible"
    checkout_from_github libs/sel4runtime "12.0.x-compatible"

    checkout_from_github tools/camkes "t:camkes-3.9.0"
    checkout_from_github tools/nanopb "c:847ac296b50936a8b13d1434080cef8edeba621c"
    checkout_from_github tools/seL4 "12.0.x-compatible"
    checkout_from_github tools/riscv-pk "12.0.x-compatible"
}


#-------------------------------------------------------------------------------
function sel4_camkes_update_github_cutting_edge()
{
    checkout_from_github capdl "master"
    checkout_from_github kernel "master"

    checkout_from_github libs/musllibc "sel4"
    checkout_from_github libs/projects_libs "master"
    checkout_from_github libs/sel4_global_components "master"
    checkout_from_github libs/sel4_libs "master"
    checkout_from_github libs/sel4_projects_libs "master"
    checkout_from_github libs/sel4_util_libs "master"
    checkout_from_github libs/sel4runtime "master"

    checkout_from_github tools/camkes "master"
    checkout_from_github tools/nanopb "c:847ac296b50936a8b13d1434080cef8edeba621c"
    checkout_from_github tools/seL4 "master"
    checkout_from_github tools/riscv-pk "12.0.x-compatible"
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

# we expect to be in seos_tests
cd seos_sandbox/sdk-sel4-camkes


#sel4_camkes_update_RELEASE_old
#sel4_camkes_update_RELEASE_2020_11
sel4_camkes_update_github_cutting_edge
