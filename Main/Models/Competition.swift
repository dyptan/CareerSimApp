import Foundation

/// A contest tied to a discipline — an athletic event, an e-sports tournament,
/// an arts prize, or a contest of the mind. The player never enters one
/// directly: practising a discipline automatically enters its top eligible
/// contest each year (see `CompetitionCatalog.bestCompetition` and
/// `Player.advanceYear`). Winning is a skill-based gamble that pays no money —
/// the reward is a lasting **achievement** (a titled trophy). Achievements are
/// reputation: they bank fame in the discipline's own bucket (see
/// `Sport.fameCategory` and `Player.fameHireBonus(for:)`).
struct Competition: Identifiable, Hashable {
    let id: String
    private let nameResource: LocalizedStringResource
    /// The contest's name, in the player's language.
    var name: String { String(localized: nameResource) }
    let icon: String
    private let blurbResource: LocalizedStringResource
    /// What the contest is, in a sentence.
    var blurb: String { String(localized: blurbResource) }
    let discipline: Discipline
    private let achievementResource: LocalizedStringResource
    /// The titled trophy granted on a win, in the player's language. Banked as a
    /// `Player.FameAward`, whose stable id is `fameKey` — never this text.
    var achievement: String { String(localized: achievementResource) }
    /// The trophy's English title: the id of the `FameAward` a win banks (and what
    /// `Job.breakthroughFame` names). Never shown.
    var fameKey: String { achievementResource.key }
    /// Reputation weight this trophy carries when totalled into the player's
    /// fame score (see `Player.fameScore`). A flat 1.0 is "one local win"; the
    /// marquee titles (Olympics, world finals) are tuned higher so a single
    /// championship moves the needle more than several warm-up events.
    var fameWeight: Double = 1.0
    /// Soft-skill axes that drive the odds of winning.
    let skills: [WritableKeyPath<SoftSkills, Int>]
    /// Sports that qualify for entry. Set membership is the hard gate: the
    /// competition only auto-enters when the player trains one of these sports
    /// (see `CompetitionCatalog.bestCompetition`). `nil` means open (no sport
    /// gate), but since entry is sport-driven, such an event has no way in.
    let sports: Set<Sport>?
    /// Life stages in which the competition is open (mirrors `Sport.stages`).
    let stages: Set<LifeStage>

    /// Years of training required in a qualifying `sport` before the player may
    /// enter — the progression gate. Entry-level meets (1 year) open as soon as
    /// you take up the sport; marquee championships demand a seasoned competitor,
    /// so a player climbs the ladder only by putting in the years. Ignored for
    /// open events (nil `sports`).
    var minSportYears: Int = 0

    /// Overrides the tier's win cap (`winCap`) for an event whose field is far
    /// deeper than its trophy's weight suggests. Used for the Junior
    /// Championship: it is the scouting gate into professional sport, contested
    /// by every serious youth player, so a title is a genuine long shot.
    var maxWinChance: Double? = nil

    /// The catalogue rows pass their text as literals (`name: "Hackathon"`), which the compiler
    /// extracts into the String Catalog; `name`, `blurb` and `achievement` read it back.
    init(id: String, name: LocalizedStringResource, icon: String, blurb: LocalizedStringResource,
         discipline: Discipline, achievement: LocalizedStringResource, fameWeight: Double = 1.0,
         skills: [WritableKeyPath<SoftSkills, Int>], sports: Set<Sport>?, stages: Set<LifeStage>,
         minSportYears: Int = 0, maxWinChance: Double? = nil) {
        self.id = id
        self.nameResource = name
        self.icon = icon
        self.blurbResource = blurb
        self.discipline = discipline
        self.achievementResource = achievement
        self.fameWeight = fameWeight
        self.skills = skills
        self.sports = sports
        self.stages = stages
        self.minSportYears = minSportYears
        self.maxWinChance = maxWinChance
    }

    enum Discipline: String { case athletic = "Athletic", esports = "E-Sports", creative = "Creative", mind = "Mind", academic = "Academic" }

    static func == (lhs: Competition, rhs: Competition) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Skill level at which one axis is a perfect fit (caps its contribution).
    static let skillReference = 6

    /// Years of training at which a sport is a perfect fit (caps the bonus).
    static let sportReference = 6

    /// 0...1 fit of the player's skills to this competition.
    func skillFit(for soft: SoftSkills) -> Double {
        guard !skills.isEmpty else { return 0 }
        let total = skills.reduce(0.0) { acc, kp in
            acc + min(Double(soft[keyPath: kp]) / Double(Competition.skillReference), 1.0)
        }
        return total / Double(skills.count)
    }

    /// 0...1 sport-fit from the years trained in the *specific* sport the player
    /// is competing through — competitions are always evaluated per sport, so a
    /// multi-sport event draws only on the years in the one sport that entered
    /// it, not the player's best across the whole qualifying set. Tops out at
    /// `sportReference` years.
    func sportFit(forYears years: Int) -> Double {
        min(Double(years) / Double(Competition.sportReference), 1.0)
    }

    /// Whether the given years in a qualifying sport clear this event's gate.
    func meetsTrainingRequirement(forYears years: Int) -> Bool {
        years >= minSportYears
    }

    /// Probability of winning this year, evaluated for one specific sport's
    /// trained `years`. Deliberately steep: even a seasoned, highly skilled
    /// competitor tops out around a coin-flip, and a newcomer is a long shot —
    /// winning a title is meant to take years of committed training.
    func winProbability(for soft: SoftSkills, years: Int) -> Double {
        let skillTerm = skillFit(for: soft) * 0.30
        let sportTerm = sportFit(forYears: years) * 0.25
        // The whole curve scales with the tier's cap, so a perfect competitor
        // reaches the cap and a newcomer stays a long shot at every level.
        let cap = winCap
        return max(0.005, min(cap, (0.02 + skillTerm + sportTerm) * cap / Competition.baseWinCap))
    }

    /// The best odds of winning in any one year, by how big the title is. A
    /// school ribbon goes to one child in a class; a national title to one
    /// competitor in thousands; an Olympic medal or a world final to a handful
    /// in a generation (about 1 in 10 Olympians medal at all). Keyed off the
    /// trophy's `fameWeight`, which already ranks the tiers.
    var winCap: Double {
        if let maxWinChance { return maxWinChance }
        switch fameWeight {
        case ..<0.75: return Competition.baseWinCap   // school, local, club
        case ..<1.5:  return 0.20                     // youth / regional
        case ..<2.5:  return 0.12                     // national
        default:      return 0.04                     // international / Olympic
        }
    }

    /// The cap the skill and sport terms were tuned against.
    static let baseWinCap = 0.55
}

enum CompetitionCatalog {
    /// Every discipline's contests, mixing accessible local events with
    /// marquee championships carrying a far more prestigious trophy.
    static let all: [Competition] = [
        // MARK: - Childhood (first rung)
        // Every discipline open to children has a small school-level contest, so
        // a young player sees levels and trophies from the first year. Light
        // fame weights: a sports-day ribbon is a start, not a reputation.
        Competition(
            id: "school-sports-day",
            name: "School Sports Day",
            icon: "🎽",
            blurb: "Races and routines in front of the whole school — the first taste of winning.",
            discipline: .athletic,
            achievement: "Sports Day Winner",
            fameWeight: 0.25,
            skills: [\.resilienceAndEndurance, \.selfDisciplineAndPerseverance],
            sports: [.running, .swimming, .cycling, .gymnastics, .martialArts, .skateboarding],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "kids-league-cup",
            name: "Kids' League Cup",
            icon: "🏆",
            blurb: "A season of Saturday games, one trophy at the end of it.",
            discipline: .athletic,
            achievement: "Kids' Cup Winner",
            fameWeight: 0.25,
            skills: [\.collaborationAndTeamwork, \.resilienceAndEndurance],
            sports: [.soccer, .basketball, .tennis],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "school-recital",
            name: "School Music Recital",
            icon: "🎵",
            blurb: "One piece, a full hall, and your family in the front row.",
            discipline: .creative,
            achievement: "Recital Star",
            fameWeight: 0.25,
            skills: [\.selfDisciplineAndPerseverance, \.communicationAndNetworking],
            sports: [.music],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "school-art-contest",
            name: "School Art Contest",
            icon: "🖍️",
            blurb: "Pinned to the corridor wall — and judged.",
            discipline: .creative,
            achievement: "Art Contest Winner",
            fameWeight: 0.25,
            skills: [\.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail],
            sports: [.drawing],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "kids-photo-contest",
            name: "Kids' Photo Contest",
            icon: "📷",
            blurb: "One photo, one theme, judged by the local paper.",
            discipline: .creative,
            achievement: "Photo Contest Winner",
            fameWeight: 0.25,
            skills: [\.carefulnessAndAttentionToDetail, \.creativityAndInsightfulThinking],
            sports: [.photography],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "kids-bake-off",
            name: "Kids' Bake-Off",
            icon: "🧁",
            blurb: "A tray of bakes, a panel of judges, and a ribbon for the best.",
            discipline: .creative,
            achievement: "Bake-Off Winner",
            fameWeight: 0.25,
            skills: [\.tinkeringAndFingerPrecision, \.creativityAndInsightfulThinking],
            sports: [.cooking],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "dance-showcase",
            name: "Dance-School Showcase",
            icon: "🩰",
            blurb: "The end-of-year show — one solo gets the prize.",
            discipline: .creative,
            achievement: "Showcase Star",
            fameWeight: 0.25,
            skills: [\.communicationAndNetworking, \.selfDisciplineAndPerseverance],
            sports: [.dance],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "kids-coding-challenge",
            name: "Kids' Coding Challenge",
            icon: "🧩",
            blurb: "Block-coding puzzles against the clock.",
            discipline: .mind,
            achievement: "Coding Challenge Winner",
            fameWeight: 0.25,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail],
            sports: [.coding],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "school-chess",
            name: "School Chess Tournament",
            icon: "♟️",
            blurb: "Swiss rounds in the school library.",
            discipline: .mind,
            achievement: "School Chess Champion",
            fameWeight: 0.25,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail],
            sports: [.chess],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "primary-debate-cup",
            name: "Primary Debate Cup",
            icon: "🗣️",
            blurb: "Short motions, big opinions, a trophy for the best speaker.",
            discipline: .mind,
            achievement: "Debate Cup Winner",
            fameWeight: 0.25,
            skills: [\.communicationAndNetworking],
            sports: [.debate],
            stages: [.child],
            minSportYears: 1
        ),
        // MARK: - Junior (teen-only)
        // The youth pathway into team sport. Winning it as a teen banks the
        // "Junior Champion" title, which is the gateway fame award for the
        // Professional Player career (see `Job.breakthroughFameByRole`).
        Competition(
            id: "junior-championship",
            name: "Junior Championship",
            icon: "🏅",
            blurb: "The youth league final — where scouts spot the next generation of pro players.",
            discipline: .athletic,
            achievement: "Junior Champion",
            fameWeight: 1.0,
            skills: [\.collaborationAndTeamwork, \.spacialNavigationAndOrientation, \.resilienceAndEndurance, \.stressResistanceAndEmotionalRegulation],
            sports: [.soccer, .basketball, .tennis],
            stages: [.teen],
            minSportYears: 1,
            // About 1 in 30 dedicated youth players: NCAA puts the high-school-
            // to-pro odds at well under 1 %, and the title is the scouts' gate.
            maxWinChance: 0.035
        ),
        Competition(
            id: "junior-athletics-meet",
            name: "Junior Athletics Meet",
            icon: "🏃",
            blurb: "The county youth meet — heats, finals, and a podium.",
            discipline: .athletic,
            achievement: "Junior Meet Winner",
            fameWeight: 0.75,
            skills: [\.resilienceAndEndurance, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            sports: [.running, .swimming, .cycling, .gymnastics, .martialArts, .skateboarding],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "high-school-esports",
            name: "High-School Esports Cup",
            icon: "🎮",
            blurb: "School teams, one bracket, one weekend.",
            discipline: .esports,
            achievement: "Esports Cup Winner",
            fameWeight: 0.5,
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.collaborationAndTeamwork],
            sports: [.esports],
            stages: [.teen],
            minSportYears: 1
        ),
        // MARK: - Athletic
        Competition(
            id: "local-5k",
            name: "Local 5K Race",
            icon: "🏃",
            blurb: "A weekend road race — an accessible first taste of competition.",
            discipline: .athletic,
            achievement: "5K Race Winner",
            fameWeight: 0.5,
            skills: [\.resilienceAndEndurance, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            sports: [.running],
            stages: [.youngAdult, .adult],
            minSportYears: 1
        ),
        Competition(
            id: "city-marathon",
            name: "City Marathon",
            icon: "🥇",
            blurb: "26.2 miles against thousands. A few seasons of training under your belt to even finish.",
            discipline: .athletic,
            achievement: "Marathon Champion",
            fameWeight: 1.0,
            skills: [\.resilienceAndEndurance, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            sports: [.running],
            stages: [.youngAdult, .adult],
            minSportYears: 3
        ),
        Competition(
            id: "regional-championship",
            name: "Regional Championship",
            icon: "🏅",
            blurb: "The step up to serious competition — qualify against your region's best. Years of training required.",
            discipline: .athletic,
            achievement: "Regional Champion",
            fameWeight: 1.5,
            skills: [\.resilienceAndEndurance, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance],
            sports: [.running, .swimming, .cycling, .gymnastics, .martialArts, .skateboarding],
            stages: [.youngAdult, .adult],
            minSportYears: 5
        ),
        Competition(
            id: "national-championship",
            name: "National Championship",
            icon: "🏆",
            blurb: "The premier athletic title — the country is watching. Only for seasoned competitors.",
            discipline: .athletic,
            achievement: "National Champion",
            fameWeight: 2.0,
            skills: [\.resilienceAndEndurance, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance],
            sports: [.soccer, .basketball, .tennis, .martialArts],
            stages: [.youngAdult, .adult],
            minSportYears: 5
        ),
        Competition(
            id: "olympic-trials",
            name: "Olympic Games",
            icon: "🥇",
            blurb: "The world stage. Medal here and you're a household name for life — the summit of a long career.",
            discipline: .athletic,
            achievement: "Olympic Medalist",
            fameWeight: 3.0,
            skills: [\.resilienceAndEndurance, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance, \.visionaryThinkingAndAmbition],
            sports: [.running, .swimming, .cycling, .gymnastics, .martialArts, .skateboarding],
            stages: [.youngAdult, .adult],
            minSportYears: 8
        ),
        // MARK: - Arts
        Competition(
            id: "youth-music-competition",
            name: "Youth Music Competition",
            icon: "🎻",
            blurb: "Graded repertoire before a jury of conservatoire teachers.",
            discipline: .creative,
            achievement: "Young Musician of the Year",
            fameWeight: 1.0,
            skills: [\.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking, \.communicationAndNetworking, \.stressResistanceAndEmotionalRegulation],
            sports: [.music],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "national-music-competition",
            name: "National Music Competition",
            icon: "🎼",
            blurb: "The country's top young players, one concert hall.",
            discipline: .creative,
            achievement: "National Music Laureate",
            fameWeight: 1.5,
            skills: [\.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking, \.communicationAndNetworking, \.stressResistanceAndEmotionalRegulation],
            sports: [.music],
            stages: [.youngAdult, .adult],
            minSportYears: 3
        ),
        Competition(
            id: "international-music-competition",
            name: "International Music Competition",
            icon: "🏛️",
            blurb: "The Chopin, the Tchaikovsky — a win makes a career.",
            discipline: .creative,
            achievement: "International Music Laureate",
            fameWeight: 2.5,
            skills: [\.selfDisciplineAndPerseverance, \.creativityAndInsightfulThinking, \.communicationAndNetworking, \.stressResistanceAndEmotionalRegulation, \.visionaryThinkingAndAmbition],
            sports: [.music],
            stages: [.youngAdult, .adult],
            minSportYears: 8
        ),
        Competition(
            id: "youth-art-prize",
            name: "Youth Art Prize",
            icon: "🎨",
            blurb: "A regional gallery hangs the shortlist.",
            discipline: .creative,
            achievement: "Young Artist of the Year",
            fameWeight: 0.75,
            skills: [\.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail, \.tinkeringAndFingerPrecision],
            sports: [.drawing],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "open-art-exhibition",
            name: "Open Art Exhibition",
            icon: "🖼️",
            blurb: "Submit to the open show — selection is the first prize.",
            discipline: .creative,
            achievement: "Exhibition Prizewinner",
            fameWeight: 0.75,
            skills: [\.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail, \.tinkeringAndFingerPrecision],
            sports: [.drawing],
            stages: [.youngAdult, .adult],
            minSportYears: 1
        ),
        Competition(
            id: "national-art-prize",
            name: "National Art Prize",
            icon: "🏆",
            blurb: "The prize critics write about.",
            discipline: .creative,
            achievement: "National Art Prize Winner",
            fameWeight: 1.5,
            skills: [\.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail, \.tinkeringAndFingerPrecision, \.visionaryThinkingAndAmbition],
            sports: [.drawing],
            stages: [.youngAdult, .adult],
            minSportYears: 5
        ),
        Competition(
            id: "youth-photo-award",
            name: "Youth Photography Award",
            icon: "📸",
            blurb: "A portfolio of six, judged by working photographers.",
            discipline: .creative,
            achievement: "Young Photographer of the Year",
            fameWeight: 0.75,
            skills: [\.carefulnessAndAttentionToDetail, \.creativityAndInsightfulThinking, \.timeManagementAndPlanning],
            sports: [.photography],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "national-photo-award",
            name: "National Photography Award",
            icon: "🏞️",
            blurb: "The year's best images, printed large and toured.",
            discipline: .creative,
            achievement: "National Photography Award Winner",
            fameWeight: 1.5,
            skills: [\.carefulnessAndAttentionToDetail, \.creativityAndInsightfulThinking, \.timeManagementAndPlanning, \.communicationAndNetworking],
            sports: [.photography],
            stages: [.youngAdult, .adult],
            minSportYears: 3
        ),
        Competition(
            id: "junior-cook-off",
            name: "Junior Cook-Off",
            icon: "🍳",
            blurb: "Three courses in ninety minutes, live.",
            discipline: .creative,
            achievement: "Junior Chef Champion",
            fameWeight: 0.75,
            skills: [\.tinkeringAndFingerPrecision, \.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail, \.stressResistanceAndEmotionalRegulation],
            sports: [.cooking],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "culinary-championship",
            name: "Culinary Championship",
            icon: "👨‍🍳",
            blurb: "A mystery basket and a panel of head chefs.",
            discipline: .creative,
            achievement: "Culinary Champion",
            fameWeight: 1.5,
            skills: [\.tinkeringAndFingerPrecision, \.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail, \.stressResistanceAndEmotionalRegulation],
            sports: [.cooking],
            stages: [.youngAdult, .adult],
            minSportYears: 3
        ),
        Competition(
            id: "youth-dance-competition",
            name: "Youth Dance Competition",
            icon: "💃",
            blurb: "Solo and troupe sections, marked to the step.",
            discipline: .creative,
            achievement: "Youth Dance Champion",
            fameWeight: 0.75,
            skills: [\.communicationAndNetworking, \.resilienceAndEndurance, \.creativityAndInsightfulThinking, \.selfDisciplineAndPerseverance],
            sports: [.dance],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "national-dance-championship",
            name: "National Dance Championship",
            icon: "🏆",
            blurb: "The title the companies scout at.",
            discipline: .creative,
            achievement: "National Dance Champion",
            fameWeight: 1.5,
            skills: [\.communicationAndNetworking, \.resilienceAndEndurance, \.creativityAndInsightfulThinking, \.selfDisciplineAndPerseverance],
            sports: [.dance],
            stages: [.youngAdult, .adult],
            minSportYears: 3
        ),
        // MARK: - Minds
        Competition(
            id: "coding-olympiad",
            name: "Coding Olympiad",
            icon: "🧮",
            blurb: "Five hard problems, five hours, no internet.",
            discipline: .mind,
            achievement: "Olympiad Medalist",
            fameWeight: 1.0,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance],
            sports: [.coding],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "hackathon",
            name: "Hackathon",
            icon: "💻",
            blurb: "Build something that works in a weekend.",
            discipline: .mind,
            achievement: "Hackathon Winner",
            fameWeight: 0.75,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.collaborationAndTeamwork],
            sports: [.coding],
            stages: [.youngAdult, .adult],
            minSportYears: 1
        ),
        Competition(
            id: "world-programming-finals",
            name: "World Programming Finals",
            icon: "🌐",
            blurb: "The world's best teams on one stage.",
            discipline: .mind,
            achievement: "World Programming Champion",
            fameWeight: 2.0,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            sports: [.coding],
            stages: [.youngAdult, .adult],
            minSportYears: 5
        ),
        Competition(
            id: "junior-chess-championship",
            name: "Junior Chess Championship",
            icon: "♞",
            blurb: "The national under-18 title.",
            discipline: .mind,
            achievement: "Junior Chess Champion",
            fameWeight: 1.0,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.stressResistanceAndEmotionalRegulation],
            sports: [.chess],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "national-chess-championship",
            name: "National Chess Championship",
            icon: "♚",
            blurb: "Classical time control, the country's strongest board.",
            discipline: .mind,
            achievement: "National Chess Champion",
            fameWeight: 1.5,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.stressResistanceAndEmotionalRegulation],
            sports: [.chess],
            stages: [.youngAdult, .adult],
            minSportYears: 3
        ),
        Competition(
            id: "international-chess-open",
            name: "International Chess Open",
            icon: "👑",
            blurb: "Norms here earn the title every player wants.",
            discipline: .mind,
            achievement: "Grandmaster",
            fameWeight: 2.5,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.stressResistanceAndEmotionalRegulation, \.visionaryThinkingAndAmbition],
            sports: [.chess],
            stages: [.youngAdult, .adult],
            minSportYears: 8
        ),
        Competition(
            id: "youth-debate-championship",
            name: "Youth Debate Championship",
            icon: "🎤",
            blurb: "Schools from across the country, one motion per round.",
            discipline: .mind,
            achievement: "Youth Debate Champion",
            fameWeight: 1.0,
            skills: [\.communicationAndNetworking, \.persuasionAndNegotiation, \.stressResistanceAndEmotionalRegulation],
            sports: [.debate],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "national-debate-championship",
            name: "National Debate Championship",
            icon: "🏛️",
            blurb: "University and open circuits — the final is broadcast.",
            discipline: .mind,
            achievement: "National Debate Champion",
            fameWeight: 1.5,
            skills: [\.communicationAndNetworking, \.persuasionAndNegotiation, \.stressResistanceAndEmotionalRegulation],
            sports: [.debate],
            stages: [.youngAdult, .adult],
            minSportYears: 3
        ),
        // MARK: - Leadership
        // Elections are the contest: the student council's ladder runs from a
        // class seat to leading the whole school, and on to a national award.
        Competition(
            id: "class-rep-election",
            name: "Class Representative Election",
            icon: "🗳️",
            blurb: "Make your pitch to the class, then count the votes.",
            discipline: .mind,
            achievement: "Class Representative",
            fameWeight: 0.25,
            skills: [\.leadershipAndInfluence, \.persuasionAndNegotiation],
            sports: [.studentCouncil],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "student-council-election",
            name: "Student Council Election",
            icon: "🏫",
            blurb: "A campaign, a speech in the hall, and the whole school voting.",
            discipline: .mind,
            achievement: "Student Body President",
            fameWeight: 1.0,
            skills: [\.leadershipAndInfluence, \.persuasionAndNegotiation, \.communicationAndNetworking],
            sports: [.studentCouncil],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "youth-leadership-award",
            name: "National Youth Leadership Award",
            icon: "🎖️",
            blurb: "For the student who led something real — a campaign, a charity, a change at school.",
            discipline: .mind,
            achievement: "Youth Leadership Award Winner",
            fameWeight: 1.5,
            skills: [\.leadershipAndInfluence, \.visionaryThinkingAndAmbition, \.collaborationAndTeamwork, \.communicationAndNetworking],
            sports: [.studentCouncil],
            stages: [.teen],
            minSportYears: 3
        ),
        // MARK: - Academic
        // School subjects compete while the player is at school; the national and
        // international rungs are what a selective university's admissions
        // office notices.
        Competition(
            id: "math-kangaroo",
            name: "Math Kangaroo",
            icon: "🦘",
            blurb: "Thirty tricky puzzles, one morning, millions of kids worldwide.",
            discipline: .academic,
            achievement: "Math Kangaroo Winner",
            fameWeight: 0.25,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail],
            sports: [.math],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "math-olympiad",
            name: "Math Olympiad",
            icon: "➗",
            blurb: "Proofs, not sums — the national round for school students.",
            discipline: .academic,
            achievement: "Math Olympiad Medalist",
            fameWeight: 1.0,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance],
            sports: [.math],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "international-math-olympiad",
            name: "International Math Olympiad",
            icon: "🌐",
            blurb: "Six problems over two days against the world's best school students.",
            discipline: .academic,
            achievement: "International Math Olympiad Medalist",
            fameWeight: 2.0,
            skills: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            sports: [.math],
            stages: [.teen],
            minSportYears: 4
        ),
        Competition(
            id: "school-science-fair",
            name: "School Science Fair",
            icon: "🧪",
            blurb: "A poster, an experiment, and a judge with a clipboard.",
            discipline: .academic,
            achievement: "Science Fair Winner",
            fameWeight: 0.25,
            skills: [\.analyticalReasoningAndProblemSolving, \.creativityAndInsightfulThinking],
            sports: [.science],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "regional-science-fair",
            name: "Regional Science Fair",
            icon: "🔬",
            blurb: "A real research question, defended in front of scientists.",
            discipline: .academic,
            achievement: "Regional Science Fair Winner",
            fameWeight: 0.75,
            skills: [\.analyticalReasoningAndProblemSolving, \.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail, \.timeManagementAndPlanning],
            sports: [.science],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "international-science-fair",
            name: "International Science & Engineering Fair",
            icon: "🏛️",
            blurb: "The world's largest pre-college science competition.",
            discipline: .academic,
            achievement: "International Science Fair Winner",
            fameWeight: 2.0,
            skills: [\.analyticalReasoningAndProblemSolving, \.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail, \.timeManagementAndPlanning],
            sports: [.science],
            stages: [.teen],
            minSportYears: 4
        ),
        Competition(
            id: "spelling-bee",
            name: "Spelling Bee",
            icon: "🐝",
            blurb: "One word at a time, on stage, until one speller is left.",
            discipline: .academic,
            achievement: "Spelling Bee Champion",
            fameWeight: 0.25,
            skills: [\.carefulnessAndAttentionToDetail, \.communicationAndNetworking],
            sports: [.literature],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "young-writers-prize",
            name: "Young Writers' Prize",
            icon: "✍️",
            blurb: "Short stories and essays, judged by published authors.",
            discipline: .academic,
            achievement: "Young Writer of the Year",
            fameWeight: 0.75,
            skills: [\.communicationAndNetworking, \.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail],
            sports: [.literature],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "national-essay-competition",
            name: "National Essay Competition",
            icon: "📜",
            blurb: "One prompt, the country's strongest student writers.",
            discipline: .academic,
            achievement: "National Essay Prize Winner",
            fameWeight: 1.5,
            skills: [\.communicationAndNetworking, \.creativityAndInsightfulThinking, \.carefulnessAndAttentionToDetail],
            sports: [.literature],
            stages: [.teen],
            minSportYears: 3
        ),
        Competition(
            id: "geography-bee",
            name: "Geography Bee",
            icon: "🗺️",
            blurb: "Capitals, rivers, and mountain ranges — fastest hand wins.",
            discipline: .academic,
            achievement: "Geography Bee Champion",
            fameWeight: 0.25,
            skills: [\.spacialNavigationAndOrientation, \.analyticalReasoningAndProblemSolving],
            sports: [.history],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "history-bowl",
            name: "History Bowl",
            icon: "🏺",
            blurb: "Team quiz rounds from the pharaohs to the moon landing.",
            discipline: .academic,
            achievement: "History Bowl Champion",
            fameWeight: 0.75,
            skills: [\.analyticalReasoningAndProblemSolving, \.spacialNavigationAndOrientation, \.communicationAndNetworking],
            sports: [.history],
            stages: [.teen],
            minSportYears: 1
        ),
        Competition(
            id: "geography-olympiad",
            name: "National Geography Olympiad",
            icon: "🌍",
            blurb: "Fieldwork, maps, and a written exam — the national title.",
            discipline: .academic,
            achievement: "Geography Olympiad Medalist",
            fameWeight: 1.5,
            skills: [\.analyticalReasoningAndProblemSolving, \.spacialNavigationAndOrientation, \.communicationAndNetworking, \.timeManagementAndPlanning],
            sports: [.history],
            stages: [.teen],
            minSportYears: 3
        ),
        Competition(
            id: "junior-language-contest",
            name: "Junior Language Contest",
            icon: "🗣️",
            blurb: "Recite, listen, and answer — all in another language.",
            discipline: .academic,
            achievement: "Language Contest Winner",
            fameWeight: 0.25,
            skills: [\.communicationAndNetworking, \.selfDisciplineAndPerseverance],
            sports: [.languages],
            stages: [.child],
            minSportYears: 1
        ),
        Competition(
            id: "linguistics-olympiad",
            name: "Linguistics Olympiad",
            icon: "🈯",
            blurb: "Crack the rules of a language you've never seen.",
            discipline: .academic,
            achievement: "Linguistics Olympiad Medalist",
            fameWeight: 1.0,
            skills: [\.communicationAndNetworking, \.analyticalReasoningAndProblemSolving, \.selfDisciplineAndPerseverance],
            sports: [.languages],
            stages: [.teen],
            minSportYears: 1
        ),
        // MARK: - E-Sports
        Competition(
            id: "online-ladder",
            name: "Online Ranked Ladder",
            icon: "🎮",
            blurb: "Climb the seasonal ranks from your own setup. Cheap to enter, a real grind.",
            discipline: .esports,
            achievement: "Ladder Season Champion",
            fameWeight: 0.5,
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.stressResistanceAndEmotionalRegulation],
            sports: [.esports],
            stages: [.youngAdult, .adult],
            minSportYears: 1
        ),
        Competition(
            id: "lan-tournament",
            name: "Regional LAN Tournament",
            icon: "🕹️",
            blurb: "Bracket play on stage against the region's best squads. A few seasons of grinding to qualify.",
            discipline: .esports,
            achievement: "LAN Tournament Champion",
            fameWeight: 1.0,
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation],
            sports: [.esports],
            stages: [.youngAdult, .adult],
            minSportYears: 3
        ),
        Competition(
            id: "world-esports-final",
            name: "World Esports Finals",
            icon: "🌐",
            blurb: "The global championship, a packed arena, and a life-changing purse — years at the top to reach it.",
            discipline: .esports,
            achievement: "Esports World Champion",
            fameWeight: 2.5,
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation, \.visionaryThinkingAndAmbition],
            sports: [.esports],
            stages: [.youngAdult, .adult],
            minSportYears: 6
        ),
    ]

    static let byId: [String: Competition] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    /// The id (`fameKey`, the English title) of every trophy a competition can grant — how the UI
    /// tells a sports title apart from the other accolades on the fame shelf. Compare it with a
    /// `FameAward`'s key, not with its displayed title.
    static let achievementTitles: Set<String> = Set(all.map(\.fameKey))

    /// The top competition a player training `sport` currently qualifies for:
    /// stage-eligible, explicitly tagged for that sport, and within `years` of
    /// training in *that* sport (the gate is per-sport). The highest tier wins
    /// (max `minSportYears`, then max `fameWeight`); returns nil if none qualify —
    /// e.g. a child, or year 0 in the sport. Drives the automatic yearly contest
    /// resolved in `Player.advanceYear`.
    static func bestCompetition(
        forSport sport: Sport,
        stage: LifeStage,
        years: Int
    ) -> Competition? {
        all
            .filter { competition in
                competition.stages.contains(stage)
                    && competition.sports?.contains(sport) == true
                    && competition.meetsTrainingRequirement(forYears: years)
            }
            .max { lhs, rhs in
                (lhs.minSportYears, lhs.fameWeight) < (rhs.minSportYears, rhs.fameWeight)
            }
    }
}
