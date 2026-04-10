#!/usr/bin/env bash
#
# Peer disconnect detection test for con.
# Validates that con detects peer shutdown immediately via poll()/POLLRDHUP
# without requiring a read() call to discover EOF.

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "UDS PEER DISCONNECT TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "UDS Peer Disconnect Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/peer-disconnect.sock"

# Test 1: Server closes connection, con detects EOF and exits cleanly.
# socat sends a short payload then closes the socket (no fork, single-shot).
# con must detect the peer shutdown and terminate without hanging.
_log "INFO" "Server-side close: con must detect EOF promptly"

PAYLOAD="PEER_DISCONNECT_TEST_DATA"
socat UNIX-LISTEN:"${SOCK_PATH}" EXEC:"printf '${PAYLOAD}'" &
SOCAT_PID=$!

attempt=0
while [[ ! -S "${SOCK_PATH}" && ${attempt} -lt 20 ]]; do
    sleep 0.1
    attempt=$((attempt + 1))
done

start_ms=$(date +%s%3N)

# No exit key sent; con must exit on its own when peer closes.
# Timeout at 5s; anything over 3s is a failure.
CON_TIMEOUT=5 run_con 60 "" "-c ${SOCK_PATH} -q"

end_ms=$(date +%s%3N)
elapsed_ms=$((end_ms - start_ms))

wait "${SOCAT_PID}" 2>/dev/null || true
SOCAT_PID=""

got_data="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "${PAYLOAD}"; then
    got_data="true"
fi
verify_state "true" "${got_data}" "Received data before peer disconnect"

# con should exit within 3 seconds of peer close
fast_exit="false"
if [[ ${elapsed_ms} -lt 3000 ]]; then
    fast_exit="true"
fi
verify_state "true" "${fast_exit}" "Exited within 3s of peer disconnect (${elapsed_ms} ms)"

eof_detected="false"
if printf "%s" "${RUN_CON_OUTPUT}" | grep -qi "EOF"; then
    eof_detected="true"
fi
verify_state "true" "${eof_detected}" "EOF message reported on peer disconnect"

rm -f "${SOCK_PATH}"

# Test 2: Abrupt peer kill after connection established.
# Uses single-connection socat (no fork) so SIGKILL closes the socket immediately.
_log "INFO" "Abrupt peer kill: con must handle unclean disconnect"

socat UNIX-LISTEN:"${SOCK_PATH}" EXEC:cat 2>/dev/null &
SOCAT_PID=$!

attempt=0
while [[ ! -S "${SOCK_PATH}" && ${attempt} -lt 20 ]]; do
    sleep 0.1
    attempt=$((attempt + 1))
done

# Connect con in background, then kill socat after 1s
{
    sleep 1
    kill -9 "${SOCAT_PID}" 2>/dev/null || true
} &
KILLER_PID=$!

start_ms=$(date +%s%3N)

CON_TIMEOUT=5 run_con 60 "" "-c ${SOCK_PATH} -q"

end_ms=$(date +%s%3N)
elapsed_ms=$((end_ms - start_ms))

wait "${KILLER_PID}" 2>/dev/null || true
wait "${SOCAT_PID}" 2>/dev/null || true
SOCAT_PID=""

peer_kill_exit="false"
if [[ ${elapsed_ms} -lt 5000 ]]; then
    peer_kill_exit="true"
fi
verify_state "true" "${peer_kill_exit}" "Exited after abrupt peer kill (${elapsed_ms} ms)"

rm -f "${SOCK_PATH}"
