# Scripts and add-ons

Vibesomnia add-ons are small, reviewable local packages, not compiled plug-ins
loaded into the app or its privileged power guard. No marketplace or remote
script-execution endpoint is present.

## Use the app

Open Settings → Add-ons:

- **New script** creates an unapproved package in your AddOns folder.
- **Import add-on** copies a selected package's manifest and entry-point script.
- **Edit** edits script and manifest in-app. **Open folder** supports your editor.
- **Review** displays the actual code, interpreter, event bindings, and timeout.
- **Approve this version** enables only the exact reviewed content hash.
- **Run** invokes it manually; event hooks run only while approved and enabled.
- **Stop script** cancels the current run. Disable an add-on to stop future hooks.

Changing the source, interpreter, timeout, or events requires another approval.
There is no blanket trust based on the package name or installation location.
Bundled examples are installed disabled/unapproved; installation is not execution.

## Package format

```text
my-workflow/
  manifest.json
  main.sh
```

```json
{
  "schemaVersion": 1,
  "id": "my-workflow",
  "name": "My workflow",
  "summary": "A workflow I own and have reviewed.",
  "interpreter": "zsh",
  "entryPoint": "main.sh",
  "events": ["manual", "sessionStarted"],
  "timeoutSeconds": 30
}
```

IDs use lowercase letters, digits, dots, and hyphens. The entry point is one regular
filename, not a directory traversal or absolute path. The app imports only these
two files. Additional assets/package dependencies are not imported in alpha.3.

Interpreters: `zsh`, `bash`, `appleScript`, `python3`. Python requires an installed
`/usr/bin/python3`. Events: `manual`, `sessionStarted`, `sessionEnded`. End hooks
run after normal/manual/timed/app/battery session termination, not during app quit.
App quit cancels running scripts; it does not wait for an end-of-shift test suite.
Overlapping runs are skipped, with a local result message, rather than queued
without bounds. This is a single-runner alpha, not a background job scheduler.

## Runtime contract

Scripts run as the logged-in user; root execution is refused. The approved bytes
are copied to a private temporary snapshot so editing the source after review
cannot swap code into a running invocation. The working directory is the add-on
folder. stdin is closed; noninteractive scripts should not prompt for passwords.

A clean environment includes PATH, HOME, LANG, `VIBESOMNIA_EVENT`, and
`VIBESOMNIA_ADDON_DIR`. Model keys and the app's inherited environment are not
forwarded. These scripts still have your account's normal filesystem/network
access; this is not an OS sandbox or a defense against code you mistakenly trust.

Timeouts are 1–300 seconds. Captured output is limited to 64 KiB; an output-size
monitor terminates a noisy run. Timeout/cancel sends signals to the run's process
group. Deliberately daemonizing/detaching children is unsupported and cannot be
contained by this contract. Scripts should return, not leave agents running
behind the runner. Use the workspace launch controls for long-lived tools.

## Included examples

- **Workspace pulse:** read-only time, uptime, and local power assertions.
- **End-of-shift chime:** a built-in macOS sound on `sessionEnded` or manual run.

## Ideas to adapt

- Run `swift test` or your project's test command on session start.
- Show `git status` or save a local branch/working-tree summary before leaving.
- Open your editor, AI app, and project directory together.
- Export a build report or invoke your own backup command after a session ends.
- Send yourself a notification through a service you explicitly configure.

For example, after setting your own project path and reviewing the command:

```sh
#!/bin/zsh
set -eu
PROJECT="$HOME/Developer/my-project"
cd "$PROJECT"
git status --short
```

Do not paste API tokens into packages or publish private paths/keys in the repo.
A script that sends messages, uploads files, changes a firewall, or performs a
financial action needs the user's own deliberate authorization and configuration;
Vibesomnia approving code is not permission from the data's owner or recipient.
