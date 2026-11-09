// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import UniformTypeIdentifiers
import Combine
import OSLog
import VibesomniaCore

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var session: ActiveSession?
    @Published private(set) var closedLidVerifiedAt: Date?
    var isClosedLidActive: Bool { session?.backend == .closedLid && closedLidVerifiedAt != nil }
    @Published private(set) var apps: [WorkspaceApp] = []
    @Published private(set) var busy = false
    @Published var error: String?
    @Published private(set) var events: [String] = []
    @Published var page: WorkspacePage = .dashboard
    @Published var settingsTab: SettingsTab = .general
    @Published private(set) var now = Date()
    @Published private(set) var appErrors: [String: String] = [:]
    @Published var pinnedApps = Set(NightCrewCatalog.defaultPinned) { didSet { preferencesDefaults?.set(Array(pinnedApps), forKey: "crew.pinned") } }
    @Published var autoShowRunning = true { didSet { preferencesDefaults?.set(autoShowRunning, forKey: "crew.autoShow") } }
    @Published var recapEnabled = false {
        didSet {
            preferencesDefaults?.set(recapEnabled, forKey: "recap.enabled")
            if !recapEnabled { observedAppNames.removeAll(); lastRecap = nil }
        }
    }
    @Published private(set) var lastRecap: SessionRecap?
    private var observedAppNames = Set<String>()
    @Published var minutes = 60
    @Published var timed = false
    @Published var allowDisplaySleep = true { didSet { savePreferences() } }
    @Published var closedLid = false { didSet { savePreferences() } }
    @Published var selectedApp = ""
    @Published var autoStart = false
    @Published var batteryProtection = true { didSet { savePreferences() } }
    @Published private(set) var battery: BatteryStatus?
    @Published private(set) var needsRecovery = false
    @Published var showSetup = false
    @Published var confirmedRemoteTest = false { didSet { savePreferences() } }
    let isPreview: Bool
    private let preferencesDefaults: UserDefaults?
    private var setupCompleted = false
    lazy var addons = AddOnStore()
    let transport = ControlTransport()
    private let power = PowerService()
    private lazy var lidGuard = ClosedLidService(transport: transport)
    private lazy var workspace = WorkspaceService(defaults: preferencesDefaults)
    private let logger = Logger(subsystem: "com.angelodeleon.Vibesomnia", category: "sessions")
    private var timer: Timer?
    private var ticking = false
    private var suppressAutoStart = false
    private var ipcReady = false

    init(preview: Bool = false) {
        isPreview = preview
        preferencesDefaults = preview ? nil : .standard
        if let pinned = preferencesDefaults?.stringArray(forKey: "crew.pinned") { pinnedApps = Set(pinned) }
        if preferencesDefaults?.object(forKey: "crew.autoShow") != nil { autoShowRunning = preferencesDefaults?.bool(forKey: "crew.autoShow") ?? true }
        recapEnabled = preferencesDefaults?.bool(forKey: "recap.enabled") ?? false
        let preferences = SetupPreferences.load(from: preferencesDefaults)
        allowDisplaySleep = preferences.allowDisplaySleep
        closedLid = preferences.closedLid
        batteryProtection = preferences.batteryProtection
        confirmedRemoteTest = preferences.confirmedRemoteTest
        setupCompleted = preferences.completed
        showSetup = !preferences.completed
        if preview {
            showSetup = false
            apps = workspace.snapshot()
            battery = .current()
            return // Preview never touches IPC, add-ons, leases, or system power.
        }
        do { try transport.prepare(); ipcReady = true }
        catch { self.error = error.localizedDescription }
        needsRecovery = lidGuard.needsRecovery
        apps = workspace.snapshot()
        battery = .current()
        publish()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.tick() }
        }
    }

    private func savePreferences() {
        var value = SetupPreferences()
        value.completed = setupCompleted
        value.allowDisplaySleep = allowDisplaySleep
        value.closedLid = closedLid
        value.batteryProtection = batteryProtection
        value.confirmedRemoteTest = confirmedRemoteTest
        value.save(to: preferencesDefaults)
    }

    func finishSetup() {
        setupCompleted = true
        savePreferences()
        showSetup = false
    }

    func refreshApps() { apps = workspace.snapshot(force: true) }
    var visibleApps: [WorkspaceApp] { NightCrewCatalog.visible(apps, pinned: pinnedApps, autoShowRunning: autoShowRunning) }
    func appIcon(_ id: String) -> NSImage? { workspace.icon(for: id) }
    func pinApp(_ id: String, _ pinned: Bool) {
        if pinned { pinnedApps.insert(id) } else { pinnedApps.remove(id) }
    }
    func addApplication() {
        guard !isPreview else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false; panel.canChooseFiles = true
        panel.allowsMultipleSelection = false; panel.allowedContentTypes = [.application]
        panel.prompt = "Add to Night Crew"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { pinnedApps.insert(try workspace.addApplication(url)); refreshApps() } catch { report(error) }
    }
    func showSettings(_ tab: SettingsTab = .general) { settingsTab = tab; page = .settings }
    func selectDuration(_ value: Int?) throws {
        guard !busy else { throw VibeError.message("Wait for the session update to finish.") }
        try SessionRequest(minutes: value).validate()
        if let current = session {
            session = try current.changingDuration(to: value)
            record(value.map { "Timer reset to \(SessionDuration.title($0))" } ?? "Timer removed")
        }
        timed = value != nil
        if let value { minutes = value }
        now = Date(); publish()
    }
    var countdown: String? { session?.remainingSeconds(now: now).map(SessionDuration.countdown) }
    func dismissRecap() { lastRecap = nil }


    var request: SessionRequest {
        SessionRequest(minutes: timed ? minutes : nil, allowDisplaySleep: allowDisplaySleep,
                       closedLid: closedLid, whileApp: selectedApp.isEmpty ? nil : selectedApp)
    }

    func start(_ request: SessionRequest? = nil) async throws {
        guard !isPreview else { throw VibeError.message("Setup preview cannot start sessions.") }
        guard !busy else { throw VibeError.message("A session change is already in progress.") }
        guard session == nil else { throw VibeError.message("End the current session before starting another.") }
        guard !needsRecovery else { throw VibeError.message("Recover the previous closed-lid session first.") }
        let next = try ActiveSession(request: request ?? self.request)
        if let bundle = next.request.whileApp, !workspace.runningBundleIDs.contains(bundle) {
            throw VibeError.message("The selected app must be running before the session starts.")
        }
        if batteryProtection, let battery = BatteryStatus.current(), battery.onBattery, battery.percent <= 20 {
            throw VibeError.message("Battery is at or below 20%. Connect power or disable battery protection.")
        }
        busy = true
        defer { busy = false; needsRecovery = lidGuard.needsRecovery; publish() }
        if next.backend == .closedLid {
            try power.start(allowDisplaySleep: next.request.allowDisplaySleep)
            do { try await lidGuard.start() } catch { power.stop(); throw error }
        }
        else { try power.start(allowDisplaySleep: next.request.allowDisplaySleep) }
        session = try ActiveSession(request: next.request)
        timed = next.request.minutes != nil
        if let duration = next.request.minutes { minutes = duration }
        closedLidVerifiedAt = next.backend == .closedLid ? Date() : nil
        error = nil
        observedAppNames = recapEnabled ? Set(apps.filter(\.running).map(\.name)) : []
        lastRecap = nil
        now = Date()
        addons.fire(.sessionStarted)
        record("Started \(next.backend.rawValue) session\(next.endsAt == nil ? " · indefinite" : " · timed")")
    }

    func stop(reason: String = "Stopped manually") async throws {
        guard !isPreview else { return }
        guard !busy else { throw VibeError.message("A session change is already in progress.") }
        busy = true
        closedLidVerifiedAt = nil
        defer { busy = false; needsRecovery = lidGuard.needsRecovery; publish() }
        if session?.backend == .closedLid || lidGuard.ownsSession { try await lidGuard.stop() }
        power.stop()
        if let current = session {
            if recapEnabled {
                lastRecap = SessionRecap(startedAt: current.startedAt, endedAt: Date(), reason: reason,
                                         observedApps: Array(observedAppNames))
            }
            observedAppNames.removeAll()
            record(reason)
            if reason != "App quit" { addons.fire(.sessionEnded) }
        }
        session = nil
        suppressAutoStart = true
        error = nil
    }

    /// The dashboard switch controls the live session, not the saved startup preference.
    func setClosedLidEnabled(_ enabled: Bool) async throws {
        guard !isPreview else { throw VibeError.message("Setup preview cannot change power mode.") }
        guard !busy else { throw VibeError.message("A session change is already in progress.") }
        guard let current = session else {
            if enabled {
                var next = request
                next.closedLid = true
                try await start(next)
            }
            return
        }
        guard enabled != (current.backend == .closedLid) else { return }
        let next = try current.changingClosedLid(to: enabled)
        busy = true
        defer { busy = false; needsRecovery = lidGuard.needsRecovery; publish() }
        closedLidVerifiedAt = nil
        if enabled {
            guard !needsRecovery else { throw VibeError.message("Recover the previous closed-lid session first.") }
            try await lidGuard.start()
            closedLidVerifiedAt = Date()
        } else {
            try await lidGuard.stop()
        }
        session = next
        error = nil
        record(enabled ? "Closed-lid protection enabled" : "Closed-lid protection off · native keep-awake continues")
    }

    func recover() async {
        guard !isPreview else { return }
        guard !busy else { return }
        busy = true
        defer { busy = false; needsRecovery = lidGuard.needsRecovery; publish() }
        do {
            try await lidGuard.recover()
            record("Recovered Vibesomnia power settings")
            error = nil
        } catch { report(error) }
    }

    func perform(_ action: @escaping @MainActor () async throws -> Void) {
        Task { do { try await action() } catch { report(error) } }
    }

    func launch(_ app: String) async throws {
        guard !isPreview else { return }
        do {
            try await workspace.launch(app)
            appErrors[app] = nil
            refreshApps()
        } catch {
            appErrors[app] = error.localizedDescription
            throw error
        }
    }

    func displayOff() async throws {
        guard !isPreview else { return }
        if let session, !session.request.allowDisplaySleep {
            throw VibeError.message("This session keeps the display on. Stop it and allow display sleep first.")
        }
        _ = try await ProcessRunner.run("/usr/bin/pmset", ["displaysleepnow"])
    }

    func quit() async throws {
        guard !isPreview else { return }
        guard !needsRecovery || session != nil else {
            throw VibeError.message("Recover the previous closed-lid session before quitting.")
        }
        await addons.cancel(forShutdown: true)
        try await stop(reason: "App quit")
    }

    func report(_ failure: Error) {
        error = failure.localizedDescription
        logger.error("\(failure.localizedDescription, privacy: .public)")
        publish()
    }

    private func tick() async {
        now = Date()
        guard !ticking, !busy else { return }
        ticking = true
        defer { ticking = false }
        apps = workspace.snapshot()
        if session != nil, recapEnabled { observedAppNames.formUnion(apps.filter(\.running).map(\.name)) }
        if !recapEnabled { observedAppNames.removeAll() }
        battery = .current()
        needsRecovery = lidGuard.needsRecovery
        if let observed = session, observed.backend == .closedLid {
            do {
                let verified = try await lidGuard.heartbeat()
                guard !busy, session == observed else { return }
                closedLidVerifiedAt = verified ? Date() : nil
            }
            catch {
                guard !busy, session == observed else { return }
                closedLidVerifiedAt = nil
                let failure = error
                try? await stop(reason: "Closed-lid guard stopped")
                power.stop()
                session = nil
                report(failure)
                suppressAutoStart = true
            }
        }
        let running = workspace.runningBundleIDs
        if !selectedApp.isEmpty, !running.contains(selectedApp) { suppressAutoStart = false }
        do {
            if let session {
                if let reason = session.endReason(now: Date(), runningBundleIDs: running) {
                    try await stop(reason: reason)
                } else if batteryProtection, let battery, battery.onBattery, battery.percent <= 20 {
                    try await stop(reason: "Battery protection · at or below 20%")
                }
            } else if autoStart, !selectedApp.isEmpty, running.contains(selectedApp), !suppressAutoStart, !needsRecovery {
                // Suppress retries (and permission prompts) until the app closes if startup fails.
                suppressAutoStart = true
                try await start(request)
            }
        } catch { report(error) }
        await processInbox()
        publish()
    }

    private func processInbox() async {
        guard ipcReady, let urls = try? FileManager.default.contentsOfDirectory(at: transport.inbox,
                                                                               includingPropertiesForKeys: nil) else { return }
        for url in urls.filter({ $0.pathExtension == "json" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).prefix(8) {
            guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) else {
                try? FileManager.default.removeItem(at: url); continue
            }
            var reply: ControlReply
            do {
                let command = try transport.read(ControlRequest.self, from: url)
                guard command.id == id else { throw VibeError.message("Request identifier mismatch.") }
                try command.validate()
                switch command.action {
                case .start: try await start(command.session ?? SessionRequest())
                case .stop: try await stop()
                case .toggle:
                    if session == nil { try await start(command.session ?? SessionRequest()) }
                    else { try await stop() }
                case .launch: try await launch(command.app ?? "")
                case .displayOff: try await displayOff()
                case .quit: try await quit()
                }
                reply = ControlReply(ok: true, message: "\(command.action.rawValue) completed")
                if command.action == .quit {
                    // Reply before asking AppKit to terminate.
                    try transport.write(reply, to: transport.replies.appendingPathComponent("\(id).json"))
                    try? FileManager.default.removeItem(at: url)
                    // Do not enter AppKit termination from a running MainActor task.
                    DispatchQueue.main.async { NSApp.terminate(nil) }
                    return
                }
            } catch { reply = ControlReply(ok: false, message: error.localizedDescription) }
            try? transport.write(reply, to: transport.replies.appendingPathComponent("\(id).json"))
            try? FileManager.default.removeItem(at: url)
        }
        // Replies are ephemeral; abandoned CLI calls must not grow the directory forever.
        if let replies = try? FileManager.default.contentsOfDirectory(at: transport.replies, includingPropertiesForKeys: [.contentModificationDateKey]) {
            for url in replies {
                if let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                   Date().timeIntervalSince(date) > 60 { try? FileManager.default.removeItem(at: url) }
            }
        }
    }

    private func publish() {
        guard ipcReady else { return }
        do { try transport.write(AppStatus(session: session, apps: apps, lastError: error,
                                          closedLidActive: isClosedLidActive,
                                          closedLidVerifiedAt: closedLidVerifiedAt), to: transport.status) }
        catch { self.error = "Remote controls unavailable: \(error.localizedDescription)" }
    }

    private func record(_ event: String) {
        logger.info("\(event, privacy: .public)")
        events.insert("\(Date().formatted(date: .omitted, time: .shortened)) · \(event)", at: 0)
        events = Array(events.prefix(30))
    }
}
