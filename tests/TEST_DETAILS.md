# con - Test Details

This document describes each test suite, its scenarios, and the technical approach used to drive `con` in an automated environment.


---

## Echo Server Backends

All UDS tests require an echo server that accepts a connection on a UNIX domain socket and reflects all received data back.

**socat** (preferred, auto-detected):
```bash
socat UNIX-LISTEN:/path/to/sock,fork EXEC:cat
```

**echo_server** (compiled C fallback, zero external dependencies):
```bash
tests/helpers/echo_server /path/to/sock
```

The test runner automatically selects the available backend.

---

## Test Suite Details

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

Validates basic UDS client connectivity. Starts an echo server, connects `con`, sends the exit character, and verifies clean disconnection.

| Scenario | Expected |
|----------|----------|
| Connect to valid UDS socket | Clean exit |
| Socket file exists during connection | Pass |

---

### test-uds-echo

Validates data integrity through a UDS round-trip. Sends a known string through `con` to the echo server and verifies the echoed output.

| Scenario | Expected |
|----------|----------|
| Single-line string echoed back | Output contains test string |
| Multi-line data echoed back | Output contains last line |

---

### test-uds-exit

Validates exit key behavior for both default and custom configurations.

| Scenario | Expected |
|----------|----------|
| Default `Ctrl-A` (0x01) triggers exit | Clean exit |
| Custom `Ctrl-B` via `-x ctrl/b` triggers exit | Clean exit |
| No exit key sent | Timeout (not crash) |

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

## Shared Utilities (`test-common.bash`)

| Function | Description |
|----------|-------------|
| `verify_state` | Assert expected vs actual string values |
| `verify_exit_code` | Assert expected vs actual exit codes |
| `setup_tmpdir` | Create isolated temp directory |
| `cleanup_tmpdir` | Remove temp directory and stop echo server |
| `start_echo_server` | Launch socat or echo_server on a UDS path |
| `stop_echo_server` | Kill background echo server process |
| `run_con` | Execute `con` with PTY-based input via `script(1)` and FIFO |
| `print_summary` | Print pass/fail assertion summary |
