import SwiftUI
import Observation

@MainActor
@Observable
final class AppModel {
    let engine: AchievementEngine
    let toasts = ToastPresenter()
    @ObservationIgnored let monitor = TranscriptMonitor()

    private(set) var status: ClaudeStatus = .idle
    /// Bumped whenever engine state changes so views re-read progress/unlocks.
    private(set) var stateVersion = 0

    var devMode: Bool {
        didSet { UserDefaults.standard.set(devMode, forKey: "devMode") }
    }

    private var statusTimer: Timer?

    init() {
        let saved = Persistence.load()
        engine = AchievementEngine(state: saved ?? EngineState())
        devMode = UserDefaults.standard.bool(forKey: "devMode")

        monitor.offsets = engine.state.fileOffsets
        if saved == nil {
            // First launch: achievements are earned live, not backfilled.
            monitor.baselineToCurrentEnd()
            persist()
        }
        monitor.onEvents = { [weak self] events in self?.handle(events) }
        monitor.start()

        let timer = Timer(timeInterval: 5, repeats: true) { _ in
            Task { @MainActor [weak self] in self?.refreshStatus() }
        }
        RunLoop.main.add(timer, forMode: .common)
        statusTimer = timer
        refreshStatus()

        if ProcessInfo.processInfo.arguments.contains("--test-toast") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                for achievement in Achievements.all.prefix(2) {
                    devPreview(achievement)
                }
            }
        }

        // Renders share cards to a directory and exits; used for design review from the CLI.
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "--render-cards"), arguments.count > flagIndex + 1 {
            let directory = URL(fileURLWithPath: arguments[flagIndex + 1])
            Task { @MainActor in
                monitor.stop() // preview only — never persist the forced unlocks below
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let sample = Achievements.byID(Achievements.nightOwl)!
                for layout in ShareCardLayout.allCases {
                    if let data = ShareCardRenderer.pngData(for: sample, unlockDate: .now, layout: layout) {
                        try? data.write(to: directory.appendingPathComponent("card-\(layout.rawValue).png"))
                    }
                }
                let toast = ToastView(unlock: Unlock(achievement: sample, date: .now),
                                      staticOpen: true, onDone: {})
                    .frame(width: 520, height: 110)
                render(toast, scale: 2, to: directory.appendingPathComponent("toast.png"))

                // Force a couple of unlocks (in-memory only) so the grid shows both states.
                engine.unlock(Achievements.helloClaude)
                engine.unlock(Achievements.multitasker)
                stateVersion += 1
                func preview(_ scheme: ColorScheme) -> some View {
                    PopoverView(staticRender: true)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .environment(\.colorScheme, scheme)
                        .environment(self)
                }
                render(preview(.light), scale: 2, to: directory.appendingPathComponent("popover-light.png"))
                render(preview(.dark), scale: 2, to: directory.appendingPathComponent("popover-dark.png"))
                NSApplication.shared.terminate(nil)
            }
        }
    }

    var totalPoints: Int { engine.totalPoints }
    var unlockedCount: Int { engine.state.unlocked.count }

    func progress(for id: String) -> Double? { engine.progress(for: id) }

    func progressCaption(for id: String) -> String? {
        let state = engine.state
        switch id {
        case Achievements.firstBlood:
            return "\(state.totalOutputTokens.formatted()) of \(Achievements.tokenGoal.formatted()) tokens"
        case Achievements.pleaseThankYou:
            return "\(state.politenessCount) of \(Achievements.politenessGoal) kind words"
        case Achievements.multitasker:
            return "\(state.maxSessionsInADay) of \(Achievements.sessionsInDayGoal) conversations in a day"
        case Achievements.marathon:
            let minutes = Int(state.bestMarathonSeconds / 60)
            return "Best streak \(minutes / 60)h \(minutes % 60)m of 6h"
        default:
            return nil
        }
    }

    func handle(_ events: [TranscriptEvent]) {
        let unlocks = engine.process(events)
        persist()
        for unlock in unlocks {
            toasts.show(unlock)
        }
    }

    // MARK: - Dev mode

    func devPreview(_ achievement: Achievement) {
        toasts.show(Unlock(achievement: achievement, date: .now))
    }

    func devUnlock(_ achievement: Achievement) {
        if let unlock = engine.unlock(achievement.id) {
            persist()
            toasts.show(unlock)
        }
    }

    func devReset() {
        engine.reset()
        persist()
    }

    private func render(_ view: some View, scale: CGFloat, to url: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        if let cgImage = renderer.cgImage,
           let data = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) {
            try? data.write(to: url)
        }
    }

    private func refreshStatus() {
        status = ClaudeStatus.current(directoryExists: monitor.directoryExists,
                                      lastActivity: monitor.lastActivity)
    }

    private func persist() {
        engine.state.fileOffsets = monitor.offsets
        Persistence.save(engine.state)
        stateVersion += 1
    }
}
