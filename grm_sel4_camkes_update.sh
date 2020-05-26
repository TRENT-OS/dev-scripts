#!/bin/bash -ue

# get the directory the script is located in
SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"


#-------------------------------------------------------------------------------
function update_cutting_edge()
{
    (
        SUBDIR=$1
        BRANCH=${2:-master}

        echo ""
        echo "-----------------------------------------------------------------"
        echo "${SUBDIR}"
        echo "-----------------------------------------------------------------"
        cd ${SUBDIR}
        git remote -v
        git fetch --all
        (
            set -x
            git checkout -B ${BRANCH} github/${BRANCH}
            git pull
            git push origin ${BRANCH}
        )
    )
}


#-------------------------------------------------------------------------------
function sel4_camkes_update_cutting_edge()
{
    cd seos_sandbox/sdk-sel4-camkes
    (
        update_cutting_edge capdl

        update_cutting_edge kernel

        update_cutting_edge libs/musllibc sel4
        update_cutting_edge libs/sel4_libs
        update_cutting_edge libs/sel4_project_libs
        update_cutting_edge libs/sel4_util_libs
        update_cutting_edge libs/sel4runtime

        update_cutting_edge tools/camkes
        update_cutting_edge tools/seL4

        update_cutting_edge tools/riscv-pk 11.0.x-compatible
    )
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

# we expect to be in seos_tests
sel4_camkes_update_cutting_edge
