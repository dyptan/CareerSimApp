import Foundation

/// A spare-time venture that tries to *monetize the player's talents* — the soft
/// skills built up through hobbies and activities. Unlike a salaried job (whose
/// pay is taxed and mostly eaten by living costs before the savings rate takes
/// its slice), a side hustle's takings are banked in full, so a strong hobby can
/// meaningfully accelerate the road to the first million.
///
/// Each attempt is a gamble: the player stakes some capital up front, and the
/// odds and the payout both scale with how well their talents fit the venture.
/// A flop salvages half the stake. Examples range from a local small business to
/// a shot at influencer fame, releasing an album, or landing a TV-show casting.
struct SideHustle: Identifiable, Hashable {
    let id: String
    let label: String
    let icon: String
    let blurb: String
    /// The soft-skill axes this venture monetizes. The player's levels in these
    /// talents drive both the success odds and the size of the payout.
    let talents: [WritableKeyPath<SoftSkills, Int>]
    /// Capital staked up front to attempt the hustle this year (seed inventory,
    /// studio time, gear). Lost on a flop except for a half-stake salvage.
    let startupCost: Int
    /// Earnings on a successful year, before talent scaling. The actual payout is
    /// interpolated across this range by the player's talent fit, then jittered.
    let payoutRange: ClosedRange<Int>
    /// Life stages in which the hustle is offered (mirrors `Activity.stages`).
    let stages: Set<LifeStage>

    static func == (lhs: SideHustle, rhs: SideHustle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Talent level at which a single axis is considered a perfect fit (caps the
    /// per-axis contribution at 1.0). Reachable mid-game by a focused hobbyist.
    static let talentReference = 6

    /// 0...1 measure of how well the player's talents suit this venture: the mean
    /// of each required axis, normalized against `talentReference` and capped.
    func talentFit(for soft: SoftSkills) -> Double {
        guard !talents.isEmpty else { return 0 }
        let total = talents.reduce(0.0) { acc, kp in
            acc + min(Double(soft[keyPath: kp]) / Double(SideHustle.talentReference), 1.0)
        }
        return total / Double(talents.count)
    }

    /// Probability (0.1...0.9) that the venture pays off in a given year.
    func successProbability(for soft: SoftSkills) -> Double {
        max(0.1, min(0.9, 0.2 + talentFit(for: soft) * 0.65))
    }

    /// The payout a successful year would yield at the player's current talent
    /// fit, without the random jitter — used to preview the upside in the UI.
    func projectedPayout(for soft: SoftSkills) -> Int {
        let lo = Double(payoutRange.lowerBound)
        let hi = Double(payoutRange.upperBound)
        return Int((lo + (hi - lo) * talentFit(for: soft)).rounded())
    }

    /// Rolls a single year of this hustle. On success the takings (banked in
    /// full) are returned; on a flop, half the stake is salvaged. The caller is
    /// responsible for having already charged `startupCost`.
    func resolve(for soft: SoftSkills) -> Outcome {
        let succeeded = Double.random(in: 0...1) < successProbability(for: soft)
        guard succeeded else {
            return Outcome(hustle: self, success: false, credit: startupCost / 2)
        }
        let base = Double(projectedPayout(for: soft))
        let jitter = Double.random(in: 0.75...1.25)
        let payout = max(payoutRange.lowerBound, Int((base * jitter).rounded()))
        return Outcome(hustle: self, success: true, credit: payout)
    }

    /// Result of resolving one year of a side hustle.
    struct Outcome {
        let hustle: SideHustle
        let success: Bool
        /// Money returned to the player this year (full payout on success, or a
        /// half-stake salvage on a flop). Does not subtract the stake — the
        /// caller charges that separately.
        let credit: Int
    }
}

/// Master catalogue of side hustles, filtered by life stage in the UI the same
/// way `activities` is. Tutoring is open to teens; capital-heavy ventures (real
/// estate, a brick-and-mortar shop) are adult-only.
enum SideHustleCatalog {
    static let all: [SideHustle] = [
        SideHustle(
            id: "tutoring",
            label: "Tutoring",
            icon: "📐",
            blurb: "Coach younger students after school. No money down — just your know-how and patience.",
            talents: [\.communicationAndNetworking, \.analyticalReasoningAndProblemSolving, \.empathyAndInterpersonalCare],
            startupCost: 0,
            payoutRange: 500...8_000,
            stages: [.teen, .youngAdult, .adult]
        ),
        SideHustle(
            id: "etsyCrafts",
            label: "Sell Art & Crafts Online",
            icon: "🧵",
            blurb: "Turn a making hobby into an online storefront of handmade goods.",
            talents: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision, \.carefulnessAndAttentionToDetail],
            startupCost: 1_500,
            payoutRange: 500...16_000,
            stages: [.teen, .youngAdult, .adult]
        ),
        SideHustle(
            id: "influencer",
            label: "Influencer / Content Creator",
            icon: "📱",
            blurb: "Build an audience and chase brand deals. Most channels fizzle — a viral one prints money.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            startupCost: 1_000,
            payoutRange: 0...45_000,
            stages: [.teen, .youngAdult, .adult]
        ),
        SideHustle(
            id: "freelanceConsulting",
            label: "Freelance Consulting",
            icon: "💻",
            blurb: "Take on paid projects on the side, solving problems for clients after hours.",
            talents: [\.analyticalReasoningAndProblemSolving, \.communicationAndNetworking, \.timeManagementAndPlanning],
            startupCost: 500,
            payoutRange: 1_000...30_000,
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "fitnessCoaching",
            label: "Fitness Coaching",
            icon: "🏋️",
            blurb: "Train clients on evenings and weekends, turning your own discipline into income.",
            talents: [\.resilienceAndEndurance, \.communicationAndNetworking, \.empathyAndInterpersonalCare],
            startupCost: 800,
            payoutRange: 1_000...20_000,
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "selfPublishBook",
            label: "Write & Self-Publish a Book",
            icon: "📚",
            blurb: "Spend the year writing and publishing. Most titles sell little; a hit earns for years.",
            talents: [\.presentationAndStorytelling, \.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking],
            startupCost: 1_000,
            payoutRange: 0...28_000,
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "releaseAlbum",
            label: "Record & Release an Album",
            icon: "🎵",
            blurb: "Book studio time and put your music out there. Long odds, but a breakout single pays big.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            startupCost: 6_000,
            payoutRange: 0...55_000,
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "tvShow",
            label: "Cast on a TV Show",
            icon: "📺",
            blurb: "Audition for a spot on screen. The longest shot of them all — and the biggest paycheck.",
            talents: [\.presentationAndStorytelling, \.communicationAndNetworking, \.stressResistanceAndEmotionalRegulation],
            startupCost: 500,
            payoutRange: 0...70_000,
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "smallBusiness",
            label: "Start a Small Business",
            icon: "🏪",
            blurb: "Open a local shop or service. Real overhead and real risk, but a steady earner when it clicks.",
            talents: [\.persuasionAndNegotiation, \.riskTakingAndInitiative, \.timeManagementAndPlanning],
            startupCost: 8_000,
            payoutRange: 2_000...30_000,
            stages: [.adult]
        ),
        SideHustle(
            id: "realEstateFlip",
            label: "Flip Real Estate",
            icon: "🏠",
            blurb: "Buy, renovate, and resell a property. A heavy stake with the largest upside of any hustle.",
            talents: [\.riskTakingAndInitiative, \.analyticalReasoningAndProblemSolving, \.persuasionAndNegotiation],
            startupCost: 40_000,
            payoutRange: 0...130_000,
            stages: [.adult]
        ),
    ]

    /// Lookup by stable id, used when resolving the year's selected hustles.
    static let byId: [String: SideHustle] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
