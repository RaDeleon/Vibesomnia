#!/usr/bin/env python3
"""Exercise the real app's native controls. Start the app and end sessions first."""
# Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import json
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent
CLI = ROOT / "dist/Vibesomnia.app/Contents/MacOS/vibesomnia-cli"


def call(*args, success=True):
    result = subprocess.run([str(CLI), *args], capture_output=True, text=True)
    if (result.returncode == 0) != success:
        raise RuntimeError(f"{args}: {result.stdout}{result.stderr}")
    return result.stdout


def assertions():
    # pmset can emit non-UTF-8 bytes in other apps' assertion descriptions.
    return subprocess.check_output(["pmset", "-g", "assertions"], text=True, errors="replace")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    require("session" not in json.loads(call("status")), "End the current session before this test.")
    call("start", "--minutes", "0", success=False)
    call("launch", "sh -c anything", success=False)
    try:
        call("start")
        lines = [line for line in assertions().splitlines() if "pid " in line and "(Vibesomnia)" in line]
        require(len(lines) == 1 and "PreventUserIdleSystemSleep" in lines[0], "Expected one system assertion.")
        call("stop")
        require("(Vibesomnia)" not in assertions(), "Stop did not release assertions.")
        call("start", "--keep-display-on")
        lines = [line for line in assertions().splitlines() if "pid " in line and "(Vibesomnia)" in line]
        require(len(lines) == 2 and any("PreventUserIdleDisplaySleep" in line for line in lines),
                "Expected system and display assertions.")
        call("toggle")
        require("(Vibesomnia)" not in assertions(), "Toggle did not stop the session.")
        call("toggle")
        require("(Vibesomnia)" in assertions(), "Toggle did not start the session.")
        call("quit")
        for _ in range(50):
            if subprocess.run(["pgrep", "-x", "Vibesomnia"], capture_output=True).returncode != 0:
                break
            time.sleep(0.1)
        else:
            raise RuntimeError("Quit acknowledged but process did not exit.")
        require("(Vibesomnia)" not in assertions(), "Quit did not release assertions.")
    except Exception:
        # Best-effort graceful cleanup; never kill the process to hide a failure.
        subprocess.run([str(CLI), "stop"], capture_output=True, timeout=20)
        raise
    print("PASS: validation, native/display assertions, start/stop/toggle, graceful quit and cleanup.")


if __name__ == "__main__":
    main()
