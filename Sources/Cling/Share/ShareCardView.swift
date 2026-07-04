import SwiftUI

enum ShareCardLayout: String, CaseIterable, Identifiable {
    /// 1080×1920 — stories.
    case vertical
    /// 1200×630 — posts / link previews.
    case horizontal

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .vertical: CGSize(width: 1080, height: 1920)
        case .horizontal: CGSize(width: 1200, height: 630)
        }
    }

    var label: String {
        switch self {
        case .vertical: "Story"
        case .horizontal: "Post"
        }
    }
}

/// Social share image, rendered off-screen at full pixel size.
struct ShareCardView: View {
    let achievement: Achievement
    let unlockDate: Date
    let layout: ShareCardLayout

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.16, green: 0.15, blue: 0.17),
                                    Color(red: 0.09, green: 0.085, blue: 0.10)],
                           startPoint: .top, endPoint: .bottom)
            content
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var content: some View {
        switch layout {
        case .vertical:
            VStack(spacing: 48) {
                Spacer()
                badge(diameter: 420)
                VStack(spacing: 28) {
                    caption(size: 34)
                    Text(achievement.name)
                        .font(.system(size: 88, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(white: 0.93))
                    Text(achievement.blurb)
                        .font(.system(size: 40, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(white: 0.62))
                    points(size: 56)
                }
                .padding(.horizontal, 80)
                Spacer()
                branding(size: 34)
                    .padding(.bottom, 90)
            }
        case .horizontal:
            HStack(spacing: 70) {
                badge(diameter: 320)
                    .padding(.leading, 100)
                VStack(alignment: .leading, spacing: 22) {
                    caption(size: 26)
                    Text(achievement.name)
                        .font(.system(size: 62, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.93))
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                    Text(achievement.blurb)
                        .font(.system(size: 30, design: .rounded))
                        .foregroundStyle(Color(white: 0.62))
                    points(size: 40)
                    branding(size: 24)
                        .padding(.top, 18)
                }
                .padding(.trailing, 80)
                Spacer(minLength: 0)
            }
        }
    }

    private func badge(diameter: CGFloat) -> some View {
        AchievementBadge(achievement: achievement, unlocked: true, size: diameter)
            .shadow(color: achievement.tier.color.opacity(0.45), radius: diameter / 6)
    }

    private func caption(size: CGFloat) -> some View {
        Text("Achievement unlocked")
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .foregroundStyle(achievement.tier.color)
    }

    private func points(size: CGFloat) -> some View {
        Text("+\(achievement.points)P · \(unlockDate.formatted(date: .abbreviated, time: .omitted))")
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.accent)
    }

    private func branding(size: CGFloat) -> some View {
        HStack(spacing: size / 2.5) {
            LucideText(icon: .trophy, size: size)
            Text("Cling — Claude achievements")
                .font(.system(size: size, weight: .medium, design: .rounded))
        }
        .foregroundStyle(Color(white: 0.62).opacity(0.7))
    }
}
