// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit

@MainActor
enum SupportPage {
    static func open() {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Support/index.html"),
              FileManager.default.fileExists(atPath: url.path) else { return }
        NSWorkspace.shared.open(url)
    }
}
