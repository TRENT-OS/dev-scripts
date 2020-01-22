#!/bin/bash -uex

SEOS_TEST=test_network_api.py

clear
cd seos_tests

if [[ ${1:-} == "prepare" ]]; then
    src/test.sh prepare
fi

src/test.sh run ${SEOS_TEST} --capture=no
