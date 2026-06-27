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
    /// What a successful venture yields. Money ventures stake capital up front and
    /// pay cash; portfolio projects stake no money at all — "they risk not money,
    /// only the year's attempt" — and instead grant a portfolio piece on success.
    enum Payoff: Hashable {
        /// Stake `startupCost` up front (lost on a flop except a half-stake
        /// salvage); a successful year pays out within `payoutRange`, banked in
        /// full.
        case money(startupCost: Int, payoutRange: ClosedRange<Int>)
        /// No money at stake or paid out; a successful year grants this portfolio
        /// piece (a hiring signal at portfolio-tier employers), a flop yields
        /// nothing.
        case portfolio(Project)
    }

    let id: String
    let label: String
    let icon: String
    let blurb: String
    /// The soft-skill axes this venture draws on. The player's levels in these
    /// talents drive both the success odds and — for money ventures — the payout.
    let talents: [WritableKeyPath<SoftSkills, Int>]
    /// Whether this venture stakes/pays money or instead builds the portfolio.
    let payoff: Payoff
    /// Life stages in which the venture is offered (mirrors `Activity.stages`).
    let stages: Set<LifeStage>
    /// A titled fame trophy this venture grants on a successful year (nil if it
    /// doesn't build fame). Show-business ventures — going viral, publishing,
    /// performing, recording, landing a TV spot — bank reputation that opens
    /// doors across Show Business careers, the same currency a competition win
    /// earns (see `Player.achievements` / `achievementHireBonus`).
    var fameAward: String? = nil

    static func == (lhs: SideHustle, rhs: SideHustle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Capital staked up front this year (0 for portfolio projects).
    var startupCost: Int {
        if case .money(let cost, _) = payoff { return cost }
        return 0
    }

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
    /// Zero for portfolio projects, which pay no money.
    func projectedPayout(for soft: SoftSkills) -> Int {
        guard case .money(_, let payoutRange) = payoff else { return 0 }
        let lo = Double(payoutRange.lowerBound)
        let hi = Double(payoutRange.upperBound)
        return Int((lo + (hi - lo) * talentFit(for: soft)).rounded())
    }

    /// Rolls a single year of this venture. Money ventures return the takings
    /// (banked in full) on success or a half-stake salvage on a flop; the caller
    /// charges `startupCost` separately. Portfolio projects return the granted
    /// piece on success and nothing on a flop.
    func resolve(for soft: SoftSkills) -> Outcome {
        let succeeded = Double.random(in: 0...1) < successProbability(for: soft)
        // Fame is banked only on a successful year, whatever the payoff kind.
        let fame = succeeded ? fameAward : nil
        switch payoff {
        case .money(let startupCost, let payoutRange):
            guard succeeded else {
                return Outcome(hustle: self, success: false, credit: startupCost / 2,
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
        /// Money returned to the player this year (full payout on success, or a
        /// half-stake salvage on a flop). Does not subtract the stake — the
        /// caller charges that separately. Always 0 for portfolio projects.
        let credit: Int
        /// The portfolio piece earned this year, if a project succeeded.
        let grantedPortfolio: Project?
        /// The fame trophy banked this year, if a fame-building venture succeeded.
        let grantedFame: String?
    }
}

/// Master catalogue of private projects, filtered by life stage in the UI the
/// same way `activities` is. It joins money-making ventures (which stake and pay
/// cash) with portfolio projects (which risk no money and grant a portfolio piece
/// on success) — both resolve identically under the hood.
enum SideHustleCatalog {
    /// Money-making ventures: stake capital up front, success pays cash. Tutoring
    /// is open to teens; capital-heavy ventures (real estate, a brick-and-mortar
    /// shop) are adult-only.
    static let moneyVentures: [SideHustle] = [
        SideHustle(
            id: "tutoring",
            label: "Tutoring",
            icon: "📐",
            blurb: "Coach younger students after school. No money down — just your know-how and patience.",
            talents: [\.communicationAndNetworking, \.analyticalReasoningAndProblemSolving, \.empathyAndInterpersonalCare],
            payoff: .money(startupCost: 0, payoutRange: 500...8_000),
            stages: [.teen, .youngAdult, .adult]
        ),
        SideHustle(
            id: "etsyCrafts",
            label: "Sell Art & Crafts Online",
            icon: "🧵",
            blurb: "Turn a making hobby into an online storefront of handmade goods.",
            talents: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision, \.carefulnessAndAttentionToDetail],
            payoff: .money(startupCost: 1_500, payoutRange: 500...16_000),
            stages: [.teen, .youngAdult, .adult]
        ),
        SideHustle(
            id: "influencer",
            label: "Influencer / Content Creator",
            icon: "📱",
            blurb: "Build an audience and chase brand deals. Most channels fizzle — a viral one prints money.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            payoff: .money(startupCost: 1_000, payoutRange: 0...45_000),
            stages: [.teen, .youngAdult, .adult],
            fameAward: "Viral Creator"
        ),
        SideHustle(
            id: "freelanceConsulting",
            label: "Freelance Consulting",
            icon: "💻",
            blurb: "Take on paid projects on the side, solving problems for clients after hours.",
            talents: [\.analyticalReasoningAndProblemSolving, \.communicationAndNetworking, \.timeManagementAndPlanning],
            payoff: .money(startupCost: 500, payoutRange: 1_000...30_000),
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "fitnessCoaching",
            label: "Fitness Coaching",
            icon: "🏋️",
            blurb: "Train clients on evenings and weekends, turning your own discipline into income.",
            talents: [\.resilienceAndEndurance, \.communicationAndNetworking, \.empathyAndInterpersonalCare],
            payoff: .money(startupCost: 800, payoutRange: 1_000...20_000),
            stages: [.youngAdult, .adult]
        ),
        SideHustle(
            id: "selfPublishBook",
            label: "Write & Self-Publish a Book",
            icon: "📚",
            blurb: "Spend the year writing and publishing. Most titles sell little; a hit earns for years.",
            talents: [\.presentationAndStorytelling, \.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking],
            payoff: .money(startupCost: 1_000, payoutRange: 0...28_000),
            stages: [.youngAdult, .adult],
            fameAward: "Published Author"
        ),
        SideHustle(
            id: "freelancePerformer",
            label: "Freelance Artist & Performer",
            icon: "🎭",
            blurb: "Go independent in show business — sell your art, gig as a musician, dancer, or actor, and take commissions. The self-employed creative path: feast or famine.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            payoff: .money(startupCost: 800, payoutRange: 0...40_000),
            stages: [.teen, .youngAdult, .adult],
            fameAward: "Rising Performer"
        ),
        SideHustle(
            id: "releaseAlbum",
            label: "Record & Release an Album",
            icon: "🎵",
            blurb: "Book studio time and put your music out there. Long odds, but a breakout single pays big.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            payoff: .money(startupCost: 6_000, payoutRange: 0...55_000),
            stages: [.youngAdult, .adult],
            fameAward: "Recording Artist"
        ),
        SideHustle(
            id: "tvShow",
            label: "Cast on a TV Show",
            icon: "📺",
            blurb: "Audition for a spot on screen. The longest shot of them all — and the biggest paycheck.",
            talents: [\.presentationAndStorytelling, \.communicationAndNetworking, \.stressResistanceAndEmotionalRegulation],
            payoff: .money(startupCost: 500, payoutRange: 0...70_000),
            stages: [.youngAdult, .adult],
            fameAward: "TV Personality"
        ),
        SideHustle(
            id: "smallBusiness",
            label: "Start a Small Business",
            icon: "🏪",
            blurb: "Open a local shop or service. Real overhead and real risk, but a steady earner when it clicks.",
            talents: [\.persuasionAndNegotiation, \.riskTakingAndInitiative, \.timeManagementAndPlanning],
            payoff: .money(startupCost: 8_000, payoutRange: 2_000...30_000),
            stages: [.adult]
        ),
        SideHustle(
            id: "realEstateFlip",
            label: "Flip Real Estate",
            icon: "🏠",
            blurb: "Buy, renovate, and resell a property. A heavy stake with the largest upside of any venture.",
            talents: [\.riskTakingAndInitiative, \.analyticalReasoningAndProblemSolving, \.persuasionAndNegotiation],
            payoff: .money(startupCost: 40_000, payoutRange: 0...130_000),
            stages: [.adult]
        ),
    ]

    /// Portfolio projects, generated from `Project`. No money is staked or paid —
    /// they "risk not money", only the year's attempt — and a successful one grants
    /// the matching portfolio piece, a hiring signal at portfolio-tier employers.
    static let portfolioProjects: [SideHustle] = Project.allCases.map { project in
        SideHustle(
            id: "project-\(project.rawValue)",
            label: project.rawValue,
            icon: project.pictogram,
            blurb: project.description,
            talents: project.talents,
            payoff: .portfolio(project),
            stages: project.stages
        )
    }

    /// Every private project on offer: money ventures first, portfolio projects
    /// after, shown as a single list.
    static let all: [SideHustle] = moneyVentures + portfolioProjects

    /// Lookup by stable id, used when resolving the year's selected projects.
    static let byId: [String: SideHustle] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
