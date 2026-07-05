import Foundation

struct Unlock: Equatable {
    let achievement: Achievement
    let date: Date
}

struct EngineState: Codable {
    var installDate: Date = .now
    var unlocked: [String: Date] = [:]
    var fileOffsets: [String: UInt64] = [:]

    /// Simple additive counters, keyed by `Achievements.s*`.
    var counters: [String: Int] = [:]
    var tokens = 0
    var costCents: Double = 0

    // Distinct-day sets (ordinal day numbers).
    var nightDays: Set<Int> = []
    var morningDays: Set<Int> = []
    var activityDays: Set<Int> = []
    var lastActivityDay: Int?

    // Weekends: a weekend is "complete" when both its Saturday and Sunday saw activity.
    var weekendSat: Set<String> = []
    var weekendSun: Set<String> = []

    var mcpServers: Set<String> = []
    var projectDirs = 0
    var maxSimultaneous = 1

    // Deja Vu: session → normalized-block → repeat count.
    var sessionBlocks: [String: [String: Int]] = [:]
    // The Refactorer: sessions already counted as deletion-heavy.
    var refactorCounted: Set<String> = []
    var sessionEdits: [String: [Int]] = [:]     // session → [added, deleted]
    // Multitasker: session → last-active time (pruned).
    var sessionLastActive: [String: Date] = [:]

    // Activity by hour-of-day (0…23), for the "most active" statistic.
    // Optional so decoding older saved state (without this key) still succeeds.
    var hourCounts: [Int]?
}

/// Pure achievement logic: feed it transcript events, get unlocks back.
@MainActor
final class AchievementEngine {
    var state: EngineState

    init(state: EngineState = EngineState()) { self.state = state }

    func isUnlocked(_ id: String) -> Bool { state.unlocked[id] != nil }

    var totalPoints: Int {
        state.unlocked.keys.compactMap { Achievements.byID($0)?.points }.reduce(0, +)
    }

    // MARK: - Stats

    /// The current value of every tracked stat.
    func stats() -> [String: Int] {
        var s = state.counters
        s[Achievements.sTokens] = state.tokens
        s[Achievements.sCostCents] = Int(state.costCents)
        s[Achievements.sNights] = state.nightDays.count
        s[Achievements.sMornings] = state.morningDays.count
        s[Achievements.sStreak] = longestStreak(state.activityDays)
        s[Achievements.sWeekends] = state.weekendSat.intersection(state.weekendSun).count
        s[Achievements.sMcpServers] = state.mcpServers.count
        s[Achievements.sProjectDirs] = state.projectDirs
        s[Achievements.sMultitasker] = state.maxSimultaneous
        s[Achievements.sCompletion] = state.unlocked.keys.filter { $0 != Achievements.completionID }.count
        return s
    }

    func value(for stat: String) -> Int { stats()[stat] ?? 0 }

    /// The run of consecutive active days ending today or yesterday (0 if the streak is broken).
    func currentStreak(now: Date = .now) -> Int {
        guard let last = state.activityDays.max() else { return 0 }
        guard last >= Self.dayOrdinal(now) - 1 else { return 0 }
        var streak = 0
        var day = last
        while state.activityDays.contains(day) {
            streak += 1
            day -= 1
        }
        return streak
    }

    /// The peak 2-hour activity window, formatted for the user's locale
    /// (e.g. "11PM–1AM" in the US, "23–01" in 24-hour Europe). Nil if there's no data.
    func mostActiveWindow() -> String? {
        guard let counts = state.hourCounts, let peak = counts.indices.max(by: { counts[$0] < counts[$1] }),
              counts[peak] > 0 else { return nil }

        let formatter = DateFormatter()
        formatter.locale = .current
        // "j" = locale-appropriate hour field (12-hour with AM/PM, or 24-hour).
        formatter.setLocalizedDateFormatFromTemplate("j")
        let calendar = Calendar.current
        func label(_ h: Int) -> String {
            let hour = ((h % 24) + 24) % 24
            let date = calendar.date(from: DateComponents(hour: hour)) ?? Date()
            // Drop the space some locales insert ("11 PM" → "11PM") for a compact range.
            return formatter.string(from: date).replacingOccurrences(of: " ", with: "")
        }
        return "\(label(peak))–\(label(peak + 2))"
    }

    func progress(for id: String) -> Double? {
        guard let a = Achievements.byID(id), a.goal > 1 else { return nil }
        let v = value(for: a.stat)
        guard v > 0 else { return nil }
        return min(1, Double(v) / Double(a.goal))
    }

    func progressCaption(for id: String) -> String? {
        guard let a = Achievements.byID(id) else { return nil }
        let v = value(for: a.stat)
        switch a.unit {
        case .tokens:
            return "\(v.formatted()) of \(a.goal.formatted()) tokens"
        case .usdCents:
            return String(format: "$%.2f of $%d", Double(v) / 100, a.goal / 100)
        case .days:
            return "\(v) of \(a.goal)-day streak"
        case .count:
            return "\(v.formatted()) of \(a.goal.formatted())"
        }
    }

    // MARK: - Processing

    func process(_ events: [TranscriptEvent]) -> [Unlock] {
        var latest = state.installDate
        for event in events where event.timestamp >= state.installDate {
            latest = max(latest, event.timestamp)
            trackTimestamp(event.timestamp, session: event.sessionID)
            switch event {
            case .user(let text, _, let session):
                state.counters[Achievements.sFirstContact] = 1
                trackUserText(text, session: session)
            case .assistant(let usage, let model, _, _):
                state.tokens += usage.total
                state.costCents += Pricing.cents(for: usage, model: model)
            case .toolUse(let name, let input, _, let session):
                trackToolUse(name: name, input: input, session: session)
            case .toolResult(let isError, _, _):
                if !isError { bump(Achievements.sApprovals) }
            case .slashCommand(let name, _, _):
                trackSlash(name)
            case .interrupted:
                bump(Achievements.sInterruptions)
            case .activity:
                break
            }
        }
        return checkUnlocks(at: latest)
    }

    private func checkUnlocks(at date: Date) -> [Unlock] {
        let current = stats()
        var unlocks: [Unlock] = []
        for achievement in Achievements.all where state.unlocked[achievement.id] == nil {
            if current[achievement.stat, default: 0] >= achievement.goal {
                if let unlock = unlock(achievement.id, at: date) { unlocks.append(unlock) }
            }
        }
        return unlocks
    }

    @discardableResult
    func unlock(_ id: String, at date: Date = .now) -> Unlock? {
        guard state.unlocked[id] == nil, let achievement = Achievements.byID(id) else { return nil }
        state.unlocked[id] = date
        return Unlock(achievement: achievement, date: date)
    }

    func reset() {
        let offsets = state.fileOffsets
        let dirs = state.projectDirs
        state = EngineState()
        state.fileOffsets = offsets
        state.projectDirs = dirs
    }

    /// Called by the app when the project-dir count changes.
    func updateProjectDirs(_ count: Int) -> [Unlock] {
        state.projectDirs = count
        return checkUnlocks(at: .now)
    }

    // MARK: - Trackers

    private func trackTimestamp(_ ts: Date, session: String) {
        let day = Self.dayOrdinal(ts)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: ts)

        if hour < 5 { state.nightDays.insert(day) }
        if hour >= 5, hour < 7 { state.morningDays.insert(day) }
        state.activityDays.insert(day)

        if state.hourCounts == nil { state.hourCounts = Array(repeating: 0, count: 24) }
        state.hourCounts?[hour] += 1

        let weekday = calendar.component(.weekday, from: ts)   // 1=Sun … 7=Sat
        let weekID = weekendID(ts, calendar: calendar)
        if weekday == 7 { state.weekendSat.insert(weekID) }
        if weekday == 1 { state.weekendSun.insert(weekID) }

        let comps = calendar.dateComponents([.month, .day], from: ts)
        if (comps.month == 12 && comps.day == 25) || (comps.month == 1 && comps.day == 1) {
            state.counters[Achievements.sHoliday] = 1
        }

        if let last = state.lastActivityDay, day - last >= 30 {
            state.counters[Achievements.sOldFriend] = 1
        }
        state.lastActivityDay = max(state.lastActivityDay ?? day, day)

        // Simultaneous sessions: how many sessions were active within the last 90s.
        state.sessionLastActive[session] = ts
        state.sessionLastActive = state.sessionLastActive.filter { ts.timeIntervalSince($0.value) < 90 }
        state.maxSimultaneous = max(state.maxSimultaneous, state.sessionLastActive.count)
    }

    private func trackUserText(_ text: String, session: String) {
        let lower = text.lowercased()
        add(Achievements.sPoliteness, occurrences(in: lower, of: ["please", "thank you"]))
        add(Achievements.sSorry, occurrences(in: lower, of: ["sorry"]))
        add(Achievements.sProfanity, occurrences(in: lower, of: ["fuck"]))
        add(Achievements.sExorcist, occurrences(in: lower, of: ["why did you do that"]))
        if lower.contains("you were right") { state.counters[Achievements.sGaslighter] = 1 }
        if lower.contains("make no mistakes") { state.counters[Achievements.sFeelingLucky] = 1 }
        if lower.contains("remove claude") || lower.contains("co-authored") || lower.contains("contributor") {
            state.counters[Achievements.sErased] = 1
        }
        if lower.contains(".claude/projects") || lower.contains(".jsonl") {
            state.counters[Achievements.sInception] = 1
        }
        if text.split(whereSeparator: \.isWhitespace).count < 5 { bump(Achievements.sShortPrompts) }

        // Deja Vu — same block pasted 5× in a session.
        let key = String(lower.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2000))
        guard !key.isEmpty else { return }
        state.sessionBlocks[session, default: [:]][key, default: 0] += 1
        if state.sessionBlocks[session]?[key] ?? 0 >= 5 { state.counters[Achievements.sDejaVu] = 1 }
    }

    private func trackToolUse(name: String, input: String, session: String) {
        if name.hasPrefix("mcp__") {
            state.counters[Achievements.sMcpAny] = 1
            let parts = name.split(separator: "_", omittingEmptySubsequences: true)
            if let server = parts.first { state.mcpServers.insert(String(server)) }
        }
        if name == "Bash", input.contains("git commit") { bump(Achievements.sGitCommits) }

        if name == "Edit" || name == "Write" || name == "MultiEdit" {
            let (added, deleted) = editDelta(name: name, input: input)
            var totals = state.sessionEdits[session] ?? [0, 0]
            totals[0] += added
            totals[1] += deleted
            state.sessionEdits[session] = totals
            if totals[1] > totals[0], !state.refactorCounted.contains(session) {
                state.refactorCounted.insert(session)
                bump(Achievements.sRefactor)
            }
        }
    }

    private func trackSlash(_ name: String) {
        let n = name.lowercased()
        if n.hasPrefix("doctor") { bump(Achievements.sDoctor) }
        if n.hasPrefix("feedback") { bump(Achievements.sFeedback) }
        if n.hasPrefix("fast") { state.counters[Achievements.sFast] = 1 }
        if n.hasPrefix("radio") { state.counters[Achievements.sRadio] = 1 }
        if n.contains("karpathy") { state.counters[Achievements.sKarpathy] = 1 }
    }

    // MARK: - Helpers

    private func bump(_ key: String) { state.counters[key, default: 0] += 1 }
    private func add(_ key: String, _ n: Int) { if n > 0 { state.counters[key, default: 0] += n } }

    private func editDelta(name: String, input: String) -> (added: Int, deleted: Int) {
        guard let data = input.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return (0, 0) }
        func lines(_ s: String?) -> Int { s.map { $0.split(separator: "\n", omittingEmptySubsequences: false).count } ?? 0 }
        if name == "Write" { return (lines(dict["content"] as? String), 0) }
        return (lines(dict["new_string"] as? String), lines(dict["old_string"] as? String))
    }

    private func occurrences(in lowered: String, of phrases: [String]) -> Int {
        var count = 0
        for phrase in phrases {
            var range = lowered.startIndex..<lowered.endIndex
            while let found = lowered.range(of: phrase, range: range) {
                count += 1
                range = found.upperBound..<lowered.endIndex
            }
        }
        return count
    }

    private func longestStreak(_ days: Set<Int>) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var best = 1, run = 1
        for i in 1..<sorted.count {
            if sorted[i] == sorted[i - 1] + 1 { run += 1; best = max(best, run) }
            else { run = 1 }
        }
        return best
    }

    private func weekendID(_ ts: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: ts)
        return "\(c.yearForWeekOfYear ?? 0)-\(c.weekOfYear ?? 0)"
    }

    private static let referenceDay = Calendar.current.startOfDay(
        for: Date(timeIntervalSinceReferenceDate: 0))

    static func dayOrdinal(_ ts: Date) -> Int {
        let start = Calendar.current.startOfDay(for: ts)
        return Calendar.current.dateComponents([.day], from: referenceDay, to: start).day ?? 0
    }
}
