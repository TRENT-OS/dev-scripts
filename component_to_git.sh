#!/bin/sh

# Copyright (C) 2020-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net

#
# Usage: 
#   ./component_to_git.sh <component-name> <repository-name>
#
# Will push all commits related to the component folder into the git repository 
# in the branch "old-commits". 
#
# Example: 
#   ./component_to_git.sh RamDisk ramdisk
#
 
COMP=$1
GIT=$2

# Branch name
BRANCH=old-commits

git clone -b integration ssh://git@bitbucket.hensoldt-cyber.systems:7999/seos/sandbox.git $COMP
cd $COMP
git checkout -b $BRANCH `git subtree split --prefix components/$COMP/`
git remote add neworigin ssh://git@bitbucket.hensoldt-cyber.systems:7999/sc/$GIT.git
git push -u neworigin $BRANCH
cd ..
rm -rf $COMP
