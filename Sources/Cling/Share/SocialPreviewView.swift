import SwiftUI

/// GitHub social preview / Open Graph card, rendered at 1280×640.
/// Uses the app's own medal badges so the image stays on-brand.
struct SocialPreviewView: View {
    private let showcase: [(id: String, unlocked: Bool)] = [
        (Achievements.helloClaude, true),
        (Achievements.nightOwl, true),
        (Achievements.multitasker, true),
        (Achievements.homunculus, false),
        (Achievements.marathon, true),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.16, green: 0.14, blue: 0.18),
                                    Color(red: 0.07, green: 0.065, blue: 0.08)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Theme.accent.opacity(0.28), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 720)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 22) {
                    ZStack {
                        Circle().fill(LinearGradient(
                            colors: [Theme.accent, Theme.peach],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        LucideText(icon: .trophy, size: 58)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 104, height: 104)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 24)

                    Text("Cling")
                        .font(.system(size: 108, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("Xbox-style achievements for your Claude Code usage")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(white: 0.88))
                    .padding(.top, 18)

                Text("A tiny, private, native macOS menu bar app.")
                    .font(.system(size: 30, design: .rounded))
                    .foregroundStyle(Color(white: 0.6))
                    .padding(.top, 10)

                Spacer(minLength: 0)

                HStack(spacing: 34) {
                    ForEach(showcase, id: \.id) { item in
                        if let achievement = Achievements.byID(item.id) {
                            AchievementBadge(achievement: achievement, unlocked: item.unlocked, size: 118)
                                .shadow(color: item.unlocked
                                        ? achievement.tier.color.opacity(0.5) : .clear, radius: 16)
                        }
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    Text("290 points")
                        .foregroundStyle(Theme.accent)
                    Text("·  7 achievements  ·  Bronze / Silver / Gold  ·  Open source")
                        .foregroundStyle(Color(white: 0.55))
                }
                .font(.system(size: 27, weight: .medium, design: .rounded))
                .padding(.top, 30)
            }
            .padding(72)
        }
        .frame(width: 1280, height: 640)
        .environment(\.colorScheme, .dark)
    }
}
