import SwiftUI
import AppKit

/// Xbox 360-style unlock animation: a badge circle springs in,
/// expands into a pill with the achievement text, holds, then collapses away.
/// Hovering pins the toast open; clicking it opens the achievement in the app.
struct ToastView: View {
    let unlock: Unlock
    var onSelect: () -> Void
    var onDone: () -> Void

    /// Freezes the animation in the expanded state (design previews / renders).
    private let staticOpen: Bool

    private enum Phase { case hidden, badge, open }
    @State private var phase: Phase
    @State private var hovering = false
    @Environment(\.colorScheme) private var colorScheme

    init(unlock: Unlock, staticOpen: Bool = false,
         onSelect: @escaping () -> Void = {}, onDone: @escaping () -> Void) {
        self.unlock = unlock
        self.staticOpen = staticOpen
        self.onSelect = onSelect
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
                .padding(.trailing, 14)
                .transition(.opacity.combined(with: .move(edge: .leading)))
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
        .onTapGesture { if !staticOpen { onSelect() } }
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

        // Hold ~4s, but stay open while hovered.
        var idle: TimeInterval = 0
        while idle < 4 {
            try? await Task.sleep(for: .seconds(0.2))
            idle = hovering ? 0 : idle + 0.2
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
