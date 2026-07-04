import SwiftUI

/// The tier-grouped, 3-column medal grid. Extracted from the scroll view so it
/// can also be rendered directly (offscreen `ImageRenderer` won't draw scroll content).
struct AchievementGrid: View {
    var onSelect: (Achievement) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Tier.allCases, id: \.self) { tier in
                tierSection(tier)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func tierSection(_ tier: Tier) -> some View {
        let items = Achievements.all.filter { $0.tier == tier }
        let rows = stride(from: 0, to: items.count, by: 3).map {
            Array(items[$0..<min($0 + 3, items.count)])
        }
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Circle().fill(tier.color).frame(width: 8, height: 8)
                Text(tier.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 18) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(rows[r]) { achievement in
                            AchievementCell(achievement: achievement, onSelect: onSelect)
                        }
                        ForEach(0..<(3 - rows[r].count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}
