import AppKit
import SwiftUI

/// Borderless panel that can still take clicks (share button) without activating the app.
final class ToastPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Shows Xbox-style unlock toasts in a floating panel at the bottom-center
/// of the main screen. Unlocks queue and play sequentially; hover pins them open.
@MainActor
final class ToastPresenter {
    private let sounds = SoundPlayer()
    private var queue: [Unlock] = []
    private var panel: NSPanel?

    func show(_ unlock: Unlock) {
        queue.append(unlock)
        presentNextIfIdle()
    }

    private func presentNextIfIdle() {
        guard panel == nil, !queue.isEmpty else { return }
        let unlock = queue.removeFirst()

        let size = NSSize(width: 520, height: 110)
        let panel = ToastPanel(contentRect: NSRect(origin: .zero, size: size),
                               styleMask: [.borderless, .nonactivatingPanel],
                               backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        panel.contentView = NSHostingView(rootView: ToastView(unlock: unlock) { [weak self] in
            self?.dismiss()
        })

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.minY + 48))
        }

        self.panel = panel
        if UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true {
            sounds.play(unlock.achievement.sound)
        }
        panel.orderFrontRegardless()
    }

    private func dismiss() {
        panel?.close()
        panel = nil
        presentNextIfIdle()
    }
}
