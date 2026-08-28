# con - Automated Tests

Integration tests for the `con` console utility, focused on UNIX Domain Socket (UDS) client mode.

## Prerequisites

* `con` binary compiled in the repository root (`make`)
* `socat` or the compiled `tests/helpers/echo_server`

## Running Tests

```bash
# Execute all test suites with Global Summary
make test

# Execute the discovered suites with an explicit echo backend
ECHO_SERVER_MODE=socat bash tests/run-all-tests.bash
ECHO_SERVER_MODE=echo_server bash tests/run-all-tests.bash

# Execute individual suite for isolated verification
bash tests/test-uds-echo.bash
```

Note: `make test` returns a non-zero exit code upon any suite failure to support CI/CD pipelines.

The master runner executes every `tests/test-*.bash` file once in C-locale
filename order. `common.bash`, helper programs, manual tests, and release-gate
scripts are outside that naming rule and are not run as suites. When
`ECHO_SERVER_MODE` is unset, the runner selects `socat` first and then the
compiled `echo_server`; an explicit value is preserved and validated.

## Test Suites

| Suite | Description |
|-------|-------------|
| `test-color-filter` | `-n` ANSI escape sequence stripping |
| `test-common-path` | Standalone `common.bash` path resolution and non-executable binary rejection |
| `test-error-handling` | CLI argument validation and error paths |
| `test-hexa-output` | `-X` and `-Y` hex output format and data integrity |
| `test-log-output` | `-l` log file persistence |
| `test-throughput` | High-load stress test and processing throughput |
| `test-uds-connect` | Successful payload round trip and failed-connect status |
| `test-uds-diag` | Automated `Ctrl-T` diagnostic hotkey behavior |
| `test-uds-echo` | Data round-trip integrity via echo server |
| `test-uds-exit` | Default and custom exit key triggers |
| `test-uds-multi-client` | Concurrent client isolation and echo behavior |
| `test-uds-peer-disconnect` | Peer disconnect detection via `poll()`/`POLLRDHUP` |
| `test-uds-readonly` | `-r` read-only mode input suppression |
| `test-uds-sun-path-guard` | UNIX socket path length boundary and rejection behavior |
| `test-version` | `-V` flag output and exit code |

For system architecture and functional specifications, see [TEST_DETAILS.md](TEST_DETAILS.md).
