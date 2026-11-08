// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import VibesomniaCore

struct InstalledAddOn: Identifiable {
    let manifest: AddOnManifest
    let script: Data
    let directory: URL
    let fingerprint: String
    var id: String { manifest.id }
}

@MainActor
final class AddOnStore: ObservableObject {
    @Published private(set) var addons: [InstalledAddOn] = []
    @Published private(set) var running = false
    @Published var output = "Add-ons run as your macOS user, never inside the power guard. Review code before approving it."
    let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Vibesomnia/AddOns")
    private let defaults = UserDefaults.standard
    private var execution: Task<String, Error>?
    private var shuttingDown = false

    init() { reload() }
    func reload() {
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            addons = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
                .compactMap { try? load($0) }.sorted { $0.manifest.name < $1.manifest.name }
        } catch { output = error.localizedDescription }
    }
    private func load(_ directory: URL) throws -> InstalledAddOn {
        let attributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        guard attributes[.type] as? FileAttributeType == .typeDirectory else { throw VibeError.message("Add-on must be a real folder.") }
        let manifestURL = directory.appendingPathComponent("manifest.json")
        let manifestData = try regularData(manifestURL, limit: 16384)
        let manifest = try JSONDecoder().decode(AddOnManifest.self, from: manifestData)
        try manifest.validate()
        let script = try regularData(directory.appendingPathComponent(manifest.entryPoint), limit: 262144)
        return InstalledAddOn(manifest: manifest, script: script, directory: directory,
                              fingerprint: try manifest.fingerprint(script: script))
    }
    private func regularData(_ url: URL, limit: Int) throws -> Data {
        let a = try FileManager.default.attributesOfItem(atPath: url.path)
        guard a[.type] as? FileAttributeType == .typeRegular,
              (a[.size] as? NSNumber)?.intValue ?? Int.max <= limit else { throw VibeError.message("Add-on files must be regular files within size limits.") }
        return try Data(contentsOf: url)
    }
    func approved(_ addon: InstalledAddOn) -> Bool { defaults.string(forKey: "addon.approved.\(addon.id)") == addon.fingerprint }
    func enabled(_ addon: InstalledAddOn) -> Bool { approved(addon) && defaults.bool(forKey: "addon.enabled.\(addon.id)") }
    func approve(_ reviewed: InstalledAddOn) {
        do {
            let current = try load(reviewed.directory)
            guard current.fingerprint == reviewed.fingerprint else { throw VibeError.message("The add-on changed while being reviewed. Review it again.") }
            defaults.set(current.fingerprint, forKey: "addon.approved.\(current.id)")
            defaults.set(true, forKey: "addon.enabled.\(current.id)")
            reload()
        } catch { output = error.localizedDescription }
    }
    func setEnabled(_ addon: InstalledAddOn, _ enabled: Bool) {
        defaults.set(enabled, forKey: "addon.enabled.\(addon.id)"); objectWillChange.send()
    }
    func importFolder() {
        let panel = NSOpenPanel(); panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let addon = try load(url)
            let destination = root.appendingPathComponent(addon.id)
            guard !FileManager.default.fileExists(atPath: destination.path) else { throw VibeError.message("That add-on is already installed. Open its folder to edit it.") }
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            try JSONEncoder().encode(addon.manifest).write(to: destination.appendingPathComponent("manifest.json"))
            try addon.script.write(to: destination.appendingPathComponent(addon.manifest.entryPoint))
            output = "Imported \(addon.manifest.name). Review and approve before running."
            reload()
        } catch { output = error.localizedDescription }
    }
    func newScript() {
        do {
            let id = "my-script-" + UUID().uuidString.lowercased().prefix(8)
            let directory = root.appendingPathComponent(id)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            let manifest = AddOnManifest(id: id, name: "My script", summary: "A script I control. Edit the script and manifest, reload, then review it.")
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(manifest).write(to: directory.appendingPathComponent("manifest.json"))
            try Data("#!/bin/zsh\nprint \"Hello from Vibesomnia: $VIBESOMNIA_EVENT\"\n".utf8).write(to: directory.appendingPathComponent("main.sh"))
            reload(); NSWorkspace.shared.open(directory)
        } catch { output = error.localizedDescription }
    }
    func save(_ addon: InstalledAddOn, manifestText: String, scriptText: String) throws {
        let manifest = try JSONDecoder().decode(AddOnManifest.self, from: Data(manifestText.utf8))
        try manifest.validate()
        guard manifest.id == addon.id else { throw VibeError.message("Keep the add-on ID unchanged when editing.") }
        let data = Data(scriptText.utf8)
        _ = try manifest.fingerprint(script: data)
        try data.write(to: addon.directory.appendingPathComponent(manifest.entryPoint), options: .atomic)
        try Data(manifestText.utf8).write(to: addon.directory.appendingPathComponent("manifest.json"), options: .atomic)
        output = "Saved. Review and approve the new version before running."
        reload()
    }
    func installExamples() {
        guard let directory = Bundle.main.resourceURL?.appendingPathComponent("AddOnExamples") else { return }
        do {
            for source in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
                let addon = try load(source)
                let destination = root.appendingPathComponent(addon.id)
                if !FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
                    try JSONEncoder().encode(addon.manifest).write(to: destination.appendingPathComponent("manifest.json"))
                    try addon.script.write(to: destination.appendingPathComponent(addon.manifest.entryPoint))
                }
            }
            reload(); output = "Examples installed without approval. Review each one before enabling."
        } catch { output = error.localizedDescription }
    }
    func fire(_ event: AddOnEvent) {
        reload()
        let selected = addons.filter { enabled($0) && $0.manifest.events.contains(event) }
        guard !selected.isEmpty else { return }
        Task { for addon in selected { await run(addon, event: event) } }
    }
    func cancel(forShutdown: Bool = false) async {
        if forShutdown { shuttingDown = true }
        let task = execution
        task?.cancel()
        _ = try? await task?.value
    }
    func resume() { shuttingDown = false }

    func run(_ reviewed: InstalledAddOn, event: AddOnEvent = .manual) async {
        guard !shuttingDown else { return }
        guard !running else { output = "An add-on is already running; this event was skipped."; return }
        running = true; defer { running = false }
        do {
            let current = try load(reviewed.directory)
            guard approved(current), enabled(current) else { throw VibeError.message("Add-on changed or is disabled. Reload and review this version before running.") }
            output = "Running \(current.manifest.name)…"
            let task = Task { try await ScriptRunner.run(manifest: current.manifest, script: current.script,
                                                        directory: current.directory, event: event) }
            execution = task
            defer { execution = nil }
            output = try await task.value
        } catch { output = error.localizedDescription }
    }
}
