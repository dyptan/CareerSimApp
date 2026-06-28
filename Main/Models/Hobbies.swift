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
    /// The portfolio `Project`s this hobby unlocks. A project only appears in
    /// `ProjectsView` once the player has practised at least one hobby that
    /// unlocks it — you can't ship a photo portfolio without ever picking up
    /// photography. See `Project.unlocked(byPractisedHobbies:)`.
    var unlocks: [Project] = []
}

// Master catalogue. Curated to the rule that every hobby must have a clearly
// corresponding `Project` (portfolio piece) — practising the hobby builds
// toward the deliverable. Pure-experience pastimes (board games, travel) and
// athletic pursuits live elsewhere (Sports dialog). Professional networking
// is handled by `Event`. Stage filtering is unchanged: HobbiesView shows the
// subset whose `stages` includes `LifeStage.forAge(player.age)`.
let hobbies: [Hobby] = [

    // MARK: - Creative output

    // → musicAlbum
    // Elite: instruments and private lessons are out of reach for average
    // families.
    Hobby(
        label: "Music Playing and Composing",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult],
        isElite: true,
        unlocks: [.musicAlbum]
    ),
    // → paintingPortfolio
    Hobby(
        label: "Drawing and Sketching",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult],
        unlocks: [.paintingPortfolio]
    ),
    // → photoPortfolio
    // Elite: camera gear, lenses, and editing software add up fast.
    Hobby(
        label: "Photography and Cinematography",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult],
        isElite: true,
        unlocks: [.photoPortfolio]
    ),
    // → recipeBook
    Hobby(
        label: "Cooking & Culinary Arts",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult],
        unlocks: [.recipeBook]
    ),
    // → paper / website / presentation / lessonPlan
    Hobby(
        label: "Journalism, Blogging, Podcasting",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult],
        unlocks: [.paper, .website, .presentation, .lessonPlan]
    ),

    // MARK: - Technical / analytical output

    // → app / library / website
    Hobby(
        label: "Coding and Programming",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult],
        unlocks: [.app, .library, .website]
    )
]

extension Project {
    /// The set of projects unlocked by a player who has practised the hobbies in
    /// `practisedHobbies` (their labels). A project unlocks the moment the player
    /// has taken *any* hobby that lists it in `Hobby.unlocks` — practise the
    /// craft first, then you can turn it into a portfolio piece.
    static func unlocked(byPractisedHobbies practisedHobbies: Set<String>) -> Set<Project> {
        var result: Set<Project> = []
        for hobby in hobbies where practisedHobbies.contains(hobby.label) {
            result.formUnion(hobby.unlocks)
        }
        return result
    }
}
