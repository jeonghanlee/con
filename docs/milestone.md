# con — Milestone Register

Single, repository-local source of truth for milestone and carry-forward
status. Every agent and contributor reads this file instead of chat history or
memory. GitHub milestone state and issue `Closes`/`Refs` footers are
authoritative; this register reconciles them into one readable view.

**Mode:** remote-authoritative — GitHub issues carry the verification checkbox
lists; this register mirrors them. Tracker: github.com/jeonghanlee/con.

**Release convention:** one unified register, not a per-version file. On each
release the register is cleared and restarted for the next cycle; the released
milestone's full record is preserved in the matching git tag
(`git show <tag>:docs/milestone.md`).

**1.1.0 release target:** owner to set the GitHub `1.1.0` due date. 1.0.0 is
released (commit `ff9ba8c`). This cycle hardens the UDS **client** path (P1 —
con's primary mode, attaching to a procServ UNIX-domain socket); the UDS server
and peripheral items are deferred to `Backlog`. Version is `1.1.0-dev`
(`GNUmakefile` CON_VERSION).

**Next session entry point:** M4 (#7, H2) — M1 (#4, U3), M2 (#5, U6), M3 (#6, U7) done. Work order M1-M4 + M5 gate, set
2026-06-16: standalone U3 (M1) and H2 (M4) are independent; the co-located
sun_path pair M2 (U6 validation) then M3 (U7 SUN_LEN) — M3 rides M2 because
both edit con.cpp:841-842 (client) / 667-668 (server). The cycle test plan is
[`testplan_1.1.0.md`](testplan_1.1.0.md).

## Active Register

Each milestone row is followed by its verification subs (`M<n>.T<k>`):
T1 = change-specific verification, T2 = suite/regression cases, T3 = re-run of
an earlier milestone's verification on a shared surface. Sub procedures are in
[`testplan_1.1.0.md`](testplan_1.1.0.md). Each issue carries the same subs as a
checkbox list in its Verification section on GitHub — GitHub is authoritative
for sub status; this register mirrors it.

| M | Topic | Work unit | Type | Status | Evidence or next action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| M1 | 1.1.0 | #4 U3 UDS path containing ':' misrouted to TCP | Coherence + bug | Done | tcp_separator() at con.cpp:805/620 routes a '/'-bearing or non-numeric-port target as UNIX; 591-593 comment aligned to code. Scope held to #4; -u flag / 588 / 577 / test-suite repair split to Backlog #20-23. Closes #4 (fires at release merge). |
| M1.T1 | 1.1.0 | -c to a colon-bearing path connects as UDS, not TCP | Test sub | Done | test-uds-connect colon block: echo round-trip + no Invalid port, client and -s. |
| M1.T2 | 1.1.0 | UDS client suite green (connect/echo/exit/readonly/peer-disconnect) | Test sub | Done | make test 11/11 suites green on release-1.1.0. |
| M2 | 1.1.0 | #5 U6 sun_path over 108B silently truncated | Bug | Done | Guard at con.cpp:670 (server) / 849 (client) rejects a path of sizeof(sun_path) bytes or more. Committed ce10568 on release-1.1.0; Closes #5 fires at release merge. |
| M2.T1 | 1.1.0 | -c/-s to a >108B path errors instead of truncating | Test sub | Done | test-uds-sun-path-guard.bash: over-length -c/-s exit non-zero, print the guard message, and (server) create no socket node. |
| M2.T2 | 1.1.0 | UDS suite green | Test sub | Done | make test 12/12 suites green on release-1.1.0 (ce10568). |
| M3 | 1.1.0 | #6 U7 servlen non-standard vs SUN_LEN | Refactor | Done | servlen = SUN_LEN(&serv_addr) at con.cpp:679 (server) / 858 (client); a file-scope static_assert pins offsetof(sun_path) == sizeof(sun_family). Behavior identical. Committed e118961; Closes #6 fires at release merge. |
| M3.T1 | 1.1.0 | connect/echo behaviorally identical with SUN_LEN | Test sub | Done | before/after full-suite diff: all PASS/FAIL verdicts identical (only timing noise). |
| M3.T3 | 1.1.0 | re-run M2.T2 (same lines edited) | Test sub | Done | full UDS suite green on release-1.1.0 (e118961), incl. the 107-byte boundary. |
| M4 | 1.1.0 | #7 H2 Ctrl-T diagChr vs exitChr collision, no guard | Enhancement | Open | con.cpp:330 (precedence), 51 (diagChr); warn or reject when -x resolves to diagChr. enhancement, P3-low, area/uds. |
| M4.T1 | 1.1.0 | -x ctrl/t warns or rejects collision (manual: 0x14 PTY-consumed) | Test sub | Open | — |
| M4.T2 | 1.1.0 | exit-key suite green (test-uds-exit) | Test sub | Open | — |
| M5 | 1.1.0 | release gate (no GitHub issue; testplan_1.1.0 "Release Gate") | Release gate | Open | Runs after M1-M4; gates the master merge, 1.1.0 tag, and version bump. |
| M5.T1 | 1.1.0 | batch re-run of M1-M4 change-specific verifications on the final tree | Test sub | Open | — |
| M5.T2 | 1.1.0 | full tests/run-all-tests.bash green; -V reports 1.1.0 | Test sub | Open | — |

**Tally:** milestones Open 2 (1 work + 1 gate) · Done 3 · test subs Open 3 · Done 6

## Milestone 1.1.0

P1 — UDS client path hardening. GitHub milestone `1.1.0` (to be created). U3 and
H2 are standalone; U6/U7 are a co-located pair (same sun_path lines), U7 riding
U6. The client path is already hardened by 1.0.0 (`-r`, the Ctrl-T diagnostic,
`poll()`/`POLLRDHUP`); these are the remaining client-path defects.

| Issue | Title | Priority | Notes |
| --- | --- | --- | --- |
| [#4](https://github.com/jeonghanlee/con/issues/4) (M1) | UDS path containing ':' is misrouted to TCP | bug, P1 | con.cpp:805-806, 588-595. A UDS path with a colon parses as host:port and fails; the auto-detect comment ("client") contradicts the code (server). Disambiguate path vs host:port. |
| [#5](https://github.com/jeonghanlee/con/issues/5) (M2) | sun_path silently truncated past 108 bytes | enhancement, P1 | con.cpp:841 (also 667). strncpy bounds at sizeof(sun_path)-1 with no overflow signal; an over-length path connects to a different path silently. Reject with an error. |
| [#6](https://github.com/jeonghanlee/con/issues/6) (M3) | servlen computed non-standardly vs SUN_LEN | refactor, P3-low | con.cpp:842 (also 668). Hand-rolled length works only because sun_family is the first member; switch to SUN_LEN. Rides M2 (same lines). |
| [#7](https://github.com/jeonghanlee/con/issues/7) (M4) | Ctrl-T diagnostic key can collide with the exit key | enhancement, P3-low | con.cpp:330, 51. -x ctrl/t makes exitChr == diagChr; exit wins by precedence and the diagnostic is silently disabled. Warn or reject the collision. |

## Backlog

Deferred to the `Backlog` GitHub milestone — UDS server and peripheral items,
not in the 1.1.0 cycle. Each is an individual issue: U1 #8, U2 #9, U4 #10,
B2/C2 #11, U5 #12, U8 #13, O2 #14, C1 #15, O3 #16, H1 #17, O1 #18, O4 #19.
The former umbrella #3 was superseded by #8/#10/#11 and closed.

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

## Examined-Keep Ledger

Coherence-sweep findings examined and deliberately left as-is (2026-06-16
sweep), carried forward so the next sweep closes them fast instead of
re-opening the same seams.

| ID | Finding | Why Keep |
| --- | --- | --- |
| K1 | Printable-ASCII predicate `c>=' ' && c<='~'` duplicated (con.cpp:283, str_utils.cpp:121, send_rs232.cpp:239). | Range agrees; the substitute char differs by purpose ('.', `\xNN`, '?'). Principled divergence. |
| K2 | exitChr parse (con.cpp:523-526) vs render (`exitChr+0x40`, multiple sites). | Inverse modulo case-folding; the two sides agree. |

## Notes

- The `Backlog` GitHub milestone holds the deferred items as individual issues
  #8-#19; the former umbrella #3 was superseded and closed.
- The cycle test plan is [`testplan_1.1.0.md`](testplan_1.1.0.md) — per-milestone
  verification, dependency re-run matrix, and release-gate sequence. Test plans
  are V&V artifacts, not milestone register items.
- The 1.0.0 record is preserved in git history (commit `ff9ba8c`).
