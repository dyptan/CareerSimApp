import Foundation

enum Certification: String, CaseIterable, Codable, Hashable, Identifiable {
    case aws = "AWS"
    case azure = "Azure"
    case google = "Google"
    case scrum = "Scrum"
    case security = "Security"
    case cwi = "CWI"
    case epa608 = "EPA608"
    case nate = "NATE"
    case faaAMP = "FAA A&P"
    case cna = "CNA"
    case dentalAssistant = "Dental Assistant"
    case medicalAssistant = "Medical Assistant"
    case pharmacyTech = "Pharmacy Tech"
    case cfp = "CFP"
    case series65 = "Series 65"
    case flightAttendantCert = "Flight Attendant"

    var id: String { rawValue }

    var friendlyName: String {
        switch self {
        case .aws: return "AWS Certification"
        case .azure: return "Azure Certification"
        case .google: return "Google Cloud Certification"
        case .scrum: return "Scrum Master"
        case .security: return "Security Awareness"
        case .cwi: return "Certified Welding Inspector"
        case .epa608: return "EPA 608"
        case .nate: return "NATE Certification"
        case .faaAMP: return "FAA A&P"
        case .cna: return "Certified Nursing Assistant"
        case .dentalAssistant: return "Dental Assistant"
        case .medicalAssistant: return "Medical Assistant"
        case .pharmacyTech: return "Pharmacy Technician"
        case .cfp: return "Certified Financial Planner"
        case .series65: return "Series 65"
        case .flightAttendantCert: return "Flight Attendant Certificate"
        }
    }

    var pictogram: String {
        switch self {
        case .aws, .azure, .google: return "☁️"
        case .scrum: return "📈"
        case .security: return "🔐"
        case .cwi: return "⚙️"
        case .epa608: return "🌬️"
        case .nate: return "🧰"
        case .faaAMP: return "✈️"
        case .cna: return "🏥"
        case .dentalAssistant: return "🦷"
        case .medicalAssistant: return "🩺"
        case .pharmacyTech: return "💊"
        case .cfp: return "💼"
        case .series65: return "📜"
        case .flightAttendantCert: return "🧳"
        }
    }
}
