import SwiftUI
import AppKit

/// Xbox 360-style unlock animation: a badge circle springs in,
/// expands into a pill with the achievement text, holds, then collapses away.
/// Hovering pins the toast open; it also offers a share button.
struct ToastView: View {
    let unlock: Unlock
    var onDone: () -> Void

    /// Freezes the animation in the expanded state (design previews / renders).
    private let staticOpen: Bool

    private enum Phase { case hidden, badge, open }
    @State private var phase: Phase
    @State private var hovering = false
    @State private var sharing = false
    @Environment(\.colorScheme) private var colorScheme

    init(unlock: Unlock, staticOpen: Bool = false, onDone: @escaping () -> Void) {
        self.unlock = unlock
        self.staticOpen = staticOpen
        self.onDone = onDone
        _phase = State(initialValue: staticOpen ? .open : .hidden)
    }

    var body: some View {
        HStack(spacing: 14) {
            badge
            if phase == .open {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Achievement unlocked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text(unlock.achievement.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("+\(unlock.achievement.points)P")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .lineLimit(1)
                .fixedSize()
                .transition(.opacity.combined(with: .move(edge: .leading)))

                Group {
                    if staticOpen {
                        // NSViewRepresentable can't draw in ImageRenderer; use a plain glyph.
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.secondary)
                    } else {
                        ToastShareButton(unlock: unlock) { active in sharing = active }
                    }
                }
                .frame(width: 26, height: 26)
                .padding(.trailing, 10)
                .transition(.opacity)
            }
        }
        .padding(7)
        .background {
            // Materials/glass need a live window; static renders get a plain fill.
            if staticOpen {
                Capsule().fill(Color(white: 0.13))
            }
        }
        .modifier(GlassIfLive(enabled: !staticOpen))
        .environment(\.colorScheme, staticOpen ? .dark : colorScheme)
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        .fixedSize()
        .scaleEffect(phase == .hidden ? 0.3 : 1)
        .opacity(phase == .hidden ? 0 : 1)
        .onHover { hovering = $0 }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if !staticOpen { await run() }
        }
    }

    private var badge: some View {
        AchievementBadge(achievement: unlock.achievement, unlocked: true, size: 58)
    }

    private func run() async {
        withAnimation(.spring(duration: 0.4, bounce: 0.5)) { phase = .badge }
        try? await Task.sleep(for: .seconds(0.55))
        withAnimation(.spring(duration: 0.45, bounce: 0.25)) { phase = .open }

        // Hold ~4s, but stay open while hovered or while the share picker is up.
        var idle: TimeInterval = 0
        while idle < 4 {
            try? await Task.sleep(for: .seconds(0.2))
            idle = (hovering || sharing) ? 0 : idle + 0.2
        }

        withAnimation(.spring(duration: 0.35)) { phase = .badge }
        try? await Task.sleep(for: .seconds(0.4))
        withAnimation(.easeIn(duration: 0.25)) { phase = .hidden }
        try? await Task.sleep(for: .seconds(0.3))
        onDone()
    }
}

private struct GlassIfLive: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.glassCapsule()
        } else {
            content
        }
    }
}

/// Native share button (NSSharingServicePicker needs an NSView anchor).
private struct ToastShareButton: NSViewRepresentable {
    let unlock: Unlock
    let pickerActive: (Bool) -> Void

    init(unlock: Unlock, pickerActive: @escaping (Bool) -> Void) {
        self.unlock = unlock
        self.pickerActive = pickerActive
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSButton {
        let image = NSImage(systemSymbolName: "square.and.arrow.up",
                            accessibilityDescription: "Share achievement")!
        let button = NSButton(image: image, target: context.coordinator,
                              action: #selector(Coordinator.share(_:)))
        button.isBordered = false
        button.contentTintColor = .secondaryLabelColor
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.parent = self
    }

    @MainActor
    final class Coordinator: NSObject, NSSharingServicePickerDelegate {
        var parent: ToastShareButton
        private var picker: NSSharingServicePicker?

        init(_ parent: ToastShareButton) { self.parent = parent }

        @objc func share(_ sender: NSButton) {
            guard let url = ShareCardRenderer.temporaryPNG(for: parent.unlock.achievement,
                                                           unlockDate: parent.unlock.date,
                                                           layout: .horizontal) else { return }
            parent.pickerActive(true)
            let picker = NSSharingServicePicker(items: [url])
            picker.delegate = self
            self.picker = picker
            picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }

        nonisolated func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker,
                                              didChoose service: NSSharingService?) {
            Task { @MainActor in
                self.parent.pickerActive(false)
                self.picker = nil
            }
        }
    }
}
