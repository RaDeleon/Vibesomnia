// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import VibesomniaCore

struct ProcessRunner {
    static func run(_ path: String, _ arguments: [String]) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments
            let output = Pipe()
            process.standardOutput = output
            process.standardError = output
            try process.run()
            // Drain before waiting to avoid a full pipe deadlocking a child process.
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            guard process.terminationStatus == 0 else {
                throw VibeError.message(text.isEmpty ? "Command failed (\(process.terminationStatus))." : text)
            }
            return text
        }.value
    }

    static func appleScript(_ source: String) async throws -> String {
        try await run("/usr/bin/osascript", ["-e", source])
    }
}
