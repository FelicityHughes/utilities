#!/usr/bin/env bash


################################################################################
# This script updates Homebrew and its formulae and casks.  It removes old
# versions as well - you may want to leave this part out if you worry about
# breaking changes.
#
# Use cron to run this daily and keep all software up to date.
################################################################################


# /usr/local/bin/brew update - No longer needed as it's done by cask upgrade.
/usr/local/bin/brew upgrade
/usr/local/bin/brew cu --cleanup -y < /dev/null  # See https://github.com/buo/homebrew-cask-upgrade for details
/usr/local/bin/brew cleanup
# NOTE:  May need to remove old Java installations manually from 
# /Library/Java/JavaVirtualMachines
