// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI

@main
struct VibesomniaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var store = SessionStore(preview: CommandLine.arguments.contains("--setup-preview"))

    var body: some Scene {
        WindowGroup("Vibesomnia", id: "workspace") {
            Group {
                if store.isPreview {
                    SetupView(store: store) { NSApp.terminate(nil) }
                } else {
                    ContentView(store: store)
                        .sheet(isPresented: $store.showSetup) {
                            SetupView(store: store) { store.finishSetup() }
                                .interactiveDismissDisabled(store.busy)
                        }
                }
            }.onAppear { delegate.store = store }
        }
        .defaultSize(width: 860, height: 680)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button(store.session == nil ? "Start Session" : "End Session") {
                    store.perform {
                        if store.session == nil { try await store.start() }
                        else { try await store.stop() }
                    }
                }.keyboardShortcut("s", modifiers: [.command, .shift]).disabled(store.busy || store.isPreview)
            }
        }
        MenuBarExtra {
            SessionMenu(store: store).disabled(store.isPreview)
        } label: {
            Image(nsImage: MenuBarIcon.image(active: store.session != nil))
                .renderingMode(.original)
                .accessibilityLabel(store.session == nil ? "Vibesomnia · idle" : "Vibesomnia · awake")
                .help(store.session == nil ? "Vibesomnia · idle" : "Vibesomnia · awake")
        }
        Settings {
            if store.isPreview { Text("Setup preview · preferences are not saved").padding() }
            else { SettingsView(store: store) }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var store: SessionStore?
    private var cleanupInProgress = false
    private var allowTermination = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = image
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !allowTermination, let store else { return .terminateNow }
        guard !cleanupInProgress else { return .terminateCancel }
        cleanupInProgress = true
        // Return to the normal run loop before awaiting actor-isolated cleanup.
        // NSTerminateLater's nested loop can otherwise stall Swift concurrency.
        Task {
            do {
                try await store.quit()
                allowTermination = true
                cleanupInProgress = false
                DispatchQueue.main.async { sender.terminate(nil) }
            } catch {
                store.addons.resume()
                store.report(error)
                cleanupInProgress = false
            }
        }
        return .terminateCancel
    }
}
