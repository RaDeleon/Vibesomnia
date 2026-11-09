// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: SessionStore
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Button { store.page = .dashboard } label: { Label("Dashboard", systemImage: "chevron.left") }
                Text("Settings").font(.largeTitle.bold())
                Spacer()
            }
            Picker("Settings section", selection: $store.settingsTab) {
                ForEach(SettingsTab.allCases) { tab in Label(tab.rawValue, systemImage: tab.icon).tag(tab) }
            }.pickerStyle(.segmented).labelsHidden()
            switch store.settingsTab {
            case .general: general
            case .crew: crew
            case .scripts:
                if store.isPreview {
                    Text("Read-only UI preview. Script storage and execution are disabled.").foregroundStyle(.secondary)
                    Spacer()
                } else { AddOnsView(store: store.addons) }
            case .recap: recaps
            }
        }.padding(28)
    }
    private var general: some View {
        Form {
            Section("Session defaults") {
                Toggle("Let the display sleep", isOn: $store.allowDisplaySleep)
                Toggle("Start new sessions with closed-lid protection", isOn: $store.closedLid)
                Text("These defaults apply when a session starts. Closed-lid protection requests administrator approval each time; its live status is shown on the dashboard.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Battery protection") {
                Toggle("End sessions at 20% battery", isOn: $store.batteryProtection)
                Text("Applies when running on battery. Other apps may still prevent sleep.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Startup & recovery") {
                Text("Sessions and automatic app triggers do not resume after relaunch. No login item is installed.")
                Text("Vibesomnia releases its native sleep assertions on exit. Its temporary closed-lid guard restores the setting it owns on stop or lost heartbeat.")
                    .foregroundStyle(.secondary)
                Button("Open setup guide") { store.showSetup = true }
            }
        }.formStyle(.grouped)
    }
    private var crew: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Automatically show running catalog apps", isOn: $store.autoShowRunning)
            Text("Pin apps to keep them visible when closed. Unpin to remove them; a running app still appears while automatic discovery is on. Adding an app grants no access to its chats or accounts.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("Add application…", systemImage: "plus") { store.addApplication() }.disabled(store.isPreview)
                Button("Refresh", systemImage: "arrow.clockwise") { store.refreshApps() }
            }
            List(store.apps) { app in
                HStack(spacing: 12) {
                    CrewIcon(store: store, app: app)
                    VStack(alignment: .leading) {
                        Text(app.name)
                        Text(app.running ? "Running" : app.installed ? "Installed" : "Not installed").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("Pinned", isOn: Binding(get: { store.pinnedApps.contains(app.id) }, set: { store.pinApp(app.id, $0) }))
                        .toggleStyle(.checkbox).accessibilityLabel("Pin \(app.name)")
                }.padding(.vertical, 4)
            }.clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    private var recaps: some View {
        Form {
            Section("Session recap") {
                Toggle("Show a recap when my session ends", isOn: $store.recapEnabled)
                Text("Summarizes the session interval, end reason and apps observed running. Kept only in memory until dismissed or the app closes. No screenshots, prompts, conversations or model activity are collected.")
            }
            Section("AI work recap with Computer History") {
                Text("Use “Copy AI recap prompt” on a completed session and paste it into ChatGPT/Codex with Computer History enabled. It asks the assistant to use the exact session interval and disclose missing history.")
                Text("An automatic Computer History connection is not available in this build. Vibesomnia does not access another app’s private history files or change its recording settings.")
                    .foregroundStyle(.secondary)
            }
        }.formStyle(.grouped)
    }
}
