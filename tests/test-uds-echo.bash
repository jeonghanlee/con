#!/usr/bin/env bash
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "UDS ECHO TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "UDS Echo Round-Trip Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/echo-test.sock"

start_echo_server "${SOCK_PATH}"

TEST_STRING="HELLO_CON_TEST_12345"
run_con 1 "$(printf '%s\n\x01' "${TEST_STRING}")" "-c ${SOCK_PATH} -q"

echo_ok="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "${TEST_STRING}"; then
    echo_ok="true"
fi
verify_state "true" "${echo_ok}" "Echo server returned test string"

stop_echo_server
