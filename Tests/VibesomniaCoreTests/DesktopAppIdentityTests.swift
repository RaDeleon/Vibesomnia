// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import XCTest
@testable import VibesomniaCore

final class DesktopAppIdentityTests: XCTestCase {
    func testChatGPTWithEitherObservedBundleIdentifier() {
        XCTAssertEqual(DesktopAppIdentity.product(bundleID: "com.openai.chat", names: ["ChatGPT"]), "chatgpt")
        XCTAssertEqual(DesktopAppIdentity.product(bundleID: "com.openai.codex", names: ["ChatGPT"]), "chatgpt")
    }

    func testSeparateCodexAndClaudeKeepTheirIdentity() {
        XCTAssertEqual(DesktopAppIdentity.product(bundleID: "com.openai.codex", names: ["Codex"]), "codex")
        XCTAssertEqual(DesktopAppIdentity.product(bundleID: "com.anthropic.claudefordesktop", names: ["Claude"]), "claude")
    }

    func testNameAloneDoesNotIdentifyAnUnrelatedApp() {
        XCTAssertNil(DesktopAppIdentity.product(bundleID: "example.unrelated", names: ["ChatGPT"]))
    }
}
