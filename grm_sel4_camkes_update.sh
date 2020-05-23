#!/bin/bash -ue


# get the directory the script is located in
SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

cd ${SCRIPT_DIR}/seos_tests/src/seos_sandbox/sdk-sel4-camkes


function checkout_cutting_edge()
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
        git checkout -B ${BRANCH} github/${BRANCH}
        git pull
        git push origin ${BRANCH}
    )
}


checkout_cutting_edge capdl

checkout_cutting_edge kernel

checkout_cutting_edge libs/musllibc sel4
checkout_cutting_edge libs/sel4_libs
checkout_cutting_edge libs/sel4_project_libs
checkout_cutting_edge libs/sel4_util_libs
checkout_cutting_edge libs/sel4runtime

checkout_cutting_edge tools/camkes
checkout_cutting_edge tools/seL4

# checkout_cutting_edge tools/riscv-pk
