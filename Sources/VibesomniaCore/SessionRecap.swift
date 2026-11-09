// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation

/// Session metadata only. An app being open is not evidence of completed AI work.
public struct SessionRecap: Sendable {
    public let startedAt: Date
    public let endedAt: Date
    public let reason: String
    public let observedApps: [String]
    public init(startedAt: Date, endedAt: Date, reason: String, observedApps: [String]) {
        self.startedAt = startedAt; self.endedAt = endedAt; self.reason = reason
        self.observedApps = observedApps.sorted()
    }
    public var text: String {
        let iso = ISO8601DateFormatter()
        return "Vibesomnia session\nFrom: \(iso.string(from: startedAt))\nTo: \(iso.string(from: endedAt))\nEnded: \(reason)\nApps observed running: \(observedApps.isEmpty ? "None" : observedApps.joined(separator: ", "))\nThis records app presence, not AI tasks, model activity, or completed work."
    }
    public var historyPrompt: String {
        "Use Computer History, if enabled and available, to recap my AI development work within this exact interval. Check capture status and coverage first. Distinguish observed actions, inferred context, and verified results; identify gaps. Do not invent work based only on an app being open. Do not change observation settings.\n\n" + text
    }
}
