struct WeightedAbility {
    let keyPath: WritableKeyPath<SoftSkills, Int>
    let weight: Int
}

struct Activity {
    let label: String
    let abilities: [WeightedAbility]
}

// Activities the player can pick each year. Pared to extracurriculars typically
// available in US public middle/high schools — sports, arts, academic teams,
// student government — so a player's options match what a real teen would face.
let activities: [Activity] = [

    // Physical
    Activity(
        label: "Sports and Athletics",
        abilities: [
            .init(keyPath: \.resilienceAndEndurance, weight: 2),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ]
    ),
    Activity(
        label: "Dancing and Choreography",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ]
    ),

    // Performing arts / creative
    Activity(
        label: "Music Playing and Composing",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ]
    ),
    Activity(
        label: "Drawing and Sketching",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ]
    ),
    Activity(
        label: "Theatre and Acting",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 2)
        ]
    ),
    Activity(
        label: "Photography and Cinematography",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ]
    ),
    Activity(
        label: "Journalism, Blogging, Podcasting",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ]
    ),

    // Academic / analytical
    Activity(
        label: "Chess and Strategy Games",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ]
    ),
    Activity(
        label: "Coding and Programming",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
        ]
    ),
    Activity(
        label: "Robotics Club",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ]
    ),
    Activity(
        label: "Math Olympiad",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ]
    ),
    Activity(
        label: "Science Fair",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ]
    ),
    Activity(
        label: "Language Learning",
        abilities: [
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)
        ]
    ),
    Activity(
        label: "Reading Books",
        abilities: [
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ]
    ),

    // Social / leadership
    Activity(
        label: "Debate Club",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)
        ]
    ),
    Activity(
        label: "Student Council / Leadership",
        abilities: [
            .init(keyPath: \.leadershipAndInfluence, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ]
    ),
    Activity(
        label: "Model UN",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 2),
            .init(keyPath: \.leadershipAndInfluence, weight: 1)
        ]
    ),
    Activity(
        label: "Hanging Out with Friends",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ]
    )
]
