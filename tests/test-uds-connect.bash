#!/usr/bin/env bash
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/common.bash"

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
CONNECT_STRING="UDS_CONNECT_OK_12345"

start_echo_server "${SOCK_PATH}"

# Send a payload, observe the echo, and exit with Ctrl-A.
connect_rc=0
run_con 1 "$(printf '%s\n\x01' "${CONNECT_STRING}")" "-c ${SOCK_PATH} -q" || connect_rc=$?
verify_exit_code "0" "${connect_rc}" "Connect and disconnect via UDS"

connect_echo_ok="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "${CONNECT_STRING}"; then
    connect_echo_ok="true"
fi
verify_state "true" "${connect_echo_ok}" "Connected UDS endpoint returned the payload"

stop_echo_server
rm -f "${SOCK_PATH}"

# A missing endpoint must remain non-zero through the PTY helper and cleanup.
MISSING_SOCK="${TEST_TMPDIR}/missing-connect.sock"
missing_rc=0
run_con 0 "" "-c ${MISSING_SOCK} -q" || missing_rc=$?

missing_failed="false"
if [[ ${missing_rc} -ne 0 ]]; then
    missing_failed="true"
fi
verify_state "true" "${missing_failed}" "Missing UDS endpoint returns non-zero"

# --- Issue #4: a UDS path containing ':' must route UNIX, not TCP ---
print_sub_divider
_log "INFO" "Colon-in-path disambiguation (issue #4)"

# socat treats ':' as an address separator, so a colon path needs the
# raw-argv compiled backend; build it on demand and pin it for this block.
make -C "${SC_TOP}/helpers" >/dev/null 2>&1 || true
ECHO_SERVER_MODE="echo_server"

# Client: -c to a colon path echoes via UDS and never reports "Invalid port".
COLON_SOCK="${TEST_TMPDIR}/proc:serv.sock"
start_echo_server "${COLON_SOCK}"
COLON_STR="COLON_PATH_OK_67890"
run_con 1 "$(printf '%s\n\x01' "${COLON_STR}")" "-c ${COLON_SOCK} -q"
stop_echo_server

colon_echo_ok="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "${COLON_STR}"; then colon_echo_ok="true"; fi
verify_state "true" "${colon_echo_ok}" "Client: colon path echoes via UDS"

colon_client_no_tcp="true"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "Invalid port"; then colon_client_no_tcp="false"; fi
verify_state "true" "${colon_client_no_tcp}" "Client: colon path not misrouted to TCP"

# Server: -s follows the same tcp_separator() classification and binds a UNIX
# socket node.
SRV_SOCK="${TEST_TMPDIR}/srv:listen.sock"
run_con 0 "$(printf '\x01')" "-s ${SRV_SOCK}"

srv_node_ok="false"
if [[ -S "${SRV_SOCK}" ]]; then srv_node_ok="true"; fi
verify_state "true" "${srv_node_ok}" "Server: colon path binds a UNIX socket node"

srv_no_tcp="true"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "Invalid port"; then srv_no_tcp="false"; fi
verify_state "true" "${srv_no_tcp}" "Server: colon path not misrouted to TCP"
