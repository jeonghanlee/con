# con - Automated Tests

Integration tests for the `con` console utility, focused on UNIX Domain Socket (UDS) client mode.

## Prerequisites

* `con` binary compiled in the repository root (`make`)
* **socat** (preferred) or **echo_server** (compiled automatically as fallback)

## Running Tests

```bash
# Execute all test suites with Global Summary
make test

# Execute individual suite for isolated verification
bash tests/test-uds-echo.bash
```

Note: `make test` returns a non-zero exit code upon any suite failure to support CI/CD pipelines.

## Test Suites

| Suite | Description |
|-------|-------------|
| `test-error-handling` | CLI argument validation and error paths |
| `test-version` | `-V` flag output and exit code (Under development) |
| `test-uds-connect` | UDS client connect and disconnect operations |
| `test-uds-echo` | Data round-trip integrity via echo server |
| `test-uds-exit` | Default and custom exit key triggers |
| `test-log-output` | `-l` and `-a` log file persistence |
| `test-color-filter` | `-n` ANSI escape sequence stripping |
| `test-throughput` | High-load stress test and processing throughput |

For system architecture and functional specifications, see [TEST_DETAILS.md](TEST_DETAILS.md).
