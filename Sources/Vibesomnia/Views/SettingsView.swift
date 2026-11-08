// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: SessionStore
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        TabView {
            preferences.tabItem { Label("General", systemImage: "gearshape") }
            AddOnsView(store: store.addons).tabItem { Label("Add-ons", systemImage: "puzzlepiece.extension") }
        }.frame(width: 760, height: 580)
    }
    private var preferences: some View {
        Form {
            Section("Battery") {
                Toggle("End sessions on battery at 20%", isOn: $store.batteryProtection)
                Text("Prevents this app from holding the Mac awake on a low battery. Other apps may still prevent sleep.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Setup") {
                Toggle("Let the display sleep", isOn: $store.allowDisplaySleep)
                Toggle("Use closed-lid mode for new sessions", isOn: $store.closedLid)
                Text("Changes apply to the next session. Closed-lid sessions ask for administrator approval each time.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Open setup guide") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "workspace")
                    store.showSetup = true
                }
            }
            Section("Alpha behavior") {
                Text("Sessions and triggers do not resume automatically after relaunch. No background login item is installed.")
                Text("Native power assertions are released on exit. The closed-lid guard restores sleep when the app exits or loses its heartbeat. Explicit recovery is available after guard failure.")
            }
        }.formStyle(.grouped)
    }
}
