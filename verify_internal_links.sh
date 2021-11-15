#!/bin/bash
set -Eeuxo pipefail

#-------------------------------------------------------------------------------
# Copyright (C) 2021, HENSOLDT Cyber GmbH
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Finds all the internal hyperlinks in the pdf files in the current directory,
# and checks if they are valid by issuing a file request, and prints out the
# failing ones.
#
# Example:
#   cd <SDK_FOLDER>/sdk/doc/pdf
#   <DEV_SCRIPTS_FOLDER>/dev-scripts/verify_internal_links.sh
#-------------------------------------------------------------------------------

# Find all pdfs in the current dir (not recursively)...
find . -maxdepth 1 -name "*.pdf" -type f -printf '%P\0' |
while IFS='\0' read -r -d '' file
do
    # ...convert all pdfs to html and store them to the tmp folder...
    pdftohtml -s -i -q "${file}" "/tmp/${file}";
    # ...find all hyperlinks...
    grep \
        -rhsPo \
        --include="${file}*" \
        "<[a|img]+\\s+(?:[^>]*?\\s+)?[src|href]+=[\"']\K([^\"']*)(?=\")"  /tmp |
    # ...filter out external links...
    grep "${file}" |
    # ...remove duplicates to optimize the number of requests...
    sort -u | \
    # ...for each link check if valid by sending a file request and print
    #    if link is invalid.
    xargs -n 1 -I % sh -c \
        'curl --output /dev/null --silent --head --fail "file:///tmp/%" || echo "%"' \
    || :; # Keep looping even if failure encountered.
done
