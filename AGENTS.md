# Vibesomnia — agent instructions

## Product scope

Build an open-source macOS utility for screen-off AI development and remote
workspace control. Current version: `VERSION`. All work is alpha until the owner
explicitly approves beta. Community/Pro separation is backlogged; do not add
paywalls, licensing checks, payment flows, or artificial feature limits now.

## Before changing code

- Read README.md, CHANGELOG.md, and the most recent sessions.log entries.
- Follow existing module boundaries. App lifecycle, UI, session state, native
  power, app discovery, and CLI transport belong in separate files.
- If a codebase-memory graph tool is available, use it for structural exploration,
  index this repository first, and verify index coverage. If unavailable or
  incomplete, use direct source reads/rg and state the limitation when relevant.
- No sub-agent delegation unless the user or another applicable instruction asks.

## Engineering rules

- SwiftPM; macOS 14+; Swift 5.9-compatible source; native SwiftUI with narrow AppKit
  integration. Avoid third-party dependencies unless there is a concrete need.
- SessionStore owns app-wide state. Views must not directly run power commands.
- Native mode prevents idle sleep only. Never claim this also bypasses lid sleep.
- Closed-lid mode uses the bundled temporary VibesomniaPowerGuard after explicit
  macOS administrator approval. It owns only a sleep override it acquired from
  normal state. Preserve its root-owned lock/record, PID identity check, expiring
  heartbeat, fixed operations, and restore-before-cleanup ordering.
- Never execute add-ons in the power guard. User scripts run unprivileged with
  reviewed content hashes, opt-in hooks, timeouts, bounded captured output, and
  process-group cleanup. Changing code or manifest invalidates approval.
- Do not silently end other apps' sessions, alter sudoers, install persistent
  root daemons, weaken security, enable remote sharing, or expose listeners.
- Native power assertions must be released on stop/failure/quit. Any external
  backend needs ownership tracking and explicit interruption recovery.
- Remote commands are typed and allowlisted. No arbitrary shell/script endpoint.
  Preserve same-user isolation, expiry, file permissions, and bounded input size.
- Don't read AI conversations, tokens, credentials, or agent configs to detect apps.
- Never label absent apps, CLI activity, remote connectivity, or model runs as
  working without real evidence. No fake metrics, screenshot mockups, or badges.
- Keep app UI focused on user outcomes; keep detailed architecture in docs.
- Avoid copying Amphetamine code/assets. Feature inspiration and supported
  automation do not establish permission to relicense third-party source.

## Build and validate

```sh
swift test
./script/build_and_run.sh --verify
```

Use the build script instead of launching the GUI SwiftPM binary directly.
The CLI executable is `vibesomnia-cli` to avoid a case-insensitive filesystem
collision with `Vibesomnia`. Use `--build-only` for packaging without launch.
Exercise the affected items in docs/TESTING.md. Never turn a physical lid test,
macOS permission prompt, or live remote test into an unqualified automated pass.
Gracefully end owned sessions before relaunching; don't force-kill around recovery.

## Version and history discipline

- Use SemVer prereleases: `0.1.0-alpha.1`, `.2`, etc. Beta is an explicit milestone.
- For a new release, synchronize VERSION, AppStatus/CLI/UI version strings,
  README badge, CHANGELOG, and generated bundle version metadata.
- CHANGELOG.md records user-visible changes by version, with Unreleased for work
  not assigned a release. Distinguish added, fixed, changed, and known limitations.
- Keep docs/dev-diary/ updated for meaningful milestones, bugs, and decisions as
  unpublished material for angelodeleon.com. Separate owner reports from verified
  behavior, name the tested version, and never publish to the website automatically.
- Append a dated entry to sessions.log for each work session: objective, changes,
  verification, limitations, and next steps. Never invent time spent or outcomes.
- Update README, roadmap, and tests when behavior or scope changes.
- Stage/commit/push completed work on a feature branch by default. Inspect the
  diff first; exclude .build, dist, local logs, credentials, and machine state.
  Don't add AI attribution to commits. Do not publish binary releases or merge
  main without an explicit instruction to do so.

## Public repository hygiene

- Keep this repository private until the owner confirms acceptance testing is complete.
- Build installers privately; do not publish releases or change visibility automatically.

All current code is AGPL-3.0-only. Preserve Angelo De Leon's copyright notices.
Don't put user-specific local paths, network addresses, remote access details,
private keys, saved chat history, or secret-bearing logs into source or docs.
Source sessions.log is an engineering work log, not captured user activity.
