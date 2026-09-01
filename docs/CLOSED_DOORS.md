# Closed Doors

This record preserves owner decisions that keep examined work out of active
milestones. A closed door is not reopened by issue review, source discovery,
or a proposed release grouping. Reopen or reclassify only on explicit owner
request.

| ID | Date | Keep verdict | Premise | Evidence | Carrying commit |
| --- | --- | --- | --- | --- | --- |
| D1 | 2026-08-13 | Keep UDS server work outside the active release | The next cycle is client-first. UDS server changes remain unassigned in the canonical `Backlog`; GitHub tracks the server-only subset behind the `Closed Door` milestone. No automatic movement into an active release is allowed. | Current `docs/milestone-bef067f.md` Backlog; prior `docs/milestone-1.2.0.md` at `bef067f99983b282cd06aff2cff8b2ec12e87f31`; UDS server issues #8, #9, #10, #12, #13, and #14; GitHub `Closed Door` milestone #3. | `242a351328bfce44980f2fd6f6c87016043706be` |
| D2 | 2026-08-13 | Keep only UDS-client-containing work eligible for client review | UDS client work remains in GitHub `Backlog`; UDS server-only, TCP server, and TCP client issues are held in `Closed Door`. Generic issues remain in `Backlog` without the `closed-door` label. | Client review set: #16, #20, #22, #23, and #25. GitHub `closed-door` label is on #8-#14, #17, and #21; these issues are `OPEN` in milestone #3 `Closed Door`. #15, #18, and #19 remain `OPEN` in milestone #1 `Backlog` without that label; issue bodies and state were preserved. | `39eb9ccd50802f93e1c318595670e9341493f082` |
| D3 | 2026-08-26 | Keep duplicated hexa output blocks unchanged and keep issue #16 open in GitHub `Backlog` | The behavior-neutral P3 refactor is not required by the client-focused release. The current `-X` and `-Y` blocks remain separate, and issue #16 remains outside active canonical work without a `closed-door` label. | GitHub issue #16 was observed 2026-08-27T17:37:04Z as `OPEN` in milestone `Backlog`, assigned to `jeonghanlee`, with labels `P3-low` and `refactor`; phase 7 changed no labels or body and created no canonical Backlog row. | `c7ade10f9de5fe469fdf3ecbcf3fca8d8a3c9432` |
