# ADR 0002 — Exit/diagnostic key collision: reject at parse time

- Status: **Accepted** (2026-06-26). To be committed on `release-1.1.0`
  (milestone M4, issue #7); the commit reference is added when the fix lands.
- Scope: how `con` handles a user-configured exit key that equals the fixed
  diagnostic key. The guard rejects the colliding `-x` value at option-parse
  time instead of letting the diagnostic key be silently disabled. This record
  covers the warn-vs-reject decision; the per-fix details (message text, test
  assertions) live in the `docs/milestone.md` M4 register row and the issue #7
  body.
- Supersedes: none. Relates to ADR 0001 (also a `con.cpp` input guard), but the
  decision is independent.

This record is self-contained: it states the chosen disposition, the alternative
weighed against it, the evidence, and the consequences inline, so it remains
readable independently of the (gitignored, now-closed) review session that
produced it.

---

## Context

`con` reads two single-byte control keys from the local terminal inside its
`poll()` I/O loop: an **exit key** (`exitChr`, default `'\001'` Ctrl-A,
con.cpp:54) that ends the session, and a **diagnostic key** (`diagChr`,
`'\024'` Ctrl-T, con.cpp:57) that prints a diagnostic block. The exit key is
user-configurable through `-x` / `--exit`; the diagnostic key is a compile-time
constant with no setter.

The loop tests the exit key first (con.cpp:336) and the diagnostic key second
(con.cpp:338). When the user sets `-x ctrl/t` (or any `-x` value that resolves
to 0x14), `exitChr` equals `diagChr`, the exit test matches first, and the
diagnostic branch becomes unreachable — the diagnostic key is **silently**
disabled with no warning (issue #7, priority P3-low). The collision is
one-directional: only `-x` can drive the collision, because `diagChr` is never
reconfigurable.

Issue #7 leaves the disposition open ("warn or reject"). That open question is
this ADR's subject.

## Decision

**Reject** the colliding value at option-parse time. A single guard at the end
of the `-x` parsing block (con.cpp:571, after both the numeric and control
assignment paths have finalized `exitChr`) compares the finalized `exitChr`
byte to `diagChr`; on equality it prints a message and exits through the
existing `finish(1)` path. `con` does not warn and continue.

The guard compares the **finalized byte**, not the input text, so it also
catches numeric truncation: `-x 0x114` casts through `unsigned char` to 0x14
(con.cpp:523) and is rejected like any other 0x14 value. A comment at the guard
records that the check assumes `diagChr` is a constant parsed before this point;
if `diagChr` ever becomes configurable, the check moves to after all options are
parsed.

## Alternatives considered

| Option | What it is | Outcome |
| --- | --- | --- |
| **Reject** | Refuse the colliding `-x` value; print a message and `finish(1)`. | **chosen** |
| **Warn** | Print a one-line stderr warning and start anyway, exit-first behavior kept. | rejected |

The Round 1 design review leaned warn: the five reviewer responses split warn 3
to reject 2, or 4 to 2 counting the seed report. The Round 2 11-reviewer vote,
after reading all five Round 1 responses, reversed to reject 10 to 1 across
opus/sonnet/haiku models. As with ADR 0001, the vote was not the basis for the
decision; code facts were.

## Evidence

- **CLI-contract uniformity.** Every other value-validation failure in the `-x`
  parsing block already terminates via `finish(1)` (con.cpp:521, 530, 542, 549,
  560). A warn-and-continue here would be the lone exception to that block's
  uniform fail-fast contract.
- **No warn idiom exists.** `con` has no warn-and-continue validation idiom
  anywhere; `PERR` / `RERR` / `finish` are all terminal (con.cpp:41-42).
  Reject reuses an established idiom and introduces no new concept; warn would
  introduce the codebase's first soft-validation path and a regression risk for
  future editors (a bare `fprintf(stderr, ...)` with no `finish`).
- **The collision is a validation failure, not a warning condition.** The
  colliding value cannot do what the user asked — it cannot serve as an exit key
  without shadowing the diagnostic key — so it belongs with the block's other
  rejected inputs.
- **Recorded dissent.** The single warn vote noted that `-x ctrl/t` produces a
  *valid* byte (con.cpp:523/553/555), unlike the reject paths that fire when no
  usable byte exists, so rejecting a well-formed user choice to protect a
  P3-low diagnostic is arguably disproportionate. The panel and the User judged
  contract uniformity the stronger concern.
- **Contrast with ADR 0001.** ADR 0001 rejected a parse-time guard for the
  sun_path length check because the UDS/TCP classification is not known until
  after `/dev/tty` is opened. That constraint does not apply here: the
  exit/diagnostic collision is fully decidable from the finalized `exitChr`
  byte during `-x` parsing, with no later classification, so the parse-time
  guard that was wrong for #5 is exactly right for #7.

## Consequences

- **Preserved:** the non-colliding default path (exitChr 0x01 != diagChr 0x14)
  is byte-for-byte unchanged; the guard body is never entered without `-x`.
- **Accepted trade-off — a well-formed value is refused.** A user who wants
  Ctrl-T as the exit key must choose a different key. This is the deliberate
  cost of contract uniformity over convenience for a P3-low feature.
- **Testable by exit code and message.** Because the guard runs before
  `/dev/tty` is opened, the change-specific test drives `con -x ctrl/t` and
  checks exit code and stderr message directly, with no pseudo-terminal harness
  (unlike ADR 0001's test path). The actual 0x14 keypress remains a manual
  check.
- **Non-goal.** Making `diagChr` configurable, adding a `-d` option, or
  reordering the poll-loop precedence are out of scope (deferred; Backlog
  candidates if pursued).

## References

- Milestone M4 / issue #7; the fix lands on `release-1.1.0` (commit reference
  added when committed), with the register status update in `docs/milestone.md`.
- The full working record — a 5-reviewer design review, an 11-reviewer
  disposition vote, a 5-reviewer plan-validation review, and a 5-reviewer
  pre-commit review — was produced in review session `rs20260625_101503`, which
  is gitignored and removed at closure. The decisive facts are inlined above so
  this ADR stands alone.
