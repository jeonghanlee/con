#!/usr/bin/env bash
#
# Multi-client UDS test -- issue #28.
#
# Every other suite drives one con at a time; con's real deployment has several
# clients on one procServ console socket. This suite drives two con clients
# concurrently and asserts con's client-side multi-attach behavior: concurrent
# echo attribution, detach isolation, a read-only mix, and collective EOF on
# server death.
#
# The echo backends give each client its own echo peer (socat fork / a forked
# echo_server child): "concurrent echo" here proves per-client attribution and
# non-interference, NOT procServ-style shared-console multiplexing. That face
# is the release gate's downstream two-con check (#27). Detach isolation is
# near-vacuous under socat fork (independent peers) and meaningful under the
# forked echo_server (children of one parent); both backends run.
#
# Harness: per client, a fifo + timed writer + background script(1) PTY with
# its own capture file (the diag-test pattern generalized; #24/#26). The server
# is started suite-locally via `setsid sh -c 'echo $$ > pidfile; exec ...'` so
# its real PID (= PGID) is known: a bare `setsid <srv> &` under a job-control
# shell forks an intermediate whose PID dies instantly and a group kill would
# miss (verified). The server-death case kills the group, which also reaches
# the per-connection children of either backend. common.bash is
# deliberately not modified.
set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/common.bash"

MC_SOCK=""
MC_SRV_PIDFILE=""

function _mc_stop_server {
    if [[ -n "${MC_SRV_PIDFILE}" && -s "${MC_SRV_PIDFILE}" ]]; then
        kill -- -"$(cat "${MC_SRV_PIDFILE}")" 2>/dev/null || true
        rm -f "${MC_SRV_PIDFILE}"
    fi
}

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi
    _mc_stop_server
    cleanup_tmpdir
    print_summary "UDS MULTI-CLIENT TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir
MC_SOCK="${TEST_TMPDIR}/multi-client.sock"
MC_SRV_PIDFILE="${TEST_TMPDIR}/mc_srv.pid"

_log "INFO" "UDS Multi-Client Tests (issue #28)"
print_sub_divider

# Suite-local server control: same backend selection as start_echo_server, but
# the server owns a process group and its real PID lands in the pidfile.
function _mc_start_server {
    rm -f "${MC_SRV_PIDFILE}" "${MC_SOCK}"
    if [[ "${ECHO_SERVER_MODE}" == "socat" ]]; then
        setsid sh -c "echo \$\$ > '${MC_SRV_PIDFILE}'; exec socat UNIX-LISTEN:'${MC_SOCK}',fork EXEC:cat" 2>/dev/null &
    elif [[ "${ECHO_SERVER_MODE}" == "echo_server" ]]; then
        setsid sh -c "echo \$\$ > '${MC_SRV_PIDFILE}'; exec '${HELPERS_DIR}/echo_server' '${MC_SOCK}'" 2>/dev/null &
    else
        _log "ERROR" "No echo server backend available."
        return 1
    fi
    # Poll for a NON-EMPTY pidfile and the socket node: an empty pidfile read
    # would misfire the group kill.
    local attempt=0
    while { [[ ! -s "${MC_SRV_PIDFILE}" ]] || [[ ! -S "${MC_SOCK}" ]]; } && [[ ${attempt} -lt 30 ]]; do
        sleep 0.1
        attempt=$((attempt + 1))
    done
    if [[ ! -s "${MC_SRV_PIDFILE}" || ! -S "${MC_SOCK}" ]]; then
        _log "ERROR" "Multi-client echo server failed to start."
        return 1
    fi
}

_mc_start_server

# --- Cases 1 + 2: concurrent echo attribution, then detach isolation --------
# A: connect 1.5s, marker, exit key at 4.0s. B: connect 2.0s, first marker,
# second marker at 5.0s (after A detached), exit key at 6.0s.
MARK_A1="MC_A_FIRST_28111"
MARK_B1="MC_B_FIRST_28222"
MARK_B2="MC_B_AFTER_DETACH_28333"

FIFO_A="${TEST_TMPDIR}/mc_a.fifo"; FIFO_B="${TEST_TMPDIR}/mc_b.fifo"
OUT_A="${TEST_TMPDIR}/mc_a.out";   OUT_B="${TEST_TMPDIR}/mc_b.out"
mkfifo "${FIFO_A}" "${FIFO_B}"

( sleep 1.5; printf '%s\n' "${MARK_A1}"; sleep 2.5; printf '\x01'; sleep 0.3 ) > "${FIFO_A}" &
WRITER_A=$!
( sleep 2.0; printf '%s\n' "${MARK_B1}"; sleep 3.0; printf '%s\n' "${MARK_B2}"; sleep 1.0; printf '\x01'; sleep 0.3 ) > "${FIFO_B}" &
WRITER_B=$!

timeout 10 script -q /dev/null -c "${CON_BIN} -c ${MC_SOCK} -q" < "${FIFO_A}" > "${OUT_A}" 2>&1 &
CON_A=$!
timeout 10 script -q /dev/null -c "${CON_BIN} -c ${MC_SOCK} -q" < "${FIFO_B}" > "${OUT_B}" 2>&1 &
CON_B=$!

wait "${CON_A}" 2>/dev/null || true
wait "${CON_B}" 2>/dev/null || true
kill "${WRITER_A}" "${WRITER_B}" 2>/dev/null || true
wait "${WRITER_A}" "${WRITER_B}" 2>/dev/null || true
rm -f "${FIFO_A}" "${FIFO_B}"

a_echo="false"
if grep -qaF "${MARK_A1}" "${OUT_A}"; then a_echo="true"; fi
verify_state "true" "${a_echo}" "Client A echoes its own marker while B is attached"

b_echo="false"
if grep -qaF "${MARK_B1}" "${OUT_B}"; then b_echo="true"; fi
verify_state "true" "${b_echo}" "Client B echoes its own marker while A is attached"

no_cross="true"
if grep -qaF "${MARK_B1}" "${OUT_A}" || grep -qaF "${MARK_A1}" "${OUT_B}"; then no_cross="false"; fi
verify_state "true" "${no_cross}" "No cross-client marker leakage (attribution)"

b_after_detach="false"
if grep -qaF "${MARK_B2}" "${OUT_B}"; then b_after_detach="true"; fi
verify_state "true" "${b_after_detach}" "Client B still echoes after A detaches (detach isolation)"

# --- Case 3: read-only mix (positive control -> liveness -> negative) -------
# Normal client proves the input path; the -r client's liveness is proven by
# process (kill -0 on the script wrapper, whose lifetime is bound to con's) --
# a quiet -r capture holds no observable, so capture-content liveness would
# false-pass. Only then is the absence of the -r marker meaningful.
MARK_N="MC_NORM_28444"
MARK_RO="MC_RO_28555"

FIFO_N="${TEST_TMPDIR}/mc_n.fifo"; FIFO_RO="${TEST_TMPDIR}/mc_ro.fifo"
OUT_N="${TEST_TMPDIR}/mc_n.out";   OUT_RO="${TEST_TMPDIR}/mc_ro.out"
mkfifo "${FIFO_N}" "${FIFO_RO}"

( sleep 1.5; printf '%s\n' "${MARK_N}"; sleep 3.0; printf '\x01'; sleep 0.3 ) > "${FIFO_N}" &
WRITER_N=$!
( sleep 2.0; printf '%s\n' "${MARK_RO}"; sleep 2.5; printf '\x01'; sleep 0.3 ) > "${FIFO_RO}" &
WRITER_RO=$!

timeout 10 script -q /dev/null -c "${CON_BIN} -c ${MC_SOCK} -q" < "${FIFO_N}" > "${OUT_N}" 2>&1 &
CON_N=$!
timeout 10 script -q /dev/null -c "${CON_BIN} -c ${MC_SOCK} -q -r" < "${FIFO_RO}" > "${OUT_RO}" 2>&1 &
RO_SCRIPT_PID=$!

# Liveness probe while both should be attached (after the normal marker's
# round-trip window, before either exit key).
sleep 3.5
ro_alive="false"
if kill -0 "${RO_SCRIPT_PID}" 2>/dev/null; then ro_alive="true"; fi

wait "${CON_N}" 2>/dev/null || true
wait "${RO_SCRIPT_PID}" 2>/dev/null || true
kill "${WRITER_N}" "${WRITER_RO}" 2>/dev/null || true
wait "${WRITER_N}" "${WRITER_RO}" 2>/dev/null || true
rm -f "${FIFO_N}" "${FIFO_RO}"

n_echo="false"
if grep -qaF "${MARK_N}" "${OUT_N}"; then n_echo="true"; fi
verify_state "true" "${n_echo}" "Normal client input path works alongside -r (positive control)"

verify_state "true" "${ro_alive}" "-r client session alive at probe time (kill -0 liveness)"

ro_suppressed="true"
if grep -qaF "${MARK_RO}" "${OUT_N}" || grep -qaF "${MARK_RO}" "${OUT_RO}"; then ro_suppressed="false"; fi
verify_state "true" "${ro_suppressed}" "-r client input is not forwarded (marker absent everywhere)"

# --- Case 4: server death -> every attached client gets EOF, no hang --------
MARK_D1="MC_D1_28666"
MARK_D2="MC_D2_28777"

FIFO_D1="${TEST_TMPDIR}/mc_d1.fifo"; FIFO_D2="${TEST_TMPDIR}/mc_d2.fifo"
OUT_D1="${TEST_TMPDIR}/mc_d1.out";   OUT_D2="${TEST_TMPDIR}/mc_d2.out"
mkfifo "${FIFO_D1}" "${FIFO_D2}"

# Writers hold the fifos well past the kill; no exit keys -- EOF must come
# from the dying server, not from the input side.
( sleep 1.5; printf '%s\n' "${MARK_D1}"; sleep 8 ) > "${FIFO_D1}" &
WRITER_D1=$!
( sleep 1.8; printf '%s\n' "${MARK_D2}"; sleep 8 ) > "${FIFO_D2}" &
WRITER_D2=$!

timeout 12 script -q /dev/null -c "${CON_BIN} -c ${MC_SOCK} -q" < "${FIFO_D1}" > "${OUT_D1}" 2>&1 &
CON_D1=$!
timeout 12 script -q /dev/null -c "${CON_BIN} -c ${MC_SOCK} -q" < "${FIFO_D2}" > "${OUT_D2}" 2>&1 &
CON_D2=$!

sleep 3
kill -- -"$(cat "${MC_SRV_PIDFILE}")" 2>/dev/null || true
DEATH_T0=$(date +%s)
wait "${CON_D1}" 2>/dev/null || true
wait "${CON_D2}" 2>/dev/null || true
DEATH_T1=$(date +%s)
rm -f "${MC_SRV_PIDFILE}"
kill "${WRITER_D1}" "${WRITER_D2}" 2>/dev/null || true
wait "${WRITER_D1}" "${WRITER_D2}" 2>/dev/null || true
rm -f "${FIFO_D1}" "${FIFO_D2}"

both_connected="false"
if grep -qaF "${MARK_D1}" "${OUT_D1}" && grep -qaF "${MARK_D2}" "${OUT_D2}"; then both_connected="true"; fi
verify_state "true" "${both_connected}" "Both clients connected before the server died (launch proof)"

prompt_eof="false"
if [[ $((DEATH_T1 - DEATH_T0)) -le 4 ]]; then prompt_eof="true"; fi
verify_state "true" "${prompt_eof}" "All clients exit promptly on server death (EOF, no hang)"
