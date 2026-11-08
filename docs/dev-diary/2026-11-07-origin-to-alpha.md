# Why I’m building Vibesomnia—and getting the first closed-lid test working

- Date: November 7, 2026 (America/Los_Angeles)
- Versions: alpha.1 through alpha.5; the physical lid test used alpha.4
- Stage: Unpublished working draft for Angelo's review
- Intended destination: angelodeleon.com

## The problem that started it

I use the ChatGPT and Claude desktop apps throughout my workday. I wanted to close
my MacBook, let the screen turn off, and keep the machine working so I could reach
my AI workspace remotely. Opening the lid should return me to normal use. Closing
it again should keep the same session going. When I no longer need that behavior,
I should be able to switch it off.

This started as a request to configure Amphetamine. Then the question became:
what would a keep-awake app look like if it were built around this workflow?

That became Vibesomnia. The goal is eventually to replace Amphetamine's feature
set and add useful AI workspace awareness, remote controls, and user extensions.
That is the destination, not a claim that the first alpha already does everything.

The name came after several directions that did not quite fit. I wanted something
that connected to developers staying up all night vibe coding. Vibesomnia fit that
idea. The bloodshot-eyed developer mascot and glowing workstation banner carry it
through the app and README.

## Keeping the machine awake is only part of the job

The first alpha had native keep-awake sessions, timers, app-lifetime rules, battery
protection, app discovery, and a command-line interface. Closed-lid behavior
initially depended on Amphetamine. I wanted Vibesomnia to handle that itself.

An ordinary idle-sleep assertion does not solve lid-close sleep. The standalone
implementation uses a bundled, temporary power guard that asks for macOS
administrator approval when a closed-lid session starts. It records ownership of
the sleep override and restores it when the session ends.

The failure cases mattered as much as the start button. If the app exits or stops
sending fresh heartbeats, the guard should restore normal sleep. If another tool
already owns an override, Vibesomnia should refuse to overwrite it.

Those checks produced real progress: stopping normally and simulating app exit
both restored sleep. Suspending the app while its process still existed also
worked—the guard restored sleep after roughly 8.4 seconds without a fresh
heartbeat. These are controlled local results, not proof of every failure mode
on every Mac.

One complication was a global sleep override appearing again without a Vibesomnia
owner. Other power-management software was running, but we did not establish
which utility caused it. Rather than assume ownership, Vibesomnia refused it.
The override later cleared before a manual reset was needed.

## A detection bug hiding in plain sight

Vibesomnia said ChatGPT was not installed while I was using it. The installed app
was named ChatGPT but used the bundle identifier `com.openai.codex`. The discovery
code expected `com.openai.chat`, so it classified the installation incorrectly.

The fix combined product names with bundle identifiers and checked actual running
bundle locations, registered applications, and Applications folders. Alpha.4 then
reported both ChatGPT and Claude Desktop as installed and running. Regression
tests cover both observed ChatGPT identifiers and keep a separate Codex app
identity distinct.

That was a useful reminder: an identifier that looks authoritative can still be
the wrong shortcut for the question the user is asking.

## Making room for other people's workflows

I also wanted people to add their own scripts and add-ons. Someone might want to
open a workspace, run tests, play a sound after a session, or run a backup they
control. Those are possibilities, not integrations we have already shipped.

The first implementation includes an editor, import, manual runs, and session
start/end hooks. Users review and approve an exact version of the code. Editing
it invalidates that approval. Scripts run as the regular user, separately from
the privileged power guard, with timeouts and bounded output.

The included examples are small: a local workspace diagnostic and an end-of-shift
chime. These extensions are trusted local scripts, not sandboxed plug-ins. That
boundary needs to stay clear as the feature grows.

## A download people can actually install

A source repository is useful to developers, but I do not want every person
trying Vibesomnia to build it themselves. Alpha.5 adds a universal DMG containing
a standard macOS installer and first-run setup.

The installer puts the app in Applications. Setup detects AI apps, saves sleep
preferences, explains the administrator prompt, and offers a guided lid/remote
test. It does not silently enable SSH or install a persistent background service.
The package refuses to replace a running app or guard.

We built and inspected this installer without interrupting the existing alpha.4
closed-lid session. That was deliberate: packaging a new version should not break
the workspace the current version is keeping alive.

The current DMG is a local alpha test build. The app is ad-hoc signed; the installer
is unsigned and not notarized. Developer ID distribution is prepared in the build
scripts, but credentials and end-to-end distribution testing are still needed.

## The first real lid test

With alpha.4 running, I closed the lid and reported that it seemed to be working.
A check on the Mac confirmed the lid was closed, Vibesomnia was still responding,
and ChatGPT and Claude were still running.

That is an encouraging first hardware observation. It is not yet a completed
remote-access acceptance test. Reopening and reclosing the lid, interacting with
both apps remotely, charger changes, and testing the newly installed alpha.5 still
need explicit verification. Other utilities were also holding power assertions,
so this observation alone does not establish that Vibesomnia was the only thing
keeping the machine awake.

## Where the project stands

Alpha.5 has 23 passing automated tests and passing CI, plus local package and setup
UI checks. The normal-stop, app-exit and heartbeat recovery tests belong to the
earlier standalone guard work. The first physical lid observation belongs to the
still-running alpha.4. Keeping those versions straight matters.

The repo will remain private until testing is complete. It uses AGPL-3.0-only;
Community/Pro editions and monetization are deferred while the basic app gets
reliable. Full Amphetamine parity and built-in remote desktop are still planned.
Today, Vibesomnia keeps the host awake and offers session controls; remote GUI
interaction relies on tools the user already has.

The next useful milestone is a clean installation, first-run setup, and a repeatable
close → connect → open → close again test. After that come broader hardware testing,
signing/notarization, and a public release when I am satisfied with the results.

## Possible follow-up posts

- What happens when a keep-awake app freezes—and why cleanup needs its own process.
- Why the ChatGPT app was running but my app could not find it.
- From a working Mac app to an installer someone else can use.
- What the first real remote/lid tests changed about the design.

## Evidence and editorial notes

This is a draft, not a verbatim account written by Angelo. The motivation comes
from his requests in the development conversation. Technical results are grounded
in the project records and live observations; no usage numbers, development hours,
or broader compatibility claims have been inferred.

- [Engineering session log](../../sessions.log)
- [Version history](../../CHANGELOG.md)
- [Acceptance test checklist](../TESTING.md)
- [Closed-lid ownership and recovery](../CLOSED_LID.md)
- [Installer and distribution guide](../DISTRIBUTION.md)
- [Feature-parity checklist](../PARITY.md)
- [Alpha.4 discovery fix](https://github.com/RaDeleon/Vibesomnia/commit/d17f02d)
- [Alpha.5 installer and setup](https://github.com/RaDeleon/Vibesomnia/commit/4e7098b)

The owner’s “seems to be working” report and the confirmed closed-lid/app-running
observation happened after the alpha.5 build; the active app remained alpha.4.
Do not rewrite that observation as an installed-alpha.5 test or a verified remote
interaction with both apps. Recheck status before turning this draft into a post.
