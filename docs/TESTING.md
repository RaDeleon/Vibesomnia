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

## Desktop app discovery

- Confirm ChatGPT and Claude Desktop report installed/running against real apps.
- Verify ChatGPT with either `com.openai.chat` or a ChatGPT-named
  `com.openai.codex` bundle; a separate Codex app must stay a separate product.
- Check running apps outside Applications and an installed but closed app.
- Launch and app-lifetime selection must use the detected URL/bundle identity.
- Never treat a matching display name with an unrelated bundle ID as an AI app.

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

## Standalone closed-lid guard (manual and opt-in)

- End other power-manager sessions. Verify the guard refuses an existing global override.
- Start Vibesomnia closed-lid mode; approve the macOS administrator prompt yourself.
- Verify SleepDisabled=1, display assertions follow the chosen display policy,
  and the temporary root-owned state records Vibesomnia's PID identity.
- Stop normally; verify SleepDisabled=0 and no root guard/record remains.
- In an isolated test, terminate the app; verify the guard restores and exits.
- Suspend only the test app to stop heartbeat progress; verify lease expiry
  restores sleep even while the app's PID remains alive. Resume and inspect errors.
- Close lid → confirm remote task continues → open → close again → confirm again.
- Test charger disconnect/reconnect, external displays, low battery, timer end,
  app closure, manual stop, and normal quit. Verify restoration each time.
- Simulate a worker failure only in a controlled environment; recovery must use
  a verified root-owned record, never adopt another tool's sleep override.
- Don't force-kill a real user session or authenticate an admin prompt automatically.

## Add-ons

- Import/create without approval: Run and event execution remain disabled.
- Review source/manifest; approve that version; run a harmless script.
- Edit source or change event/interpreter/timeout: approval invalidates.
- Verify timeout, cancellation, bounded output, clean environment, and no root execution.
- Opt into start/end events; verify normal end hook and no end hook on app quit.
- Verify quitting cancels/waits for the current unprivileged runner's cleanup.
- Reject malformed IDs, path traversal, symlinks, oversized code, and duplicate events.
- Review two-file import limitations; no marketplace, package assets, or remote run endpoint.

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
