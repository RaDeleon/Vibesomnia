# Workspace controls (unreleased)

These changes are on the development branch; the published V1.0 Beta 1 installer
has not been replaced by this work.

## One window

The toolbar gear, menu-bar Settings item, and Command-comma open Settings inside
the workspace. Dashboard returns to the session without ending it. General covers
session defaults and battery protection; Night Crew manages app visibility;
Scripts explains and runs approved add-ons; Recaps controls optional summaries.

## Timers and Stay awhile

The question-mark button explains each control and when it takes effect.
Duration presets are 5, 10, 30, and 60 minutes (shown as 1 hour), then 2–12 hours.
Custom durations remain available, from 1 minute through seven days.

Before starting, the choices configure the next session. During a session,
choosing a duration resets the remaining time from now; **Set remaining** applies
a custom duration. Turning the timer off makes that session indefinite. Neither
operation restarts the power guard or changes the original session start time,
display policy, or app-lifetime condition. The countdown clamps to zero at expiry.
The menu bar offers **Start for…** when idle and **Set Time Remaining** when active.

Display and app choices apply to the next session. The closed-lid switch changes
the current session immediately and continues to reflect verified ownership.
When idle, turning it on starts a session and requests administrator approval.
An ordinary timer ending releases Vibesomnia's assertions; it does not quit apps.

## Night Crew

The catalog includes Claude Desktop, ChatGPT, Codex, Claude Code/Codex CLI,
Cursor, OpenCode, Warp, Terax, Orca, Atlas IDE, bb, T3 Code, herdr, LM Studio,
Bionic, Ollama and cmux. Bionic and LM Studio have separate entries. Atlas IDE is
separate from OpenAI's Atlas browser.

Icons come from the installed app's bundle through macOS; absent apps and CLI
entries use a system fallback. No logo downloads or embedded browser are needed.
Bundle discovery is cached for 15 seconds and can be refreshed manually; running
state is sampled with the existing session tick. Icons are cached in memory.

- Green means macOS reports the desktop app running.
- Red means it is not running, not installed, or CLI activity is not monitored;
  the accompanying label states which. Installed CLI tools are never called connected.
- Yellow means a launch attempt failed. **Troubleshoot** shows the error and
  suggested recovery steps, with refresh and retry controls.

None of these states proves model activity, authentication or remote reachability.
No conversations, tokens, agent configuration or command-line arguments are read.

Pin a tool to keep it visible while closed. Unpin it to remove that pinned entry.
With automatic discovery enabled, running catalog apps still appear; disable the
option to show only pinned apps. **Add application…** selects a local `.app`,
including apps installed in unusual locations. Custom apps are launchable only
from the local UI; remote CLI launch still accepts only fixed catalog identifiers.

## Session recaps

Recaps are off by default. When enabled, Vibesomnia keeps the session interval,
end reason and names of apps observed running in memory. The last recap appears
after a normal session end and is discarded when dismissed, replaced by the next
session, or on app exit. This is a presence summary, not a record of AI work.

**Copy AI recap prompt** copies the exact UTC interval and an evidence-oriented
request. Paste it into ChatGPT/Codex with Computer History enabled. The assistant
must check capture coverage and distinguish observed actions from assumptions.
No prompt is sent automatically and Vibesomnia does not read history caches.

[OpenAI's Computer History documentation](https://developers.openai.com/codex/customization/computer-history)
describes opt-in history for ChatGPT/Codex, including app/website inclusion rules.
This investigation did not verify a supported third-party native-app API for an
automatic recap. Such a connector remains pending; the host agent's ability to
query Computer History is not a bundled Vibesomnia integration.

## Support

The heart button and menu item open a small bundled HTML page in the default
browser. It offers $1, $5, $10, $20, $50, $100 and a custom USD amount. It currently
shows an explicit not-connected state and cannot collect money. A verified owner
recipient/provider and end-to-end checkout test are required before enabling it.
No payment SDK, account requirement or feature gate is added to the native app.
