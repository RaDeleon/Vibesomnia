// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import XCTest
@testable import VibesomniaCore

final class WorkspaceRefreshTests: XCTestCase {
    func testReschedulePreservesOwnedModeAndOriginalStart() throws {
        let start = Date(timeIntervalSince1970: 1000)
        let original = try ActiveSession(request: .init(minutes: 60, allowDisplaySleep: false,
                                                        closedLid: true, whileApp: "editor"), now: start)
        let updated = try original.changingDuration(to: 5, now: start.addingTimeInterval(120))
        XCTAssertEqual(updated.startedAt, start)
        XCTAssertEqual(updated.endsAt, start.addingTimeInterval(420))
        XCTAssertEqual(updated.backend, .closedLid)
        XCTAssertEqual(updated.request.whileApp, "editor")
        XCTAssertFalse(updated.request.allowDisplaySleep)
        XCTAssertEqual(try updated.changingClosedLid(to: false).endsAt, updated.endsAt)
        XCTAssertNil(try updated.changingDuration(to: nil).endsAt)
        XCTAssertThrowsError(try updated.changingDuration(to: 0))
    }
    func testCountdownNeverCountsUpAfterExpiry() throws {
        let start = Date(timeIntervalSince1970: 0)
        let session = try ActiveSession(request: .init(minutes: 5), now: start)
        XCTAssertEqual(session.remainingSeconds(now: start.addingTimeInterval(0.2)), 300)
        XCTAssertEqual(session.remainingSeconds(now: start.addingTimeInterval(300)), 0)
        XCTAssertEqual(session.remainingSeconds(now: start.addingTimeInterval(1000)), 0)
        XCTAssertEqual(SessionDuration.countdown(43200), "12:00:00")
        XCTAssertEqual(SessionDuration.countdown(-5), "00:00:00")
        XCTAssertNil(try ActiveSession(request: .init()).remainingSeconds())
    }
    func testRequiredPresetsHaveOneHourOnlyOnce() {
        XCTAssertEqual(SessionDuration.presets, [5,10,30,60,120,180,240,300,360,420,480,540,600,660,720])
    }
    func testCrewAutoDiscoveryAndRemoval() {
        let apps = [WorkspaceApp(id: "claude", name: "Claude", installed: true, running: true, bundleID: "claude"),
                    WorkspaceApp(id: "cursor", name: "Cursor", installed: true, running: false, bundleID: "cursor")]
        XCTAssertEqual(NightCrewCatalog.visible(apps, pinned: ["cursor"], autoShowRunning: true).map(\.id), ["claude", "cursor"])
        XCTAssertEqual(NightCrewCatalog.visible(apps, pinned: ["cursor"], autoShowRunning: false).map(\.id), ["cursor"])
        XCTAssertTrue(NightCrewCatalog.visible(apps, pinned: [], autoShowRunning: false).isEmpty)
    }
    func testIdentitySeparatesAtlasAndChatGPTVariants() {
        XCTAssertEqual(NightCrewCatalog.product(bundleID: "dev.atlas.ide", names: ["Atlas"]), "atlas-ide")
        XCTAssertNil(NightCrewCatalog.product(bundleID: "com.openai.atlas", names: ["Atlas"]))
        XCTAssertNil(NightCrewCatalog.product(bundleID: "other.app", names: ["ChatGPT"]))
        XCTAssertEqual(NightCrewCatalog.product(bundleID: "com.openai.codex", names: ["ChatGPT"]), "chatgpt")
        XCTAssertEqual(NightCrewCatalog.product(bundleID: "com.openai.codex", names: ["Codex"]), "codex")
        XCTAssertNotEqual(NightCrewCatalog.product(bundleID: "ai.elementlabs.bionic", names: ["Bionic"]), "lmstudio")
    }
    func testCatalogLaunchRemainsAllowlisted() {
        for item in NightCrewCatalog.products {
            XCTAssertNoThrow(try ControlRequest(action: .launch, app: item.id).validate())
        }
        for invalid in ["custom:arbitrary.bundle", "/bin/sh", "$(whoami)", ""] {
            XCTAssertThrowsError(try ControlRequest(action: .launch, app: invalid).validate())
        }
    }
    func testRecapRequestsEvidenceWithinExactInterval() {
        let recap = SessionRecap(startedAt: Date(timeIntervalSince1970: 0), endedAt: Date(timeIntervalSince1970: 60),
                                 reason: "Timer finished", observedApps: ["ChatGPT", "Claude"])
        XCTAssertTrue(recap.historyPrompt.contains("1970-01-01T00:00:00Z"))
        XCTAssertTrue(recap.historyPrompt.contains("1970-01-01T00:01:00Z"))
        XCTAssertTrue(recap.historyPrompt.contains("not AI tasks"))
        XCTAssertTrue(recap.historyPrompt.contains("Do not change observation settings"))
    }
}
