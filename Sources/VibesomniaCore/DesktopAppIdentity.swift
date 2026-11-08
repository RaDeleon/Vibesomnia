// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation

/// Product identity is separate from bundle identity: some ChatGPT builds use
/// the Codex bundle identifier. Names disambiguate that shared identifier.
public enum DesktopAppIdentity {
    public static func product(bundleID: String, names: [String]) -> String? {
        switch bundleID {
        case "com.anthropic.claudefordesktop": return "claude"
        case "com.openai.chat": return "chatgpt"
        case "com.openai.codex":
            return names.contains { $0.caseInsensitiveCompare("ChatGPT") == .orderedSame }
                ? "chatgpt" : "codex"
        default: return nil
        }
    }
}
