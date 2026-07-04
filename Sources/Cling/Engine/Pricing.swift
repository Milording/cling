import Foundation

/// Rough Claude API pricing for a gamified spend estimate (USD per million tokens).
/// These are ballpark public rates — the "$" achievements are estimates, not billing.
enum Pricing {
    struct Rate { let input, output, cacheWrite, cacheRead: Double }

    private static let opus = Rate(input: 15, output: 75, cacheWrite: 18.75, cacheRead: 1.5)
    private static let sonnet = Rate(input: 3, output: 15, cacheWrite: 3.75, cacheRead: 0.30)
    private static let haiku = Rate(input: 0.80, output: 4, cacheWrite: 1.0, cacheRead: 0.08)

    private static func rate(for model: String?) -> Rate {
        let m = model?.lowercased() ?? ""
        if m.contains("opus") { return opus }
        if m.contains("haiku") { return haiku }
        return sonnet
    }

    /// Estimated cost of one usage record, in US cents.
    static func cents(for usage: Usage, model: String?) -> Double {
        let r = rate(for: model)
        let dollars = (Double(usage.input) * r.input
            + Double(usage.output) * r.output
            + Double(usage.cacheCreate) * r.cacheWrite
            + Double(usage.cacheRead) * r.cacheRead) / 1_000_000
        return dollars * 100
    }
}
