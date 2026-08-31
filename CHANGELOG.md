# Changelog

Newest first. Each release section is sourced from the milestone's issues;
internal-only refactors with no behavior change stay out.

## 1.2.0 — Explicit UNIX Transport Release (2026-08-31)

### Added

- CLI: `-u` and `--unix` force UNIX socket transport for client and server
  targets while leaving flagless transport selection unchanged (#20).
- UDS: explicit UNIX mode supports colonless socket paths such as
  `/tmp/foo.sock` and colon-bearing paths with numeric suffixes (#20, #22).

### Fixed

- Tests: the PTY helper preserves the real command status, UDS connection
  checks require an observable round trip, suite discovery follows the
  `test-*.bash` naming rule, explicit echo-backend selection is honored, and
  `make test` propagates failures (#23).
- Tests: the shared helper resolves the repository binary when sourced from
  another directory and rejects a missing or non-executable binary (#25).

## 1.1.0 — UDS Hardening Release (2026-07-04)

### Fixed

- UDS: a colon-bearing target path now routes as a UNIX socket, not TCP (#4).
- UDS: a `sun_path` over 108 bytes is rejected instead of silently
  truncated (#5).
- UDS: `servlen` standardized on `SUN_LEN` (#6).
- CLI: an `-x` exit key whose finalized byte collides with the Ctrl-T
  diagnostic is rejected at parse time (#7).

### Added

- Automated Ctrl-T diagnostic coverage, pause and resume, under the PTY test
  harness (#24, #26).
- Multi-client UDS test suite and a forking echo-server test helper (#28).
- Five-step release gate with real-environment downstream integration on the
  epics-ioc-runner goldens (#27), a standing version-independent gate
  reference (`docs/release-gate.md`), and pinned gate dependencies with a
  verified advancement procedure.
