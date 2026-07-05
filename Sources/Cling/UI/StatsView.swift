import SwiftUI

/// The Statistics tab: a hero "tokens used" card plus a grid of usage numbers.
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
        VStack(spacing: 12) {
            hero
            LazyVGrid(columns: columns, spacing: 12) {
                gridCard(icon: "dollarsign", label: "Estimated spend",
                         value: Self.money(model.statCostDollars),
                         sub: "Total on tokens", info: costInfo)
                gridCard(icon: "flame.fill", label: "Longest streak",
                         value: streakText, sub: "Keep it going!")
                gridCard(icon: "clock", label: "Most active hours",
                         value: model.statMostActive ?? "—", sub: "Your daily peak")
                gridCard(icon: "chart.line.uptrend.xyaxis", label: "Average per day",
                         value: Self.compact(model.statAveragePerDay), sub: "Tokens used")
            }
        }
        .padding(16)
    }

    private var streakText: String {
        let n = model.statLongestStreak
        return "\(n) day\(n == 1 ? "" : "s")"
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Theme.accent.opacity(0.16), Theme.accent.opacity(0.05)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))

            // Decorative books + sparkles on the right.
            HStack {
                Spacer()
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 82))
                    .foregroundStyle(Theme.accent.opacity(0.22))
                    .rotationEffect(.degrees(-8))
                    .padding(.trailing, 22)
            }
            Image(systemName: "sparkle")
                .font(.system(size: 13))
                .foregroundStyle(Theme.accent.opacity(0.5))
                .offset(x: 232, y: 26)
            Image(systemName: "sparkle")
                .font(.system(size: 9))
                .foregroundStyle(Theme.accent.opacity(0.4))
                .offset(x: 256, y: 52)

            VStack(alignment: .leading, spacing: 0) {
                iconCircle("square.3.layers.3d", filled: true)
                Text("Tokens used")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.top, 12)
                Text(Self.compact(model.statTokens))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent)
                    .frame(width: 34, height: 4)
                    .padding(.top, 4)
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "book")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.accent)
                    Text(Self.tokensBlurb(model.statTokens))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 18)
                .padding(.trailing, 120)
            }
            .padding(20)
        }
    }

    // MARK: - Grid card

    private func gridCard(icon: String, label: String, value: String,
                          sub: String, info: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                iconCircle(icon, filled: false)
                Spacer(minLength: 0)
                if let info { InfoButton(text: info) }
            }
            .padding(.bottom, 2)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.09)))
    }

    private func iconCircle(_ icon: String, filled: Bool) -> some View {
        Image(systemName: icon)
            .font(.system(size: filled ? 19 : 15, weight: .medium))
            .foregroundStyle(filled ? AnyShapeStyle(.white) : AnyShapeStyle(Theme.accent))
            .frame(width: filled ? 44 : 34, height: filled ? 44 : 34)
            .background(Circle().fill(filled ? AnyShapeStyle(Theme.accent)
                                            : AnyShapeStyle(Theme.accent.opacity(0.15))))
    }

    /// USD is billed in dollars; group US-style ("$1,393.80") regardless of locale.
    static func money(_ dollars: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$" + (formatter.string(from: dollars as NSNumber) ?? String(format: "%.2f", dollars))
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

    /// A reading-comparison for the token count, in 10 tiers up to 10B.
    static func tokensBlurb(_ n: Int) -> String {
        switch n {
        case ..<100_000:        return "One Philosopher's Stone."
        case ..<1_000_000:      return "A journey through the whole Lord of the Rings."
        case ..<10_000_000:     return "Seven complete trips through Harry Potter."
        case ..<50_000_000:     return "Sixty-four copies of War and Peace."
        case ..<100_000_000:    return "Shakespeare's complete works, eighty-five times over."
        case ..<500_000_000:    return "The entire Harry Potter series, 345 times."
        case ..<1_000_000_000:  return "Shakespeare's complete works, around 850 times."
        case ..<5_000_000_000:  return "Three quarters of English Wikipedia."
        case ..<10_000_000_000: return "One and a half English Wikipedias."
        default:                return "English Wikipedia once, then halfway through it again."
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
