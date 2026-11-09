// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public struct CrewProduct: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let bundleIDs: [String]
    public let appNames: [String]
    public let executable: String?
    public init(_ id: String, _ name: String, bundles: [String] = [], names: [String] = [], executable: String? = nil) {
        self.id = id; self.name = name; bundleIDs = bundles; appNames = names; self.executable = executable
    }
}

public enum NightCrewCatalog {
    public static let products: [CrewProduct] = [
        .init("claude", "Claude Desktop", bundles: ["com.anthropic.claudefordesktop"], names: ["Claude"]),
        .init("chatgpt", "ChatGPT", bundles: ["com.openai.chat", "com.openai.codex"], names: ["ChatGPT"]),
        .init("codex", "Codex", bundles: ["com.openai.codex"], names: ["Codex"]),
        .init("claude-code", "Claude Code", executable: "claude"),
        .init("codex-cli", "Codex CLI", executable: "codex"),
        .init("cursor", "Cursor", bundles: ["com.todesktop.230313mzl4w4u92"], names: ["Cursor"]),
        .init("opencode", "OpenCode", names: ["OpenCode", "opencode"], executable: "opencode"),
        .init("warp", "Warp", bundles: ["dev.warp.Warp-Stable"], names: ["Warp"]),
        .init("terax", "Terax", bundles: ["app.crynta.terax"], names: ["Terax"]),
        .init("orca", "Orca", bundles: ["com.stablyai.orca"], names: ["Orca"]),
        .init("atlas-ide", "Atlas IDE", bundles: ["dev.atlas.ide"], names: ["Atlas"]),
        .init("bb", "bb", bundles: ["dev.bb.desktop"], names: ["bb"]),
        .init("t3code", "T3 Code", bundles: ["com.t3tools.t3code"], names: ["T3 Code", "T3 Code (Beta)"]),
        .init("herdr", "herdr", names: ["herdr"]),
        .init("lmstudio", "LM Studio", names: ["LM Studio"]),
        .init("bionic", "Bionic", bundles: ["ai.elementlabs.bionic"], names: ["Bionic"]),
        .init("ollama", "Ollama", bundles: ["com.electron.ollama"], names: ["Ollama"]),
        .init("cmux", "cmux", bundles: ["com.cmuxterm.app"], names: ["cmux"])
    ]
    public static let defaultPinned = ["claude", "chatgpt", "codex", "claude-code", "codex-cli"]
    public static func product(bundleID: String, names: [String]) -> String? {
        if let original = DesktopAppIdentity.product(bundleID: bundleID, names: names) { return original }
        if let exact = products.first(where: { $0.bundleIDs.contains(bundleID) }) { return exact.id }
        // Never confuse OpenAI's Atlas browser with the independently developed Atlas IDE.
        if bundleID.hasPrefix("com.openai.") { return nil }
        return products.first { item in
            item.bundleIDs.isEmpty && item.appNames.contains { expected in names.contains { $0.caseInsensitiveCompare(expected) == .orderedSame } }
        }?.id
    }
    public static func visible(_ apps: [WorkspaceApp], pinned: Set<String>, autoShowRunning: Bool) -> [WorkspaceApp] {
        apps.filter { pinned.contains($0.id) || (autoShowRunning && $0.running) }
    }
}

public enum SessionDuration {
    public static let presets = [5, 10, 30, 60] + Array(2...12).map { $0 * 60 }
    public static func title(_ minutes: Int) -> String {
        minutes >= 60 && minutes % 60 == 0 ? "\(minutes / 60) \(minutes == 60 ? "hour" : "hours")" : "\(minutes) minutes"
    }
    public static func countdown(_ seconds: Int) -> String {
        let value = max(0, seconds)
        return String(format: "%02d:%02d:%02d", value / 3600, (value % 3600) / 60, value % 60)
    }
}
