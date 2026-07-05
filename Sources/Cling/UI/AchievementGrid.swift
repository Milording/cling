import SwiftUI

enum MedalFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unlocked = "Unlocked"
    case inProgress = "In progress"
    case locked = "Locked"
    var id: String { rawValue }
}

/// The tier-grouped, 2-column medal grid. Extracted from the scroll view so it
/// can also be rendered directly (offscreen `ImageRenderer` won't draw scroll content).
struct AchievementGrid: View {
    var onSelect: (Achievement) -> Void = { _ in }
    @Environment(AppModel.self) private var model
    @State private var filter: MedalFilter = .all

    var body: some View {
        let _ = model.stateVersion // re-order when unlocks change
        let tiers = Tier.allCases
            .map { (tier: $0, items: items(for: $0)) }
            .filter { !$0.items.isEmpty }
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(tiers.enumerated()), id: \.offset) { index, entry in
                tierSection(entry.tier, items: entry.items, showFilter: index == 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    /// Achievements for a tier after the current filter, unlocked ones first.
    private func items(for tier: Tier) -> [Achievement] {
        let inTier = Achievements.all.filter { $0.tier == tier && matches($0) }
        return inTier.filter { model.engine.isUnlocked($0.id) }
            + inTier.filter { !model.engine.isUnlocked($0.id) }
    }

    private func matches(_ achievement: Achievement) -> Bool {
        let unlocked = model.engine.isUnlocked(achievement.id)
        let progress = unlocked ? 0 : (model.progress(for: achievement.id) ?? 0)
        switch filter {
        case .all: return true
        case .unlocked: return unlocked
        case .inProgress: return !unlocked && progress > 0
        case .locked: return !unlocked && progress == 0
        }
    }

    private func tierSection(_ tier: Tier, items: [Achievement], showFilter: Bool) -> some View {
        let rows = stride(from: 0, to: items.count, by: 2).map {
            Array(items[$0..<min($0 + 2, items.count)])
        }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "rosette")
                    .font(.system(size: 16))
                    .foregroundStyle(tier.color)
                Text(tier.label)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                if showFilter { filterMenu }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 12) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(rows[r]) { achievement in
                            AchievementCell(achievement: achievement, onSelect: onSelect)
                        }
                        ForEach(0..<(2 - rows[r].count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            ForEach(MedalFilter.allCases) { option in
                Button {
                    filter = option
                } label: {
                    if filter == option { Label(option.rawValue, systemImage: "checkmark") }
                    else { Text(option.rawValue) }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(filter.rawValue)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(.quaternary.opacity(0.5)))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
