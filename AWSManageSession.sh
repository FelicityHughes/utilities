#!/usr/bin/env bash


################################################################################
# This script keeps AWS sessions alive by requesting a new token with saml2aws.
# The first time the script is run for a given profile, it will try to create an
# automated job that recalls the script for that profile every 55 minutes.  It
# re-uses the account last used with the nominated profile, keeping track of
# the profile+account pair in ~/.aws/history.
#
# The program can be called with the following arguments (both are optional):
# -a <account> The name of the AWS account to use.  The first time a new profile
#              is nominated, the account MUST be specified as well.
# -p <profile> The name of the AWS profile to use.  If not set, the script will
#              use 'default'.
#
# If you wish to change the account used with a given profile, simply run the
# script manually.
################################################################################


################################################################################
# Usage, file path & miscellaneous constants.
################################################################################
readonly USAGE="USAGE:  $0 [-a <account>] [-p <profile>]"
readonly ALLOWED_FLAGS="^-[ap]$"

readonly WORKING_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"
readonly SCRIPT_NAME="$("basename" "${BASH_SOURCE[0]}")"

# Include error handling functionality.
. "${WORKING_DIR}/ErrorHandling.sh"

readonly AWS_DIR="${HOME}/.aws"
readonly AWS_CREDENTIALS="${AWS_DIR}/credentials"
readonly AWS_HISTORY="${AWS_DIR}/history"

readonly TOKEN_EXPIRY_REGEX="^x_security_token_expires..*"


################################################################################
# Script-specific exit states.
################################################################################
readonly NO_SESSION_ERROR=96
readonly UNHANDLED_OS_ERROR=97


################################################################################
# Command line switch environment variables.
################################################################################
account=""
profile="default"


################################################################################
# Checks command line arguments are valid and have valid arguments.
#
# @param $@ All arguments passed on the command line.
################################################################################
check_args() {
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      -a)
        while ! [[ "${2}" =~ ${ALLOWED_FLAGS} ]] && [[ ${#} -gt 1 ]]; do
          account="${2}"
          shift
        done

        if [[ "${account}" == "" ]]; then
          exit_with_error "${BAD_ARGUMENT_ERROR}" \
                          "Option ${1} requires an argument.\n${USAGE}"
        fi
        ;;
      -p)
        while ! [[ "${2}" =~ ${ALLOWED_FLAGS} ]] && [[ ${#} -gt 1 ]]; do
          profile="${2}"
          shift
        done

        if [[ "${profile}" == "" ]]; then
          exit_with_error "${BAD_ARGUMENT_ERROR}" \
                          "Option ${1} requires an argument.\n${USAGE}"
        fi
        ;;
      *)
        exit_with_error "${BAD_ARGUMENT_ERROR}" \
                        "Invalid option: ${1}.\n${USAGE}"
        ;;
    esac
    shift
  done
}


################################################################################
# Removes the token expiry line from the AWS credentials file for the nominated
# profile.
#
# This line only seems to be used by saml2aws to stop requests for new tokens
# within the timeout, so removing it before expiry should not interfere with
# AWSCLI calls using the old token while we retrieve a new one.
################################################################################
clear_token() {
  sed -i "" -e '/^\['"${profile}"'\]$/,/'"${TOKEN_EXPIRY_REGEX}"'/{/'"${TOKEN_EXPIRY_REGEX}"'/d;};' \
      "${AWS_CREDENTIALS}"
}


################################################################################
# Creates a recurring job so the session for the current profile is kept
# active.  Currently only works for macos.
################################################################################
create_job () {
  local -r KERNEL_NAME="$("uname" "-s" | "tr" "[:upper:]" "[:lower:]")"

  case "${KERNEL_NAME}" in
    darwin)
          create_mac_agent
          ;;
    *)
          exit_with_error "${UNHANDLED_OS_ERROR}" \
                          "Unknown operating system - ${KERNEL_NAME}.  Exiting."
  esac
}


################################################################################
# Creates a recurring launchctl job on macos so the session for the current
# profile is kept active.
#
# Note:  The job will write both stdout and stderr streams to /dev/null.  If the
#        script does not appear to run from launchd, you can change the
#        StandardErrorPath and StandardOutPath keys at the bottom of the file to
#        redirect output to log files.  Please ensure any such files are subject
#        to external log maintenance (rotation/clearing via logrotate, for
#        example) as this script makes no attempt to manage logs.
################################################################################
create_mac_agent() {
  local -r PLIST_FILE="${HOME}/Library/LaunchAgents/com.intelematics.AwsKeepAlive_${profile}.plist"
  local -r SESSION_REFRESH_SECS=3300

  cat << EOF > "${PLIST_FILE}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.intelematics.awskeepalive_${profile}.activator</string>
    <key>ProgramArguments</key>
    <array>
      <string>${WORKING_DIR}/${SCRIPT_NAME}</string>
      <string>-p</string>
      <string>${profile}</string>
    </array>

    <key>Nice</key>
    <integer>1</integer>

    <key>StartInterval</key>
    <integer>${SESSION_REFRESH_SECS}</integer>

    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
  </dict>
</plist>
EOF

  launchctl load "${PLIST_FILE}"
}


################################################################################
# Prints the account last used for the current profile as stored in the history
# file.
################################################################################
get_account() {
  sed -n 's/^'"${profile}"' \(..*\)$/\1/p' < "${AWS_HISTORY}"
}


################################################################################
# Sets the account according to the last one used for the nominated profile if
# no account supplied on the command line.  We need both when calling saml2aws.
################################################################################
set_account() {
  if [[ "${account}" == "" ]]; then
    # Read account from login history, based on profile.
    account="$("get_account")"

    if [[ "${account}" == "" ]]; then
      exit_with_error "${BAD_ARGUMENT_ERROR}" \
                      "Profile *${profile}* not previously logged - account must be nominated.\n${USAGE}"
    fi
  fi
}


################################################################################
# Ensures the credentials and history files exist.
################################################################################
set_aws_files() {
  if [[ ! -f "${AWS_CREDENTIALS}" ]]; then
    mkdir -p "${AWS_DIR}" && touch "${AWS_CREDENTIALS}"
  fi

  if [[ ! -f "${AWS_HISTORY}" ]]; then
    touch "${AWS_HISTORY}"
  fi
}


################################################################################
# Records the account and profile used for this login to the history file.  If
# this is the first time the profile has been used, the program will also create
# a job to keep the session active.
################################################################################
set_history() {
  local -r OLD_ACCOUNT="$("get_account")"

  if [[ "${OLD_ACCOUNT}" != "" ]]; then
    # Subsequent run for profile
    sed -i "" "s/^\(${profile}\) ${OLD_ACCOUNT}$/\1 ${account}/" "${AWS_HISTORY}"
  else
    # First run for profile
    echo "${profile} ${account}" >> "${AWS_HISTORY}"
    create_job
  fi
}


################################################################################
# Creates a saml2aws session.
################################################################################
start_session() {
  echo -ne "${account}\n" | \
       /usr/local/bin/saml2aws login -p "${profile}" --skip-prompt

  if [[ "${?}" != "${SUCCESS}" ]]; then
    exit_with_error "${NO_SESSION_ERROR}" \
                    "Could not connect with profile ${profile} & account ${account}."
  fi
}


################################################################################
# Entry point to the program.  Valid command line options are described at the
# top of the script.
#
# @param ARGS Command line flags, including -a <account name> and
#             -p <profile name>.  Both are optional.
################################################################################
main() {
  local -r ARGS=("${@}")

  check_args "${ARGS[@]}"
  set_aws_files
  set_account
  clear_token
  start_session
  set_history
}


################################################################################
# Set up for bomb-proof exit, then run the script
################################################################################
trap_with_signal cleanup HUP INT QUIT ABRT TERM EXIT

main "${@}"

exit ${SUCCESS}
