struct Activity {
    let label: String
    let abilityKeyPaths: [WritableKeyPath<SoftSkills, Int>]
}

let activities: [Activity] = [
    Activity(
        label: "Sports and Athletics",
        abilityKeyPaths: [
            \.physicalStrength,
            \.resilienceAndEndurance,
            \.coordinationAndBalance,
            \.collaborationAndTeamwork
        ]
    ),
    Activity(
        label: "Scouting and hiking",
        abilityKeyPaths: [
            \.resilienceAndEndurance,
            \.perseveranceAndGrit,
            \.spacialNavigation,
            \.collaborationAndTeamwork,
            \.timeManagementAndPlanning
        ]
    ),

    Activity(
        label: "Music playing and composing",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.tinkeringAndFingerPrecision,
            \.communicationAndNetworking,
            \.collaborationAndTeamwork,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    Activity(
        label: "Photography and Cinematography",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.communicationAndNetworking,
            \.carefulnessAndAttentionToDetail,
            \.presentationAndStorytelling
        ]
    ),
    Activity(
        label: "Drawing and Sketching",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.tinkeringAndFingerPrecision,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    Activity(
        label: "Theatre and Acting",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.perseveranceAndGrit,
            \.presentationAndStorytelling,
            \.adaptabilityAndLearningAgility
        ]
    ),

    Activity(
        label: "Chess and Strategy Games",
        abilityKeyPaths: [
            \.analyticalReasoningAndProblemSolving,
            \.carefulnessAndAttentionToDetail,
            \.perseveranceAndGrit
        ]
    ),
    Activity(
        label: "Coding and Programming",
        abilityKeyPaths: [
            \.analyticalReasoningAndProblemSolving,
            \.carefulnessAndAttentionToDetail,
            \.perseveranceAndGrit,
            \.selfDisciplineAndStudyHabits
        ]
    ),

    Activity(
        label: "Journalism, Blogging, Podcasting",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.leadershipAndInfluence,
            \.communicationAndNetworking,
            \.presentationAndStorytelling
        ]
    ),
    Activity(
        label: "Hanging out with friends",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.emotionalIntelligence
        ]
    ),
    Activity(
        label: "Organizing events and fundraising",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.leadershipAndInfluence,
            \.perseveranceAndGrit,
            \.courageAndRiskTolerance,
            \.timeManagementAndPlanning,
            \.collaborationAndTeamwork
        ]
    ),

    Activity(
        label: "Cooking and baking",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.carefulnessAndAttentionToDetail,
            \.tinkeringAndFingerPrecision,
            \.perseveranceAndGrit,
            \.timeManagementAndPlanning
        ]
    ),
    Activity(
        label: "Dancing and choreography",
        abilityKeyPaths: [
            \.coordinationAndBalance,
            \.resilienceAndEndurance,
            \.creativityAndInsightfulThinking,
            \.selfDisciplineAndStudyHabits
        ]
    ),

    Activity(
        label: "Language Learning",
        abilityKeyPaths: [
            \.perseveranceAndGrit,
            \.communicationAndNetworking,
            \.analyticalReasoningAndProblemSolving,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    Activity(
        label: "3D Puzzles and Model Building",
        abilityKeyPaths: [
            \.spacialNavigation,
            \.tinkeringAndFingerPrecision,
            \.carefulnessAndAttentionToDetail
        ]
    ),
    Activity(
        label: "Reading books",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.analyticalReasoningAndProblemSolving,
            \.perseveranceAndGrit,
            \.presentationAndStorytelling
        ]
    )
]
