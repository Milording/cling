import SwiftUI

/// A single, fully-static frame of the unlock-toast animation, parametrized so a
/// sequence of them can be encoded into a GIF (see `AppModel --render-toast-gif`).
/// Unlike `ToastView` this has no `@State`/`.task`; every visual is driven by inputs.
struct ToastGIFFrame: View {
    let unlock: Unlock
    /// Overall badge/pill scale (badge spring-in and collapse).
    var scale: CGFloat
    /// Overall opacity (fade in at the very start, fade out at the very end).
    var opacity: Double
    /// 0 → just the badge, 1 → the pill fully expanded with text.
    var reveal: CGFloat

    /// Natural width of the text region once fully revealed.
    private let textWidth: CGFloat = 214

    var body: some View {
        HStack(spacing: 14) {
            AchievementBadge(achievement: unlock.achievement, unlocked: true, size: 58)

            if reveal > 0.001 {
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
                .frame(width: textWidth * reveal, alignment: .leading)
                .opacity(Double(min(1, reveal * 1.4)))
                .clipped()
                .padding(.trailing, 16 * reveal)
            }
        }
        .padding(7)
        .background {
            ZStack {
                Capsule().fill(Color(white: 0.13))
                Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
        }
        .environment(\.colorScheme, .dark)
        .fixedSize()
        .scaleEffect(scale)
        .opacity(opacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
