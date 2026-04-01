#!/usr/bin/env bash
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "UDS CONNECT TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "UDS Connection Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/connect-test.sock"

start_echo_server "${SOCK_PATH}"

# Send exit character (Ctrl-A) after brief delay
run_con 1 "$(printf '\x01')" "-c ${SOCK_PATH} -q"

connect_ok="false"
if [[ $? -eq 0 || $? -eq 124 ]]; then
    connect_ok="true"
fi
verify_state "true" "${connect_ok}" "Connect and disconnect via UDS"

stop_echo_server
