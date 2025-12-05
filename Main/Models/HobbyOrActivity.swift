struct HobbyOrActivity {
    let label: String
    let abilityKeyPaths: [WritableKeyPath<SoftSkills, Int>]
}

let extraCurriculum: [HobbyOrActivity] = [
    // Physical / team play
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

    // Creative / performing arts
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

    // Analytical / academic
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

    // Communication / leadership / social
    HobbyOrActivity(
        label: "Journalism and Writing",
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

    // Hands-on / crafts
    HobbyOrActivity(
        label: "Modeling",
        abilityKeyPaths: [
            \.tinkeringAndFingerPrecision,
            \.perseveranceAndGrit,
            \.carefulnessAndAttentionToDetail
        ]
    ),
    HobbyOrActivity(
        label: "Crafting, Knitting, and Sewing",
        abilityKeyPaths: [
            \.tinkeringAndFingerPrecision,
            \.carefulnessAndAttentionToDetail,
            \.perseveranceAndGrit,
            \.selfDisciplineAndStudyHabits
        ]
    ),

    // Lifestyle / wellness
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
        label: "Dress-Up and DIY Accessories",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.carefulnessAndAttentionToDetail,
            \.tinkeringAndFingerPrecision
        ]
    ),
    HobbyOrActivity(
        label: "Gardening",
        abilityKeyPaths: [
            \.perseveranceAndGrit,
            \.carefulnessAndAttentionToDetail,
            \.spacialNavigation,
            \.timeManagementAndPlanning
        ]
    ),

    // Language / teaching
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
        label: "Teaching and Tutoring",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.leadershipAndInfluence,
            \.carefulnessAndAttentionToDetail,
            \.presentationAndStorytelling,
            \.emotionalIntelligence
        ]
    ),

    // Service / community
    HobbyOrActivity(
        label: "Volunteering and Community Service",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.leadershipAndInfluence,
            \.perseveranceAndGrit,
            \.emotionalIntelligence,
            \.collaborationAndTeamwork
        ]
    ),

    // Media / content
    HobbyOrActivity(
        label: "Blogging and Content Creation",
        abilityKeyPaths: [
            \.creativityAndInsightfulThinking,
            \.communicationAndNetworking,
            \.perseveranceAndGrit,
            \.presentationAndStorytelling
        ]
    ),

    // New: school-age skills centric
    HobbyOrActivity(
        label: "Public Speaking Club",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.leadershipAndInfluence,
            \.perseveranceAndGrit,
            \.presentationAndStorytelling
        ]
    ),
    HobbyOrActivity(
        label: "Debate Club",
        abilityKeyPaths: [
            \.analyticalReasoningAndProblemSolving,
            \.communicationAndNetworking,
            \.courageAndRiskTolerance,
            \.presentationAndStorytelling
        ]
    ),
    HobbyOrActivity(
        label: "Science Club",
        abilityKeyPaths: [
            \.analyticalReasoningAndProblemSolving,
            \.carefulnessAndAttentionToDetail,
            \.perseveranceAndGrit,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    HobbyOrActivity(
        label: "Math Puzzles and Logic Games",
        abilityKeyPaths: [
            \.analyticalReasoningAndProblemSolving,
            \.perseveranceAndGrit,
            \.carefulnessAndAttentionToDetail
        ]
    ),
    HobbyOrActivity(
        label: "Robotics / LEGO Engineering",
        abilityKeyPaths: [
            \.tinkeringAndFingerPrecision,
            \.analyticalReasoningAndProblemSolving,
            \.perseveranceAndGrit,
            \.collaborationAndTeamwork
        ]
    ),
    HobbyOrActivity(
        label: "Coding Club (Kids)",
        abilityKeyPaths: [
            \.analyticalReasoningAndProblemSolving,
            \.carefulnessAndAttentionToDetail,
            \.perseveranceAndGrit,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    HobbyOrActivity(
        label: "School Newspaper",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.creativityAndInsightfulThinking,
            \.leadershipAndInfluence,
            \.timeManagementAndPlanning
        ]
    ),
    HobbyOrActivity(
        label: "Student Council / Class Helper",
        abilityKeyPaths: [
            \.leadershipAndInfluence,
            \.communicationAndNetworking,
            \.courageAndRiskTolerance,
            \.collaborationAndTeamwork
        ]
    ),
    HobbyOrActivity(
        label: "Entrepreneurship Fair / Lemonade Stand",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.courageAndRiskTolerance,
            \.leadershipAndInfluence,
            \.timeManagementAndPlanning
        ]
    ),
    HobbyOrActivity(
        label: "First Aid Basics (Kids)",
        abilityKeyPaths: [
            \.carefulnessAndAttentionToDetail,
            \.resilienceAndEndurance,
            \.courageAndRiskTolerance,
            \.emotionalIntelligence
        ]
    ),
    HobbyOrActivity(
        label: "Nature Hikes and Orienteering",
        abilityKeyPaths: [
            \.spacialNavigation,
            \.resilienceAndEndurance,
            \.perseveranceAndGrit,
            \.timeManagementAndPlanning
        ]
    ),
    HobbyOrActivity(
        label: "Instrument Practice",
        abilityKeyPaths: [
            \.perseveranceAndGrit,
            \.tinkeringAndFingerPrecision,
            \.creativityAndInsightfulThinking,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    HobbyOrActivity(
        label: "Choir / Singing Group",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.creativityAndInsightfulThinking,
            \.perseveranceAndGrit,
            \.collaborationAndTeamwork
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
        label: "Book Club / Reading Circle",
        abilityKeyPaths: [
            \.communicationAndNetworking,
            \.analyticalReasoningAndProblemSolving,
            \.perseveranceAndGrit,
            \.presentationAndStorytelling
        ]
    ),
    HobbyOrActivity(
        label: "Show & Tell / Storytelling",
        abilityKeyPaths: [
            \.presentationAndStorytelling,
            \.communicationAndNetworking,
            \.selfDisciplineAndStudyHabits
        ]
    ),
    HobbyOrActivity(
        label: "Group Projects Club",
        abilityKeyPaths: [
            \.collaborationAndTeamwork,
            \.timeManagementAndPlanning,
            \.presentationAndStorytelling
        ]
    ),
    HobbyOrActivity(
        label: "Study Planner / Homework Club",
        abilityKeyPaths: [
            \.timeManagementAndPlanning,
            \.selfDisciplineAndStudyHabits,
            \.perseveranceAndGrit
        ]
    ),
    HobbyOrActivity(
        label: "Improv Games / Drama Games",
        abilityKeyPaths: [
            \.adaptabilityAndLearningAgility,
            \.presentationAndStorytelling,
            \.courageAndRiskTolerance
        ]
    ),
    HobbyOrActivity(
        label: "Peer Mentoring / Buddy Helper",
        abilityKeyPaths: [
            \.emotionalIntelligence,
            \.collaborationAndTeamwork,
            \.communicationAndNetworking
        ]
    )
]
