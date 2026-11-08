// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import VibesomniaCore

let help = """
Vibesomnia 0.1.0-alpha.1 — control your logged-in Mac's AI workspace.

Usage: vibesomnia-cli <command> [options]
  status                   Print fresh app status as JSON
  start                    Start an indefinite session (display may sleep)
  stop                     End Vibesomnia's current session
  toggle                   Start or end a session
  launch <app>             claude | chatgpt | codex | claude-code | codex-cli
  display-off              Turn displays off now
  quit                     End the session and quit Vibesomnia

Start/toggle options:
  --minutes <1–10080>       End automatically after this many minutes
  --while-app <bundle-id>   End when this GUI app closes (it must be running)
  --keep-display-on        Also prevent idle display sleep
  --closed-lid             Use the optional Amphetamine backend

Open Vibesomnia.app before using the CLI. Over SSH, log in as the same macOS
user. This CLI never opens a network port or executes arbitrary remote code.
"""

func run() throws {
    var args = Array(CommandLine.arguments.dropFirst())
    guard !args.isEmpty, !["help", "--help", "-h"].contains(args[0]) else { print(help); return }
    if args == ["--version"] { print("0.1.0-alpha.1"); return }
    let verb = args.removeFirst()
    let transport = ControlTransport()
    try transport.prepare()
    if verb == "status" {
        guard args.isEmpty else { throw VibeError.message("status takes no options") }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        print(String(decoding: try encoder.encode(transport.freshStatus()), as: UTF8.self))
        return
    }
    let action: ControlAction
    switch verb {
    case "start": action = .start
    case "stop": action = .stop
    case "toggle": action = .toggle
    case "launch": action = .launch
    case "display-off": action = .displayOff
    case "quit": action = .quit
    default: throw VibeError.message("Unknown command: \(verb). Use --help.")
    }
    var request = SessionRequest()
    var app: String?
    if action == .launch {
        guard args.count == 1 else { throw VibeError.message("launch requires exactly one app identifier") }
        app = args.removeFirst()
    }
    while !args.isEmpty {
        guard action == .start || action == .toggle else { throw VibeError.message("\(verb) takes no options") }
        switch args.removeFirst() {
        case "--closed-lid": request.closedLid = true
        case "--keep-display-on": request.allowDisplaySleep = false
        case "--minutes":
            guard !args.isEmpty, let minutes = Int(args.removeFirst()) else { throw VibeError.message("--minutes requires a number") }
            request.minutes = minutes
        case "--while-app":
            guard !args.isEmpty else { throw VibeError.message("--while-app requires a bundle identifier") }
            request.whileApp = args.removeFirst()
        default: throw VibeError.message("Unknown option. Use --help.")
        }
    }
    let command = ControlRequest(action: action, session: request, app: app)
    try command.validate()
    _ = try transport.freshStatus()
    let url = transport.inbox.appendingPathComponent("\(command.id).json")
    let replyURL = transport.replies.appendingPathComponent("\(command.id).json")
    try transport.write(command, to: url)
    defer {
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: replyURL)
    }
    let deadline = Date().addingTimeInterval(15)
    while Date() < deadline {
        if FileManager.default.fileExists(atPath: replyURL.path) {
            let reply = try transport.read(ControlReply.self, from: replyURL)
            guard reply.ok else { throw VibeError.message(reply.message) }
            print(reply.message)
            return
        }
        Thread.sleep(forTimeInterval: 0.1)
    }
    throw VibeError.message("No reply within 15 seconds. The app may be waiting for macOS permission; check the Mac before retrying.")
}

do { try run() }
catch {
    FileHandle.standardError.write(Data("vibesomnia-cli: \(error.localizedDescription)\n".utf8))
    exit(1)
}
