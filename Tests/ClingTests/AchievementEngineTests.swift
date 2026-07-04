import XCTest
@testable import Cling

@MainActor
final class AchievementEngineTests: XCTestCase {
    private var engine: AchievementEngine!

    override func setUp() async throws {
        var state = EngineState()
        state.installDate = .distantPast
        engine = AchievementEngine(state: state)
    }

    private func date(day: Int = 1, hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: day,
                                                   hour: hour, minute: minute))!
    }

    private func unlockedIDs(_ unlocks: [Unlock]) -> Set<String> {
        Set(unlocks.map(\.achievement.id))
    }

    func testFirstContact() {
        let unlocks = engine.process([.user(text: "hi", timestamp: date(hour: 12), sessionID: "s")])
        XCTAssertTrue(unlockedIDs(unlocks).contains("first-contact"))
    }

    func testTokensAndCost() {
        // 1M tokens on Sonnet unlocks Millionaire I; also crosses $1 (First Dollar).
        let unlocks = engine.process([
            .assistant(usage: Usage(input: 0, output: 1_000_000), model: "claude-sonnet-4",
                       timestamp: date(hour: 10), sessionID: "s"),
        ])
        XCTAssertTrue(unlockedIDs(unlocks).contains("millionaire-1"))
        XCTAssertTrue(unlockedIDs(unlocks).contains("first-dollar")) // 1M output × $15/M = $15
        XCTAssertEqual(engine.value(for: Achievements.sTokens), 1_000_000)
    }

    func testNightsCountDistinctDays() {
        var events: [TranscriptEvent] = []
        for d in 1...10 {
            events.append(.user(text: "x", timestamp: date(day: d, hour: 2), sessionID: "s"))
        }
        let unlocks = engine.process(events)
        XCTAssertEqual(engine.value(for: Achievements.sNights), 10)
        XCTAssertTrue(unlockedIDs(unlocks).contains("night-owl-1"))
    }

    func testMorningsWindow() {
        _ = engine.process([.user(text: "x", timestamp: date(hour: 6), sessionID: "s")])
        XCTAssertEqual(engine.value(for: Achievements.sMornings), 1)
        _ = engine.process([.user(text: "x", timestamp: date(day: 2, hour: 7), sessionID: "s")]) // 7am excluded
        XCTAssertEqual(engine.value(for: Achievements.sMornings), 1)
    }

    func testStreak() {
        let events = (1...7).map { TranscriptEvent.user(text: "x", timestamp: date(day: $0, hour: 12), sessionID: "s") }
        let unlocks = engine.process(events)
        XCTAssertEqual(engine.value(for: Achievements.sStreak), 7)
        XCTAssertTrue(unlockedIDs(unlocks).contains("daily-driver-1"))
    }

    func testStreakBreaks() {
        let events = [1, 2, 3, 5, 6].map { TranscriptEvent.user(text: "x", timestamp: date(day: $0, hour: 12), sessionID: "s") }
        _ = engine.process(events)
        XCTAssertEqual(engine.value(for: Achievements.sStreak), 3)
    }

    func testPolitenessTiers() {
        let text = Array(repeating: "please thank you", count: 8).joined(separator: " ") // 16 occurrences
        let unlocks = engine.process([.user(text: text, timestamp: date(hour: 12), sessionID: "s")])
        XCTAssertGreaterThanOrEqual(engine.value(for: Achievements.sPoliteness), 15)
        XCTAssertTrue(unlockedIDs(unlocks).contains("please-1"))
    }

    func testProfanityAndSorry() {
        _ = engine.process([.user(text: "sorry sorry fuck", timestamp: date(hour: 12), sessionID: "s")])
        XCTAssertEqual(engine.value(for: Achievements.sProfanity), 1)
        XCTAssertEqual(engine.value(for: Achievements.sSorry), 2)
    }

    func testHiddenPhrases() {
        _ = engine.process([.user(text: "You were right, my bad", timestamp: date(hour: 12), sessionID: "s")])
        XCTAssertTrue(engine.isUnlocked("gaslighter"))
    }

    func testShortPrompts() {
        _ = engine.process([.user(text: "fix it", timestamp: date(hour: 12), sessionID: "s")])
        XCTAssertEqual(engine.value(for: Achievements.sShortPrompts), 1)
        _ = engine.process([.user(text: "this one has plenty of words here", timestamp: date(hour: 13), sessionID: "s")])
        XCTAssertEqual(engine.value(for: Achievements.sShortPrompts), 1)
    }

    func testGitCommitsAndMcp() {
        _ = engine.process([
            .toolUse(name: "Bash", input: "{\"command\":\"git commit -m x\"}", timestamp: date(hour: 12), sessionID: "s"),
            .toolUse(name: "mcp__amplitude__search", input: "{}", timestamp: date(hour: 12), sessionID: "s"),
        ])
        XCTAssertEqual(engine.value(for: Achievements.sGitCommits), 1)
        XCTAssertEqual(engine.value(for: Achievements.sMcpAny), 1)
        XCTAssertEqual(engine.value(for: Achievements.sMcpServers), 1)
        XCTAssertTrue(engine.isUnlocked("mcp-curious"))
    }

    func testInterruptionsAndApprovals() {
        var events: [TranscriptEvent] = []
        for _ in 0..<100 { events.append(.interrupted(timestamp: date(hour: 12), sessionID: "s")) }
        for _ in 0..<100 { events.append(.toolResult(isError: false, timestamp: date(hour: 12), sessionID: "s")) }
        let unlocks = engine.process(events)
        XCTAssertEqual(engine.value(for: Achievements.sInterruptions), 100)
        XCTAssertEqual(engine.value(for: Achievements.sApprovals), 100)
        XCTAssertTrue(unlockedIDs(unlocks).contains("rage-quit-1"))
        XCTAssertTrue(unlockedIDs(unlocks).contains("approver-1"))
    }

    func testSlashCommands() {
        _ = engine.process([.slashCommand(name: "fast", timestamp: date(hour: 12), sessionID: "s")])
        XCTAssertTrue(engine.isUnlocked("speed-demon"))
    }

    func testMultitaskerSimultaneous() {
        let unlocks = engine.process((0..<3).map {
            TranscriptEvent.user(text: "x", timestamp: date(hour: 12), sessionID: "s\($0)")
        })
        XCTAssertEqual(engine.value(for: Achievements.sMultitasker), 3)
        XCTAssertTrue(unlockedIDs(unlocks).contains("multitasker"))
    }

    func testProjectDirsUnlock() {
        let unlocks = engine.updateProjectDirs(5)
        XCTAssertTrue(unlockedIDs(unlocks).contains("project-hopper-1"))
    }

    func testEventsBeforeInstallIgnored() {
        engine.state.installDate = date(hour: 12)
        let unlocks = engine.process([.user(text: "old", timestamp: date(hour: 11), sessionID: "s")])
        XCTAssertTrue(unlocks.isEmpty)
    }

    func testStateRoundTrip() throws {
        _ = engine.process([
            .user(text: "please", timestamp: date(hour: 12), sessionID: "s"),
            .assistant(usage: Usage(input: 10, output: 20), model: "claude-sonnet-4",
                       timestamp: date(hour: 12), sessionID: "s"),
        ])
        let data = try JSONEncoder().encode(engine.state)
        let restored = try JSONDecoder().decode(EngineState.self, from: data)
        XCTAssertEqual(restored.tokens, 30)
        XCTAssertEqual(restored.unlocked.keys.sorted(), engine.state.unlocked.keys.sorted())
    }
}
