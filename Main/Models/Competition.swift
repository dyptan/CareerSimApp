import Foundation

/// A contest the player can enter in their spare time — an athletic event or an
/// e-sports tournament. Entering costs a fee; winning is a skill-based gamble
/// that pays prize money AND grants a lasting **achievement** (a titled trophy).
/// Achievements are reputation: they raise the player's hire odds across the
/// fame-driven Show Business industry (see `Player.fameHireBonus(for:)`).
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
    /// Reputation weight this trophy carries when totalled into the player's
    /// fame score (see `Player.fameScore`). A flat 1.0 is "one local win"; the
    /// marquee titles (Olympics, world finals) are tuned higher so a single
    /// championship moves the needle more than several warm-up events.
    var fameWeight: Double = 1.0
    /// Soft-skill axes that drive the odds of winning.
    let skills: [WritableKeyPath<SoftSkills, Int>]
    /// Sports that qualify for entry. Set membership is the hard gate: a
    /// competition is hidden in `CompetitionsView` unless the player practices
    /// at least one of these sports. `nil` means open (no sport gate, e.g. a
    /// generic multi-sport event), in which case `sportBonus` returns 0.
    let sports: Set<Sport>?
    /// Life stages in which the competition is open (mirrors `Hobby.stages`).
    let stages: Set<LifeStage>

    enum Discipline: String { case athletic = "Athletic", esports = "E-Sports" }

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

    /// 0...1 fit of the player's most-trained qualifying sport. Returns 0 for
    /// open competitions (sport-agnostic events) and for players who don't
    /// practice any qualifying sport.
    func sportFit(for sportYears: [Sport: Int]) -> Double {
        guard let sports else { return 0 }
        let best = sports.compactMap { sportYears[$0] }.max() ?? 0
        return min(Double(best) / Double(Competition.sportReference), 1.0)
    }

    /// Probability (0.05...0.85) of winning this year. Skill fit is the lead
    /// driver; years in a qualifying sport add an additive bonus that tops out
    /// once the player is a seasoned competitor in the discipline.
    func winProbability(for soft: SoftSkills, sportYears: [Sport: Int]) -> Double {
        let skillTerm = skillFit(for: soft) * 0.60
        let sportTerm = sportFit(for: sportYears) * 0.25
        return max(0.05, min(0.85, 0.05 + skillTerm + sportTerm))
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
            fameWeight: 0.5,
            skills: [\.resilienceAndEndurance, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            sports: [.running],
            stages: [.youngAdult, .adult]
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
            fameWeight: 1.0,
            skills: [\.resilienceAndEndurance, \.selfDisciplineAndPerseverance, \.stressResistanceAndEmotionalRegulation],
            sports: [.running],
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
            fameWeight: 2.0,
            skills: [\.resilienceAndEndurance, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance],
            sports: [.soccer, .basketball, .tennis, .martialArts],
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
            fameWeight: 3.0,
            skills: [\.resilienceAndEndurance, \.stressResistanceAndEmotionalRegulation, \.selfDisciplineAndPerseverance, \.visionaryThinkingAndAmbition],
            sports: [.running, .swimming, .cycling, .gymnastics, .martialArts],
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
            fameWeight: 0.5,
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.stressResistanceAndEmotionalRegulation],
            sports: [.esports],
            stages: [.youngAdult, .adult]
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
            fameWeight: 1.0,
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation],
            sports: [.esports],
            stages: [.youngAdult, .adult]
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
            fameWeight: 2.5,
            skills: [\.tinkeringAndFingerPrecision, \.analyticalReasoningAndProblemSolving, \.collaborationAndTeamwork, \.stressResistanceAndEmotionalRegulation, \.visionaryThinkingAndAmbition],
            sports: [.esports],
            stages: [.youngAdult, .adult]
        ),
    ]

    static let byId: [String: Competition] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
