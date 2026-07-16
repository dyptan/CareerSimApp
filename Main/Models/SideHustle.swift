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
    /// A hard capital gate: the minimum savings the player must have on hand to
    /// take the venture on. Set for ventures that need real money up front — a
    /// shop's fit-out, a property's down payment — so you can't credibly start
    /// them broke. `nil` for ventures that need no capital.
    var minCapital: Int? = nil
    /// The industry a committed year of this venture credits as *work
    /// experience*. Set on the entrepreneurship ventures (`.entrepreneurship`),
    /// so years spent building a startup, pitching, or crowdfunding accumulate
    /// like a job would — and, because Business credits entrepreneurship
    /// (`JobCategory.creditedExperienceCategories`), count toward Business roles.
    /// The player's existing experience in this field also lifts the venture's
    /// success odds (see `experienceLift`). `nil` for ventures that build no
    /// formal work experience (most fame plays).
    var experienceCategory: JobCategory? = nil
    /// Whether this play has prospects of becoming a business — a real income
    /// stream or company. Set on every venture that can turn profitable: the
    /// cash-paying money ventures (a course, an online store, a shop, a
    /// property flip) and the buildable products that could grow into one (a
    /// mobile app, a shipped game). Combined with the entrepreneurship plays
    /// (`experienceCategory == .entrepreneurship`), these fill the **Ventures**
    /// sheet, while pure fame/creative projects stay in **Projects**.
    var hasBusinessProspects: Bool = false

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

    /// Whether the player has the capital this venture requires on hand (always
    /// true when it needs none).
    func meetsCapital(savings: Int) -> Bool {
        guard let minCapital else { return true }
        return savings >= minCapital
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

    /// Per-year lift to a venture's success odds from relevant work experience,
    /// and the cap that lift tops out at. Only ventures with an
    /// `experienceCategory` benefit — a seasoned operator runs a smarter play.
    static let experienceLiftPerYear = 0.03
    static let maxExperienceLift = 0.15

    /// Additive success-odds lift from the player's relevant work experience.
    /// Zero for ventures that build no experience (`experienceCategory == nil`);
    /// otherwise +`experienceLiftPerYear` per credited year, capped. `years` is
    /// the player's `industryExperience` for this venture's `experienceCategory`.
    func experienceLift(years: Int) -> Double {
        guard experienceCategory != nil else { return 0 }
        return min(Double(max(0, years)) * SideHustle.experienceLiftPerYear, SideHustle.maxExperienceLift)
    }

    /// Probability (0.05...0.9) that the venture pays off in a given year. The
    /// floor is deliberately low — a poorly-suited attempt almost always flops —
    /// and the odds climb steeply with talent fit, so success is earned by
    /// building the right skills first. Fame ventures snowball with reputation —
    /// every banked award lifts the odds by +0.03 per weighted fame point, capped
    /// at +0.15. `fameScore` is the weighted sum of the player's awards.
    /// Ventures that build work experience also lift with the player's years in
    /// the field (`experienceYears`, see `experienceLift`) — a startup runs
    /// smarter the more business you've done.
    func successProbability(for soft: SoftSkills, fameScore: Double = 0, experienceYears: Int = 0) -> Double {
        let base = 0.05 + talentFit(for: soft) * 0.7
        let fameLift = buildsFame ? min(fameScore * 0.03, 0.15) : 0.0
        let expLift = experienceLift(years: experienceYears)
        return max(0.05, min(0.9, base + fameLift + expLift))
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
    /// `fameScore` lets a fame venture's odds rise with the player's reputation;
    /// `experienceYears` lets an experience-building venture's odds rise with the
    /// player's years in its field.
    func resolve(for soft: SoftSkills, fameScore: Double = 0, experienceYears: Int = 0) -> Outcome {
        let succeeded = Double.random(in: 0...1) < successProbability(for: soft, fameScore: fameScore, experienceYears: experienceYears)
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
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 5),
            hasBusinessProspects: true
        ),
        SideHustle(
            id: "etsyCrafts",
            label: "Sell Art & Crafts Online",
            icon: "🧵",
            blurb: "Turn a making hobby into an online storefront of handmade goods.",
            talents: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision, \.carefulnessAndAttentionToDetail],
            payoff: .money(payoutRange: 500...16_000),
            stages: [.youngAdult, .adult],
            prerequisite: .init(keyPath: \.tinkeringAndFingerPrecision, minLevel: 4),
            hasBusinessProspects: true
        ),
        SideHustle(
            id: "smallBusiness",
            label: "Start a Small Business",
            icon: "🏪",
            blurb: "Open a local shop or service. Real overhead and real risk, but a steady earner when it clicks.",
            talents: [\.persuasionAndNegotiation, \.riskTakingAndInitiative, \.timeManagementAndPlanning],
            payoff: .money(payoutRange: 2_000...30_000),
            stages: [.adult],
            prerequisite: .init(keyPath: \.timeManagementAndPlanning, minLevel: 5),
            minCapital: 15_000,
            hasBusinessProspects: true
        ),
        SideHustle(
            id: "realEstateFlip",
            label: "Flip Real Estate",
            icon: "🏠",
            blurb: "Buy, renovate, and resell a property. The longest odds of any money venture — but the largest cash upside when it lands.",
            talents: [\.riskTakingAndInitiative, \.analyticalReasoningAndProblemSolving, \.persuasionAndNegotiation],
            payoff: .money(payoutRange: 0...130_000),
            stages: [.adult],
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 6),
            minCapital: 60_000,
            hasBusinessProspects: true
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
            blurb: "Build an audience across social, a blog, and a podcast, and chase the spotlight. Most channels fizzle — a viral one makes your name.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            payoff: .fame(industry: .showBusiness, weight: 1.0),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1)],
            fameTitle: "Viral Creator",
            prerequisite: .init(keyPath: \.communicationAndNetworking, minLevel: 4)
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
            prerequisite: .init(keyPath: \.presentationAndStorytelling, minLevel: 5)
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
            prerequisite: .init(keyPath: \.creativityAndInsightfulThinking, minLevel: 5)
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
            prerequisite: .init(keyPath: \.creativityAndInsightfulThinking, minLevel: 6)
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
            prerequisite: .init(keyPath: \.presentationAndStorytelling, minLevel: 7)
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
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 5),
            hasBusinessProspects: true
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
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 6)
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
            prerequisite: .init(keyPath: \.communicationAndNetworking, minLevel: 4)
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
            prerequisite: .init(keyPath: \.presentationAndStorytelling, minLevel: 5)
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
            prerequisite: .init(keyPath: \.creativityAndInsightfulThinking, minLevel: 4)
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
            prerequisite: .init(keyPath: \.carefulnessAndAttentionToDetail, minLevel: 6)
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
            prerequisite: .init(keyPath: \.spacialNavigationAndOrientation, minLevel: 5),
            hasBusinessProspects: true
        ),
        // --- Entrepreneurship ventures: the path to the founder skillset that
        // hobbies can't teach — leadership, vision, persuasion, and risk appetite.
        // The talents they draw on are all hobby-built (analytical from Coding &
        // Board Games, communication from Journalism & Language Learning,
        // presentation from Diary Writing & Dancing), so each idea is linked to a
        // hobby, a soft skill, and — via `experienceCategory` — real work
        // experience. A committed year credits `.entrepreneurship` work
        // experience (which counts toward Business roles), banks business-industry
        // fame (toward management and C-suite roles), and grows the entrepreneurial
        // cluster the way running a company would. Years already spent in
        // business/entrepreneurship also raise the odds (see `experienceLift`).
        SideHustle(
            id: "startupLaunch",
            label: "Launch a Startup",
            icon: "🚀",
            blurb: "Spin up a company on the side — pitch the idea, ship a product, chase growth. Most fold, but a breakout puts your name in the business press and a year on your entrepreneurial résumé.",
            talents: [\.analyticalReasoningAndProblemSolving, \.communicationAndNetworking, \.timeManagementAndPlanning],
            payoff: .fame(industry: .business, weight: 1.5),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                     .init(keyPath: \.leadershipAndInfluence, weight: 1),
                     .init(keyPath: \.persuasionAndNegotiation, weight: 1)],
            fameTitle: "Startup Founder",
            prerequisite: .init(keyPath: \.analyticalReasoningAndProblemSolving, minLevel: 4),
            experienceCategory: .entrepreneurship
        ),
        SideHustle(
            id: "pitchCompetition",
            label: "Enter a Pitch Competition",
            icon: "🎤",
            blurb: "Take a business idea to investors and a live audience. Win the room and doors — and wallets — start to open, and the reps count as real venture experience.",
            talents: [\.presentationAndStorytelling, \.communicationAndNetworking, \.creativityAndInsightfulThinking],
            payoff: .fame(industry: .business, weight: 1.0),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.persuasionAndNegotiation, weight: 2),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Pitch Winner",
            prerequisite: .init(keyPath: \.presentationAndStorytelling, minLevel: 4),
            experienceCategory: .entrepreneurship
        ),
        SideHustle(
            id: "crowdfundingCampaign",
            label: "Run a Crowdfunding Campaign",
            icon: "💸",
            blurb: "Rally backers behind a product idea and hit your funding goal. A funded campaign proves you can sell a vision, lead a crowd, and run a venture end to end.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            payoff: .fame(industry: .business, weight: 1.0),
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.persuasionAndNegotiation, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                     .init(keyPath: \.leadershipAndInfluence, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1)],
            fameTitle: "Crowdfunded Creator",
            prerequisite: .init(keyPath: \.communicationAndNetworking, minLevel: 4),
            experienceCategory: .entrepreneurship
        ),
    ]

    /// Every spare-time venture on offer: money plays first, then the fame set.
    static let all: [SideHustle] = moneyVentures + fameVentures

    /// Ventures with prospects of becoming a business — everything that can
    /// turn profitable: the cash-paying money ventures (course, online store,
    /// shop, property flip), the buildable products that could grow into a
    /// business (app, game), and the entrepreneurship plays (startup, pitch
    /// competition, crowdfunding) that credit real `.entrepreneurship` work
    /// experience. These live in the **Ventures** sheet alongside the founder
    /// path, not in the spare-time **Projects** sheet.
    static let businessVentures: [SideHustle] =
        all.filter { $0.hasBusinessProspects || $0.experienceCategory == .entrepreneurship }

    /// Spare-time projects shown in the **Projects** sheet: the pure
    /// fame/creative plays with no business prospects (articles, talks,
    /// festivals, open source, and the personal-brand performances).
    static let spareTimeProjects: [SideHustle] =
        all.filter { !($0.hasBusinessProspects || $0.experienceCategory == .entrepreneurship) }

    /// Lookup by stable id, used when resolving the year's selected ventures.
    static let byId: [String: SideHustle] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
