# con — Milestone Register

Single, repository-local source of truth for milestone and carry-forward
status. Every agent and contributor reads this file instead of chat history or
memory. The canonical register owns scope, status, plans, tests, results, and
projected issue content. GitHub owns live issue and milestone metadata; this
register records observed metadata and projection drift.

**Mode:** canonical-authoritative. Tracker: github.com/jeonghanlee/con.

**Release convention:** one unified register, not a per-version file. On each
release the register is cleared and restarted for the next cycle; the released
milestone's full record is preserved in the matching git tag
(`git show <tag>:docs/milestone.md`).

**Current release:** 1.1.0 was released on 2026-07-04 (merge `0dfe4f2`, tag
`1.1.0`). The current source sets `GNUmakefile` `CON_VERSION` to `1.1.0`;
the UDS server and peripheral items remain deferred to `Backlog`.

**Next session entry point:** **1.1.0 RELEASED 2026-07-04** (merge `0dfe4f2`
--no-ff, annotated tag `1.1.0`, GitHub release published with curated notes,
milestone closed 8/8; release issue bodies reconciled on 2026-08-12. No prior
release branch to delete (1.0.0 released from master). The next cycle (1.1.1 or
1.2.0) is NOT
yet opened — deferred by the owner; opening it (new release branch, register
restart, dev bump, per the release-cycle procedure and `release-gate.md`'s
cycle-open checklist) is the next session's first decision. This register's
1.1.0 record is preserved in the `1.1.0` tag.

## Active Register

Each milestone row is followed by its verification subs (`M<n>.T<k>`):
T1 = change-specific verification, T2 = suite/regression cases, T3 = re-run of
an earlier milestone's verification on a shared surface. Sub procedures are in
[`testplan_1.1.0.md`](testplan_1.1.0.md). Verification Results below come from
observed runs of the shipped code and test paths. GitHub issue bodies are
projections; live state, labels, milestone assignment, and update time are
observed metadata.

| M | Topic | Work unit | Type | Status | Evidence or next action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| M1 | 1.1.0 | #4 U3 UDS path containing ':' misrouted to TCP | Coherence + bug | Complete | `tcp_separator()` at con.cpp:419-433, called at 667 and 857, routes slash-bearing or non-numeric-port targets as UNIX. Scope held to #4; issues #20-#23 and #25 remain in Backlog. Closes #4 at release merge. |
| M1.T1 | 1.1.0 | -c to a colon-bearing path connects as UDS, not TCP | Test sub | Complete | 2026-08-12: tests/test-uds-connect.bash passed 5/5 assertions; the colon-path client and server checks used the compiled echo_server backend. |
| M1.T2 | 1.1.0 | UDS client suite green (connect/echo/exit/readonly/peer-disconnect) | Test sub | Complete | 2026-08-12: bash tests/run-all-tests.bash passed 14/14 suites under socat; release evidence also covers both backends. |
| M2 | 1.1.0 | #5 U6 sun_path over 108B silently truncated | Bug | Complete | `PERR` guards at con.cpp:694 (server) and 873 (client) reject a path of sizeof(sun_path) bytes or more. Committed ce10568 on release-1.1.0; Closes #5 at release merge. |
| M2.T1 | 1.1.0 | -c/-s to a >108B path errors instead of truncating | Test sub | Complete | 2026-08-12: tests/test-uds-sun-path-guard.bash passed 10/10 assertions, including rejection and the 107-byte boundary. |
| M2.T2 | 1.1.0 | UDS suite green | Test sub | Complete | 2026-08-12: bash tests/run-all-tests.bash passed 14/14 suites under socat; release evidence also covers both backends. |
| M3 | 1.1.0 | #6 U7 servlen non-standard vs SUN_LEN | Refactor | Complete | `servlen = SUN_LEN(&serv_addr)` at con.cpp:697 (server) and 876 (client); static_assert at 46-47 pins the required layout assumption. Behavior identical. Committed e118961; Closes #6 at release merge. |
| M3.T1 | 1.1.0 | connect/echo behaviorally identical with SUN_LEN | Test sub | Complete | Before/after full-suite comparison recorded identical PASS/FAIL verdicts, with timing as the only difference. |
| M3.T3 | 1.1.0 | re-run M2.T2 (same lines edited) | Test sub | Complete | 2026-08-12: bash tests/run-all-tests.bash passed 14/14 suites under socat, including the 107-byte boundary. |
| M4 | 1.1.0 | #7 H2 Ctrl-T diagChr vs exitChr collision, no guard | Enhancement | Complete | Guard at con.cpp:574 rejects an -x value whose finalized byte equals diagChr (0x14); numeric truncation such as -x 0x114 is also caught. ADR 0002 records the reject decision. Committed 9fcf724; Closes #7 at release merge. |
| M4.T1 | 1.1.0 | -x ctrl/t rejects collision (parse-time); Ctrl-T diagnostic automated (#24) | Test sub | Complete | 2026-08-12: test-error-handling.bash passed 12/12 assertions and test-uds-diag.bash passed 3/3 assertions under socat. The diagnostic path covers a solitary 0x14 pause and a follow-up resume key (#24, #26). |
| M4.T2 | 1.1.0 | exit-key suite green (test-uds-exit) | Test sub | Complete | 2026-08-12: tests/test-uds-exit.bash passed 2/2 assertions under socat. |
| M5 | 1.1.0 | release gate (no GitHub issue; testplan_1.1.0 "Release Gate", 5 steps) | Release gate | Complete | **Gate passed and release executed 2026-07-04**: steps 1-4 verified twice on the final trees (14/14 both backends; downstream 11/11 then 15/15 with the DEPS pin on both goldens); step 5 sequence - changelog 11cdd5c, bump 025e57, merge 0dfe4f2 (--no-ff), annotated tag 1.1.0, GitHub release published, milestone closed 8/8. Environment pinned at epics-ioc-runner 1.2.0 (6c50604) per the Gate Dependency Pin Ledger. |
| M5.T1 | 1.1.0 | batch re-run of M1-M4 change-specific verifications on the final tree | Test sub | Complete | 2026-07-02: full suite carries every M1-M4 change-specific case on the final tree (7dff13c): 14/14 suites, both backends (socat, echo_server). Gate step 3 evidence alongside: pause/resume automated in-suite; flood recv-q > 0 reproduced (8192 bytes; K3 amended, 7dff13c). |
| M5.T2 | 1.1.0 | full tests/run-all-tests.bash green (14 suites incl. test-uds-multi-client); -V reports 1.1.0 | Test sub | Complete | 2026-08-12: current HEAD e0394fa reports `con version 1.1.0 (e0394fa)` and bash tests/run-all-tests.bash passed 14/14 suites under socat. Release evidence covers both backends. |
| M5.T3 | 1.1.0 | downstream integration (#27): multiuser S4+S10 + two-con check with the candidate pinned via IOC_RUNNER_CON_TOOL | Test sub | Complete | PASS 2026-07-02, both goldens (testbed-rocky8/debian13-iocrunner on alsucl-psrv3), 11/11 each via tests/release-gate4-downstream.bash. Candidate 1.1.0-dev 7dff13c at /opt/con-rc/con, pinned per principal invocation and asserted by -V inside opb's context (the stale con 1.0.0 on the fixed path was correctly bypassed). S10 layered access (opb attach OK; obs denied at conf resolution; inspect root-gated); two-con shared console verified both directions; S4 remove-under-attach ended opb's session in 0 s (EOF), socket dir and unit gone. Fixtures opa/opb/obs provisioned per run. |

**Tally:** milestones Open 0 · Complete 5 · test subs Open 0 · Complete 11

## Milestone 1.1.0

P1 - UDS client path hardening. GitHub issue metadata observed on 2026-08-12
places eight closed issues (#4-#7, #24, #26-#28) in milestone `1.1.0`. U3 and
H2 are standalone; U6/U7 are a co-located pair (same sun_path lines), U7 riding
U6. The client path is already hardened by 1.0.0 (`-r`, the Ctrl-T diagnostic,
`poll()`/`POLLRDHUP`); these were the remaining client-path defects.

| Issue | Title | Priority | Notes |
| --- | --- | --- | --- |
| [#4](https://github.com/jeonghanlee/con/issues/4) (M1) | UDS path containing ':' is misrouted to TCP | bug, P1 | `con.cpp:419-433`, call sites `667` and `857`. `tcp_separator()` treats slash-bearing and non-numeric-port targets as UNIX; the colon-path test passes. |
| [#5](https://github.com/jeonghanlee/con/issues/5) (M2) | sun_path silently truncated past 108 bytes | enhancement, P1 | `con.cpp:694` and `873`. `PERR` rejects paths at or above `sizeof(sun_path)` before copying; the guard and 107-byte boundary tests pass. |
| [#6](https://github.com/jeonghanlee/con/issues/6) (M3) | servlen computed non-standardly vs SUN_LEN | refactor, P3-low | `con.cpp:697` and `876` use `SUN_LEN`; static_assert `con.cpp:46-47` pins the layout assumption. |
| [#7](https://github.com/jeonghanlee/con/issues/7) (M4) | Ctrl-T diagnostic key can collide with the exit key | enhancement, P3-low | `diagChr` is `con.cpp:57`, the poll order is `336-338`, and the parse-time guard is `574`. `-x ctrl/t`, `0x14`, and `0x114` are rejected. |
| [#24](https://github.com/jeonghanlee/con/issues/24) (M4.T1) | Automate the Ctrl-T diagnostic hotkey test and correct the PTY-consumed claim | documentation, P3-low | `tests/test-uds-diag.bash` passes the launch, solitary Ctrl-T, and diagnostic assertions. |
| [#26](https://github.com/jeonghanlee/con/issues/26) (M4.T1) | test-uds-diag.bash asserts the diagnostic pause but not the resume; add a resume assertion | enhancement, P3-low | `tests/test-uds-diag.bash` asserts that the post-diagnostic marker appears after the resume key. |
| [#27](https://github.com/jeonghanlee/con/issues/27) (M5.T3) | Add a downstream integration step (epics-ioc-runner) to the release gate | documentation, P2-medium | Downstream S4, S10, and the two-con shared-console check passed on both goldens; candidate selection is pinned by `IOC_RUNNER_CON_TOOL`. |
| [#28](https://github.com/jeonghanlee/con/issues/28) (M5.T2) | Add a multi-client UDS test: concurrent attach, detach isolation, -r mix, server-death EOF | enhancement, P2-medium | `tests/test-uds-multi-client.bash` is included in the 14-suite runner and passed its 9 assertions under socat. |

### GitHub Reconcile

Observed 2026-08-12 from live issue metadata via `gh issue view`: #4-#7, #24,
and #26-#28 remain `CLOSED` and assigned to `1.1.0`; their existing titles and
labels were preserved. The eight body rewrites now match the canonical drafts;
all former unchecked verification items are checked and every body contains
observed `Verification Results`.

| Issue | State | Milestone | GitHub updatedAt |
| --- | --- | --- | --- |
| #4 | CLOSED | 1.1.0 | 2026-08-13T06:47:30Z |
| #5 | CLOSED | 1.1.0 | 2026-08-13T06:47:38Z |
| #6 | CLOSED | 1.1.0 | 2026-08-13T06:47:48Z |
| #7 | CLOSED | 1.1.0 | 2026-08-13T06:47:56Z |
| #24 | CLOSED | 1.1.0 | 2026-08-13T06:48:04Z |
| #26 | CLOSED | 1.1.0 | 2026-08-13T06:48:12Z |
| #27 | CLOSED | 1.1.0 | 2026-08-13T06:48:21Z |
| #28 | CLOSED | 1.1.0 | 2026-08-13T06:48:30Z |

## Backlog

Deferred to the `Backlog` GitHub milestone - UDS server and peripheral items,
not in the 1.1.0 cycle. The release-independent backlog currently includes
issues #8-#23 and #25; issue #24 is part of `1.1.0`. The former umbrella #3 was
superseded by #8/#10/#11 and is closed.

| ID | Topic | Work unit | Type | Priority | Notes |
| --- | --- | --- | --- | --- | --- |
| U1 | UDS server | destructive unlink of a non-socket + TOCTOU | bug | P2 (severity HIGH) | con.cpp:646-648; #3 B1. Guard via stat()/S_ISSOCK before unlink; check rc. |
| U2 | UDS server | server leaves stale socket on exit | bug | P2 | finish() con.cpp:125-149; unlink own sun_path on exit (root cause of U1's pre-bind unlink). |
| U4 | UDS server | peer authn SO_PEERCRED + socket-file perms | enhancement | P2 | con.cpp:634-648; #3 B3. Log PID/UID, set umask/fchmod. |
| U5 | UDS server | SO_REUSEADDR no-op on AF_UNIX | refactor | P3 | con.cpp:638; dead call, symptom of O2. |
| U8 | UDS server | typo "unkonown", read vs readn, int to socklen_t* | refactor | P3 | con.cpp:686, 698, 679. |
| O2 | Structure | UNIX and TCP server accept loops near-identical | refactor | P3 | con.cpp:659-706 / 747-800; Generalize vs Keep. |
| C1 | CLI | -l/-a missing-arg error says "baud rate" | bug | P3 | con.cpp:436, 450; fix message text. |
| B2/C2 | Net resolve | gethostby* to getaddrinfo/getnameinfo (IPv6); hostname buffer sized by sizeof(ptr) | enhancement | P2 | con.cpp:774-779, 846-852; #3 B2. C2 = con.cpp:616, 777. |
| O3 | I/O core | hexa-ascii / hexa output blocks duplicated | refactor | P3 | con.cpp:276-294 / 296-312; Generalize vs Keep. |
| H1 | I/O core | static term_cnt not reset across server connections | bug | P3 | con.cpp:246; server+hexa only, cosmetic. |
| O1 | str_utils library | dormant API; filter_colors duplicates write_log | refactor | P3 | str_utils.cpp:276 / con.cpp:184-240; Keep-as-library vs Discard. |
| O4 | send_rs232 | CLI skeleton + baud parse duplicated con vs send_rs232 | refactor | P3 | con.cpp:413-567 / send_rs232.cpp:51-140; Generalize vs Keep-separate. |
| T1 | Test harness | test-common.bash resolves CON_BIN to /../con when sourced standalone (SC_TOP unset) | bug | P3 | #25. SC_TOP set by each test-*.bash, not test-common; a bare-shell source leaves CON_BIN=/../con and con never runs. Only bites interactive/standalone sourcing, not run-all-tests. Root cause of #24's false "PTY-consumed" negative. |

## Examined-Keep Ledger

Coherence-sweep findings examined and deliberately left as-is, carried forward
so the next sweep closes them fast instead of re-opening the same seams. K1-K2
from the 2026-06-16 sweep; K3-K5 from the 1.1.0 diagnostic work (#24, #26),
recorded 2026-07-01 so the same doors are not re-opened.

| ID | Finding | Why Keep |
| --- | --- | --- |
| K1 | Printable-ASCII predicate `c>=' ' && c<='~'` duplicated (con.cpp:283, str_utils.cpp:121, send_rs232.cpp:239). | Range agrees; the substitute char differs by purpose ('.', `\xNN`, '?'). Principled divergence. |
| K2 | exitChr parse (con.cpp:523-526) vs render (`exitChr+0x40`, multiple sites). | Inverse modulo case-folding; the two sides agree. |
| K3 | Flood-mode diagnostic (recv-q > 0) remains outside the automated suite (#24). | **Amended 2026-07-02.** The original verdict ("the poll loop drains the socket before the keyboard, so a fast host reads recv-q 0 -- structural race, do not re-attempt") was reasoned, never reproduced, and is false: the loop reads MAXBUF per cycle, not a full drain, so a flood backlogs the queue. Reproduced on this host: a solitary 0x14 under a yes-through-socat flood reported `recv buffer: 8192 / 212992 (3%) - NORMAL`. Flood IS automatable; it stays out of the suite only because an unbounded flood writes GBs into the PTY capture within seconds -- a bounded design (kill the flood right after the diag, or cap the capture) is needed before it becomes a suite case. Echo-mode stays the automated case; manual-test-diag-hotkey.bash --flood stays the interactive check. |
| K4 | con.cpp diagnostic pause/resume left unchanged by #24 and #26. | con.cpp:338 (pause) and 394-397 (resume) already work; #24/#26 added test coverage only, no code change. The diagnostic is test + doc work, not a con.cpp defect. |
| K5 | FIONREAD-failure diagnostic branch (con.cpp:388) is not covered by test-uds-diag.bash. | The `[diag] ioctl(FIONREAD):` path cannot fire on a connected UNIX socket, so it is unreachable in the automated test; the test asserts the `[diag] con recv buffer:` prefix (the two reachable formats) only. |

## Gate Dependency Pin Ledger

Append-only, one line per pin advancement. Process:
[`release-gate.md`](release-gate.md) "Dependency pins and advancement";
enforced values live in the DEPS preamble of
`tests/release-gate4-downstream.bash`.

| Date | Pinned runner identity | Upstream hash | Per-golden OS / sudo | Validating run |
| --- | --- | --- | --- | --- |
| 2026-07-04 | epics-ioc-runner version 1.2.0 (6c50604) | 6c50604 (tag 1.2.0) | rocky 8.10 / 1.9.5p2; debian 13 / 1.9.16p2 | Initial pin. Goldens updated in place from the unreproducible 1.2.0-dev (25f6adc-dirty) bake; gate step 4 rerun 15/15 on both goldens with con candidate 1.1.0-dev 42149b7; DEPS guard negative-tested (mismatch and set-but-empty both abort before scenarios). |

## Notes

- The `Backlog` GitHub milestone holds the deferred items as individual issues
  #8-#23 and #25; the former umbrella #3 was superseded and closed.
- The cycle test plan is [`testplan_1.1.0.md`](testplan_1.1.0.md) — per-milestone
  verification, dependency re-run matrix, and release-gate sequence. Test plans
  are V&V artifacts, not milestone register items.
- The release gate's version-independent definition is
  [`release-gate.md`](release-gate.md); each cycle's test plan instantiates it
  rather than forking it. Introduced after the 1.1.0 gate's first full run.
- The 1.0.0 record is preserved in git history (commit `ff9ba8c`).
