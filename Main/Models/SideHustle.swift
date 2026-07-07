import Foundation

/// A spare-time venture that tries to *monetize the player's talents* — the soft
/// skills built up through hobbies and activities. Unlike a salaried job (whose
/// pay is taxed and mostly eaten by living costs before the savings rate takes
/// its slice), a side hustle's takings are banked in full, so a strong hobby can
/// meaningfully accelerate the road to the first million.
///
/// Each attempt is a gamble, but no money is staked up front: the odds and the
/// payout both scale with how well the player's talents fit the venture, and a
/// flop simply earns nothing. Examples range from babysitting to a shot at
/// influencer fame, releasing an album, or landing a TV-show casting.
struct SideHustle: Identifiable, Hashable {
    /// What a successful venture yields. Money ventures pay cash; portfolio
    /// projects grant a portfolio piece on success. Neither stakes money up
    /// front — they risk only the year's attempt.
    enum Payoff: Hashable {
        /// A successful year pays out within `payoutRange`, banked in full; a
        /// flop earns nothing.
        case money(payoutRange: ClosedRange<Int>)
        /// A successful year grants this portfolio piece (a hiring signal at
        /// portfolio-tier employers); a flop yields nothing.
        case portfolio(Project)
    }

    let id: String
    let label: String
    let icon: String
    let blurb: String
    /// The soft-skill axes this venture draws on. The player's levels in these
    /// talents drive both the success odds and — for money ventures — the payout.
    let talents: [WritableKeyPath<SoftSkills, Int>]
    /// Whether this venture pays money or instead builds the portfolio.
    let payoff: Payoff
    /// Life stages in which the venture is offered (mirrors `Activity.stages`).
    let stages: Set<LifeStage>
    /// A titled fame trophy this venture grants on a successful year (nil if it
    /// doesn't build fame). Show-business ventures — going viral, publishing,
    /// performing, recording, landing a TV spot — bank reputation that opens
    /// doors across Show Business careers, the same currency a competition win
    /// earns (see `Player.fameAwards` / `fameHireBonus(for:)`).
    var fameAward: String? = nil
    /// Reputation weight this trophy carries when totalled into the player's
    /// fame score (see `Player.fameScore`). Only meaningful for fame-building
    /// ventures; marquee outcomes (album, TV) are tuned higher than a single
    /// viral upload.
    var fameWeight: Double = 1.0

    static func == (lhs: SideHustle, rhs: SideHustle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// The portfolio piece this venture grants on success, if it is a project.
    var portfolioReward: Project? {
        if case .portfolio(let project) = payoff { return project }
        return nil
    }

    /// Whether this venture builds the portfolio rather than making money.
    var isPortfolioProject: Bool { portfolioReward != nil }

    /// Whether a successful year of this venture banks fame (a Show Business
    /// reputation boost).
    var buildsFame: Bool { fameAward != nil }

    /// Talent level at which a single axis is considered a perfect fit (caps the
    /// per-axis contribution at 1.0). Set high so a venture only pays off
    /// reliably once the player has genuinely mastered its talents — reachable
    /// late-game by a dedicated hobbyist, not a casual dabbler.
    static let talentReference = 8

    /// 0...1 measure of how well the player's talents suit this venture: the mean
    /// of each required axis, normalized against `talentReference` and capped.
    func talentFit(for soft: SoftSkills) -> Double {
        guard !talents.isEmpty else { return 0 }
        let total = talents.reduce(0.0) { acc, kp in
            acc + min(Double(soft[keyPath: kp]) / Double(SideHustle.talentReference), 1.0)
        }
        return total / Double(talents.count)
    }

    /// Probability (0.05...0.9) that the venture pays off in a given year. The
    /// floor is deliberately low — a poorly-suited attempt almost always flops —
    /// and the odds climb steeply with talent fit, so success is earned by
    /// building the right skills first. Fame-building social-media ventures
    /// (influencer, album, performer, TV, self-published book) snowball with
    /// reputation — every banked achievement (a competition win or earlier fame
    /// hustle) lifts the odds by +0.03 per weighted point of fame, capped at
    /// +0.15 so the climb still feels earned. `fameScore` is the weighted sum of
    /// the player's trophies (see `Player.fameScore`).
    func successProbability(for soft: SoftSkills, fameScore: Double = 0) -> Double {
        let base = 0.05 + talentFit(for: soft) * 0.7
        let fameLift = buildsFame ? min(fameScore * 0.03, 0.15) : 0.0
        return max(0.05, min(0.9, base + fameLift))
    }

    /// The payout a successful year would yield at the player's current talent
    /// fit, without the random jitter — used to preview the upside in the UI.
    /// Zero for portfolio projects, which pay no money.
    func projectedPayout(for soft: SoftSkills) -> Int {
        guard case .money(let payoutRange) = payoff else { return 0 }
        let lo = Double(payoutRange.lowerBound)
        let hi = Double(payoutRange.upperBound)
        return Int((lo + (hi - lo) * talentFit(for: soft)).rounded())
    }

    /// Rolls a single year of this venture. Money ventures return the takings
    /// (banked in full) on success or nothing on a flop — no money is staked, so
    /// there is nothing to salvage. Portfolio projects return the granted piece
    /// on success and nothing on a flop. `fameScore` lets a fame-building
    /// venture's odds rise with the player's reputation (see `successProbability`).
    func resolve(for soft: SoftSkills, fameScore: Double = 0) -> Outcome {
        let succeeded = Double.random(in: 0...1) < successProbability(for: soft, fameScore: fameScore)
        // Fame is banked only on a successful year, whatever the payoff kind.
        let fame = succeeded ? fameAward : nil
        switch payoff {
        case .money(let payoutRange):
            guard succeeded else {
                return Outcome(hustle: self, success: false, credit: 0,
                               grantedPortfolio: nil, grantedFame: nil)
            }
            let base = Double(projectedPayout(for: soft))
            let jitter = Double.random(in: 0.75...1.25)
            let payout = max(payoutRange.lowerBound, Int((base * jitter).rounded()))
            return Outcome(hustle: self, success: true, credit: payout,
                           grantedPortfolio: nil, grantedFame: fame)
        case .portfolio(let project):
            return Outcome(hustle: self, success: succeeded, credit: 0,
                           grantedPortfolio: succeeded ? project : nil, grantedFame: fame)
        }
    }

    /// Result of resolving one year of a venture.
    struct Outcome {
        let hustle: SideHustle
        let success: Bool
        /// Money returned to the player this year: the full payout on success, or
        /// 0 on a flop. Always 0 for portfolio projects.
        let credit: Int
        /// The portfolio piece earned this year, if a project succeeded.
        let grantedPortfolio: Project?
        /// The fame trophy banked this year, if a fame-building venture succeeded.
        let grantedFame: String?
    }
}

/// Master catalogue of private projects, filtered by life stage in the UI the
/// same way `activities` is. It joins money-making ventures (which pay cash) with
/// portfolio projects (which grant a portfolio piece on success) — neither stakes
/// money, and both resolve identically under the hood.
enum SideHustleCatalog {
    /// Money-making ventures: no money down, success pays cash. Most open once
    /// the player is a young adult; higher-upside ventures (real estate, a
    /// brick-and-mortar shop) are adult-only.
    static let moneyVentures: [SideHustle] = [
        SideHustle(
            id: "moocCourse",
            label: "Create a MOOC Course",
            icon: "🎓",
            blurb: "Record an online course once and sell seats for years. A big effort up front, but the best courses earn while you sleep.",
            talents: [\.analyticalReasoningAndProblemSolving, \.presentationAndStorytelling, \.communicationAndNetworking],
            payoff: .money(payoutRange: 0...25_000),
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "etsyCrafts",
            label: "Sell Art & Crafts Online",
            icon: "🧵",
            blurb: "Turn a making hobby into an online storefront of handmade goods.",
            talents: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision, \.carefulnessAndAttentionToDetail],
            payoff: .money(payoutRange: 500...16_000),
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "influencer",
            label: "Influencer / Content Creator",
            icon: "📱",
            blurb: "Build an audience and chase brand deals. Most channels fizzle — a viral one prints money.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            payoff: .money(payoutRange: 0...45_000),
            stages: [.youngAdult, .adult],
            fameAward: "Viral Creator",
            fameWeight: 1.0
        ),
        SideHustle(
            id: "bloggingPodcasting",
            label: "Blogging & Podcasting",
            icon: "🎙️",
            blurb: "Publish a blog and a podcast on the side. Slow to build an audience, but ads and sponsors trickle in once it catches on.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            payoff: .money(payoutRange: 0...20_000),
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "freelanceConsulting",
            label: "Freelance Consulting",
            icon: "💻",
            blurb: "Take on paid projects on the side, solving problems for clients after hours.",
            talents: [\.analyticalReasoningAndProblemSolving, \.communicationAndNetworking, \.timeManagementAndPlanning],
            payoff: .money(payoutRange: 1_000...30_000),
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "fitnessCoaching",
            label: "Fitness Coaching",
            icon: "🏋️",
            blurb: "Train clients on evenings and weekends, turning your own discipline into income.",
            talents: [\.resilienceAndEndurance, \.communicationAndNetworking, \.empathyAndInterpersonalCare],
            payoff: .money(payoutRange: 1_000...20_000),
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "selfPublishBook",
            label: "Write & Self-Publish a Book",
            icon: "📚",
            blurb: "Spend the year writing and publishing. Most titles sell little; a hit earns for years.",
            talents: [\.presentationAndStorytelling, \.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking],
            payoff: .money(payoutRange: 0...28_000),
            stages: [.youngAdult, .adult],
            fameAward: "Published Author",
            fameWeight: 1.5
        ),
        SideHustle(
            id: "freelancePerformer",
            label: "Freelance Artist & Performer",
            icon: "🎭",
            blurb: "Go independent in show business — sell your art, gig as a musician, dancer, or actor, and take commissions. The self-employed creative path: feast or famine.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            payoff: .money(payoutRange: 0...40_000),
            stages: [.youngAdult, .adult],
            fameAward: "Rising Performer",
            fameWeight: 1.0
        ),
        SideHustle(
            id: "releaseAlbum",
            label: "Record & Release an Album",
            icon: "🎵",
            blurb: "Book studio time and put your music out there. Long odds, but a breakout single pays big.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            payoff: .money(payoutRange: 0...55_000),
            stages: [.youngAdult, .adult],
            fameAward: "Recording Artist",
            fameWeight: 2.0
        ),
        SideHustle(
            id: "tvShow",
            label: "Cast on a TV Show",
            icon: "📺",
            blurb: "Audition for a spot on screen. The longest shot of them all — and the biggest paycheck.",
            talents: [\.presentationAndStorytelling, \.communicationAndNetworking, \.stressResistanceAndEmotionalRegulation],
            payoff: .money(payoutRange: 0...70_000),
            stages: [.youngAdult, .adult],
            fameAward: "TV Personality",
            fameWeight: 2.0
        ),
        SideHustle(
            id: "smallBusiness",
            label: "Start a Small Business",
            icon: "🏪",
            blurb: "Open a local shop or service. Real overhead and real risk, but a steady earner when it clicks.",
            talents: [\.persuasionAndNegotiation, \.riskTakingAndInitiative, \.timeManagementAndPlanning],
            payoff: .money(payoutRange: 2_000...30_000),
            stages: [.adult]
        ),
        SideHustle(
            id: "realEstateFlip",
            label: "Flip Real Estate",
            icon: "🏠",
            blurb: "Buy, renovate, and resell a property. The longest odds of any venture — but the largest upside when it lands.",
            talents: [\.riskTakingAndInitiative, \.analyticalReasoningAndProblemSolving, \.persuasionAndNegotiation],
            payoff: .money(payoutRange: 0...130_000),
            stages: [.adult]
        ),
    ]

    /// Every side hustle on offer. Portfolio projects used to live here too, but
    /// they are now a standalone, hobby-style feature (see `Project` /
    /// `ProjectsView`): gated by soft-skill requirements, they probabilistically
    /// grant a portfolio piece and fame rather than money. This catalogue is
    /// therefore the money-making ventures only.
    static let all: [SideHustle] = moneyVentures

    /// Lookup by stable id, used when resolving the year's selected hustles.
    static let byId: [String: SideHustle] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
