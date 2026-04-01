#!/usr/bin/env bash
#
# Master test runner for con utility.
# Discovers and runs all test-*.bash scripts in the tests directory.
# Supports dual echo server backends: socat (preferred) or compiled echo_server.

set -e

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g NC='\033[0m'

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

declare -g REPO_TOP="${SC_TOP}/.."
declare -g CON_BIN="${REPO_TOP}/con"
declare -g HELPERS_DIR="${SC_TOP}/helpers"

# --- Global Tracking Variables (Top of run-all-tests.bash) ---
declare -g GLOBAL_PASSED=0
declare -g GLOBAL_FAILED=0
declare -g -a GLOBAL_FAILED_SUITES=()


# Exported for child test scripts
export CON_BIN
export HELPERS_DIR
export ECHO_SERVER_MODE=""

function print_divider {
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
}

function _run_test {
    local test_name="$1"
    local test_script="$2"

    print_divider
    printf "${BLUE}[ RUN      ] %s${NC}\n" "${test_name}"
    print_divider

    # Execute the test script and capture its exit status
    if bash "${test_script}"; then
        # The child script already printed its own summary.
        # We just increment the global counter here.
        GLOBAL_PASSED=$((GLOBAL_PASSED + 1))
    else
        # Only print failure message if the child script failed
        printf "\n${RED}[ FAILED   ] %s${NC}\n\n" "${test_name}"
        GLOBAL_FAILED=$((GLOBAL_FAILED + 1))
        GLOBAL_FAILED_SUITES+=("${test_name}")
    fi
}


# --- Pre-flight Checks ---
if [[ ! -x "${CON_BIN}" ]]; then
    printf "${RED}Error: con binary not found at %s${NC}\n" "${CON_BIN}" >&2
    printf "Run 'make' in the repository root first.\n" >&2
    exit 1
fi

# --- Resolve Echo Server Backend ---
if command -v socat >/dev/null 2>&1; then
    ECHO_SERVER_MODE="socat"
elif [[ -x "${HELPERS_DIR}/echo_server" ]]; then
    ECHO_SERVER_MODE="echo_server"
else
    printf "Building echo_server helper...\n"
    make -C "${HELPERS_DIR}" >/dev/null 2>&1
    if [[ -x "${HELPERS_DIR}/echo_server" ]]; then
        ECHO_SERVER_MODE="echo_server"
    else
        printf "${RED}Error: Neither socat nor echo_server available.${NC}\n" >&2
        printf "Install socat or run: make -C tests/helpers\n" >&2
        exit 1
    fi
fi
export ECHO_SERVER_MODE

printf "Echo server backend: %s\n" "${ECHO_SERVER_MODE}"
printf "con binary: %s\n\n" "${CON_BIN}"

# --- Run All Tests ---
_run_test "Error Handling"  "${SC_TOP}/test-error-handling.bash"
_run_test "Version Output"  "${SC_TOP}/test-version.bash"
_run_test "UDS Connect"     "${SC_TOP}/test-uds-connect.bash"
_run_test "UDS Echo"        "${SC_TOP}/test-uds-echo.bash"
_run_test "UDS Exit Key"    "${SC_TOP}/test-uds-exit.bash"
_run_test "Log Output"      "${SC_TOP}/test-log-output.bash"
_run_test "Color Filter"    "${SC_TOP}/test-color-filter.bash"
_run_test "Throughput Stress" "${SC_TOP}/test-throughput.bash"

# --- Print Global Summary ---
print_divider
printf "${BLUE}  GLOBAL TEST SUMMARY${NC}\n"
print_divider

# Calculate total suites in global scope
total_suites=$((GLOBAL_PASSED + GLOBAL_FAILED))
printf "  %-20s : %d\n" "Total Test Suites" "${total_suites}"
printf "${GREEN}  %-20s : %d${NC}\n" "Passed Suites" "${GLOBAL_PASSED}"

if [[ ${GLOBAL_FAILED} -gt 0 ]]; then
    printf "${RED}  %-20s : %d${NC}\n" "Failed Suites" "${GLOBAL_FAILED}"
    printf "\n${RED}%s${NC}\n" "--- [ FAILED SUITES ] ---"
    for suite in "${GLOBAL_FAILED_SUITES[@]}"; do
        printf "${RED}  * %s${NC}\n" "${suite}"
    done
    print_divider
    exit 1
else
    printf "  %-20s : %d\n\n" "Failed Suites" "0"
    printf "${GREEN}%s${NC}\n" "ALL TEST SUITES COMPLETED SUCCESSFULLY."
    print_divider
    exit 0
fi
