import SwiftUI

enum Tier: String, Codable, CaseIterable {
    case bronze, silver, gold, platinum

    var label: String { rawValue.capitalized }
    var points: Int {
        switch self {
        case .bronze: 15
        case .silver: 25
        case .gold: 50
        case .platinum: 100
        }
    }

    var color: Color {
        switch self {
        case .bronze: Color(hex: 0xC4823E)
        case .silver: Color(hex: 0xADB0B6)
        case .gold: Color(hex: 0xE0B23C)
        case .platinum: Color(hex: 0xBBC7D8)
        }
    }
}

/// Keys for the values the engine tracks. An achievement unlocks when its
/// stat reaches its goal. Stubbed stats (no reliable log signal yet) never
/// increment — their achievements stay locked until wired up.
enum Stat {
    enum Unit { case count, tokens, usdCents, days }
}

struct Achievement: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    let tier: Tier
    let icon: LucideIcon
    /// The engine value this tracks; unlocks when it reaches `goal`.
    let stat: String
    var goal: Int = 1
    var unit: Stat.Unit = .count
    var hidden: Bool = false
    var sound: String = "achievement"

    var points: Int { tier.points }

    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }
}

enum Achievements {
    // Stat keys.
    static let sFirstContact = "firstContact"
    static let sTokens = "tokens"
    static let sCostCents = "costCents"
    static let sNights = "nights"
    static let sMornings = "mornings"
    static let sStreak = "streak"
    static let sWeekends = "weekends"
    static let sHoliday = "holiday"
    static let sOldFriend = "oldFriend"
    static let sMultitasker = "multitasker"
    static let sPoliteness = "politeness"
    static let sSorry = "sorry"
    static let sProfanity = "profanity"
    static let sExorcist = "exorcist"
    static let sGaslighter = "gaslighter"
    static let sFeelingLucky = "feelingLucky"
    static let sErased = "erased"
    static let sShortPrompts = "shortPrompts"
    static let sDejaVu = "dejaVu"
    static let sApprovals = "approvals"
    static let sDoctor = "doctor"
    static let sFeedback = "feedback"
    static let sFast = "fast"
    static let sRadio = "radio"
    static let sKarpathy = "karpathy"
    static let sContextLimit = "contextLimit"
    static let sProjectDirs = "projectDirs"
    static let sMcpAny = "mcpAny"
    static let sMcpServers = "mcpServers"
    static let sGitCommits = "gitCommits"
    static let sInterruptions = "interruptions"
    static let sRefactor = "refactorSessions"
    static let sItCompiles = "itCompiles"
    static let sSkipPermissions = "skipPermissions"
    static let sWeeklyLimit = "weeklyLimit"
    static let sShipIt = "shipIt"
    static let sIntervention = "intervention"
    static let sInception = "inception"
    static let sCompletion = "completion"

    /// Stats we can't reliably read from the logs yet; their achievements stay locked.
    static let stubbedStats: Set<String> = [
        sSkipPermissions, sWeeklyLimit, sShipIt, sIntervention, sInception, sItCompiles,
    ]

    static let all: [Achievement] = {
        var list: [Achievement] = [
            // MARK: Bronze
            Achievement(id: "first-contact", name: "First Contact",
                        blurb: "Send your very first message — Hello, World.",
                        tier: .bronze, icon: .sparkles, stat: sFirstContact),
            Achievement(id: "millionaire-1", name: "Millionaire's Club I",
                        blurb: "Pocket Change — reach 1,000,000 tokens.",
                        tier: .bronze, icon: .coins, stat: sTokens, goal: 1_000_000,
                        unit: .tokens, sound: "firstblood"),
            Achievement(id: "night-owl-1", name: "Night Owl I",
                        blurb: "Past Your Bedtime — 10 nights coding between midnight and 5 AM.",
                        tier: .bronze, icon: .moon, stat: sNights, goal: 10),
            Achievement(id: "early-bird-1", name: "Early Bird I",
                        blurb: "Worm Getter — 10 mornings between 5 and 7 AM.",
                        tier: .bronze, icon: .sunrise, stat: sMornings, goal: 10),
            Achievement(id: "daily-driver-1", name: "Daily Driver I",
                        blurb: "Habit Forming — a 7-day streak.",
                        tier: .bronze, icon: .flame, stat: sStreak, goal: 7, unit: .days),
            Achievement(id: "please-1", name: "Thank You, Please I",
                        blurb: "Raised Right — 15 pleases or thank-yous.",
                        tier: .bronze, icon: .heartHandshake, stat: sPoliteness, goal: 15),
            Achievement(id: "apology-tour", name: "Apology Tour",
                        blurb: "My Bad — say sorry 10 times.",
                        tier: .bronze, icon: .frown, stat: sSorry, goal: 10),
            Achievement(id: "potty-mouth-1", name: "Potty Mouth I",
                        blurb: "Pardon My French — swear once.",
                        tier: .bronze, icon: .skull, stat: sProfanity, goal: 1),
            Achievement(id: "exorcist", name: "The Exorcist",
                        blurb: "What Are You Doing — ask \u{201C}why did you do that\u{201D} 10 times.",
                        tier: .bronze, icon: .ghost, stat: sExorcist, goal: 10),
            Achievement(id: "deja-vu", name: "Deja Vu",
                        blurb: "Have We Met? — paste the same block 5 times in one session.",
                        tier: .bronze, icon: .copy, stat: sDejaVu, goal: 1),
            Achievement(id: "approver-1", name: "Approver I",
                        blurb: "Rubber Stamp — 100 approved tool calls.",
                        tier: .bronze, icon: .badgeCheck, stat: sApprovals, goal: 100),
            Achievement(id: "doctor-1", name: "Doctor I",
                        blurb: "Second Opinion — run /doctor 10 times.",
                        tier: .bronze, icon: .stethoscope, stat: sDoctor, goal: 10),
            Achievement(id: "feedback-1", name: "Feedback I",
                        blurb: "Suggestion Box — run /feedback 10 times.",
                        tier: .bronze, icon: .messageSquare, stat: sFeedback, goal: 10),
            Achievement(id: "speed-demon", name: "Speed Demon",
                        blurb: "Gotta Go Fast — run /fast once.",
                        tier: .bronze, icon: .zap, stat: sFast, goal: 1),
            Achievement(id: "context-goblin-1", name: "Context Goblin I",
                        blurb: "Bursting at the Seams — hit the context limit once.",
                        tier: .bronze, icon: .brain, stat: sContextLimit, goal: 1),
            Achievement(id: "project-hopper-1", name: "Project Hopper I",
                        blurb: "Tourist — use Claude Code in 5 projects.",
                        tier: .bronze, icon: .folder, stat: sProjectDirs, goal: 5),
            Achievement(id: "mcp-curious", name: "MCP Curious",
                        blurb: "Plugged In (Almost) — use your first MCP tool.",
                        tier: .bronze, icon: .plug, stat: sMcpAny, goal: 1),
            Achievement(id: "git-gud-1", name: "Git Gud I",
                        blurb: "Commit-ment — 10 git commits.",
                        tier: .bronze, icon: .gitCommit, stat: sGitCommits, goal: 10),
            Achievement(id: "first-dollar", name: "First Dollar",
                        blurb: "Ka-Ching — $1 of estimated usage.",
                        tier: .bronze, icon: .circleDollarSign, stat: sCostCents, goal: 100, unit: .usdCents),
            Achievement(id: "trust-fall-1", name: "Trust Fall I",
                        blurb: "Living Dangerously — first --dangerously-skip-permissions.",
                        tier: .bronze, icon: .shieldAlert, stat: sSkipPermissions, goal: 1),

            // MARK: Silver
            Achievement(id: "millionaire-2", name: "Millionaire's Club II",
                        blurb: "Token Baron — reach 10,000,000 tokens.",
                        tier: .silver, icon: .coins, stat: sTokens, goal: 10_000_000, unit: .tokens),
            Achievement(id: "night-owl-2", name: "Night Owl II",
                        blurb: "Nocturnal by Nature — 100 nights.",
                        tier: .silver, icon: .moon, stat: sNights, goal: 100),
            Achievement(id: "early-bird-2", name: "Early Bird II",
                        blurb: "Rooster — 100 mornings.",
                        tier: .silver, icon: .sunrise, stat: sMornings, goal: 100),
            Achievement(id: "daily-driver-2", name: "Daily Driver II",
                        blurb: "Regular — a 30-day streak.",
                        tier: .silver, icon: .flame, stat: sStreak, goal: 30, unit: .days),
            Achievement(id: "please-2", name: "Thank You, Please II",
                        blurb: "The Polite One — 100 pleases or thank-yous.",
                        tier: .silver, icon: .heartHandshake, stat: sPoliteness, goal: 100),
            Achievement(id: "potty-mouth-2", name: "Potty Mouth II",
                        blurb: "Sailor's Vocabulary — swear 25 times.",
                        tier: .silver, icon: .skull, stat: sProfanity, goal: 25),
            Achievement(id: "approver-2", name: "Approver II",
                        blurb: "Yes Man — 1,000 approved tool calls.",
                        tier: .silver, icon: .badgeCheck, stat: sApprovals, goal: 1000),
            Achievement(id: "doctor-2", name: "Doctor II",
                        blurb: "Frequent Flyer — run /doctor 100 times.",
                        tier: .silver, icon: .stethoscope, stat: sDoctor, goal: 100),
            Achievement(id: "feedback-2", name: "Feedback II",
                        blurb: "Squeaky Wheel — run /feedback 100 times.",
                        tier: .silver, icon: .messageSquare, stat: sFeedback, goal: 100),
            Achievement(id: "rage-quit-1", name: "CTRL+C Rage Quit I",
                        blurb: "Trigger Finger — interrupt Claude 100 times.",
                        tier: .silver, icon: .circleStop, stat: sInterruptions, goal: 100),
            Achievement(id: "context-goblin-2", name: "Context Goblin II",
                        blurb: "Hoarder of Tokens — hit the context limit 50 times.",
                        tier: .silver, icon: .brain, stat: sContextLimit, goal: 50),
            Achievement(id: "project-hopper-2", name: "Project Hopper II",
                        blurb: "Digital Nomad — 25 projects.",
                        tier: .silver, icon: .folders, stat: sProjectDirs, goal: 25),
            Achievement(id: "plugged-in", name: "Plugged In",
                        blurb: "Fully Wired — use 5 distinct MCP servers.",
                        tier: .silver, icon: .plugZap, stat: sMcpServers, goal: 5),
            Achievement(id: "git-gud-2", name: "Git Gud II",
                        blurb: "Century Committer — 100 git commits.",
                        tier: .silver, icon: .gitCommit, stat: sGitCommits, goal: 100),
            Achievement(id: "latte-money", name: "Latte Money",
                        blurb: "Coffee Budget — $50 of estimated usage.",
                        tier: .silver, icon: .coffee, stat: sCostCents, goal: 5000, unit: .usdCents),
            Achievement(id: "refactorer", name: "The Refactorer",
                        blurb: "Less Is More — 50 sessions that deleted more than they added.",
                        tier: .silver, icon: .scissors, stat: sRefactor, goal: 50),
            Achievement(id: "it-compiles", name: "It Compiles",
                        blurb: "First Try, No Lies — a build or test passes right after an edit.",
                        tier: .silver, icon: .badgeCheck, stat: sItCompiles, goal: 1),
            Achievement(id: "few-words", name: "Man of Few Words",
                        blurb: "Grunt Work — 100 prompts under 5 words.",
                        tier: .silver, icon: .pilcrow, stat: sShortPrompts, goal: 100),
            Achievement(id: "weekend-warrior", name: "Weekend Warrior",
                        blurb: "No Days Off — code both days of 10 weekends.",
                        tier: .silver, icon: .tent, stat: sWeekends, goal: 10),
            Achievement(id: "multitasker", name: "Multitasker",
                        blurb: "Octopus Mode — 3 sessions running at once.",
                        tier: .silver, icon: .layers, stat: sMultitasker, goal: 3),
            Achievement(id: "gaslighter", name: "Gaslighter",
                        blurb: "Fine, You Win — tell Claude \u{201C}you were right\u{201D}.",
                        tier: .silver, icon: .crown, stat: sGaslighter, goal: 1),
            Achievement(id: "erased-history", name: "Erased from History",
                        blurb: "Ask to remove Claude from the contributors.",
                        tier: .silver, icon: .eraser, stat: sErased, goal: 1, hidden: true),
            Achievement(id: "feeling-lucky", name: "I'm Feeling Lucky",
                        blurb: "Tell Claude to \u{201C}make no mistakes\u{201D}.",
                        tier: .silver, icon: .clover, stat: sFeelingLucky, goal: 1, hidden: true),
            Achievement(id: "lofi", name: "Lo-Fi Beats to Refactor To",
                        blurb: "Run /radio once.",
                        tier: .silver, icon: .music, stat: sRadio, goal: 1, hidden: true),
            Achievement(id: "senpai", name: "Senpai Noticed You",
                        blurb: "Use an andrej-karpathy skill.",
                        tier: .silver, icon: .graduationCap, stat: sKarpathy, goal: 1, hidden: true),
            Achievement(id: "old-friend", name: "Hello, Old Friend",
                        blurb: "Come back after 30+ days away.",
                        tier: .silver, icon: .undo, stat: sOldFriend, goal: 1, hidden: true),
            Achievement(id: "intervention", name: "The Intervention",
                        blurb: "Claude suggests you take a break.",
                        tier: .silver, icon: .coffee, stat: sIntervention, goal: 1, hidden: true),
            Achievement(id: "inception", name: "Inception",
                        blurb: "Build a tool that parses Claude Code logs.",
                        tier: .silver, icon: .brain, stat: sInception, goal: 1, hidden: true),
            Achievement(id: "vacation", name: "Vacation? What Vacation?",
                        blurb: "Code on December 25th or January 1st.",
                        tier: .silver, icon: .palmtree, stat: sHoliday, goal: 1, hidden: true),

            // MARK: Gold
            Achievement(id: "millionaire-3", name: "Millionaire's Club III",
                        blurb: "Old Money — reach 100,000,000 tokens.",
                        tier: .gold, icon: .gem, stat: sTokens, goal: 100_000_000, unit: .tokens),
            Achievement(id: "night-owl-3", name: "Night Owl III",
                        blurb: "Creature of the Night — 365 nights.",
                        tier: .gold, icon: .moon, stat: sNights, goal: 365),
            Achievement(id: "daily-driver-3", name: "Daily Driver III",
                        blurb: "Locked In — a 100-day streak.",
                        tier: .gold, icon: .flame, stat: sStreak, goal: 100, unit: .days),
            Achievement(id: "please-3", name: "Thank You, Please III",
                        blurb: "Saint of the Terminal — 1,000 pleases or thank-yous.",
                        tier: .gold, icon: .heartHandshake, stat: sPoliteness, goal: 1000),
            Achievement(id: "potty-mouth-3", name: "Potty Mouth III",
                        blurb: "Anger Management Candidate — swear 100 times.",
                        tier: .gold, icon: .skull, stat: sProfanity, goal: 100),
            Achievement(id: "doctor-3", name: "Doctor III",
                        blurb: "Chronic Condition — run /doctor 1,000 times.",
                        tier: .gold, icon: .stethoscope, stat: sDoctor, goal: 1000),
            Achievement(id: "feedback-3", name: "Feedback III",
                        blurb: "Unpaid QA Engineer — run /feedback 1,000 times.",
                        tier: .gold, icon: .messageSquare, stat: sFeedback, goal: 1000),
            Achievement(id: "rage-quit-2", name: "CTRL+C Rage Quit II",
                        blurb: "Serial Interrupter — interrupt Claude 1,000 times.",
                        tier: .gold, icon: .circleStop, stat: sInterruptions, goal: 1000),
            Achievement(id: "context-goblin-3", name: "Context Goblin III",
                        blurb: "The Context Must Flow — hit the context limit 500 times.",
                        tier: .gold, icon: .brain, stat: sContextLimit, goal: 500),
            Achievement(id: "project-hopper-3", name: "Project Hopper III",
                        blurb: "Empire Builder — 100 projects.",
                        tier: .gold, icon: .folders, stat: sProjectDirs, goal: 100),
            Achievement(id: "git-gud-3", name: "Git Gud III",
                        blurb: "Merge Lord — 1,000 git commits.",
                        tier: .gold, icon: .gitCommit, stat: sGitCommits, goal: 1000),
            Achievement(id: "car-payment", name: "Car Payment",
                        blurb: "It's an Investment — $500 of estimated usage.",
                        tier: .gold, icon: .banknote, stat: sCostCents, goal: 50000, unit: .usdCents),
            Achievement(id: "trust-fall-2", name: "Trust Fall II",
                        blurb: "YOLO Merge — 100 skip-permission sessions.",
                        tier: .gold, icon: .shield, stat: sSkipPermissions, goal: 100),
            Achievement(id: "ship-it", name: "Ship It",
                        blurb: "Friday Deploy — push to main on a Friday after 5 PM.",
                        tier: .gold, icon: .rocket, stat: sShipIt, goal: 1, hidden: true),

            // MARK: Platinum
            Achievement(id: "best-customer", name: "Anthropic's Best Customer",
                        blurb: "Hit the weekly limit 52 times.",
                        tier: .platinum, icon: .creditCard, stat: sWeeklyLimit, goal: 52),
            Achievement(id: "daily-driver-4", name: "Daily Driver IV",
                        blurb: "365: A Love Story — a 365-day streak.",
                        tier: .platinum, icon: .flame, stat: sStreak, goal: 365, unit: .days),
            Achievement(id: "should-have-bought-stock", name: "Should've Bought Stock",
                        blurb: "$5,000 of estimated lifetime usage.",
                        tier: .platinum, icon: .gem, stat: sCostCents, goal: 500000, unit: .usdCents,
                        hidden: true),
        ]
        // 100% completion — unlock when every other achievement is unlocked.
        list.append(Achievement(id: "completion", name: "100% Claude Completion",
                                blurb: "Touch Grass — unlock every other achievement.",
                                tier: .platinum, icon: .award, stat: sCompletion, goal: list.count))
        return list
    }()

    static func byID(_ id: String) -> Achievement? { all.first { $0.id == id } }
    static let maxPoints = all.reduce(0) { $0 + $1.points }
    static let completionID = "completion"
}
