# ADR 0001 — UDS sun_path length guard: placement at the copy site

- Status: **Accepted** (2026-06-24). Implemented in commit `ce10568` on
  `release-1.1.0` (milestone M2, issue #5).
- Scope: where the over-length UNIX-domain socket path guard lives in
  `con.cpp`. The guard rejects a target path of `sizeof(sun_path)` bytes or
  more instead of letting `strncpy` truncate it silently. This record covers
  the placement decision; the per-fix details (message format, commit split,
  test assertions) live in the `docs/milestone.md` M2 register row and the
  issue #5 body.
- Supersedes: none. First ADR in this repository.

This record is self-contained: it states the chosen placement, the alternative
weighed against it, the evidence, and the consequences inline, so it remains
readable independently of the (gitignored, now-closed) review session that
produced it.

---

## Context

`con` connects to either a UNIX-domain socket (UDS) or a TCP `host:port`
target. For a UDS target it copies the path into the fixed `sun_path` field of
`struct sockaddr_un` with `strncpy(dst, src, sizeof(sun_path) - 1)` at two
sites: the server `bind` path and the client `connect` path. On Linux
`sizeof(sun_path)` is 108, so any path of 108 bytes or more was silently
truncated, and `con` then bound or connected to a different path than the
operator requested, with no diagnostic (issue #5, priority P1).

The fix is a length guard that rejects an over-length path. The open question —
this ADR's subject — was **where** to place that guard.

A property of the surrounding code constrains the answer: `con` does not know
whether a target is UDS or TCP until `tcp_separator()` examines it. That
classification runs inside the connect/bind path, after the controlling
terminal (`/dev/tty`) is already opened; at argument-parse time the target
string is still unclassified, and a TCP target is reassigned later in the same
path.

## Decision

Place the guard at the **copy site**, immediately before each `strncpy`, at
both UDS sites (the server `bind` path, con.cpp:670, and the client `connect`
path, con.cpp:849, as of `ce10568`). The guard rejects when
`strlen(target) >= sizeof(sun_path)` and exits through the existing
`PERR(...)` / `finish(1)` error path. This is "Option A".

The guard runs only on the branch already classified as UDS, so it never sees
a TCP target. The two sites carry an identical guard; a comment ties the three
`sizeof(sun_path)` references together so a later change (the M3 `SUN_LEN`
refactor, issue #6, which edits the adjacent length line) does not let them
drift apart.

## Alternatives considered

The contest was between two placements:

| Option | What it is | Outcome |
| --- | --- | --- |
| **A — copy site** | Guard at each `strncpy`, after the UDS branch is taken. | **chosen** |
| **B — parse time** | Hoist the length check to argument-parse time, before any socket or terminal setup. | rejected |

Option B was attractive for testability and clean error reporting: a check that
runs before the terminal is opened can be tested by exit code alone and prints
its message cleanly. An 11-reviewer panel split 6 to 5 in favour of A — but the
vote was not the basis for the decision; a code fact was.

## Evidence

- **B would over-reject TCP targets, or duplicate work.** At argument-parse
  time the target is not yet classified as UDS or TCP (`tcp_separator()`
  decides that later, inside the connect/bind path, and a TCP target is
  reassigned there). A length check at parse time would therefore reject a
  legitimate `host:port` of 108 bytes or more, or it would have to repeat the
  UDS/TCP classification it does not yet have.
- **B's benefit is unreachable in this code.** B's advantage — validate before
  the controlling terminal (`/dev/tty`) is opened — cannot be realised, because
  the UDS classification itself happens after that terminal is opened. There is
  no point that is both after classification and before terminal setup.
- **A is correct and local.** At the copy site the target is known to be a UDS
  path, so the guard never affects the TCP path. Placing it here also keeps the
  precondition that the later `SUN_LEN` refactor (M3) depends on — a
  NUL-terminated, non-truncated `sun_path` — verifiable next to the line that
  uses it.
- **Verified.** Build is clean under `-Werror -fno-exceptions`; the full suite
  is 12/12 green; a `host:port` target longer than 108 bytes still takes the
  TCP path and is not rejected by the guard (confirmed at runtime).

## Consequences

- **Preserved:** TCP targets of any length are unaffected; the M3 `SUN_LEN`
  precondition stays locally verifiable.
- **Accepted trade-off — duplication.** The guard is written at two sites that
  must stay identical. A shared comment ties the `sizeof(sun_path)` references
  together to guard against drift; a shared helper was out of scope for this
  single-issue fix.
- **Accepted trade-off — test path.** Because the guard runs after `/dev/tty`
  is opened, the change-specific test must drive `con` through a
  pseudo-terminal harness to read the error message, rather than checking an
  exit code alone.
- **Non-goal.** An empty path passes the guard by design; it is not a
  truncation case and `bind`/`connect` reject it downstream.

## References

- Milestone M2 / issue #5; the fix landed in commit `ce10568`, with the
  register status update in `03ed2b5`, on `release-1.1.0`.
- The full working record — a 5-reviewer design review, the 11-reviewer
  placement panel, a 5-reviewer pre-commit review, and an 11-reviewer post-fix
  review — was produced in review session `rs20260624_064432`, which is
  gitignored and removed at closure. The decisive facts are inlined above so
  this ADR stands alone.
