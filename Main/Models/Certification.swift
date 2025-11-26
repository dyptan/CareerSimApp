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
          case .aws: return 350   // prep + exam voucher
          case .azure: return 350
          case .google: return 300
          case .scrum: return 600 // 2-day course + exam
          case .security: return 250 // basic security awareness + test
          case .cwi: return 3000  // course + exam (CWI is pricey)
          case .epa608: return 200 // prep + exam
          case .nate: return 450   // prep + exam
          case .faaAMP: return 6000 // A&P prep/testing (very rough, excluding full school tuition)
          case .cna: return 1500   // course + clinical + exam
          case .dentalAssistant: return 2500 // short program + exam
          case .medicalAssistant: return 3500 // program + exam
          case .pharmacyTech: return 1200 // course + exam
          case .cfp: return 7000   // coursework + exam fee
          case .series65: return 500 // prep + exam
          case .flightAttendantCert: return 1000 // prep + airline hiring process costs
          }
      }

    
    func certificationRequirements(_ player: Player) -> TrainingRequirementResult {
        let age = player.age
        let softSkills = player.softSkills
        switch self {
        case .cwi, .epa608, .nate, .faaAMP, .cfp, .series65:
            if age < 18 { return .blocked(reason: "Requires age 18+") }
        case .flightAttendantCert:
            if age < 17 { return .blocked(reason: "Requires age 17+") }
        default:
            break
        }

        switch self {
        case .scrum:
            if softSkills.communicationAndNetworking < 2 || softSkills.leadershipAndInfluence < 2 {
                return .blocked(reason: "Needs better Communication and Leadership")
            }
        case .security:
            if softSkills.carefulnessAndAttentionToDetail < 2 {
                return .blocked(reason: "Needs more Carefulness")
            }
        case .aws, .azure, .google:
            if softSkills.analyticalReasoningAndProblemSolving < 2 {
                return .blocked(reason: "Needs more Problem Solving")
            }
        default:
            break
        }
        return .ok(cost: costForCertification)
    }
    
}
