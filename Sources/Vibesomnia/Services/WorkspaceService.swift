// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import VibesomniaCore

@MainActor
final class WorkspaceService {
    struct CustomApp: Codable {
        let id: String
        let name: String
        let path: String
    }
    private struct DiscoveredApp {
        let product: String
        let bundleID: String
        let url: URL
    }
    private var discovered: [DiscoveredApp] = []
    private var lastDiscovery = Date.distantPast
    private var icons: [String: NSImage] = [:]
    private var custom: [CustomApp] = []
    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        if let data = defaults?.data(forKey: "crew.custom"),
           let saved = try? JSONDecoder().decode([CustomApp].self, from: data) { custom = saved }
    }
    var runningBundleIDs: Set<String> {
        Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }
    private func discover(force: Bool) {
        guard force || Date().timeIntervalSince(lastDiscovery) >= 15 else { return }
        lastDiscovery = Date()
        let workspace = NSWorkspace.shared
        var urls = workspace.runningApplications.compactMap(\.bundleURL)
        urls += NightCrewCatalog.products.flatMap(\.bundleIDs)
            .compactMap { workspace.urlForApplication(withBundleIdentifier: $0) }
        let roots = [URL(fileURLWithPath: "/Applications"),
                     FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        urls += roots.flatMap { root in
            NightCrewCatalog.products.flatMap(\.appNames).map { root.appendingPathComponent("\($0).app") }
        }
        urls += custom.map { URL(fileURLWithPath: $0.path) }
        var seen = Set<URL>()
        discovered = urls.compactMap { candidate in
            let url = candidate.resolvingSymlinksInPath().standardizedFileURL
            guard seen.insert(url).inserted, let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier else { return nil }
            let names = [bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
                         bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
                         url.deletingPathExtension().lastPathComponent].compactMap { $0 }
            let product = NightCrewCatalog.product(bundleID: bundleID, names: names)
                ?? custom.first(where: { URL(fileURLWithPath: $0.path).resolvingSymlinksInPath() == url })?.id
            guard let product else { return nil }
            return DiscoveredApp(product: product, bundleID: bundleID, url: url)
        }
        let validPaths = Set(discovered.map { $0.url.path })
        icons = icons.filter { validPaths.contains($0.key) }
    }
    private var runningURLs: Set<URL> {
        Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleURL?.resolvingSymlinksInPath().standardizedFileURL })
    }
    func url(for id: String) -> URL? {
        discover(force: false)
        let matches = discovered.filter { $0.product == id }
        let running = runningURLs
        return (matches.first(where: { running.contains($0.url) }) ?? matches.first)?.url
    }
    func icon(for id: String) -> NSImage? {
        guard let url = url(for: id) else { return nil }
        if let cached = icons[url.path] { return cached }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)
        icons[url.path] = icon
        return icon
    }
    func executable(for id: String) -> String? {
        guard let name = NightCrewCatalog.products.first(where: { $0.id == id })?.executable else { return nil }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return ["\(home)/.local/bin", "/opt/homebrew/bin", "/usr/local/bin", "\(home)/.npm-global/bin", "\(home)/.opencode/bin"]
            .map { "\($0)/\(name)" }.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
    func snapshot(force: Bool = false) -> [WorkspaceApp] {
        discover(force: force)
        let running = runningURLs
        let products = NightCrewCatalog.products.map { ($0.id, $0.name) } + custom.filter { item in !NightCrewCatalog.products.contains { $0.id == item.id } }.map { ($0.id, $0.name) }
        return products.map { id, name in
            let matches = discovered.filter { $0.product == id }
            let selected = matches.first(where: { running.contains($0.url) }) ?? matches.first
            return WorkspaceApp(id: id, name: name, installed: selected != nil || executable(for: id) != nil,
                                running: matches.contains { running.contains($0.url) }, bundleID: selected?.bundleID)
        }
    }
    func addApplication(_ url: URL) throws -> String {
        guard url.pathExtension == "app", let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier else {
            throw VibeError.message("Choose a macOS application (.app).")
        }
        let name = url.deletingPathExtension().lastPathComponent
        if let known = NightCrewCatalog.product(bundleID: bundleID, names: [name]) {
            // Remember nonstandard installation locations as well as catalog applications.
            if !custom.contains(where: { $0.id == known }) {
                custom.append(CustomApp(id: known, name: name, path: url.path))
            }
            saveCustom(); discover(force: true); return known
        }
        let id = "custom:" + bundleID
        custom.removeAll { $0.id == id }
        custom.append(CustomApp(id: id, name: name, path: url.path))
        saveCustom(); discover(force: true); return id
    }
    private func saveCustom() {
        if let data = try? JSONEncoder().encode(custom) { defaults?.set(data, forKey: "crew.custom") }
    }
    func launch(_ id: String) async throws {
        discover(force: true)
        if let url = url(for: id) {
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: .init())
        } else if let executable = executable(for: id) {
            let command = "export PATH=/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH; " + shellQuote(executable)
            let literal = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            _ = try await ProcessRunner.appleScript("tell application \"Terminal\"\nactivate\ndo script \"\(literal)\"\nend tell")
        } else { throw VibeError.message("Application was not found. Install it, or select its .app in Settings → Night Crew → Add application.") }
    }
    private func shellQuote(_ text: String) -> String { "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'" }
}
