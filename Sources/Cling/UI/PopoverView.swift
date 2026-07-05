import SwiftUI

enum PopoverTab: String, CaseIterable {
    case achievements = "Achievements"
    case statistics = "Statistics"
}

struct PopoverView: View {
    @Environment(AppModel.self) private var model
    @State private var showSettings = false
    @State private var showDev = false
    @State private var selected: Achievement?
    @State private var tab: PopoverTab

    /// When true, the achievement grid is drawn without a `ScrollView` so the
    /// whole popover renders in a single `ImageRenderer` pass (for screenshots).
    var staticRender = false

    init(staticRender: Bool = false, initialTab: PopoverTab = .achievements) {
        self.staticRender = staticRender
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                Divider()
                if showSettings {
                    SettingsView(showDev: $showDev)
                    Spacer(minLength: 0)
                } else if showDev {
                    DevModeView()
                } else {
                    tabSwitcher
                    if tab == .achievements {
                        summary
                        if staticRender {
                            AchievementGrid()
                        } else {
                            achievementList
                        }
                    } else if staticRender {
                        StatsView()
                        Spacer(minLength: 0)
                    } else {
                        // A ScrollView keeps the tab bar pinned; without it the tall
                        // stats content overflows and pushes the tab bar off-screen.
                        ScrollView { StatsView() }
                            .frame(maxHeight: .infinity)
                    }
                }
                Divider()
                footer
            }

            if let selected {
                let _ = model.stateVersion
                AchievementDetailView(
                    achievement: selected,
                    unlockDate: model.engine.state.unlocked[selected.id],
                    onClose: { withAnimation(.easeInOut(duration: 0.2)) { self.selected = nil } }
                )
                .transition(.opacity)
            }
        }
        .frame(width: 360)
        .frame(minHeight: staticRender ? nil : 500,
               idealHeight: staticRender ? nil : 680,
               maxHeight: staticRender ? nil : .infinity)
    }

    private var header: some View {
        HStack(spacing: 8) {
            LucideText(icon: .trophy, size: 15)
                .foregroundStyle(Theme.accent)
            Text("Cling")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Button {
                showSettings.toggle()
                showDev = false
            } label: {
                Image(systemName: showSettings ? "xmark" : "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(showSettings ? "Close settings" : "Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(PopoverTab.allCases, id: \.self) { item in
                let selected = tab == item
                Text(item.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selected ? .white : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 7).fill(Theme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) { tab = item }
                    }
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 9).fill(.quaternary.opacity(0.6)))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var summary: some View {
        let _ = model.stateVersion
        return VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(model.totalPoints)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                Text("P")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.accent.opacity(0.7))
                Spacer()
                if model.currentStreak >= 1 {
                    streakPill
                }
            }
            VStack(spacing: 6) {
                HStack {
                    Text("\(model.unlockedCount) of \(model.totalAchievements) unlocked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(model.completionPercent)%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ProgressBar(fraction: model.completionFraction, color: Theme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var streakPill: some View {
        HStack(spacing: 5) {
            LucideText(icon: .flame, size: 12)
            Text("\(model.currentStreak) day streak")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.accent.opacity(0.15)))
    }

    private var achievementList: some View {
        ScrollView {
            AchievementGrid(onSelect: { achievement in
                withAnimation(.easeInOut(duration: 0.2)) { selected = achievement }
            })
        }
        .frame(maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            if model.devMode {
                Button {
                    showDev.toggle()
                    showSettings = false
                } label: {
                    Image(systemName: "flask")
                        .font(.system(size: 14))
                        .foregroundStyle(showDev ? Theme.accent : .secondary)
                }
                .buttonStyle(.plain)
                .help("Dev mode")
            }
            Spacer()
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit Cling")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct ProgressBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary.opacity(0.6))
                Capsule()
                    .fill(color)
                    .frame(width: max(4, geo.size.width * min(1, fraction)))
                    .opacity(fraction > 0 ? 1 : 0)
            }
        }
        .frame(height: 4)
    }
}
