// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import XCTest
@testable import VibesomniaCore

final class SessionTests: XCTestCase {
    func testTimerEndsAtBoundary() throws {
        let start = Date(timeIntervalSince1970: 1000)
        let session = try ActiveSession(request: .init(minutes: 10), now: start)
        XCTAssertNil(session.endReason(now: start.addingTimeInterval(599), runningBundleIDs: []))
        XCTAssertEqual(session.endReason(now: start.addingTimeInterval(600), runningBundleIDs: []), "Timer finished")
    }

    func testIndefiniteDoesNotExpire() throws {
        let session = try ActiveSession(request: .init(), now: .distantPast)
        XCTAssertNil(session.endsAt)
        XCTAssertNil(session.endReason(now: .distantFuture, runningBundleIDs: []))
    }

    func testAppLifetimeEndsOnlyWhenSelectedAppCloses() throws {
        let session = try ActiveSession(request: .init(whileApp: "com.example.editor"))
        XCTAssertNil(session.endReason(now: Date(), runningBundleIDs: ["com.example.editor", "com.other.app"]))
        XCTAssertEqual(session.endReason(now: Date(), runningBundleIDs: ["com.other.app"]), "Selected app closed")
    }

    func testInvalidDurationsRejected() {
        for minutes in [-1, 0, 10081, Int.max] {
            XCTAssertThrowsError(try ActiveSession(request: .init(minutes: minutes)))
        }
    }

    func testExpiredCommandsCannotStartSessionsAfterRelaunch() {
        var command = ControlRequest(action: .start)
        command.createdAt = Date().addingTimeInterval(-60)
        XCTAssertThrowsError(try command.validate())
    }

    func testLaunchDoesNotAcceptArbitraryCommands() {
        XCTAssertThrowsError(try ControlRequest(action: .launch, app: "sh -c anything").validate())
        XCTAssertNoThrow(try ControlRequest(action: .launch, app: "claude-code").validate())
    }

    func testTransportPermissionsAndStaleStatus() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let transport = ControlTransport(root: directory)
        try transport.prepare()
        let snapshot = AppStatus(session: nil, apps: [], lastError: nil)
        try transport.write(snapshot, to: transport.status)
        XCTAssertNil(try transport.freshStatus().session)
        let attributes = try FileManager.default.attributesOfItem(atPath: transport.root.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o700)
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: transport.status.path)
        XCTAssertEqual((fileAttributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
        XCTAssertThrowsError(try transport.freshStatus(now: Date().addingTimeInterval(11)))
    }

    func testTransportRejectsSymlinkDirectory() throws {
        let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: parent) }
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let destination = parent.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let link = parent.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: destination)
        XCTAssertThrowsError(try ControlTransport(root: link).prepare())
    }
}
