import AppKit
import Darwin
import SwiftUI

@main
struct VistaRestApp: App {
    @StateObject private var model: AppModel

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        _model = StateObject(wrappedValue: AppModel())

        if CommandLine.arguments.contains("--self-check") {
            SelfCheck.run()
            exit(0)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(model: model)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sun.horizon.fill")
                if model.preferences.showRemainingInMenuBar && model.state.phase != .idle {
                    Text(model.formattedRemaining)
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
