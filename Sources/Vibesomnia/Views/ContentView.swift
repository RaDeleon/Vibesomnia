// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI
import VibesomniaCore

struct ContentView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        Group {
            if store.page == .settings {
                SettingsView(store: store)
            } else { dashboard }
        }
        .frame(minWidth: 860, minHeight: 680)
        .tint(.purple)
        .navigationTitle(store.isPreview ? "Vibesomnia · UI preview" : "Vibesomnia")
        .toolbar {
            Button("Dashboard", systemImage: "square.grid.2x2") { store.page = .dashboard }
            Button("Setup guide", systemImage: "sparkles") { store.showSetup = true }
            Button("Support Vibesomnia", systemImage: "heart") { SupportPage.open() }
            Button("Settings", systemImage: "gearshape") { store.showSettings() }
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if store.isPreview {
                    Label("Read-only UI preview · your running session is unchanged", systemImage: "eye")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if let error = store.error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout).foregroundStyle(.orange).textSelection(.enabled)
                }
                if store.needsRecovery, store.session == nil {
                    GroupBox("Previous closed-lid session") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("A stopped Vibesomnia power guard left a recovery record. Restore normal sleep settings with administrator approval.")
                            Button("Recover session") { Task { await store.recover() } }.disabled(store.busy)
                        }.padding(8)
                    }
                }
                if let recap = store.lastRecap { SessionRecapView(store: store, recap: recap) }
                HStack(alignment: .top, spacing: 20) {
                    SessionControlsView(store: store).frame(maxWidth: .infinity)
                    NightCrewView(store: store).frame(maxWidth: .infinity)
                }
                remoteCard
                if !store.events.isEmpty {
                    GroupBox("This session’s activity") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(store.events.prefix(6).enumerated()), id: \.offset) { _, event in
                                Text(event).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                    }
                }
                HStack {
                    Text("1.0.0-beta.2 · Open source · Created by Angelo De Leon")
                    Spacer()
                    Link("Source & roadmap", destination: URL(string: "https://github.com/RaDeleon/Vibesomnia")!)
                }.font(.caption).foregroundStyle(.secondary)
            }.padding(30)
        }

    }

    private static let bundledAppIcon: NSImage = {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) { return image }
        return NSApp.applicationIconImage
    }()

    private var header: some View {
        HStack(spacing: 16) {
            Image(nsImage: Self.bundledAppIcon)
                .resizable().interpolation(.high)
                .frame(width: 76, height: 76)
                .accessibilityLabel("Vibesomnia: a late-night developer at a glowing laptop")
            VStack(alignment: .leading, spacing: 4) {
                Text("Vibesomnia").font(.largeTitle.bold())
                Text("You can sleep. Your AI doesn’t have to.").foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Label(store.session == nil ? "Off duty" : "Keeping awake", systemImage: "circle.fill")
                    .foregroundStyle(store.session == nil ? Color.secondary : Color.green)
                if store.session?.endsAt != nil {
                    Text(store.countdown ?? "00:00:00").monospacedDigit()
                        .accessibilityLabel("Time remaining")
                } else if store.session != nil { Text("Until you say stop").font(.caption).foregroundStyle(.secondary) }
                if let battery = store.battery {
                    Text("\(battery.percent)% · \(battery.onBattery ? "Battery" : "Power adapter")")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.font(.callout)
        }.padding(20)
            .background(LinearGradient(colors: [.purple.opacity(0.16), .indigo.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
    }

    private var remoteCard: some View {
        GroupBox("Take the session with you") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Control sessions and launch AI apps over your existing SSH connection. The Mac must be logged in with Vibesomnia running.")
                Text("ssh your-mac '/path/to/vibesomnia-cli status'")
                    .font(.callout.monospaced()).textSelection(.enabled)
                HStack {
                    Button("Copy CLI path") {
                        let path = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/vibesomnia-cli").path
                        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(path, forType: .string)
                    }
                    Button("Sharing settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Sharing-Settings.extension")!)
                    }
                    Button("Display off now") { store.perform { try await store.displayOff() } }
                }
                Text("Screen sharing, remote chat, and unattended login are not implemented. Vibesomnia does not enable SSH or expose a network listener.")
                    .font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
        }
    }
}
