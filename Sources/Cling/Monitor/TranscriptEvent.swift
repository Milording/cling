import Foundation

/// Token usage from an assistant entry's `message.usage`.
struct Usage: Equatable, Sendable {
    var input = 0
    var output = 0
    var cacheCreate = 0
    var cacheRead = 0
    var total: Int { input + output + cacheCreate + cacheRead }
}

/// A single relevant occurrence extracted from a Claude Code transcript line.
/// One JSONL line may yield several events (an assistant reply plus its tool calls).
enum TranscriptEvent: Equatable, Sendable {
    case user(text: String, timestamp: Date, sessionID: String)
    case assistant(usage: Usage, model: String?, timestamp: Date, sessionID: String)
    case toolUse(name: String, input: String, timestamp: Date, sessionID: String)
    case toolResult(isError: Bool, timestamp: Date, sessionID: String)
    case slashCommand(name: String, timestamp: Date, sessionID: String)
    case interrupted(timestamp: Date, sessionID: String)
    case activity(timestamp: Date, sessionID: String)

    var timestamp: Date {
        switch self {
        case .user(_, let t, _), .assistant(_, _, let t, _), .toolUse(_, _, let t, _),
             .toolResult(_, let t, _), .slashCommand(_, let t, _), .interrupted(let t, _),
             .activity(let t, _):
            return t
        }
    }

    var sessionID: String {
        switch self {
        case .user(_, _, let s), .assistant(_, _, _, let s), .toolUse(_, _, _, let s),
             .toolResult(_, _, let s), .slashCommand(_, _, let s), .interrupted(_, let s),
             .activity(_, let s):
            return s
        }
    }
}
