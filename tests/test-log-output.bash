#!/usr/bin/env bash
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "LOG OUTPUT TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "Log Output Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/log-test.sock"
LOG_FILE="${TEST_TMPDIR}/con-test.log"

start_echo_server "${SOCK_PATH}"

TEST_STRING="LOG_VERIFY_STRING_98765"
run_con 1 "$(printf '%s\n\x01' "${TEST_STRING}")" "-c ${SOCK_PATH} -q -l ${LOG_FILE}"

stop_echo_server

log_exists="false"
if [[ -f "${LOG_FILE}" ]]; then
    log_exists="true"
fi
verify_state "true" "${log_exists}" "Log file created with -l flag"

log_has_data="false"
if [[ -f "${LOG_FILE}" ]] && grep -q "${TEST_STRING}" "${LOG_FILE}"; then
    log_has_data="true"
fi
verify_state "true" "${log_has_data}" "Log file contains transmitted data"
