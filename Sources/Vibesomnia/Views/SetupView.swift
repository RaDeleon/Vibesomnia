// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI
import VibesomniaCore

struct SetupView: View {
    @ObservedObject var store: SessionStore
    let finish: () -> Void
    @State private var step = 0
    private let steps = ["Welcome", "Your apps", "Stay awake", "Try it remotely"]

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 24) {
                if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                   let image = NSImage(contentsOf: url) {
                    Image(nsImage: image).resizable().frame(width: 112, height: 112)
                        .accessibilityLabel("Vibesomnia late-night developer mascot")
                }
                Text("Set up your\nnight shift.").font(.system(size: 27, weight: .bold, design: .rounded))
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(steps.indices, id: \.self) { index in
                        Label(steps[index], systemImage: index < step ? "checkmark.circle.fill" : "\(index + 1).circle\(index == step ? ".fill" : "")")
                            .foregroundStyle(index == step ? Color.accentColor : Color.secondary)
                            .fontWeight(index == step ? .semibold : .regular)
                    }
                }
                Spacer()
                Text(store.isPreview ? "SETUP PREVIEW\nNo settings or power changes" : "BETA · MADE FOR MAC\nYour workspace, on your terms")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(28).frame(width: 230).frame(maxHeight: .infinity).background(.regularMaterial)
            VStack(alignment: .leading, spacing: 20) {
                Text("\(step + 1) / 4").font(.caption.monospaced()).foregroundStyle(.secondary)
                Text(steps[step]).font(.largeTitle.bold())
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        switch step {
                        case 0: welcome
                        case 1: apps
                        case 2: preferences
                        default: remoteTest
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider()
                HStack {
                    if step > 0 { Button("Back") { step -= 1 }.disabled(store.busy) }
                    Spacer()
                    if step < 3 {
                        Button("Set up later", action: finish).disabled(store.busy)
                        Button("Continue") { step += 1 }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    } else {
                        Button(store.isPreview ? "Close preview" : "Open my workspace", action: finish)
                            .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(store.busy)
                    }
                }
            }.padding(30).frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(width: 840, height: 610)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("You can sleep. Your AI doesn’t have to.").font(.title3.weight(.medium))
            Text("Keep your Mac awake for the apps and remote tools you already use. Let the screen go dark, close the lid when you need to, and end the session when you’re done.")
            feature("moon.stars", "Awake on demand", "You choose when a session starts and stops.")
            feature("lock.shield", "Local by design", "No model account, API key, or chat access is needed.")
            feature("laptopcomputer", "Your existing remote access", "Vibesomnia keeps the Mac awake. Use your remote desktop or SSH tool to reach it.")
            Text("You can reopen this guide from the toolbar or Settings at any time.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var apps: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Here’s what we found on this Mac. No conversations or credentials are read.")
            ForEach(store.apps) { app in
                HStack {
                    Image(systemName: app.installed ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(app.installed ? Color.green : Color.secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.name).fontWeight(.medium)
                        Text(app.running ? "Running" : app.installed ? (app.bundleID == nil ? "CLI available · activity not monitored" : "Installed") : "Not installed")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }.padding(.vertical, 4)
            }
            Button("Check again") { store.refreshApps() }
            Text("Missing an app? Install it, then check again. You can use Vibesomnia with any app; this list is a convenience.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var preferences: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle("Let the display sleep", isOn: $store.allowDisplaySleep)
            Text("Keep work running while your screen goes dark.").font(.caption).foregroundStyle(.secondary)
            Toggle("Use closed-lid mode for new sessions", isOn: $store.closedLid)
            Text("Optional. Starting a closed-lid session asks for macOS administrator approval. Normal system sleep returns when you end the session or quit. Opening the lid does not end it.")
                .font(.callout).foregroundStyle(.secondary)
            Toggle("End sessions on battery at 20%", isOn: $store.batteryProtection)
            Text("Keep an awake laptop on a ventilated surface. End the session before putting it in a bag.")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("Preferences are saved. Sessions never restart automatically after relaunch, and setup does not install a background service.")
                .font(.callout)
        }.toggleStyle(.switch)
    }

    private var remoteTest: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("First, connect from your other device with the lid open. Use an existing screen-sharing tool for app windows, or SSH for command-line controls.")
            HStack {
                Button("Open Sharing settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Sharing-Settings.extension")!)
                }.disabled(store.isPreview)
                Button("Copy CLI path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/vibesomnia-cli").path, forType: .string)
                }.disabled(store.isPreview)
            }
            Text("Vibesomnia does not enable remote access or verify connectivity for you. Your Mac must remain logged in.")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            Text("Then try a closed-lid session").font(.headline)
            Text("1. Start the test and approve the administrator prompt.\n2. Close the lid. Check your apps from your other device.\n3. Open and close the lid again, then reconnect.\n4. End the session to restore normal sleep.")
            if let error = store.error {
                Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange).font(.caption)
            }
            if store.needsRecovery && store.session == nil {
                Text("Close setup and recover the previous session from the dashboard before testing.").foregroundStyle(.orange)
            }
            Button(store.session == nil ? "Start closed-lid test" : "End current session") {
                store.perform {
                    if store.session == nil {
                        try await store.start(SessionRequest(allowDisplaySleep: true, closedLid: true))
                    } else { try await store.stop() }
                }
            }.disabled(store.isPreview || store.busy || (store.needsRecovery && store.session == nil))
            if store.session != nil {
                Text("Session active. Finishing setup leaves it running until you end it.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Toggle("I verified lid cycling and remote access on this Mac", isOn: $store.confirmedRemoteTest)
                .font(.caption)
            Text("Optional, recorded as your confirmation—not an automatic test result. You can finish setup and test later.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.title2).foregroundStyle(Color.accentColor).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).fontWeight(.semibold)
                Text(detail).foregroundStyle(.secondary)
            }
        }
    }
}
