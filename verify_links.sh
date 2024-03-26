#!/bin/bash
set -Eeuxo pipefail

#-------------------------------------------------------------------------------
# Copyright (C) 2021-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Finds all the hyperlinks in the pdf files in the current directory, and checks
# if they are valid by issuing an http request, and prints out the failing ones.
#
# Example:
#   cd <SDK_FOLDER>/sdk/doc/pdf
#   <DEV_SCRIPTS_FOLDER>/dev-scripts/verify_links.sh
#-------------------------------------------------------------------------------

# Find all pdfs in the current dir (not recursively)...
find . -maxdepth 1 -print0 -name "*.pdf" | \
    # ...convert all pdfs to html...
    xargs -0 -n 1 -I % pdftohtml -s -i -q -stdout % "found_pdf_file.html" | \
    # ...find all hyperlinks...
    grep -Po "<[a|img]+\\s+(?:[^>]*?\\s+)?[src|href]+=[\"']\K([^\"']*)(?=\")" |\
    # ...filter out internal links...
    grep -v "found_pdf_file.html" | \
    # ...remove duplicates to optimize the number of http requests...
    sort -u | \
    # ...for each link check if valid by sending an http/s request and print
    #    if link is invalid.
    xargs -n 1 -I % \
        sh -c 'curl --output /dev/null --silent --head --fail "%" || echo "%"'
