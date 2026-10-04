import Foundation

/// A spare-time venture the player commits a year to — a gamble that stakes no
/// money, only the year: the odds scale with how well the player's soft skills
/// fit the work and how much working life stands behind it, and a flop simply
/// yields nothing.
///
/// A successful year banks an industry-scoped reputation award (see
/// `Player.fameAwards` / `fameHireBonus`) and grows the soft skills it drew on —
/// the reward a passive hobby can't give.
struct SideHustle: Identifiable, Hashable {
    let id: String
    private let labelResource: LocalizedStringResource
    /// The project's name, in the player's language.
    var label: String { String(localized: labelResource) }
    let icon: String
    private let blurbResource: LocalizedStringResource
    /// What the project is, in a sentence or two.
    var blurb: String { String(localized: blurbResource) }
    /// The soft-skill axes this venture draws on. The player's levels in these
    /// talents drive the success odds.
    let talents: [WritableKeyPath<SoftSkills, Int>]
    /// The fame bucket a successful year banks reputation in, and the award's
    /// weight in reputation points (see `Player.award`).
    let fameCategory: FameCategory
    let fameWeight: Double
    /// Life stages in which the venture is offered (mirrors `Sport.stages`).
    let stages: Set<LifeStage>
    /// Soft-skill gains applied for *any* committed year, hit or flop (each
    /// capped at 10 in `advanceYear`) — the craft axes drawn on plus a
    /// founder-cluster bump. Only the fame award turns on the roll.
    var growth: [WeightedAbility] = []
    private var fameTitleResource: LocalizedStringResource? = nil
    /// The bespoke title of the fame award banked on a successful year, in the player's
    /// language; nil when the award is named after the project (see `awardTitle`).
    var fameTitle: String? { fameTitleResource.map { String(localized: $0) } }
    /// The title of the fame award a successful year banks, in the player's language.
    var awardTitle: String { fameTitle ?? label }
    /// The English title of that award: its stable id (`FameAward` key, `requiresAward`,
    /// `Job.breakthroughFame`). Never shown.
    var fameKey: String { fameTitleResource?.key ?? labelResource.key }
    /// The industry a committed year of this venture credits as *work
    /// experience*. Set on the entrepreneurship ventures (`.entrepreneurship`),
    /// so years spent on them accumulate like a job would — and, because Business
    /// credits entrepreneurship (`JobCategory.creditedExperienceCategories`),
    /// count toward Business roles.
    /// Years in this field count double toward the odds (see `experienceFit`).
    /// `nil` for ventures that build no formal work experience (most fame plays).
    var experienceCategory: JobCategory? = nil
    /// The most this project's success odds can ever reach in a single year,
    /// however talented and famous the player is — set per project from how
    /// often such work really pays off: booking gigs ~90%, crowdfunding and
    /// articles ~60%, a book, an album or a new channel 20–25%, a true big
    /// break ~0.5% (a lottery you keep entering for years). Fame raises the odds
    /// within the cap, so building an audience matters most where it's lowest.
    var successCeiling: Double = 0.9
    /// A fame award the player must hold to take this project on — the big-
    /// break titles that open the star projects. `nil` for open projects. The
    /// award's English title, i.e. its id (compare with `fameKey`); show it with
    /// `requiredAwardTitle`.
    var requiresAward: String? = nil

    /// The required award's title in the player's language, for the lock line.
    var requiredAwardTitle: String? {
        guard let requiresAward else { return nil }
        return SideHustleCatalog.all.first { $0.fameKey == requiresAward }?.awardTitle ?? requiresAward
    }

    /// Row literals pass the text as literals (`label: "Host a Podcast"`), which the compiler
    /// extracts into the String Catalog; `label`, `blurb` and `fameTitle` read it back.
    init(id: String, label: LocalizedStringResource, icon: String, blurb: LocalizedStringResource,
         talents: [WritableKeyPath<SoftSkills, Int>], fameCategory: FameCategory, fameWeight: Double,
         stages: Set<LifeStage>, growth: [WeightedAbility] = [], fameTitle: LocalizedStringResource? = nil,
         experienceCategory: JobCategory? = nil, successCeiling: Double = 0.9, requiresAward: String? = nil) {
        self.id = id
        self.labelResource = label
        self.icon = icon
        self.blurbResource = blurb
        self.talents = talents
        self.fameCategory = fameCategory
        self.fameWeight = fameWeight
        self.stages = stages
        self.growth = growth
        self.fameTitleResource = fameTitle
        self.experienceCategory = experienceCategory
        self.successCeiling = successCeiling
        self.requiresAward = requiresAward
    }

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

    /// Fame snowball: how much each weighted fame point adds to the project's
    /// fit (so the lift is a share of its `successCeiling`), and the cap that
    /// lift tops out at.
    static let fameLiftPerPoint = 0.05
    static let maxFameLift = 0.30

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
    /// No skill or career gates a project — every one can be attempted with any
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
                            climate: IndustryClimate = .steady,
                            age: Int? = nil) -> Double {
        let fit = SideHustle.talentWeight * talentFit(for: soft)
            + SideHustle.experienceWeight * experienceFit(totalYears: totalExperienceYears,
                                                          fieldYears: fieldExperienceYears)
        // Fame raises the odds *within* the project's ceiling — at most
        // `maxFameLift` of it — so a long shot stays a long shot and talent,
        // not a couple of banked gigs, is what reaches the cap.
        let fameLift = min(famePoints * SideHustle.fameLiftPerPoint, SideHustle.maxFameLift)
        let raw = successCeiling * min(1, fit + fameLift) * climate.projectFactor
            * (age.map(castingAgeFactor) ?? 1)
        return min(successCeiling, max(0, raw))
    }

    /// For a big break, how much the player's age still lets them be
    /// discovered: breakout roles and debut hits go overwhelmingly to people
    /// in their twenties, so the lottery thins after 30 and all but closes
    /// after 40. Every other project is age-blind.
    func castingAgeFactor(_ age: Int) -> Double {
        guard SideHustle.bigBreakIds.contains(id) else { return 1 }
        switch age {
        case ..<30: return 1.0
        case ..<40: return 0.4
        default:    return 0.1
        }
    }

    static let bigBreakIds: Set<String> = ["bigBreakActing", "bigBreakMusic"]

    /// Rolls a single year of this venture: a `FameGrant` on success, nothing on
    /// a flop. The experience and fame arguments are the odds inputs described on
    /// `successProbability`.
    func resolve(for soft: SoftSkills, famePoints: Double = 0,
                 totalExperienceYears: Int = 0, fieldExperienceYears: Int = 0,
                 climate: IndustryClimate = .steady, age: Int? = nil) -> Outcome {
        let odds = successProbability(for: soft, famePoints: famePoints,
                                      totalExperienceYears: totalExperienceYears,
                                      fieldExperienceYears: fieldExperienceYears,
                                      climate: climate, age: age)
        guard Double.random(in: 0...1) < odds else {
            return Outcome(hustle: self, success: false, odds: odds, grantedFame: nil)
        }
        // A shipped project is a strong fame driver, like presenting at an
        // event — the banked reputation is scaled up from the raw catalogue
        // weight (see GameConstants.accomplishmentFameMultiplier).
        let banked = fameWeight * GameConstants.accomplishmentFameMultiplier
        let grant = FameGrant(title: awardTitle, key: fameKey, category: fameCategory, weight: banked)
        return Outcome(hustle: self, success: true, odds: odds, grantedFame: grant)
    }

    /// The fame award banked by a successful year.
    struct FameGrant {
        /// The award's title, in the player's language.
        let title: String
        /// The award's English title: its stable id. Never shown.
        let key: String
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
            blurb: "Record an online course and build an audience of learners.",
            talents: [\.analyticalReasoningAndProblemSolving, \.communicationAndNetworking],
            fameCategory: .business, fameWeight: 1.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 2),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Course Creator",
            successCeiling: 0.5
        ),
        // --- Creative personal-brand ventures ---
        SideHustle(
            id: "influencer",
            label: "Influencer / Content Creator",
            icon: "📱",
            blurb: "Build an audience across social media, a blog and a podcast.",
            talents: [\.communicationAndNetworking, \.creativityAndInsightfulThinking],
            fameCategory: .entertainment, fameWeight: 1.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 2),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Viral Creator",
            successCeiling: 0.2
        ),
        SideHustle(
            id: "selfPublishBook",
            label: "Write & Self-Publish a Book",
            icon: "📚",
            blurb: "Spend the year writing and publishing a book.",
            talents: [\.communicationAndNetworking, \.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking],
            fameCategory: .arts, fameWeight: 1.5,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Published Author",
            successCeiling: 0.25
        ),
        SideHustle(
            id: "freelancePerformer",
            label: "Freelance Artist & Performer",
            icon: "🎭",
            blurb: "Perform on your own, as a musician, dancer or actor.",
            talents: [\.creativityAndInsightfulThinking, \.communicationAndNetworking, \.selfDisciplineAndPerseverance],
            fameCategory: .entertainment, fameWeight: 1.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Rising Performer",
            successCeiling: 0.6
        ),
        SideHustle(
            id: "releaseAlbum",
            label: "Record & Release an Album",
            icon: "🎵",
            blurb: "Book studio time and release your own music.",
            talents: [\.creativityAndInsightfulThinking, \.communicationAndNetworking, \.selfDisciplineAndPerseverance],
            fameCategory: .entertainment, fameWeight: 2.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Recording Artist",
            successCeiling: 0.2
        ),
        // --- Working gigs: how most actors and musicians actually start — one
        // production, one booking at a time. They build an entertainment name
        // and the skills for the big break (projects pay no money).
        SideHustle(
            id: "actingGigs",
            label: "Take Acting Gigs",
            icon: "🎭",
            blurb: "Go to auditions and take the parts you can get: an ad, a small TV role, a play.",
            talents: [\.communicationAndNetworking, \.creativityAndInsightfulThinking, \.resilienceAndEndurance],
            fameCategory: .entertainment, fameWeight: 0.5,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)],
            fameTitle: "Working Actor",
            successCeiling: 0.9
        ),
        SideHustle(
            id: "musicGigs",
            label: "Play Music Gigs",
            icon: "🎸",
            blurb: "Play weddings, cafés and shows of your own.",
            talents: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision, \.selfDisciplineAndPerseverance],
            fameCategory: .entertainment, fameWeight: 0.5,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1)],
            fameTitle: "Gigging Musician",
            successCeiling: 0.9
        ),
        // --- Star work: open only to a name the big break has made. A hit makes
        // you famous; fame, not a fee, is what these projects pay in.
        SideHustle(
            id: "starFilm",
            label: "Star in a Film",
            icon: "🌟",
            blurb: "Take the lead in a big movie.",
            talents: [\.communicationAndNetworking, \.creativityAndInsightfulThinking, \.resilienceAndEndurance],
            fameCategory: .entertainment, fameWeight: 2.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.resilienceAndEndurance, weight: 1)],
            fameTitle: "Film Star",
            successCeiling: 0.85,
            requiresAward: "Breakout Role"
        ),
        SideHustle(
            id: "headlineTour",
            label: "Headline a Tour",
            icon: "🎤",
            blurb: "Take your songs on tour, from small clubs to stadiums.",
            talents: [\.creativityAndInsightfulThinking, \.communicationAndNetworking, \.resilienceAndEndurance],
            fameCategory: .entertainment, fameWeight: 2.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.resilienceAndEndurance, weight: 1)],
            fameTitle: "Headliner",
            successCeiling: 0.85,
            requiresAward: "Hit Record"
        ),
        // --- The big break: rare, career-defining show-business lotteries. Each
        // banks a signature title that opens the star projects above ("Breakout
        // Role" opens Star in a Film, "Hit Record" opens Headline a Tour). The odds ceiling is
        // deliberately low: even a gifted, well-known performer only breaks
        // through after chasing it for years — that's the lottery upside show
        // business is meant to have. Talent and a working career set the odds,
        // and accumulated show-business fame nudges the long shot upward.
        SideHustle(
            id: "bigBreakActing",
            label: "Chase a Breakout Role",
            icon: "🎬",
            blurb: "Audition for the lead role that could make you a movie star.",
            talents: [\.communicationAndNetworking, \.creativityAndInsightfulThinking, \.resilienceAndEndurance],
            fameCategory: .entertainment, fameWeight: 3.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.resilienceAndEndurance, weight: 1)],
            fameTitle: "Breakout Role",
            // About 1 in 200 a year even for real talent: a lead role is a
            // lottery that most working actors never win.
            successCeiling: 0.005
        ),
        SideHustle(
            id: "bigBreakMusic",
            label: "Chase a Hit Single",
            icon: "🎤",
            blurb: "Write the song that could top the charts.",
            talents: [\.creativityAndInsightfulThinking, \.communicationAndNetworking, \.selfDisciplineAndPerseverance],
            fameCategory: .entertainment, fameWeight: 3.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Hit Record",
            successCeiling: 0.005
        ),
        // --- Self-initiated creative works (unlocked to everyone, stage-gated) ---
        SideHustle(
            id: "projectApp",
            label: "Build a Demo App",
            icon: "📱",
            blurb: "Build a small demo app to show off an idea.",
            talents: [\.analyticalReasoningAndProblemSolving, \.creativityAndInsightfulThinking, \.timeManagementAndPlanning],
            fameCategory: .technology, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 2)],
            fameTitle: "Demo Developer",
            successCeiling: 0.3
        ),
        SideHustle(
            id: "projectLibrary",
            label: "Contribute to Open Source",
            icon: "📦",
            blurb: "Contribute to an open-source project, in the open.",
            talents: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance],
            fameCategory: .technology, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                     .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                     .init(keyPath: \.leadershipAndInfluence, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Open-Source Contributor",
            successCeiling: 0.6
        ),
        SideHustle(
            id: "projectArticle",
            label: "Write a Long-Form Article",
            icon: "📝",
            blurb: "Write a long deep-dive out of pure curiosity.",
            talents: [\.communicationAndNetworking, \.carefulnessAndAttentionToDetail],
            fameCategory: .arts, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 2),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.persuasionAndNegotiation, weight: 1)],
            fameTitle: "Bylined Writer",
            successCeiling: 0.6
        ),
        SideHustle(
            id: "projectGame3d",
            label: "Build a Game Mod",
            icon: "🎮",
            blurb: "Make a mod for a game you love: new levels, mechanics or art.",
            talents: [\.creativityAndInsightfulThinking, \.spacialNavigationAndOrientation, \.analyticalReasoningAndProblemSolving],
            fameCategory: .technology, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 2)],
            fameTitle: "Game Modder",
            successCeiling: 0.3
        ),
        // --- More spare-time fame plays: personal-brand builders, not businesses.
        // Each is a pure reputation gamble (no capital, no experience) that banks
        // fame in its bucket and grows the craft it drew on.
        SideHustle(
            id: "projectPodcast",
            label: "Host a Podcast",
            icon: "🎙️",
            blurb: "Record a podcast and put out episode after episode.",
            talents: [\.communicationAndNetworking, \.creativityAndInsightfulThinking],
            fameCategory: .entertainment, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 2),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Podcast Host",
            successCeiling: 0.25
        ),
        SideHustle(
            id: "projectShortFilm",
            label: "Direct a Short Film",
            icon: "🎞️",
            blurb: "Write, shoot and edit a short film yourself.",
            talents: [\.creativityAndInsightfulThinking, \.communicationAndNetworking, \.timeManagementAndPlanning],
            fameCategory: .arts, fameWeight: 1.5,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)],
            fameTitle: "Indie Filmmaker",
            successCeiling: 0.3
        ),
        SideHustle(
            id: "projectTechChannel",
            label: "Run a Tech Channel",
            icon: "🎥",
            blurb: "Record tutorials and deep-dives for developers, on the side.",
            talents: [\.communicationAndNetworking, \.analyticalReasoningAndProblemSolving],
            fameCategory: .technology, fameWeight: 1.0,
            stages: [.teen, .youngAdult, .adult],
            growth: [.init(keyPath: \.communicationAndNetworking, weight: 2),
                     .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)],
            fameTitle: "Tech Educator",
            successCeiling: 0.2
        ),
        SideHustle(
            id: "projectPreprint",
            label: "Publish a Research Preprint",
            icon: "🧪",
            blurb: "Write up independent research and post it for the world to read.",
            talents: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance],
            fameCategory: .science, fameWeight: 1.5,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                     .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)],
            fameTitle: "Published Researcher",
            successCeiling: 0.6
        ),
        // --- Entrepreneurship venture: the self-initiated path to the founder
        // skillset that hobbies can't teach — leadership, vision, persuasion, and
        // risk appetite. (Its organized-competition sibling, entering a pitch
        // competition, is an Event.) A committed year credits
        // `.entrepreneurship` work experience (which counts toward Business
        // roles), banks business-industry fame (toward management and C-suite
        // roles), and grows the entrepreneurial cluster the way running a company
        // would. Years already spent in business/entrepreneurship count twice
        // toward the odds (see `experienceFit`).
        SideHustle(
            id: "crowdfundingCampaign",
            label: "Run a Crowdfunding Campaign",
            icon: "💸",
            blurb: "Rally backers behind a product idea and hit your funding goal.",
            talents: [\.communicationAndNetworking, \.creativityAndInsightfulThinking],
            fameCategory: .business, fameWeight: 1.0,
            stages: [.youngAdult, .adult],
            growth: [.init(keyPath: \.persuasionAndNegotiation, weight: 1),
                     .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                     .init(keyPath: \.leadershipAndInfluence, weight: 1),
                     .init(keyPath: \.communicationAndNetworking, weight: 1)],
            fameTitle: "Crowdfunded Creator",
            experienceCategory: .entrepreneurship,
            successCeiling: 0.6
        ),
    ]

    /// Lookup by stable id, used when resolving the year's selected ventures.
    static let byId: [String: SideHustle] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
