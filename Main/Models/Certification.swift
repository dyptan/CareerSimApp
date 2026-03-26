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

    var costForCertification: Int {
        switch self {
        case .aws: return 350
        case .azure: return 350
        case .google: return 300
        case .scrum: return 600
        case .security: return 250
        case .cwi: return 3000
        case .epa608: return 200
        case .nate: return 450
        case .faaAMP: return 6000
        case .cna: return 1500
        case .dentalAssistant: return 2500
        case .medicalAssistant: return 3500
        case .pharmacyTech: return 1200
        case .cfp: return 7000
        case .series65: return 500
        case .flightAttendantCert: return 1000
        }
    }

    var softSkillThresholds: [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch self {
        case .aws, .azure, .google:
            return [(\.analyticalReasoningAndProblemSolving, 3)]
        case .scrum:
            return [(\.communicationAndNetworking, 2)]
        case .security:
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .cna:
            return [
                (\.communicationAndNetworking, 2),
                (\.patienceAndPerseverance, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .dentalAssistant:
            return [
                (\.carefulnessAndAttentionToDetail, 3),
                (\.communicationAndNetworking, 2),
            ]
        case .medicalAssistant:
            return [
                (\.communicationAndNetworking, 2),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.patienceAndPerseverance, 2),
            ]
        case .pharmacyTech:
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 3),
            ]
        case .cwi:
            return [
                (\.patienceAndPerseverance, 3),
                (\.carefulnessAndAttentionToDetail, 3),
            ]
        case .epa608:
            return [
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .nate:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.patienceAndPerseverance, 2),
            ]
        case .faaAMP:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.patienceAndPerseverance, 3),
            ]
        case .cfp:
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.communicationAndNetworking, 2),
            ]
        case .series65:
            return [(\.analyticalReasoningAndProblemSolving, 3)]
        case .flightAttendantCert:
            return [
                (\.communicationAndNetworking, 2),
                (\.resilienceAndEndurance, 3),
            ]
        }
    }

    func certificationRequirements(_ player: Player) -> TrainingRequirementResult {
        for (kp, required) in softSkillThresholds {
            guard player.softSkills[keyPath: kp] >= required else {
                let name = SoftSkills.label(forKeyPath: kp) ?? "skill"
                return .blocked(reason: "Needs more \(name)")
            }
        }
        return .ok(cost: costForCertification)
    }
}
