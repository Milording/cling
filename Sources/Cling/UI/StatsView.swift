import SwiftUI

/// The Statistics tab: a grid of headline numbers about your Claude Code usage.
struct StatsView: View {
    @Environment(AppModel.self) private var model

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        let _ = model.stateVersion
        LazyVGrid(columns: columns, spacing: 12) {
            card("Tokens used", Self.compact(model.statTokens))
            card("Spent on tokens", String(format: "$%.2f", model.statCostDollars))
            card("Longest streak", streakText)
            card("Most active", model.statMostActive ?? "—")
        }
        .padding(16)
    }

    private var streakText: String {
        let n = model.statLongestStreak
        return "\(n) day\(n == 1 ? "" : "s")"
    }

    private func card(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.09)))
    }

    /// 47_200_000 → "47.2M", 4_820 → "4.8K".
    static func compact(_ n: Int) -> String {
        switch n {
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...: return String(format: "%.1fK", Double(n) / 1_000)
        default: return "\(n)"
        }
    }
}
