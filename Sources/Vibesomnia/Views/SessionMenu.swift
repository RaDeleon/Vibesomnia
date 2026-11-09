// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI
import VibesomniaCore

struct SessionMenu: View {
    @ObservedObject var store: SessionStore
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Text(store.session == nil ? "Off duty" : "Keeping your Mac awake")
        if let countdown = store.countdown { Text("Remaining: \(countdown)") }
        else if store.session != nil { Text("Until you say stop") }
        Button(store.session == nil ? "Start Session" : "End Session") {
            store.perform {
                if store.session == nil { try await store.start() }
                else { try await store.stop() }
            }
        }.disabled(store.busy)
        Menu(store.session == nil ? "Start for…" : "Set Time Remaining") {
            duration(nil)
            Divider()
            ForEach(SessionDuration.presets, id: \.self) { minutes in duration(minutes) }
        }.disabled(store.busy || store.needsRecovery)
        Divider()
        Button("Open Vibesomnia") { store.page = .dashboard; openWindow(id: "workspace"); NSApp.activate(ignoringOtherApps: true) }
        Button("Display Off Now") { store.perform { try await store.displayOff() } }
        WorkspaceSettingsCommand(store: store)
        Button("Support Vibesomnia") { SupportPage.open() }
        Divider()
        Button("Quit Vibesomnia") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
    private func duration(_ minutes: Int?) -> some View {
        Button(minutes.map(SessionDuration.title) ?? "Indefinitely") {
            store.perform {
                try store.selectDuration(minutes)
                if store.session == nil { try await store.start() }
            }
        }
    }
}

struct WorkspaceSettingsCommand: View {
    @ObservedObject var store: SessionStore
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Settings…") {
            store.showSettings()
            openWindow(id: "workspace")
            NSApp.activate(ignoringOtherApps: true)
        }.keyboardShortcut(",").disabled(store.isPreview)
    }
}
