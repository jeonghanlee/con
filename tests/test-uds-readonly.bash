#!/usr/bin/env bash
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "UDS READONLY TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "UDS Read-only Mode Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/readonly-test.sock"

# Test 1: Keyboard input is not forwarded in readonly mode
start_echo_server "${SOCK_PATH}"

TEST_STRING="READONLY_SHOULD_NOT_ECHO_67890"
run_con 1 "$(printf '%s\n\x01' "${TEST_STRING}")" "-r -c ${SOCK_PATH} -q"

not_echoed="false"
if ! printf "%s" "${RUN_CON_OUTPUT}" | grep -q "${TEST_STRING}"; then
    not_echoed="true"
fi
verify_state "true" "${not_echoed}" "Keyboard input not forwarded in readonly mode"

stop_echo_server
rm -f "${SOCK_PATH}"

# Test 2: Exit character works in readonly mode
start_echo_server "${SOCK_PATH}"

run_con 1 "$(printf '\x01')" "-r -c ${SOCK_PATH} -q"

exit_ok="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -qv "error"; then
    exit_ok="true"
fi
verify_state "true" "${exit_ok}" "Exit key works in readonly mode"

stop_echo_server
