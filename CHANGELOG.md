# Changelog

All notable user-visible changes are recorded here. Versions use SemVer
prereleases. Alpha continues until the owner explicitly approves the beta gate.

## [Unreleased]

### Planned

- Standalone closed-lid backend, richer triggers, and remote-workspace validation.
- Community/Pro separation is deferred; no paid tier exists in this version.

## [0.1.0-alpha.1] — 2026-11-07

### Added

- Native macOS SwiftUI dashboard and menu bar session controls.
- Indefinite/timed sessions, optional display wakefulness, and GUI app-lifetime rules.
- Opt-in selected-app auto-start, manual-stop suppression, and 20% battery protection.
- Claude Desktop, ChatGPT, and Codex discovery/launch; Claude Code/Codex CLI launch.
- Same-user command-line session/status/launch controls usable over existing SSH.
- Optional Amphetamine-backed closed-lid sessions with ownership and recovery markers.
- Graceful session cleanup; native assertions released by macOS on process exit.
- SwiftPM build/test setup, local app bundle script, Codex Run action, and CI workflow.
- README, shared agent guidance, contributor guidance, roadmap, test checklist,
  engineering session log, and version tracking.

### Validation

- Eight core tests pass; local app build and CLI readiness verified.
- Live native assertions, start/stop/toggle, a real one-minute timeout, GUI
  app-lifetime cleanup, Codex GUI launch, and graceful quit verified locally.
- Dashboard and Settings inspected through computer use; runtime smoke test added.

### Known limitations

- Closed-lid mode requires separately installed/configured Amphetamine; no native
  privileged closed-lid helper is installed by Vibesomnia.
- No complete Amphetamine parity, remote desktop/input streaming, mobile client,
  unattended login, persistent preferences, or CLI activity monitoring.
- Interrupted Amphetamine sessions may remain active until explicitly recovered.
- Physical lid/charger behavior and remote connections require manual validation.
- Local ad-hoc builds only; no notarized DMG or Mac App Store release yet.

[Unreleased]: https://github.com/RaDeleon/Vibesomnia/compare/v0.1.0-alpha.1...HEAD
[0.1.0-alpha.1]: https://github.com/RaDeleon/Vibesomnia/tree/v0.1.0-alpha.1
