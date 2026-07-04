import Foundation

/// A single relevant occurrence extracted from a Claude Code transcript.
enum TranscriptEvent: Equatable {
    /// A human-authored message (string content, not meta / command wrappers).
    case userMessage(text: String, timestamp: Date, sessionID: String)
    /// An assistant API response; `outputTokens` comes from `message.usage.output_tokens`.
    case assistantMessage(outputTokens: Int, timestamp: Date, sessionID: String)
    /// Any other timestamped session activity (tool results, local commands).
    /// Counts for "no gap" streaks but not for message-based achievements.
    case activity(timestamp: Date, sessionID: String)

    var timestamp: Date {
        switch self {
        case .userMessage(_, let t, _), .assistantMessage(_, let t, _), .activity(let t, _):
            return t
        }
    }

    var sessionID: String {
        switch self {
        case .userMessage(_, _, let s), .assistantMessage(_, _, let s), .activity(_, let s):
            return s
        }
    }
}
