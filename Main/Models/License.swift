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
}
