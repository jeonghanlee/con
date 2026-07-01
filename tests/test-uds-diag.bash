#!/usr/bin/env bash
#
# Ctrl-T diagnostic hotkey (0x14) automated test -- issues #24 (pause), #26 (resume).
#
# The diagnostic block fires when con reads a solitary 0x14 (buf_cnt == 1,
# con.cpp:338). This was once believed un-automatable ("0x14 consumed by the PTY
# line discipline"); it is not. A local timed writer feeds, in ONE con session,
# a marker (launch proof via echo round-trip), a solitary 0x14 (the diagnostic
# pause), a resume key, then a second marker (resume proof). The first marker
# disambiguates con-not-running from a regression; the second marker AFTER the
# [diag] line proves the socket resumed (con.cpp:391-393).
#
# Timing is pinned: connect 1.5s (con must connect AND switch /dev/tty to raw
# before input, else a dead socket cooked-echoes the marker), gap 0.5s (0x14 must
# land in its own readn so buf_cnt == 1). The resume key is a dedicated space:
# con.cpp:392 consumes exactly one byte to resume, so without it the next marker's
# first char is swallowed. timeout 7s bounds the ~4s writer. A local timed writer
# is used instead of run_con because run_con writes the fifo once and cannot
# separate the reads.
#
# Only echo mode (recv-q 0, NORMAL) is automated. Flood mode (recv-q > 0) stays
# manual (manual-test-diag-hotkey.bash --flood): the poll loop drains the socket
# (pfds[0]) before checking the keyboard (pfds[1]), so a fast host reads recv-q
# as 0 regardless of load -- a structural race that retry cannot fix.
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

_log "INFO" "UDS Diagnostic Hotkey Tests (issues #24, #26)"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/diag-test.sock"
# Match the stable prefix only; the line has two formats depending on SO_RCVBUF.
# grep -F is required: [diag] is a regex character class under BRE.
DIAG_PREFIX="[diag] con recv buffer:"
MARKER="DIAG_PROBE_24680"
# Distinct from MARKER so the ordering check cannot match the pre-diag echo (#26).
RESUME_MARK="RESUME_PROBE_26"

start_echo_server "${SOCK_PATH}"

# One con session: marker (launch proof), 0x14 (pause), a dedicated space
# (resume key), a second marker (resume proof), then exit (0x01). con pauses on
# the diagnostic and resumes on the space; do not assert con's exit code.
DIAG_FIFO="${TEST_TMPDIR}/diag_input.fifo"
rm -f "${DIAG_FIFO}"
mkfifo "${DIAG_FIFO}"

( sleep 1.5; printf '%s\n' "${MARKER}"; sleep 0.5; printf '\x14'; sleep 0.6; printf ' '; sleep 0.5; printf '%s\n' "${RESUME_MARK}"; sleep 0.6; printf '\x01'; sleep 0.3 ) > "${DIAG_FIFO}" &
DIAG_WRITER_PID=$!

DIAG_OUT=$(timeout 7 script -q /dev/null -c "${CON_BIN} -c ${SOCK_PATH} -q" < "${DIAG_FIFO}" 2>&1 || true)

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

# Resume: after the diagnostic pause, a resume key restores data flow. The second
# marker must echo AFTER the [diag] line (order, not mere presence -- a run where
# the diagnostic never fired would false-pass on presence alone). grep -aFn gives
# line numbers; the -n guards handle an absent line, and the pipeline ends on cut
# (exit 0), so a no-match grep does not abort under set -e.
diag_line=$(printf "%s" "${DIAG_OUT}" | grep -aFn "${DIAG_PREFIX}" | head -1 | cut -d: -f1)
resume_line=$(printf "%s" "${DIAG_OUT}" | grep -aFn "${RESUME_MARK}" | head -1 | cut -d: -f1)
resume_ok="false"
if [ -n "${diag_line}" ] && [ -n "${resume_line}" ] && [ "${resume_line}" -gt "${diag_line}" ]; then
    resume_ok="true"
fi
verify_state "true" "${resume_ok}" "Resume key restores data flow (marker echoes after the diagnostic)"

stop_echo_server
