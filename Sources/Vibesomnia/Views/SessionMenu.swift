// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI

struct SessionMenu: View {
    @ObservedObject var store: SessionStore
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Text(store.session == nil ? "Off duty" : "Keeping your Mac awake")
        Button(store.session == nil ? "Start Session" : "End Session") {
            store.perform {
                if store.session == nil { try await store.start() }
                else { try await store.stop() }
            }
        }.disabled(store.busy)
        Divider()
        Button("Open Vibesomnia") { openWindow(id: "workspace"); NSApp.activate(ignoringOtherApps: true) }
        Button("Display Off Now") { store.perform { try await store.displayOff() } }
        SettingsLink()
        Divider()
        Button("Quit Vibesomnia") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
