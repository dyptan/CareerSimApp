struct WeightedAbility {
    let keyPath: WritableKeyPath<SoftSkills, Int>
    let weight: Int
}

// Age-driven life stages that gate which hobbies a player can pick.
// Tagged on each Hobby; HobbiesView filters the catalogue by the
// player's current stage. (Paid professional networking — summits,
// conferences — lives separately in `Event` / `EventCatalog`.)
enum LifeStage: String, CaseIterable, Hashable {
    case child       // 7–10  (primary school)
    case teen        // 11–17 (middle / high school)
    case youngAdult  // 18–24 (college, early career)
    case adult       // 25+   (working life)

    /// Bracket the given in-game age into a stage.
    static func forAge(_ age: Int) -> LifeStage {
        switch age {
        case ..<11: return .child
        case 11...17: return .teen
        case 18...24: return .youngAdult
        default: return .adult
        }
    }

    var displayName: String {
        switch self {
        case .child: return "Childhood"
        case .teen: return "Teen Years"
        case .youngAdult: return "Young Adult"
        case .adult: return "Working Life"
        }
    }
}

struct Hobby {
    let label: String
    let abilities: [WeightedAbility]
    /// Stages in which this hobby is offered. Most options are stage-specific
    /// (Math Olympiad only in school), but a few classics (Reading Books,
    /// Sports) span the whole life.
    let stages: Set<LifeStage>
    /// Gear-heavy or class-marker hobbies (private music lessons + instruments,
    /// camera gear) that only appear in `.comfortable` ("Relaxed", well-off
    /// family) runs. `HobbiesView` hides them on every other difficulty.
    var isElite: Bool = false
}

// Master catalogue. A hobby reliably builds soft skills — those skills in turn
// unlock the spare-time ventures in the Projects menu (see `SideHustle`).
// Athletic pursuits live elsewhere (Sports dialog) and professional networking
// is handled by `Event`. Stage
// filtering is unchanged: HobbiesView shows the subset whose `stages` includes
// `LifeStage.forAge(player.age)`.
let hobbies: [Hobby] = [

    // MARK: - Creative output

    Hobby(
        label: "Playing music instrument",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    // Builds the eye and craft for creative competitions (see CompetitionCatalog).
    Hobby(
        label: "Drawing and Sketching",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    // Builds the eye and craft for creative competitions (see CompetitionCatalog).
    Hobby(
        label: "Photography",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Hobby(
        label: "Cooking",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Hobby(
        label: "Diary Writing",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Hobby(
        label: "Journalism",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult]
    ),

    // MARK: - Technical / analytical output

    Hobby(
        label: "Coding and Programming",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult]
    ),
    Hobby(
        label: "3D Modelling",
        abilities: [
            .init(keyPath: \.spacialNavigationAndOrientation, weight: 2),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult]
    ),

    // MARK: - Movement & play

    // Builds toward dance competitions and showcases (see CompetitionCatalog).
    Hobby(
        label: "Dancing",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.resilienceAndEndurance, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    // Physical street activity — balance, coordination, and composure under the
    // risk of a spill. A pure soft-skill builder.
    Hobby(
        label: "Urban Leisure (Skating, BMX)",
        abilities: [
            .init(keyPath: \.spacialNavigationAndOrientation, weight: 2),
            .init(keyPath: \.resilienceAndEndurance, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.outdoorAndWeatherResilience, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    // A pure soft-skill builder — sharpens strategy and table manners, but has
    // no matching portfolio project.
    Hobby(
        label: "Board Games",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),

    // MARK: - Learning & leisure

    // Builds toward craft fairs and maker competitions (see CompetitionCatalog).
    Hobby(
        label: "Hand Crafting",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    // Pure soft-skill builders — no matching portfolio project.
    Hobby(
        label: "Language Learning",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 2),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Hobby(
        label: "Watching Educational TV",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Hobby(
        label: "Playing Simulator Games",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    )
]

