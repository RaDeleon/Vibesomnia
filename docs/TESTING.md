# Validation checklist

Automated tests cover policy and the local command transport; they cannot prove
macOS hardware sleep behavior or a successful remote connection.

## Automated

```sh
swift test
./script/build_and_run.sh --verify
./script/smoke_test.py
```

The smoke test requires Python 3 and an idle app. It checks real power assertions
and graceful CLI shutdown, then leaves Vibesomnia closed. It refuses to replace
an active session. Relaunch with the build script afterward.

Verify timer boundaries, indefinite sessions, app lifetime, rejected durations,
expired requests, launch allowlisting, transport permissions, and stale status.
Check that the app bundle and CLI report VERSION consistently.

## Native session smoke test

- Start indefinite mode with display sleep allowed. `pmset -g assertions` should
  show Vibesomnia's idle-system assertion and no Vibesomnia display assertion.
- Stop; verify Vibesomnia's assertions disappear. Other apps may retain theirs.
- Start with display sleep prevented; verify both assertions. Stop again.
- Start one-minute mode and verify actual timeout, not just countdown UI.
- Start while a selected GUI app runs, quit that app, and verify session ends.
- Enable the app trigger; verify auto-start. Manually stop; verify it doesn't
  immediately restart. Quit/reopen the selected app to permit another trigger.
- Test battery cutoff using controlled hardware conditions; do not drain a machine
  running important work just to satisfy the checklist.
- Close the dashboard; menu control remains available. Quit app; assertions release.

## Closed-lid backend (manual and opt-in)

- Install/configure Amphetamine independently. Approve Automation on the Mac.
- Keep an existing Amphetamine session active; confirm Vibesomnia refuses to replace it.
- End it yourself. Start Vibesomnia closed-lid mode and confirm Amphetamine's
  session, display-sleep permission, and closed-display state.
- Close lid → confirm remote task continues → open → close again → confirm again.
- Test charger disconnect/reconnect, external displays, low battery, timer end,
  app closure, manual stop, and normal quit. Verify sleep overrides restore.
- Interrupt a controlled test session, relaunch, and explicitly recover. Recovery
  ends the current Amphetamine session; review it before clicking Recover.
- Do not force-kill or replace a real user session as an automated test.

## Remote controls

- Run `vibesomnia-cli status/start/stop/toggle` locally.
- Repeat over an existing SSH connection as the same user from another device.
- Verify invalid commands/durations/unknown launch targets fail with no session changes.
- Verify stale status after the app exits fails instead of reporting an active service.
- No SSH changes, firewall changes, public listener, or GUI remote input should appear.
- GUI apps launch as requested. Terminal agents open a local Terminal window;
  this does not imply remote terminal attachment or successful model authentication.

## UI and accessibility

Check light/dark appearance, error messages, permission denial, larger text,
keyboard navigation, VoiceOver, multiple windows, menu labels, and minimum size.
Capture screenshots from the real app; don't substitute marketing mockups for UI.

## Evidence

Record actual checks and limitations in sessions.log and release notes. Keep
private runtime output, hostnames, and screenshots containing user data out of Git.
