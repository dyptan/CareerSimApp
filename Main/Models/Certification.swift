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
    case teachingCertificate = "Teaching Certificate"
    case personalTrainer = "Personal Trainer"
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
        case .teachingCertificate: return "Teaching Certificate"
        case .personalTrainer: return "Personal Trainer Certification"
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
        case .cwi: return "Certified Welding Inspector. Lets you check that welds on bridges, ships, and pipelines are safe and meet building codes."
        case .epa608: return "U.S. licence to handle the chemicals inside air conditioners and fridges. Required for HVAC technicians."
        case .nate: return "North American Technician Excellence — proves you can install and repair heating and cooling systems."
        case .faaAMP: return "FAA Airframe & Powerplant — U.S. licence to repair commercial aircraft. Mandatory for aviation mechanics."
        case .cna: return "Certified Nursing Assistant. The first step into nursing — basic patient care under a nurse’s supervision."
        case .dentalAssistant: return "Trained to help dentists during procedures, take X-rays, and prepare patients."
        case .medicalAssistant: return "Trained to help doctors with vitals, simple lab work, and patient records in clinics."
        case .pharmacyTech: return "Trained to dispense medication under a pharmacist’s supervision."
        case .cfp: return "Certified Financial Planner — U.S. credential for advising people on investments, retirement, and taxes."
        case .series65: return "U.S. exam that lets you give paid investment advice as a registered investment adviser."
        case .flightAttendantCert: return "FAA-issued certificate proving you can keep passengers safe on commercial flights."
        case .teachingCertificate: return "State or country licence to teach in a public school. Earned after a teacher-training programme and supervised classroom hours."
        case .personalTrainer: return "Industry credential (like NASM or ACE) qualifying you to design fitness programmes and coach clients in a gym or studio."
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
        case .teachingCertificate: return "📚"
        case .personalTrainer: return "💪"
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
        case .teachingCertificate: return 2500
        case .personalTrainer: return 700
        case .culinaryDiploma: return 5000
        case .paralegal: return 3000
        case .cosmetology: return 8000
        case .emt: return 1500   // EMT-Basic course + state exam
        case .cpa: return 3500   // exam fees + review course
        case .cfa: return 5000   // 3 exam levels + study materials
        case .pmp: return 1200   // PMI exam + prep
        case .shrm: return 700   // exam + study materials
        case .comptiaA: return 500  // 2 exams + voucher
        case .ase: return 400    // multi-test mechanic certification
        case .osha10: return 100 // short safety card course
        }
    }

    // Minimum EQF level (education) required before pursuing this certification
    var minEQF: Int {
        switch self {
        case .cfp,
             .teachingCertificate,  // most school systems require a Bachelor + teacher training
             .cpa,                  // licensing typically requires 150 college credits (≈ Bachelor)
             .cfa,                  // CFA Institute requires Bachelor or final-year status
             .pmp,                  // 4-year degree + 36 months experience (or HS + 60 months)
             .shrm:                 // SHRM-CP commonly requires a Bachelor for full eligibility
            return 5
        case .faaAMP,               // FAA requires 18 months of accredited aviation maintenance training
             .paralegal:            // typically an associate degree or vocational diploma
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
                (\.outdoorAndWeatherResilience, 1),
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
        case .teachingCertificate:
            // Teacher training: classroom communication + emotional regulation + planning
            return [
                (\.communicationAndNetworking, 4),
                (\.stressResistanceAndEmotionalRegulation, 3),
                (\.presentationAndStorytelling, 3),
                (\.timeManagementAndPlanning, 2),
            ]
        case .personalTrainer:
            // Personal training: leading clients through demanding sessions + coaching
            return [
                (\.resilienceAndEndurance, 4),
                (\.communicationAndNetworking, 2),
                (\.leadershipAndInfluence, 2),
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
