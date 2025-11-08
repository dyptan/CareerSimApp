import Foundation

struct Job: Identifiable, Codable, Hashable {
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
