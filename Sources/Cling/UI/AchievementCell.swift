import SwiftUI

/// One medal card in the achievements grid: badge (with progress ring / status
/// badge), name, and points/progress. Tapping the card opens its detail view.
struct AchievementCell: View {
    let achievement: Achievement
    var onSelect: (Achievement) -> Void = { _ in }
    @Environment(AppModel.self) private var model

    private var unlockDate: Date? {
        let _ = model.stateVersion
        return model.engine.state.unlocked[achievement.id]
    }

    var body: some View {
        let unlocked = unlockDate != nil
        let masked = achievement.hidden && !unlocked
        let fraction = unlocked ? nil : model.progress(for: achievement.id)
        let inProgress = (fraction ?? 0) > 0

        VStack(spacing: 10) {
            medal(unlocked: unlocked, masked: masked, ring: inProgress ? fraction : nil)

            Text(masked ? "???" : achievement.name)
                .font(.system(size: 13, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(unlocked ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            footer(unlocked: unlocked, masked: masked, fraction: fraction)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .cardSurface()
        .contentShape(Rectangle())
        .onTapGesture { onSelect(achievement) }
        .help(masked ? "" : achievement.blurb)
    }

    private func medal(unlocked: Bool, masked: Bool, ring: Double?) -> some View {
        AchievementBadge(achievement: achievement, unlocked: unlocked, size: 72, hiddenLocked: masked)
            .shadow(color: unlocked ? achievement.tier.color.opacity(0.35) : .clear, radius: 5, y: 2)
            .overlay {
                if let ring {
                    Circle()
                        .trim(from: 0, to: max(0.03, ring))
                        .stroke(achievement.tier.color,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(-6)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                statusBadge(unlocked: unlocked, masked: masked, inProgress: ring != nil)
            }
    }

    @ViewBuilder
    private func statusBadge(unlocked: Bool, masked: Bool, inProgress: Bool) -> some View {
        if unlocked {
            badgeCircle("checkmark", background: achievement.tier.color, foreground: .white)
        } else if !inProgress && !masked {
            badgeCircle("lock.fill",
                        background: Color(nsColor: .tertiaryLabelColor),
                        foreground: Color(nsColor: .controlBackgroundColor))
        }
    }

    private func badgeCircle(_ symbol: String, background: Color, foreground: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(foreground)
            .frame(width: 21, height: 21)
            .background(Circle().fill(background))
            .overlay(Circle().strokeBorder(Color(nsColor: .controlBackgroundColor), lineWidth: 2))
    }

    @ViewBuilder
    private func footer(unlocked: Bool, masked: Bool, fraction: Double?) -> some View {
        if unlocked {
            HStack(spacing: 4) {
                Text("\(achievement.points)P")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(achievement.tier.color)
        } else if let fraction, fraction > 0, !masked {
            VStack(spacing: 5) {
                Text("\(achievement.points)P")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(achievement.tier.color)
                ProgressBar(fraction: fraction, color: achievement.tier.color)
                    .frame(width: 92)
                Text(progressText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        } else {
            Text("\(achievement.points)P")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
        }
    }

    private var progressText: String {
        let current = min(model.engine.value(for: achievement.stat), achievement.goal)
        return "\(StatsView.compact(current)) / \(StatsView.compact(achievement.goal))"
    }
}
