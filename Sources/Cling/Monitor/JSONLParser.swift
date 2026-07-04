import Foundation

/// Parses one line of a Claude Code session transcript (`~/.claude/projects/*/<session>.jsonl`).
enum JSONLParser {
    private static let isoWithFraction = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let iso = Date.ISO8601FormatStyle()

    static func parse(line: String) -> TranscriptEvent? {
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any],
              let type = dict["type"] as? String,
              let sessionID = dict["sessionId"] as? String,
              let timestampString = dict["timestamp"] as? String,
              let timestamp = parseDate(timestampString)
        else { return nil }

        let message = dict["message"] as? [String: Any]

        switch type {
        case "user":
            guard dict["isMeta"] as? Bool != true else {
                return .activity(timestamp: timestamp, sessionID: sessionID)
            }
            return parseUser(message: message, timestamp: timestamp, sessionID: sessionID)
        case "assistant":
            let usage = message?["usage"] as? [String: Any]
            if let outputTokens = usage?["output_tokens"] as? Int {
                return .assistantMessage(outputTokens: outputTokens, timestamp: timestamp, sessionID: sessionID)
            }
            return .activity(timestamp: timestamp, sessionID: sessionID)
        default:
            // Progress/system entries still indicate session liveness.
            return .activity(timestamp: timestamp, sessionID: sessionID)
        }
    }

    private static func parseUser(message: [String: Any]?, timestamp: Date, sessionID: String) -> TranscriptEvent {
        let activity = TranscriptEvent.activity(timestamp: timestamp, sessionID: sessionID)
        guard let content = message?["content"] else { return activity }

        if let text = content as? String {
            // Slash-command wrappers and local-command output are not human prose.
            if text.hasPrefix("<command-") || text.hasPrefix("<local-command") {
                return activity
            }
            return .userMessage(text: text, timestamp: timestamp, sessionID: sessionID)
        }

        if let blocks = content as? [[String: Any]] {
            // Tool results arrive as user-typed entries; they are machine activity.
            if blocks.contains(where: { $0["type"] as? String == "tool_result" }) {
                return activity
            }
            let text = blocks
                .filter { $0["type"] as? String == "text" }
                .compactMap { $0["text"] as? String }
                .joined(separator: "\n")
            if !text.isEmpty {
                return .userMessage(text: text, timestamp: timestamp, sessionID: sessionID)
            }
        }
        return activity
    }

    private static func parseDate(_ string: String) -> Date? {
        (try? Date(string, strategy: isoWithFraction)) ?? (try? Date(string, strategy: iso))
    }
}
