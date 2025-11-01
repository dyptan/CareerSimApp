import Foundation

struct Job: Identifiable, Codable, Hashable {
    // luck: 0 = Low-paid, poor working conditions, "desperation jobs"
    // luck: 1 = Mainstream, steady jobs (nurse, teacher, technician, etc)
    // luck: 2 = Highly competitive/fast-growing, but broadly accessible (tech, design, entry data, etc)
    // luck: 3 = Rare, niche, or out-of-date professions
    // luck: 4 = Elite, prestigious, extremely selective (investment banker, ceo, etc)
    // luck: 5 = High risk/high reward (influencer, celebrity, eSports, etc)
    //
    // education: 0 = EQF 1 (No formal education / basic skills)
    // education: 1 = EQF 2 (Primary school)
    // education: 2 = EQF 3 (Lower secondary)
    // education: 3 = EQF 4 (Upper secondary, high school, apprenticeship)
    // education: 4 = EQF 5 (Short-cycle tertiary or advanced vocational)
    // education: 5 = EQF 6 (Bachelor's degree or equivalent)
    // education: 6 = EQF 7 (Master's degree or equivalent)
    // education: 7 = EQF 8 (Doctorate or equivalent)
    //
    // cognitive/physical requirement levels (0–5):
    //   0 = Not needed
    //   1 = Minimal/basic
    //   2 = Somewhat helpful
    //   3 = Clearly useful/moderate
    //   4 = Important/high
    //   5 = Essential/critical for success
    let id: String
    let category: Category
    let income: Int
    func reward() -> String {
        switch income {
        case 0...60: return "💵"
        case 61..<120: return "💵💵"
        default: return "💵💵💵"
        }
    }
    let prestige: Int
    let summary: String
    let icon: String
    let requirements: Requirements
    let version: Int
    
    struct Requirements: Codable, Hashable {
        let education: Int
        let cognitive: Cognitive
        let physical: Physical
        
        struct Cognitive: Codable, Hashable {
            let analyticalReasoning: Int?
            let creativeExpression: Int?
            let socialCommunication: Int?
            let teamLeadership: Int?
            let influenceAndNetworking: Int?
            let riskTolerance: Int?
            let spatialThinking: Int?
            let attentionToDetail: Int?
            let resilienceCognitive: Int?
        }
        
        struct Physical: Codable, Hashable {
            let mechanicalOperation: Int?
            let physicalAbility: Int?
            let outdoorOrientation: Int?
            let resiliencePhysical: Int?
            let endurance: Int?
        }
        
        var analyticalReasoning: Int { cognitive.analyticalReasoning ?? 0 }
        var creativeExpression: Int { cognitive.creativeExpression ?? 0 }
        var socialCommunication: Int { cognitive.socialCommunication ?? 0 }
        var teamLeadership: Int { cognitive.teamLeadership ?? 0 }
        var influenceAndNetworking: Int { cognitive.influenceAndNetworking ?? 0 }
        var riskTolerance: Int { cognitive.riskTolerance ?? 0 }
        var spatialThinking: Int { cognitive.spatialThinking ?? 0 }
        var attentionToDetail: Int { cognitive.attentionToDetail ?? 0 }
        var resilienceCognitive: Int { cognitive.resilienceCognitive ?? 0 }
        
        var mechanicalOperation: Int { physical.mechanicalOperation ?? 0 }
        var physicalAbility: Int { physical.physicalAbility ?? 0 }
        var outdoorOrientation: Int { physical.outdoorOrientation ?? 0 }
        var resiliencePhysical: Int { physical.resiliencePhysical ?? 0 }
        var endurance: Int { physical.endurance ?? 0 }
        
        func educationLabel() -> String {
            // Map EQF-ish scale used in this model to human-friendly education tiers.
            switch education {
            case ..<1: return "Primary school"
            case 1: return "Primary school"
            case 2: return "Middle school"
            case 3: return "High school"
            case 4: return "College / Vocational"
            case 5: return "University — Bachelor’s"
            case 6: return "University — Master’s"
            case 7: return "Doctorate"
            default: return "Doctorate+"
            }
        }
    }
}

var jobExample = Job(
    id: "superman",
    category: .agriculture,
    income: 10000,
    prestige: 5,
    summary: "sdf",
    icon: "🦸",
    requirements: Job.Requirements(
        education: 0,
        cognitive: Job.Requirements.Cognitive(
            analyticalReasoning: 2,
            creativeExpression: 3,
            socialCommunication: 4,
            teamLeadership: 5,
            influenceAndNetworking: 5,
            riskTolerance: 6,
            spatialThinking: 7,
            attentionToDetail: 8,
            resilienceCognitive: 5
        ),
        physical: Job.Requirements.Physical(
            mechanicalOperation: nil,
            physicalAbility: nil,
            outdoorOrientation: nil,
            resiliencePhysical: nil,
            endurance: nil
        )
    ),
    version: 1
)
