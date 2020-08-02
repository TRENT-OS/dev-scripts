#!/bin/bash -ue

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
