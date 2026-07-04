import Foundation

/// Parses one line of a Claude Code session transcript (`~/.claude/projects/*/<session>.jsonl`)
/// into zero or more events.
enum JSONLParser {
    private static let isoWithFraction = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let iso = Date.ISO8601FormatStyle()
    static let interruptMarker = "[Request interrupted by user]"

    static func parse(line: String) -> [TranscriptEvent] {
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any],
              let type = dict["type"] as? String,
              let sessionID = dict["sessionId"] as? String,
              let timestampString = dict["timestamp"] as? String,
              let timestamp = parseDate(timestampString)
        else { return [] }

        let message = dict["message"] as? [String: Any]

        switch type {
        case "user":
            return parseUser(dict: dict, message: message, timestamp: timestamp, sessionID: sessionID)
        case "assistant":
            return parseAssistant(message: message, timestamp: timestamp, sessionID: sessionID)
        default:
            return [.activity(timestamp: timestamp, sessionID: sessionID)]
        }
    }

    private static func parseUser(dict: [String: Any], message: [String: Any]?,
                                  timestamp: Date, sessionID: String) -> [TranscriptEvent] {
        let activity = TranscriptEvent.activity(timestamp: timestamp, sessionID: sessionID)
        let content = message?["content"]

        if let text = content as? String {
            if text.contains(interruptMarker) {
                return [.interrupted(timestamp: timestamp, sessionID: sessionID)]
            }
            if let command = slashCommand(in: text) {
                return [.slashCommand(name: command, timestamp: timestamp, sessionID: sessionID)]
            }
            if text.hasPrefix("<command-") || text.hasPrefix("<local-command") {
                return [activity]
            }
            if dict["isMeta"] as? Bool == true { return [activity] }
            return [.user(text: text, timestamp: timestamp, sessionID: sessionID)]
        }

        if let blocks = content as? [[String: Any]] {
            if let result = blocks.first(where: { $0["type"] as? String == "tool_result" }) {
                let isError = result["is_error"] as? Bool ?? false
                return [.toolResult(isError: isError, timestamp: timestamp, sessionID: sessionID)]
            }
            let text = blocks.filter { $0["type"] as? String == "text" }
                .compactMap { $0["text"] as? String }.joined(separator: "\n")
            if !text.isEmpty {
                return [.user(text: text, timestamp: timestamp, sessionID: sessionID)]
            }
        }
        return [activity]
    }

    private static func parseAssistant(message: [String: Any]?, timestamp: Date,
                                       sessionID: String) -> [TranscriptEvent] {
        var events: [TranscriptEvent] = []
        if let usageDict = message?["usage"] as? [String: Any] {
            var usage = Usage()
            usage.input = usageDict["input_tokens"] as? Int ?? 0
            usage.output = usageDict["output_tokens"] as? Int ?? 0
            usage.cacheCreate = usageDict["cache_creation_input_tokens"] as? Int ?? 0
            usage.cacheRead = usageDict["cache_read_input_tokens"] as? Int ?? 0
            let model = message?["model"] as? String
            events.append(.assistant(usage: usage, model: model,
                                     timestamp: timestamp, sessionID: sessionID))
        }
        if let blocks = message?["content"] as? [[String: Any]] {
            for block in blocks where block["type"] as? String == "tool_use" {
                let name = block["name"] as? String ?? ""
                let input = (block["input"] as? [String: Any]).map { serialize($0) } ?? ""
                events.append(.toolUse(name: name, input: input,
                                       timestamp: timestamp, sessionID: sessionID))
            }
        }
        if events.isEmpty { events.append(.activity(timestamp: timestamp, sessionID: sessionID)) }
        return events
    }

    /// Extracts the slash-command name from a `<command-name>/foo</command-name>` wrapper.
    private static func slashCommand(in text: String) -> String? {
        guard let open = text.range(of: "<command-name>"),
              let close = text.range(of: "</command-name>"),
              open.upperBound <= close.lowerBound else { return nil }
        let raw = text[open.upperBound..<close.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let name = raw.hasPrefix("/") ? String(raw.dropFirst()) : raw
        return name.isEmpty ? nil : name
    }

    private static func serialize(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let string = String(data: data, encoding: .utf8) else { return "" }
        return string
    }

    private static func parseDate(_ string: String) -> Date? {
        (try? Date(string, strategy: isoWithFraction)) ?? (try? Date(string, strategy: iso))
    }
}
