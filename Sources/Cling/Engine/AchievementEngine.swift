import Foundation

struct Unlock: Equatable {
    let achievement: Achievement
    let date: Date
}

struct EngineState: Codable {
    var installDate: Date = .now
    /// Achievement id → unlock date.
    var unlocked: [String: Date] = [:]

    // Progress counters.
    var totalOutputTokens = 0
    var politenessCount = 0
    var maxSessionsInADay = 0
    var bestMarathonSeconds: TimeInterval = 0

    /// Sessions with a user message today (day key → session ids); pruned to the current day.
    var sessionsByDay: [String: Set<String>] = [:]
    /// Session id → timestamp of the user message currently awaiting a first response.
    var awaitingResponse: [String: Date] = [:]
    /// Session id → current no-gap streak.
    var marathonRuns: [String: MarathonRun] = [:]

    /// Transcript byte offsets already consumed (file path → offset).
    var fileOffsets: [String: UInt64] = [:]

    struct MarathonRun: Codable {
        var start: Date
        var lastEvent: Date
    }
}

/// Pure achievement logic: feed it transcript events, get unlocks back.
/// The caller persists `state` and presents the unlocks.
@MainActor
final class AchievementEngine {
    var state: EngineState

    init(state: EngineState = EngineState()) {
        self.state = state
    }

    func isUnlocked(_ id: String) -> Bool { state.unlocked[id] != nil }

    var totalPoints: Int {
        state.unlocked.keys.compactMap { Achievements.byID($0)?.points }.reduce(0, +)
    }

    /// Fraction toward the goal for locked achievements with meaningful progress.
    func progress(for id: String) -> Double? {
        switch id {
        case Achievements.firstBlood:
            Double(state.totalOutputTokens) / Double(Achievements.tokenGoal)
        case Achievements.pleaseThankYou:
            Double(state.politenessCount) / Double(Achievements.politenessGoal)
        case Achievements.multitasker:
            Double(state.maxSessionsInADay) / Double(Achievements.sessionsInDayGoal)
        case Achievements.marathon:
            state.bestMarathonSeconds / Achievements.marathonGoal
        default:
            nil
        }
    }

    func process(_ events: [TranscriptEvent]) -> [Unlock] {
        var unlocks: [Unlock] = []
        for event in events where event.timestamp >= state.installDate {
            trackMarathon(event, unlocks: &unlocks)
            switch event {
            case .userMessage(let text, let timestamp, let sessionID):
                trackUserMessage(text: text, timestamp: timestamp, sessionID: sessionID, unlocks: &unlocks)
            case .assistantMessage(let outputTokens, let timestamp, let sessionID):
                trackAssistantMessage(outputTokens: outputTokens, timestamp: timestamp,
                                      sessionID: sessionID, unlocks: &unlocks)
            case .activity:
                break
            }
        }
        return unlocks
    }

    /// Directly award an achievement (dev mode).
    @discardableResult
    func unlock(_ id: String, at date: Date = .now) -> Unlock? {
        guard state.unlocked[id] == nil, let achievement = Achievements.byID(id) else { return nil }
        state.unlocked[id] = date
        return Unlock(achievement: achievement, date: date)
    }

    func reset() {
        let offsets = state.fileOffsets
        state = EngineState()
        state.fileOffsets = offsets
    }

    // MARK: - Rules

    private func trackUserMessage(text: String, timestamp: Date, sessionID: String, unlocks: inout [Unlock]) {
        award(Achievements.helloClaude, at: timestamp, unlocks: &unlocks)

        let hour = Calendar.current.component(.hour, from: timestamp)
        if hour < 5 {
            award(Achievements.nightOwl, at: timestamp, unlocks: &unlocks)
        }

        if !isUnlocked(Achievements.pleaseThankYou) {
            state.politenessCount += occurrences(in: text, of: ["please", "thank you"])
            if state.politenessCount >= Achievements.politenessGoal {
                award(Achievements.pleaseThankYou, at: timestamp, unlocks: &unlocks)
            }
        }

        let dayKey = Self.dayKey(for: timestamp)
        state.sessionsByDay = state.sessionsByDay.filter { $0.key == dayKey }
        state.sessionsByDay[dayKey, default: []].insert(sessionID)
        let todayCount = state.sessionsByDay[dayKey]?.count ?? 0
        state.maxSessionsInADay = max(state.maxSessionsInADay, todayCount)
        if todayCount >= Achievements.sessionsInDayGoal {
            award(Achievements.multitasker, at: timestamp, unlocks: &unlocks)
        }

        state.awaitingResponse[sessionID] = timestamp
    }

    private func trackAssistantMessage(outputTokens: Int, timestamp: Date, sessionID: String,
                                       unlocks: inout [Unlock]) {
        state.totalOutputTokens += outputTokens
        if state.totalOutputTokens >= Achievements.tokenGoal {
            award(Achievements.firstBlood, at: timestamp, unlocks: &unlocks)
        }

        if let asked = state.awaitingResponse.removeValue(forKey: sessionID),
           timestamp.timeIntervalSince(asked) >= Achievements.waitGoal {
            award(Achievements.homunculus, at: timestamp, unlocks: &unlocks)
        }
    }

    private func trackMarathon(_ event: TranscriptEvent, unlocks: inout [Unlock]) {
        let sessionID = event.sessionID
        let timestamp = event.timestamp
        var run = state.marathonRuns[sessionID] ?? .init(start: timestamp, lastEvent: timestamp)
        if timestamp.timeIntervalSince(run.lastEvent) > Achievements.marathonMaxGap {
            run = .init(start: timestamp, lastEvent: timestamp)
        } else {
            run.lastEvent = timestamp
        }
        state.marathonRuns[sessionID] = run

        let span = run.lastEvent.timeIntervalSince(run.start)
        state.bestMarathonSeconds = max(state.bestMarathonSeconds, span)
        if span >= Achievements.marathonGoal {
            award(Achievements.marathon, at: timestamp, unlocks: &unlocks)
        }

        // Drop streaks that ended long ago so state stays small.
        state.marathonRuns = state.marathonRuns.filter {
            timestamp.timeIntervalSince($0.value.lastEvent) < 3600
        }
    }

    private func award(_ id: String, at date: Date, unlocks: inout [Unlock]) {
        if let unlock = unlock(id, at: date) {
            unlocks.append(unlock)
        }
    }

    private func occurrences(in text: String, of phrases: [String]) -> Int {
        let lowered = text.lowercased()
        var count = 0
        for phrase in phrases {
            var searchRange = lowered.startIndex..<lowered.endIndex
            while let found = lowered.range(of: phrase, range: searchRange) {
                count += 1
                searchRange = found.upperBound..<lowered.endIndex
            }
        }
        return count
    }

    static func dayKey(for date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year!)-\(parts.month!)-\(parts.day!)"
    }
}
