# Work Register

## Scope

This document is the canonical work register for the con 1.2.0 release line. It owns release scope, order, accepted plans, verification plans, status, Backlog, and observed GitHub metadata.

Out of scope: implementation without explicit authorization, Git or GitHub mutation without the matching authority, and work held by a Closed Door decision.

Release line: 1.2.0
Milestone index: 1.2.0
Canonical path: `docs/milestone-1.2.0.md`
Canonical branch or ref: `release-1.2.0`
Git upstream: `origin/release-1.2.0`
Remote tracker: `github.com/jeonghanlee/con`, GitHub milestone `1.2.0` (#4)
Default development verification host: `top`, Debian GNU/Linux 13.6, x86_64, repository binary `/data/gitsrc/con/con`

Next session entry point: prepare the reviewed M4 commit, obtain separate commit and push authority, then reconcile and close issue #22 with issue authority.

Milestone tally: milestones Not started 0, In progress 1, Blocked 1, Complete 3; external gates Open 1, Complete 0; Ready milestones 0.

Tracker reconciliation observed 2026-08-28T09:17:22Z: GitHub milestone `1.2.0` is open with one open issue and three closed issues. Issue #16 is open in GitHub `Backlog` with labels `P3-low` and `refactor`. Issue #20 is closed in `1.2.0` with state reason `completed`; issue #22 remains open in `1.2.0`; issues #23 and #25 are closed. Their titles, labels, milestone assignments, assignees, and live states match the canonical details; issues #20, #23, and #25 record checked completion criteria and closure evidence.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| External | G1 | Confirm epics-ioc-runner 1.2.4 with released con 1.1.0 | External gate | Open | No | D4, D11 | Released con 1.1.0 passes the epics-ioc-runner 1.2.4 gate on both pinned goldens; [detail](#g1---confirm-epics-ioc-runner-124-with-released-con-110) |
| Test integrity | M1 | Restore real test outcomes and auto-discovery (#23) | Milestone | Complete | No | D4, D5 | Real connection failures remain nonzero, valid UDS echo passes under each selected backend, every `test-*.bash` suite is discovered, and `make test` returns the runner status; [detail](#m1---restore-real-test-outcomes-and-auto-discovery-23) |
| Test integrity | M2 | Make common test setup safe when sourced standalone (#25) | Milestone | Complete | No | M1, D6 | A fresh shell resolves the real binary or fails clearly, and both suite backends pass; [detail](#m2---make-common-test-setup-safe-when-sourced-standalone-25) |
| UDS client | M3 | Add an explicit UNIX transport flag (#20) | Milestone | Complete | No | M2, D7 | `-u` and `--unix` force AF_UNIX for client and server targets without changing flagless behavior; [detail](#m3---add-an-explicit-unix-transport-flag-20) |
| UDS client | M4 | Reach colonless UDS paths through explicit UNIX mode (#22) | Milestone | In progress | No | M3, D7 | A colonless socket works through `-u` and serial auto-detection remains unchanged; [detail](#m4---reach-colonless-uds-paths-through-explicit-unix-mode-22) |
| Release | M5 | Release con 1.2.0 | Milestone | Blocked | No | G1, M1, M2, M3, M4, D8 | Every Release Verification result passes and every separately authorized release action has immutable evidence; [detail](#m5---release-con-120) |

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | Keep UDS server work outside the active client-focused release line. | 2026-08-13 |
| D2 | Keep UDS server-only, TCP server, and TCP client issues in Closed Door; keep generic issues unassigned in Backlog. | 2026-08-13 |
| D3 | Keep issue #16 implementation unchanged, exclude it from active 1.2.0 work, and move the open GitHub issue to `Backlog` with its existing labels. | 2026-08-26 |
| D4 | Open 1.2.0 in the order M1, M2, M3, M4, M5, with G1 independent but blocking M5. | 2026-08-26 |
| D5 | Implement actual sorted `test-*.bash` auto-discovery; rename the shared helper to `tests/common.bash` so the naming rule has no exception; preserve an explicitly selected echo backend before auto-detection. | 2026-08-26 |
| D6 | Derive standalone test paths from `BASH_SOURCE` and reject a resolved `CON_BIN` that is not executable. | 2026-08-26 |
| D7 | Make `-u` and `--unix` purely additive, use them for colonless UDS paths, and preserve all flagless transport and direction behavior. | 2026-08-26 |
| D8 | Replace the prior canonical and separate 1.1.0 test plan with this version-qualified register, carry all surviving Backlog work, and keep the active cycle test plan inside M5. | 2026-08-26 |
| D9 | Preserve each Accepted ADR body unchanged and append a correction note that pins historical milestone references to the prior-state commit. | 2026-08-26 |
| D10 | Run the post-release source build and `/usr/local/bin/con` install path on both clean Debian 13 x86_64 and Rocky Linux 8.10 x86_64 hosts, using the shipped `echo_server` path as the documented default UDS check. | 2026-08-26 |
| D11 | Keep G1 limited to the released-con two-golden run; place local downstream driver reconciliation and runner identity update in M5. | 2026-08-27 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| GitHub issue #23 | 1.1.0 `docs/milestone.md` Backlog at `2fb9b8b1a90c45e75a9c46b57c61e7fd9ddacf75` | 1.2.0 `docs/milestone-1.2.0.md` M1 | this synchronization commit | this synchronization commit |
| GitHub issue #25 | 1.1.0 `docs/milestone.md` Backlog at `2fb9b8b1a90c45e75a9c46b57c61e7fd9ddacf75` | 1.2.0 `docs/milestone-1.2.0.md` M2 | this synchronization commit | this synchronization commit |
| GitHub issue #20 | 1.1.0 `docs/milestone.md` Backlog at `2fb9b8b1a90c45e75a9c46b57c61e7fd9ddacf75` | 1.2.0 `docs/milestone-1.2.0.md` M3 | this synchronization commit | this synchronization commit |
| GitHub issue #22 | 1.1.0 `docs/milestone.md` Backlog at `2fb9b8b1a90c45e75a9c46b57c61e7fd9ddacf75` | 1.2.0 `docs/milestone-1.2.0.md` M4 | this synchronization commit | this synchronization commit |

### Milestone Details

#### G1 - Confirm epics-ioc-runner 1.2.4 with released con 1.1.0

Origin: 1.2.0 / G1
GitHub Issue: none
Status: Open

##### Summary

The release operator must confirm that released con 1.1.0 passes the epics-ioc-runner 1.2.4 gate on both pinned goldens before M5 can run. M5 owns the local downstream driver reconciliation and runner identity update.

##### Completion Criteria

- Run the current epics-ioc-runner 1.2.4 gate at commit `1961fbffbb1c650999b62d562f05363152c6a9cd` with released con 1.1.0 on Rocky Linux 8.10 and Debian 13 production-equivalent goldens.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-08-26T17:12:37Z | Pending | Upstream release 1.2.4 is published at tag commit `1961fbffbb1c650999b62d562f05363152c6a9cd`; the required released-con run was not performed in this session. |

##### Closure Evidence

- None.

#### M1 - Restore real test outcomes and auto-discovery (#23)

Origin: 1.2.0 / M1
Identity History: none
GitHub Issue: [#23](https://github.com/jeonghanlee/con/issues/23)
Status: Complete

##### Summary

Repair the test harness so `run_con` preserves the real PTY command status, the UDS connect suite proves an actual round trip, the master runner discovers every suite from one naming rule, each echo backend can be selected explicitly, and `make test` returns the runner's result.

##### Scope

Rename `tests/test-common.bash` to `tests/common.bash`, update every source site, preserve the status from the real `script(1)` and timeout path through cleanup, replace the vacuous connect assertion with observable UDS behavior, discover the sorted `tests/test-*.bash` set without a registration list, preserve and validate an explicit `ECHO_SERVER_MODE`, and make the GNUmakefile `test` recipe propagate runner failure.

Out of scope: changing con transport behavior, changing the released issue #4 fix, or running manual and release-gate scripts as unit suites.

##### Completion Criteria

- A missing or misrouted UDS endpoint produces a nonzero status through the real con and PTY path.
- A valid UDS echo round trip passes through the shipped con binary and shipped echo-server fixture.
- `tests/run-all-tests.bash` executes every sorted `tests/test-*.bash` file and does not treat helper, manual, or release-gate scripts as suites.
- `ECHO_SERVER_MODE=socat` and `ECHO_SERVER_MODE=echo_server` each select exactly the requested available backend; auto-detection runs only when the variable is unset.
- `make test` returns nonzero when the real runner fails and zero only when every discovered suite passes.
- T1 through T4 pass and issue #23 has closure evidence.

##### Dependencies And Decisions

- D4 sets M1 first so later test and CLI work uses truthful evidence.
- D5 selects the helper rename, actual auto-discovery, and explicit echo-backend selection.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner approval and accepted third-person review findings in this conversation on 2026-08-26
Implementation Authorization: owner approval in conversation on 2026-08-27
Superseded Plan Artifacts: none

1. Rename the shared helper to `tests/common.bash` and update all source sites without changing helper behavior yet.
2. Capture and return the real PTY command status from `run_con`; ensure cleanup cannot replace that status.
3. Replace the connect status check with a real payload round trip and a real failed-connect assertion.
4. Replace the hardcoded runner list with deterministic filename discovery and derive suite display names from filenames.
5. Preserve a valid caller-selected `ECHO_SERVER_MODE`, reject an unavailable or unknown selection, and auto-detect only when no mode is supplied.
6. Remove the GNUmakefile recipe error-ignore prefix so `make test` returns the real runner status.
7. Update test architecture and verified-behavior documentation to match the shipped runner.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Functional negative | Invoke shipped con through the real `script(1)` PTY helper against a missing UDS endpoint and inspect the returned status. | Linux dev host | The connection fails and `run_con` returns nonzero; cleanup does not mask the status. |
| T2 | Functional integration | Select `socat`, then select the compiled `echo_server`; for each mode, start the shipped fixture, connect with shipped con through the PTY helper, send a unique payload, and assert the echoed payload. | Linux dev host with both backends available | The exact payload returns under each explicitly reported backend and each run exits zero. |
| T3 | Runner integration | Run `tests/run-all-tests.bash` and compare its executed suite names and order with the current sorted `tests/test-*.bash` files. | Linux dev host | Every currently shipped suite runs once in deterministic order; helper, manual, and release-gate scripts do not run as suites. |
| T4 | GNUmake integration | Run the real `make test` path with `CON_TIMEOUT=0.1` so a shipped PTY case with a one-second input delay reaches the real timeout boundary, then run the normal complete suite. | Linux dev host | The forced real-path timeout makes `make test` nonzero; the complete passing run returns zero. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-27T18:08:29Z | `top`; Debian GNU/Linux 13.6; x86_64; repository `con` | Pass | The real `script(1)` PTY path against a missing UDS endpoint produced a nonzero `run_con` status under both explicit backends; each `test-uds-connect.bash` run returned 0 after the negative assertion passed. |
| T2 | 2026-08-27T18:08:29Z | `top`; Debian GNU/Linux 13.6; x86_64; repository `con`; `socat` and compiled `tests/helpers/echo_server` | Pass | Fresh explicit `socat` and `echo_server` runs each completed the real payload round trip and exited 0; complete runner runs reported the requested backend and passed 14 of 14 suites. |
| T3 | 2026-08-27T18:02:35Z | `top`; Debian GNU/Linux 13.6; x86_64 | Pass | A filename-derived expected list compared byte-for-byte with the runner's executed display-name order with `diff` status 0; all 14 `test-*.bash` files ran once and non-suite files were absent. |
| T4 | 2026-08-27T18:05:57Z | `top`; Debian GNU/Linux 13.6; x86_64; GNU Make | Pass | `CON_TIMEOUT=0.1 make test` exercised the real PTY timeout path, reported 8 failed suites, and ended with the recipe's `Error 1`; normal `make test` then exited 0 with 14 of 14 suites passed. |

##### Closure Evidence

- 2026-08-27: first-person retrospective, independent third-person review, and second-person reader-seat review passed with no accepted findings outstanding.
- 2026-08-27T19:58:54Z: issue #23 was observed closed with labels `bug` and `P2-medium`, milestone `1.2.0`, assignee `jeonghanlee`, the checked completion criteria, and the closure comment for commit `520e6917c2329ba02aa40c69a7ec1728d2b07934`.
- 2026-08-27T20:01:48Z: after `git fetch`, `HEAD` and `origin/release-1.2.0` both resolved to commit `520e6917c2329ba02aa40c69a7ec1728d2b07934`; the landed commit contains the reviewed GNUmakefile, test harness, suite, and documentation changes.

##### GitHub Projection

Title: test-uds-connect assertion is vacuous; runner is a hardcoded list
Labels: `bug`, `P2-medium`
GitHub Milestone: `1.2.0`
Observed State: closed
Observed Labels: `bug`, `P2-medium`
Observed Milestone: `1.2.0`
Last Compared: 2026-08-27T20:01:48Z; issue updated 2026-08-27T19:58:54Z

#### M2 - Make common test setup safe when sourced standalone (#25)

Origin: 1.2.0 / M2
Identity History: none
GitHub Issue: [#25](https://github.com/jeonghanlee/con/issues/25)
Status: Complete

##### Summary

Make the renamed shared test helper derive its own repository location when callers do not supply `SC_TOP`, and fail clearly when its resolved `CON_BIN` is not executable.

##### Scope

Use `BASH_SOURCE` as the standalone location source, preserve a valid caller-supplied `CON_BIN`, add an executable guard, add an automatically discovered regression suite, and update test documentation.

Out of scope: changes to `con.cpp` or the issue #24 diagnostic behavior.

##### Completion Criteria

- Sourcing `tests/common.bash` from a fresh shell outside the repository resolves the built repository `con` binary.
- A missing or non-executable resolved binary causes an immediate, clear nonzero failure.
- The new regression suite is discovered automatically and the full suite passes under both echo backends.

##### Dependencies And Decisions

- M1 supplies the renamed helper, truthful status path, and auto-discovery rule.
- D6 selects both the `BASH_SOURCE` fallback and executable guard.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner approval and accepted third-person review findings in this conversation on 2026-08-26
Implementation Authorization: owner approval in conversation on 2026-08-27
Superseded Plan Artifacts: none

1. Derive `SC_TOP` from `BASH_SOURCE[0]` only when it is absent, then resolve the default `CON_BIN` from that directory.
2. Validate the final `CON_BIN` as executable and return a clear error before any test command runs.
3. Add `tests/test-common-path.bash` to exercise fresh-shell success and invalid-binary failure through the real helper.
4. Run the full discovered suite once with `ECHO_SERVER_MODE=socat` and once with `ECHO_SERVER_MODE=echo_server`, confirming that each run reports the requested backend.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Functional | Start a fresh shell outside `tests/`, unset `SC_TOP` and `CON_BIN`, source the shipped helper, and execute the resolved built con `-V` path. | Linux dev host | `CON_BIN` is the repository binary and the real binary executes. |
| T2 | Functional negative | Start a fresh shell with `CON_BIN` set to a non-executable outer-boundary path and source the shipped helper. | Linux dev host | The helper prints a clear error and returns nonzero before a con invocation. |
| T3 | Regression | Run the complete discovered suite with `ECHO_SERVER_MODE=socat`, then with `ECHO_SERVER_MODE=echo_server`. | Linux dev host with both backends available | Every suite, including `test-common-path.bash`, passes and each run reports the requested backend. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-27T20:25:58Z | `top`; Debian GNU/Linux 13.6; x86_64; Bash 5.2.37; repository `con` | Pass | From a temporary directory outside the repository, a fresh `bash --noprofile --norc` process sourced the real `tests/common.bash` with `SC_TOP`, `CON_BIN`, and helper variables unset, resolved `/data/gitsrc/con/con`, executed its `-V` path, and exited 0. |
| T2 | 2026-08-27T20:25:58Z | `top`; Debian GNU/Linux 13.6; x86_64; Bash 5.2.37; repository `tests/common.bash` | Pass | The real helper was sourced with `CON_BIN` set to a mode-0600 temporary file; sourcing returned 1 and identified the rejected path as not executable. The complete `test-common-path.bash` suite passed 5 of 5 assertions. |
| T3 | 2026-08-27T20:25:58Z | `top`; Debian GNU/Linux 13.6; x86_64; repository `con`; `socat` and compiled `tests/helpers/echo_server` | Pass | Explicit `ECHO_SERVER_MODE=socat` and `ECHO_SERVER_MODE=echo_server` runs each reported the requested backend, executed all 15 discovered suites including `test-common-path.bash`, passed 15 of 15 suites, and exited 0. |

##### Closure Evidence

- 2026-08-27: first-person retrospective, independent third-person review, and second-person reader-seat review passed with no accepted findings outstanding.
- 2026-08-28T01:45:16Z: issue #25 was observed closed with labels `bug` and `P3-low`, milestone `1.2.0`, assignee `jeonghanlee`, checked completion criteria, and the closure comment for commit `6becf23f795efcced3f49807c816b9b85fc00d2b`.
- 2026-08-28T01:55:29Z: after `git fetch`, `HEAD` and `origin/release-1.2.0` both resolved to commit `6becf23f795efcced3f49807c816b9b85fc00d2b`; the landed commit contains the reviewed helper, regression suite, test documentation, and milestone evidence.

##### GitHub Projection

Title: test-common.bash resolves CON_BIN to /../con when sourced standalone (SC_TOP unset)
Labels: `bug`, `P3-low`
GitHub Milestone: `1.2.0`
Observed State: closed
Observed Labels: `bug`, `P3-low`
Observed Milestone: `1.2.0`
Last Compared: 2026-08-28T01:55:40Z; issue updated 2026-08-28T01:45:16Z

#### M3 - Add an explicit UNIX transport flag (#20)

Origin: 1.2.0 / M3
Identity History: none
GitHub Issue: [#20](https://github.com/jeonghanlee/con/issues/20)
Status: Complete

##### Summary

Add `-u` and `--unix` as an explicit additive override that forces `AF_UNIX` for both client and server target selection, regardless of colons in the target.

##### Scope

Add both option forms, carry one explicit UNIX-mode state through option parsing, bypass the colon heuristic at the client and server transport splits, add a compiled PTY-pair serial fixture independent of the echo backend, and document the override in help and README switch references.

Out of scope: changing flagless transport detection, changing flagless client/server direction, or implementing issue #21.

##### Completion Criteria

- `-u` and `--unix` force UDS client and server behavior for paths with numeric-looking colon suffixes.
- Help and README describe the flag and the unchanged flagless behavior.
- A compiled helper supplies a real PTY slave target and observable master-side data path for serial regression without requiring `socat`.
- Serial, flagless UDS/TCP, and explicit `-c`/`-s` behavior remain compatible through real shipped paths.

##### Dependencies And Decisions

- M2 completes the test-harness foundation before CLI behavior changes.
- D7 requires an additive override and preserves flagless behavior.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner approval and accepted third-person review findings in this conversation on 2026-08-26
Implementation Authorization: owner approval in conversation on 2026-08-28
Superseded Plan Artifacts: none

1. Add short and long option parsing for one explicit UNIX-mode flag and update help output.
2. Route client and server targets to the existing AF_UNIX branches when the flag is set, without changing the heuristic when it is absent.
3. Add real client and server UDS cases using target names that the flagless heuristic would classify differently.
4. Add a compiled `tests/helpers/serial_pty` fixture that reports its PTY slave path, keeps the master endpoint active, and exposes an observable data exchange for the flagless serial test.
5. Update README functional specifications and run CLI, UDS, serial, and TCP regressions.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Functional integration | Start the shipped UDS echo fixture at a path such as `cache:6379`, invoke shipped con with `-u -c`, send a unique payload, and inspect the echo. | Linux dev host | con uses AF_UNIX and returns the exact payload. |
| T2 | Functional integration | Start shipped con in server mode with `-u -s` on a colon-bearing numeric-tail path, inspect the created socket node, and connect through a real peer. | Linux dev host | A UNIX socket node is created and the peer exchanges data. |
| T3 | CLI and regression | Exercise `-u`, `--unix`, help output, the compiled PTY-pair serial target, flagless targets, and explicit TCP client/server paths through shipped binaries. | Linux dev host | New options are documented and accepted; the real PTY slave stays on the serial path, and existing socket paths retain their prior transport and direction. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-28T09:00:51Z | `top`; Debian GNU/Linux 13; x86_64; repository `con`; compiled `echo_server` | Pass | Fresh `-u -c` and `--unix -c` runs against the relative numeric-tail path `cache:6379` each used the shipped AF_UNIX client path, returned its exact marker through the real echo server, and exited 0. |
| T2 | 2026-08-28T09:00:51Z | `top`; Debian GNU/Linux 13; x86_64; repository `con` as server and peer | Pass | `-u -s listen:6380` created a UNIX socket node; a second shipped con process connected with `-u -c`, and the server PTY received the exact peer marker. Both processes exited 0. |
| T3 | 2026-08-28T09:02:22Z | `top`; Debian GNU/Linux 13; x86_64; Bash 5.2.37; repository `con`; `socat`, compiled `echo_server`, and compiled `serial_pty` | Pass | `test-unix-flag.bash` passed 18 of 18 assertions through the real CLI, UDS, PTY serial, and TCP paths, including the requirement that the server path-removal warning precedes the server example in help. Explicit `socat` and `echo_server` full runs each reported the selected backend, discovered and passed 16 of 16 suites, and exited 0. |

##### Closure Evidence

- 2026-08-28: first-person retrospective and independent third-person review passed. The review cycle found that the new server example did not present the existing-target removal warning before the command; after the owner accepted the finding, help and README were corrected, the complete M3 verification was repeated, and the final second-person review passed with no remaining finding.

##### GitHub Projection

Title: Add explicit -u/--unix flag to force UNIX socket transport
Labels: `enhancement`, `P3-low`, `area/uds`
GitHub Milestone: `1.2.0`
Observed State: closed
Observed Labels: `enhancement`, `P3-low`, `area/uds`
Observed Milestone: `1.2.0`
Last Compared: 2026-08-28T09:17:22Z; issue updated 2026-08-28T09:17:22Z; state reason `completed`

#### M4 - Reach colonless UDS paths through explicit UNIX mode (#22)

Origin: 1.2.0 / M4
Identity History: none
GitHub Issue: [#22](https://github.com/jeonghanlee/con/issues/22)
Status: In progress

##### Summary

Close the colonless UDS usability gap through the explicit UNIX mode from M3. Do not infer socket transport from slash shape or filesystem state.

##### Scope

Add a permanent real-path case for `con -u -c /tmp/foo.sock`, document explicit UNIX selection for colonless paths, and reuse M3's compiled PTY-pair fixture to preserve flagless serial auto-detection.

Out of scope: path-shape detection, `stat()`-based auto-detection, and any flagless behavior change.

##### Completion Criteria

- A colonless UDS path completes a real echo round trip with `-u`.
- The shipped compiled PTY-pair fixture completes an observable serial exchange when `-u` is absent.
- T1 through T3 pass on the combined M3 and M4 tree.

##### Dependencies And Decisions

- M3 provides the explicit UNIX mode.
- D7 rules out path-shape, `stat()` heuristics, and flagless changes for this release.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner approval and accepted third-person review findings in this conversation on 2026-08-26
Implementation Authorization: owner approval in conversation on 2026-08-28
Superseded Plan Artifacts: none

1. Add a dedicated colonless UDS round-trip case using M3's explicit UNIX option.
2. Reuse M3's compiled PTY-pair fixture in a serial-path regression that proves the absence of `-u` preserves serial selection and real data exchange.
3. Update user-facing UDS connection documentation with the colonless form.
4. Run the combined UDS and full-suite checks with each backend selected explicitly.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Functional integration | Start the shipped UDS echo fixture on a colonless pathname, invoke shipped con with `-u -c`, send a unique payload, and inspect the echo. | Linux dev host | The exact payload returns over AF_UNIX. |
| T2 | Functional regression | Start the shipped compiled serial fixture, read its PTY slave path, invoke shipped con without `-u`, and exchange a unique payload through the real PTY master and slave. | Linux dev host | The exact payload crosses the serial path and no AF_UNIX endpoint is created or contacted. |
| T3 | Regression | Run the complete discovered suite with `ECHO_SERVER_MODE=socat`, then with `ECHO_SERVER_MODE=echo_server`. | Linux dev host with both backends available | All suites pass and each run reports the requested backend. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-28T16:53:36Z | `top`; Debian GNU/Linux 13; x86_64; repository `con`; `socat` and compiled `echo_server` | Pass | Fresh explicit `socat` and `echo_server` runs each used `-u -c` with the relative colonless path `colonless.sock`, returned the exact `UNIX_COLONLESS_CLIENT_OK` marker through the real AF_UNIX echo path, passed 20 of 20 suite assertions, and exited 0. |
| T2 | 2026-08-28T16:53:36Z | `top`; Debian GNU/Linux 13; x86_64; repository `con`; compiled `serial_pty` | Pass | Both explicit-backend runs invoked shipped con without `-u` against the real PTY slave, returned `SERIAL_PTY_ECHO:FLAGLESS_SERIAL_OK` through the PTY master, passed the serial assertions, and exited 0. |
| T3 | 2026-08-28T16:53:36Z | `top`; Debian GNU/Linux 13; x86_64; repository `con`; `socat`, compiled `echo_server`, and compiled `serial_pty` | Pass | Fresh complete runs explicitly selected `socat` and `echo_server`; each discovered and passed 16 of 16 suites, including the 20-of-20 `test-unix-flag.bash` suite, and exited 0. |

##### Closure Evidence

- 2026-08-28T16:53:36Z: the authorized local implementation matches the accepted M4 scope; `bash -n tests/test-unix-flag.bash` and `git diff --check` passed.
- 2026-08-28T17:16:14Z: independent third-person review passed with no implementation finding. The owner accepted the second-person finding that the next entry point and review state were stale, and this update corrects both. Commit landing and issue #22 closure remain pending.

##### GitHub Projection

Title: Colonless UDS socket path auto-detects as a serial tty
Labels: `enhancement`, `P3-low`, `area/uds`
GitHub Milestone: `1.2.0`
Observed State: open
Observed Labels: `enhancement`, `P3-low`, `area/uds`
Observed Milestone: `1.2.0`
Last Compared: 2026-08-27T17:37:04Z; issue updated 2026-08-27T17:15:33Z

#### M5 - Release con 1.2.0

Origin: 1.2.0 / M5
Identity History: none
GitHub Issue: none
Status: Blocked

##### Summary

Integrate M1 through M4, complete `docs/release-gate.md`, verify the final candidate through every supported real path, change the version, execute the separately authorized release sequence, and verify the released objects, both default post-release install environments, and next release-line state.

##### Scope

Own final-tree invalidation reruns, both explicitly selected echo backends, diagnostic and bounded-flood behavior, local downstream driver reconciliation and runner identity update, downstream production-equivalent tests, version consistency, release actions, GitHub milestone closure, and clean Debian 13 and Rocky Linux 8.10 post-release installations at `/usr/local/bin/con`.

Out of scope: Backlog work, implementation excluded by D1 through D3, and any execution action lacking its own `git-workflow` authority.

##### Completion Criteria

- G1 and M1 through M4 are Complete.
- `tests/release-gate4-downstream.bash` matches the epics-ioc-runner 1.2.4 runbook and drivers and enforces the 1.2.4 runner identity before Release Verification 14 and 15.
- Release Verification 1 through Release Verification 23 are Pass with reachable evidence.
- Every Release Execution row has separate authority and immutable evidence.
- GitHub milestone `1.2.0` closes only in phase 12 after linked issues are reconciled and Release Verification 1 through 21 and 23 are Pass; Release Verification 22 immediately confirms the observed closure.

##### Dependencies And Decisions

- G1, M1, M2, M3, and M4 must be Complete.
- D11 assigns the released-con two-golden run to G1 and the local driver and runner identity changes to M5.
- D8 places the complete active cycle test plan here instead of a separate file.
- D10 selects both clean Linux install environments as the default post-release path.
- `docs/release-gate.md` is the standing five-step gate definition; this cycle records no amendment to its shape.
- Resume as Not started after G1 is Complete; implementation and release execution still require separate authority.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner approval in this conversation on 2026-08-27, retaining accepted third-person review findings from 2026-08-26
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Execute gate step 1 by re-running every mapped M1 through M4 check on the final combined candidate.
2. Execute gate steps 2 and 3 with both explicitly selected full-suite backends, automated diagnostic coverage, and the bounded flood check.
3. Complete G1, reconcile `tests/release-gate4-downstream.bash` with the epics-ioc-runner 1.2.4 runbook and drivers, update the enforced runner identity, then execute gate step 4 with the release candidate on both pinned goldens.
4. Begin gate step 5 by verifying the current version, obtaining authority for the version mutation, and verifying the resulting binary.
5. Complete gate step 5 by obtaining the exact authority for each release action, executing it, and capturing immutable evidence.
6. Execute phase 10 with an explicit canonical checkpoint commit after every irreversible action and use explicit object targets for every dependent action.
7. On each phase 11 host, install the documented source-acquisition, build, and UDS verification prerequisites, then complete the Released-Object Storage Preflight before creating any fresh clone or temporary verification tree.
8. Obtain the released source through the completed preflight, perform the post-release source installations on both default hosts, verify release objects and next-line state, then complete phase 12 issue reconciliation, milestone closure, Release Verification 22, and canonical closure.

##### Test Plan

The final release uses only the Release Verification plan below; it has no local T labels. The standing gate is `docs/release-gate.md`, all five steps apply, and this cycle has no gate-shape amendment.

##### Verification Results

The final release uses only the Release Verification results below.

##### Closure Evidence

- None.

##### GitHub Projection

Title: Release con 1.2.0
Labels: none
GitHub Milestone: `1.2.0`
Observed State: none
Observed Labels: none
Observed Milestone: open, four open issues and zero closed issues
Last Compared: 2026-08-27T17:37:04Z; milestone updated 2026-08-27T17:15:32Z

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M1 / T1 | M2 changes the shared helper | PTY status and helper cleanup | Release Verification 1 | A real failed UDS connection remains nonzero. | pending |
| M1 / T2 | M3 and M4 change transport selection | UDS client connection and echo | Release Verification 2 | The real UDS echo payload returns. | pending |
| M1 / T3 | M2 adds a new suite | Runner discovery convention | Release Verification 3 | The new suite runs without a registration edit. | pending |
| M2 / T1 | Final combined candidate | Helper path and built binary | Release Verification 4 | Fresh-shell sourcing resolves and executes the real binary. | pending |
| M2 / T2 | Final combined candidate | Helper executable guard | Release Verification 5 | An invalid binary path fails clearly and nonzero. | pending |
| M2 / T3 | M3 and M4 change con and add tests | Complete suite | Release Verification 11 and Release Verification 12 | Both supported backends pass. | pending |
| M3 / T1 | M4 adds the colonless explicit-mode use | UNIX client option and transport split | Release Verification 6 | A colon-bearing numeric-tail path uses AF_UNIX and echoes. | pending |
| M3 / T2 | M4 shares explicit UNIX mode | UNIX server option and transport split | Release Verification 7 | Explicit UNIX server mode creates a socket and exchanges data. | pending |
| M3 / T3 | M4 adds documentation and regression cases | CLI parsing and legacy transport selection | Release Verification 8 | New options work, the compiled PTY serial path passes, and legacy socket modes remain unchanged. | pending |
| M4 / T1 | Final combined candidate | Colonless UDS explicit mode | Release Verification 9 | The colonless UDS echo round trip passes. | pending |
| M4 / T2 | Final combined candidate | Serial versus socket selection | Release Verification 10 | The shipped PTY slave completes a flagless serial exchange. | pending |
| M4 / T3 | Final combined candidate | Complete suite | Release Verification 11 and Release Verification 12 | Both supported backends pass. | pending |

##### Released-Object Storage Preflight

Before any phase 11 fresh clone or temporary verification tree, including Release Verification 18 and 19:

1. Record the exact target filesystem, an absent destination path, clone mode, complete refspec set, and canonical remote. Use a shallow clone only when the owner selects it. Before cloning, compare the canonical remote's advertised release and tag refs with the accepted immutable identifiers and include every required object in the refspec set.
2. Record the object-database bound and its provenance for the selected remote, clone mode, and refspec set. Treat a local source measurement as valid only when its shallow and partial-clone state and its remote refs match that selection; stop when the object-database bound or its provenance is absent. Record the clean published working-tree allocation without its object database and conservative workspace and evidence bounds using filesystem-allocated bytes; use the last matching verification run or record a conservative bound when none exists.
3. Require available space before object creation to be at least the object-database bound plus `1073741824` bytes. Create and fetch only the object database, verify the release commit and annotated tag object types and identifiers, and record actual allocated size.
4. Require the remaining available space before checkout to be at least the published working-tree allocation plus the workspace and evidence bounds plus `1073741824` bytes. Checkout only after this second gate passes.
5. On a failed gate, stop and present cleanup, another filesystem, and an applicable clone mode as separate choices. Re-run the first gate after a Gate 1 failure. After a Gate 2 failure, retain the unchanged object database and re-run only Gate 2. Use a new absent destination and restart at Gate 1 when the filesystem, clone mode, remote, refspec set, or object database changes.

Each target host records the inputs, calculations, object identities, measured allocations, and both gate results in the retained M5 evidence. No source, installed tree, release object, or prior evidence is deleted except at an owner-approved exact path after the retained evidence is copied and its digest is verified.

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 11 | pre-change | Dev host `top` | Debian GNU/Linux 13.6 | x86_64 | `/data/gitsrc/con/con` | Run the complete discovered suite with `ECHO_SERVER_MODE=socat` and the shipped con binary. | Every suite passes and reports the socat backend. | pending |
| Release Verification 12 | pre-change | Dev host `top` | Debian GNU/Linux 13.6 | x86_64 | `/data/gitsrc/con/con` | Run the complete discovered suite with `ECHO_SERVER_MODE=echo_server` and the shipped con binary. | Every suite passes and reports the compiled backend. | pending |
| Release Verification 13 | pre-change | Dev host `top` | Debian GNU/Linux 13.6 | x86_64 | `/data/gitsrc/con/con` | Run the real PTY diagnostic pause/resume path and one bounded flood that observes recv-q above zero without unbounded capture. | Diagnostic output is observed, input resumes, and bounded flood evidence records host, value, and candidate hash. | pending |
| Release Verification 14 | pre-change | Golden `testbed-rocky8` | Rocky Linux 8.10, epics-ioc-runner 1.2.4 | x86_64 | `/opt/con-rc/con` | Run the reconciled upstream gate with candidate identity asserted inside the console-holding principal and execute the real shared-console path. | All pinned dependency, access, shared-console, and lifecycle checks pass. | pending |
| Release Verification 15 | pre-change | Golden `debian13-iocrunner-server` | Debian GNU/Linux 13, epics-ioc-runner 1.2.4 | x86_64 | `/opt/con-rc/con` | Run the same reconciled gate and real candidate path on the Debian golden. | All pinned dependency, access, shared-console, and lifecycle checks pass. | pending |
| Release Verification 18 | post-release | Fresh VM `con-release-install-debian13` | Debian GNU/Linux 13 | x86_64 | `/usr/local/bin/con` | Install the documented Debian prerequisites, complete the per-host Released-Object Storage Preflight, obtain the released source, follow the README build and install path, invoke installed `con -V`, and run the documented shipped-`echo_server` UDS test with `CON_BIN=/usr/local/bin/con`. | Both storage gates pass, installed con reports 1.2.0, and the real shipped-`echo_server` round trip passes. | pending |
| Release Verification 19 | post-release | Fresh VM `con-release-install-rocky8` | Rocky Linux 8.10 | x86_64 | `/usr/local/bin/con` | Install the documented Rocky prerequisites, complete the per-host Released-Object Storage Preflight, obtain the released source, follow the README build and install path, invoke installed `con -V`, and run the documented shipped-`echo_server` UDS test with `CON_BIN=/usr/local/bin/con`. | Both storage gates pass, installed con reports 1.2.0, and the real shipped-`echo_server` round trip passes. | pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `CON_VERSION` | `GNUmakefile` | `1.1.0` | `1.2.0` | Build the final pre-change candidate and inspect shipped `con -V`. | Release Verification 16 | Rebuild after the authorized mutation and inspect shipped `con -V`. | Release Verification 17 |

##### Release Execution

Phase 9 prepares the release candidate. Phase 10 rows run in order, and every checkpoint row must complete before the next dependent action. Phase 11 then runs Release Verification 18 through 21 and 23. Phase 12 reconciles linked issues, closes the GitHub milestone, runs Release Verification 22 against the observed closure, and closes the canonical cycle only after Release Verification 1 through 23 are Pass.

| Phase | Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| 9 | 1 | Finalize `CHANGELOG.md`; create and review ignored file `work/release-notes-1.2.0.md`; commit only `CHANGELOG.md`. | Separate release-content edit and commit/add authority | The changelog is committed on `release-1.2.0`, and the reviewed notes remain outside the Git index for the later GitHub release action. | pending |
| 9 | 2 | Record all pre-change results in the canonical document and commit the checked evidence. | Separate canonical-update and commit/add authority | The pre-change evidence commit names every observed result and retained log. | pending |
| 9 | 3 | Change `GNUmakefile` `CON_VERSION` to 1.2.0 and commit only the verified version file. | Separate version-edit and commit/add authority | The version commit contains only the release version change. | pending |
| 9 | 4 | Run the post-change checks, record the results, and commit the readiness evidence. | Separate canonical-update and commit/add authority | The readiness-evidence commit is the explicit release candidate. | pending |
| 10 | 5 | Merge reviewed `release-1.2.0` to `master` with the previewed non-fast-forward release procedure, naming the readiness-evidence commit. | Separate release authority | The recorded release merge contains the explicit candidate. | pending |
| 10 | 6 | Record the merge object in the canonical document and create a checkpoint commit on `master`. | Separate canonical-update and commit/add authority | The next action can name the recorded release merge rather than implicit `HEAD`. | pending |
| 10 | 7 | Create annotated tag `1.2.0` on the recorded release merge. | Separate release authority | The local annotated tag targets the verified release merge. | pending |
| 10 | 8 | Record the tag object and peeled merge object, then create a canonical checkpoint commit. | Separate canonical-update and commit/add authority | Both immutable tag identities are recorded before any push. | pending |
| 10 | 9 | Push local `master` and the final `release-1.2.0` branch to `origin` as `refs/heads/master` and `refs/heads/release-1.2.0`; do not include any tag. | Separate push authority | Both `origin` branch refs resolve to the reviewed local branch objects. | pending |
| 10 | 10 | Re-read `origin` refs `refs/heads/master` and `refs/heads/release-1.2.0`, record their object IDs, and create a canonical checkpoint commit. | Separate canonical-update and commit/add authority | Remote branch evidence is committed before tag publication. | pending |
| 10 | 11 | Push fully qualified local tag ref `refs/tags/1.2.0` to `origin` separately. | Owner-executed tag push; assistant Push scope does not authorize tags | The `origin` annotated tag resolves to the recorded local tag object. | pending |
| 10 | 12 | Re-read `origin` refs `refs/tags/1.2.0` and `refs/tags/1.2.0^{}`, record their tag and peeled object IDs, and create a canonical checkpoint commit. | Separate canonical-update and commit/add authority | Remote tag object and peeled release-merge evidence are committed before release publication. | pending |
| 10 | 13 | Publish the GitHub 1.2.0 release in `github.com/jeonghanlee/con` from the verified tag and `work/release-notes-1.2.0.md`. | Separate release authority | The release object targets tag 1.2.0 and contains the reviewed notes. | pending |
| 10 | 14 | Re-read the GitHub release, record its URL and target, and create a canonical checkpoint commit. | Separate canonical-update and commit/add authority | Release-object evidence is committed before the next dependent action. | pending |
| 10 | 15 | Check local branch `release-1.0.0` and `origin` ref `refs/heads/release-1.0.0`; record N/A while both are absent, and stop for an explicit owner instruction if either appears. | Read-only check; explicit owner instruction only if deletion becomes applicable | The two-back check is recorded without deleting an unverified branch. | pending |
| 10 | 16 | Record the observed retention result and any separately owner-executed deletion result in a canonical checkpoint commit. | Separate canonical-update and commit/add authority | Retention evidence precedes next-line creation. | pending |
| 10 | 17 | Create local branch `release-1.3.0` from the recorded release merge. | Separate explicit owner instruction | The next release line starts from the released object and remains local until separately authorized for push. | pending |
| 10 | 18 | Create `docs/milestone-1.3.0.md` as the first canonical commit on `release-1.3.0`, carrying surviving Backlog work. | Separate reset and commit/add authority | The next branch has one version-qualified canonical document and one entry point. | pending |
| 10 | 19 | Change `GNUmakefile` `CON_VERSION` to `1.3.0-dev` in a standalone commit. | Separate version-edit and commit/add authority | Development builds identify the 1.3.0 line. | pending |
| 10 | 20 | Create a GitHub 1.3.0 milestone only if active work is assigned; otherwise record that creation remains deferred. | Owner-executed GitHub milestone action | Remote next-line state matches the canonical assignment state. | pending |
| 10 | 21 | Return to `master`, record the next-line canonical commit and optional remote milestone result in the 1.2.0 canonical document, then create a checkpoint commit. | Separate explicit owner instruction for the branch switch, plus canonical-update and commit/add authority | Phase 11 can verify one explicit next-line entry point. | pending |
| 12 | 22 | After Release Verification 18 through 21 and 23 pass, prepare the source-first closure record on `master` and commit all observed post-release results and issue intent. | Separate canonical-update and commit/add authority | The default branch contains the checked closure intent before any phase 12 issue mutation. | pending |
| 12 | 23 | Push the source-first closure preparation commit from local `master` to `origin` ref `refs/heads/master`, then re-read that remote ref. | Separate push authority followed by a read-only remote check | `origin` resolves `refs/heads/master` to the source-first preparation commit before issue mutation. | pending |
| 12 | 24 | Re-read every linked issue and apply only pending, separately authorized projection or close actions; issue #16 must remain open in GitHub `Backlog` with its existing labels. | Separate issue authority for each mutation | Every linked issue matches its canonical assignment and closure intent. | pending |
| 12 | 25 | Close GitHub milestone `1.2.0` (#4) in `github.com/jeonghanlee/con` after all linked issues are reconciled and every Release Verification result other than the closure observation is Pass. | Separate release authority | The milestone closes with no unintended open assignment. | pending |
| 12 | 26 | Re-read the milestone and assigned issues, record Release Verification 22, set M5 and the cycle to Complete, and create the final canonical closure commit. | Read-only observation followed by separate canonical-update and commit/add authority | Release Verification 1 through 23 are Pass, the tally and next entry point agree, and the committed canonical file is final. | pending |
| 12 | 27 | Push the final canonical closure commit from local `master` to `origin` ref `refs/heads/master`; re-read that remote ref, then compare the committed canonical file byte-for-byte with the checked working-tree file. | Separate push authority followed by read-only remote and repository checks | Local `master` and `origin` ref `refs/heads/master` resolve to the same final closure commit with no remaining closure-path modification. | pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Integrated negative | pre-change | Execute M1 / T1 on the final combined candidate. | Linux dev host | A real failed UDS connection returns nonzero. | M5 result row and retained test output |
| Release Verification 2 | Integrated functional | pre-change | Execute M1 / T2 on the final combined candidate. | Linux dev host | A real UDS echo round trip returns the exact payload. | M5 result row and retained test output |
| Release Verification 3 | Runner integration | pre-change | Execute M1 / T3 after the M2 suite exists. | Linux dev host | The discovered set equals the shipped `test-*.bash` set and every suite runs once. | M5 result row and runner output |
| Release Verification 4 | Integrated functional | pre-change | Execute M2 / T1 on the final combined candidate. | Linux dev host | A fresh shell resolves and executes the real repository binary. | M5 result row and shell output |
| Release Verification 5 | Integrated negative | pre-change | Execute M2 / T2 on the final combined candidate. | Linux dev host | A non-executable binary path fails clearly and nonzero. | M5 result row and shell output |
| Release Verification 6 | Integrated functional | pre-change | Execute M3 / T1 on the final combined candidate. | Linux dev host | `-u -c` forces AF_UNIX for a colon-bearing numeric-tail path. | M5 result row and echo output |
| Release Verification 7 | Integrated functional | pre-change | Execute M3 / T2 on the final combined candidate. | Linux dev host | `-u -s` creates a UDS endpoint and exchanges real data. | M5 result row and socket evidence |
| Release Verification 8 | CLI regression | pre-change | Execute M3 / T3 on the final combined candidate, including the compiled PTY-pair serial fixture. | Linux dev host | Both option forms and help work; the real serial path and legacy socket behavior remain compatible. | M5 result row and CLI plus PTY output |
| Release Verification 9 | Integrated functional | pre-change | Execute M4 / T1 on the final combined candidate. | Linux dev host | A colonless UDS path completes a real echo round trip with `-u`. | M5 result row and echo output |
| Release Verification 10 | Serial regression | pre-change | Execute M4 / T2 on the final combined candidate through the shipped compiled serial fixture. | Linux dev host | A unique payload crosses the flagless serial path through the real PTY pair. | M5 result row and PTY output |
| Release Verification 11 | Automated suite | pre-change | Run the complete discovered suite with `ECHO_SERVER_MODE=socat`. | `top`, Debian GNU/Linux 13.6, x86_64 | Every shipped suite passes and reports the socat backend. | M5 result row and full runner log |
| Release Verification 12 | Automated suite | pre-change | Run the complete discovered suite with `ECHO_SERVER_MODE=echo_server`. | `top`, Debian GNU/Linux 13.6, x86_64 | Every shipped suite passes and reports the compiled backend. | M5 result row and full runner log |
| Release Verification 13 | Diagnostic integration | pre-change | Run the real PTY pause/resume test and one bounded flood diagnostic. | `top`, Debian GNU/Linux 13.6, x86_64 | Pause, diagnostic, resume, and recv-q above zero are observed on the candidate. | M5 result row with host, value, hash, and log |
| Release Verification 14 | Downstream integration | pre-change | Run the reconciled gate with the staged candidate on `testbed-rocky8`. | Rocky Linux 8.10 x86_64 golden | All gate checks pass with the candidate identity observed in the real principal context. | M5 result row and retained golden log |
| Release Verification 15 | Downstream integration | pre-change | Run the reconciled gate with the staged candidate on `debian13-iocrunner-server`. | Debian GNU/Linux 13 x86_64 golden | All gate checks pass with the candidate identity observed in the real principal context. | M5 result row and retained golden log |
| Release Verification 16 | Version pre-check | pre-change | Build the final candidate before version mutation and inspect `con -V`. | Release branch build host | The binary reports 1.1.0 and the final pre-change git identity. | M5 result row and version output |
| Release Verification 17 | Version post-check | post-change | Rebuild after the authorized version mutation and inspect `con -V`. | Release branch build host | The binary reports 1.2.0 and the intended release git identity. | M5 result row and version output |
| Release Verification 18 | Debian installation integration | post-release | On fresh VM `con-release-install-debian13`, install the README prerequisites, complete the per-host Released-Object Storage Preflight, obtain, build, and install the released source, verify `/usr/local/bin/con -V`, and run the documented shipped-`echo_server` test with `CON_BIN=/usr/local/bin/con`. | Debian GNU/Linux 13 x86_64 | Both storage gates pass, installed con reports 1.2.0, and the real shipped-`echo_server` round trip passes. | M5 result row and Debian installation log |
| Release Verification 19 | Rocky installation integration | post-release | On fresh VM `con-release-install-rocky8`, install the README prerequisites, complete the per-host Released-Object Storage Preflight, obtain, build, and install the released source, verify `/usr/local/bin/con -V`, and run the documented shipped-`echo_server` test with `CON_BIN=/usr/local/bin/con`. | Rocky Linux 8.10 x86_64 | Both storage gates pass, installed con reports 1.2.0, and the real shipped-`echo_server` round trip passes. | M5 result row and Rocky installation log |
| Release Verification 20 | Git object identity | post-release | Resolve the local tag object, `origin` refs `refs/tags/1.2.0` and `refs/tags/1.2.0^{}`, and the default-branch release merge. | Git repository and origin | Annotated tag 1.2.0 resolves to the authorized release merge. | M5 result row with immutable object IDs |
| Release Verification 21 | Release object identity | post-release | Read the published GitHub release and compare its tag and reviewed notes. | GitHub | The release is published for tag 1.2.0 with the approved content. | M5 result row and release URL |
| Release Verification 22 | Tracker closure | post-release | Read GitHub milestone 1.2.0 and its assigned issue states. | GitHub | The milestone is closed and no unintended open issue remains assigned. | M5 result row and milestone URL |
| Release Verification 23 | Next-line state | post-release | Read the default branch canonical documents and live tracker after the next-line actions. | Repository and GitHub | Exactly one next entry point is recorded and remote metadata matches its authorized projection. | M5 result row with commit and tracker evidence |

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | Not run | Linux dev host | Pending | none |
| Release Verification 2 | Not run | Linux dev host | Pending | none |
| Release Verification 3 | Not run | Linux dev host | Pending | none |
| Release Verification 4 | Not run | Linux dev host | Pending | none |
| Release Verification 5 | Not run | Linux dev host | Pending | none |
| Release Verification 6 | Not run | Linux dev host | Pending | none |
| Release Verification 7 | Not run | Linux dev host | Pending | none |
| Release Verification 8 | Not run | Linux dev host | Pending | none |
| Release Verification 9 | Not run | Linux dev host | Pending | none |
| Release Verification 10 | Not run | Linux dev host | Pending | none |
| Release Verification 11 | Not run | `top`, Debian GNU/Linux 13.6, x86_64 | Pending | none |
| Release Verification 12 | Not run | `top`, Debian GNU/Linux 13.6, x86_64 | Pending | none |
| Release Verification 13 | Not run | `top`, Debian GNU/Linux 13.6, x86_64 | Pending | none |
| Release Verification 14 | Not run | `testbed-rocky8`, Rocky Linux 8.10, x86_64 | Pending | none |
| Release Verification 15 | Not run | `debian13-iocrunner-server`, Debian GNU/Linux 13, x86_64 | Pending | none |
| Release Verification 16 | Not run | Release branch build host | Pending | none |
| Release Verification 17 | Not run | Release branch build host | Pending | none |
| Release Verification 18 | Not run | Debian GNU/Linux 13 x86_64 | Pending | none |
| Release Verification 19 | Not run | Rocky Linux 8.10 x86_64 | Pending | none |
| Release Verification 20 | Not run | Git repository and origin | Pending | none |
| Release Verification 21 | Not run | GitHub | Pending | none |
| Release Verification 22 | Not run | GitHub | Pending | none |
| Release Verification 23 | Not run | Repository and GitHub | Pending | none |

## Backlog

Backlog rows are unassigned, excluded from the 1.2.0 release tally, and retained until a dated owner decision assigns, defers, transfers, or retires them.

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Closed Door | M6 | Prevent destructive UDS server path unlink (#8) | Carry-forward | Deferred | No | D1, D2 | A new dated owner decision reopens or transfers the work; [detail](#m6---prevent-destructive-uds-server-path-unlink-8) |
| Closed Door | M7 | Remove the UDS server socket on exit (#9) | Carry-forward | Deferred | No | D1, D2 | A new dated owner decision reopens or transfers the work; [detail](#m7---remove-the-uds-server-socket-on-exit-9) |
| Closed Door | M8 | Add UDS peer identity and socket permissions (#10) | Carry-forward | Deferred | No | D1, D2 | A new dated owner decision reopens or transfers the work; [detail](#m8---add-uds-peer-identity-and-socket-permissions-10) |
| Closed Door | M9 | Replace legacy host lookup for IPv6 (#11) | Carry-forward | Deferred | No | D2 | A new dated owner decision reopens or transfers the work; [detail](#m9---replace-legacy-host-lookup-for-ipv6-11) |
| Closed Door | M10 | Remove AF_UNIX SO_REUSEADDR (#12) | Carry-forward | Deferred | No | D1, D2 | A new dated owner decision reopens or transfers the work; [detail](#m10---remove-af_unix-so_reuseaddr-12) |
| Closed Door | M11 | Correct minor UDS server defects (#13) | Carry-forward | Deferred | No | D1, D2 | A new dated owner decision reopens or transfers the work; [detail](#m11---correct-minor-uds-server-defects-13) |
| Closed Door | M12 | Evaluate shared UNIX and TCP accept-loop code (#14) | Carry-forward | Deferred | No | D1, D2 | A new dated owner decision selects Generalize or Keep; [detail](#m12---evaluate-shared-unix-and-tcp-accept-loop-code-14) |
| Closed Door | M13 | Reset the hexa line counter per server connection (#17) | Carry-forward | Deferred | No | D1, D2 | A new dated owner decision reopens or transfers the work; [detail](#m13---reset-the-hexa-line-counter-per-server-connection-17) |
| Closed Door | M14 | Define flagless host:port server direction (#21) | Carry-forward | Deferred | No | D2, D7 | A new dated owner decision changes or confirms the behavior outside 1.2.0; [detail](#m14---define-flagless-hostport-server-direction-21) |
| General | M15 | Correct missing-argument errors for log flags (#15) | Carry-forward | Open | No | | Owner assigns priority and accepts a plan; [detail](#m15---correct-missing-argument-errors-for-log-flags-15) |
| General | M16 | Decide the fate of dormant str_utils APIs (#18) | Carry-forward | Open | No | | Owner selects Keep or Discard and accepts a plan; [detail](#m16---decide-the-fate-of-dormant-str_utils-apis-18) |
| General | M17 | Decide whether CLI parsers stay separate (#19) | Carry-forward | Open | No | | Owner selects Keep or Generalize and accepts a plan; [detail](#m17---decide-whether-cli-parsers-stay-separate-19) |

### Backlog Details

#### M6 - Prevent destructive UDS server path unlink (#8)

Origin: 1.2.0 / M6
Identity History: none
GitHub Issue: [#8](https://github.com/jeonghanlee/con/issues/8)
Status: Deferred

##### Summary

The UDS server unconditionally unlinks its bind path, which can delete a non-socket file and leaves a check-to-bind race.

##### Scope

Before binding, inspect an existing path, unlink only a socket, reject other file types, and check the unlink result.

Out of scope: automatic execution in 1.2.0 and broader UDS server lifecycle changes from issue #9.

##### Completion Criteria

- A server start on an existing regular file fails without deleting the file.
- A stale socket path can still be removed and rebound.
- Required UDS server regressions pass after a dated reopening decision.

##### Dependencies And Decisions

- D1 and D2 defer this work. Resume as Not started only after a new dated owner decision.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Inspect the target with a race-aware design before any unlink.
2. Reject non-socket targets and check every unlink result.
3. Add permanent non-socket-preservation and stale-socket tests.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Security negative | Place a real regular file at the requested server path and invoke shipped con server mode. | Linux test host | con fails nonzero and the file remains byte-identical. |
| T2 | Functional | Leave a real stale UDS node at the path and start shipped con server mode. | Linux test host | The stale socket is safely replaced and the server accepts a real client. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D1 and D2; no implementation evidence.

##### GitHub Projection

Title: UDS server: destructive unlink of a non-socket plus TOCTOU
Labels: `bug`, `area/uds`, `P2-medium`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `bug`, `area/uds`, `P2-medium`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:23Z

#### M7 - Remove the UDS server socket on exit (#9)

Origin: 1.2.0 / M7
Identity History: none
GitHub Issue: [#9](https://github.com/jeonghanlee/con/issues/9)
Status: Deferred

##### Summary

The UDS server closes its descriptor on exit but leaves its owned socket node on disk, forcing the next start to clean stale state.

##### Scope

Track the bound UDS path and unlink the owned socket during normal and handled termination cleanup.

Out of scope: unlinking paths not owned by the running server and execution in 1.2.0.

##### Completion Criteria

- A clean server exit removes its socket node.
- Cleanup never removes a replacement path that the process does not own.
- UDS server lifecycle tests pass after a dated reopening decision.

##### Dependencies And Decisions

- D1 and D2 defer this work. Coordinate with M6 if both are reopened.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Store the successfully bound UDS path as owned runtime state.
2. Remove only that owned socket during cleanup.
3. Add clean-exit and replacement-path safety regressions.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Lifecycle | Start shipped con as a UDS server, verify the socket node, terminate cleanly, and inspect the path. | Linux test host | The owned socket node is absent after exit. |
| T2 | Safety | Exercise the accepted ownership-race procedure with the real server process and filesystem boundary. | Linux test host | Cleanup does not remove an unowned replacement path. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D1 and D2; no implementation evidence.

##### GitHub Projection

Title: UDS server leaves stale socket on exit
Labels: `bug`, `area/uds`, `P2-medium`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `bug`, `area/uds`, `P2-medium`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:16Z

#### M8 - Add UDS peer identity and socket permissions (#10)

Origin: 1.2.0 / M8
Identity History: none
GitHub Issue: [#10](https://github.com/jeonghanlee/con/issues/10)
Status: Deferred

##### Summary

The UDS server accepts local clients without logging peer credentials and relies on ambient defaults for socket-node permissions.

##### Scope

Retrieve Linux peer PID and UID with `SO_PEERCRED`, log them through the existing server path, and apply an owner-approved explicit socket mode.

Out of scope: defining the site access policy without owner input and execution in 1.2.0.

##### Completion Criteria

- The server logs the real connecting peer PID and UID.
- The socket node has the accepted mode independent of the caller's ambient umask.
- Access and UDS server regressions pass after reopening.

##### Dependencies And Decisions

- D1 and D2 defer this work; the socket mode remains an owner decision when reopened.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the required peer log fields and socket mode with the owner.
2. Read `SO_PEERCRED` from the accepted real socket and log its PID and UID.
3. Apply and verify the selected socket-node permissions.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Functional | Connect a real process with known PID and UID to shipped con server mode and inspect the server log. | Linux test host | Logged PID and UID match the connecting kernel process credentials. |
| T2 | Access control | Start the real server under controlled umasks and inspect the socket node with `stat`. | Linux test host | The node mode matches the accepted explicit mode in every run. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D1 and D2; no implementation evidence.

##### GitHub Projection

Title: UDS server: log peer SO_PEERCRED and set socket-file permissions
Labels: `enhancement`, `area/uds`, `P2-medium`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `enhancement`, `area/uds`, `P2-medium`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:23Z

#### M9 - Replace legacy host lookup for IPv6 (#11)

Origin: 1.2.0 / M9
Identity History: none
GitHub Issue: [#11](https://github.com/jeonghanlee/con/issues/11)
Status: Deferred

##### Summary

The TCP client and server use legacy host lookup APIs, lack IPv6 support, and size one server-side hostname buffer from a pointer rather than a hostname limit.

##### Scope

Replace legacy lookup with `getaddrinfo` and `getnameinfo`, use protocol-correct address iteration, and size names for `NI_MAXHOST`.

Out of scope: changing default client/server direction and execution in 1.2.0.

##### Completion Criteria

- The TCP client connects to an IPv6 endpoint through the shipped code.
- The TCP server logs a complete peer name or numeric address without pointer-sized truncation.
- Existing IPv4 TCP behavior remains compatible.

##### Dependencies And Decisions

- D2 defers TCP client and server work.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define accepted IPv4 and IPv6 client/server address behavior.
2. Replace both legacy lookup paths and use correctly sized storage.
3. Add real IPv4 and IPv6 endpoint regressions.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Network integration | Start a real IPv6 TCP echo endpoint and connect with shipped con. | Linux dual-stack test host | con resolves, connects, and exchanges the exact payload over IPv6. |
| T2 | Network regression | Run real IPv4 client and server paths and inspect the peer identity output. | Linux test host | IPv4 behavior remains compatible and peer text is not truncated by pointer size. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux dual-stack test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D2; no implementation evidence.

##### GitHub Projection

Title: Replace gethostby with getaddrinfo/getnameinfo for IPv6
Labels: `enhancement`, `P2-medium`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `enhancement`, `P2-medium`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:25Z

#### M10 - Remove AF_UNIX SO_REUSEADDR (#12)

Origin: 1.2.0 / M10
Identity History: none
GitHub Issue: [#12](https://github.com/jeonghanlee/con/issues/12)
Status: Deferred

##### Summary

The AF_UNIX server branch sets `SO_REUSEADDR`, although UDS pathname reuse is controlled by filesystem cleanup rather than this socket option.

##### Scope

Remove the ineffective option from the AF_UNIX branch or record a new evidence-backed Keep decision.

Out of scope: TCP `SO_REUSEADDR`, socket-path cleanup design, and execution in 1.2.0.

##### Completion Criteria

- The owner accepts Remove or Keep after current Linux behavior is verified.
- If removed, the real UDS server still binds, accepts a client, and restarts according to its cleanup contract.

##### Dependencies And Decisions

- D1 and D2 defer this work; M6 and M7 own related path lifecycle behavior.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Reconfirm the option's AF_UNIX behavior on supported Linux systems.
2. Present Remove or Keep with the observed evidence.
3. If Remove is accepted, delete only the AF_UNIX call and run UDS server regressions.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Functional | Start shipped con UDS server mode before and after the accepted change and connect through a real peer. | Linux test host | Bind and data exchange behavior remain compatible. |
| T2 | Lifecycle | Restart the real server on the same pathname under the accepted M6/M7 cleanup contract. | Linux test host | Restart outcome matches the explicit socket-path lifecycle design. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D1 and D2; no implementation evidence.

##### GitHub Projection

Title: SO_REUSEADDR is a no-op on AF_UNIX
Labels: `P3-low`, `area/uds`, `refactor`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `P3-low`, `area/uds`, `refactor`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:23Z

#### M11 - Correct minor UDS server defects (#13)

Origin: 1.2.0 / M11
Identity History: none
GitHub Issue: [#13](https://github.com/jeonghanlee/con/issues/13)
Status: Deferred

##### Summary

The UDS accept path contains a misspelled diagnostic, uses raw `read` where the core uses EINTR-aware `readn`, and casts an `int` address length to `socklen_t *`.

##### Scope

Correct the diagnostic text, use a real `socklen_t` variable, and adopt the accepted read behavior consistently.

Out of scope: refactoring both server loops and execution in 1.2.0.

##### Completion Criteria

- The accept call receives a correctly typed address length.
- The accepted read behavior handles EINTR consistently and diagnostics use correct text.
- UDS server behavior remains compatible.

##### Dependencies And Decisions

- D1 and D2 defer this work; coordinate with M12 if the accept loops are generalized.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Confirm the required blocking and EINTR semantics for the server read path.
2. Correct the type, read call, and diagnostic in the existing UDS loop.
3. Run real connection, disconnect, and signal-interruption regressions.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Functional | Connect a real UDS peer, exchange data, and disconnect through shipped con server mode. | Linux test host | Data and disconnect handling remain correct with the typed address length and accepted read path. |
| T2 | Signal regression | Exercise the real server read path with an actual interrupt signal under a bounded harness. | Linux test host | EINTR handling follows the accepted contract without corrupting data or hanging. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D1 and D2; no implementation evidence.

##### GitHub Projection

Title: UDS server minor: typo, read vs readn, socklen cast
Labels: `P3-low`, `area/uds`, `refactor`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `P3-low`, `area/uds`, `refactor`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:24Z

#### M12 - Evaluate shared UNIX and TCP accept-loop code (#14)

Origin: 1.2.0 / M12
Identity History: none
GitHub Issue: [#14](https://github.com/jeonghanlee/con/issues/14)
Status: Deferred

##### Summary

The UNIX and TCP server accept loops duplicate control flow but differ in address handling and peer-name resolution. Both copies currently agree.

##### Scope

Re-evaluate Generalize versus Keep against the current code, and generalize only if one shared abstraction preserves both real server paths without obscuring transport-specific behavior.

Out of scope: forcing a refactor without an owner fate decision and execution in 1.2.0.

##### Completion Criteria

- The owner records a dated Generalize or Keep decision from current evidence.
- If generalized, UNIX and TCP server behavior is equivalent before and after through real clients.

##### Dependencies And Decisions

- D1 and D2 defer this work; coordinate reopened server fixes before deciding the abstraction boundary.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Compare both current loops and all pending server changes at the same commit.
2. Present Generalize or Keep with concrete shared and transport-specific surfaces.
3. If Generalize is accepted, preserve separate address setup and peer identity while sharing only proven common control flow.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Behavioral comparison | Run real UNIX and TCP clients against shipped server modes before and after an accepted refactor with identical payload and disconnect cases. | Linux test host | Each transport preserves its exact observable results. |
| T2 | Regression | Run complete accepted UNIX and TCP server suites. | Linux test host | Both server paths pass. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D1 and D2; no implementation evidence.

##### GitHub Projection

Title: Deduplicate UNIX and TCP server accept loops
Labels: `P3-low`, `refactor`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `P3-low`, `refactor`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:23Z

#### M13 - Reset the hexa line counter per server connection (#17)

Origin: 1.2.0 / M13
Identity History: none
GitHub Issue: [#17](https://github.com/jeonghanlee/con/issues/17)
Status: Deferred

##### Summary

A static hexa line-wrap counter in `con_core` persists across sequential server connections, so a later client can begin with the previous client's partial line state.

##### Scope

Make the line counter local to one `con_core` connection and preserve the existing hexa output format.

Out of scope: issue #16's duplicated output blocks and execution in 1.2.0.

##### Completion Criteria

- Two sequential real server clients each begin hexa output at a fresh line boundary.
- Existing `-X` and `-Y` output remains byte-compatible apart from the corrected connection boundary.

##### Dependencies And Decisions

- D1 and D2 defer server-only work; D3 keeps issue #16 implementation unchanged and outside active 1.2.0 work while the open GitHub issue remains in `Backlog`.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Move the counter into per-call state without changing the format branches.
2. Add a sequential-client regression with the first client ending mid-line.
3. Run the complete hexa and server suites.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Functional integration | Connect two real sequential clients to shipped server mode; end the first mid-line and inspect the second client's hexa output. | Linux test host | The second connection starts with a fresh line counter. |
| T2 | Output regression | Run the shipped hexa suite for both `-X` and `-Y`. | Linux test host | Existing output cases remain byte-compatible. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D1 and D2; no implementation evidence.

##### GitHub Projection

Title: static term_cnt not reset across server connections
Labels: `bug`, `P3-low`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `bug`, `P3-low`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:22Z

#### M14 - Define flagless host:port server direction (#21)

Origin: 1.2.0 / M14
Identity History: none
GitHub Issue: [#21](https://github.com/jeonghanlee/con/issues/21)
Status: Deferred

##### Summary

A flagless `host:port` target selects server mode and binds `INADDR_ANY`, discarding the host prefix despite a contradictory source comment.

##### Scope

Choose and document one intentional flagless direction: current server behavior, conventional client behavior, or explicit `-c`/`-s` only.

Out of scope: changing this behavior through issue #20 or #22 and execution in 1.2.0.

##### Completion Criteria

- A dated owner decision defines flagless `host:port` direction and compatibility policy.
- Accepted behavior and help documentation agree with the shipped client/server path.

##### Dependencies And Decisions

- D2 defers TCP direction changes.
- D7 explicitly preserves the current flagless behavior throughout 1.2.0.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Capture current behavior for `host:port`, `:port`, `-c`, and `-s` through real endpoints.
2. Present the compatibility cost of the three direction policies.
3. Implement and document only the owner-selected policy with permanent regressions.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Network behavior | Exercise flagless `host:port` and `:port` against real TCP endpoints through shipped con. | Linux test host | Observed direction matches the accepted policy and no host component is silently mishandled. |
| T2 | CLI regression | Exercise explicit `-c` and `-s` TCP paths after the accepted change. | Linux test host | Explicit client and server modes remain stable. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D2 and D7; no implementation evidence.

##### GitHub Projection

Title: Flagless host:port binds a server and silently discards the host
Labels: `bug`, `P3-low`, `area/uds`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `bug`, `P3-low`, `area/uds`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:23Z

#### M15 - Correct missing-argument errors for log flags (#15)

Origin: 1.2.0 / M15
Identity History: none
GitHub Issue: [#15](https://github.com/jeonghanlee/con/issues/15)
Status: Open

##### Summary

The `-l` and `-a` missing-argument paths report that a baud rate is required even though each option expects a filename.

##### Scope

Correct both diagnostics and add permanent CLI error regressions.

Out of scope: broader option-parser refactoring and automatic assignment to 1.2.0.

##### Completion Criteria

- Both missing-argument cases identify a filename requirement and return nonzero.
- The complete error-handling suite passes.

##### Dependencies And Decisions

- None; priority and release assignment remain unresolved.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Replace only the two incorrect diagnostics with filename-specific text.
2. Add real CLI error assertions for both option forms.
3. Run the full error-handling suite.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | CLI negative | Invoke shipped con with `-l` and no argument, then with `-a` and no argument. | Linux dev host | Both invocations return nonzero and report a filename requirement. |
| T2 | Regression | Run `tests/test-error-handling.bash` through the shipped test path. | Linux dev host | Every error assertion passes. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux dev host | Pending | none |
| T2 | Not run | Linux dev host | Pending | none |

##### Closure Evidence

- None.

##### GitHub Projection

Title: Log flags -l and -a print the wrong missing-argument error
Labels: `bug`, `P3-low`
GitHub Milestone: `Backlog`
Observed State: open
Observed Labels: `bug`, `P3-low`
Observed Milestone: `Backlog`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:43Z

#### M16 - Decide the fate of dormant str_utils APIs (#18)

Origin: 1.2.0 / M16
Identity History: none
GitHub Issue: [#18](https://github.com/jeonghanlee/con/issues/18)
Status: Open

##### Summary

Most of `str_utils` is not referenced by either binary, while `filter_colors` overlaps con's inline color filtering and `str::unescape` remains used by `send_rs232`.

##### Scope

Choose Keep-as-library or Discard-unused from current consumers, then preserve the required `send_rs232` API and build contract.

Out of scope: deleting APIs without an owner fate decision and automatic assignment to 1.2.0.

##### Completion Criteria

- A dated owner decision records Keep or Discard with current call-site evidence.
- Any accepted change preserves the real `send_rs232` unescape path and both binaries build.

##### Dependencies And Decisions

- None; fate and release assignment remain unresolved.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Re-scan current consumers and exported APIs.
2. Present Keep-as-library or Discard-unused with compatibility evidence.
3. If Discard is accepted, remove only proven-unused code and preserve `str::unescape`.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Build and functional | Build both shipped binaries and execute the real `send_rs232` unescape input path. | Linux dev host | Both binaries link and unescape behavior remains correct. |
| T2 | Static consumer check | Search the final tracked source for references to each removed or retained API. | Repository | Every removed API has no consumer and every required API remains defined. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux dev host | Pending | none |
| T2 | Not run | Repository | Pending | none |

##### Closure Evidence

- None.

##### GitHub Projection

Title: str_utils dormant API; filter_colors duplicates write_log
Labels: `P3-low`, `refactor`
GitHub Milestone: `Backlog`
Observed State: open
Observed Labels: `P3-low`, `refactor`
Observed Milestone: `Backlog`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:40Z

#### M17 - Decide whether CLI parsers stay separate (#19)

Origin: 1.2.0 / M17
Identity History: none
GitHub Issue: [#19](https://github.com/jeonghanlee/con/issues/19)
Status: Open

##### Summary

`con` and `send_rs232` duplicate their main option-parsing skeleton and baud-rate parsing, but they are independent programs with different option surfaces.

##### Scope

Choose Keep-separate or Generalize from current behavior and maintenance cost, then preserve both public CLIs if any shared parser is accepted.

Out of scope: coupling the tools without an owner fate decision and automatic assignment to 1.2.0.

##### Completion Criteria

- A dated owner decision records Keep or Generalize with current option maps.
- If generalized, both binaries preserve argument parsing, diagnostics, and baud handling through real CLI tests.

##### Dependencies And Decisions

- None; fate and release assignment remain unresolved.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Inventory each binary's current options, defaults, errors, and baud behavior.
2. Present Keep-separate or one minimal shared boundary with compatibility evidence.
3. If Generalize is accepted, add real CLI parity tests before moving shared code.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | CLI comparison | Execute both shipped binaries across their accepted option and baud matrices before and after an accepted refactor. | Linux dev host | Each binary preserves its own observable CLI behavior. |
| T2 | Build regression | Build and link both binaries from the final tree. | Linux dev host | Both binaries build without unused or missing shared symbols. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux dev host | Pending | none |
| T2 | Not run | Linux dev host | Pending | none |

##### Closure Evidence

- None.

##### GitHub Projection

Title: Deduplicate CLI parsing between con and send_rs232
Labels: `P3-low`, `refactor`
GitHub Milestone: `Backlog`
Observed State: open
Observed Labels: `P3-low`, `refactor`
Observed Milestone: `Backlog`
Last Compared: 2026-08-26T17:12:37Z; issue updated 2026-08-13T07:45:34Z

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-08-26 | `2fb9b8b1a90c45e75a9c46b57c61e7fd9ddacf75` |
