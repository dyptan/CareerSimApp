import Foundation

/// A contest tied to a sport — an athletic event or an e-sports tournament.
/// The player never enters one directly: training a sport automatically enters
/// its top eligible contest each year (see `CompetitionCatalog.bestCompetition`
/// and `Player.advanceYear`). Winning is a skill-based gamble that pays prize
/// money AND grants a lasting **achievement** (a titled trophy). Achievements
/// are reputation: they raise the player's hire odds across the fame-driven
/// Show Business industry (see `Player.fameHireBonus(for:)`).
struct Competition: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let blurb: String
    let discipline: Discipline
    /// Legacy field from when competitions were entered manually for a fee.
    /// Competing is now automatic and free, so this is no longer charged; kept
    /// on the model for reference and possible future use.
    let entryFee: Int
    /// Cash awarded on a win.
    let prize: Int
    /// The titled trophy granted on a win, banked as a `Player.FameAward`.
    let achievement: String
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
    /// gate), in which case `sportBonus` returns 0 — such events no longer have
    /// an entry point now that competing is sport-driven.
    let sports: Set<Sport>?
    /// Life stages in which the competition is open (mirrors `Hobby.stages`).
    let stages: Set<LifeStage>

    /// Years of training required in a qualifying `sport` before the player may
    /// enter — the progression gate. Entry-level meets (1 year) open as soon as
    /// you take up the sport; marquee championships demand a seasoned competitor,
    /// so a player climbs the ladder only by putting in the years. Ignored for
    /// open events (nil `sports`).
    var minSportYears: Int = 0

    enum Discipline: String { case athletic = "Athletic", esports = "E-Sports", creative = "Creative" }

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
        return max(0.02, min(0.55, 0.02 + skillTerm + sportTerm))
    }
}

enum CompetitionCatalog {
    /// Athletic and e-sports contests, mixing accessible local events (cheap,
    /// modest prizes) with marquee championships (steep entry, big purse and a
    /// prestigious trophy). Open from the teen years onward.
    static let all: [Competition] = [
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
            entryFee: 0,
            prize: 3_000,
            achievement: "Junior Champion",
            fameWeight: 1.0,
            skills: [\.collaborationAndTeamwork, \.spacialNavigationAndOrientation, \.resilienceAndEndurance, \.stressResistanceAndEmotionalRegulation],
            sports: [.soccer, .basketball, .tennis],
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
            entryFee: 100,
            prize: 1_500,
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
            entryFee: 400,
            prize: 12_000,
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
            entryFee: 800,
            prize: 30_000,
            achievement: "Regional Champion",
            fameWeight: 1.5,
            skills: [\.resilienceAndEndurance, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance],
            sports: [.running, .swimming, .cycling, .gymnastics, .martialArts],
            stages: [.youngAdult, .adult],
            minSportYears: 5
        ),
        Competition(
            id: "national-championship",
            name: "National Championship",
            icon: "🏆",
            blurb: "The premier athletic title — the country is watching. Only for seasoned competitors.",
            discipline: .athletic,
            entryFee: 1_500,
            prize: 60_000,
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
            entryFee: 3_000,
            prize: 150_000,
            achievement: "Olympic Medalist",
            fameWeight: 3.0,
            skills: [\.resilienceAndEndurance, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance, \.visionaryThinkingAndAmbition],
            sports: [.running, .swimming, .cycling, .gymnastics, .martialArts],
            stages: [.youngAdult, .adult],
            minSportYears: 8
        ),
        // MARK: - E-Sports
        Competition(
            id: "online-ladder",
            name: "Online Ranked Ladder",
            icon: "🎮",
            blurb: "Climb the seasonal ranks from your own setup. Cheap to enter, a real grind.",
            discipline: .esports,
            entryFee: 50,
            prize: 2_000,
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
            entryFee: 300,
            prize: 15_000,
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
            entryFee: 1_200,
            prize: 120_000,
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

    /// The top competition a player training `sport` currently qualifies for:
    /// stage-eligible, explicitly tagged for that sport, and within `years` of
    /// training in *that* sport (the gate is per-sport). The highest tier wins
    /// (max `minSportYears`, then max `prize`); returns nil if none qualify —
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
                (lhs.minSportYears, lhs.prize) < (rhs.minSportYears, rhs.prize)
            }
    }
}
