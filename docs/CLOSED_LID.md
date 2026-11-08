# Standalone closed-lid design

Alpha.3 replaces the Amphetamine automation bridge with VibesomniaPowerGuard.
Normal sessions still use native idle/display assertions; they alone do not
suppress lid-close sleep. Closed-lid mode uses macOS's `pmset -a disablesleep`
system-wide override, not the deprecated PreventSystemSleep assertion.

## Consent and scope

Each closed-lid start requests administrator authorization through macOS. The
bundled helper is ad-hoc signed for local development. Production signing,
notarization, OS compatibility, and Mac App Store eligibility remain separate
release work. No persistent daemon, privileged login item, sudoers change,
network listener, script execution, or remote-input service is installed.

The helper accepts only `--check`, a validated launch/worker request, and explicit
recovery. It invokes only `/usr/bin/pmset` with fixed arguments. User add-ons run
under a separate unprivileged runner and cannot supply commands to this worker.

## Acquisition

1. Refuse acquisition if system sleep is already disabled or another guard's
   state directory exists. Never "adopt" an unknown override.
2. Validate the requesting UID, PID, and process start identity.
3. Exclusively create a root-owned lock/state directory in `/private/var/run`.
4. Validate a small regular, single-link, non-symlink lease file owned by that UID.
   Its path is derived from the UID's account home and a validated UUID.
5. Persist a recovery record before changing power state.
6. Set and verify `SleepDisabled=1`; confirm readiness to the app.
7. The detached worker monitors process identity and a monotonically increasing
   heartbeat sequence. Replayed data cannot extend the eight-second lease.

The worker's runtime is tied to the session. Opening/reclosing the lid does not
end the session; display sleep is independently controlled by native assertions.
While active, system sleep requests are suppressed, not just idle sleep.

## Restoration

Stop writes an explicit lease stop request. The worker also restores on app PID
exit/reuse, missing/frozen heartbeat, and handled termination signals. It sets
and verifies `SleepDisabled=0` before deleting its known state file and empty
lock directory. If restoration fails, it retains recovery evidence. It does not
recursively delete directories or restore unrelated profile settings.

If the worker itself is forcibly killed, automatic restoration cannot be
promised. The app offers explicit authorized recovery only for its root-owned
record and refuses recovery while the recorded worker still exists. Reboot clears
`/var/run`; OS behavior after abrupt power loss/reboot is a hardware acceptance
item, not a proven cleanup guarantee. Avoid concurrent power-manager sessions:
macOS's global flag cannot distinguish another tool writing the same value while
Vibesomnia owns it.

## Evidence

Local elevated tests: successful activation, normal stop and state cleanup, and
restoration after simulated app exit, and frozen-app heartbeat expiry in about
8.4 seconds, with Amphetamine's session ended. Native
assertions, script runner, lease expiry/replay policy, and control validation have
automated checks. Physical lid/charger behavior, external remote reconnection,
rare root-worker failure recovery, and cross-version behavior need manual tests.
