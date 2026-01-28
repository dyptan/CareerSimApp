struct WeightedAbility {
    let keyPath: WritableKeyPath<SoftSkills, Int>
    let weight: Int
}

struct Activity {
    let label: String
    let abilities: [WeightedAbility]
}

let activities: [Activity] = [
    Activity(
        label: "Sports and Athletics",
        abilities: [
            .init(keyPath: \.physicalStrengthAndEndurance, weight: 2),
            .init(keyPath: \.patienceAndPerseverance, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ]
    ),
    Activity(
        label: "Scouting and Hiking",
        abilities: [
            .init(keyPath: \.spacialNavigationAndOrientation, weight: 2),
            .init(keyPath: \.outdoorAndWeatherResilience, weight: 2),
            .init(keyPath: \.physicalStrengthAndEndurance, weight: 1),
            .init(keyPath: \.patienceAndPerseverance, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1)
        ]
    ),
    Activity(
        label: "Outdoor Volunteering and Conservation",
        abilities: [
            .init(keyPath: \.outdoorAndWeatherResilience, weight: 2),
            .init(keyPath: \.physicalStrengthAndEndurance, weight: 1),
            .init(keyPath: \.patienceAndPerseverance, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ]
    ),
    Activity(
        label: "Dancing and Choreography",
        abilities: [
            .init(keyPath: \.selfDisciplineAndStudyHabits, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ]
    ),

    Activity(
        label: "Music Playing and Composing",
        abilities: [
            .init(keyPath: \.selfDisciplineAndStudyHabits, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
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
        label: "Drawing and Sketching",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.patienceAndPerseverance, weight: 1)
        ]
    ),
    Activity(
        label: "Theatre and Acting",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.adaptabilityAndLearningAgility, weight: 1),
            .init(keyPath: \.patienceAndPerseverance, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ]
    ),
    Activity(
        label: "Debate Club",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.courageAndRiskTolerance, weight: 1)
        ]
    ),

    // Analytical / Academic
    Activity(
        label: "Chess and Strategy Games",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
            .init(keyPath: \.patienceAndPerseverance, weight: 1)
        ]
    ),
    Activity(
        label: "Coding and Programming",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.patienceAndPerseverance, weight: 1),
            .init(keyPath: \.selfDisciplineAndStudyHabits, weight: 1)
        ]
    ),
    Activity(
        label: "Robotics Club",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.patienceAndPerseverance, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ]
    ),
    Activity(
        label: "Language Learning",
        abilities: [
            .init(keyPath: \.selfDisciplineAndStudyHabits, weight: 2),
            .init(keyPath: \.patienceAndPerseverance, weight: 1),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)
        ]
    ),
    Activity(
        label: "3D Puzzles and Model Building",
        abilities: [
            .init(keyPath: \.spacialNavigationAndOrientation, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ]
    ),
    Activity(
        label: "Reading Books",
        abilities: [
            .init(keyPath: \.patienceAndPerseverance, weight: 1),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.selfDisciplineAndStudyHabits, weight: 1),
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
    Activity(
        label: "Hanging Out with Friends",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
        ]
    ),
    Activity(
        label: "Organizing Events and Fundraising",
        abilities: [
            .init(keyPath: \.leadershipAndInfluence, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1),
            .init(keyPath: \.courageAndRiskTolerance, weight: 1),
            .init(keyPath: \.patienceAndPerseverance, weight: 1)
        ]
    ),
    Activity(
        label: "Student Council / Leadership",
        abilities: [
            .init(keyPath: \.leadershipAndInfluence, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.adaptabilityAndLearningAgility, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ]
    ),
    Activity(
        label: "Public Speaking Club",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.courageAndRiskTolerance, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.leadershipAndInfluence, weight: 1)
        ]
    ),
    Activity(
        label: "Hackathon / Maker Fair",
        abilities: [
            .init(keyPath: \.adaptabilityAndLearningAgility, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1)
        ]
    ),
    Activity(
        label: "Emergency Preparedness Training",
        abilities: [
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 2),
            .init(keyPath: \.outdoorAndWeatherResilience, weight: 2),
            .init(keyPath: \.courageAndRiskTolerance, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1)
        ]
    ),

    Activity(
        label: "Cooking and Baking",
        abilities: [
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
            .init(keyPath: \.timeManagementAndPlanning, weight: 2),
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
            .init(keyPath: \.patienceAndPerseverance, weight: 1)
        ]
    )
]
