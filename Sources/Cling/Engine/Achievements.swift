import SwiftUI

enum Tier: String, Codable, CaseIterable {
    case bronze, silver, gold

    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .bronze: Color(hex: 0xC4823E)
        case .silver: Color(hex: 0xADB0B6)
        case .gold: Color(hex: 0xE0B23C)
        }
    }
}

struct Achievement: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let tier: Tier
    let points: Int
    let icon: LucideIcon
    /// mp3 resource played on unlock.
    let sound: String

    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }
}

enum Achievements {
    static let helloClaude = "hello-claude"
    static let firstBlood = "first-blood"
    static let nightOwl = "night-owl"
    static let multitasker = "multitasker"
    static let pleaseThankYou = "please-thank-you"
    static let homunculus = "homunculus-loxodontus"
    static let marathon = "the-marathon"

    static let tokenGoal = 1_000_000
    static let politenessGoal = 50
    static let sessionsInDayGoal = 5
    static let waitGoal: TimeInterval = 30 * 60
    static let marathonGoal: TimeInterval = 6 * 60 * 60
    static let marathonMaxGap: TimeInterval = 30

    static let all: [Achievement] = [
        Achievement(id: helloClaude, name: "Hello, Claude",
                    blurb: "Send your first message",
                    tier: .bronze, points: 10, icon: .messageCircle, sound: "achievement"),
        Achievement(id: firstBlood, name: "First Blood",
                    blurb: "Generate your first 1,000,000 tokens",
                    tier: .bronze, points: 15, icon: .droplet, sound: "firstblood"),
        Achievement(id: nightOwl, name: "Night Owl",
                    blurb: "Use Claude Code after midnight",
                    tier: .bronze, points: 15, icon: .moon, sound: "achievement"),
        Achievement(id: multitasker, name: "Multitasker",
                    blurb: "Have 5 conversations open in one day",
                    tier: .silver, points: 25, icon: .layers, sound: "achievement"),
        Achievement(id: pleaseThankYou, name: "Please and Thank You",
                    blurb: "Say \u{201C}please\u{201D} or \u{201C}thank you\u{201D} to Claude 50 times",
                    tier: .silver, points: 25, icon: .heartHandshake, sound: "achievement"),
        Achievement(id: homunculus, name: "Homunculus loxodontus",
                    blurb: "Wait more than 30 minutes for a response",
                    tier: .gold, points: 100, icon: .hourglass, sound: "achievement"),
        Achievement(id: marathon, name: "The Marathon",
                    blurb: "A 6-hour session with no gaps over 30 seconds",
                    tier: .gold, points: 100, icon: .footprints, sound: "achievement"),
    ]

    static func byID(_ id: String) -> Achievement? {
        all.first { $0.id == id }
    }

    static let maxPoints = all.reduce(0) { $0 + $1.points }
}
