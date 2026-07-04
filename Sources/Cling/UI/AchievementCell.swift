import SwiftUI

/// One medal in the achievements grid: badge, name, and points/progress.
/// Tapping any medal opens its detail view.
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
        VStack(spacing: 8) {
            Button {
                onSelect(achievement)
            } label: {
                AchievementBadge(achievement: achievement, unlocked: unlocked, size: 84,
                                 hiddenLocked: masked)
                    .shadow(color: unlocked ? achievement.tier.color.opacity(0.35) : .clear,
                            radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            Text(masked ? "???" : achievement.name)
                .font(.system(size: 13, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(unlocked ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            footer(unlocked: unlocked)
                .frame(height: 22)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .help(achievement.blurb)
    }

    @ViewBuilder
    private func footer(unlocked: Bool) -> some View {
        if unlocked {
            HStack(spacing: 4) {
                Text("\(achievement.points)P")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(achievement.tier.color)
        } else if let fraction = model.progress(for: achievement.id) {
            VStack(spacing: 4) {
                ProgressBar(fraction: fraction, color: achievement.tier.color)
                Text("\(achievement.points)P")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        } else {
            Text("\(achievement.points)P")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
        }
    }
}
