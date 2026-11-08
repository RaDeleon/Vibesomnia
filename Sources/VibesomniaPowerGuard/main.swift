// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
// Narrow, temporary elevated worker. Never executes add-ons or accepts shell commands.
import Foundation
import Darwin
import VibeSystem
import VibesomniaCore

func fail(_ text: String) -> Never {
    FileHandle.standardError.write(Data((text + "\n").utf8)); exit(1)
}
func powerFlag() throws -> Bool {
    let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset"); p.arguments = ["-g"]
    let pipe = Pipe(); p.standardOutput = pipe; p.standardError = pipe
    try p.run(); let text = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    p.waitUntilExit()
    guard p.terminationStatus == 0 else { throw VibeError.message("Cannot read macOS power state.") }
    for line in text.split(separator: "\n") {
        let fields = line.split(whereSeparator: \.isWhitespace)
        if fields.first == "SleepDisabled", let flag = fields.last, ["0", "1"].contains(String(flag)) { return flag == "1" }
    }
    // macOS can omit SleepDisabled entirely when no override is active.
    return false
}
func setPower(_ value: Bool) throws {
    let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    p.arguments = ["-a", "disablesleep", value ? "1" : "0"]
    p.standardOutput = FileHandle.nullDevice; p.standardError = FileHandle.nullDevice
    try p.run(); p.waitUntilExit()
    guard p.terminationStatus == 0, try powerFlag() == value else { throw VibeError.message("macOS did not confirm the power setting.") }
}
func writeRecord(_ record: GuardRecord) throws {
    let url = URL(fileURLWithPath: GuardRecord.path)
    try JSONEncoder().encode(record).write(to: url, options: .atomic)
    try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
}
func existingRecord() throws -> GuardRecord {
    let a = try FileManager.default.attributesOfItem(atPath: GuardRecord.path)
    guard a[.type] as? FileAttributeType == .typeRegular,
          (a[.ownerAccountID] as? NSNumber)?.uint32Value == 0,
          (a[.size] as? NSNumber)?.intValue ?? 0 < 8192 else { throw VibeError.message("Invalid guard recovery record.") }
    return try JSONDecoder().decode(GuardRecord.self, from: Data(contentsOf: URL(fileURLWithPath: GuardRecord.path)))
}
func readLease(uid: UInt32, nonce: String) -> ClosedLidLease? {
    guard let pw = getpwuid(uid) else { return nil }
    let home = String(cString: pw.pointee.pw_dir)
    let path = home + "/Library/Application Support/Vibesomnia/Control/lid-\(nonce).lease"
    let fd = open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
    guard fd >= 0 else { return nil }
    defer { close(fd) }
    var stat = Darwin.stat()
    guard fstat(fd, &stat) == 0, stat.st_uid == uid, stat.st_mode & S_IFMT == S_IFREG,
          stat.st_nlink == 1, stat.st_size > 0, stat.st_size < 4096 else { return nil }
    var bytes = [UInt8](repeating: 0, count: Int(stat.st_size))
    let count = read(fd, &bytes, bytes.count)
    guard count == bytes.count else { return nil }
    return try? JSONDecoder().decode(ClosedLidLease.self, from: Data(bytes))
}
func removeRecord() {
    // Only our known fixed file and empty directory are removed; never recursive deletion.
    _ = unlink(GuardRecord.path); _ = rmdir(GuardRecord.directory)
}

let args = Array(CommandLine.arguments.dropFirst())
if args == ["--check"] {
    do { print(try powerFlag() ? "sleep-disabled" : "normal") } catch { fail(error.localizedDescription) }
    exit(0)
}
guard geteuid() == 0 else { fail("Closed-lid power guard requires explicit administrator approval.") }
guard args.count >= 2, let uid = UInt32(args[1]), uid > 0 else { fail("Invalid guard owner.") }

if args[0] == "--recover" {
    do {
        if !FileManager.default.fileExists(atPath: GuardRecord.path) {
            let attributes = try FileManager.default.attributesOfItem(atPath: GuardRecord.directory)
            guard attributes[.type] as? FileAttributeType == .typeDirectory,
                  (attributes[.ownerAccountID] as? NSNumber)?.uint32Value == 0,
                  !(try powerFlag()), rmdir(GuardRecord.directory) == 0 else {
                throw VibeError.message("Cannot recover an unverified or nonempty guard directory.")
            }
            print("recovered"); exit(0)
        }
        let record = try existingRecord()
        guard record.uid == uid else { throw VibeError.message("Recovery belongs to another user.") }
        guard vibe_process_stamp(record.workerPID, nil) != record.workerStamp || record.workerStamp == 0 else {
            throw VibeError.message("Power guard is still running. End its session or wait for lease expiry.")
        }
        // A durable record is written before changing the flag, including before worker activation.
        if try powerFlag() { try setPower(false) }
        removeRecord(); print("recovered")
    } catch { fail(error.localizedDescription) }
    exit(0)
}

guard args.count == 5, ["--launch", "--worker"].contains(args[0]),
      let pid = Int32(args[2]), pid > 1, let stamp = UInt64(args[3]), stamp > 0,
      UUID(uuidString: args[4]) != nil else { fail("Invalid guard request.") }
let nonce = args[4]
var owner: uid_t = 0
guard vibe_process_stamp(pid, &owner) == stamp, owner == uid else { fail("The requesting app is no longer running as the expected user.") }

if args[0] == "--launch" {
    do {
        guard !FileManager.default.fileExists(atPath: GuardRecord.directory) else {
            throw VibeError.message("A power guard or recovery record already exists. Resolve it first.")
        }
        let child = Process()
        child.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        child.arguments = ["--worker"] + Array(args.dropFirst())
        child.standardInput = FileHandle.nullDevice; child.standardOutput = FileHandle.nullDevice; child.standardError = FileHandle.nullDevice
        child.environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]
        try child.run()
        for _ in 0..<40 {
            if let record = try? existingRecord(), record.nonce == nonce {
                if let error = record.error { throw VibeError.message(error) }
                if record.active { print("active"); exit(0) }
            }
            if !child.isRunning { throw VibeError.message("Power guard could not start. Check existing power overrides.") }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw VibeError.message("Power guard did not become ready; its lease will expire automatically.")
    } catch { fail(error.localizedDescription) }
}

_ = setsid() // Detach the temporary worker from the authorization launcher.

// Exclusive, root-owned directory acts as a system-wide lock; don't overwrite other managers.
guard mkdir(GuardRecord.directory, 0o755) == 0 else { fail("Another closed-lid guard is active or needs recovery.") }
var record = GuardRecord(uid: uid, parentPID: pid, parentStamp: stamp, workerPID: getpid(),
                         workerStamp: vibe_process_stamp(getpid(), nil), nonce: nonce)
var changedPower = false
vibe_install_signals()
do {
    guard !(try powerFlag()) else { throw VibeError.message("Another app already disabled system sleep. End that session first.") }
    guard let lease = readLease(uid: uid, nonce: nonce), lease.nonce == nonce, !lease.stop else {
        throw VibeError.message("No valid Vibesomnia lease was supplied.")
    }
    try writeRecord(record) // Recovery evidence exists before touching global state.
    changedPower = true // Restore even if setPower partially succeeds before reporting an error.
    try setPower(true)
    record.active = true; try writeRecord(record)
    var watchdog = LeaseWatchdog(nonce: nonce, now: ProcessInfo.processInfo.systemUptime)
    _ = watchdog.receive(lease, now: ProcessInfo.processInfo.systemUptime)
    while vibe_interrupted() == 0 {
        let now = ProcessInfo.processInfo.systemUptime
        if vibe_process_stamp(pid, nil) != stamp { break }
        if let lease = readLease(uid: uid, nonce: nonce), watchdog.receive(lease, now: now) { break }
        if watchdog.expired(now: now) { break }
        Thread.sleep(forTimeInterval: 0.25)
    }
} catch { record.error = error.localizedDescription }
if changedPower {
    var restored = false
    for _ in 0..<5 {
        do { try setPower(false); restored = true; break }
        catch { record.error = "Sleep restoration failed: \(error.localizedDescription)"; Thread.sleep(forTimeInterval: 0.5) }
    }
    if !restored { record.active = false; try? writeRecord(record); exit(1) }
}
removeRecord()
