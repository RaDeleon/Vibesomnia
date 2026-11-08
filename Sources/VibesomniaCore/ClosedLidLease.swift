// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public struct ClosedLidLease: Codable, Sendable {
    public var nonce: String
    public var sequence: UInt64
    public var stop: Bool
    public init(nonce: String, sequence: UInt64, stop: Bool = false) {
        self.nonce = nonce; self.sequence = sequence; self.stop = stop
    }
}

public struct GuardRecord: Codable, Sendable {
    public var uid: UInt32
    public var parentPID: Int32
    public var parentStamp: UInt64
    public var workerPID: Int32
    public var workerStamp: UInt64
    public var nonce: String
    public var active: Bool
    public var error: String?
    public init(uid: UInt32, parentPID: Int32, parentStamp: UInt64, workerPID: Int32,
                workerStamp: UInt64, nonce: String, active: Bool = false, error: String? = nil) {
        self.uid = uid; self.parentPID = parentPID; self.parentStamp = parentStamp
        self.workerPID = workerPID; self.workerStamp = workerStamp
        self.nonce = nonce; self.active = active; self.error = error
    }
    public static let directory = "/private/var/run/vibesomnia-closed-lid"
    public static let path = directory + "/state.json"
}

/// A replayed heartbeat cannot indefinitely renew a root helper's lease.
public struct LeaseWatchdog {
    public private(set) var sequence: UInt64 = 0
    public private(set) var lastPulse: TimeInterval
    public let nonce: String
    public init(nonce: String, now: TimeInterval) { self.nonce = nonce; lastPulse = now }
    public mutating func receive(_ lease: ClosedLidLease, now: TimeInterval) -> Bool {
        guard lease.nonce == nonce else { return false }
        if lease.stop { return true }
        if lease.sequence > sequence { sequence = lease.sequence; lastPulse = now }
        return false
    }
    public func expired(now: TimeInterval) -> Bool { now - lastPulse >= 8 }
}
