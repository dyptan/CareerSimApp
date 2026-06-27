import Foundation

/// A contest the player can enter in their spare time — an athletic event or an
/// e-sports tournament. Entering costs a fee; winning is a skill-based gamble
/// that pays prize money AND grants a lasting **achievement** (a titled trophy).
/// Achievements are reputation: they raise the player's hire odds across the
/// fame-driven Show Business industry (see `Player.achievementHireBonus`).
struct Competition: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let blurb: String
    let discipline: Discipline
    /// Entry fee (registration, travel, gear), staked when the player competes.
    let entryFee: Int
    /// Cash awarded on a win.
    let prize: Int
    /// The titled trophy granted on a win, banked in `Player.achievements`.
    let achievement: String
    /// Soft-skill axes that drive the odds of winning.
    let skills: [WritableKeyPath<SoftSkills, Int>]
    /// Life stages in which the competition is open (mirrors `Hobby.stages`).
    let stages: Set<LifeStage>

    enum Discipline: String { case athletic = "Athletic", esports = "E-Sports" }

    static func == (lhs: Competition, rhs: Competition) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Skill level at which one axis is a perfect fit (caps its contribution).
    static let skillReference = 6

    /// 0...1 fit of the player's skills to this competition.
    func skillFit(for soft: SoftSkills) -> Double {
        guard !skills.isEmpty else { return 0 }
        let total = skills.reduce(0.0) { acc, kp in
            acc + min(Double(soft[keyPath: kp]) / Double(Competition.skillReference), 1.0)
        }
        return total / Double(skills.count)
    }

    /// Probability (0.05...0.85) of winning this year, scaled by skill fit.
    /// Deliberately steeper than a side hustle — trophies are hard-won.
    func winProbability(for soft: SoftSkills) -> Double {
        max(0.05, min(0.85, 0.05 + skillFit(for: soft) * 0.75))
    }
}

enum CompetitionCatalog {
    /// Athletic and e-sports contests, mixing accessible local events (cheap,
    /// modest prizes) with marquee championships (steep entry, big purse and a
    /// prestigious trophy). Open from the teen years onward.
    static let all: [Competition] = [
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
            skills: [\.resilienceAndEndurance, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            stages: [.teen, .youngAdult, .adult]
        ),
        Competition(
            id: "city-marathon",
            name: "City Marathon",
            icon: "🥇",
            blurb: "26.2 miles against thousands. Finishing strong turns heads.",
            discipline: .athletic,
            entryFee: 400,
            prize: 12_000,
            achievement: "Marathon Champion",
            skills: [\.resilienceAndEndurance, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            stages: [.youngAdult, .adult]
        ),
        Competition(
            id: "national-championship",
            name: "National Championship",
            icon: "🏆",
            blurb: "The premier athletic title — the country is watching.",
            discipline: .athletic,
            entryFee: 1_500,
            prize: 60_000,
            achievement: "National Champion",
            skills: [\.resilienceAndEndurance, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance],
            stages: [.youngAdult, .adult]
        ),
        Competition(
            id: "olympic-trials",
            name: "Olympic Games",
            icon: "🥇",
            blurb: "The world stage. Medal here and you're a household name for life.",
            discipline: .athletic,
            entryFee: 3_000,
            prize: 150_000,
            achievement: "Olympic Medalist",
            skills: [\.resilienceAndEndurance, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance, \.visionaryThinkingAndAmbition],
            stages: [.youngAdult, .adult]
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
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.stressResistanceAndEmotionalRegulation],
            stages: [.teen, .youngAdult, .adult]
        ),
        Competition(
            id: "lan-tournament",
            name: "Regional LAN Tournament",
            icon: "🕹️",
            blurb: "Bracket play on stage against the region's best squads.",
            discipline: .esports,
            entryFee: 300,
            prize: 15_000,
            achievement: "LAN Tournament Champion",
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation],
            stages: [.teen, .youngAdult, .adult]
        ),
        Competition(
            id: "world-esports-final",
            name: "World Esports Finals",
            icon: "🌐",
            blurb: "The global championship, a packed arena, and a life-changing purse.",
            discipline: .esports,
            entryFee: 1_200,
            prize: 120_000,
            achievement: "Esports World Champion",
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation, \.visionaryThinkingAndAmbition],
            stages: [.youngAdult, .adult]
        ),
    ]

    static let byId: [String: Competition] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
