import SwiftUI
import Observation
import ImageIO
import UniformTypeIdentifiers

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
        toasts.onSelect = { [weak self] unlock in self?.showDetail(for: unlock) }
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

        // Renders the unlock-toast animation to an animated GIF and exits (for the README).
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "--render-toast-gif"), arguments.count > flagIndex + 1 {
            let url = URL(fileURLWithPath: arguments[flagIndex + 1])
            Task { @MainActor in
                monitor.stop()
                let unlock = Unlock(achievement: Achievements.byID("millionaire-1")!, date: .now)
                renderToastGIF(unlock, to: url)
                NSApplication.shared.terminate(nil)
            }
        }

        // Renders a rotating coin medal to an animated GIF and exits (for the README).
        if let flagIndex = arguments.firstIndex(of: "--render-coin-gif"), arguments.count > flagIndex + 1 {
            let url = URL(fileURLWithPath: arguments[flagIndex + 1])
            Task { @MainActor in
                monitor.stop()
                renderCoinGIF(Achievements.byID("millionaire-3")!, to: url)
                NSApplication.shared.terminate(nil)
            }
        }

        // Renders share cards to a directory and exits; used for design review from the CLI.
        if let flagIndex = arguments.firstIndex(of: "--render-cards"), arguments.count > flagIndex + 1 {
            let directory = URL(fileURLWithPath: arguments[flagIndex + 1])
            Task { @MainActor in
                monitor.stop() // preview only — never persist the forced unlocks below
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let sample = Achievements.byID("night-owl-1")!
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
                engine.unlock("first-contact")
                engine.unlock("multitasker")
                let today = AchievementEngine.dayOrdinal(.now)
                engine.state.activityDays = [today, today - 1, today - 2]
                engine.state.tokens = 47_200_000
                engine.state.costCents = 18_640
                engine.state.hourCounts = { var h = Array(repeating: 2, count: 24); h[23] = 40; return h }()
                stateVersion += 1
                func preview(_ scheme: ColorScheme) -> some View {
                    PopoverView(staticRender: true)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .environment(\.colorScheme, scheme)
                        .environment(self)
                }
                render(preview(.light), scale: 2, to: directory.appendingPathComponent("popover-light.png"))
                render(preview(.dark), scale: 2, to: directory.appendingPathComponent("popover-dark.png"))
                func stats(_ scheme: ColorScheme) -> some View {
                    StatsView()
                        .frame(width: 360)
                        .background(Color(nsColor: .windowBackgroundColor))
                        .environment(\.colorScheme, scheme)
                        .environment(self)
                }
                render(stats(.light), scale: 2, to: directory.appendingPathComponent("stats-light.png"))
                render(stats(.dark), scale: 2, to: directory.appendingPathComponent("stats-dark.png"))
                render(SocialPreviewView(), scale: 1, to: directory.appendingPathComponent("social-preview.png"))

                // Coin medal snapshots at a few rotations (SceneKit, offscreen).
                for (id, deg) in [("first-contact", 0.0), ("first-contact", 35.0),
                                  ("first-contact", 180.0), ("multitasker", 30.0),
                                  ("daily-driver-4", 30.0)] {
                    let a = Achievements.byID(id)!
                    let image = CoinMedal.snapshot(achievement: a, unlocked: true,
                                                   angle: deg * .pi / 180, size: 520,
                                                   backText: "Jul 5, 2026")
                    if let data = NSBitmapImageRep(data: image.tiffRepresentation!)?
                        .representation(using: .png, properties: [:]) {
                        try? data.write(to: directory.appendingPathComponent("coin-\(id)-\(Int(deg)).png"))
                    }
                }
                let detail = AchievementDetailView(
                    achievement: Achievements.byID("first-contact")!, unlockDate: .now,
                    onClose: {}, staticRender: true)
                    .frame(width: 360)
                    .environment(self)
                render(detail, scale: 2, to: directory.appendingPathComponent("detail.png"))
                let summary = SummaryToastView(
                    title: "Unlocked 14 achievements",
                    counts: [(.gold, 3), (.silver, 5), (.bronze, 6)],
                    staticRender: true, onDone: {})
                    .frame(width: 520, height: 110)
                render(summary, scale: 2, to: directory.appendingPathComponent("summary.png"))
                NSApplication.shared.terminate(nil)
            }
        }
    }

    var totalPoints: Int { engine.totalPoints }
    var unlockedCount: Int { engine.state.unlocked.count }
    var totalAchievements: Int { Achievements.all.count }
    var completionFraction: Double { Double(unlockedCount) / Double(totalAchievements) }
    var completionPercent: Int { Int((completionFraction * 100).rounded()) }
    var currentStreak: Int { engine.currentStreak() }

    // MARK: - Statistics (Statistics tab)

    var statTokens: Int { engine.state.tokens }
    var statCostDollars: Double { engine.state.costCents / 100 }
    var statLongestStreak: Int { engine.value(for: Achievements.sStreak) }
    var statMostActive: String? { engine.mostActiveWindow() }

    /// True while a full-history recalculation is running.
    private(set) var isRecalculating = false

    /// Rebuilds all progress by replaying every local transcript from the beginning.
    /// Unlocks are applied silently (no toast flood) since this is a bulk backfill.
    func recalculateFromLogs() {
        guard !isRecalculating else { return }
        isRecalculating = true
        monitor.stop()
        let directory = monitor.projectsDirectory
        Task {
            let result = await Task.detached {
                TranscriptMonitor.scanAll(projectsDirectory: directory)
            }.value

            engine.reset()
            engine.state.installDate = .distantPast    // count the full history
            let unlocks = engine.process(result.events) // applied silently (no toast flood)
            monitor.offsets = result.offsets
            refreshProjectDirs()
            persist()

            isRecalculating = false
            monitor.start()                            // resume live tailing

            // Summarize the backfill: counts per tier, most-valuable tier first.
            let counts = Tier.allCases.reversed().compactMap { tier -> (tier: Tier, count: Int)? in
                let n = unlocks.filter { $0.achievement.tier == tier }.count
                return n > 0 ? (tier, n) : nil
            }
            let total = unlocks.count
            toasts.showSummary(
                title: total == 0 ? "Progress recalculated"
                                   : "Unlocked \(total) achievement\(total == 1 ? "" : "s")",
                counts: counts)
        }
    }

    func progress(for id: String) -> Double? { engine.progress(for: id) }
    func progressCaption(for id: String) -> String? { engine.progressCaption(for: id) }

    func handle(_ events: [TranscriptEvent]) {
        let unlocks = engine.process(events)
        persist()
        for unlock in unlocks {
            toasts.show(unlock)
        }
    }

    /// Counts project directories under ~/.claude/projects for the Project Hopper stats.
    private func refreshProjectDirs() {
        let dirs = (try? FileManager.default.contentsOfDirectory(
            at: monitor.projectsDirectory, includingPropertiesForKeys: [.isDirectoryKey]))?
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .count ?? 0
        guard dirs != engine.state.projectDirs else { return }
        let unlocks = engine.updateProjectDirs(dirs)
        persist()
        for unlock in unlocks { toasts.show(unlock) }
    }

    // MARK: - Detail window

    private var detailWindow: NSWindow?

    /// Opens the app and shows a tapped unlock toast's achievement in its own window.
    func showDetail(for unlock: Unlock) {
        NSApp.activate(ignoringOtherApps: true)
        let date = engine.state.unlocked[unlock.achievement.id] ?? unlock.date
        let view = AchievementDetailView(
            achievement: unlock.achievement, unlockDate: date,
            onClose: { [weak self] in self?.detailWindow?.close() })
            .environment(self)
            .frame(width: 360, height: 560)

        let window = detailWindow ?? {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 560),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.isReleasedWhenClosed = false
            window.level = .floating
            detailWindow = window
            return window
        }()
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.makeKeyAndOrderFront(nil)
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

    /// Renders the Xbox-style unlock animation as a looping GIF.
    private func renderToastGIF(_ unlock: Unlock, to url: URL) {
        let canvas = CGSize(width: 580, height: 150)
        let fps = 20.0
        let frameDelay = 1.0 / fps

        // easeOutBack — overshoots past 1 before settling, for the badge spring-in.
        func easeOutBack(_ t: Double) -> Double {
            let c1 = 1.70158, c3 = c1 + 1
            let p = t - 1
            return 1 + c3 * p * p * p + c1 * p * p
        }
        func easeOut(_ t: Double) -> Double { 1 - (1 - t) * (1 - t) }
        func easeIn(_ t: Double) -> Double { t * t }

        struct Frame { var scale: CGFloat; var opacity: Double; var reveal: CGFloat; var delay: Double }
        var frames: [Frame] = []

        // 1. Badge springs in.
        for i in 0..<12 {
            let t = Double(i) / 11
            frames.append(Frame(scale: 0.3 + 0.7 * easeOutBack(t),
                                opacity: min(1, t * 4), reveal: 0, delay: frameDelay))
        }
        // 2. Pill expands and text reveals.
        for i in 0..<10 {
            let t = Double(i) / 9
            frames.append(Frame(scale: 1, opacity: 1, reveal: easeOut(t), delay: frameDelay))
        }
        // 3. Hold, fully open.
        frames.append(Frame(scale: 1, opacity: 1, reveal: 1, delay: 1.6))
        // 4. Pill collapses back to the badge.
        for i in 0..<7 {
            let t = Double(i) / 6
            frames.append(Frame(scale: 1, opacity: 1, reveal: 1 - easeIn(t), delay: frameDelay))
        }
        // 5. Badge shrinks and fades away.
        for i in 0..<8 {
            let t = Double(i) / 7
            frames.append(Frame(scale: 1 - 0.7 * easeIn(t), opacity: 1 - easeIn(t),
                                reveal: 0, delay: frameDelay))
        }
        // 6. Empty beat before the loop restarts.
        frames.append(Frame(scale: 0.3, opacity: 0, reveal: 0, delay: 0.7))

        var images: [(image: CGImage, delay: Double)] = []
        for frame in frames {
            let view = ToastGIFFrame(unlock: unlock, scale: frame.scale,
                                     opacity: frame.opacity, reveal: frame.reveal)
                .frame(width: canvas.width, height: canvas.height)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            if let cgImage = renderer.cgImage { images.append((cgImage, frame.delay)) }
        }
        writeGIF(images, to: url)
    }

    /// Renders a full 360° rotation of a coin medal as a looping GIF.
    private func renderCoinGIF(_ achievement: Achievement, to url: URL) {
        let frameCount = 40
        let delay = 0.05
        var images: [(image: CGImage, delay: Double)] = []
        for i in 0..<frameCount {
            let angle = 2 * Double.pi * Double(i) / Double(frameCount)
            let snapshot = CoinMedal.snapshot(achievement: achievement, unlocked: true,
                                              angle: angle, size: 420, backText: "Jul 5, 2026")
            if let cgImage = snapshot.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                images.append((cgImage, delay))
            }
        }
        writeGIF(images, to: url)
    }

    /// Encodes a sequence of frames into an infinitely-looping GIF at `url`.
    private func writeGIF(_ frames: [(image: CGImage, delay: Double)], to url: URL) {
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.gif.identifier as CFString, frames.count,
            [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary
        ) else { return }
        for frame in frames {
            let properties = [kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frame.delay,
                kCGImagePropertyGIFUnclampedDelayTime: frame.delay,
            ]] as CFDictionary
            CGImageDestinationAddImage(dest, frame.image, properties)
        }
        CGImageDestinationFinalize(dest)
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
        refreshProjectDirs()
    }

    private func persist() {
        engine.state.fileOffsets = monitor.offsets
        Persistence.save(engine.state)
        stateVersion += 1
    }
}
