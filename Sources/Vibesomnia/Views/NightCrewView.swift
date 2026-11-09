// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import VibesomniaCore

struct NightCrewView: View {
    @ObservedObject var store: SessionStore
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Your night crew", systemImage: "square.stack.3d.up").font(.headline)
                Spacer()
                Button("Manage") { store.showSettings(.crew) }.buttonStyle(.link)
            }
            if store.visibleApps.isEmpty {
                Text("Add your tools in Settings. Running catalog apps appear here automatically when discovery is enabled.")
                    .foregroundStyle(.secondary)
            }
            ForEach(store.visibleApps) { app in
                CrewRow(store: store, app: app)
                if app.id != store.visibleApps.last?.id { Divider() }
            }
            Text("Status is local app presence. AI activity, sign-in, and remote connectivity are not monitored.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(20).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct CrewIcon: View {
    @ObservedObject var store: SessionStore
    let app: WorkspaceApp
    var body: some View {
        Group {
            if let icon = store.appIcon(app.id) { Image(nsImage: icon).resizable().interpolation(.high) }
            else { Image(systemName: app.bundleID == nil ? "terminal" : "app.dashed").resizable().scaledToFit().padding(5).foregroundStyle(.secondary) }
        }.frame(width: 32, height: 32).accessibilityHidden(true)
    }
}

private struct CrewRow: View {
    @ObservedObject var store: SessionStore
    let app: WorkspaceApp
    @State private var showDetails = false
    private var failure: String? { store.appErrors[app.id] }
    private var status: String {
        if failure != nil { return "Needs attention" }
        if app.running { return "Running on this Mac" }
        if !app.installed { return "Not installed" }
        return app.bundleID == nil ? "CLI installed · activity not monitored" : "Not running"
    }
    var body: some View {
        HStack(spacing: 10) {
            CrewIcon(store: store, app: app)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).fontWeight(.medium)
                HStack(spacing: 5) {
                    Circle().fill(failure != nil ? Color.yellow : app.running ? Color.green : Color.red).frame(width: 6, height: 6)
                    Text(status).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 4)
            if failure != nil || !app.installed {
                Button("Troubleshoot", systemImage: "info.circle") { showDetails = true }.labelStyle(.iconOnly)
                    .help("Troubleshoot \(app.name)")
                    .popover(isPresented: $showDetails) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(app.name).font(.headline)
                            Text(failure ?? "Vibesomnia could not find this application in its known locations.").textSelection(.enabled)
                            Text("Install the app, or use Settings → Night Crew → Add application to select its .app. If macOS blocked a launch, open it once in Finder and complete its setup. CLI tools must be installed in a supported executable location.")
                            Button("Check again") { store.refreshApps() }
                            if failure != nil {
                                Button("Retry launch") { showDetails = false; store.perform { try await store.launch(app.id) } }
                            }
                        }.padding(20).frame(width: 320)
                    }
            }
            Button(app.running ? "Open" : "Launch") { store.perform { try await store.launch(app.id) } }
                .disabled(store.isPreview || !app.installed)
        }
    }
}
