#!/usr/bin/env bash
#
# Validates standalone common.bash path resolution and binary rejection.

set -e

SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"
source "${SC_TOP}/common.bash"

function _handle_exit {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        TEST_TOTAL=$((TEST_TOTAL + 1))
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("Script exited before all assertions completed (exit ${exit_code})")
    fi
    cleanup_tmpdir
    print_summary "COMMON PATH TEST SUMMARY"
}
trap _handle_exit EXIT

setup_tmpdir

_log "INFO" "Common Helper Path Tests"
print_sub_divider

expected_con="$(realpath "${SC_TOP}/../con")"
fresh_status=0
fresh_output=$(
    env -u SC_TOP -u CON_BIN -u HELPERS_DIR -u ECHO_SERVER_MODE \
        bash --noprofile --norc -c '
            set -e
            cd "$1"
            source "$2"
            printf "%s\n" "$(realpath "$CON_BIN")"
            "$CON_BIN" -V
        ' _ "${TEST_TMPDIR}" "${SC_TOP}/common.bash"
) || fresh_status=$?

verify_exit_code "0" "${fresh_status}" "Fresh shell sources common.bash and executes con"

resolved_con="${fresh_output%%$'\n'*}"
verify_state "${expected_con}" "${resolved_con}" "Fresh shell resolves the repository con binary"

fresh_has_version="false"
if printf "%s" "${fresh_output}" | grep -q "version"; then
    fresh_has_version="true"
fi
verify_state "true" "${fresh_has_version}" "Resolved con executes the -V path"

invalid_con="${TEST_TMPDIR}/not-executable-con"
printf "%s\n" "#!/usr/bin/env bash" "exit 99" > "${invalid_con}"
chmod 600 "${invalid_con}"

invalid_status=0
invalid_output=$(
    env -u SC_TOP -u HELPERS_DIR -u ECHO_SERVER_MODE CON_BIN="${invalid_con}" \
        bash --noprofile --norc -c 'source "$1"' _ "${SC_TOP}/common.bash" 2>&1
) || invalid_status=$?

verify_exit_code "1" "${invalid_status}" "Non-executable CON_BIN fails while sourcing common.bash"

expected_error="Error: con binary is not executable: ${invalid_con}"
invalid_has_error="false"
if [[ "${invalid_output}" == *"${expected_error}"* ]]; then
    invalid_has_error="true"
fi
verify_state "true" "${invalid_has_error}" "Non-executable CON_BIN reports its resolved path"
