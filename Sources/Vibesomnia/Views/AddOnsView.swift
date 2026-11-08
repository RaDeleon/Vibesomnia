// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI
import VibesomniaCore

struct AddOnsView: View {
    @ObservedObject var store: AddOnStore
    @State private var reviewing: InstalledAddOn?
    @State private var editing: InstalledAddOn?
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Make the night shift yours").font(.title2.bold())
            Text("Run your scripts manually or on session events. Scripts have your account’s file and network access. Approve only code you trust; changes require another review.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("New script") { store.newScript() }
                Button("Import add-on…") { store.importFolder() }
                Button("Open folder") { NSWorkspace.shared.open(store.root) }
                Button("Install examples") { store.installExamples() }
                Button("Reload") { store.reload() }
            }
            List(store.addons) { addon in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(addon.manifest.name).fontWeight(.semibold)
                            Text(addon.manifest.summary).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("Enabled", isOn: Binding(get: { store.enabled(addon) }, set: { store.setEnabled(addon, $0) }))
                            .disabled(!store.approved(addon))
                        Button("Edit") { editing = addon }
                        Button("Review") { reviewing = addon }
                        Button("Run") { Task { await store.run(addon) } }
                            .disabled(!store.enabled(addon) || store.running)
                    }
                    Text("\(addon.manifest.interpreter.rawValue) · \(addon.manifest.timeoutSeconds)s limit · \(addon.manifest.events.map(\.rawValue).joined(separator: ", "))")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 6)
            }
            if store.running { Button("Stop script") { Task { await store.cancel() } } }
            Text("Last result").font(.headline)
            ScrollView { Text(store.output).font(.caption.monospaced()).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                .frame(height: 100).padding(10).background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }.padding(22).frame(minWidth: 680, minHeight: 460)
        .sheet(item: $editing) { addon in AddOnEditor(store: store, addon: addon) }
        .sheet(item: $reviewing) { addon in
            VStack(alignment: .leading, spacing: 14) {
                Text("Review \(addon.manifest.name)").font(.title2.bold())
                Text("Runs as you, with your account permissions. Never runs as root. Events: \(addon.manifest.events.map(\.rawValue).joined(separator: ", ")).")
                ScrollView {
                    VStack(alignment: .leading) {
                        Text(String(decoding: (try? JSONEncoder().encode(addon.manifest)) ?? Data(), as: UTF8.self))
                        Divider()
                        Text(String(decoding: addon.script, as: UTF8.self))
                    }.font(.callout.monospaced()).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack {
                    Button("Cancel") { reviewing = nil }
                    Spacer()
                    Button("Approve this version") { store.approve(addon); reviewing = nil }.buttonStyle(.borderedProminent)
                }
            }.padding(24).frame(width: 660, height: 480)
        }
    }
}

struct AddOnEditor: View {
    @ObservedObject var store: AddOnStore
    let addon: InstalledAddOn
    @Environment(\.dismiss) private var dismiss
    @State private var source = ""
    @State private var manifest = ""
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit \(addon.manifest.name)").font(.title2.bold())
            Text("Saving changes invalidates prior approval. Scripts run with your user permissions.").foregroundStyle(.secondary)
            TabView {
                TextEditor(text: $source).font(.body.monospaced()).tabItem { Text("Script") }
                TextEditor(text: $manifest).font(.body.monospaced()).tabItem { Text("Manifest") }
            }
            if let error { Text(error).foregroundStyle(.red) }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    do { try store.save(addon, manifestText: manifest, scriptText: source); dismiss() }
                    catch { self.error = error.localizedDescription }
                }.buttonStyle(.borderedProminent)
            }
        }.padding(20).frame(width: 680, height: 500).onAppear {
            source = String(decoding: addon.script, as: UTF8.self)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            manifest = String(decoding: (try? encoder.encode(addon.manifest)) ?? Data(), as: UTF8.self)
        }
    }
}
