import SwiftUI

/// A one-line summary toast (e.g. the result of a recalculation), styled like the
/// unlock toast but with a title, a message, and per-tier count chips.
struct SummaryToastView: View {
    let title: String
    let counts: [(tier: Tier, count: Int)]
    var staticRender = false
    var onDone: () -> Void

    @State private var shown = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.accent)
                LucideText(icon: .trophy, size: 24).foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                if counts.isEmpty {
                    Text("No new achievements")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 8) {
                        ForEach(counts, id: \.tier) { item in
                            HStack(spacing: 4) {
                                Circle().fill(item.tier.color).frame(width: 7, height: 7)
                                Text("\(item.count) \(item.tier.label)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .fixedSize()
            .padding(.trailing, 12)
        }
        .padding(9)
        .background { if staticRender { Capsule().fill(Color(white: 0.13)) } }
        .modifier(GlassIf(enabled: !staticRender))
        .environment(\.colorScheme, staticRender ? .dark : colorScheme)
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        .fixedSize()
        .scaleEffect(shown ? 1 : 0.3)
        .opacity(shown ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if staticRender { shown = true } else { await run() }
        }
    }

    private func run() async {
        withAnimation(.spring(duration: 0.4, bounce: 0.4)) { shown = true }
        try? await Task.sleep(for: .seconds(4.5))
        withAnimation(.easeIn(duration: 0.25)) { shown = false }
        try? await Task.sleep(for: .seconds(0.3))
        onDone()
    }
}

private struct GlassIf: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled { content.glassCapsule() } else { content }
    }
}
