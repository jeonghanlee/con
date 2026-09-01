# Work Register

Release line: master
Milestone index: bef067f
Canonical path: `docs/milestone-bef067f.md`
Canonical branch or ref: `master`
Git upstream: `origin/master`
Remote tracker: `github.com/jeonghanlee/con`, GitHub milestones `Backlog` (#1) and `Closed Door` (#3)

Next session entry point: choose one Backlog row through a dated owner decision; no row is currently Ready.

Milestone tally: milestones Not started 0, In progress 0, Blocked 0, Complete 0; external gates Open 0, Complete 0; Ready milestones 0.

Tracker reconciliation observed 2026-09-01T06:45:35Z: all 12 linked issues are open in their canonical `Backlog` or `Closed Door` assignment and assigned to `jeonghanlee`. Issue #16 remains outside this register under its dated Keep decision in `docs/CLOSED_DOORS.md`.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | Keep issues #8 through #14, #17, and #21 deferred in `Closed Door` until a new dated owner decision reopens or transfers one. | 2026-08-13 |
| D2 | Keep issues #15, #18, and #19 open in `Backlog` until a dated owner decision assigns, defers, transfers, or retires one. | 2026-08-13 |
| D3 | Preserve the additive `-u` and `--unix` behavior and current flagless transport behavior until issue #21 receives a dated direction decision. | 2026-08-26 |

### Milestone Details

No work is assigned to the active milestone.

## Backlog

Backlog rows are unassigned, excluded from the milestone tally, and retained until a dated owner decision assigns, defers, transfers, or retires them.

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Closed Door | M1 | Prevent destructive UDS server path unlink (#8) | Carry-forward | Deferred | No | D1 | A new dated owner decision reopens or transfers the work; [detail](#m1---prevent-destructive-uds-server-path-unlink-8) |
| Closed Door | M2 | Remove the UDS server socket on exit (#9) | Carry-forward | Deferred | No | D1 | A new dated owner decision reopens or transfers the work; [detail](#m2---remove-the-uds-server-socket-on-exit-9) |
| Closed Door | M3 | Add UDS peer identity and socket permissions (#10) | Carry-forward | Deferred | No | D1 | A new dated owner decision reopens or transfers the work; [detail](#m3---add-uds-peer-identity-and-socket-permissions-10) |
| Closed Door | M4 | Replace legacy host lookup for IPv6 (#11) | Carry-forward | Deferred | No | D1 | A new dated owner decision reopens or transfers the work; [detail](#m4---replace-legacy-host-lookup-for-ipv6-11) |
| Closed Door | M5 | Remove AF_UNIX SO_REUSEADDR (#12) | Carry-forward | Deferred | No | D1 | A new dated owner decision reopens or transfers the work; [detail](#m5---remove-af_unix-so_reuseaddr-12) |
| Closed Door | M6 | Correct minor UDS server defects (#13) | Carry-forward | Deferred | No | D1 | A new dated owner decision reopens or transfers the work; [detail](#m6---correct-minor-uds-server-defects-13) |
| Closed Door | M7 | Evaluate shared UNIX and TCP accept-loop code (#14) | Carry-forward | Deferred | No | D1 | A new dated owner decision selects Generalize or Keep; [detail](#m7---evaluate-shared-unix-and-tcp-accept-loop-code-14) |
| Closed Door | M8 | Reset the hexa line counter per server connection (#17) | Carry-forward | Deferred | No | D1 | A new dated owner decision reopens or transfers the work; [detail](#m8---reset-the-hexa-line-counter-per-server-connection-17) |
| Closed Door | M9 | Define flagless host:port server direction (#21) | Carry-forward | Deferred | No | D1, D3 | A new dated owner decision changes or confirms the behavior; [detail](#m9---define-flagless-hostport-server-direction-21) |
| General | M10 | Correct missing-argument errors for log flags (#15) | Carry-forward | Open | No | D2 | A dated owner decision assigns priority and accepts or defers the draft plan; [detail](#m10---correct-missing-argument-errors-for-log-flags-15) |
| General | M11 | Decide the fate of dormant str_utils APIs (#18) | Carry-forward | Open | No | D2 | A dated owner decision selects Keep or Discard; [detail](#m11---decide-the-fate-of-dormant-str_utils-apis-18) |
| General | M12 | Decide whether CLI parsers stay separate (#19) | Carry-forward | Open | No | D2 | A dated owner decision selects Keep or Generalize; [detail](#m12---decide-whether-cli-parsers-stay-separate-19) |

### Backlog Details

#### M1 - Prevent destructive UDS server path unlink (#8)

Origin: bef067f / M1
Identity History: none
GitHub Issue: [#8](https://github.com/jeonghanlee/con/issues/8)
Status: Deferred

##### Summary

The UDS server unconditionally unlinks its bind path, which can delete a non-socket file and leaves a check-to-bind race.

##### Scope

Before binding, inspect an existing path, unlink only a socket, reject other file types, and check the unlink result.

Out of scope: automatic assignment from Backlog and broader UDS server lifecycle changes from issue #9.

##### Completion Criteria

- A server start on an existing regular file fails without deleting the file.
- A stale socket path can still be removed and rebound.
- Required UDS server regressions pass after a dated reopening decision.

##### Dependencies And Decisions

- D1 defers this work. Resume as Not started only after a new dated owner decision.

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

- Deferred by D1; no implementation evidence.

##### GitHub Projection

Title: UDS server: destructive unlink of a non-socket plus TOCTOU
Labels: `bug`, `area/uds`, `P2-medium`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `bug`, `area/uds`, `P2-medium`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:08Z

#### M2 - Remove the UDS server socket on exit (#9)

Origin: bef067f / M2
Identity History: none
GitHub Issue: [#9](https://github.com/jeonghanlee/con/issues/9)
Status: Deferred

##### Summary

The UDS server closes its descriptor on exit but leaves its owned socket node on disk, forcing the next start to clean stale state.

##### Scope

Track the bound UDS path and unlink the owned socket during normal and handled termination cleanup.

Out of scope: unlinking paths not owned by the running server and automatic assignment from Backlog.

##### Completion Criteria

- A clean server exit removes its socket node.
- Cleanup never removes a replacement path that the process does not own.
- UDS server lifecycle tests pass after a dated reopening decision.

##### Dependencies And Decisions

- D1 defers this work. Coordinate with M1 if both are reopened.

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

- Deferred by D1; no implementation evidence.

##### GitHub Projection

Title: UDS server leaves stale socket on exit
Labels: `bug`, `area/uds`, `P2-medium`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `bug`, `area/uds`, `P2-medium`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:12Z

#### M3 - Add UDS peer identity and socket permissions (#10)

Origin: bef067f / M3
Identity History: none
GitHub Issue: [#10](https://github.com/jeonghanlee/con/issues/10)
Status: Deferred

##### Summary

The UDS server accepts local clients without logging peer credentials and relies on ambient defaults for socket-node permissions.

##### Scope

Retrieve Linux peer PID and UID with `SO_PEERCRED`, log them through the existing server path, and apply an owner-approved explicit socket mode.

Out of scope: defining the site access policy without owner input and automatic assignment from Backlog.

##### Completion Criteria

- The server logs the real connecting peer PID and UID.
- The socket node has the accepted mode independent of the caller's ambient umask.
- Access and UDS server regressions pass after reopening.

##### Dependencies And Decisions

- D1 defers this work; the socket mode remains an owner decision when reopened.

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

- Deferred by D1; no implementation evidence.

##### GitHub Projection

Title: UDS server: log peer SO_PEERCRED and set socket-file permissions
Labels: `enhancement`, `area/uds`, `P2-medium`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `enhancement`, `area/uds`, `P2-medium`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:16Z

#### M4 - Replace legacy host lookup for IPv6 (#11)

Origin: bef067f / M4
Identity History: none
GitHub Issue: [#11](https://github.com/jeonghanlee/con/issues/11)
Status: Deferred

##### Summary

The TCP client and server use legacy host lookup APIs, lack IPv6 support, and size one server-side hostname buffer from a pointer rather than a hostname limit.

##### Scope

Replace legacy lookup with `getaddrinfo` and `getnameinfo`, use protocol-correct address iteration, and size names for `NI_MAXHOST`.

Out of scope: changing default client/server direction and automatic assignment from Backlog.

##### Completion Criteria

- The TCP client connects to an IPv6 endpoint through the shipped code.
- The TCP server logs a complete peer name or numeric address without pointer-sized truncation.
- Existing IPv4 TCP behavior remains compatible.

##### Dependencies And Decisions

- D1 defers this TCP client and server work.

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

- Deferred by D1; no implementation evidence.

##### GitHub Projection

Title: Replace gethostby with getaddrinfo/getnameinfo for IPv6
Labels: `enhancement`, `P2-medium`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `enhancement`, `P2-medium`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:20Z

#### M5 - Remove AF_UNIX SO_REUSEADDR (#12)

Origin: bef067f / M5
Identity History: none
GitHub Issue: [#12](https://github.com/jeonghanlee/con/issues/12)
Status: Deferred

##### Summary

The AF_UNIX server branch sets `SO_REUSEADDR`, although UDS pathname reuse is controlled by filesystem cleanup rather than this socket option.

##### Scope

Remove the ineffective option from the AF_UNIX branch or record a new evidence-backed Keep decision.

Out of scope: TCP `SO_REUSEADDR`, socket-path cleanup design, and automatic assignment from Backlog.

##### Completion Criteria

- The owner accepts Remove or Keep after current Linux behavior is verified.
- If removed, the real UDS server still binds, accepts a client, and restarts according to its cleanup contract.

##### Dependencies And Decisions

- D1 defers this work; M1 and M2 own related path lifecycle behavior.

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
| T2 | Lifecycle | Restart the real server on the same pathname under the accepted M1/M2 cleanup contract. | Linux test host | Restart outcome matches the explicit socket-path lifecycle design. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Linux test host | Pending | none |
| T2 | Not run | Linux test host | Pending | none |

##### Closure Evidence

- Deferred by D1; no implementation evidence.

##### GitHub Projection

Title: SO_REUSEADDR is a no-op on AF_UNIX
Labels: `P3-low`, `area/uds`, `refactor`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `P3-low`, `area/uds`, `refactor`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:23Z

#### M6 - Correct minor UDS server defects (#13)

Origin: bef067f / M6
Identity History: none
GitHub Issue: [#13](https://github.com/jeonghanlee/con/issues/13)
Status: Deferred

##### Summary

The UDS accept path contains a misspelled diagnostic, uses raw `read` where the core uses EINTR-aware `readn`, and casts an `int` address length to `socklen_t *`.

##### Scope

Correct the diagnostic text, use a real `socklen_t` variable, and adopt the accepted read behavior consistently.

Out of scope: refactoring both server loops and automatic assignment from Backlog.

##### Completion Criteria

- The accept call receives a correctly typed address length.
- The accepted read behavior handles EINTR consistently and diagnostics use correct text.
- UDS server behavior remains compatible.

##### Dependencies And Decisions

- D1 defers this work; coordinate with M7 if the accept loops are generalized.

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

- Deferred by D1; no implementation evidence.

##### GitHub Projection

Title: UDS server minor: typo, read vs readn, socklen cast
Labels: `P3-low`, `area/uds`, `refactor`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `P3-low`, `area/uds`, `refactor`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:28Z

#### M7 - Evaluate shared UNIX and TCP accept-loop code (#14)

Origin: bef067f / M7
Identity History: none
GitHub Issue: [#14](https://github.com/jeonghanlee/con/issues/14)
Status: Deferred

##### Summary

The UNIX and TCP server accept loops duplicate control flow but differ in address handling and peer-name resolution. Both copies currently agree.

##### Scope

Re-evaluate Generalize versus Keep against the current code, and generalize only if one shared abstraction preserves both real server paths without obscuring transport-specific behavior.

Out of scope: forcing a refactor without an owner fate decision and automatic assignment from Backlog.

##### Completion Criteria

- The owner records a dated Generalize or Keep decision from current evidence.
- If generalized, UNIX and TCP server behavior is equivalent before and after through real clients.

##### Dependencies And Decisions

- D1 defers this work; coordinate reopened server fixes before deciding the abstraction boundary.

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

- Deferred by D1; no implementation evidence.

##### GitHub Projection

Title: Deduplicate UNIX and TCP server accept loops
Labels: `P3-low`, `refactor`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `P3-low`, `refactor`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:31Z

#### M8 - Reset the hexa line counter per server connection (#17)

Origin: bef067f / M8
Identity History: none
GitHub Issue: [#17](https://github.com/jeonghanlee/con/issues/17)
Status: Deferred

##### Summary

A static hexa line-wrap counter in `con_core` persists across sequential server connections, so a later client can begin with the previous client's partial line state.

##### Scope

Make the line counter local to one `con_core` connection and preserve the existing hexa output format.

Out of scope: issue #16's duplicated output blocks and automatic assignment from Backlog.

##### Completion Criteria

- Two sequential real server clients each begin hexa output at a fresh line boundary.
- Existing `-X` and `-Y` output remains byte-compatible apart from the corrected connection boundary.

##### Dependencies And Decisions

- D1 defers this server-only work. The dated Keep decision for issue #16 remains in `docs/CLOSED_DOORS.md`.

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

- Deferred by D1; no implementation evidence.

##### GitHub Projection

Title: static term_cnt not reset across server connections
Labels: `bug`, `P3-low`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `bug`, `P3-low`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:40Z

#### M9 - Define flagless host:port server direction (#21)

Origin: bef067f / M9
Identity History: none
GitHub Issue: [#21](https://github.com/jeonghanlee/con/issues/21)
Status: Deferred

##### Summary

A flagless `host:port` target selects server mode and binds `INADDR_ANY`, discarding the host prefix despite a contradictory source comment.

##### Scope

Choose and document one intentional flagless direction: current server behavior, conventional client behavior, or explicit `-c` and `-s` only.

Out of scope: automatic assignment from Backlog.

##### Completion Criteria

- A dated owner decision defines flagless `host:port` direction and compatibility policy.
- Accepted behavior and help documentation agree with the shipped client/server path.

##### Dependencies And Decisions

- D1 defers this work.
- D3 preserves current flagless behavior until the direction decision is made.

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

- Deferred by D1 and D3; no implementation evidence.

##### GitHub Projection

Title: Flagless host:port binds a server and silently discards the host
Labels: `bug`, `P3-low`, `area/uds`, `closed-door`
GitHub Milestone: `Closed Door`
Observed State: open
Observed Labels: `bug`, `P3-low`, `area/uds`, `closed-door`
Observed Milestone: `Closed Door`
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:51Z

#### M10 - Correct missing-argument errors for log flags (#15)

Origin: bef067f / M10
Identity History: none
GitHub Issue: [#15](https://github.com/jeonghanlee/con/issues/15)
Status: Open

##### Summary

The `-l` and `-a` missing-argument paths report that a baud rate is required even though each option expects a filename.

##### Scope

Correct both diagnostics and add permanent CLI error regressions.

Out of scope: broader option-parser refactoring and automatic assignment from Backlog.

##### Completion Criteria

- Both missing-argument cases identify a filename requirement and return nonzero.
- The complete error-handling suite passes.

##### Dependencies And Decisions

- D2 keeps this work open until a dated owner assignment decision.

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
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:35Z

#### M11 - Decide the fate of dormant str_utils APIs (#18)

Origin: bef067f / M11
Identity History: none
GitHub Issue: [#18](https://github.com/jeonghanlee/con/issues/18)
Status: Open

##### Summary

Most of `str_utils` is not referenced by either binary, while `filter_colors` overlaps con's inline color filtering and `str::unescape` remains used by `send_rs232`.

##### Scope

Choose Keep-as-library or Discard-unused from current consumers, then preserve the required `send_rs232` API and build contract.

Out of scope: deleting APIs without an owner fate decision and automatic assignment from Backlog.

##### Completion Criteria

- A dated owner decision records Keep or Discard with current call-site evidence.
- Any accepted change preserves the real `send_rs232` unescape path and both binaries build.

##### Dependencies And Decisions

- D2 keeps this work open until a dated owner fate decision.

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
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:44Z

#### M12 - Decide whether CLI parsers stay separate (#19)

Origin: bef067f / M12
Identity History: none
GitHub Issue: [#19](https://github.com/jeonghanlee/con/issues/19)
Status: Open

##### Summary

`con` and `send_rs232` duplicate their main option-parsing skeleton and baud-rate parsing, but they are independent programs with different option surfaces.

##### Scope

Choose Keep-separate or Generalize from current behavior and maintenance cost, then preserve both public CLIs if any shared parser is accepted.

Out of scope: coupling the tools without an owner fate decision and automatic assignment from Backlog.

##### Completion Criteria

- A dated owner decision records Keep or Generalize with current option maps.
- If generalized, both binaries preserve argument parsing, diagnostics, and baud handling through real CLI tests.

##### Dependencies And Decisions

- D2 keeps this work open until a dated owner fate decision.

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
Last Compared: 2026-09-01T06:45:35Z; issue updated 2026-09-01T06:03:48Z

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-09-01 | `bef067f99983b282cd06aff2cff8b2ec12e87f31` |
