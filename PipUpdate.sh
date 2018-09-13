#!/usr/bin/env bash

################################################################################
# This script keeps Python packages installed via pip up-to-date.  Prefer to
# update Python 3 packages first.
#
# Beware if you choose to install editable packages.  See this post for details:
# https://stackoverflow.com/questions/2720014/upgrading-all-packages-with-pip
################################################################################

pip3 list --outdated | cut -d ' ' -f1 | xargs -n1 pip3 install -U
pip2 list --outdated | cut -d ' ' -f1 | xargs -n1 pip2 install -U
