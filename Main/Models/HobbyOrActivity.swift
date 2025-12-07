struct HobbyOrActivity {
    let label: String
    let abilityKeyPaths: [WritableKeyPath<SoftSkills, Int>]
}

let extraCurriculum: [HobbyOrActivity] = [
    HobbyOrActivity(
        label: "Sports and Athletics",
        abilityKeyPaths: [
            \.physicalStrength,
            \.resilienceAndEndurance,
            \.coordinationAndBalance,
            \.collaborationAndTeamwork
        ]
    ),
    HobbyOrActivity(
        label: "Scouting",
        abilityKeyPaths: [
            \.resilienceAndEndurance,
            \.perseveranceAndGrit,
            \.spacialNavigation,
            \.collaborationAndTeamwork,
            \.timeManagementAndPlanning
        ]
    ),

    HobbyOrActivity(
        label: "Music Band",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.tinkeringAndFingerPrecision,
            \.communicationAndNetworking,
            \.collaborationAndTeamwork,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    HobbyOrActivity(
        label: "Photography and Cinematography",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.communicationAndNetworking,
            \.carefulnessAndAttentionToDetail,
            \.presentationAndStorytelling
        ]
    ),
    HobbyOrActivity(
        label: "Drawing and Sketching",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.tinkeringAndFingerPrecision,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    HobbyOrActivity(
        label: "Theatre and Acting",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.perseveranceAndGrit,
            \.presentationAndStorytelling,
            \.adaptabilityAndLearningAgility
        ]
    ),

    HobbyOrActivity(
        label: "Chess and Strategy Games",
        abilityKeyPaths: [
            \.analyticalReasoningAndProblemSolving,
            \.carefulnessAndAttentionToDetail,
            \.perseveranceAndGrit
        ]
    ),
    HobbyOrActivity(
        label: "Coding",
        abilityKeyPaths: [
            \.analyticalReasoningAndProblemSolving,
            \.carefulnessAndAttentionToDetail,
            \.perseveranceAndGrit,
            \.selfDisciplineAndStudyHabits
        ]
    ),

    HobbyOrActivity(
        label: "Journalism, Blogging, Podcasting",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.leadershipAndInfluence,
            \.communicationAndNetworking,
            \.presentationAndStorytelling
        ]
    ),
    HobbyOrActivity(
        label: "Hanging out with friends",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.emotionalIntelligence
        ]
    ),
    HobbyOrActivity(
        label: "Organizing events, Fundraising",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.leadershipAndInfluence,
            \.perseveranceAndGrit,
            \.courageAndRiskTolerance,
            \.timeManagementAndPlanning,
            \.collaborationAndTeamwork
        ]
    ),


    HobbyOrActivity(
        label: "Cooking and Baking",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.carefulnessAndAttentionToDetail,
            \.tinkeringAndFingerPrecision,
            \.perseveranceAndGrit,
            \.timeManagementAndPlanning
        ]
    ),
    HobbyOrActivity(
        label: "Dance",
        abilityKeyPaths: [
            \.coordinationAndBalance,
            \.resilienceAndEndurance,
            \.creativityAndInsightfulThinking,
            \.selfDisciplineAndStudyHabits
        ]
    ),

    HobbyOrActivity(
        label: "Language Learning",
        abilityKeyPaths: [
            \.perseveranceAndGrit,
            \.communicationAndNetworking,
            \.analyticalReasoningAndProblemSolving,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    HobbyOrActivity(
        label: "3D Puzzles and Model Building",
        abilityKeyPaths: [
            \.spacialNavigation,
            \.tinkeringAndFingerPrecision,
            \.carefulnessAndAttentionToDetail
        ]
    ),
    HobbyOrActivity(
        label: "Reading books",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.analyticalReasoningAndProblemSolving,
            \.perseveranceAndGrit,
            \.presentationAndStorytelling
        ]
    )
]
