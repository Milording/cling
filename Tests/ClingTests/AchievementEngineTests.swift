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

    /// Local-time date builder so hour-based rules are deterministic.
    private func date(day: Int = 1, hour: Int, minute: Int = 0, second: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(
            year: 2026, month: 7, day: day, hour: hour, minute: minute, second: second))!
    }

    private func user(_ text: String, at date: Date, session: String = "s1") -> TranscriptEvent {
        .userMessage(text: text, timestamp: date, sessionID: session)
    }

    private func assistant(tokens: Int, at date: Date, session: String = "s1") -> TranscriptEvent {
        .assistantMessage(outputTokens: tokens, timestamp: date, sessionID: session)
    }

    // MARK: - Hello, Claude

    func testFirstMessageUnlocksHelloClaude() {
        let unlocks = engine.process([user("hi", at: date(hour: 12))])
        XCTAssertEqual(unlocks.map(\.achievement.id), [Achievements.helloClaude])
        // Second message does not unlock again.
        XCTAssertTrue(engine.process([user("hi again", at: date(hour: 13))]).isEmpty)
    }

    func testEventsBeforeInstallDateAreIgnored() {
        engine.state.installDate = date(hour: 12)
        let unlocks = engine.process([user("old", at: date(hour: 11))])
        XCTAssertTrue(unlocks.isEmpty)
    }

    // MARK: - First Blood

    func testFirstBloodAtExactlyOneMillion() {
        XCTAssertTrue(engine.process([assistant(tokens: 999_999, at: date(hour: 10))]).isEmpty)
        let unlocks = engine.process([assistant(tokens: 1, at: date(hour: 10, minute: 1))])
        XCTAssertTrue(unlocks.contains { $0.achievement.id == Achievements.firstBlood })
        XCTAssertEqual(engine.state.totalOutputTokens, 1_000_000)
    }

    // MARK: - Night Owl

    func testNightOwlBoundaries() {
        XCTAssertTrue(engine.process([user("evening", at: date(hour: 23, minute: 59))])
            .allSatisfy { $0.achievement.id != Achievements.nightOwl })
        let unlocks = engine.process([user("midnight", at: date(day: 2, hour: 0, minute: 0))])
        XCTAssertTrue(unlocks.contains { $0.achievement.id == Achievements.nightOwl })
    }

    func testNoNightOwlAtFiveAM() {
        let unlocks = engine.process([user("early", at: date(hour: 5))])
        XCTAssertTrue(unlocks.allSatisfy { $0.achievement.id != Achievements.nightOwl })
    }

    // MARK: - Multitasker

    func testMultitaskerNeedsFiveSessionsSameDay() {
        for i in 0..<4 {
            let unlocks = engine.process([user("hi", at: date(hour: 10 + i), session: "s\(i)")])
            XCTAssertTrue(unlocks.allSatisfy { $0.achievement.id != Achievements.multitasker })
        }
        let unlocks = engine.process([user("hi", at: date(hour: 15), session: "s5")])
        XCTAssertTrue(unlocks.contains { $0.achievement.id == Achievements.multitasker })
    }

    func testMultitaskerResetsAcrossDays() {
        for i in 0..<4 {
            _ = engine.process([user("hi", at: date(day: 1, hour: 10 + i), session: "s\(i)")])
        }
        let unlocks = engine.process([user("hi", at: date(day: 2, hour: 10), session: "s5")])
        XCTAssertTrue(unlocks.allSatisfy { $0.achievement.id != Achievements.multitasker })
        XCTAssertEqual(engine.state.maxSessionsInADay, 4)
    }

    func testSameSessionCountsOnce() {
        for i in 0..<6 {
            let unlocks = engine.process([user("hi", at: date(hour: 10, minute: i), session: "same")])
            XCTAssertTrue(unlocks.allSatisfy { $0.achievement.id != Achievements.multitasker })
        }
    }

    // MARK: - Please and Thank You

    func testPolitenessCountsOccurrencesCaseInsensitive() {
        _ = engine.process([user("Please, PLEASE and thank you!", at: date(hour: 9))])
        XCTAssertEqual(engine.state.politenessCount, 3)
    }

    func testPolitenessUnlocksAtFifty() {
        let almostAll = Array(repeating: "please", count: 49).joined(separator: " ")
        XCTAssertTrue(engine.process([user(almostAll, at: date(hour: 9))])
            .allSatisfy { $0.achievement.id != Achievements.pleaseThankYou })
        let unlocks = engine.process([user("thank you", at: date(hour: 10))])
        XCTAssertTrue(unlocks.contains { $0.achievement.id == Achievements.pleaseThankYou })
    }

    // MARK: - Homunculus loxodontus

    func testThirtyMinuteWaitUnlocks() {
        let asked = date(hour: 10)
        _ = engine.process([user("slow question", at: asked)])
        let unlocks = engine.process([assistant(tokens: 5, at: asked.addingTimeInterval(31 * 60))])
        XCTAssertTrue(unlocks.contains { $0.achievement.id == Achievements.homunculus })
    }

    func testFastResponseDoesNotUnlock() {
        let asked = date(hour: 10)
        _ = engine.process([
            user("quick question", at: asked),
            assistant(tokens: 5, at: asked.addingTimeInterval(29 * 60)),
        ])
        XCTAssertFalse(engine.isUnlocked(Achievements.homunculus))
        // A later assistant message in the same turn doesn't count as a new wait.
        _ = engine.process([assistant(tokens: 5, at: asked.addingTimeInterval(45 * 60))])
        XCTAssertFalse(engine.isUnlocked(Achievements.homunculus))
    }

    // MARK: - The Marathon

    func testSixHourStreakUnlocks() {
        let start = date(hour: 8)
        let events = stride(from: 0.0, through: 6 * 3600, by: 25).map {
            TranscriptEvent.activity(timestamp: start.addingTimeInterval($0), sessionID: "m")
        }
        let unlocks = engine.process(events)
        XCTAssertTrue(unlocks.contains { $0.achievement.id == Achievements.marathon })
    }

    func testGapOverThirtySecondsResetsStreak() {
        let start = date(hour: 8)
        var events = stride(from: 0.0, to: 3 * 3600, by: 25).map {
            TranscriptEvent.activity(timestamp: start.addingTimeInterval($0), sessionID: "m")
        }
        // 31s gap in the middle, then another 3.5 hours of activity.
        let resume = start.addingTimeInterval(3 * 3600 + 31)
        events += stride(from: 0.0, through: 3.5 * 3600, by: 25).map {
            TranscriptEvent.activity(timestamp: resume.addingTimeInterval($0), sessionID: "m")
        }
        let unlocks = engine.process(events)
        XCTAssertTrue(unlocks.allSatisfy { $0.achievement.id != Achievements.marathon })
        XCTAssertEqual(engine.state.bestMarathonSeconds, 3.5 * 3600, accuracy: 30)
    }

    // MARK: - State round-trip

    func testStateSurvivesEncodingRoundTrip() throws {
        _ = engine.process([
            user("please", at: date(hour: 10)),
            assistant(tokens: 42, at: date(hour: 10, minute: 1)),
        ])
        let data = try JSONEncoder().encode(engine.state)
        let restored = try JSONDecoder().decode(EngineState.self, from: data)
        XCTAssertEqual(restored.unlocked.keys.sorted(), engine.state.unlocked.keys.sorted())
        XCTAssertEqual(restored.totalOutputTokens, 42)
        XCTAssertEqual(restored.politenessCount, 1)
    }

    func testResetClearsProgressButKeepsOffsets() {
        engine.state.fileOffsets = ["/a.jsonl": 123]
        _ = engine.process([user("please", at: date(hour: 10))])
        engine.reset()
        XCTAssertTrue(engine.state.unlocked.isEmpty)
        XCTAssertEqual(engine.state.politenessCount, 0)
        XCTAssertEqual(engine.state.fileOffsets, ["/a.jsonl": 123])
    }
}
