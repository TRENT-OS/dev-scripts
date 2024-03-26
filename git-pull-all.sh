#!/bin/bash -ue

# Copyright (C) 2020-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net

git fetch --all

BRANCHES=(
    # move line with '*' to the end, remove '*', remove leading spaces
    $(git branch | sed '/*/{$q;h;d};$G' | tr -d '*' | sed 's/^ *//g')
)

for branch in ${BRANCHES[@]}; do
    echo ""
    echo "----  ${branch}"
    git checkout ${branch}
    git merge --ff-only
done
