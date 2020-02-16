#!/usr/bin/env bash -l

################################################################################
# This script updates Homebrew and its formulae and casks.  It optionally
# removes old versions as well.
#
# The program can be called with the following argument (which is optional):
# -c Indicates the script should remove old formulae & casks.
#
# It is assumed both brew and brew-cask-upgrade are installed.
# See https://github.com/buo/homebrew-cask-upgrade for details
################################################################################
BREW_EXE="$("which" "brew")"

# "${BREW_EXE}" update - No longer needed as it's done by cask upgrade.
"${BREW_EXE}" upgrade
"${BREW_EXE}" cu --all --cleanup -y < /dev/null  # See https://github.com/buo/homebrew-cask-upgrade for details
"${BREW_EXE}" cleanup
