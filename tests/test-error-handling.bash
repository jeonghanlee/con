#!/usr/bin/env bash
#
# Error path and negative-case tests for con.
# Validates CLI argument handling, missing targets, and invalid options.

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        SCRIPT_ERROR=1
    fi
    cleanup_tmpdir
    print_summary "ERROR HANDLING TEST SUMMARY"
}
trap _handle_exit EXIT

function _run {
    "$@" >/dev/null 2>&1; local rc=$?; true
    printf "%d" "${rc}"
}

setup_tmpdir

_log "INFO" "Error Handling Tests"
print_sub_divider

# No arguments
exit_code=$(_run "${CON_BIN}")
verify_exit_code "1" "${exit_code}" "No arguments exits 1"

# Help flag
exit_code=$(_run "${CON_BIN}" -h)
verify_exit_code "1" "${exit_code}" "-h exits 1 (with usage)"

# Invalid switch
exit_code=$(_run "${CON_BIN}" -z)
verify_exit_code "1" "${exit_code}" "Invalid switch exits 1"

# Nonexistent UDS path
exit_code=$(_run "${CON_BIN}" -c "${TEST_TMPDIR}/nonexistent.sock")
verify_exit_code "1" "${exit_code}" "Connect to nonexistent socket exits 1"

# Nonexistent TTY device
exit_code=$(_run "${CON_BIN}" /dev/ttyNONEXISTENT)
verify_exit_code "1" "${exit_code}" "Open nonexistent TTY exits 1"

# Mutually exclusive flags
exit_code=$(_run "${CON_BIN}" -s -c /tmp/test.sock)
verify_exit_code "1" "${exit_code}" "Mutually exclusive -s and -c exits 1"

exit_code=$(_run "${CON_BIN}" -t -c /tmp/test.sock)
verify_exit_code "1" "${exit_code}" "Mutually exclusive -t and -c exits 1"

# Exit-key collision with the built-in diagnostic key (Ctrl-T, 0x14) -- M4 (#7).
# The guard fires during -x parsing, before con opens /dev/tty, so no PTY is
# needed. It rejects any -x value whose finalized byte equals diagChr, in both
# control and numeric forms, including a numeric value that truncates to 0x14.
COLLIDE_SOCK="${TEST_TMPDIR}/collide.sock"

exit_code=$(_run "${CON_BIN}" -x ctrl/t -c "${COLLIDE_SOCK}")
verify_exit_code "1" "${exit_code}" "Exit key colliding with Ctrl-T (control form) exits 1"

exit_code=$(_run "${CON_BIN}" -x 0x14 -c "${COLLIDE_SOCK}")
verify_exit_code "1" "${exit_code}" "Exit key colliding with Ctrl-T (numeric form) exits 1"

exit_code=$(_run "${CON_BIN}" -x 0x114 -c "${COLLIDE_SOCK}")
verify_exit_code "1" "${exit_code}" "Exit key 0x114 truncating to Ctrl-T exits 1"

# The collision message is specific, distinguishing a guard rejection from other
# exit-1 causes (e.g. an unreachable socket).
COLLIDE_MSG="conflicts with the built-in diagnostic key"
collide_out=$("${CON_BIN}" -x ctrl/t -c "${COLLIDE_SOCK}" 2>&1 || true)
collide_msg_ok="false"
if printf "%s" "${collide_out}" | grep -q "${COLLIDE_MSG}"; then collide_msg_ok="true"; fi
verify_state "true" "${collide_msg_ok}" "Exit-key collision reports the conflict message"

# A non-colliding exit key (Ctrl-A, 0x01 -- the default) must pass the guard:
# it may still exit 1 on the unreachable socket, but never via the collision
# message. This pins that the guard does not over-reject.
noncollide_out=$("${CON_BIN}" -x ctrl/a -c "${COLLIDE_SOCK}" 2>&1 || true)
noncollide_ok="true"
if printf "%s" "${noncollide_out}" | grep -q "${COLLIDE_MSG}"; then noncollide_ok="false"; fi
verify_state "true" "${noncollide_ok}" "Non-colliding exit key (Ctrl-A) not flagged by the collision guard"
