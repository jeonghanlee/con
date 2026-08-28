#!/usr/bin/env bash
#
# Validates the explicit UNIX transport override and preserved flagless paths.

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/common.bash"

declare -g ORIGINAL_DIR="${PWD}"
declare -g SERVER_RUNNER_PID=""
declare -g SERIAL_PTY_PID=""

function _handle_exit {
    local exit_code=$?

    cd "${ORIGINAL_DIR}" || true
    if [[ -n "${SERVER_RUNNER_PID}" ]]; then
        wait "${SERVER_RUNNER_PID}" 2>/dev/null || true
    fi
    if [[ -n "${SERIAL_PTY_PID}" ]]; then
        kill "${SERIAL_PTY_PID}" 2>/dev/null || true
        wait "${SERIAL_PTY_PID}" 2>/dev/null || true
    fi
    if [[ ${exit_code} -ne 0 ]]; then
        TEST_TOTAL=$((TEST_TOTAL + 1))
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("Script exited before all assertions completed (exit ${exit_code})")
    fi
    cleanup_tmpdir
    print_summary "EXPLICIT UNIX FLAG TEST SUMMARY"
}
trap _handle_exit EXIT

function _wait_for_socket {
    local socket_path="$1"
    local attempt=0

    while [[ ! -S "${socket_path}" && ${attempt} -lt 30 ]]; do
        sleep 0.1
        attempt=$((attempt + 1))
    done
    [[ -S "${socket_path}" ]]
}

function _output_contains {
    local output="$1"
    local marker="$2"

    if printf "%s" "${output}" | grep -Fq -- "${marker}"; then
        printf "true"
    else
        printf "false"
    fi
}

setup_tmpdir
make -C "${HELPERS_DIR}" echo_server serial_pty >/dev/null

_log "INFO" "Explicit UNIX Transport Flag Tests"
print_sub_divider

cd "${TEST_TMPDIR}"

# A relative numeric-tail target follows the TCP heuristic without the override.
# Pin the raw-argv helper because socat treats ':' as its own address separator.
requested_echo_mode="${ECHO_SERVER_MODE}"
ECHO_SERVER_MODE="echo_server"
CLIENT_SOCKET="cache:6379"
start_echo_server "${CLIENT_SOCKET}"

SHORT_MARKER="UNIX_SHORT_CLIENT_OK"
short_status=0
run_con 0.2 "$(printf '%s\n\x01' "${SHORT_MARKER}")" "-u -c ${CLIENT_SOCKET} -q" || short_status=$?
verify_exit_code "0" "${short_status}" "-u forces a numeric-tail client target to UNIX"
verify_state "true" "$(_output_contains "${RUN_CON_OUTPUT}" "${SHORT_MARKER}")" "-u client completes a real UDS echo"

LONG_MARKER="UNIX_LONG_CLIENT_OK"
long_status=0
run_con 0.2 "$(printf '%s\n\x01' "${LONG_MARKER}")" "--unix -c ${CLIENT_SOCKET} -q" || long_status=$?
verify_exit_code "0" "${long_status}" "--unix is accepted as the long option"
verify_state "true" "$(_output_contains "${RUN_CON_OUTPUT}" "${LONG_MARKER}")" "--unix client completes a real UDS echo"

stop_echo_server
ECHO_SERVER_MODE="${requested_echo_mode}"

# A colonless target normally needs an explicit socket direction. The UNIX
# override and client flag must select AF_UNIX without changing auto-detection.
COLONLESS_SOCKET="colonless.sock"
start_echo_server "${COLONLESS_SOCKET}"

COLONLESS_MARKER="UNIX_COLONLESS_CLIENT_OK"
colonless_status=0
run_con 0.2 "$(printf '%s\n\x01' "${COLONLESS_MARKER}")" "-u -c ${COLONLESS_SOCKET} -q" || colonless_status=$?
verify_exit_code "0" "${colonless_status}" "-u selects UNIX for a colonless client target"
verify_state "true" "$(_output_contains "${RUN_CON_OUTPUT}" "${COLONLESS_MARKER}")" "Colonless UNIX client completes a real UDS echo"

stop_echo_server

# Run the shipped con server and client against a relative numeric-tail path.
SERVER_SOCKET="listen:6380"
SERVER_OUTPUT_FILE="${TEST_TMPDIR}/unix-server.out"
SERVER_STATUS_FILE="${TEST_TMPDIR}/unix-server.status"
SERVER_TMPDIR="${TEST_TMPDIR}/server-runner"
mkdir "${SERVER_TMPDIR}"

(
    TEST_TMPDIR="${SERVER_TMPDIR}"
    server_status=0
    run_con 3 "$(printf '\x01')" "-u -s ${SERVER_SOCKET} -q" || server_status=$?
    printf "%s" "${RUN_CON_OUTPUT}" > "${SERVER_OUTPUT_FILE}"
    printf "%s\n" "${server_status}" > "${SERVER_STATUS_FILE}"
) &
SERVER_RUNNER_PID=$!

server_node_ok="false"
if _wait_for_socket "${SERVER_SOCKET}"; then
    server_node_ok="true"
fi
verify_state "true" "${server_node_ok}" "-u server creates a UNIX socket for a numeric-tail target"

SERVER_MARKER="UNIX_SERVER_PEER_OK"
server_client_status=0
run_con 0.2 "$(printf '%s\n\x01' "${SERVER_MARKER}")" "-u -c ${SERVER_SOCKET} -q" || server_client_status=$?
verify_exit_code "0" "${server_client_status}" "Real con client connects to the -u server"

wait "${SERVER_RUNNER_PID}"
SERVER_RUNNER_PID=""
server_status="$(<"${SERVER_STATUS_FILE}")"
server_output="$(<"${SERVER_OUTPUT_FILE}")"
verify_exit_code "0" "${server_status}" "-u server exits cleanly through its PTY"
verify_state "true" "$(_output_contains "${server_output}" "${SERVER_MARKER}")" "-u server receives peer data through AF_UNIX"

print_sub_divider
_log "INFO" "CLI and compatibility regressions"

help_output=$("${CON_BIN}" -h 2>&1 || true)
help_options_ok="$(_output_contains "${help_output}" "-u, --unix")"
help_warning_block=$(printf '%s\n%s\n%s' \
    "   Warning:" \
    "       Server mode removes an existing target path before binding." \
    "   Example:")
help_warning_ok="$(_output_contains "${help_output}" "${help_warning_block}")"
help_contract_ok="false"
if [[ "${help_options_ok}" == "true" && "${help_warning_ok}" == "true" ]]; then
    help_contract_ok="true"
fi
verify_state "true" "${help_contract_ok}" "Help lists UNIX options and the server path warning"

# The compiled fixture owns a real PTY pair and prefixes data returned through
# its master endpoint so the serial path has an observable round trip.
SERIAL_PATH_FILE="${TEST_TMPDIR}/serial-pty.path"
SERIAL_ERROR_FILE="${TEST_TMPDIR}/serial-pty.err"
"${HELPERS_DIR}/serial_pty" > "${SERIAL_PATH_FILE}" 2> "${SERIAL_ERROR_FILE}" &
SERIAL_PTY_PID=$!

attempt=0
while [[ ! -s "${SERIAL_PATH_FILE}" && ${attempt} -lt 30 ]]; do
    sleep 0.1
    attempt=$((attempt + 1))
done

serial_path=""
if [[ -s "${SERIAL_PATH_FILE}" ]]; then
    read -r serial_path < "${SERIAL_PATH_FILE}"
fi
serial_node_ok="false"
if [[ -n "${serial_path}" && -c "${serial_path}" ]]; then
    serial_node_ok="true"
fi
verify_state "true" "${serial_node_ok}" "Compiled serial helper reports a real PTY slave"

SERIAL_MARKER="FLAGLESS_SERIAL_OK"
serial_status=1
RUN_CON_OUTPUT=""
if [[ "${serial_node_ok}" == "true" ]]; then
    serial_status=0
    run_con 0.2 "$(printf '%s\n\x01' "${SERIAL_MARKER}")" "${serial_path} -q" || serial_status=$?
fi
verify_exit_code "0" "${serial_status}" "Flagless PTY target remains on the serial path"
verify_state "true" "$(_output_contains "${RUN_CON_OUTPUT}" "SERIAL_PTY_ECHO:${SERIAL_MARKER}")" "Serial fixture returns observable peer data"

kill "${SERIAL_PTY_PID}" 2>/dev/null || true
wait "${SERIAL_PTY_PID}" 2>/dev/null || true
SERIAL_PTY_PID=""

FLAGLESS_SOCKET="${TEST_TMPDIR}/flagless.sock"
ECHO_SERVER_MODE="echo_server"
start_echo_server "${FLAGLESS_SOCKET}"
FLAGLESS_MARKER="FLAGLESS_UDS_OK"
flagless_uds_status=0
run_con 0.2 "$(printf '%s\n\x01' "${FLAGLESS_MARKER}")" "-c ${FLAGLESS_SOCKET} -q" || flagless_uds_status=$?
verify_exit_code "0" "${flagless_uds_status}" "Flagless UDS classification remains unchanged"
verify_state "true" "$(_output_contains "${RUN_CON_OUTPUT}" "${FLAGLESS_MARKER}")" "Flagless UDS client retains its real echo path"
stop_echo_server
ECHO_SERVER_MODE="${requested_echo_mode}"

tcp_client_status=0
run_con 0 "" "-c 127.0.0.1:0 -q" || tcp_client_status=$?
tcp_client_failed="false"
if [[ ${tcp_client_status} -ne 0 ]]; then
    tcp_client_failed="true"
fi
verify_state "true" "${tcp_client_failed}" "Explicit TCP client still reaches the TCP connect path"
verify_state "true" "$(_output_contains "${RUN_CON_OUTPUT}" "connect:")" "TCP client failure comes from the real connect call"

tcp_server_status=0
run_con 0.2 "$(printf '\x01')" "-s :0 -q" || tcp_server_status=$?
verify_exit_code "0" "${tcp_server_status}" "Explicit TCP server still binds and exits cleanly"

flagless_tcp_status=0
run_con 0.2 "$(printf '\x01')" ":0 -q" || flagless_tcp_status=$?
verify_exit_code "0" "${flagless_tcp_status}" "Flagless TCP server direction remains unchanged"

cd "${ORIGINAL_DIR}"
