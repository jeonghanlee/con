#!/usr/bin/env bash
#
# Hexa output mode tests for con.
# Validates -X (hex bytes) and -Y (hex + ASCII) output format and data integrity.

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "HEXA OUTPUT TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "Hexa Output Mode Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/hexa-test.sock"

# --- Test 1: -X flag produces hex byte output ---
_log "INFO" "-X mode: hex byte format"

start_echo_server "${SOCK_PATH}"

run_con 1 "$(printf 'AB\x01')" "-c ${SOCK_PATH} -q -X"

stop_echo_server

# 'A' = 0x41, 'B' = 0x42 — output must contain hex representation
has_hex_x="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "0x41"; then
    has_hex_x="true"
fi
verify_state "true" "${has_hex_x}" "-X output contains 0x41 for ASCII 'A'"

has_hex_x2="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "0x42"; then
    has_hex_x2="true"
fi
verify_state "true" "${has_hex_x2}" "-X output contains 0x42 for ASCII 'B'"

rm -f "${SOCK_PATH}"

# --- Test 2: -Y flag produces hex + ASCII output ---
_log "INFO" "-Y mode: hex + ASCII format"

start_echo_server "${SOCK_PATH}"

run_con 1 "$(printf 'AB\x01')" "-c ${SOCK_PATH} -q -Y"

stop_echo_server

# -Y format includes bracketed ASCII character: [A], [B]
has_hex_y="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "0x41"; then
    has_hex_y="true"
fi
verify_state "true" "${has_hex_y}" "-Y output contains 0x41 for ASCII 'A'"

has_ascii_bracket="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q '\[A\]'; then
    has_ascii_bracket="true"
fi
verify_state "true" "${has_ascii_bracket}" "-Y output contains [A] ASCII display"

rm -f "${SOCK_PATH}"

# --- Test 3: -X handles non-printable bytes ---
_log "INFO" "-X mode: non-printable byte representation"

start_echo_server "${SOCK_PATH}"

# Send 0xff 0x00 then exit key
run_con 1 "$(printf '\xff\x01')" "-c ${SOCK_PATH} -q -X"

stop_echo_server

has_ff="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "0xff"; then
    has_ff="true"
fi
verify_state "true" "${has_ff}" "-X output contains 0xff for non-printable byte"

rm -f "${SOCK_PATH}"

# --- Test 4: -Y shows dot for non-printable in ASCII column ---
_log "INFO" "-Y mode: non-printable shown as dot"

start_echo_server "${SOCK_PATH}"

run_con 1 "$(printf '\xff\x01')" "-c ${SOCK_PATH} -q -Y"

stop_echo_server

has_dot="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q '\[\.\]'; then
    has_dot="true"
fi
verify_state "true" "${has_dot}" "-Y output shows [.] for non-printable byte"

rm -f "${SOCK_PATH}"
