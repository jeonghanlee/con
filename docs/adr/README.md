# Architecture Decision Records — index and decision-record map

This directory holds con's Architecture Decision Records (ADRs). An ADR records
an architecture-level decision — one that weighs named alternatives and has
lasting consequences — as a self-contained statement of the "why", so it
outlives the working session that produced it.

## ADRs

| ADR | Title | Status | Scope |
| --- | --- | --- | --- |
| [0001](0001-uds-sun-path-guard-placement.md) | UDS sun_path length guard: placement at the copy site | Accepted (2026-06-24) | Where the over-length UNIX-domain socket path guard lives (M2 / #5). |

## Where decision rationale lives

Not every decision becomes an ADR. The rationale is recorded at the layer that
matches the decision; each layer is in-repository (committed) and self-contained:

| Decision kind | Home |
| --- | --- |
| Architecture decision (alternatives weighed, lasting) | an ADR in this directory |
| Per-milestone fix decision | the `docs/milestone.md` register row (rationale inline) + the GitHub issue body |
| Cycle test approach | `docs/testplan_<version>.md` |

A decision is promoted to an ADR when it is architecture-level: it weighs named
alternatives, has lasting consequences, and benefits from a self-contained
record that outlives any single milestone. A routine per-milestone fix keeps its
rationale in the register row and the issue body instead.

## Conventions

- Filenames: `NNNN-short-slug.md`, zero-padded sequential.
- Each ADR is self-contained: it states the decision, the alternatives, the
  evidence, and the consequences inline, so it remains readable without the
  working session (review sessions are gitignored and removed at closure — they
  are provenance, not the home of the rationale).
- A superseding decision adds a new ADR and marks the prior one `Superseded by
  NNNN`; an Accepted ADR is not rewritten in place once accepted — append a
  correction note instead.
