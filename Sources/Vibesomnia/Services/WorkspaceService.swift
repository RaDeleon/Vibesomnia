// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import VibesomniaCore

@MainActor
struct WorkspaceService {
    private let gui: [(String, String, [String])] = [
        ("claude", "Claude Desktop", ["com.anthropic.claudefordesktop"]),
        ("chatgpt", "ChatGPT", ["com.openai.chat"]),
        ("codex", "Codex", ["com.openai.codex"])
    ]

    var runningBundleIDs: Set<String> {
        Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }

    func url(for id: String) -> URL? {
        guard let entry = gui.first(where: { $0.0 == id }) else { return nil }
        return entry.2.compactMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }.first
    }

    func executable(for id: String) -> String? {
        let name = id == "claude-code" ? "claude" : "codex"
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return ["\(home)/.local/bin", "/opt/homebrew/bin", "/usr/local/bin", "\(home)/.npm-global/bin"]
            .map { "\($0)/\(name)" }.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func snapshot() -> [WorkspaceApp] {
        let running = runningBundleIDs
        var apps = gui.map { id, name, ids in
            WorkspaceApp(id: id, name: name, installed: url(for: id) != nil,
                         running: ids.contains { running.contains($0) }, bundleID: ids.first)
        }
        apps += [("claude-code", "Claude Code"), ("codex-cli", "Codex CLI")].map { id, name in
            WorkspaceApp(id: id, name: name, installed: executable(for: id) != nil,
                         running: false, bundleID: nil)
        }
        return apps
    }

    func launch(_ id: String) async throws {
        if id == "claude-code" || id == "codex-cli" {
            guard let executable = executable(for: id) else { throw VibeError.message("Install \(id) first.") }
            let command = "export PATH=/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH; " + shellQuote(executable)
            let literal = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            _ = try await ProcessRunner.appleScript("tell application \"Terminal\"\nactivate\ndo script \"\(literal)\"\nend tell")
        } else {
            guard let url = url(for: id) else { throw VibeError.message("Application is not installed.") }
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }

    private func shellQuote(_ text: String) -> String { "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'" }
}
