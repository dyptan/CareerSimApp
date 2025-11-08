struct ExtraActivity {
    let label: String
    let abilityKeyPaths: [WritableKeyPath<SoftSkills, Int>]
}

let schoolActivities: [ExtraActivity] = [
    ExtraActivity(
        label: "Sports",
        abilityKeyPaths: [\.physicalAbility, \.riskTolerance, \.outdoorOrientation]
    ),
    ExtraActivity(
        label: "Music band",
        abilityKeyPaths: [\.creativeExpression, \.influenceAndNetworking]
    ),
    ExtraActivity(
        label: "Photography",
        abilityKeyPaths: [\.creativeExpression]
    ),
    ExtraActivity(
        label: "Chess",
        abilityKeyPaths: [\.attentionToDetail, \.analyticalReasoning, \.resilienceCognitive]
    ),
    ExtraActivity(
        label: "Literature",
        abilityKeyPaths: [\.attentionToDetail, \.analyticalReasoning, \.teamLeadership]
    ),
    ExtraActivity(
        label: "3D simulation gaming",
        abilityKeyPaths: [\.spatialThinking, \.mechanicalOperation]
    ),
    ExtraActivity(
        label: "Economic simulation gaming",
        abilityKeyPaths: [\.spatialThinking, \.mechanicalOperation]
    ),
    ExtraActivity(
        label: "Scouting",
        abilityKeyPaths: [\.resiliencePhysical, \.outdoorOrientation]
    ),
    ExtraActivity(
        label: "Hanging out with friends",
        abilityKeyPaths: [\.socialCommunication, \.influenceAndNetworking]
    ),
    ExtraActivity(
        label: "Modeling",
        abilityKeyPaths: [\.mechanicalOperation, \.creativeExpression, \.attentionToDetail]
    ),
    ExtraActivity(
        label: "Mini-job",
        abilityKeyPaths: [\.riskTolerance, \.teamLeadership]
    ),
    ExtraActivity(
        label: "Organizing events",
        abilityKeyPaths: [\.influenceAndNetworking, \.teamLeadership, \.socialCommunication]
    ),
    ExtraActivity(
        label: "Pop‑up Stand",
        abilityKeyPaths: [\.opportunityRecognition, \.socialCommunication, \.attentionToDetail]
    ),
    ExtraActivity(
        label: "Volunteering Fundraising",
        abilityKeyPaths: [\.opportunityRecognition, \.influenceAndNetworking, \.teamLeadership]
    ),
]
