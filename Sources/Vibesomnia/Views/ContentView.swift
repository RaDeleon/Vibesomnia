// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI
import VibesomniaCore

struct ContentView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
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
                HStack(alignment: .top, spacing: 20) {
                    sessionCard.frame(maxWidth: .infinity)
                    workspaceCard.frame(maxWidth: .infinity)
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
                    Text("0.1.0-alpha.4 · Open source · Created by Angelo De Leon")
                    Spacer()
                    Link("Source & roadmap", destination: URL(string: "https://github.com/RaDeleon/Vibesomnia")!)
                }.font(.caption).foregroundStyle(.secondary)
            }.padding(30)
        }
        .frame(minWidth: 800, minHeight: 620)
        .toolbar { SettingsLink() }
    }

    private var bundledAppIcon: NSImage {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) { return image }
        return NSApp.applicationIconImage
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(nsImage: bundledAppIcon)
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
                if let end = store.session?.endsAt {
                    Text(end, style: .timer).monospacedDigit()
                } else if store.session != nil { Text("Until you say stop").font(.caption).foregroundStyle(.secondary) }
                if let battery = store.battery {
                    Text("\(battery.percent)% · \(battery.onBattery ? "Battery" : "Power adapter")")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.font(.callout)
        }
    }

    private var sessionCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Text("STAY AWHILE").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Toggle("End after a timer", isOn: $store.timed)
                if store.timed {
                    HStack { Text("Minutes"); TextField("Minutes", value: $store.minutes, format: .number).frame(width: 80) }
                }
                Toggle("Let the display sleep", isOn: $store.allowDisplaySleep)
                Toggle("Keep running with lid closed", isOn: $store.closedLid)
                if store.closedLid {
                    Text("Uses Vibesomnia’s own temporary power guard. macOS requests administrator approval for each session. Normal sleep returns on stop, exit, or lost heartbeat.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Picker("While app runs", selection: $store.selectedApp) {
                    Text("Any / manual session").tag("")
                    ForEach(store.apps.filter { $0.installed && $0.bundleID != nil }) { app in
                        Text(app.name).tag(app.bundleID ?? "")
                    }
                }
                Toggle("Start when selected app runs", isOn: $store.autoStart).disabled(store.selectedApp.isEmpty)
                Text("Session options apply to the next session.").font(.caption).foregroundStyle(.secondary)
                Button {
                    store.perform {
                        if store.session == nil { try await store.start() }
                        else { try await store.stop() }
                    }
                } label: {
                    Label(store.busy ? "Updating…" : (store.session == nil ? "Start session" : "End session"),
                          systemImage: store.session == nil ? "play.fill" : "stop.fill")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).controlSize(.large).disabled(store.busy || (store.needsRecovery && store.session == nil))
                Text(store.session?.backend == .closedLid ? "Closed-lid guard active · no Amphetamine needed" : "Native sessions prevent idle sleep; they do not override lid-close sleep.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(12)
        }
    }

    private var workspaceCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Text("YOUR NIGHT CREW").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(store.apps) { app in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name).fontWeight(.medium)
                            Text(app.bundleID == nil && app.installed ? "CLI installed · opens in Terminal" : app.running ? "Running" : app.installed ? "Ready to launch" : "Not installed")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(app.running ? "Open" : "Launch") { store.perform { try await store.launch(app.id) } }
                            .disabled(!app.installed)
                    }
                    if app.id != "codex-cli" { Divider() }
                }
                Text("Detects app availability only. No conversations, prompts, or API keys are read.")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(12)
        }
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
