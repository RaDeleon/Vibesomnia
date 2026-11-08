# Roadmap

Vibesomnia is beta, following owner approval of V1.0 Beta 1. The goal is a reliable open-source app first; feature parity
is a direction, not a claim about today's build.

## Alpha 0.1 — usable foundation

- [x] Native menu bar + dashboard, manual start/stop, graceful quit.
- [x] Mascot menu bar icon matching the app artwork, with an active-session dot.
- [x] Indefinite/timed sessions and optional display wakefulness.
- [x] GUI app-lifetime sessions and opt-in app-start triggers.
- [x] Battery cutoff, session events, CLI status/control.
- [x] Claude/ChatGPT/Codex availability and launch controls.
- [x] Standalone, explicitly authorized temporary closed-lid guard (alpha.3).
- [x] Reviewed user scripts, in-app editor/import, start/end hooks and runner limits.
- [x] SwiftPM build, app bundle script, CI definition, contributor/agent docs.
- [ ] Physical closed-lid/open-lid/reclose and charger-transition acceptance tests.
- [ ] Remote SSH validation from another device.
- [x] Universal local-test DMG/pkg, first-run setup, and private installer workflow.
- [ ] Signed/notarized DMG, clean installation, and wider Mac/OS testing.

## Beta and beyond — own the whole session

- [x] Standalone temporary guard, lease/process monitoring, restoration and explicit recovery.
- [ ] Closed-lid hardware/charger matrix, rare recovery scenarios, production signing,
      and distribution constraints.
- [x] Persist display/closed-lid/battery preferences and setup completion.
- [ ] Persist remaining session options; login item and opt-in resume policies.
- [x] Reconcile the live closed-lid guard with the macOS sleep override (alpha.6).
- [ ] Complete live external-override-loss and repeated lid-cycle acceptance tests.
- [ ] [Investigate unowned sleep overrides and the closed-lid conflict message](https://github.com/RaDeleon/Vibesomnia/issues/3).
      Deferred at the owner’s request; leave existing unowned overrides unchanged.
- [ ] Multiple app/CLI activity triggers with clear precedence and pause behavior.
- [ ] Scheduled/date sessions, power adapter, network, and external-display triggers.
- [ ] File/download sessions, Drive Alive, display/system sleep policy refinement.
- [ ] Global hotkeys, notifications, accessibility and localization.
- [ ] Optional session history/export with explicit privacy controls.
- [ ] Editable CLI executable locations and configurable project directories.

## Amphetamine-inspired parity inventory

The detailed [parity checklist](PARITY.md) is the authoritative feature inventory.
Track and test each feature independently before marking parity complete:
manual durations and dates; application/file/download sessions; trigger rules;
display sleep and screen saver policies; drive wakefulness; battery and power
source rules; closed-display operation; hotkeys; notifications; login behavior;
status/menu customization; scripting; statistics and diagnostics. Original
implementation only; no copied source, branding, or assets.

## Remote AI workspace

- [ ] Readiness diagnostics for existing SSH/VPN/screen-sharing arrangements.
- [ ] Agent-specific run detection and session attachment without chat/key scraping.
- [ ] Research authenticated, encrypted, narrowly scoped remote controls.
- [ ] Prototype full screen/keyboard control or a documented integration with an
      existing remote desktop provider; clarify permissions and lock-screen limits.
- [ ] Decide whether a companion web/mobile client is worthwhile.
- [ ] Threat model, abuse boundaries, consent, revocation, and security review before
      any network listener, pairing service, remote input, or public exposure.

## Acceptance work remaining after beta approval

The owner approved the beta milestone on 2026-11-07. The following checks remain
open and are not implied passes by the new version name.


- Repeatable start/stop/timeout, app exits, battery transitions, and crash recovery.
- Verified closed-lid → remote control → open → close again flow on supported Macs.
- No stale sleep override after normal exit or the defined recovery path.
- Accessibility, UI responsiveness, tests, and clean-machine install/uninstall.
- Accurate docs; reproducible signed/notarized builds; versioned release notes.

## Deferred business backlog

Community/Pro editions, early-access policy, commercial licensing, contributor
agreements, payments, support/funding links, and Mac App Store feasibility.
No feature gates, license checks, or monetization work in the current beta.
