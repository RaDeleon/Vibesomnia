// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import CryptoKit

public enum AddOnEvent: String, Codable, CaseIterable, Sendable {
    case manual, sessionStarted, sessionEnded
}
public enum ScriptInterpreter: String, Codable, CaseIterable, Sendable {
    case zsh, bash, appleScript, python3
    public var path: String {
        switch self {
        case .zsh: return "/bin/zsh"
        case .bash: return "/bin/bash"
        case .appleScript: return "/usr/bin/osascript"
        case .python3: return "/usr/bin/python3"
        }
    }
}
public struct AddOnManifest: Codable, Identifiable, Equatable, Sendable {
    public var schemaVersion: Int
    public var id: String
    public var name: String
    public var summary: String
    public var interpreter: ScriptInterpreter
    public var entryPoint: String
    public var events: [AddOnEvent]
    public var timeoutSeconds: Int
    public init(id: String, name: String, summary: String, interpreter: ScriptInterpreter = .zsh,
                entryPoint: String = "main.sh", events: [AddOnEvent] = [.manual], timeoutSeconds: Int = 30) {
        schemaVersion = 1; self.id = id; self.name = name; self.summary = summary
        self.interpreter = interpreter; self.entryPoint = entryPoint; self.events = events
        self.timeoutSeconds = timeoutSeconds
    }
    public func validate() throws {
        guard schemaVersion == 1, id.range(of: "^[a-z0-9][a-z0-9.-]{0,79}$", options: .regularExpression) != nil,
              !name.isEmpty, name.count <= 80, summary.count <= 1024,
              entryPoint.range(of: "^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,79}$", options: .regularExpression) != nil,
              !entryPoint.contains(".."), !events.isEmpty, Set(events).count == events.count,
              (1...300).contains(timeoutSeconds) else {
            throw VibeError.message("Invalid add-on manifest. Use a single script filename, unique events, and a 1–300 second timeout.")
        }
    }
    public func fingerprint(script: Data) throws -> String {
        try validate()
        guard script.count <= 262144 else { throw VibeError.message("Add-on scripts are limited to 256 KiB.") }
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        return SHA256.hash(data: try encoder.encode(self) + script).map { String(format: "%02x", $0) }.joined()
    }
}
