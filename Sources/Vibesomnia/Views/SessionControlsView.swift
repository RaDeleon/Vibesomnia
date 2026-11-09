// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import VibesomniaCore

struct SessionControlsView: View {
    @ObservedObject var store: SessionStore
    @State private var showHelp = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Stay awhile", systemImage: "moon.stars").font(.headline)
                Spacer()
                Button { showHelp.toggle() } label: { Image(systemName: "questionmark.circle") }
                    .buttonStyle(.plain).help("What do these controls do?")
                    .accessibilityLabel("Explain session controls")
                    .popover(isPresented: $showHelp, arrowEdge: .top) { ScrollView { SessionHelpView().padding(22) }.frame(width: 420, height: 360) }
            }
            if let countdown = store.countdown, let endsAt = store.session?.endsAt {
                VStack(alignment: .leading, spacing: 4) {
                    Text(countdown).font(.system(size: 38, weight: .semibold, design: .rounded)).monospacedDigit()
                    Text("remaining · ends \(endsAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }.accessibilityElement(children: .combine)
            }
            Toggle("End after a timer", isOn: Binding(get: { store.timed }, set: { enabled in
                store.perform { try store.selectDuration(enabled ? store.minutes : nil) }
            })).disabled(store.busy)
            if store.timed {
                HStack {
                    Menu {
                        ForEach(SessionDuration.presets, id: \.self) { minutes in
                            Button(SessionDuration.title(minutes)) { store.perform { try store.selectDuration(minutes) } }
                        }
                    } label: { Label(SessionDuration.title(store.minutes), systemImage: "timer") }
                    .disabled(store.busy)
                    TextField("Minutes", value: $store.minutes, format: .number).frame(width: 64)
                        .accessibilityLabel("Custom duration in minutes")
                    if store.session != nil {
                        Button("Set remaining") { store.perform { try store.selectDuration(store.minutes) } }.disabled(store.busy)
                    }
                }
                Text(store.session == nil ? "Or enter a custom duration in minutes." : "Choosing a preset resets the remaining time from now.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            Toggle("Let the display sleep", isOn: $store.allowDisplaySleep)
            Text("Keep work running while your display follows its normal sleep timer.")
                .font(.caption).foregroundStyle(.secondary)
            Toggle("Keep running with lid closed", isOn: Binding(
                get: { store.isClosedLidActive },
                set: { enabled in store.perform { try await store.setClosedLidEnabled(enabled) } }
            )).disabled(store.busy || store.needsRecovery || store.isPreview)
            Label(store.isClosedLidActive ? "Closed-lid protection verified" : "Closed-lid protection off",
                  systemImage: store.isClosedLidActive ? "checkmark.shield" : "laptopcomputer")
                .font(.caption).foregroundStyle(store.isClosedLidActive ? Color.green : Color.secondary)
            Divider()
            Picker("While app runs", selection: $store.selectedApp) {
                Text("Any / manual session").tag("")
                ForEach(store.apps.filter { $0.installed && $0.bundleID != nil }) { app in
                    Text(app.name).tag(app.bundleID ?? "")
                }
            }
            Toggle("Start when selected app runs", isOn: $store.autoStart).disabled(store.selectedApp.isEmpty)
            Text("Lid and timer controls affect this session. Display and app choices apply to the next one.")
                .font(.caption).foregroundStyle(.secondary)
            Button {
                store.perform {
                    if store.session == nil { try await store.start() }
                    else { try await store.stop() }
                }
            } label: {
                Label(store.busy ? "Updating…" : (store.session == nil ? "Start session" : "End session"),
                      systemImage: store.session == nil ? "play.fill" : "stop.fill").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(store.isPreview || store.busy || (store.needsRecovery && store.session == nil))
        }.padding(20).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct SessionHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Make the session yours").font(.title2.bold())
            help("End after a timer", "Ends Vibesomnia’s keep-awake session when time runs out. It does not quit your apps. Turn it off for an indefinite session. Presets during an active session set a new countdown from now.")
            help("Let the display sleep", "On: the display may sleep according to macOS settings while the Mac stays awake. Off: Vibesomnia also prevents idle display sleep. This is a next-session choice; it does not change screen locking.")
            help("Keep running with lid closed", "Immediately enables or disables Vibesomnia’s temporary closed-lid guard. Enabling asks for macOS administrator approval and starts a session if needed. Turning it off keeps an existing native session running, but closing the lid can then sleep the Mac. The switch shows verified protection, not a saved preference.")
            help("While app runs", "Ends the session when the selected desktop app closes, or the timer expires—whichever happens first. The app must already be running when you start.")
            help("Start when selected app runs", "Automatically starts a session while the chosen app is running. After you stop manually, close and reopen that app to re-arm it. This does not monitor model activity.")
            Text("Battery protection can end a session early. Keeping the Mac awake does not set up remote access.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private func help(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(detail).font(.callout).foregroundStyle(.secondary) }
    }
}
