#!/usr/bin/env bash


################################################################################
# This script keeps rbenv (a Ruby environment manager) and Ruby up-to-date.  No
# arguments are required.
################################################################################


LATEST_VERSION="$(rbenv install -l | grep -v - | tail -1 | tr -d '[:space:]')"
rbenv install "${LATEST_VERSION}"
RESULT=${?}

if [[ ${RESULT} -eq 0 ]]
then
  rbenv local "${LATEST_VERSION}"
  echo "Ruby version now ${LATEST_VERSION}.  Don't forget to uninstall obsolete versions:"
  rbenv versions
else
  echo "If you chose '(y)es', you may need to turn off anti-virus protection and re-try."
fi
