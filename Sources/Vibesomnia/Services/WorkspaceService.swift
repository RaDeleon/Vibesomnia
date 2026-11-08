// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import VibesomniaCore

@MainActor
struct WorkspaceService {
    private let gui = [("claude", "Claude Desktop"), ("chatgpt", "ChatGPT"), ("codex", "Codex")]

    var runningBundleIDs: Set<String> {
        Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }

    private struct DiscoveredApp {
        let product: String
        let bundleID: String
        let url: URL
        let running: Bool
    }

    private func discover() -> [DiscoveredApp] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        // Running bundles work even when Launch Services has not registered an app.
        var urls = runningApps.compactMap(\.bundleURL)
        urls += ["com.anthropic.claudefordesktop", "com.openai.chat", "com.openai.codex"]
            .compactMap { workspace.urlForApplication(withBundleIdentifier: $0) }
        let roots = [URL(fileURLWithPath: "/Applications"),
                     FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        urls += roots.flatMap { root in
            ["Claude", "ChatGPT", "Codex"].map { root.appendingPathComponent("\($0).app") }
        }
        var seen = Set<URL>()
        return urls.compactMap { candidate in
            let url = candidate.resolvingSymlinksInPath().standardizedFileURL
            guard seen.insert(url).inserted, let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier else { return nil }
            let names = [bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
                         bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
                         url.deletingPathExtension().lastPathComponent].compactMap { $0 }
            guard let product = DesktopAppIdentity.product(bundleID: bundleID, names: names) else { return nil }
            let running = runningApps.contains {
                $0.bundleURL?.resolvingSymlinksInPath().standardizedFileURL == url
            }
            return DiscoveredApp(product: product, bundleID: bundleID, url: url, running: running)
        }
    }

    func url(for id: String) -> URL? {
        let matches = discover().filter { $0.product == id }
        return (matches.first(where: \.running) ?? matches.first)?.url
    }

    func executable(for id: String) -> String? {
        let name = id == "claude-code" ? "claude" : "codex"
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return ["\(home)/.local/bin", "/opt/homebrew/bin", "/usr/local/bin", "\(home)/.npm-global/bin"]
            .map { "\($0)/\(name)" }.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func snapshot() -> [WorkspaceApp] {
        let discovered = discover()
        var apps = gui.map { id, name in
            let matches = discovered.filter { $0.product == id }
            let selected = matches.first(where: \.running) ?? matches.first
            return WorkspaceApp(id: id, name: name, installed: selected != nil,
                                running: matches.contains(where: \.running), bundleID: selected?.bundleID)
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
