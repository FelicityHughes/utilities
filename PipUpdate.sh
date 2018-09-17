#!/usr/bin/env bash

################################################################################
# This script keeps Python packages installed via pip up-to-date.  Prefer to
# update Python 3 packages first - some caching issues in Pip3, Pip2 seems OK.
#
# Beware if you choose to install editable packages.  See this post for details:
# https://stackoverflow.com/questions/2720014/upgrading-all-packages-with-pip
################################################################################

/usr/local/bin/pip3 list --no-cache-dir --outdated | cut -d ' ' -f1 | xargs -n1 /usr/local/bin/pip3 install -U
/usr/local/bin/pip2 list --outdated | cut -d ' ' -f1 | xargs -n1 /usr/local/bin/pip2 install --upgrade pip
