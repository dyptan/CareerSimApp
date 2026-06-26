import Foundation

enum Certification: String, CaseIterable, Codable, Hashable, Identifiable {
    case aws = "AWS"
    case azure = "Azure"
    case google = "Google"
    case scrum = "Scrum"
    case security = "Security"
    case cna = "CNA"
    case dentalAssistant = "Dental Assistant"
    case medicalAssistant = "Medical Assistant"
    case flightAttendantCert = "Flight Attendant"
    case teachingCertificate = "Teaching Certificate"
    case culinaryDiploma = "Culinary Diploma"
    case paralegal = "Paralegal Certificate"
    case cosmetology = "Cosmetology Licence"
    case emt = "EMT"
    case cpa = "CPA"
    case cfa = "CFA"
    case pmp = "PMP"
    case shrm = "SHRM-CP"
    case comptiaA = "CompTIA A+"
    case ase = "ASE"
    case osha10 = "OSHA 10"
    case boardCertified = "Board Certification"

    var id: String { rawValue }

    var friendlyName: String {
        switch self {
        case .aws: return "AWS Certification"
        case .azure: return "Azure Certification"
        case .google: return "Google Cloud Certification"
        case .scrum: return "Scrum Master"
        case .security: return "Security Awareness"
        case .cna: return "Certified Nursing Assistant"
        case .dentalAssistant: return "Dental Assistant"
        case .medicalAssistant: return "Medical Assistant"
        case .flightAttendantCert: return "Flight Attendant Certificate"
        case .teachingCertificate: return "Teaching Certificate"
        case .culinaryDiploma: return "Culinary Diploma"
        case .paralegal: return "Paralegal Certificate"
        case .cosmetology: return "Cosmetology Licence"
        case .emt: return "Emergency Medical Technician"
        case .cpa: return "Certified Public Accountant"
        case .cfa: return "Chartered Financial Analyst"
        case .pmp: return "Project Management Professional"
        case .shrm: return "SHRM Certified Professional"
        case .comptiaA: return "CompTIA A+"
        case .ase: return "ASE Mechanic Certification"
        case .osha10: return "OSHA 10 Safety Card"
        case .boardCertified: return "Medical Board Certification"
        }
    }

    /// Plain-language explanation of the certification, for the in-game info popover.
    var description: String {
        switch self {
        case .aws: return "Cloud-computing certificate from Amazon. Shows you can build websites and apps that run on Amazon’s online servers."
        case .azure: return "Cloud-computing certificate from Microsoft. Like AWS, but for Microsoft’s online servers."
        case .google: return "Cloud-computing certificate from Google. Shows you can build apps using Google’s online services."
        case .scrum: return "Project-management approach used by tech teams. Proves you can lead a small team building software in short, repeated cycles called sprints."
        case .security: return "Cybersecurity basics. Useful for any IT job; required for many tech roles that handle sensitive data."
        case .cna: return "Certified Nursing Assistant. The first step into nursing — basic patient care under a nurse’s supervision."
        case .dentalAssistant: return "Trained to help dentists during procedures, take X-rays, and prepare patients."
        case .medicalAssistant: return "Trained to help doctors with vitals, simple lab work, and patient records in clinics."
        case .flightAttendantCert: return "FAA-issued certificate proving you can keep passengers safe on commercial flights."
        case .teachingCertificate: return "State or country licence to teach in a public school. Earned after a teacher-training programme and supervised classroom hours."
        case .culinaryDiploma: return "Diploma from a cooking school covering knife skills, recipes, and kitchen management. The standard credential for restaurant kitchens."
        case .paralegal: return "Trained to help lawyers research cases, draft documents, and prepare for trials. A common entry into the legal field without going to law school."
        case .cosmetology: return "State licence to cut hair and provide skin and nail services in a salon. Earned after attending a cosmetology school and passing a state exam."
        case .emt: return "Emergency Medical Technician — qualifies you to provide pre-hospital emergency care on an ambulance crew. The first step toward becoming a paramedic."
        case .cpa: return "Certified Public Accountant — the gold standard for accountants. Required to sign off on tax filings, audit financial statements, and lead corporate finance roles."
        case .cfa: return "Chartered Financial Analyst — the most respected credential for investment professionals. Three brutal exams over several years; expected for senior analyst, fund manager, and equity research roles."
        case .pmp: return "Project Management Professional — globally recognised credential for running large projects on time and on budget. Standard expectation for senior project manager roles."
        case .shrm: return "Society for Human Resource Management — Certified Professional. Validates that you understand HR policy, hiring law, and people operations. Common requirement for HR specialist roles."
        case .comptiaA: return "Entry-level IT certification covering hardware, networking, and troubleshooting. Standard credential for help-desk and IT-support jobs."
        case .ase: return "Automotive Service Excellence — the trade certification that proves you can diagnose and repair vehicles to dealership standards. Common requirement for senior mechanic roles."
        case .osha10: return "A 10-hour construction-safety training card recognised across U.S. job sites. Often required before you can step onto a building site as a labourer or carpenter."
        case .boardCertified: return "Specialty board certification earned after residency — the standard credential for attending physicians and medical leadership. Verifies mastery of a medical specialty."
        }
    }

    var pictogram: String {
        switch self {
        case .aws, .azure, .google: return "☁️"
        case .scrum: return "📈"
        case .security: return "🔐"
        case .cna: return "🏥"
        case .dentalAssistant: return "🦷"
        case .medicalAssistant: return "🩺"
        case .flightAttendantCert: return "🧳"
        case .teachingCertificate: return "📚"
        case .culinaryDiploma: return "🧑‍🍳"
        case .paralegal: return "⚖️"
        case .cosmetology: return "💇"
        case .emt: return "🚑"
        case .cpa: return "📒"
        case .cfa: return "💹"
        case .pmp: return "📋"
        case .shrm: return "🧑‍💼"
        case .comptiaA: return "🖥️"
        case .ase: return "🔧"
        case .osha10: return "🦺"
        case .boardCertified: return "⚕️"
        }
    }

    var costForCertification: Int {
        switch self {
        case .aws: return 350
        case .azure: return 350
        case .google: return 300
        case .scrum: return 600
        case .security: return 250
        case .cna: return 1500
        case .dentalAssistant: return 2500
        case .medicalAssistant: return 3500
        case .flightAttendantCert: return 1000
        case .teachingCertificate: return 2500
        case .culinaryDiploma: return 5000
        case .paralegal: return 3000
        case .cosmetology: return 8000
        case .emt: return 1500    // EMT-Basic course + state exam
        case .cpa: return 3500    // exam fees + review course
        case .cfa: return 5000    // 3 exam levels + study materials
        case .pmp: return 1200    // PMI exam + prep
        case .shrm: return 700    // exam + study materials
        case .comptiaA: return 500   // 2 exams + voucher
        case .ase: return 400     // multi-test mechanic certification
        case .osha10: return 100  // short safety card course
        case .boardCertified: return 4000  // specialty board exam + prep
        }
    }

    /// Life stages in which this certification is offered. All career certifications
    /// presume the player is at least old enough to be pursuing post-secondary work
    /// or vocational training, so the child and teen sheets stay empty.
    var stages: Set<LifeStage> {
        [.youngAdult, .adult]
    }

    // Minimum EQF level (education) required before pursuing this certification
    var minEQF: Int {
        switch self {
        case .teachingCertificate,  // most school systems require a Bachelor + teacher training
             .cpa,                  // licensing typically requires 150 college credits (≈ Bachelor)
             .cfa,                  // CFA Institute requires Bachelor or final-year status
             .pmp,                  // 4-year degree + 36 months experience (or HS + 60 months)
             .shrm:                 // SHRM-CP commonly requires a Bachelor for full eligibility
            return 5
        case .boardCertified:       // requires a completed medical doctorate
            return 7
        case .paralegal:            // typically an associate degree or vocational diploma
            return 4
        case .osha10:               // safety card has no education prerequisite
            return 0
        default:
            return 3                // High school diploma for all others
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
        case .flightAttendantCert:
            // Emergency procedures + customer service + crew resource management
            return [
                (\.communicationAndNetworking, 3),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.presentationAndStorytelling, 2),
                (\.collaborationAndTeamwork, 2),
            ]
        case .teachingCertificate:
            // Teacher training: classroom communication + emotional regulation + planning
            return [
                (\.communicationAndNetworking, 4),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.presentationAndStorytelling, 3),
                (\.timeManagementAndPlanning, 2),
            ]
        case .culinaryDiploma:
            // Culinary school: creative recipes under heavy time pressure
            return [
                (\.creativityAndInsightfulThinking, 3),
                (\.timeManagementAndPlanning, 3),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.resilienceAndEndurance, 2),
            ]
        case .paralegal:
            // Legal research and document preparation: precision and analysis
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.carefulnessAndAttentionToDetail, 4),
                (\.communicationAndNetworking, 2),
            ]
        case .cosmetology:
            // Cosmetology: creative styling, fine motor work, client communication
            return [
                (\.creativityAndInsightfulThinking, 3),
                (\.tinkeringAndFingerPrecision, 3),
                (\.communicationAndNetworking, 2),
            ]
        case .emt:
            // Emergency response: stress under pressure, decisive action, patient communication
            return [
                (\.stressResistanceAndEmotionalRegulation, 4),
                (\.communicationAndNetworking, 3),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.resilienceAndEndurance, 2),
            ]
        case .cpa:
            // CPA: rigorous accounting exam covering 4 sections — precision and stamina
            return [
                (\.analyticalReasoningAndProblemSolving, 4),
                (\.carefulnessAndAttentionToDetail, 4),
                (\.selfDisciplineAndPerseverance, 3),
            ]
        case .cfa:
            // CFA: three brutal exams covering investments, ethics, financial analysis
            return [
                (\.analyticalReasoningAndProblemSolving, 4),
                (\.selfDisciplineAndPerseverance, 4),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.timeManagementAndPlanning, 2),
            ]
        case .pmp:
            // PMP: managing scope, schedule, budget, and stakeholders across complex projects
            return [
                (\.timeManagementAndPlanning, 4),
                (\.leadershipAndInfluence, 3),
                (\.communicationAndNetworking, 3),
                (\.collaborationAndTeamwork, 2),
            ]
        case .shrm:
            // SHRM-CP: people operations, employment law, conflict resolution
            return [
                (\.communicationAndNetworking, 3),
                (\.stressResistanceAndEmotionalRegulation, 2),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.collaborationAndTeamwork, 2),
            ]
        case .comptiaA:
            // CompTIA A+: hands-on troubleshooting, helpdesk communication, methodical diagnosis
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.communicationAndNetworking, 2),
            ]
        case .ase:
            // ASE: vehicle diagnostics combine analysis with hands-on mechanical work
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .osha10:
            // Short safety course — entry-level, attention to following procedures
            return [
                (\.carefulnessAndAttentionToDetail, 1),
            ]
        case .boardCertified:
            // Specialty boards: deep clinical mastery, judgement under pressure, care
            return [
                (\.analyticalReasoningAndProblemSolving, 4),
                (\.carefulnessAndAttentionToDetail, 4),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.empathyAndInterpersonalCare, 2),
                (\.selfDisciplineAndPerseverance, 3),
            ]
        }
    }

    /// Education (EQF) is a hard prerequisite for sitting the exam. Soft skills
    /// are no longer a pass/fail gate here — they set the odds of passing (see
    /// `passProbability`), so meeting the bar isn't required to attempt, just
    /// to have a good chance.
    func certificationRequirements(_ player: Player) -> TrainingRequirementResult {
        let highestEQF = player.degrees.map(\.eqf).max() ?? 0
        if highestEQF < minEQF {
            let label = Education.Requirements(minEQF: minEQF).educationLabel()
            return .blocked(reason: "Requires \(label)")
        }
        return .ok(cost: costForCertification)
    }

    /// Probability (0.05…0.98) of passing this exam, from how well the player's
    /// soft skills meet the certification's thresholds — the industry-specific
    /// requirements for the credential. Mirrors `Education.admissionProbability`:
    /// strong, relevant soft skills make a pass likely but never certain.
    /// Simplified mode stays deterministic (always passes).
    func passProbability(for player: Player) -> Double {
        if player.gameMode == .simplified { return 1.0 }
        let thresholds = softSkillThresholds
        guard !thresholds.isEmpty else { return 0.95 }
        var fitSum = 0.0
        for (kp, need) in thresholds {
            fitSum += min(Double(player.softSkills[keyPath: kp]) / Double(need), 1.0)
        }
        let fit = fitSum / Double(thresholds.count)
        let raw = 0.1 + 0.9 * fit + player.difficulty.opportunityBonus
        return max(0.05, min(0.98, raw))
    }
}
