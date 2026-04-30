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

    // Minimum EQF level (education) required before pursuing this certification
    var minEQF: Int {
        switch self {
        case .cfp:    return 5  // CFP Board mandates a bachelor's degree
        case .faaAMP: return 4  // FAA requires 18 months of accredited aviation maintenance training
        default:      return 3  // High school diploma for all others
        }
    }

    var softSkillThresholds: [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch self {
        case .aws, .azure, .google:
            // Cloud architecture exams: strong analytical ability + precision + serious self-study
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.selfDisciplineAndPerseverance, 2),
            ]
        case .scrum:
            // Scrum Master: facilitates ceremonies, manages sprint cadence, unblocks team
            return [
                (\.communicationAndNetworking, 3),
                (\.leadershipAndInfluence, 2),
                (\.collaborationAndTeamwork, 2),
                (\.timeManagementAndPlanning, 2),
            ]
        case .security:
            // CompTIA Security+: threat analysis, vulnerability assessment, technical depth
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.selfDisciplineAndPerseverance, 2),
            ]
        case .cwi:
            // Certified Welding Inspector: practical welding background + high-precision QA
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .epa608:
            // HVAC refrigerant handling: safe equipment operation + regulatory knowledge
            return [
                (\.carefulnessAndAttentionToDetail, 2),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.tinkeringAndFingerPrecision, 2),
            ]
        case .nate:
            // HVAC technician excellence: hands-on diagnostics + outdoor unit work
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.outdoorAndWeatherResilience, 2),
            ]
        case .faaAMP:
            // FAA Aircraft & Powerplant: aviation safety is life-critical — highest precision required
            return [
                (\.tinkeringAndFingerPrecision, 4),
                (\.carefulnessAndAttentionToDetail, 4),
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .cna:
            // Certified Nursing Assistant: daily patient care, physically and emotionally demanding
            return [
                (\.communicationAndNetworking, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.stressResistanceAndEmotionalRegulation, 2),
                (\.resilienceAndEndurance, 2),
            ]
        case .dentalAssistant:
            // Very fine motor work inside the mouth, patient anxiety management
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.communicationAndNetworking, 2),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .medicalAssistant:
            // Clinical procedures (phlebotomy, vitals) + busy clinic communication
            return [
                (\.communicationAndNetworking, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.tinkeringAndFingerPrecision, 2),
                (\.stressResistanceAndEmotionalRegulation, 2),
            ]
        case .pharmacyTech:
            // Dosage calculations, drug interactions — wrong fill = serious patient harm
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.communicationAndNetworking, 2),
            ]
        case .cfp:
            // CFP requires bachelor's + 6000 h of experience + rigorous board exam
            return [
                (\.analyticalReasoningAndProblemSolving, 4),
                (\.communicationAndNetworking, 3),
                (\.selfDisciplineAndPerseverance, 3),
                (\.timeManagementAndPlanning, 2),
            ]
        case .series65:
            // Investment Adviser licensing: regulatory compliance + fiduciary accuracy
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.selfDisciplineAndPerseverance, 2),
            ]
        case .flightAttendantCert:
            // Emergency procedures + customer service + crew resource management
            return [
                (\.communicationAndNetworking, 3),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.presentationAndStorytelling, 2),
                (\.collaborationAndTeamwork, 2),
            ]
        }
    }

    func certificationRequirements(_ player: Player) -> TrainingRequirementResult {
        let highestEQF = player.degrees.map(\.eqf).max() ?? 0
        if highestEQF < minEQF {
            let label = Education.Requirements(minEQF: minEQF).educationLabel()
            return .blocked(reason: "Requires \(label)")
        }
        for (kp, required) in softSkillThresholds {
            guard player.softSkills[keyPath: kp] >= required else {
                let name = SoftSkills.label(forKeyPath: kp) ?? "skill"
                return .blocked(reason: "Needs more \(name)")
            }
        }
        return .ok(cost: costForCertification)
    }
}
