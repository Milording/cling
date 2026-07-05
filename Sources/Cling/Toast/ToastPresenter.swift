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
    private enum Item {
        case unlock(Unlock)
        case summary(title: String, counts: [(tier: Tier, count: Int)])
    }

    private let sounds = SoundPlayer()
    private var queue: [Item] = []
    private var panel: NSPanel?

    func show(_ unlock: Unlock) {
        queue.append(.unlock(unlock))
        presentNextIfIdle()
    }

    /// A one-off summary toast (e.g. after recalculating progress).
    func showSummary(title: String, counts: [(tier: Tier, count: Int)]) {
        queue.append(.summary(title: title, counts: counts))
        presentNextIfIdle()
    }

    private func presentNextIfIdle() {
        guard panel == nil, !queue.isEmpty else { return }
        let item = queue.removeFirst()

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

        let dismiss: () -> Void = { [weak self] in self?.dismiss() }
        switch item {
        case .unlock(let unlock):
            panel.contentView = NSHostingView(rootView: ToastView(unlock: unlock, onDone: dismiss))
            if UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true {
                sounds.play(unlock.achievement.sound)
            }
        case .summary(let title, let counts):
            panel.contentView = NSHostingView(rootView:
                SummaryToastView(title: title, counts: counts, onDone: dismiss))
        }

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.minY + 48))
        }

        self.panel = panel
        panel.orderFrontRegardless()
    }

    private func dismiss() {
        panel?.close()
        panel = nil
        presentNextIfIdle()
    }
}
