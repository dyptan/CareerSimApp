import Foundation

/// A spare-time venture the player commits a year to — the unified home for what
/// used to be two separate features (money-making *side hustles* and fame-earning
/// *projects*). Every venture is a talent-fit gamble that stakes no money: the
/// odds scale with how well the player's soft skills fit the work, and a flop
/// simply yields nothing.
///
/// A venture pays off one of two ways (`Payoff`): a **money** venture banks cash
/// in full (untaxed, unlike salary), while a **fame** venture banks an
/// industry-scoped reputation award (see `Player.fameAwards` / `fameHireBonus`)
/// and grows the soft skills it drew on — the reward a passive hobby can't give.
/// Most ventures now chase fame; a handful of business plays still pay cash.
/// Most also gate behind a `prerequisite` — a minimum level in a relevant soft
/// skill, so you build the skill (via hobbies) before you can take the project on.
struct SideHustle: Identifiable, Hashable {
    /// What a successful year yields. Neither stakes money up front.
    enum Payoff: Hashable {
        /// A successful year pays out within `payoutRange`, banked in full; a
        /// flop earns nothing.
        case money(payoutRange: ClosedRange<Int>)
        /// A successful year banks a fame award in `industry`, worth `weight`
        /// reputation points (see `Player.award`); a flop earns nothing.
        case fame(industry: JobCategory, weight: Double)
    }

    let id: String
    let label: String
    let icon: String
    let blurb: String
    /// The soft-skill axes this venture draws on. The player's levels in these
    /// talents drive the success odds and — for money ventures — the payout.
    let talents: [WritableKeyPath<SoftSkills, Int>]
    /// Whether this venture pays cash or builds fame.
    let payoff: Payoff
    /// Life stages in which the venture is offered (mirrors `Activity.stages`).
    let stages: Set<LifeStage>
    /// Soft-skill gains applied on a *successful* year (each capped at 10 in
    /// `advanceYear`). Fame ventures grow the player the way a shipped project
    /// does — the craft axes drawn on plus a founder-cluster bump — while money
    /// ventures usually leave this empty.
    var growth: [WeightedAbility] = []
    /// Title of the fame award banked on a successful fame year. Defaults to
    /// `label` when nil; ignored by money ventures.
    var fameTitle: String? = nil
    /// A soft-skill prerequisite that gates the venture: the player must reach
    /// `minLevel` in `keyPath` before it can be taken on. Most ventures set one —
    /// you build the relevant skill (through hobbies and activities) before you
    /// can credibly chase the project. `nil` for open, entry-level ventures.
    var prerequisite: SkillRequirement? = nil

    /// A minimum-level requirement on one soft-skill axis (see `prerequisite`).
    struct SkillRequirement: Hashable {
        let keyPath: WritableKeyPath<SoftSkills, Int>
        let minLevel: Int
    }

    static func == (lhs: SideHustle, rhs: SideHustle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Whether the player clears this venture's soft-skill prerequisite (always
    /// true when it has none).
    func meetsPrerequisite(for soft: SoftSkills) -> Bool {
        guard let req = prerequisite else { return true }
        return soft[keyPath: req.keyPath] >= req.minLevel
    }

    /// The industry a fame venture builds reputation in (`nil` for money ventures).
    var fameIndustry: JobCategory? {
        if case .fame(let industry, _) = payoff { return industry }
        return nil
    }

    /// Whether a successful year of this venture banks fame.
    var buildsFame: Bool {
        if case .fame = payoff { return true }
        return false
    }

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
    /// building the right skills first. Fame ventures snowball with reputation —
    /// every banked award lifts the odds by +0.03 per weighted fame point, capped
    /// at +0.15. `fameScore` is the weighted sum of the player's awards.
    func successProbability(for soft: SoftSkills, fameScore: Double = 0) -> Double {
        let base = 0.05 + talentFit(for: soft) * 0.7
        let fameLift = buildsFame ? min(fameScore * 0.03, 0.15) : 0.0
        return max(0.05, min(0.9, base + fameLift))
    }

    /// The payout a successful year would yield at the player's current talent
    /// fit, without the random jitter — used to preview the upside in the UI.
    /// Zero for fame ventures, which pay no money.
    func projectedPayout(for soft: SoftSkills) -> Int {
        guard case .money(let payoutRange) = payoff else { return 0 }
        let lo = Double(payoutRange.lowerBound)
        let hi = Double(payoutRange.upperBound)
        return Int((lo + (hi - lo) * talentFit(for: soft)).rounded())
    }

    /// Rolls a single year of this venture. A money venture returns the takings
    /// (banked in full) on success or nothing on a flop; a fame venture returns a
    /// `FameGrant` on success. No money is staked, so there is nothing to salvage.
    /// `fameScore` lets a fame venture's odds rise with the player's reputation.
    func resolve(for soft: SoftSkills, fameScore: Double = 0) -> Outcome {
        let succeeded = Double.random(in: 0...1) < successProbability(for: soft, fameScore: fameScore)
        guard succeeded else {
            return Outcome(hustle: self, success: false, credit: 0, grantedFame: nil)
        }
        switch payoff {
        case .money(let payoutRange):
            let base = Double(projectedPayout(for: soft))
            let jitter = Double.random(in: 0.75...1.25)
            let payout = max(payoutRange.lowerBound, Int((base * jitter).rounded()))
            return Outcome(hustle: self, success: true, credit: payout, grantedFame: nil)
        case .fame(let industry, let weight):
            let grant = FameGrant(title: fameTitle ?? label, industry: industry, weight: weight)
            return Outcome(hustle: self, success: true, credit: 0, grantedFame: grant)
        }
    }

    /// The fame award banked by a successful fame venture.
    struct FameGrant {
        let title: String
        let industry: JobCategory
        let weight: Double
    }

    /// Result of resolving one year of a venture.
    struct Outcome {
        let hustle: SideHustle
        let success: Bool
        /// Money returned this year: the full payout on a money-venture success,
        /// else 0.
        let credit: Int
        /// The fame award banked this year, if a fame venture succeeded.
        let grantedFame: FameGrant?
    }
}

/// Master catalogue of spare-time ventures, filtered by life stage in the UI the
/// same way `activities` is. Joins the money-making ventures with the (now much
/// larger) set of fame-earning ventures — the former standalone "projects" — into
/// one list. All resolve identically under the hood as talent-fit gambles.
enum SideHustleCatalog {
    /// Business plays that still pay cash — no money down, success pays out. Most
    /// open once the player is a young adult; higher-upside ventures (real estate,
    /// a brick-and-mortar shop) are adult-only.
    static let moneyVentures: [SideHustle] = [
        SideHustle(
            id: "moocCourse",
            label: "Create a MOOC Course",
            icon: "🎓",
            blurb: "Record an online course once and sell seats for years. A big effort up front, but the best courses earn while you sleep.",
            talents: [\.analyticalReasoningAndProblemSolving, \.presentationAndStorytelling, \.communicationAndNetworking],
            payoff: .money(payoutRange: 0...25_000),
            stages: [.youngAdult, .adult],
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 4)
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
            stages: [.youngAdult, .adult],
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 5)
        ),
        SideHustle(
            id: "fitnessCoaching",
            label: "Fitness Coaching",
            icon: "🏋️",
            blurb: "Train clients on evenings and weekends, turning your own discipline into income.",
            talents: [\.resilienceAndEndurance, \.communicationAndNetworking, \.empathyAndInterpersonalCare],
            payoff: .money(payoutRange: 1_000...20_000),
            stages: [.youngAdult, .adult],
            prerequisite: .init(keyPath: \.resilienceAndEndurance, minLevel: 4)
        ),
        SideHustle(
            id: "smallBusiness",
            label: "Start a Small Business",
            icon: "🏪",
            blurb: "Open a local shop or service. Real overhead and real risk, but a steady earner when it clicks.",
            talents: [\.persuasionAndNegotiation, \.riskTakingAndInitiative, \.timeManagementAndPlanning],
            payoff: .money(payoutRange: 2_000...30_000),
            stages: [.adult],
            prerequisite: .init(keyPath: \.persuasionAndNegotiation, minLevel: 4)
        ),
        SideHustle(
            id: "realEstateFlip",
            label: "Flip Real Estate",
            icon: "🏠",
            blurb: "Buy, renovate, and resell a property. The longest odds of any money venture — but the largest cash upside when it lands.",
            talents: [\.riskTakingAndInitiative, \.analyticalReasoningAndProblemSolving, \.persuasionAndNegotiation],
            payoff: .money(payoutRange: 0...130_000),
            stages: [.adult],
            prerequisite: .init(keyPath: \.riskTakingAndInitiative, minLevel: 5)
        ),
    ]

    /// Fame-earning ventures: a successful year banks an industry-scoped
    /// reputation award and grows the soft skills it drew on. This set folds in
    /// the creative side hustles (influencer, book, album, TV, performer) and the
    /// former standalone projects (app, open source, article, talk, festival,
    /// coauthored book/paper, 3D game).
    static let fameVentures: [SideHustle] = [
        // --- Creative personal-brand ventures (were money+fame side hustles) ---
        SideHustle(
            id: "influencer",
            label: "Influencer / Content Creator",
            icon: "📱",
            blurb: "Build an audience and chase the spotlight. Most channels fizzle — a viral one makes your name.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            payoff: .fame(industry: .showBusiness, weight: 1.0),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1)],
            fameTitle: "Viral Creator"
        ),
        SideHustle(
            id: "selfPublishBook",
            label: "Write & Self-Publish a Book",
            icon: "📚",
            blurb: "Spend the year writing and publishing. Most titles sink; a hit puts your name on shelves everywhere.",
            talents: [\.presentationAndStorytelling, \.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking],
            payoff: .fame(industry: .showBusiness, weight: 1.5),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Published Author",
            prerequisite: .init(keyPath: \.presentationAndStorytelling, minLevel: 4)
        ),
        SideHustle(
            id: "freelancePerformer",
            label: "Freelance Artist & Performer",
            icon: "🎭",
            blurb: "Go independent in show business — gig as a musician, dancer, or actor and take commissions. Feast or famine, but every show gets you seen.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            payoff: .fame(industry: .showBusiness, weight: 1.0),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1)],
            fameTitle: "Rising Performer",
            prerequisite: .init(keyPath: \.creativityAndInsightfulThinking, minLevel: 4)
        ),
        SideHustle(
            id: "releaseAlbum",
            label: "Record & Release an Album",
            icon: "🎵",
            blurb: "Book studio time and put your music out there. Long odds, but a breakout single makes you a name.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            payoff: .fame(industry: .showBusiness, weight: 2.0),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Recording Artist",
            prerequisite: .init(keyPath: \.creativityAndInsightfulThinking, minLevel: 5)
        ),
        SideHustle(
            id: "tvShow",
            label: "Cast on a TV Show",
            icon: "📺",
            blurb: "Audition for a spot on screen. The longest shot of them all — and the brightest spotlight.",
            talents: [\.presentationAndStorytelling, \.communicationAndNetworking, \.stressResistanceAndEmotionalRegulation],
            payoff: .fame(industry: .showBusiness, weight: 2.0),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)],
            fameTitle: "TV Personality",
            prerequisite: .init(keyPath: \.presentationAndStorytelling, minLevel: 5)
        ),
        // --- Former standalone projects (unlocked to everyone, stage-gated) ---
        SideHustle(
            id: "projectApp",
            label: "Ship a Mobile App",
            icon: "📱",
            blurb: "A little app you build in your spare time. Ship something people actually use and word gets around.",
            talents: [\.analyticalReasoningAndProblemSolving, \.creativityAndInsightfulThinking, \.timeManagementAndPlanning],
            payoff: .fame(industry: .technology, weight: 1.0),
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "App Maker",
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 4)
        ),
        SideHustle(
            id: "projectLibrary",
            label: "Contribute to Open Source",
            icon: "📦",
            blurb: "An open-source project you contribute to in the open. Land your work in something people depend on and your name travels with it.",
            talents: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance],
            payoff: .fame(industry: .technology, weight: 1.0),
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                     .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                     .init(keyPath: \.leadershipAndInfluence, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Open-Source Contributor",
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 5)
        ),
        SideHustle(
            id: "projectArticle",
            label: "Write a Long-Form Article",
            icon: "📝",
            blurb: "A deep-dive you write out of pure curiosity. A piece that gets read and shared builds a quiet kind of renown.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.carefulnessAndAttentionToDetail],
            payoff: .fame(industry: .showBusiness, weight: 1.0),
            stages: [.child, .teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.persuasionAndNegotiation, weight: 1)],
            fameTitle: "Bylined Writer",
            prerequisite: .init(keyPath: \.communicationAndNetworking, minLevel: 3)
        ),
        SideHustle(
            id: "projectPresentation",
            label: "Give a Talk",
            icon: "🖥️",
            blurb: "A talk you put together for a meetup or conference. Landing an idea in front of a room is how people start to know your name.",
            talents: [\.presentationAndStorytelling, \.communicationAndNetworking, \.creativityAndInsightfulThinking],
            payoff: .fame(industry: .business, weight: 1.0),
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.persuasionAndNegotiation, weight: 2)],
            fameTitle: "Noted Speaker",
            prerequisite: .init(keyPath: \.presentationAndStorytelling, minLevel: 4)
        ),
        SideHustle(
            id: "projectMusicFestival",
            label: "Play a Music Festival",
            icon: "🎪",
            blurb: "You take the stage at a festival. A good set in front of a crowd is the fastest way to get talked about.",
            talents: [\.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking, \.presentationAndStorytelling],
            payoff: .fame(industry: .showBusiness, weight: 1.0),
            stages: [.child, .teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Festival Performer",
            prerequisite: .init(keyPath: \.creativityAndInsightfulThinking, minLevel: 3)
        ),
        SideHustle(
            id: "projectPublishBook",
            label: "Coauthor a Book or Paper",
            icon: "📖",
            blurb: "You coauthor a book or a paper and see it published. A title with your name on the spine carries lasting fame.",
            talents: [\.communicationAndNetworking, \.carefulnessAndAttentionToDetail, \.timeManagementAndPlanning],
            payoff: .fame(industry: .science, weight: 1.0),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.leadershipAndInfluence, weight: 1)],
            fameTitle: "Book Coauthor",
            prerequisite: .init(keyPath: \.carefulnessAndAttentionToDetail, minLevel: 5)
        ),
        SideHustle(
            id: "projectGame3d",
            label: "Ship a 3D Game",
            icon: "🎮",
            blurb: "A 3D game you model, build, and ship in your spare time — worlds and mechanics all your own. A standout indie title gets you noticed.",
            talents: [\.creativityAndInsightfulThinking, \.spacialNavigationAndOrientation, \.analyticalReasoningAndProblemSolving],
            payoff: .fame(industry: .gaming, weight: 1.0),
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Indie Game Dev",
            prerequisite: .init(keyPath: \.spacialNavigationAndOrientation, minLevel: 4)
        ),
    ]

    /// Every spare-time venture on offer: money plays first, then the fame set.
    static let all: [SideHustle] = moneyVentures + fameVentures

    /// Lookup by stable id, used when resolving the year's selected ventures.
    static let byId: [String: SideHustle] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
