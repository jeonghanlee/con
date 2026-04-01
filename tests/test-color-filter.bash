#!/usr/bin/env bash
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "COLOR FILTER TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "Color Filter Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/color-test.sock"
LOG_COLOR="${TEST_TMPDIR}/color.log"
LOG_PLAIN="${TEST_TMPDIR}/plain.log"

COLOR_DATA=$(printf "\033[0;31mRED_TEXT\033[0m PLAIN_TEXT")

# Test 1: Raw log preserves escape sequences
start_echo_server "${SOCK_PATH}"

run_con 1 "$(printf '%s\n\x01' "${COLOR_DATA}")" "-c ${SOCK_PATH} -q -l ${LOG_COLOR}"

stop_echo_server

color_has_escape="false"
if [[ -f "${LOG_COLOR}" ]] && grep -qP '\033' "${LOG_COLOR}" 2>/dev/null; then
    color_has_escape="true"
fi
verify_state "true" "${color_has_escape}" "Raw log preserves ANSI escape sequences"

# Test 2: Filtered log strips escape sequences
rm -f "${SOCK_PATH}"
start_echo_server "${SOCK_PATH}"

run_con 1 "$(printf '%s\n\x01' "${COLOR_DATA}")" "-c ${SOCK_PATH} -q -n -l ${LOG_PLAIN}"

stop_echo_server

plain_no_escape="false"
if [[ -f "${LOG_PLAIN}" ]] && ! grep -qP '\033' "${LOG_PLAIN}" 2>/dev/null; then
    plain_no_escape="true"
fi
verify_state "true" "${plain_no_escape}" "Filtered log has no ANSI escape sequences"

plain_has_text="false"
if [[ -f "${LOG_PLAIN}" ]] && grep -q "PLAIN_TEXT" "${LOG_PLAIN}"; then
    plain_has_text="true"
fi
verify_state "true" "${plain_has_text}" "Filtered log preserves plain text content"
