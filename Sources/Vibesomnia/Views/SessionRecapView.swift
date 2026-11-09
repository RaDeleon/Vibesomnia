// Copyright © 2026 Angelo De Leon. SPDX-License-Identifier: AGPL-3.0-only
import AppKit
import SwiftUI
import VibesomniaCore

struct SessionRecapView: View {
    @ObservedObject var store: SessionStore
    let recap: SessionRecap
    @State private var copied = false
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Session wrapped", systemImage: "checkmark.circle").font(.headline)
                    Spacer()
                    Button("Dismiss") { store.dismissRecap() }
                }
                Text(recap.text).font(.callout).textSelection(.enabled)
                HStack {
                    Button(copied ? "Prompt copied" : "Copy AI recap prompt") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(recap.historyPrompt, forType: .string)
                        copied = true
                    }
                    Button("About recaps") { store.showSettings(.recap) }
                }
                Text("Paste the prompt into ChatGPT/Codex with Computer History enabled to ask about work during this interval.")
                    .font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
        }
    }
}
