#!/usr/bin/env bash
#
# Ctrl-T diagnostic hotkey (0x14) automated test -- issue #24.
#
# The diagnostic block fires when con reads a solitary 0x14 (buf_cnt == 1,
# con.cpp:338). This was once believed un-automatable ("0x14 consumed by the PTY
# line discipline"); it is not. A local timed writer feeds, in ONE con session,
# a marker line (launch proof via echo round-trip) then -- after a gap -- a
# solitary 0x14 (the diagnostic). Asserting the marker first disambiguates
# con-not-running from a diagnostic regression, the false negative that produced
# the wrong claim.
#
# Timing is pinned: connect 1.5s (con must connect AND switch /dev/tty to raw
# before input, else a dead socket cooked-echoes the marker), gap 0.5s (0x14 must
# land in its own readn so buf_cnt == 1), hold 1.0s (capture the [diag] output).
# timeout 5s bounds the ~3s writer. A local timed writer is used instead of
# run_con because run_con writes the fifo once and cannot separate the two reads.
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    cleanup_tmpdir
    print_summary "UDS DIAGNOSTIC HOTKEY TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "UDS Diagnostic Hotkey Tests (issue #24)"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/diag-test.sock"
# Match the stable prefix only; the line has two formats depending on SO_RCVBUF.
# grep -F is required: [diag] is a regex character class under BRE.
DIAG_PREFIX="[diag] con recv buffer:"
MARKER="DIAG_PROBE_24680"

start_echo_server "${SOCK_PATH}"

# One con session: marker line (launch proof), gap, then a solitary 0x14.
# con blocks on "press any key to resume" after the diagnostic, so the session
# ends via the timeout, not a clean exit -- do not assert con's exit code.
DIAG_FIFO="${TEST_TMPDIR}/diag_input.fifo"
rm -f "${DIAG_FIFO}"
mkfifo "${DIAG_FIFO}"

( sleep 1.5; printf '%s\n' "${MARKER}"; sleep 0.5; printf '\x14'; sleep 1.0 ) > "${DIAG_FIFO}" &
DIAG_WRITER_PID=$!

DIAG_OUT=$(timeout 5 script -q /dev/null -c "${CON_BIN} -c ${SOCK_PATH} -q" < "${DIAG_FIFO}" 2>&1 || true)

kill "${DIAG_WRITER_PID}" 2>/dev/null || true
wait "${DIAG_WRITER_PID}" 2>/dev/null || true
rm -f "${DIAG_FIFO}"

# Launch proof: the marker must echo back, proving con ran and connected. An
# absent marker means con did not run/connect -- not a diagnostic regression.
proof_ok="false"
if printf "%s" "${DIAG_OUT}" | grep -qaF "${MARKER}"; then
    proof_ok="true"
fi
verify_state "true" "${proof_ok}" "con launches and connects (marker echo round-trip)"

# Diagnostic: a solitary Ctrl-T (0x14) fires the [diag] block.
diag_ok="false"
if printf "%s" "${DIAG_OUT}" | grep -qaF "${DIAG_PREFIX}"; then
    diag_ok="true"
fi
verify_state "true" "${diag_ok}" "Solitary Ctrl-T fires the diagnostic block"

stop_echo_server
