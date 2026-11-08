# Changelog

All notable user-visible changes are recorded here. Versions use SemVer
prereleases. Alpha continues until the owner explicitly approves the beta gate.

## [Unreleased]

### Documentation

- Owner approved public alpha development while acceptance testing remains open;
  updated release disclosures and recorded the decision in the development diary.

- Added a development diary and entry template for future angelodeleon.com posts,
  separating the project story, owner reports, and verified results.
- Recorded the first physical closed-lid observation on alpha.4; repeat-cycle and
  complete remote-interaction acceptance remain pending.

### Planned

- Richer triggers and physical closed-lid / remote-workspace validation.
- Community/Pro separation is deferred; no paid tier exists in this version.

## [0.1.0-alpha.5] — 2026-11-07

### Added

- Universal Apple silicon/Intel DMG containing a standard macOS package installer,
  welcome/license/completion screens, Applications placement and update guard.
- First-run setup for app discovery, sleep preferences, administrator permission
  guidance, and an optional owner-confirmed physical lid / remote test.
- Persisted display sleep, closed-lid and battery preferences; reopenable setup.
- Separate packaging build path that leaves a running app/session untouched.
- Manual private installer workflow, checksums, artifact validation, and optional
  Developer ID signing/notarization support. No automatic publication.

### Validation and limitations

- 23 tests pass, including defaults, preference persistence and corrupt-data fallback.
- Setup preview and installer introduction/license screens checked through computer use.
- Universal executable slices, bundled signatures, package destination and disk-image
  integrity verified. Preinstall refuses an active Vibesomnia session.
- This local installer is unsigned and unnotarized; Developer ID credentials are
  not configured. Actual privileged installation, clean-Mac Gatekeeper behavior,
  Intel hardware and physical lid/remote acceptance remain to be tested.

## [0.1.0-alpha.4] — 2026-11-07

### Fixed

- Detect ChatGPT builds that use the Codex bundle identifier by checking product
  names as well as bundle IDs. Separate Codex and Claude Desktop stay distinct.
- Discover running apps even without Launch Services registration, with fallback
  checks in system/user Applications folders. Launch and app-lifetime controls
  now use the actual detected bundle rather than an assumed identifier.

### Validation

- All 20 tests pass, including three desktop identity regression tests.
- Rebuilt app reports both ChatGPT and Claude Desktop installed and running.
- Owner-authorized closed-lid session started with display sleep allowed;
  physical lid cycling and remote reconnection await owner testing.

## [0.1.0-alpha.3] — 2026-11-07

### Added

- Matching mascot/workstation README banner, expanded navigation, architecture,
  extension documentation, and a complete feature-parity inventory.
- Bundled standalone closed-lid power guard with explicit macOS administrator
  authorization, exclusive ownership, process identity and heartbeat monitoring,
  verified restoration, and explicit recovery for leftover records.
- Add-on import, source/manifest editor, version-specific content approval,
  opt-in manual/start/end events, example packages, and disable/cancel controls.
- Unprivileged script process groups, clean environment, timeouts, captured-output
  limits, cancellation, and quit cleanup.

### Changed

- Removed the Amphetamine runtime dependency and automation backend.
- Timed sessions begin after successful activation rather than before authorization.

### Validation

- Seventeen policy/extension tests and the native runtime smoke test pass.
- Standalone activation, normal stop, and app-exit restoration verified locally
  with Amphetamine's session ended; frozen-app lease expiry restored sleep in
  about 8.4 seconds. Physical lid/charger and remote reconnection remain manual.
- Add-on UI install/review/run/edit and approval invalidation verified.

### Known limitations

- Full Amphetamine feature parity and full remote desktop are not complete; see
  docs/PARITY.md. The guard is experimental and locally ad-hoc signed.
- Add-ons are trusted local code, not sandboxed extensions; packages import only
  the manifest and one script. Overlapping hooks are skipped, not queued.

## [0.1.0-alpha.2] — 2026-11-07

### Added

- Original late-night developer mascot with bloodshot eyes and laptop screen glow.
- Source PNG, 1024px export, full macOS ICNS family, and reproducible icon script.
- App bundle icon in Finder/Dock, dashboard artwork, and README preview.

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

[Unreleased]: https://github.com/RaDeleon/Vibesomnia/compare/v0.1.0-alpha.5...HEAD
[0.1.0-alpha.1]: https://github.com/RaDeleon/Vibesomnia/tree/v0.1.0-alpha.1

[0.1.0-alpha.2]: https://github.com/RaDeleon/Vibesomnia/tree/v0.1.0-alpha.2

[0.1.0-alpha.3]: https://github.com/RaDeleon/Vibesomnia/tree/v0.1.0-alpha.3

[0.1.0-alpha.4]: https://github.com/RaDeleon/Vibesomnia/tree/v0.1.0-alpha.4

[0.1.0-alpha.5]: https://github.com/RaDeleon/Vibesomnia/tree/v0.1.0-alpha.5
