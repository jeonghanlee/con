# con

A lightweight console utility for serial devices, TCP sockets, and UNIX domain sockets. A minimal `minicom` replacement with zero UI overhead. For serial and TCP usage modes, see the original [README](README).

This document covers source build and installation, installed-path UDS verification, and UDS client features used for EPICS IOC console access via `procServ`.

## Build and Install

Install the source acquisition, build, and UDS verification prerequisites for the target system.

### Debian GNU/Linux 13

```bash
sudo apt-get update
sudo apt-get install --yes build-essential coreutils git util-linux
```

### Rocky Linux 8.10

```bash
sudo dnf install --assumeyes gcc-c++ make coreutils git util-linux
```

From the released source root, build and install the binaries:

```bash
make
sudo make install DESTDIR=/usr/local
/usr/local/bin/con -V
```

## Installed UDS Round Trip

Build the shipped AF_UNIX echo server and run the UDS integration test against the installed binary. This is the default installed-path check on Debian GNU/Linux 13 and Rocky Linux 8.10.

```bash
make -C tests/helpers clean all
CON_BIN=/usr/local/bin/con ECHO_SERVER_MODE=echo_server bash tests/test-uds-echo.bash
```

A successful run exits zero and reports `Echo server returned test string` as passed. The test creates and removes its temporary socket and stops the shipped echo server.

## UDS Client Connection

Connect to a `procServ` IOC console:

```bash
con -c /run/procserv/myioc/control
```

Quiet mode suppresses connection banners:

```bash
con -c /run/procserv/myioc/control -q
```

Detach with `Ctrl-A` (default exit key).

## Read-only Monitoring

Observe an IOC console without sending any keyboard input. Prevents accidental command injection when multiple operators share a console:

```bash
con -r -c /run/procserv/myioc/control
```

`Ctrl-A` exits. The exit key is always active in read-only mode.

## Diagnostic Hotkey (Ctrl-T)

Press `Ctrl-T` during an active session to pause incoming data and display receive buffer utilization:

```
[diag] con recv buffer: 49152 / 212992 bytes (23%) - NORMAL
[diag] paused -- press any key to resume
```

Press any key to resume. Buffer status levels:

| Level | Threshold | Action |
|-------|-----------|--------|
| NORMAL | < 50% | No action required |
| HIGH | 50-80% | Check remote for output flood, consider `con -r` |
| | | If EPICS IOC, check for device driver errors or crash-loop |
| CRITICAL | > 80% | Remote output may block, disconnect or reduce output rate |
| | | If EPICS IOC, restart IOC or check procServ crash-loop |

When logging is active (`-l` or `-a`), diagnostic output is also written to the log file.

## Custom Exit Key

The default exit key is `Ctrl-A` (`0x01`). To change it to `Ctrl-B`:

```bash
con -x ctrl/b -c /run/procserv/myioc/control
```

The `-x` argument accepts `ctrl/a`, `cntrl/a`, `control-a` forms, or raw integer values (`0x02`, `002`).

Accepted formats: `ctrl/a`, `cntrl/a`, `control-a`, or raw integer (`0x02`, `002`).

## Logging

Overwrite mode:

```bash
con -c /run/procserv/myioc/control -l session.log
```

Append mode with timestamped session header:

```bash
con -c /run/procserv/myioc/control -a session.log
```

Strip ANSI escape sequences from log output (for color-enabled EPICS shells):

```bash
con -c /run/procserv/myioc/control -n -l clean.log
```

## Hex Output Modes

Hex bytes:

```bash
con -X -c /run/procserv/myioc/control
```

Hex + ASCII (non-printable shown as `.`):

```bash
con -Y -c /run/procserv/myioc/control
```

## Switch Reference

| Switch | Description |
|--------|-------------|
| `-V`, `--version` | Print version, git hash, and build date |
| `-h` | Print help message |
| `-c` | Connect as UDS or TCP client |
| `-r` | Read-only mode |
| `-q` | Suppress connection banners |
| `-l FILE` | Log to file (overwrite) |
| `-a FILE` | Append to log file with session header |
| `-n` | Strip ANSI escape sequences from log |
| `-X` | Hex byte output |
| `-Y` | Hex + ASCII output |
| `-x KEY` | Custom exit key (default: `Ctrl-A`) |
| `-e` | Echo keyboard input locally |
| `Ctrl-T` | Diagnostic: pause and display buffer status |
| `Ctrl-A` | Exit session (default, configurable with `-x`) |

## Testing

```bash
make test
```

The Ctrl-T diagnostic hotkey is covered by `make test`
(`tests/test-uds-diag.bash`). The interactive test below is for flood mode and
visual inspection of the `[diag]` output:

```bash
bash tests/manual-test-diag-hotkey.bash          # echo mode
bash tests/manual-test-diag-hotkey.bash --flood   # flood mode
```

Test specifications: [tests/README.md](tests/README.md) and [tests/TEST_DETAILS.md](tests/TEST_DETAILS.md).

## Cross-compilation Example (BLM)

`/srv/librablmOpt` is the NFS folder where the BLM can access as `PATH`.

```bash
source ../deviceconf/BLM/setEnvBLMCC.bash
make clean
make
sudo make install DESTDIR=/srv/liberablmOpt
```
