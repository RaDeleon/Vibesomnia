// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Darwin
import VibeSystem

public struct ScriptRunner {
    public static func run(manifest: AddOnManifest, script: Data, directory: URL, event: AddOnEvent) async throws -> String {
        let task = Task.detached(priority: .utility) { try execute(manifest: manifest, script: script, directory: directory, event: event) }
        return try await withTaskCancellationHandler(operation: { try await task.value }, onCancel: { task.cancel() })
    }

    private static func execute(manifest: AddOnManifest, script: Data, directory: URL, event: AddOnEvent) throws -> String {
            guard geteuid() != 0 else { throw VibeError.message("Add-ons never run as root.") }
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent("vibesomnia-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            defer { try? FileManager.default.removeItem(at: temp) }
            let snapshot = temp.appendingPathComponent("reviewed-script")
            try script.write(to: snapshot)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: snapshot.path)
            let output = temp.appendingPathComponent("output")
            FileManager.default.createFile(atPath: output.path, contents: nil, attributes: [.posixPermissions: 0o600])
            let handle = try FileHandle(forWritingTo: output)
            defer { try? handle.close() }
            var pid: pid_t = 0
            let result = vibe_spawn_script(manifest.interpreter.path, snapshot.path, directory.path,
                                           event.rawValue, FileManager.default.homeDirectoryForCurrentUser.path,
                                           handle.fileDescriptor, &pid)
            guard result == 0 else { throw VibeError.message("Could not launch script: \(String(cString: strerror(result))).") }
            let deadline = ProcessInfo.processInfo.systemUptime + Double(manifest.timeoutSeconds)
            var status: Int32 = 0
            var reason: String?
            while waitpid(pid, &status, WNOHANG) == 0 {
                if ProcessInfo.processInfo.systemUptime >= deadline { reason = "Script timed out."; break }
                let size = (try? FileManager.default.attributesOfItem(atPath: output.path)[.size] as? NSNumber)?.intValue ?? 0
                if size > 65536 { reason = "Script output exceeded 64 KiB."; break }
                if Task.isCancelled { reason = "Script cancelled."; break }
                Thread.sleep(forTimeInterval: 0.05)
            }
            // Terminate any remaining children in this run's process group too.
            kill(-pid, SIGTERM)
            if reason != nil {
                Thread.sleep(forTimeInterval: 0.2); kill(-pid, SIGKILL); waitpid(pid, &status, 0)
            }
            let reader = try FileHandle(forReadingFrom: output)
            defer { try? reader.close() }
            let data = (try? reader.read(upToCount: 65536)) ?? Data()
            let text = String(decoding: data, as: UTF8.self)
            if let reason { throw VibeError.message(reason + "\n" + text) }
            guard status == 0 else { throw VibeError.message("Script exited with status \(status).\n\(text)") }
            return text.isEmpty ? "Completed without output." : text
    }
}
