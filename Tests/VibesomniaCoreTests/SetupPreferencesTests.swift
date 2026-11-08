// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import XCTest
@testable import VibesomniaCore

final class SetupPreferencesTests: XCTestCase {
    func testFreshInstallHasSafeDefaults() {
        let value = SetupPreferences.load(from: nil)
        XCTAssertFalse(value.completed)
        XCTAssertTrue(value.allowDisplaySleep)
        XCTAssertFalse(value.closedLid)
        XCTAssertTrue(value.batteryProtection)
        XCTAssertFalse(value.confirmedRemoteTest)
    }

    func testRelaunchRestoresChoicesAndCompletion() {
        let suite = "Vibesomnia.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var value = SetupPreferences()
        value.completed = true
        value.closedLid = true
        value.allowDisplaySleep = false
        value.batteryProtection = false
        value.confirmedRemoteTest = true
        value.save(to: defaults)
        XCTAssertEqual(SetupPreferences.load(from: defaults), value)
    }

    func testDamagedPreferencesReturnToSetupAndSafeDefaults() {
        let suite = "Vibesomnia.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("broken".utf8), forKey: SetupPreferences.storageKey)
        XCTAssertEqual(SetupPreferences.load(from: defaults), SetupPreferences())
    }
}
