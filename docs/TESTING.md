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

## Installer and first-run setup

- Build `./script/package_dmg.sh --local` while an existing session is active;
  confirm its PID, heartbeat and session start time remain unchanged.
- Run `./script/verify_installer.py dist/installers/<filename>.dmg`.
- Inspect installer welcome, license and completion instructions.
- Confirm preinstall refuses a running app, live guard or leftover recovery record.
- On a test Mac, install to Applications with administrator approval. Verify it
  does not relocate into a developer checkout or change power/sharing settings.
- Open the installed app: first-run setup appears. Detect apps, change preferences,
  finish/skip, relaunch, and confirm choices persist while sessions remain stopped.
- Reopen setup from both toolbar and Settings. Test permission denial/cancellation.
- Complete setup, then quit/relaunch twice. Confirm the completion flag and all
  saved choices survive both launches; loading preferences must not write a
  partially restored record over them.
- Follow the physical lid/remote checklist below; owner confirmation is not an
  automatically measured connectivity result.
- Test update and uninstall (end/recover session, quit, move app to Trash).
- Signed release: verify Developer ID signatures and stapled tickets, then test a
  browser-downloaded quarantined DMG on a clean Mac; never disable Gatekeeper.
- Check both Apple silicon and Intel hardware. Packaging slices alone is not a
  hardware compatibility test.

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
- Dashboard switch is OFF when idle even if the saved closed-lid default is ON.
- Start closed-lid mode through the CLI/setup; verify the dashboard switch is ON,
  CLI `closedLidActive=true`, and `closedLidVerifiedAt` advances with actual checks.
- Turn the dashboard switch OFF; verify SleepDisabled=0, the guard exits and native
  keep-awake remains. Turn it ON; approve macOS and verify protection resumes.
- Change modes in a timed/app-constrained session; verify its original deadline,
  display choice and selected-app condition are unchanged. Cancel authorization;
  the existing native session must remain intact with the switch OFF.
- With the lid OPEN in an isolated owned test, clear the global override. Verify
  the guard exits, the app clears its switch and ends the session with an error.
  It must not reapply the override or auto-restart immediately. Repeat with a failed
  state read; verify recovery evidence remains when restoration cannot be confirmed.
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

- Verify the menu bar shows the app's full-color mascot, with no moon/sleep symbol.
  Check idle and native active sessions: a green dot appears only while active;
  stopping restores the idle icon. Open the menu and confirm controls still work.
  Inspect light/dark menu bars, selected-menu appearance, Retina/non-Retina sizing,
  and VoiceOver's idle/awake label. The mascot must remain visible in both states.

Check light/dark appearance, error messages, permission denial, larger text,
keyboard navigation, VoiceOver, multiple windows, menu labels, and minimum size.
Capture screenshots from the real app; don't substitute marketing mockups for UI.

## Evidence

Record actual checks and limitations in the local session log and release notes. Keep
private runtime output, hostnames, and screenshots containing user data out of Git.


## Workspace refresh acceptance

- Gear, Command-comma, and menu-bar Settings reuse the main window; Dashboard
  returns without changing an active session. Test after closing the window too.
- Open Stay awhile help; read every option and confirm the popover fits onscreen.
- Start a 5-minute session from the menu. Confirm dashboard/menu-bar countdowns
  agree. Set 10 minutes remaining; confirm original start and power ownership
  stay intact. Remove timer; verify indefinite. Custom 0/negative/excess duration
  must fail without replacing the active session. Test a one-minute actual expiry.
- Confirm icons and installed/running status against actual applications. Verify
  separate Atlas IDE/browser and ChatGPT/Codex identities. Uninstalled tools must
  not appear connected. CLI presence must not be treated as running/model activity.
- Pin/unpin, toggle automatic running-app discovery, relaunch and check persistence.
  Add a custom `.app` outside Applications, launch it, and check the actual icon.
- Exercise a real launch failure; yellow status and Troubleshoot must show the
  error, recovery guidance and retry. Verify retry clears a successful failure.
- Enable recap, start/stop, check actual interval/app names, copy the prompt and
  inspect UTC timestamps. No history files or conversations should be read. A
  completed recap is not evidence that an AI task succeeded. Disable and verify
  collection stops; quitting discards in-memory recaps.
- Support opens the bundled page; all six presets and custom amount work. With no
  recipient configured, checkout remains disabled and clearly says so.
- Inspect minimum-size layout, scrolling, light/dark appearance, focus order and
  accessibility labels. Check idle CPU/RSS as a sample, not a universal benchmark.


### Non-disruptive UI preview

`./script/build_and_run.sh --preview` opens a read-only workspace using actual app
metadata. It does not create IPC, acquire power assertions, load script storage,
or save preferences. The title and dashboard label identify the preview. Use it
for layout/navigation checks while an installed session is active; close that
preview with Command-Q before a normal `--verify` run. Preview checks do not prove
live session, countdown, persistence, script execution or remote behavior.
`--build-only` now builds without requesting the running app to quit.
