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

function print_divider {
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
}

function _run_test {
    local test_name
    local test_script

    test_name="$1"
    test_script="$2"

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

function _command_is_executable {
    local command_name
    local command_path

    command_name="$1"
    command_path=$(command -v "${command_name}" 2>/dev/null) || return 1
    [[ -x "${command_path}" ]]
}

function _resolve_echo_server_mode {
    if [[ ! -v ECHO_SERVER_MODE ]]; then
        if _command_is_executable socat; then
            ECHO_SERVER_MODE="socat"
        elif [[ -x "${HELPERS_DIR}/echo_server" ]]; then
            ECHO_SERVER_MODE="echo_server"
        else
            printf "${RED}Error: Neither socat nor echo_server is available.${NC}\n" >&2
            printf "Install socat or run: make -C tests/helpers\n" >&2
            return 1
        fi
    fi

    case "${ECHO_SERVER_MODE}" in
        socat)
            if ! _command_is_executable socat; then
                printf "${RED}Error: ECHO_SERVER_MODE=socat is unavailable.${NC}\n" >&2
                return 1
            fi
            ;;
        echo_server)
            if [[ ! -x "${HELPERS_DIR}/echo_server" ]]; then
                printf "${RED}Error: ECHO_SERVER_MODE=echo_server is unavailable.${NC}\n" >&2
                printf "Run: make -C tests/helpers\n" >&2
                return 1
            fi
            ;;
        "")
            printf "${RED}Error: ECHO_SERVER_MODE cannot be empty.${NC}\n" >&2
            return 1
            ;;
        *)
            printf "${RED}Error: Unknown ECHO_SERVER_MODE: %s${NC}\n" "${ECHO_SERVER_MODE}" >&2
            return 1
            ;;
    esac

    export ECHO_SERVER_MODE
}

function _run_discovered_tests {
    local test_script
    local test_file
    local test_name
    local -a test_scripts

    test_scripts=()
    mapfile -d '' -t test_scripts < <(
        find "${SC_TOP}" -maxdepth 1 -type f -name 'test-*.bash' -print0 | LC_ALL=C sort -z
    )

    if [[ ${#test_scripts[@]} -eq 0 ]]; then
        printf "${RED}Error: No test-*.bash suites found in %s.${NC}\n" "${SC_TOP}" >&2
        return 1
    fi

    for test_script in "${test_scripts[@]}"; do
        test_file="${test_script##*/}"
        test_name="${test_file#test-}"
        test_name="${test_name%.bash}"
        test_name="${test_name//-/ }"
        _run_test "${test_name}" "${test_script}"
    done
}


# --- Pre-flight Checks ---
if [[ ! -x "${CON_BIN}" ]]; then
    printf "${RED}Error: con binary not found at %s${NC}\n" "${CON_BIN}" >&2
    printf "Run 'make' in the repository root first.\n" >&2
    exit 1
fi

# --- Resolve Echo Server Backend ---
_resolve_echo_server_mode

printf "Echo server backend: %s\n" "${ECHO_SERVER_MODE}"
printf "con binary: %s\n\n" "${CON_BIN}"

# --- Run All Tests ---
_run_discovered_tests

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
