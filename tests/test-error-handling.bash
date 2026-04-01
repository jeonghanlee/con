#!/usr/bin/env bash
#
# Error path and negative-case tests for con.
# Validates CLI argument handling, missing targets, and invalid options.

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        SCRIPT_ERROR=1
    fi
    cleanup_tmpdir
    print_summary "ERROR HANDLING TEST SUMMARY"
}
trap _handle_exit EXIT

function _run {
    "$@" >/dev/null 2>&1; local rc=$?; true
    printf "%d" "${rc}"
}

setup_tmpdir

_log "INFO" "Error Handling Tests"
print_sub_divider

# No arguments
exit_code=$(_run "${CON_BIN}")
verify_exit_code "1" "${exit_code}" "No arguments exits 1"

# Help flag
exit_code=$(_run "${CON_BIN}" -h)
verify_exit_code "1" "${exit_code}" "-h exits 1 (with usage)"

# Invalid switch
exit_code=$(_run "${CON_BIN}" -z)
verify_exit_code "1" "${exit_code}" "Invalid switch exits 1"

# Nonexistent UDS path
exit_code=$(_run "${CON_BIN}" -c "${TEST_TMPDIR}/nonexistent.sock")
verify_exit_code "1" "${exit_code}" "Connect to nonexistent socket exits 1"

# Nonexistent TTY device
exit_code=$(_run "${CON_BIN}" /dev/ttyNONEXISTENT)
verify_exit_code "1" "${exit_code}" "Open nonexistent TTY exits 1"

# Mutually exclusive flags
exit_code=$(_run "${CON_BIN}" -s -c /tmp/test.sock)
verify_exit_code "1" "${exit_code}" "Mutually exclusive -s and -c exits 1"

exit_code=$(_run "${CON_BIN}" -t -c /tmp/test.sock)
verify_exit_code "1" "${exit_code}" "Mutually exclusive -t and -c exits 1"
