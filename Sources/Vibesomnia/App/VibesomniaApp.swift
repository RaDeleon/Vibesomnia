// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI

@main
struct VibesomniaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup("Vibesomnia", id: "workspace") {
            ContentView(store: store)
                .onAppear { delegate.store = store }
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
                }.keyboardShortcut("s", modifiers: [.command, .shift]).disabled(store.busy)
            }
        }
        MenuBarExtra {
            SessionMenu(store: store)
        } label: {
            Label(store.session == nil ? "Vibesomnia" : "Vibesomnia · awake",
                  systemImage: store.session == nil ? "moon.zzz" : "moon.stars.fill")
        }
        Settings { SettingsView(store: store) }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var store: SessionStore?
    private var cleanupInProgress = false
    private var allowTermination = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
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
                store.report(error)
                cleanupInProgress = false
            }
        }
        return .terminateCancel
    }
}
