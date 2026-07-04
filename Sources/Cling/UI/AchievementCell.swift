import SwiftUI

/// One medal in the achievements grid: badge, name, and points/progress.
/// Unlocked medals are tappable and present a share popover.
struct AchievementCell: View {
    let achievement: Achievement
    @Environment(AppModel.self) private var model
    @State private var showingShare = false

    private var unlockDate: Date? {
        let _ = model.stateVersion
        return model.engine.state.unlocked[achievement.id]
    }

    var body: some View {
        let unlocked = unlockDate != nil
        VStack(spacing: 8) {
            Button {
                if unlocked { showingShare = true }
            } label: {
                AchievementBadge(achievement: achievement, unlocked: unlocked, size: 84)
                    .shadow(color: unlocked ? achievement.tier.color.opacity(0.35) : .clear,
                            radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(!unlocked)
            .popover(isPresented: $showingShare, arrowEdge: .bottom) {
                sharePopover
            }

            Text(achievement.name)
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

    private var sharePopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AchievementBadge(achievement: achievement, unlocked: true, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.name).font(.headline)
                    Text(achievement.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let date = unlockDate {
                Text("Unlocked \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(achievement.tier.color)
                ShareBar(achievement: achievement, unlockDate: date)
            }
        }
        .padding(14)
        .frame(width: 280)
    }
}
