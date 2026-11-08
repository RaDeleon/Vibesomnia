// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import XCTest
@testable import VibesomniaCore

final class ExtensionTests: XCTestCase {
    func testLeaseExpiresWithoutFreshSequence() {
        var watch = LeaseWatchdog(nonce: "test", now: 10)
        XCTAssertFalse(watch.receive(.init(nonce: "test", sequence: 1), now: 11))
        XCTAssertFalse(watch.receive(.init(nonce: "test", sequence: 1), now: 18))
        XCTAssertTrue(watch.expired(now: 19))
    }
    func testWrongNonceCannotRenewOrStopLease() {
        var watch = LeaseWatchdog(nonce: "owner", now: 0)
        XCTAssertFalse(watch.receive(.init(nonce: "intruder", sequence: 900, stop: true), now: 7))
        XCTAssertTrue(watch.expired(now: 8))
    }
    func testValidStopAndRenewal() {
        var watch = LeaseWatchdog(nonce: "owner", now: 0)
        XCTAssertFalse(watch.receive(.init(nonce: "owner", sequence: 1), now: 7))
        XCTAssertFalse(watch.expired(now: 8))
        XCTAssertTrue(watch.receive(.init(nonce: "owner", sequence: 2, stop: true), now: 9))
    }
    func testReviewFingerprintIncludesCodeAndPermissions() throws {
        var manifest = AddOnManifest(id: "test", name: "Test", summary: "")
        let original = try manifest.fingerprint(script: Data("print hello".utf8))
        XCTAssertNotEqual(original, try manifest.fingerprint(script: Data("print changed".utf8)))
        manifest.events = [.sessionStarted]
        XCTAssertNotEqual(original, try manifest.fingerprint(script: Data("print hello".utf8)))
    }
    func testAddonRejectsTraversalAndUnboundedRuns() {
        for filename in ["../main.sh", "/bin/sh", "a/b.sh", "..hidden"] {
            let manifest = AddOnManifest(id: "test", name: "Test", summary: "", entryPoint: filename)
            XCTAssertThrowsError(try manifest.validate())
        }
        XCTAssertThrowsError(try AddOnManifest(id: "../bad", name: "Bad", summary: "").validate())
        XCTAssertThrowsError(try AddOnManifest(id: "test", name: "Test", summary: "", timeoutSeconds: 9999).validate())
    }
    func testScriptRunsWithEventAndCleanEnvironment() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        setenv("VIBE_TEST_SECRET", "not-for-addon", 1)
        defer { unsetenv("VIBE_TEST_SECRET") }
        let result = try await ScriptRunner.run(manifest: .init(id: "test", name: "Test", summary: ""),
            script: Data("print $VIBESOMNIA_EVENT; print ${VIBE_TEST_SECRET-unset}".utf8), directory: directory, event: .sessionStarted)
        XCTAssertTrue(result.contains("sessionStarted"))
        XCTAssertTrue(result.contains("unset"))
        XCTAssertFalse(result.contains("not-for-addon"))
    }
    func testScriptCancellation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let task = Task { try await ScriptRunner.run(manifest: .init(id: "test", name: "Test", summary: ""),
            script: Data("sleep 10".utf8), directory: directory, event: .manual) }
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()
        do { _ = try await task.value; XCTFail("Cancelled script succeeded") }
        catch { XCTAssertTrue(error.localizedDescription.contains("cancelled")) }
    }
    func testCapturedOutputIsBounded() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let script = Data("printf '%100000s' x".utf8)
        do {
            let result = try await ScriptRunner.run(manifest: .init(id: "test", name: "Test", summary: ""),
                                                    script: script, directory: directory, event: .manual)
            XCTAssertLessThanOrEqual(result.utf8.count, 65536)
        } catch { XCTAssertTrue(error.localizedDescription.contains("64 KiB")) }
    }
    func testScriptTimeout() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        do {
            _ = try await ScriptRunner.run(manifest: .init(id: "test", name: "Test", summary: "", timeoutSeconds: 1),
                script: Data("sleep 10".utf8), directory: directory, event: .manual)
            XCTFail("Timed-out script succeeded")
        } catch { XCTAssertTrue(error.localizedDescription.contains("timed out")) }
    }
}
