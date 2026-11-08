# Full replacement checklist

The goal is **all Amphetamine capabilities plus AI workspace controls and reviewed
add-ons**. Alpha.3 is not full parity. This file makes the remaining work explicit
instead of using the word "replacement" as a completion claim.

Baseline checked against the developer's [published App Store feature list](https://apps.apple.com/app/amphetamine/id937984704)
on 2026-11-07. This is a feature inventory, not copied implementation or assets.

| Category | Current status / acceptance needed |
| --- | --- |
| Manual on/off, indefinite and duration sessions | Implemented and locally tested |
| End at a specified date/time | Pending |
| Keep awake during a download | Pending |
| Session tied to a GUI application | Implemented and locally tested |
| Display sleep permission | Implemented and locally tested |
| Screen saver permission and inactivity delay | Pending |
| Closed-lid operation without dependencies | Own guard implemented; activation/stop/app-exit tests pass; physical lid/charger tests pending |
| Screen lock and idle locking | Pending |
| Periodic mouse movement | Pending; must not be presented as fake user productivity |
| App-running auto-start trigger | Implemented; broader condition combinations pending |
| Foreground app trigger | Pending |
| External/ mirrored display triggers | Pending |
| USB / Bluetooth device triggers | Pending; respect macOS permissions |
| Charging, AC/battery, battery-threshold triggers | Low-battery protection implemented; configurable start conditions pending |
| IP, Wi-Fi, DNS, VPN triggers | Pending; avoid unnecessary location or network access |
| Audio-output/headphone trigger | Pending |
| Mounted-volume trigger / Drive Alive | Pending |
| CPU and user-idle thresholds | Pending |
| Global hotkeys | Pending; focused-app session shortcut implemented |
| Custom status icons, sounds, time display | App branding implemented; user customization pending |
| AppleScript and external automation | Typed CLI implemented; native AppleScript dictionary pending |
| User scripts / extensibility | Reviewed source editor, import, manual run, start/end hooks, cancellation and timeouts implemented |
| Notifications, history, persistence, login behavior | In-memory events/logs implemented; durable user options, notifications and login item pending |
| AI desktop/CLI launch controls | Implemented; authentication/run attachment are not inferred |
| Existing SSH session control | Implemented locally; another-device validation pending |
| Full remote screen/input / companion client | Pending; not supplied merely by keeping the Mac awake |

## Planned extension examples

Project tests, local Git snapshots, workspace launch recipes, completion sounds,
backup commands, and personal reporting. Event binding and reviewed content are
implemented; periodic hooks, richer scoped capabilities, signed catalogs, package
assets, and integration-specific UIs need design and validation.

## Completion gate

A capability is not complete because a checkbox or file exists. Each needs a
usable UI or documented automation surface, failure handling, relevant tests, and
hardware or permission evidence where applicable. Beta and any "full parity"
claim require owner approval of this checklist and the supported-machine matrix.
