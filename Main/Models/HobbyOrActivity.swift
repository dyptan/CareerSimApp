struct HobbyOrActivity {
    let label: String
    let abilityKeyPaths: [WritableKeyPath<SoftSkills, Int>]
}

let extraCurriculum: [HobbyOrActivity] = [
    HobbyOrActivity(
        label: "Sports and Athletics",
        abilityKeyPaths: [\.physicalStrength, \.resilienceAndEndurance, \.coordinationAndBalance]
    ),
    HobbyOrActivity(
        label: "Scouting",
        abilityKeyPaths: [\.resilienceAndEndurance, \.perseveranceAndGrit, \.spacialNavigation]
    ),
    HobbyOrActivity(
        label: "Music Band",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision, \.communicationAndNetworking]
    ),
    HobbyOrActivity(
        label: "Photography and Cinematography",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.communicationAndNetworking]
    ),
    HobbyOrActivity(
        label: "Drawing and Sketching",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision]
    ),
    HobbyOrActivity(
        label: "Chess and Strategy Games",
        abilityKeyPaths: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail]
    ),
    HobbyOrActivity(
        label: "Journalism and Writing",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.leadershipAndInfluence]
    ),
    HobbyOrActivity(
        label: "Theatre and Acting",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.perseveranceAndGrit]
    ),
    HobbyOrActivity(
        label: "Hanging out with friends",
        abilityKeyPaths: [\.communicationAndNetworking]
    ),
    HobbyOrActivity(
        label: "Modeling",
        abilityKeyPaths: [\.tinkeringAndFingerPrecision, \.perseveranceAndGrit]
    ),
    HobbyOrActivity(
        label: "Coding",
        abilityKeyPaths: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.perseveranceAndGrit]
    ),
    HobbyOrActivity(
        label: "Organizing events, Fundraising",
        abilityKeyPaths: [\.communicationAndNetworking, \.leadershipAndInfluence, \.perseveranceAndGrit, \.courageAndRiskTolerance]
    )
]
