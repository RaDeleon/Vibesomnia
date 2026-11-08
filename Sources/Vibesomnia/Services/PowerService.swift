// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import IOKit.pwr_mgt
import VibesomniaCore

@MainActor
final class PowerService {
    private var assertions: [IOPMAssertionID] = []

    func start(allowDisplaySleep: Bool) throws {
        stop()
        do {
            try acquire(kIOPMAssertionTypePreventUserIdleSystemSleep as CFString)
            if !allowDisplaySleep {
                try acquire(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString)
            }
        } catch {
            stop()
            throw error
        }
    }

    private func acquire(_ type: CFString) throws {
        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(type, IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                               "Vibesomnia - AI workspace session" as CFString, &id)
        guard result == kIOReturnSuccess else {
            throw VibeError.message("macOS refused the keep-awake assertion (\(result)).")
        }
        assertions.append(id)
    }

    func stop() {
        assertions.forEach { IOPMAssertionRelease($0) }
        assertions.removeAll()
    }
}
