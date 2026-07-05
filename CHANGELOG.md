# Changelog

Newest first. Each release section is sourced from the milestone's issues;
internal-only refactors with no behavior change stay out.

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
