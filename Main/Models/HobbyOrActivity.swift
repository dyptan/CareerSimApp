struct HobbyOrActivity {
    let label: String
    let abilityKeyPaths: [WritableKeyPath<SoftSkills, Int>]
}

let extraCurriculum: [HobbyOrActivity] = [
    HobbyOrActivity(
        label: "Sports",
        abilityKeyPaths: [\.physicalStrength, \.resilienceAndEndurance, \.coordinationAndBalance]
    ),
    HobbyOrActivity(
        label: "Scouting",
        abilityKeyPaths: [\.resilienceAndEndurance, \.perseveranceAndGrit, \.spacialNavigation]
    ),
    HobbyOrActivity(
        label: "Music Band",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision]
    ),
    HobbyOrActivity(
        label: "Photography and Videography",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.communicationAndNetworking]
    ),
    HobbyOrActivity(
        label: "Drawing and Sketching",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.tinkeringAndFingerPrecision]
    ),
    HobbyOrActivity(
        label: "Chess",
        abilityKeyPaths: [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail]
    ),
    HobbyOrActivity(
        label: "Hobby journalism",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.leadershipAndInfluence, \.communicationAndNetworking]
    ),
    HobbyOrActivity(
        label: "Astronomy",
        abilityKeyPaths: [\.creativityAndInsightfulThinking, \.perseveranceAndGrit]
    ),
    HobbyOrActivity(
        label: "Turn based gaming",
        abilityKeyPaths: [\.analyticalReasoningAndProblemSolving]
    ),
    HobbyOrActivity(
        label: "Hanging out with friends",
        abilityKeyPaths: [\.communicationAndNetworking]
    ),
    HobbyOrActivity(
        label: "Student Council",
        abilityKeyPaths: [\.leadershipAndInfluence, \.communicationAndNetworking]
    ),
    HobbyOrActivity(
        label: "Organizing Events",
        abilityKeyPaths: [\.leadershipAndInfluence, \.perseveranceAndGrit]
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
        label: "Volunteering & Fundraising",
        abilityKeyPaths: [\.communicationAndNetworking, \.leadershipAndInfluence, \.perseveranceAndGrit, \.courageAndRiskTolerance]
    )
]
