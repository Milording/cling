import SwiftUI

enum ClaudeStatus {
    /// Transcript written within the active window.
    case active
    /// Claude Code installed but quiet.
    case idle
    /// ~/.claude/projects not found.
    case notFound

    static let activeWindow: TimeInterval = 2 * 60

    static func current(directoryExists: Bool, lastActivity: Date?, now: Date = .now) -> ClaudeStatus {
        guard directoryExists else { return .notFound }
        if let lastActivity, now.timeIntervalSince(lastActivity) < activeWindow {
            return .active
        }
        return .idle
    }

    var label: String {
        switch self {
        case .active: "Active"
        case .idle: "Idle"
        case .notFound: "Not found"
        }
    }

    var color: Color {
        switch self {
        case .active: Theme.lime
        case .idle: Color(nsColor: .tertiaryLabelColor)
        case .notFound: Theme.coral
        }
    }
}
