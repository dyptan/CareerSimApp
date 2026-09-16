import Foundation

/// A spare-time venture the player commits a year to — a gamble that stakes no
/// money, only the year: the odds scale with how well the player's soft skills
/// fit the work and how much working life stands behind it, and a flop simply
/// yields nothing.
///
/// A successful year banks an industry-scoped reputation award (see
/// `Player.fameAwards` / `fameHireBonus`) and grows the soft skills it drew on —
/// the reward a passive hobby can't give.
/// Nothing is locked: any venture can be attempted at any time, and the odds
/// (see `successProbability`) carry the whole decision — attempt one you have no
/// talent or career for and you are rolling against essentially nothing.
struct SideHustle: Identifiable, Hashable {
    let id: String
    let label: String
    let icon: String
    let blurb: String
    /// The soft-skill axes this venture draws on. The player's levels in these
    /// talents drive the success odds.
    let talents: [WritableKeyPath<SoftSkills, Int>]
    /// The fame bucket a successful year banks reputation in, and the award's
    /// weight in reputation points (see `Player.award`).
    let fameCategory: FameCategory
    let fameWeight: Double
    /// Life stages in which the venture is offered (mirrors `Activity.stages`).
    let stages: Set<LifeStage>
    /// Soft-skill gains applied for *any* committed year, hit or flop (each
    /// capped at 10 in `advanceYear`) — the craft axes drawn on plus a
    /// founder-cluster bump. Only the fame award turns on the roll.
    var growth: [WeightedAbility] = []
    /// Title of the fame award banked on a successful year. Defaults to `label`
    /// when nil.
    var fameTitle: String? = nil
    /// The industry a committed year of this venture credits as *work
    /// experience*. Set on the entrepreneurship ventures (`.entrepreneurship`),
    /// so years spent building a startup, pitching, or crowdfunding accumulate
    /// like a job would — and, because Business credits entrepreneurship
    /// (`JobCategory.creditedExperienceCategories`), count toward Business roles.
    /// Years in this field count double toward the odds (see `experienceFit`).
    /// `nil` for ventures that build no formal work experience (most fame plays).
    var experienceCategory: JobCategory? = nil
    /// The most this venture's success odds can ever reach in a single year,
    /// however talented and famous the player is. Ordinary ventures leave this at
    /// the default 0.9. A rare **big-break** play (a breakout role, a hit single)
    /// sets it low — a lottery you keep entering — so becoming a star is a
    /// years-long chase, not a formality once your skills are high.
    var successCeiling: Double = 0.9

    static func == (lhs: SideHustle, rhs: SideHustle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

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

    /// Career years at which the experience term is fully earned. Years in the
    /// project's own `experienceCategory` count twice, so a directly relevant
    /// career gets there in half the time.
    static let experienceReference = 16

    /// How the two drivers split the fit score. Talent leads — a project is
    /// mostly about the craft — but a working life still moves the needle.
    static let talentWeight = 0.7
    static let experienceWeight = 0.3

    /// Fame snowball: how much each weighted fame point lifts a fame project's
    /// odds, and the cap that lift tops out at.
    static let fameLiftPerPoint = 0.03
    static let maxFameLift = 0.15

    /// 0...1 measure of how far the player's working life backs this project up.
    /// `fieldYears` — credited years in the project's own `experienceCategory`,
    /// when it has one — count a second time on top of `totalYears`, since
    /// directly relevant reps are worth more than a career spent elsewhere.
    func experienceFit(totalYears: Int, fieldYears: Int) -> Double {
        let credited = Double(max(0, totalYears) + max(0, fieldYears))
        return min(credited / Double(SideHustle.experienceReference), 1.0)
    }

    /// Probability (0...`successCeiling`) that the project pays off this year.
    ///
    /// Nothing gates a project — every one can be attempted at any age, with any
    /// skills — so this number carries the whole decision. It is the weighted
    /// blend of two things the player earns over time: how well their soft skills
    /// fit the work (`talentFit`) and how much working life stands behind it
    /// (`experienceFit`). There is no floor: attempt a project you have no talent
    /// or career for and you are rolling against essentially nothing.
    ///
    /// Projects additionally snowball with reputation — every banked award
    /// lifts the odds by `fameLiftPerPoint` per weighted fame point, capped at
    /// `maxFameLift` — so a name already made opens the next door.
    /// `famePoints` is the player's reputation *in this project's own bucket*
    /// (`Player.famePoints(for:)`), not their overall renown — a tech portfolio
    /// does nothing for the next album, the same rule hiring uses.
    /// `climate` is what the project's field is doing this year — a shipped thing
    /// still needs an audience with money and attention to spare. It scales the
    /// whole result, and more gently than it scales a payroll (see
    /// `IndustryClimate.projectFactor`).
    func successProbability(for soft: SoftSkills, famePoints: Double = 0,
                            totalExperienceYears: Int = 0,
                            fieldExperienceYears: Int = 0,
                            climate: IndustryClimate = .steady) -> Double {
        let fit = SideHustle.talentWeight * talentFit(for: soft)
            + SideHustle.experienceWeight * experienceFit(totalYears: totalExperienceYears,
                                                          fieldYears: fieldExperienceYears)
        let fameLift = min(famePoints * SideHustle.fameLiftPerPoint, SideHustle.maxFameLift)
        let raw = (fit * successCeiling + fameLift) * climate.projectFactor
        return min(successCeiling, max(0, raw))
    }

    /// Rolls a single year of this venture: a `FameGrant` on success, nothing on
    /// a flop. No money is staked, so there is nothing to salvage. The experience
    /// and fame arguments are the odds inputs described on `successProbability`.
    func resolve(for soft: SoftSkills, famePoints: Double = 0,
                 totalExperienceYears: Int = 0, fieldExperienceYears: Int = 0,
                 climate: IndustryClimate = .steady) -> Outcome {
        let odds = successProbability(for: soft, famePoints: famePoints,
                                      totalExperienceYears: totalExperienceYears,
                                      fieldExperienceYears: fieldExperienceYears,
                                      climate: climate)
        guard Double.random(in: 0...1) < odds else {
            return Outcome(hustle: self, success: false, odds: odds, grantedFame: nil)
        }
        // A shipped project is a strong fame driver, like presenting at an
        // event — the banked reputation is scaled up from the raw catalogue
        // weight (see GameConstants.accomplishmentFameMultiplier).
        let banked = fameWeight * GameConstants.accomplishmentFameMultiplier
        let grant = FameGrant(title: fameTitle ?? label, category: fameCategory, weight: banked)
        return Outcome(hustle: self, success: true, odds: odds, grantedFame: grant)
    }

    /// The fame award banked by a successful year.
    struct FameGrant {
        let title: String
        let category: FameCategory
        let weight: Double
    }

    /// Result of resolving one year of a venture.
    struct Outcome {
        let hustle: SideHustle
        let success: Bool
        /// The success probability this year was rolled against — so a caller can
        /// judge how long a shot the result was without recomputing the odds.
        let odds: Double
        /// The fame award banked this year, on a success.
        let grantedFame: FameGrant?
    }
}

/// Master catalogue of spare-time **projects** — the self-initiated works a
/// player creates on their own (an app, a book, an album, a podcast, a research
/// preprint), filtered by life stage in the UI the same way `activities` is.
/// Things you *participate in* rather than create — a festival set, a TV
/// casting, a conference talk, a pitch competition — live in `EventCatalog`
/// instead. Every project banks industry-scoped fame and all resolve identically
/// under the hood as talent-fit gambles.
enum SideHustleCatalog {
    /// Every spare-time project on offer, all shown in the **Projects** sheet: a
    /// successful year banks a `FameCategory`-scoped reputation award and grows
    /// the soft skills it drew on. All are self-initiated works — the business
    /// plays (a MOOC course, a crowdfunding campaign), the creative
    /// personal-brand plays (influencer, book, album, freelance performer), and
    /// things you build in the open (app, open source, article, podcast, short
    /// film, tech channel, preprint, game mod) — spread across the Business,
    /// Entertainment, Arts, Technology, and Science buckets. The capital-staked
    /// business plays live in the Ventures sheet as standalone founder Jobs.
    static let all: [SideHustle] = [
        SideHustle(
            id: "moocCourse",
            label: "Create a MOOC Course",
            icon: "🎓",
            blurb: "Record an online course and build an audience of learners. Grow it into a name and the business world takes note.",
            talents: [\.analyticalReasoningAndProblemSolving, \.presentationAndStorytelling, \.communicationAndNetworking],
            fameCategory: .business, fameWeight: 1.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Course Creator"
        ),
        // --- Creative personal-brand ventures ---
        SideHustle(
            id: "influencer",
            label: "Influencer / Content Creator",
            icon: "📱",
            blurb: "Build an audience across social, a blog, and a podcast, and chase the spotlight. Most channels fizzle — a viral one makes your name.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            fameCategory: .entertainment, fameWeight: 1.0,
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
            fameCategory: .arts, fameWeight: 1.5,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Published Author"
        ),
        SideHustle(
            id: "freelancePerformer",
            label: "Freelance Artist & Performer",
            icon: "🎭",
            blurb: "Go independent in show business — gig as a musician, dancer, or actor and take commissions. Feast or famine, but every show gets you seen.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            fameCategory: .entertainment, fameWeight: 1.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1)],
            fameTitle: "Rising Performer"
        ),
        SideHustle(
            id: "releaseAlbum",
            label: "Record & Release an Album",
            icon: "🎵",
            blurb: "Book studio time and put your music out there. Long odds, but a breakout single makes you a name.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            fameCategory: .entertainment, fameWeight: 2.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Recording Artist"
        ),
        // --- The big break: rare, career-defining show-business lotteries. Each
        // banks a signature title that is *the* gateway into the A-list career
        // ladder (see `Job.breakthroughFameByRole` — "Breakout Role" opens the
        // Movie Star track, "Hit Record" the Pop Star track). The odds ceiling is
        // deliberately low: even a gifted, well-known performer only breaks
        // through after chasing it for years — that's the lottery upside show
        // business is meant to have. Talent and a working career set the odds,
        // and accumulated show-business fame nudges the long shot upward.
        SideHustle(
            id: "bigBreakActing",
            label: "Chase a Breakout Role",
            icon: "🎬",
            blurb: "Audition for the part that could change everything — a lead that puts your face on every screen. The odds are long and you'll chase it for years, but land it and you're a movie star.",
            talents: [\.presentationAndStorytelling, \.creativityAndInsightfulThinking, \.resilienceAndEndurance],
            fameCategory: .entertainment, fameWeight: 3.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.resilienceAndEndurance, weight: 1)],
            fameTitle: "Breakout Role",
            successCeiling: 0.30
        ),
        SideHustle(
            id: "bigBreakMusic",
            label: "Chase a Hit Single",
            icon: "🎤",
            blurb: "Pour everything into the song that could top the charts. Most never land it — but a genuine hit turns a working musician into a pop star overnight.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.selfDisciplineAndPerseverance],
            fameCategory: .entertainment, fameWeight: 3.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Hit Record",
            successCeiling: 0.30
        ),
        // --- Self-initiated creative works (unlocked to everyone, stage-gated) ---
        SideHustle(
            id: "projectApp",
            label: "Build a Demo App",
            icon: "📱",
            blurb: "A small demo app you build to show off an idea. Get it in front of people and word gets around.",
            talents: [\.analyticalReasoningAndProblemSolving, \.creativityAndInsightfulThinking, \.timeManagementAndPlanning],
            fameCategory: .technology, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Demo Developer"
        ),
        SideHustle(
            id: "projectLibrary",
            label: "Contribute to Open Source",
            icon: "📦",
            blurb: "An open-source project you contribute to in the open. Land your work in something people depend on and your name travels with it.",
            talents: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance],
            fameCategory: .technology, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                     .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                     .init(keyPath: \.leadershipAndInfluence, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Open-Source Contributor"
        ),
        SideHustle(
            id: "projectArticle",
            label: "Write a Long-Form Article",
            icon: "📝",
            blurb: "A deep-dive you write out of pure curiosity. A piece that gets read and shared builds a quiet kind of renown.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.carefulnessAndAttentionToDetail],
            fameCategory: .arts, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.persuasionAndNegotiation, weight: 1)],
            fameTitle: "Bylined Writer"
        ),
        SideHustle(
            id: "projectGame3d",
            label: "Build a Game Mod",
            icon: "🎮",
            blurb: "A mod for a game you love — new levels, mechanics, or art built on someone else's engine. A mod the community adopts gets your name known.",
            talents: [\.creativityAndInsightfulThinking, \.spacialNavigationAndOrientation, \.analyticalReasoningAndProblemSolving],
            fameCategory: .technology, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Game Modder"
        ),
        // --- More spare-time fame plays: personal-brand builders, not businesses.
        // Each is a pure reputation gamble (no capital, no experience) that banks
        // fame in its bucket and grows the craft it drew on.
        SideHustle(
            id: "projectPodcast",
            label: "Host a Podcast",
            icon: "🎙️",
            blurb: "A podcast you record and put out episode by episode. Build a loyal audience and your voice becomes a name people know.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            fameCategory: .entertainment, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1)],
            fameTitle: "Podcast Host"
        ),
        SideHustle(
            id: "projectShortFilm",
            label: "Direct a Short Film",
            icon: "🎞️",
            blurb: "A short film you write, shoot, and edit yourself. Land it in a festival lineup and the art world starts to notice.",
            talents: [\.creativityAndInsightfulThinking, \.presentationAndStorytelling, \.timeManagementAndPlanning],
            fameCategory: .arts, fameWeight: 1.5,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)],
            fameTitle: "Indie Filmmaker"
        ),
        SideHustle(
            id: "projectTechChannel",
            label: "Run a Tech Channel",
            icon: "🎥",
            blurb: "A channel of tutorials and deep-dives you record on the side. Explain things well enough and you become a name developers follow.",
            talents: [\.presentationAndStorytelling, \.communicationAndNetworking, \.analyticalReasoningAndProblemSolving],
            fameCategory: .technology, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.presentationAndStorytelling, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1)],
            fameTitle: "Tech Educator"
        ),
        SideHustle(
            id: "projectPreprint",
            label: "Publish a Research Preprint",
            icon: "🧪",
            blurb: "A piece of independent research you write up and post for the world to read. A preprint that gets cited earns you a name in the field.",
            talents: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance],
            fameCategory: .science, fameWeight: 1.5,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                     .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)],
            fameTitle: "Published Researcher"
        ),
        // --- Entrepreneurship venture: the self-initiated path to the founder
        // skillset that hobbies can't teach — leadership, vision, persuasion, and
        // risk appetite. (Its organized-competition sibling, entering a pitch
        // competition, is an Event now.) A committed year credits
        // `.entrepreneurship` work experience (which counts toward Business
        // roles), banks business-industry fame (toward management and C-suite
        // roles), and grows the entrepreneurial cluster the way running a company
        // would. Years already spent in business/entrepreneurship count twice
        // toward the odds (see `experienceFit`).
        SideHustle(
            id: "crowdfundingCampaign",
            label: "Run a Crowdfunding Campaign",
            icon: "💸",
            blurb: "Rally backers behind a product idea and hit your funding goal. A funded campaign proves you can sell a vision, lead a crowd, and run a venture end to end.",
            talents: [\.communicationAndNetworking, \.presentationAndStorytelling, \.creativityAndInsightfulThinking],
            fameCategory: .business, fameWeight: 1.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.persuasionAndNegotiation, weight: 1),
                     .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                     .init(keyPath: \.leadershipAndInfluence, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1)],
            fameTitle: "Crowdfunded Creator",
            experienceCategory: .entrepreneurship
        ),
    ]

    /// Lookup by stable id, used when resolving the year's selected ventures.
    static let byId: [String: SideHustle] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
