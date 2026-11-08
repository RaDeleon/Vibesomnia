// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Darwin
import VibeSystem
import VibesomniaCore

@MainActor
final class ClosedLidService {
    private let transport: ControlTransport
    private var nonce: String?
    private var sequence: UInt64 = 0
    private var stopping = false
    var ownsSession: Bool { nonce != nil }
    var record: GuardRecord? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: GuardRecord.path)) else { return nil }
        return try? JSONDecoder().decode(GuardRecord.self, from: data)
    }
    var needsRecovery: Bool {
        guard let record else { return FileManager.default.fileExists(atPath: GuardRecord.directory) }
        guard record.uid == getuid() else { return false }
        return !workerAlive(record)
    }
    private var helper: URL { Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/VibesomniaPowerGuard") }
    init(transport: ControlTransport) { self.transport = transport }
    private func leaseURL(_ nonce: String) -> URL { transport.root.appendingPathComponent("lid-\(nonce).lease") }
    private func workerAlive(_ record: GuardRecord) -> Bool {
        kill(record.workerPID, 0) == 0 || errno == EPERM
    }

    func start() async throws {
        guard FileManager.default.isExecutableFile(atPath: helper.path) else { throw VibeError.message("The bundled closed-lid guard is missing. Rebuild Vibesomnia.") }
        let flag = try await ProcessRunner.run(helper.path, ["--check"])
        guard flag == "normal", record == nil else {
            throw VibeError.message("Another app already prevents system sleep, or a guard needs recovery. End the other power session first.")
        }
        let token = UUID().uuidString
        nonce = token; sequence = 1; stopping = false
        try transport.write(ClosedLidLease(nonce: token, sequence: sequence), to: leaseURL(token))
        let args = ["--launch", String(getuid()), String(getpid()), String(vibe_process_stamp(getpid(), nil)), token]
        do {
            let response = try await authorize(args)
            guard response == "active", record?.nonce == token, record?.active == true else {
                throw VibeError.message("Closed-lid guard did not confirm activation.")
            }
        } catch {
            // A delayed authorization reply cannot leave an unleased override alive.
            try? transport.write(ClosedLidLease(nonce: token, sequence: sequence, stop: true), to: leaseURL(token))
            nonce = nil
            throw error
        }
    }

    func heartbeat() throws {
        guard let nonce, !stopping else { return }
        guard let record, record.nonce == nonce, workerAlive(record), record.active else {
            throw VibeError.message("Closed-lid guard stopped. The session has ended; check recovery if sleep was not restored.")
        }
        sequence += 1
        try transport.write(ClosedLidLease(nonce: nonce, sequence: sequence), to: leaseURL(nonce))
    }

    func stop() async throws {
        guard let token = nonce else { return }
        stopping = true
        try transport.write(ClosedLidLease(nonce: token, sequence: sequence, stop: true), to: leaseURL(token))
        for _ in 0..<40 {
            if record?.nonce != token {
                nonce = nil
                try? FileManager.default.removeItem(at: leaseURL(token))
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        // Keep ownership for retry/recovery, without renewing the stopping lease.
        throw VibeError.message("Sleep restoration is not confirmed. Wait for the guard lease to expire, then use Recover if needed.")
    }

    func recover() async throws {
        guard needsRecovery else { throw VibeError.message("No stopped Vibesomnia power guard needs recovery.") }
        _ = try await authorize(["--recover", String(getuid())])
    }

    private func authorize(_ arguments: [String]) async throws -> String {
        // Shell arguments are quoted individually; the elevated helper accepts only fixed operations.
        let command = ([helper.path] + arguments).map { "'" + $0.replacingOccurrences(of: "'", with: "'\\''") + "'" }.joined(separator: " ")
        let literal = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return try await ProcessRunner.appleScript("do shell script \"\(literal)\" with administrator privileges")
    }
}
