#!/usr/bin/env bash
#
# Validates version flag output format.

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        SCRIPT_ERROR=1
    fi
    print_summary "VERSION OUTPUT TEST SUMMARY"
}
trap _handle_exit EXIT

_log "INFO" "Version Output Tests"
print_sub_divider

# -V flag produces output
output=$("${CON_BIN}" -V 2>&1 || true)

has_version="false"
if printf "%s" "${output}" | grep -q "version"; then
    has_version="true"
fi
verify_state "true" "${has_version}" "-V output contains 'version'"

has_build="false"
if printf "%s" "${output}" | grep -q "build"; then
    has_build="true"
fi
verify_state "true" "${has_build}" "-V output contains 'build'"

# -V exits 0
exit_code=$("${CON_BIN}" -V >/dev/null 2>&1; printf "%d" $?)
verify_exit_code "0" "${exit_code}" "-V exits 0"
