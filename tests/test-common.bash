#!/usr/bin/env bash
#
# Shared utilities for con test scripts.
# Source this file at the top of each test-*.bash script.

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g MAGENTA='\033[0;35m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

declare -g TEST_TOTAL=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0
declare -g SCRIPT_ERROR=0
declare -g -a FAILED_DETAILS=()

declare -g TEST_TMPDIR=""
declare -g ECHO_SERVER_PID=""

# Provide default paths if not exported by a master test runner
declare -g CON_BIN="${CON_BIN:-${SC_TOP}/../con}"
declare -g HELPERS_DIR="${HELPERS_DIR:-${SC_TOP}/helpers}"

function _log {
    local level="$1"
    local message="$2"
    local color="${NC}"

    case "${level}" in
        "INFO")    color="${BLUE}" ;;
        "SUCCESS") color="${GREEN}" ;;
        "WARN")    color="${YELLOW}" ;;
        "ERROR")   color="${RED}" ;;
    esac

    printf "${color}[%-7s] %s${NC}\n" "${level}" "${message}"
}

function print_divider {
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
}

function print_sub_divider {
    printf "${BLUE}%s${NC}\n" "----------------------------------------------------------------------------------------------------"
}

function verify_state {
    local expected="$1"
    local actual="$2"
    local step_name="$3"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [[ "${expected}" == "${actual}" ]]; then
        printf "${GREEN}[ PASS ]${NC} %s\n" "${step_name}"
        TEST_PASSED=$((TEST_PASSED + 1))
    else
        printf "${RED}[ FAIL ]${NC} %s\n" "${step_name}" >&2
        printf "  ${YELLOW}Expected : %s${NC}\n" "${expected}" >&2
        printf "  ${YELLOW}Actual   : %s${NC}\n" "${actual}" >&2
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("${step_name} (Expected: ${expected}, Actual: ${actual})")
    fi
}

function verify_exit_code {
    local expected_exit="$1"
    local actual_exit="$2"
    local step_name="$3"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [[ "${expected_exit}" == "${actual_exit}" ]]; then
        printf "${GREEN}[ PASS ]${NC} %s\n" "${step_name}"
        TEST_PASSED=$((TEST_PASSED + 1))
    else
        printf "${RED}[ FAIL ]${NC} %s\n" "${step_name}" >&2
        printf "  ${YELLOW}Expected exit : %s${NC}\n" "${expected_exit}" >&2
        printf "  ${YELLOW}Actual exit   : %s${NC}\n" "${actual_exit}" >&2
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("${step_name} (Expected: ${expected_exit}, Actual: ${actual_exit})")
    fi
}

function print_summary {
    local test_name="$1"

    printf "\n"
    print_divider
    printf "${BLUE}  %s${NC}\n" "${test_name}"
    print_divider

    printf "  %-20s : %d\n" "Total Assertions" "${TEST_TOTAL}"
    printf "${GREEN}  %-20s : %d${NC}\n" "Passed" "${TEST_PASSED}"

    if [[ ${TEST_FAILED} -gt 0 ]]; then
        printf "${RED}  %-20s : %d${NC}\n" "Failed" "${TEST_FAILED}"
        printf "\n${RED}%s${NC}\n" "--- [ FAILED ASSERTIONS ] ---"
        for detail in "${FAILED_DETAILS[@]}"; do
            printf "${RED}  * %s${NC}\n" "${detail}"
        done
        print_divider
        exit 1
    else
        printf "  %-20s : %d\n" "Failed" "0"
    fi

    print_divider
}

function setup_tmpdir {
    TEST_TMPDIR=$(mktemp -d)
}

function cleanup_tmpdir {
    stop_echo_server
    if [[ -d "${TEST_TMPDIR}" ]]; then
        rm -rf "${TEST_TMPDIR}"
    fi
}

# Start echo server on the given socket path.
# Uses socat if available, falls back to compiled echo_server.
function start_echo_server {
    local sock_path="$1"

    if [[ "${ECHO_SERVER_MODE}" == "socat" ]]; then
        socat UNIX-LISTEN:"${sock_path}",fork EXEC:cat 2>/dev/null &
        ECHO_SERVER_PID=$!
    elif [[ "${ECHO_SERVER_MODE}" == "echo_server" ]]; then
        "${HELPERS_DIR}/echo_server" "${sock_path}" &
        ECHO_SERVER_PID=$!
    else
        _log "ERROR" "No echo server backend available."
        return 1
    fi

    # Wait for socket to appear
    local attempt=0
    while [[ ! -S "${sock_path}" && ${attempt} -lt 20 ]]; do
        sleep 0.1
        attempt=$((attempt + 1))
    done

    if [[ ! -S "${sock_path}" ]]; then
        _log "ERROR" "Echo server failed to create socket at ${sock_path}"
        return 1
    fi
}

function stop_echo_server {
    if [[ -n "${ECHO_SERVER_PID}" ]]; then
        kill "${ECHO_SERVER_PID}" 2>/dev/null || true
        wait "${ECHO_SERVER_PID}" 2>/dev/null || true
        ECHO_SERVER_PID=""
    fi
}

# Run con with PTY-based input via script(1).
# con reads from /dev/tty directly, so piped stdin does not reach it.
# script(1) allocates a PTY that becomes the controlling terminal for con.
# Usage: run_con <delay_before_input> <input_data> <con_args...>
# Returns: captured stdout and stderr in global variable RUN_CON_OUTPUT
declare -g RUN_CON_OUTPUT=""

function run_con {
    local delay="$1"
    local input_data="$2"
    shift 2
    local con_args=("$@")

    local input_fifo="${TEST_TMPDIR}/con_input.fifo"
    rm -f "${input_fifo}"
    mkfifo "${input_fifo}"

    # Feed input with delay in background
    (sleep "${delay}"; printf "%s" "${input_data}") > "${input_fifo}" &
    local feeder_pid=$!

    # Use dynamic timeout (default 5s) and capture stderr (2>&1) for debugging
    local t_out="${CON_TIMEOUT:-5}"
    RUN_CON_OUTPUT=$(timeout "${t_out}" script -q /dev/null -c "${CON_BIN} ${con_args[*]}" < "${input_fifo}" 2>&1 || true)

    kill "${feeder_pid}" 2>/dev/null || true
    wait "${feeder_pid}" 2>/dev/null || true
    rm -f "${input_fifo}"
}
