// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public enum SessionBackend: String, Codable, Sendable {
    case native, closedLid
}

public struct SessionRequest: Codable, Equatable, Sendable {
    public var minutes: Int?
    public var allowDisplaySleep: Bool
    public var closedLid: Bool
    public var whileApp: String?

    public init(minutes: Int? = nil, allowDisplaySleep: Bool = true,
                closedLid: Bool = false, whileApp: String? = nil) {
        self.minutes = minutes
        self.allowDisplaySleep = allowDisplaySleep
        self.closedLid = closedLid
        self.whileApp = whileApp
    }

    public func validate() throws {
        if let minutes, !(1...10080).contains(minutes) {
            throw VibeError.message("Duration must be 1–10080 minutes (up to seven days).")
        }
        if let whileApp, whileApp.isEmpty || whileApp.count > 255 {
            throw VibeError.message("Choose a valid application bundle identifier.")
        }
    }
}

public struct ActiveSession: Codable, Equatable, Sendable {
    public let request: SessionRequest
    public let startedAt: Date
    public let endsAt: Date?
    public let backend: SessionBackend

    public init(request: SessionRequest, now: Date = Date()) throws {
        try request.validate()
        self.request = request
        startedAt = now
        endsAt = request.minutes.map { now.addingTimeInterval(Double($0) * 60) }
        backend = request.closedLid ? .closedLid : .native
    }

    public func endReason(now: Date, runningBundleIDs: Set<String>) -> String? {
        if let endsAt, now >= endsAt { return "Timer finished" }
        if let bundle = request.whileApp, !runningBundleIDs.contains(bundle) {
            return "Selected app closed"
        }
        return nil
    }

    /// Change power mode without extending the timer or losing app/display policy.
    public func changingClosedLid(to enabled: Bool) throws -> ActiveSession {
        var next = request
        next.closedLid = enabled
        return ActiveSession(request: next, startedAt: startedAt, endsAt: endsAt)
    }

    private init(request: SessionRequest, startedAt: Date, endsAt: Date?) {
        self.request = request; self.startedAt = startedAt; self.endsAt = endsAt
        backend = request.closedLid ? .closedLid : .native
    }

    /// A duration selection during a session sets time remaining from now.
    public func changingDuration(to minutes: Int?, now: Date = Date()) throws -> ActiveSession {
        var next = request
        next.minutes = minutes
        try next.validate()
        return ActiveSession(request: next, startedAt: startedAt,
                             endsAt: minutes.map { now.addingTimeInterval(Double($0) * 60) })
    }

    public func remainingSeconds(now: Date = Date()) -> Int? {
        endsAt.map { max(0, Int(ceil($0.timeIntervalSince(now)))) }
    }

}

public struct WorkspaceApp: Codable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var installed: Bool
    public var running: Bool
    public var bundleID: String?
    public init(id: String, name: String, installed: Bool, running: Bool, bundleID: String?) {
        self.id = id; self.name = name; self.installed = installed
        self.running = running; self.bundleID = bundleID
    }
}

public struct AppStatus: Codable, Sendable {
    public var updatedAt: Date
    public var version: String
    public var session: ActiveSession?
    public var apps: [WorkspaceApp]
    public var lastError: String?
    /// Nil when reading older app snapshots that did not verify actual power state.
    public var closedLidActive: Bool?
    public var closedLidVerifiedAt: Date?
    public init(session: ActiveSession?, apps: [WorkspaceApp], lastError: String?,
                closedLidActive: Bool? = nil, closedLidVerifiedAt: Date? = nil) {
        updatedAt = Date(); version = "1.0.0-beta.1"
        self.session = session; self.apps = apps; self.lastError = lastError
        self.closedLidActive = closedLidActive
        self.closedLidVerifiedAt = closedLidVerifiedAt
    }
}

public enum VibeError: LocalizedError {
    case message(String)
    public var errorDescription: String? {
        switch self { case .message(let message): return message }
    }
}
