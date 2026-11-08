// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation

/// Only preferences persist. Sessions and privileged authorization never do.
public struct SetupPreferences: Codable, Equatable {
    public var completed = false
    public var allowDisplaySleep = true
    public var closedLid = false
    public var batteryProtection = true
    public var confirmedRemoteTest = false
    public init() {}

    public static let storageKey = "setup.preferences.v1"
    public static func load(from defaults: UserDefaults?) -> Self {
        guard let data = defaults?.data(forKey: storageKey),
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return value
    }
    public func save(to defaults: UserDefaults?) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults?.set(data, forKey: Self.storageKey)
    }
}
