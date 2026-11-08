// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import VibesomniaCore

/// Temporary, optional closed-lid backend. No Amphetamine source is included.
@MainActor
final class AmphetamineService {
    private let transport: ControlTransport
    private let target = "tell application \"/Applications/Amphetamine.app\"\n"
    private(set) var ownsSession = false
    var needsRecovery: Bool { FileManager.default.fileExists(atPath: transport.recovery.path) }
    var installed: Bool { FileManager.default.fileExists(atPath: "/Applications/Amphetamine.app") }

    init(transport: ControlTransport) { self.transport = transport }

    func start(_ request: SessionRequest) async throws {
        guard installed else {
            throw VibeError.message("Closed-lid alpha mode needs Amphetamine in /Applications. Standard sessions work without it.")
        }
        guard !needsRecovery else {
            throw VibeError.message("A previous closed-lid session needs recovery. Use Recover session first.")
        }
        let active = try await ProcessRunner.appleScript(target + "return session is active\nend tell")
        guard active == "false" else {
            throw VibeError.message("Amphetamine already has a session. End that session in Amphetamine first; Vibesomnia will not replace it.")
        }
        // Record intent before sending commands, so interruption leaves a recovery path.
        try transport.write(Date(), to: transport.recovery)
        ownsSession = true
        let minutes = request.minutes ?? 0
        let interval = minutes == 0 ? "0" : "minutes"
        do {
            let result = try await ProcessRunner.appleScript(target + """
            start new session with options {duration:\(minutes), interval:\(interval), displaySleepAllowed:\(request.allowDisplaySleep)}
            enable closed display mode
            return {session is active, display sleep allowed, closed display mode enabled}
            end tell
            """)
            let expected = "true, \(request.allowDisplaySleep), true"
            guard result == expected else { throw VibeError.message("Amphetamine did not confirm closed-lid mode: \(result)") }
        } catch {
            try? await stop()
            throw error
        }
    }

    func stop() async throws {
        guard ownsSession || needsRecovery else { return }
        _ = try await ProcessRunner.appleScript(target + "end session\nend tell")
        ownsSession = false
        if needsRecovery { try FileManager.default.removeItem(at: transport.recovery) }
    }
}
