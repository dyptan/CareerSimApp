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

    
    func licenseRequirements(_ player: Player) -> TrainingRequirementResult {
        let age = player.age
        switch self {
        case .drivers:
            if age < 16 { return .blocked(reason: "Requires age 16+") }
        case .cdl:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        case .pilot, .realEstateAgent, .insuranceAgent:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        case .commercialPilot:
            if age < 21 { return .blocked(reason: "Requires age 21+") }
        case .nurse, .electrician, .plumber:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        }


        return .ok(cost: costForLicense)
    }

}
