#!/usr/bin/env bash -l

################################################################################
# This script keeps rbenv (a Ruby environment manager) and Ruby up-to-date.  No
# arguments are required.
#
# It is assumed rbenv and ruby-build are installed and configured for a login
# shell.  If you have aliases in your login profile, please take extra care to
# review this script and ensure it doesn't unintentionally invoke any of those
# aliases.
################################################################################
LATEST_VERSION="$("rbenv" "install" "-l" | "grep" "-v" "-" | "tail" "-1" | "tr" "-d" '[:space:]')"
VERSION_MATCH="$("rbenv" "versions" | "grep" "${LATEST_VERSION}")"

if [[ "${VERSION_MATCH}" == "" ]]; then
  rbenv install "${LATEST_VERSION}"
  RESULT=${?}

  if [[ ${RESULT} -eq 0 ]]; then
    rbenv global "${LATEST_VERSION}"
    echo "Ruby version now ${LATEST_VERSION}.  Don't forget to uninstall obsolete versions:"
    rbenv versions
  else
    echo "If you chose '(y)es', you may need to turn off anti-virus protection and re-try."
  fi
else
  VERSION_MATCH="$("rbenv" "versions" | "awk" '$1 == "*" {print $2}')"

  if [[ "${VERSION_MATCH}" == "${LATEST_VERSION}" ]]; then
    echo "Latest Ruby version ${LATEST_VERSION} is already installed and in use."
  else
    echo "Latest Ruby version ${LATEST_VERSION} is installed but version ${VERSION_MATCH} currently in use."
  fi
fi
