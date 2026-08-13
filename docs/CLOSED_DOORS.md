# Closed Doors

This record preserves owner decisions that keep examined work out of active
milestones. A closed door is not reopened by issue review, source discovery,
or a proposed release grouping. Reopen or reclassify only on explicit owner
request.

| ID | Date | Keep verdict | Premise | Evidence | Carrying commit |
| --- | --- | --- | --- | --- | --- |
| D1 | 2026-08-13 | Keep UDS server work outside the active release | The next cycle is client-first. UDS server changes remain unassigned in the canonical `Backlog`; GitHub tracks the server-only subset behind the `Closed Door` milestone. No automatic movement into an active release is allowed. | `docs/milestone.md` Backlog; UDS server issues #8, #9, #10, #12, #13, and #14; GitHub `Closed Door` milestone #3. | `242a351328bfce44980f2fd6f6c87016043706be` |
| D2 | 2026-08-13 | Keep only UDS-client-containing work eligible for client review | UDS client work remains in GitHub `Backlog`; UDS server-only, TCP server, and TCP client issues are held in `Closed Door`. Generic issues remain in `Backlog` without the `closed-door` label. | Client review set: #16, #20, #22, #23, and #25. GitHub `closed-door` label is on #8-#14, #17, and #21; these issues are `OPEN` in milestone #3 `Closed Door`. #15, #18, and #19 remain `OPEN` in milestone #1 `Backlog` without that label; issue bodies and state were preserved. | Pending commit of this classification record |
