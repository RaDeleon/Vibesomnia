#!/bin/zsh
# Read-only diagnostics. Output stays in the app's local result pane.
print "Workspace pulse — $VIBESOMNIA_EVENT"
/bin/date
/usr/bin/uptime
/usr/bin/pmset -g assertions | /usr/bin/head -35
