import Foundation

enum License: String, CaseIterable, Codable, Hashable, Identifiable {
    case drivers = "Driver's License"
    case cdl = "CDL"
    case pilot = "Pilot"
    case commercialPilot = "Commercial Pilot"
    case nurse = "Nurse License"
    case electrician = "Electrician License"
    case plumber = "Plumber License"
    case realEstateAgent = "Real Estate Agent"
    case insuranceAgent = "Insurance Agent"

    var id: String { rawValue }

    var friendlyName: String {
        switch self {
        case .drivers: return "Driver’s License"
        case .cdl: return "Commercial Driver’s License"
        case .pilot: return "Private Pilot License"
        case .commercialPilot: return "Commercial Pilot License"
        case .nurse: return "Nursing License"
        case .electrician: return "Electrician License"
        case .plumber: return "Plumber License"
        case .realEstateAgent: return "Real Estate Agent License"
        case .insuranceAgent: return "Insurance Agent License"
        }
    }

    var pictogram: String {
        switch self {
        case .drivers: return "🚗"
        case .cdl: return "🚚"
        case .pilot: return "🛩️"
        case .commercialPilot: return "✈️"
        case .nurse: return "🩺"
        case .electrician: return "⚡️"
        case .plumber: return "🔧"
        case .realEstateAgent: return "🏠"
        case .insuranceAgent: return "📄"
        }
    }
    
    var costForLicense: Int {
        switch self {
        case .drivers:
            // Driving school package + DMV fees + written/road test
            return 1200
        case .cdl:
            // CDL training program + exam fees
            return 4500
        case .pilot:
            // PPL: ground school + flight hours + checkride (very rough lower bound)
            return 12000
        case .commercialPilot:
            // Additional hours + checkride (very rough, incremental)
            return 20000
        case .nurse:
            // Licensing process costs; education is separate
            return 800
        case .electrician:
            // Course + exam + license application (excl. apprenticeship wages)
            return 1500
        case .plumber:
            // Course + exam + license application
            return 1500
        case .realEstateAgent:
            // Pre-licensing course + exam + license
            return 800
        case .insuranceAgent:
            // Pre-licensing course + exam + license
            return 600
        }
    }

    
    // Minimum EQF level (education) required before pursuing this license
    var minEQF: Int {
        switch self {
        case .nurse, .electrician, .plumber: return 4  // vocational trade training required
        default: return 0
        }
    }

    var softSkillThresholds: [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch self {
        case .drivers:
            // Basic road navigation + attention to traffic rules
            return [
                (\.spacialNavigationAndOrientation, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .cdl:
            // Large vehicle manoeuvring, HOS compliance, long-haul demands
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.stressResistanceAndEmotionalRegulation, 2),
                (\.resilienceAndEndurance, 2),
                (\.timeManagementAndPlanning, 2),
            ]
        case .pilot:
            // 3-D airspace navigation, pre-flight checklists, in-flight decisions
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .commercialPilot:
            // Higher standards than PPL; PIC authority and crew management added
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.leadershipAndInfluence, 2),
            ]
        case .nurse:
            // 12-hour shifts, physical patient care, high-stakes clinical decisions
            return [
                (\.communicationAndNetworking, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.resilienceAndEndurance, 3),
            ]
        case .electrician:
            // Circuit analysis, blueprint reading — wrong wiring can cause fire or death
            return [
                (\.tinkeringAndFingerPrecision, 4),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .plumber:
            // Pipe routing through structures, outdoor/crawlspace work, physical demands
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.spacialNavigationAndOrientation, 2),
                (\.resilienceAndEndurance, 2),
                (\.outdoorAndWeatherResilience, 1),
            ]
        case .realEstateAgent:
            // Showings, negotiation, market analysis
            return [
                (\.communicationAndNetworking, 3),
                (\.presentationAndStorytelling, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.leadershipAndInfluence, 2),
            ]
        case .insuranceAgent:
            // Client acquisition, coverage explanation, policy accuracy
            return [
                (\.communicationAndNetworking, 3),
                (\.presentationAndStorytelling, 2),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        }
    }

    func licenseRequirements(_ player: Player) -> TrainingRequirementResult {
        let age = player.age

        // Age checks
        switch self {
        case .drivers:
            if age < 16 { return .blocked(reason: "Requires age 16+") }
        case .cdl, .realEstateAgent, .insuranceAgent, .nurse, .electrician, .plumber:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        case .pilot:
            if age < 17 { return .blocked(reason: "Requires age 17+") }
        case .commercialPilot:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        }

        // Prerequisite license checks
        switch self {
        case .cdl:
            guard player.hardSkills.licenses.contains(.drivers) else {
                return .blocked(reason: "Requires Driver's License first")
            }
        case .commercialPilot:
            guard player.hardSkills.licenses.contains(.pilot) else {
                return .blocked(reason: "Requires Private Pilot License first")
            }
        default:
            break
        }

        // Education prerequisite
        let highestEQF = player.degrees.map(\.eqf).max() ?? 0
        if highestEQF < minEQF {
            let label = Education.Requirements(minEQF: minEQF).educationLabel()
            return .blocked(reason: "Requires \(label)")
        }

        // Soft skill checks
        for (kp, required) in softSkillThresholds {
            guard player.softSkills[keyPath: kp] >= required else {
                let name = SoftSkills.label(forKeyPath: kp) ?? "skill"
                return .blocked(reason: "Needs more \(name)")
            }
        }

        return .ok(cost: costForLicense)
    }

}
