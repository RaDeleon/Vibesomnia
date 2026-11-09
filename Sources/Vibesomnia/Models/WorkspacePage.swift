// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import Foundation

enum WorkspacePage { case dashboard, settings }
enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General", crew = "Night Crew", scripts = "Scripts", recap = "Recaps"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .crew: return "square.stack.3d.up"
        case .scripts: return "terminal"
        case .recap: return "text.book.closed"
        }
    }
}
