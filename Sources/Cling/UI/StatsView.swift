import SwiftUI

/// The Statistics tab: a grid of headline numbers about your Claude Code usage.
struct StatsView: View {
    @Environment(AppModel.self) private var model

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    private let costInfo = """
        Estimated from your token usage at Anthropic's public API prices. \
        If you use Claude through a Pro or Max subscription, your real cost is \
        capped by the plan — so you're likely paying less than this.
        """

    var body: some View {
        let _ = model.stateVersion
        LazyVGrid(columns: columns, spacing: 12) {
            card("Tokens used", Self.compact(model.statTokens),
                 caption: Self.tokensBlurb(model.statTokens))
            card("Spent on tokens", String(format: "$%.2f", model.statCostDollars),
                 info: costInfo)
            card("Longest streak", streakText)
            card("Most active", model.statMostActive ?? "—")
        }
        .padding(16)
    }

    private var streakText: String {
        let n = model.statLongestStreak
        return "\(n) day\(n == 1 ? "" : "s")"
    }

    private func card(_ label: String, _ value: String,
                      caption: String? = nil, info: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if let info { InfoButton(text: info) }
            }
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if let caption {
                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.09)))
    }

    /// 47_200_000 → "47.2M", 4_820 → "4.8K".
    static func compact(_ n: Int) -> String {
        switch n {
        case 1_000_000_000...: return String(format: "%.1fB", Double(n) / 1_000_000_000)
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...: return String(format: "%.1fK", Double(n) / 1_000)
        default: return "\(n)"
        }
    }

    /// A tongue-in-cheek reading-comparison for the token count, in 10 tiers up to 10B.
    static func tokensBlurb(_ n: Int) -> String {
        switch n {
        case ..<100_000:        return "A quick coffee-chat's worth of words."
        case ..<1_000_000:      return "One short story — two, if they're bad."
        case ..<10_000_000:     return "A whole novel, the beach-read kind."
        case ..<50_000_000:     return "Like reading War and Peace. Twice."
        case ..<100_000_000:    return "All of Lord of the Rings, appendices and all."
        case ..<500_000_000:    return "Every Harry Potter book, back to back."
        case ..<1_000_000_000:  return "A shelf of encyclopedias. Remember those?"
        case ..<5_000_000_000:  return "More words than you'll speak in a lifetime."
        case ..<10_000_000_000: return "Nearing the Library of Alexandria — mind the torches."
        default:                return "Ten billion tokens. Historians will study you."
        }
    }
}

/// A small "?" button that reveals a short explanation in a popover.
private struct InfoButton: View {
    let text: String
    @State private var show = false

    var body: some View {
        Button { show.toggle() } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(text)
        .popover(isPresented: $show, arrowEdge: .bottom) {
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 220, alignment: .leading)
                .padding(12)
        }
    }
}
