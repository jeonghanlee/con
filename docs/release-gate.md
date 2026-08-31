# con - Release Gate (version-independent)

This is the standing definition of con's release gate. It does not belong to
any one version: every release cycle instantiates it in the final release
detail of `docs/milestone-<release>.md`. That detail enumerates the cycle's
change-specific reruns and applies this gate without forking it. When the gate
itself changes shape, this file is amended through the normal review process
and the change applies to every later cycle.

The five-step form was introduced by the historical 1.1.0 test plan, retained
at tag `1.1.0`; its steps 1-4 were first executed 2026-07-02 on both goldens.

## The full-run contract

Every release runs the WHOLE gate — never a spot-check of the steps a cycle
happened to touch. A prior pass is not this tree's pass: the gate is the first
state in which all of a cycle's changes coexist, and the defect lives in the
seam between individually-correct changes, invisible to any single step run
alone. A null result is a result worth recording: every gate run — pass, fail,
or re-run — lands its verdict in the canonical final release detail's Release
Verification result rows, so the next cycle never re-litigates a question this
one already answered.

## Where things live

| Document | Owns |
| :--- | :--- |
| This file | The gate skeleton - the five steps every release passes |
| `docs/milestone-<release>.md` | Cycle work, per-milestone tests, final integrated reruns, production tests, release actions, and observed evidence |
| `tests/release-gate4-downstream.bash` (header) | The step 4 runbook: prerequisites, usage, provenance |
| `epics-ioc-runner/gate/RUNBOOK.md` and `gate/drivers/` | The current upstream gate, golden-image requirements, fixtures, and execution drivers |
| `git-workflow` skill, release procedure | The step 5 release sequence: merge, tag, GitHub release, milestone close, next dev cycle (referenced, never restated here) |

## The gate

Executed in order, against the release candidate, before the final release:

1. **Cycle batch re-run** — all of the cycle's change-specific verifications
   against the final tree, the first state in which every change of the cycle
   coexists. The canonical final release detail enumerates them; in practice the permanent
   suites carry them (each cycle's cases land in `tests/` as regression assets,
   not one-off checks).

2. **Full suite** — `make test` (`tests/run-all-tests.bash`) green on the dev
   host under BOTH echo-server backends. Run the master runner once with
   `ECHO_SERVER_MODE=socat` and once with `ECHO_SERVER_MODE=echo_server`, and
   confirm each run reports the requested backend; auto-detection is not gate
   evidence.

3. **Diagnostic** - the Ctrl-T pause/resume path is automated in-suite
   (`test-uds-diag.bash`). Verify the flood face (recv-q > 0) with a bounded
   reproduction or `manual-test-diag-hotkey.bash --flood`. The final release
   result records the host, observed value, candidate hash, and capture bound;
   a prior cycle's reproduction does not carry over.

4. **Downstream integration** - con's deployed role, verified with the release
   candidate on the environment defined by the pinned `epics-ioc-runner`
   `gate/RUNBOOK.md` and current drivers. Driver: `tests/release-gate4-downstream.bash`
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

## Dependency pins and advancement

Introduced by the 1.1.0 cycle.

Step 4 executes on an environment owned by other repositories, and this
driver is the seam's ONLY guard: the upstream gate is con-agnostic (its S4/S10
assertions pass with the socat/nc fallback and record no con version). The
gate therefore runs against a PINNED environment, never against "latest":

- **Pin home.** The enforced values live in the driver's DEPS preamble
  (`tests/release-gate4-downstream.bash`): ioc-runner `-V` first line, and
  per-golden OS `VERSION_ID` + `sudo -V` first line (the sudoers-branch
  discriminators the downstream plan itself pins). The driver asserts them
  before any scenario and aborts on mismatch. This file owns the process;
  the active canonical G row records the released-con compatibility run, and
  the final release detail records the local driver update and candidate runs.
- **Advancement.** On any upstream release or golden rebake - before the next
  con release - run gate step 4 with the CURRENT released con against the new
  environment (`GATE_DEPS_EXPECT=<new runner identity>` re-targets the runner
  assertion; it never skips, and a set-but-empty value fails). For a rebake
  that changes the OS or sudo identities, edit the per-golden pins in the
  driver's working tree first and validate with THAT run. Record the observed
  G result only after the current released con passes on BOTH goldens. The
  final release milestone then reconciles the driver and changes the enforced
  runner identity before its candidate gate runs. Never advance without the
  released-con run.
- **Evidence record.** Each bump records: date, the new pinned identities, the
  upstream repository's commit hash, and the validating run. A changed
  upstream hash is also the tripwire to reconcile the current `gate/RUNBOOK.md`
  and drivers with every con-specific assertion.
- **Race tie-breaker.** A con release whose gate step 4 already passed ships
  against the pin it passed with; the advancement to a newer upstream runs
  AFTER that release, with the just-released con.
- **Failure and retention.** If the new environment fails, the pin stays.
  The pinned golden images are part of the pin: rebakes land in NEW image
  filenames, and the pinned images are retained until the pin advances.

## Cycle-open checklist

When a new `docs/milestone-<release>.md` is drafted, its final release detail
must name this file as the gate definition, add the cycle's integrated reruns,
and record any cycle-specific amendment as a delta here - never as a silent
fork in the canonical plan. Every amendment names
the cycle that introduced it (e.g. "step 4 added by 1.1.0"), so the gate's
shape stays traceable to the change that demanded it.
