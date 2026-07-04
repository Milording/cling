import SwiftUI

/// The circular medal badge, shared by the grid, toast, and share card.
/// Unlocked: a tier-colored gradient disc with a white Lucide glyph and a soft ring.
/// Locked: a muted disc with a gray border and the glyph drawn as a faint outline.
struct AchievementBadge: View {
    let achievement: Achievement
    let unlocked: Bool
    let size: CGFloat
    /// A hidden achievement that hasn't been unlocked — show a lock, not its icon.
    var hiddenLocked = false

    var body: some View {
        ZStack {
            if unlocked {
                Circle()
                    .fill(LinearGradient(
                        colors: [achievement.tier.color, achievement.tier.color.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: max(1, size / 40)))
                LucideText(icon: achievement.icon, size: size * 0.42)
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.35))
                    .overlay(Circle().strokeBorder(.secondary.opacity(0.35), lineWidth: max(1, size / 40)))
                LucideText(icon: hiddenLocked ? .lock : achievement.icon, size: size * 0.42)
                    .foregroundStyle(.secondary.opacity(0.55))
            }
        }
        .frame(width: size, height: size)
    }
}
