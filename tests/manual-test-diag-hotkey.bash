#!/usr/bin/env bash
#
# Manual test for Ctrl-T diagnostic hotkey.
# Ctrl-T (0x14) is consumed by PTY line discipline in automated tests,
# so this must be verified interactively.
#
# Two modes:
#   (default)  Echo server  - verify Ctrl-T output and key consumption
#   --flood    Flood server - verify non-zero recv-q under load
#
# Usage:
#   bash tests/manual-test-diag-hotkey.bash          # echo mode
#   bash tests/manual-test-diag-hotkey.bash --flood   # flood mode

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

REPO_TOP="${SC_TOP}/.."
CON_BIN="${CON_BIN:-${REPO_TOP}/con}"
SOCK="/tmp/con-diag-manual-test.sock"
FLOOD_MODE=0

if [[ "${1:-}" == "--flood" ]]; then
    FLOOD_MODE=1
fi

if [[ ! -x "${CON_BIN}" ]]; then
    printf "Error: con binary not found at %s\n" "${CON_BIN}" >&2
    printf "Run make in the repository root first.\n" >&2
    exit 1
fi

if ! command -v socat >/dev/null 2>&1; then
    printf "Error: socat is required for this test.\n" >&2
    exit 1
fi

rm -f "${SOCK}"

SOCAT_PID=""

function _cleanup {
    if [[ -n "${SOCAT_PID}" ]]; then
        kill "${SOCAT_PID}" 2>/dev/null || true
        wait "${SOCAT_PID}" 2>/dev/null || true
    fi
    rm -f "${SOCK}"
}
trap _cleanup EXIT

function _wait_for_socket {
    local attempt=0
    while [[ ! -S "${SOCK}" && ${attempt} -lt 20 ]]; do
        sleep 0.1
        attempt=$((attempt + 1))
    done
    if [[ ! -S "${SOCK}" ]]; then
        printf "Error: Server failed to create socket.\n" >&2
        exit 1
    fi
}

if [[ ${FLOOD_MODE} -eq 0 ]]; then
    printf "%s\n" "===================================================================================================="
    printf "  Ctrl-T Diagnostic Hotkey - Echo Mode\n"
    printf "%s\n" "===================================================================================================="
    printf "\n"
    printf "This connects con to an echo server.\n"
    printf "Perform the following checks:\n"
    printf "\n"
    printf "  1. Press Ctrl-T  --> Expect: [diag] ... recv-q: 0 bytes pending\n"
    printf "  2. Type any text --> Expect: Text echoed back (Ctrl-T was consumed)\n"
    printf "  3. Press Ctrl-A  --> Expect: Clean exit\n"
    printf "\n"
    printf "To test non-zero recv-q, re-run with --flood:\n"
    printf "  bash %s --flood\n" "${SC_RPATH}"
    printf "\n"
    printf "%s\n" "----------------------------------------------------------------------------------------------------"
    printf "Starting echo server on %s ...\n" "${SOCK}"

    socat UNIX-LISTEN:"${SOCK}",fork EXEC:cat 2>/dev/null &
    SOCAT_PID=$!
    _wait_for_socket

    printf "Echo server ready. Launching con...\n"
    printf "%s\n" "----------------------------------------------------------------------------------------------------"
    printf "\n"

    "${CON_BIN}" -c "${SOCK}" -q
else
    printf "%s\n" "===================================================================================================="
    printf "  Ctrl-T Diagnostic Hotkey - Flood Mode\n"
    printf "%s\n" "===================================================================================================="
    printf "\n"
    printf "This connects con to a flood server that sends data continuously.\n"
    printf "The screen will scroll rapidly. Perform the following check:\n"
    printf "\n"
    printf "  1. Press Ctrl-T  --> Expect: [diag] ... recv-q: N bytes pending (N > 0)\n"
    printf "  2. Press Ctrl-A  --> Exit\n"
    printf "\n"
    printf "%s\n" "----------------------------------------------------------------------------------------------------"
    printf "Starting flood server on %s ...\n" "${SOCK}"

    yes "$(printf 'FLOOD_DATA_LINE\r')" | socat UNIX-LISTEN:"${SOCK}" STDIN 2>/dev/null &
    SOCAT_PID=$!
    _wait_for_socket

    printf "Flood server ready. Launching con...\n"
    printf "%s\n" "----------------------------------------------------------------------------------------------------"
    printf "\n"

    "${CON_BIN}" -c "${SOCK}" -q
fi

printf "\n"
printf "%s\n" "===================================================================================================="
printf "  Test complete. Verify the results above manually.\n"
printf "%s\n" "===================================================================================================="
