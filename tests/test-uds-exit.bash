#!/usr/bin/env bash
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "UDS EXIT KEY TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "UDS Exit Key Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/exit-test.sock"

# Test 1: Default exit key (Ctrl-A = 0x01)
start_echo_server "${SOCK_PATH}"

run_con 1 "$(printf '\x01')" "-c ${SOCK_PATH} -q"

default_ok="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -qv "error"; then
    default_ok="true"
fi
verify_state "true" "${default_ok}" "Default Ctrl-A exit clean"

stop_echo_server
rm -f "${SOCK_PATH}"

# Test 2: Custom exit key (Ctrl-B = 0x02)
start_echo_server "${SOCK_PATH}"

run_con 1 "$(printf '\x02')" "-c ${SOCK_PATH} -q -x ctrl/b"

custom_ok="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -qv "error"; then
    custom_ok="true"
fi
verify_state "true" "${custom_ok}" "Custom Ctrl-B exit clean"

stop_echo_server
