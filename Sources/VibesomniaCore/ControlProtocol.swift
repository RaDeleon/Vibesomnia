// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public enum ControlAction: String, Codable, Sendable {
    case start, stop, toggle, launch, displayOff, quit
}

public struct ControlRequest: Codable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var action: ControlAction
    public var session: SessionRequest?
    public var app: String?
    public init(action: ControlAction, session: SessionRequest? = nil, app: String? = nil) {
        id = UUID(); createdAt = Date(); self.action = action; self.session = session; self.app = app
    }
    public func validate(now: Date = Date()) throws {
        guard abs(now.timeIntervalSince(createdAt)) <= 30 else {
            throw VibeError.message("Control request expired; send it again.")
        }
        try session?.validate()
        if action == .launch, !["claude", "chatgpt", "codex", "claude-code", "codex-cli"].contains(app ?? "") {
            throw VibeError.message("Unknown app. Use claude, chatgpt, codex, claude-code, or codex-cli.")
        }
    }
}

public struct ControlReply: Codable, Sendable {
    public let ok: Bool
    public let message: String
    public init(ok: Bool, message: String) { self.ok = ok; self.message = message }
}

/// Same-user file IPC. There is no listener, token, shell endpoint, or public network port.
public struct ControlTransport {
    public let root: URL
    public var inbox: URL { root.appendingPathComponent("inbox", isDirectory: true) }
    public var replies: URL { root.appendingPathComponent("replies", isDirectory: true) }
    public var status: URL { root.appendingPathComponent("status.json") }

    public init(root: URL? = nil) {
        self.root = root ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Vibesomnia/Control", isDirectory: true)
    }

    public func prepare() throws {
        for directory in [root, inbox, replies] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                     attributes: [.posixPermissions: 0o700])
            let attributes = try FileManager.default.attributesOfItem(atPath: directory.path)
            guard attributes[.type] as? FileAttributeType == .typeDirectory,
                  (attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid() else {
                throw VibeError.message("Control directory must be a real directory owned by the current user.")
            }
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        }
    }

    public func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    public func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard attributes[.type] as? FileAttributeType == .typeRegular,
              (attributes[.size] as? NSNumber)?.intValue ?? 0 <= 65536 else {
            throw VibeError.message("Invalid control file.")
        }
        return try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }

    public func freshStatus(now: Date = Date()) throws -> AppStatus {
        let snapshot = try read(AppStatus.self, from: status)
        guard now.timeIntervalSince(snapshot.updatedAt) < 10 else {
            throw VibeError.message("Vibesomnia is not responding. Open the app in your logged-in Mac session.")
        }
        return snapshot
    }
}
