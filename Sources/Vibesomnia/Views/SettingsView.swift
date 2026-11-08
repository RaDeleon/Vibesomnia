// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SessionStore
    var body: some View {
        Form {
            Section("Battery") {
                Toggle("End sessions on battery at 20%", isOn: $store.batteryProtection)
                Text("Prevents this app from holding the Mac awake on a low battery. Other apps may still prevent sleep.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Alpha behavior") {
                Text("Sessions and triggers do not resume automatically after relaunch. No background login item is installed.")
                Text("Native power assertions are released on exit. If an Amphetamine session is interrupted, the next launch offers explicit recovery.")
            }
        }.formStyle(.grouped).frame(width: 470, height: 300)
    }
}
