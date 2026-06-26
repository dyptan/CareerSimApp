struct WeightedAbility {
    let keyPath: WritableKeyPath<SoftSkills, Int>
    let weight: Int
}

// Age-driven life stages that gate which activities a player can pick.
// Tagged on each Activity; ActivitiesView filters the catalogue by the
// player's current stage.
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

struct Activity {
    let label: String
    let abilities: [WeightedAbility]
    /// Stages in which this activity is offered. Most options are stage-specific
    /// (Math Olympiad only in school, Networking Events only after college),
    /// but a few classics (Reading Books, Sports) span the whole life.
    let stages: Set<LifeStage>
}

// Master catalogue. ActivitiesView filters by `LifeStage.forAge(player.age)`
// so a 7-year-old sees playground games while a 30-year-old sees networking
// events and gym sessions.
let activities: [Activity] = [

    // MARK: - Childhood-specific (7–10)

    Activity(
        label: "Playground & Outdoor Games",
        abilities: [
            .init(keyPath: \.resilienceAndEndurance, weight: 2),
            .init(keyPath: \.outdoorAndWeatherResilience, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ],
        stages: [.child]
    ),
    Activity(
        label: "Building Blocks & LEGO",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
            .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.child]
    ),
    Activity(
        label: "Pretend Play & Make-Believe",
        abilities: [
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
            .init(keyPath: \.presentationAndStorytelling, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1)
        ],
        stages: [.child]
    ),
    Activity(
        label: "Helping Around the House",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1)
        ],
        stages: [.child]
    ),
    Activity(
        label: "Family Board Games",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ],
        stages: [.child]
    ),
    Activity(
        label: "Pet Care",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.resilienceAndEndurance, weight: 1)
        ],
        stages: [.child]
    ),

    // MARK: - Physical (mostly all-stage)

    Activity(
        label: "Sports and Athletics",
        abilities: [
            .init(keyPath: \.resilienceAndEndurance, weight: 2),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Dancing and Choreography",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),

    // MARK: - Performing arts / creative

    Activity(
        label: "Music Playing and Composing",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Drawing and Sketching",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Theatre and Acting",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 2)
        ],
        stages: [.teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Photography and Cinematography",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Journalism, Blogging, Podcasting",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult]
    ),

    // MARK: - Academic / analytical

    Activity(
        label: "Chess and Strategy Games",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Coding and Programming",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Robotics Club",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ],
        stages: [.teen, .youngAdult]
    ),
    Activity(
        label: "Math Olympiad",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ],
        stages: [.child, .teen]
    ),
    Activity(
        label: "Science Fair",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.child, .teen]
    ),
    Activity(
        label: "Language Learning",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Reading Books",
        abilities: [
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),

    // MARK: - Social / leadership (school-era)

    Activity(
        label: "Debate Club",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.persuasionAndNegotiation, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1)
        ],
        stages: [.teen, .youngAdult]
    ),
    Activity(
        label: "Student Council / Leadership",
        abilities: [
            .init(keyPath: \.leadershipAndInfluence, weight: 2),
            .init(keyPath: \.persuasionAndNegotiation, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.teen, .youngAdult]
    ),
    Activity(
        label: "Model UN",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 2),
            .init(keyPath: \.persuasionAndNegotiation, weight: 1),
            .init(keyPath: \.leadershipAndInfluence, weight: 1)
        ],
        stages: [.teen, .youngAdult]
    ),
    Activity(
        label: "Lemonade Stand & Selling",
        abilities: [
            .init(keyPath: \.persuasionAndNegotiation, weight: 2),
            .init(keyPath: \.riskTakingAndInitiative, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1)
        ],
        stages: [.child, .teen]
    ),
    Activity(
        label: "Hanging Out with Friends",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ],
        stages: [.child, .teen, .youngAdult, .adult]
    ),

    // MARK: - Young Adult & Working Life

    Activity(
        label: "Gym & Personal Fitness",
        abilities: [
            .init(keyPath: \.resilienceAndEndurance, weight: 2),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ],
        stages: [.youngAdult, .adult]
    ),
    Activity(
        label: "Yoga & Meditation",
        abilities: [
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 2),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.resilienceAndEndurance, weight: 1)
        ],
        stages: [.youngAdult, .adult]
    ),
    Activity(
        label: "Professional Networking Events",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 2),
            .init(keyPath: \.persuasionAndNegotiation, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.youngAdult, .adult]
    ),
    Activity(
        label: "Conference Attendance",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.visionaryThinkingAndAmbition, weight: 2),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.youngAdult, .adult]
    ),
    Activity(
        label: "Side Project / Freelance Gig",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
            .init(keyPath: \.riskTakingAndInitiative, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)
        ],
        stages: [.youngAdult, .adult]
    ),
    Activity(
        label: "Mentoring Juniors",
        abilities: [
            .init(keyPath: \.leadershipAndInfluence, weight: 2),
            .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1)
        ],
        stages: [.adult]
    ),
    Activity(
        label: "Volunteering in the Community",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ],
        stages: [.youngAdult, .adult]
    ),
    Activity(
        label: "Babysitting & Caregiving",
        abilities: [
            .init(keyPath: \.empathyAndInterpersonalCare, weight: 2),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.resilienceAndEndurance, weight: 1)
        ],
        stages: [.teen, .youngAdult]
    ),
    Activity(
        label: "Personal Finance & Investing",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1)
        ],
        stages: [.youngAdult, .adult]
    ),
    Activity(
        label: "Parenting",
        abilities: [
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 2),
            .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.resilienceAndEndurance, weight: 1)
        ],
        stages: [.adult]
    ),
    Activity(
        label: "Travelling Abroad",
        abilities: [
            .init(keyPath: \.outdoorAndWeatherResilience, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.youngAdult, .adult]
    ),
    Activity(
        label: "Cooking & Culinary Arts",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.teen, .youngAdult, .adult]
    ),
    Activity(
        label: "Home DIY & Repairs",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
            .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ],
        stages: [.adult]
    )
]
