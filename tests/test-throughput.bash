#!/usr/bin/env bash
#
# Throughput and Flood Handling Test for con.
# Validates how fast con can process and log a massive stream of IOC errors.

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/test-common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then SCRIPT_ERROR=1; fi

    if [[ -n "${SOCAT_PID}" ]]; then
        kill "${SOCAT_PID}" 2>/dev/null || true
    fi
    cleanup_tmpdir
    print_summary "THROUGHPUT STRESS TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir


_log "INFO" "IOC Error Flood & Throughput Tests"
print_sub_divider

SOCK_PATH="${TEST_TMPDIR}/flood-test.sock"
LOG_FILE="${TEST_TMPDIR}/flood.log"
FLOOD_DATA="${TEST_TMPDIR}/flood_data.txt"

# 1. Generate ~10MB of dummy IOC crash log data
_log "INFO" "Generating ~10MB of dummy IOC error logs..."
yes "$(printf '\033[0;31mFATAL ERROR: IOC Crash loop detected! Core dumped at memory address 0xDEADBEEF\033[0m')" | head -n 100000 > "${FLOOD_DATA}"

# Append the exit key (Ctrl-A = \x01) at the end to cleanly terminate 'con' after receiving all data
printf '\x01' >> "${FLOOD_DATA}"

ORIG_SIZE=$(stat -c%s "${FLOOD_DATA}")
_log "INFO" "Payload size: ${ORIG_SIZE} bytes"

# 2. Start a dedicated socat server that floods the file contents immediately upon connection
socat UNIX-LISTEN:"${SOCK_PATH}",fork FILE:"${FLOOD_DATA}" &
SOCAT_PID=$!

# Wait for the UDS socket to be created
attempt=0
while [[ ! -S "${SOCK_PATH}" && ${attempt} -lt 20 ]]; do
    sleep 0.1
    attempt=$((attempt + 1))
done

# 3. Execute 'con' and start measuring processing time (ms)
_log "INFO" "Connecting 'con' to the flood server (Color filtering enabled)..."
start_time=$(date +%s%3N)

# Set both timeout and PTY delay to 60 seconds to prevent premature termination.
# con will exit naturally upon receiving socket EOF from socat.
CON_TIMEOUT=60 run_con 60 "" "-c ${SOCK_PATH} -q -n -l ${LOG_FILE}"

end_time=$(date +%s%3N)
elapsed_ms=$((end_time - start_time))

# 4. Verify results and calculate throughput (MB/s)
if [[ ! -f "${LOG_FILE}" ]]; then
    # Output the exact error message captured from con to identify the failure point
    _log "ERROR" "con failed to execute or crashed before creating the log file."
    _log "ERROR" "Captured output: ${RUN_CON_OUTPUT}"
    verify_state "true" "false" "Log file was created"
    exit 1
fi

LOG_SIZE=$(stat -c%s "${LOG_FILE}")

# Since ANSI color codes (\033[...m) are filtered out, the logged size must be strictly smaller than the original payload
if [[ ${LOG_SIZE} -gt 0 && ${LOG_SIZE} -lt ${ORIG_SIZE} ]]; then
    verify_state "true" "true" "Data received and color filtered successfully"
else
    verify_state "true" "false" "Data size mismatch (Logged: ${LOG_SIZE}, Expected < ${ORIG_SIZE})"
fi

# Prevent division by zero and calculate MB/s
if [[ ${elapsed_ms} -gt 0 ]]; then
    throughput=$(( (LOG_SIZE * 1000) / elapsed_ms / 1024 / 1024 ))
    _log "SUCCESS" "Processed ${LOG_SIZE} bytes in ${elapsed_ms} ms"
    _log "SUCCESS" "--> Measured Throughput: ${throughput} MB/s"

    # Assert minimum required throughput (e.g., must process >= 10 MB/s)
    min_required=10
    is_fast_enough="false"
    if [[ ${throughput} -ge ${min_required} ]]; then is_fast_enough="true"; fi
    verify_state "true" "${is_fast_enough}" "Throughput is >= ${min_required} MB/s"
else
    _log "WARN" "Execution was too fast to measure accurately (< 1ms)"
fi
