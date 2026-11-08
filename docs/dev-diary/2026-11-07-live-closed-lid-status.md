# When “active” did not mean protected

Date: 2026-11-07 · Status: unpublished website notes · Version: alpha.6

## The problem

While inspecting the running alpha.4 build, the app reported a closed-lid session
and its guard was alive, but macOS reported SleepDisabled=0. The dashboard switch
also represented the next-session preference, so a session started through the
CLI could be active while that switch was off. These were two different sources
of misleading status. We have not established which process cleared the flag.

## What changed

Alpha.6 checks the actual system setting in both the app and guard. A live worker
is necessary but insufficient. If protection disappears, the session ends and
reports the problem rather than silently turning the global setting back on.
The dashboard switch now controls current protection. Turning it off leaves
ordinary keep-awake running; switching modes preserves the existing timer.
Saved startup defaults remain explicitly separate in Settings and setup.

## Evidence and unfinished work

All 27 automated tests pass. The updated local bundle launches as alpha.6, and
live status shows fresh protection checks consistent with SleepDisabled=1.
ChatGPT and Claude Desktop both report running. These observations do not prove
remote interaction, physical lid cycling, or the complete failure recovery matrix.
Computer-use inspection timed out, so visual confirmation was requested from the
owner. Live loss-of-override injection and repeat-cycle acceptance remain open.

The GitHub repository sidebar showed tags and a create-release link even though
the Releases page contained the published alpha.5 prerelease and installer assets.
The README now links that download prominently and distinguishes it from the
newer local alpha.6 build. No new binary release was published for this fix.

## Possible article angle

A useful status indicator must verify the outcome it claims. Process liveness
and a saved checkbox are both easy to measure; neither alone proves the Mac is
protected from lid sleep. This bug made that distinction visible.
