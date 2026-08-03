import AppKit
import SwiftUI

@MainActor
final class BreakOverlayController {
    private var windows: [NSWindow] = []

    func show(model: AppModel) {
        hide()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = model.preferences.reminderStyle == .strict ? .screenSaver : .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            window.isOpaque = false
            window.backgroundColor = NSColor.black.withAlphaComponent(0.72)
            window.hasShadow = false
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: BreakOverlayView(model: model))
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    func hide() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}
