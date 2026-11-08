// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit

/// Keep the app's identity at menu-bar scale, including on Retina displays.
@MainActor
enum MenuBarIcon {
    private static let idle = makeImage(active: false)
    private static let awake = makeImage(active: true)

    static func image(active: Bool) -> NSImage { active ? awake : idle }

    private static func makeImage(active: Bool) -> NSImage {
        let artwork = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            .flatMap { NSImage(contentsOf: $0) } ?? NSApp.applicationIconImage
        // The ICNS includes small-size and Retina representations. AppKit picks
        // the appropriate representation for the destination drawing context.
        let image = NSImage(size: NSSize(width: 24, height: 20), flipped: false) { _ in
            artwork?.draw(in: NSRect(x: 0, y: 0, width: 20, height: 20))
            if active {
                let badge = NSBezierPath(ovalIn: NSRect(x: 18, y: 0, width: 6, height: 6))
                NSColor.white.setStroke()
                badge.lineWidth = 1
                badge.stroke()
                NSColor.systemGreen.setFill()
                badge.fill()
            }
            return true
        }
        // Template rendering would flatten the face, purple hair, and eye detail.
        image.isTemplate = false
        image.accessibilityDescription = active ? "Vibesomnia · awake" : "Vibesomnia · idle"
        return image
    }
}
