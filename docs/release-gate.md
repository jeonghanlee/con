# con — Release Gate (version-independent)

This is the standing definition of con's release gate. It does not belong to
any one version: every release cycle instantiates it. The per-cycle test plan
(`testplan_X.Y.Z.md`) enumerates that cycle's change-specific verifications and
carries this gate as its final section by reference — it instantiates the steps,
it does not fork them. When the gate itself must change shape, this file is
amended through the normal review process, and the change applies to every
later cycle.

Extracted from the 1.1.0 cycle's gate (`testplan_1.1.0.md` "Release Gate"),
which introduced the five-step form; its steps 1-4 were first executed
2026-07-02 on both goldens.

## The full-run contract

Every release runs the WHOLE gate — never a spot-check of the steps a cycle
happened to touch. A prior pass is not this tree's pass: the gate is the first
state in which all of a cycle's changes coexist, and the defect lives in the
seam between individually-correct changes, invisible to any single step run
alone. A null result is a result worth recording: every gate run — pass, fail,
or re-run — lands its verdict in the register's M-gate rows, so the next cycle
never re-litigates a question this one already answered.

## Where things live

| Document | Owns |
| :--- | :--- |
| This file | The gate skeleton — the five steps every release passes |
| `testplan_X.Y.Z.md` | The cycle's per-milestone verifications and re-run matrix; instantiates this gate |
| `docs/milestone.md` | Status and execution evidence — the M-gate rows mirror these steps, and the Examined-Keep ledger holds the recorded reproductions the gate cites (e.g. K3) |
| `tests/release-gate4-downstream.bash` (header) | The step 4 runbook: prerequisites, usage, provenance |
| `epics-ioc-runner/docs/testplan_multiuser.md` | The step 4 environment: golden images, user fixtures, execution harness (referenced, never restated here) |
| `git-workflow` skill, release procedure | The step 5 release sequence: merge, tag, GitHub release, milestone close, next dev cycle (referenced, never restated here) |

## The gate

Executed in order, against the release candidate, before the final release:

1. **Cycle batch re-run** — all of the cycle's change-specific verifications
   against the final tree, the first state in which every change of the cycle
   coexists. The cycle test plan enumerates them; in practice the permanent
   suites carry them (each cycle's cases land in `tests/` as regression assets,
   not one-off checks).

2. **Full suite** — `make test` (`tests/run-all-tests.bash`) green on the dev
   host under BOTH echo-server backends (socat and the compiled `echo_server`).

3. **Diagnostic** — the Ctrl-T pause/resume path is automated in-suite
   (`test-uds-diag.bash`). Verify the flood face (recv-q > 0) by a bounded
   reproduction — which counts as gate evidence only when recorded as a
   K3-style register entry (host, observed value, and the hash of the tree
   under gate — a prior cycle's reproduction does not carry over) — or by the
   interactive `manual-test-diag-hotkey.bash --flood`. (Flood is automatable;
   register Examined-Keep K3 records the amended verdict and the capture-size
   constraint that keeps it out of the suite.)

4. **Downstream integration** — con's deployed role, verified with the release
   candidate on the environment defined by `epics-ioc-runner`'s
   `docs/testplan_multiuser.md`. Driver: `tests/release-gate4-downstream.bash`
   (its header carries the runbook). The step's non-negotiables:
   - Pin the candidate for **every** principal invocation via
     `IOC_RUNNER_CON_TOOL=<absolute path>` passed through the sudo boundary; a
     PATH install or an operator-shell export is insufficient (`sudo -niu`
     resets the environment, and ioc-runner never resolves con from PATH).
   - Assert the resolved con's `-V` (candidate version + git hash) **inside
     the console-holding principal's context** before the scenarios.
   - Multiuser scenarios **S4** and **S10** pass with the candidate. The
     automated lifecycle `attach` checks verify availability only and never
     execute con — they are not con coverage.
   - **Two-con check**: two con clients on one running IOC, both typing, both
     detaching cleanly — the shared procServ console face the unit suites
     (per-client echo peers) cannot reach.
   Run on both golden images; the gate does not pass until both pass.

5. **Version and release sequence** — bump `GNUmakefile` CON_VERSION to the
   release version and confirm `con -V` reports it. Then execute the
   `git-workflow` release procedure (merge, tag, GitHub release, milestone
   close, next dev cycle); its reference owns the sequence — this file does
   not restate it.

## Cycle-open checklist

When a new cycle's `testplan_X.Y.Z.md` is drafted (release-cycle procedure),
its Release Gate section must: name this file as the gate definition, add the
cycle's own step 1 enumeration, and record any cycle-specific amendment as a
delta here — never as a silent fork in the cycle plan. Every amendment names
the cycle that introduced it (e.g. "step 4 added by 1.1.0"), so the gate's
shape stays traceable to the change that demanded it.
