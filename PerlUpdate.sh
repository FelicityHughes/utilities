#!/usr/bin/env bash

################################################################################
# This script keeps Perl up-to-date.
################################################################################
PERLBREW_EXE="${HOME}/perl5/perlbrew/bin/perlbrew"

"${PERLBREW_EXE}" self-upgrade
"${PERLBREW_EXE}" upgrade-perl
