# con — Test Plan 1.1.0

Cycle test plan for the 1.1.0 milestones M1-M4 (work order and issue references
in [`milestone.md`](milestone.md)). Drafted at cycle start (2026-06-16); cases
discovered during the work are added under "Added During Cycle". Before the
final release this plan is executed in full and remains the cycle's verification
record, preserved in the `1.1.0` tag.

## Verification Layers

Each milestone is verified in two layers:

1. **Change-specific verification** — designed per milestone, with depth chosen
   by blast radius: a static read, a targeted manual run, or a new automated
   case driven through the `script(1)`/PTY harness in `tests/`.
2. **Automated suites** — `tests/run-all-tests.bash` (the `test-*.bash` set:
   error-handling, version, uds-connect, uds-echo, uds-exit, uds-readonly,
   uds-peer-disconnect, log-output, color-filter, hexa-output, throughput).
   Where an issue's acceptance criteria name concrete cases, the cases are added
   to the suites as permanent regression assets, not run as one-off checks.

Suite baseline at cycle start: the UDS client suite (connect/echo/exit/readonly/
peer-disconnect) is green and is the P1 verification baseline. Ctrl-T diagnostic
coverage is manual only — `0x14` is consumed by the PTY line discipline under
`script(1)`, so the H2 collision case cannot be automated.

The milestone register tracks each verification as `M<n>.T<k>` subs that map
onto this plan: T1 = "Change-specific verification", T2 = "Suite coverage and
new cases", T3 = the milestone's row in the Dependency Re-run Matrix. Sub status
is authoritative in each issue's Verification checkbox list on GitHub and
mirrored by the register.

## Per-Milestone Verification

| M | Issue | Change-specific verification | Suite coverage and new cases |
| :--- | :--- | :--- | :--- |
| M1 | U3 | `con -c /tmp/a:b.sock` against an echo server on that path connects as UDS (not "Invalid port"); the auto-detect comment matches the code after the fix. | New `test-uds-connect` case: a colon-bearing socket path connects and echoes. UDS client suite stays green. |
| M2 | U6 | `con -c <path longer than sizeof(sun_path)-1>` errors with a clear message instead of silently connecting to the truncated path; a valid-length path is unaffected. | New error-suite case pinning the over-length rejection. UDS suite stays green. |
| M3 | U7 | connect and echo round-trip identical before and after switching to `SUN_LEN`, both client and server. Re-runs M2's suite (same lines edited). | Covered by `test-uds-connect` / `test-uds-echo`; no new case required. |
| M4 | H2 | `con -x ctrl/t -c <sock>` warns or rejects the exit/diagnostic key collision rather than silently disabling the diagnostic. Automation blocked (0x14 PTY-consumed); verified manually via `tests/manual-test-diag-hotkey.bash`. | New error-suite case for the `-x ctrl/t` rejection if the chosen design rejects at parse time (parse-time check is automatable; runtime is not). |

## Dependency Re-run Matrix

A milestone that passed individually can be invalidated by later work on a
shared surface. The matrix schedules the re-verification points; the batch
re-run at the release gate closes everything against the released tree.

| Trigger | Re-run | Shared surface |
| :--- | :--- | :--- |
| M3 (U7) | M2.T2 (UDS suite) | sun_path / servlen lines con.cpp:818-819, 644-645 |
| M1 (U3) | UDS client connect/echo | socket mode-detection shared with the client branch |

## Release Gate

Executed in order before the final 1.1.0 release:

1. **Cycle batch re-run** — all M1-M4 change-specific verifications against the
   final tree, the first state in which all four changes coexist.
2. **Full suite** — `make test` (`tests/run-all-tests.bash`) green on the dev
   host with both echo-server backends (socat and the compiled `echo_server`).
3. **Manual diagnostic** — `tests/manual-test-diag-hotkey.bash` (echo and
   `--flood`) for the Ctrl-T path, including the M4 collision check.
4. **Version** — `GNUmakefile` CON_VERSION bumped to `1.1.0`; `con -V` reports
   `1.1.0`.

## Added During Cycle

Cases discovered during the work are recorded here with the date and the
milestone that surfaced them.

(none yet)
