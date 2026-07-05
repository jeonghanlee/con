#!/usr/bin/env bash
#
# M2 (#5, U6): UNIX-domain socket sun_path length guard.
#
# con copies the target path into sockaddr_un.sun_path. A path of
# sizeof(sun_path) bytes or more (108 on Linux) was silently truncated, so con
# bound or connected to a different path with no diagnostic. The guard rejects
# such a path with a message and a non-zero exit, at both the server bind site
# (con.cpp:667) and the client connect site (con.cpp:841).
#
# This suite asserts, for both -s and -c:
#   1. an over-length path exits non-zero,
#   2. it prints the specific guard message,
#   3. on the server, no socket node is created;
# and that the 107-byte boundary path is still accepted (no over-rejection).
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "UDS SUN_PATH GUARD TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "UDS sun_path Length Guard Tests (issue #5)"
print_sub_divider

# The guard sits after con opens /dev/tty (con.cpp:629), so con must run under a
# PTY to reach it. script(1) supplies the controlling terminal; -e returns the
# child exit code (run_con in test-common.bash deliberately swallows it). No
# input is needed: con exits at the guard before any read. The exit code is
# captured inline below, not via a test-common.bash helper, to keep the shared
# run_con contract unchanged.
declare -g GUARD_RC=0
declare -g GUARD_OUTPUT=""

GUARD_MSG="UNIX socket path exceeds 107 bytes"

# An over-length REJECT path is only a string; the guard fires before
# bind/connect, so it never has to exist on disk. 130 > 108.
LONG_PATH=$(printf 'x%.0s' $(seq 1 130))

# --- Over-length server (-s): reject before bind, no socket node ---
# LONG_PATH is a bare (relative) name, so run with TEST_TMPDIR as the working
# directory: were the guard absent, strncpy would truncate to a 107-byte name
# and bind() would create that socket node right here, where we can detect it.
# TEST_TMPDIR is still empty at this point (the accept-boundary nodes are
# created later), so any socket node found means the guard failed to reject.
GUARD_RC=0
GUARD_OUTPUT=$( cd "${TEST_TMPDIR}" && timeout "${CON_TIMEOUT:-5}" script -q -e /dev/null -c "${CON_BIN} -s ${LONG_PATH}" </dev/null 2>&1 ) || GUARD_RC=$?
verify_exit_code "1" "${GUARD_RC}" "Server: over-length path exits non-zero"

srv_msg_ok="false"
if printf "%s" "${GUARD_OUTPUT}" | grep -q "${GUARD_MSG}"; then srv_msg_ok="true"; fi
verify_state "true" "${srv_msg_ok}" "Server: over-length path reports the guard message"

srv_no_node="true"
if [[ -n "$(find "${TEST_TMPDIR}" -maxdepth 1 -type s 2>/dev/null)" ]]; then srv_no_node="false"; fi
verify_state "true" "${srv_no_node}" "Server: no socket node created for over-length path"

# --- Over-length client (-c): reject before connect ---
GUARD_RC=0
GUARD_OUTPUT=$(timeout "${CON_TIMEOUT:-5}" script -q -e /dev/null -c "${CON_BIN} -c ${LONG_PATH}" </dev/null 2>&1) || GUARD_RC=$?
verify_exit_code "1" "${GUARD_RC}" "Client: over-length path exits non-zero"

cli_msg_ok="false"
if printf "%s" "${GUARD_OUTPUT}" | grep -q "${GUARD_MSG}"; then cli_msg_ok="true"; fi
verify_state "true" "${cli_msg_ok}" "Client: over-length path reports the guard message"

# --- 107-byte boundary: accepted, no over-rejection ---
# A real, filesystem-creatable path: short tmp dir + long basename = 107 bytes.
# 107 is the longest path strncpy(...,-1) round-trips intact, so the guard must
# NOT fire here (over-rejection sentinel).
print_sub_divider
_log "INFO" "107-byte accept boundary (over-rejection sentinel)"

# The boundary path is TEST_TMPDIR + "/" + filler. A 107-byte total needs a
# filler of at least one byte; if TEST_TMPDIR is so long that pad < 1, an
# exactly-107-byte path cannot be formed under it. That is an environmental
# quirk, not a guard defect, so skip this sub-case loudly instead of erroring
# the suite. The over-length REJECT assertions above always run regardless.
pad=$((107 - ${#TEST_TMPDIR} - 1))
if [[ ${pad} -lt 1 ]]; then
    _log "WARN" "SKIP: TEST_TMPDIR too long to construct a 107-byte boundary path (len=${#TEST_TMPDIR})"
else
    ACCEPT_PATH="${TEST_TMPDIR}/$(printf 'a%.0s' $(seq 1 ${pad}))"
    verify_state "107" "${#ACCEPT_PATH}" "Boundary path is exactly 107 bytes"

    # Server binds the 107-byte node and the guard does not fire.
    run_con 0 "$(printf '\x01')" "-s ${ACCEPT_PATH}"

    acc_srv_no_msg="true"
    if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "${GUARD_MSG}"; then acc_srv_no_msg="false"; fi
    verify_state "true" "${acc_srv_no_msg}" "Server: 107-byte path not rejected by the guard"

    acc_node_ok="false"
    if [[ -S "${ACCEPT_PATH}" ]]; then acc_node_ok="true"; fi
    verify_state "true" "${acc_node_ok}" "Server: 107-byte path binds a UNIX socket node"

    # Client connects to the 107-byte node and the guard does not fire.
    # Clear the stale node the server test left behind (con does not unlink its
    # own socket on exit; tracked separately as U2) so the echo server can bind.
    rm -f "${ACCEPT_PATH}"
    start_echo_server "${ACCEPT_PATH}"
    GUARD_MARKER="SUNPATH_BOUNDARY_OK_12345"
    run_con 1 "$(printf '%s\n\x01' "${GUARD_MARKER}")" "-c ${ACCEPT_PATH} -q"
    stop_echo_server

    acc_cli_no_msg="true"
    if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "${GUARD_MSG}"; then acc_cli_no_msg="false"; fi
    verify_state "true" "${acc_cli_no_msg}" "Client: 107-byte path not rejected by the guard"

    acc_cli_echo_ok="false"
    if printf "%s" "${RUN_CON_OUTPUT}" | grep -q "${GUARD_MARKER}"; then acc_cli_echo_ok="true"; fi
    verify_state "true" "${acc_cli_echo_ok}" "Client: 107-byte path connects and echoes via UDS"
fi
