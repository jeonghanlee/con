# con - Test Details

This document describes each test suite, its scenarios, and the technical approach used to drive `con` in an automated environment.


---

## Echo Server Backends

All UDS tests require an echo server that accepts a connection on a UNIX domain socket and reflects all received data back.

**socat**:
```bash
socat UNIX-LISTEN:/path/to/sock,fork EXEC:cat
```

**echo_server** (compiled C backend, zero external dependencies):
```bash
tests/helpers/echo_server /path/to/sock
```

The master runner preserves an explicit `ECHO_SERVER_MODE=socat` or
`ECHO_SERVER_MODE=echo_server` selection and rejects unavailable or unknown
values. It auto-detects only when the variable is unset, preferring `socat`
before the compiled backend. The `make test` target builds `echo_server` before
starting the runner.

---

## Master Runner and PTY Status Flow

`run-all-tests.bash` discovers regular files matching `tests/test-*.bash`,
sorts their paths in C-locale filename order, and executes each file once.
Display names are derived by removing the `test-` prefix and `.bash` suffix and
replacing hyphens with spaces. Files outside the naming rule are not suites.

`common.bash` drives `con` through a FIFO connected to the PTY allocated by
`script(1)`. The `script -e` status or the outer `timeout` status is captured
before feeder and FIFO cleanup, stored separately from `RUN_CON_OUTPUT`, and
returned after cleanup. Each suite status flows through the master runner to
the `make test` recipe.

When a caller does not provide `SC_TOP`, `common.bash` derives the test
directory from its own `BASH_SOURCE` path. It preserves a valid caller-provided
`CON_BIN`, supplies the repository binary as the default, and rejects a final
path that is not executable before test functions become available.

---

## Test Suite Details

### test-common-path

Validates shared-helper bootstrap behavior from a fresh shell whose working
directory is outside the repository.

| Scenario | Expected |
|----------|----------|
| Source `common.bash` without `SC_TOP` or `CON_BIN` | Resolve and execute the repository `con -V` path |
| Source `common.bash` with a non-executable `CON_BIN` | Return 1 and identify the rejected path |

---

### test-error-handling

Validates CLI argument parsing and error exit paths. Does not require a running echo server.

| Scenario | Expected |
|----------|----------|
| No arguments | Exit 1 |
| `-h` (help) | Exit 1 with usage |
| Invalid switch (`-z`) | Exit 1 |
| Connect to nonexistent UDS path | Exit 1 |
| Open nonexistent TTY device | Exit 1 |
| Mutually exclusive `-s` and `-c` | Exit 1 |
| Mutually exclusive `-t` and `-c` | Exit 1 |

---

### test-version

Validates the `-V` flag output format. Requires the version feature to be implemented in `con.cpp`.

| Scenario | Expected |
|----------|----------|
| `-V` output contains "version" | Pass |
| `-V` output contains "build" | Pass |
| `-V` exits with code 0 | Pass |

---

### test-uds-connect

Validates observable UDS client connectivity and failure status. It sends a
known payload through the real PTY path, verifies the echoed payload, and then
connects through the same path to an endpoint that does not exist.

| Scenario | Expected |
|----------|----------|
| Connect to valid UDS socket | Exit 0 |
| Send a known payload | Output contains the same payload |
| Connect to a missing UDS socket | Non-zero status survives PTY cleanup |
| Use a UDS path containing `:` | Client echo and server bind stay on UNIX transport |

---

### test-uds-echo

Validates data integrity through a UDS round-trip. Sends a known string through `con` to the echo server and verifies the echoed output.

| Scenario | Expected |
|----------|----------|
| Single-line string echoed back | Output contains test string |
| Multi-line data echoed back | Output contains last line |

---

### test-unix-flag

Validates `-u` and `--unix` through the shipped client and server paths, then verifies that serial, flagless UDS, and TCP classification remain compatible. The compiled `serial_pty` helper creates a real PTY pair and prefixes data returned through its master endpoint so the serial round trip is observable.

| Scenario | Expected |
|----------|----------|
| Connect with `-u -c` or `--unix -c` to a relative numeric-tail path | Real UDS echo succeeds |
| Start with `-u -s` on a relative numeric-tail path and connect with shipped con | UNIX socket node is created and peer data reaches the server PTY |
| Inspect help output | Both options are listed and the path removal warning precedes the server example |
| Connect without socket flags to the compiled PTY slave | Flagless serial path returns the helper marker |
| Connect with `-c` to an absolute UDS path | Existing UDS classification still echoes data |
| Exercise explicit TCP client and server targets | Client reaches `connect()` and server binds cleanly |
| Start a flagless `:0` target | Existing TCP server direction is unchanged |

---

### test-uds-exit

Validates exit key behavior for both default and custom configurations.

| Scenario | Expected |
|----------|----------|
| Default `Ctrl-A` (0x01) triggers exit | Clean exit |
| Custom `Ctrl-B` via `-x ctrl/b` triggers exit | Clean exit |
| No exit key sent | Timeout (not crash) |

---

### test-uds-readonly

Validates that `-r` (read-only) mode suppresses all keyboard input to the remote end while maintaining exit key functionality. Uses the echo server as a verification mechanism — in normal mode, typed input is echoed back; in readonly mode, it must not appear in the output.

| Scenario | Expected |
|----------|----------|
| Keyboard input not forwarded to echo server | Output does not contain test string |
| Exit key (`Ctrl-A`) still triggers clean exit | Clean exit without error |

---

### test-log-output

Validates the `-l` (overwrite) and `-a` (append) log file flags.

| Scenario | Expected |
|----------|----------|
| `-l` creates log file | File exists |
| Log file contains transmitted data | Grep matches test string |
| `-a` appends session header | File contains "New CON session" |

---

### test-color-filter

Validates that the `-n` flag strips ANSI escape sequences from log output while preserving plain text content.

| Scenario | Expected |
|----------|----------|
| Raw log (without `-n`) preserves `\033` sequences | Grep matches escape bytes |
| Filtered log (with `-n`) has no `\033` sequences | Grep does not match |
| Filtered log preserves plain text content | Grep matches "PLAIN_TEXT" |

Test data includes embedded ANSI color codes (`\033[0;31m` red, `\033[0m` reset) to simulate real IOC output with color-enabled EPICS shells.

---

### test-hexa-output

Validates the `-X` (hex bytes) and `-Y` (hex + ASCII) output modes. These modes use batch-buffered writes to minimize system call overhead.

| Scenario | Expected |
|----------|----------|
| `-X` with printable bytes | Output contains `0x41`, `0x42` |
| `-Y` with printable bytes | Output contains `0x41` and `[A]` |
| `-X` with non-printable byte (0xff) | Output contains `0xff` |
| `-Y` with non-printable byte | ASCII column shows `[.]` |


### test-throughput

Validates high-volume data processing and filtering efficiency.

| Scenario | Expected |
|----------|----------|
| 100,000 lines (approx. 10MB) IOC logs with ANSI colors | Log size < Original size (filtered) |
| Performance measurement | Throughput $\ge 10 \text{ MB/s}$ |
| High-speed UDS streaming | Process stability and log integrity |

---

### test-uds-peer-disconnect

Validates that `con` detects peer disconnection promptly without relying on a `read()` returning 0. Exercises the `POLLRDHUP` event path introduced with the `select()` to `poll()` migration.

| Scenario | Expected |
|----------|----------|
| Server sends data then closes socket | EOF detected, exits within 3s |
| Received data before disconnect | Output contains payload |
| EOF message reported | Output contains "EOF" |
| Abrupt peer kill (SIGKILL) | Exits without hanging (< 5s) |

### manual-test-diag-hotkey (Manual)

Validates the `Ctrl-T` diagnostic hotkey that reports receive buffer status with pause/resume. The diagnostic is automated in `test-uds-diag.bash` (issue #24) via a solitary `0x14` read (`buf_cnt == 1`); this interactive test remains for flood mode and visual inspection of the `[diag]` output.

```bash
bash tests/manual-test-diag-hotkey.bash          # echo mode
bash tests/manual-test-diag-hotkey.bash --flood   # flood mode
```

| Scenario | Expected |
|----------|----------|
| `Ctrl-T` in idle session | `con recv buffer: 0 / N bytes (0%) - NORMAL` |
| `Ctrl-T` during flood | `con recv buffer: N / M bytes (X%)` with pause |
| Any key after pause | Resumes data flow |
| `Ctrl-T` not forwarded | Remote does not receive `0x14` |
| `Ctrl-T` in readonly mode | Diagnostic output still works |

Buffer status levels:

| Level | Threshold | Action |
|-------|-----------|--------|
| NORMAL | < 50% | No action required |
| HIGH | 50-80% | Check remote for output flood, consider `con -r` |
| CRITICAL | > 80% | Remote output may block, disconnect or reduce output rate |


## Shared Utilities (`common.bash`)

| Function | Description |
|----------|-------------|
| `verify_state` | Assert expected vs actual string values |
| `verify_exit_code` | Assert expected vs actual exit codes |
| `setup_tmpdir` | Create isolated temp directory |
| `cleanup_tmpdir` | Remove temp directory and stop echo server |
| `start_echo_server` | Launch socat or echo_server on a UDS path |
| `stop_echo_server` | Kill background echo server process |
| `run_con` | Execute `con` through `script(1)` and FIFO, capture output, and return the real command or timeout status |
| `print_summary` | Print pass/fail assertion summary |
