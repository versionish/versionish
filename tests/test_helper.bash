#!/usr/bin/env bash

strict_mode() {
  # "unofficial" bash strict mode
  # See: http://redsymbol.net/articles/unofficial-bash-strict-mode
  set -o errexit  # Exit when simple command fails               'set -e'
  set -o errtrace # Exit on error inside any functions or subshells.
  set -o nounset  # Trigger error when expanding unset variables 'set -u'
  set -o pipefail # Do not hide errors within pipes              'set -o pipefail'
  set -o xtrace   # Display expanded command and arguments       'set -x'
  IFS=$'\n\t'     # Split words on \n\t rather than spaces
}

# Load a library from the `${BATS_TEST_DIRNAME}/test_helper' directory.
#
# Globals:
#   none
# Arguments:
#   $1 - name of library to load
# Returns:
#   0 - on success
#   1 - otherwise
load_lib() {
  local name="$1"
  load "/opt/bats-helpers/${name}/load.bash"
}

# Wrapping run function to permit exposure of FD 3 to child processes
run_wrapper() {
    run "${@}" 3>-
}

load_lib bats-support
load_lib bats-assert
load_lib bats-file
load "/opt/bats-helpers/bats-mock/stub.bash"

