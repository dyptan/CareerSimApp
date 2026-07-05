import Foundation

/// A paid professional credential the player can earn in their spare time — the
/// merger of what used to be separate `Certification` and `License` types. Every
/// training is pursued the same way: it costs a fee and a spare-time slot, and a
/// year's attempt rolls a pass against `passProbability` (soft skills set the
/// odds). Hard gates — age, education (EQF), prerequisite trainings, and, for
/// senior credentials, work experience — decide whether you may *attempt* it;
/// soft skills only decide whether you *pass*.
///
/// `isStatutory` marks the legally-mandated credentials (former licences): they
/// hard-gate hiring in every field, whereas the rest (former certifications)
/// only gate hiring in regulated industries (see `Job.hardSkillsMet`).
enum Training: String, CaseIterable, Codable, Hashable, Identifiable {
    // MARK: Professional certifications
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

    // MARK: Statutory licences
    case drivers = "Driver's License"
    case cdl = "CDL"
    case pilot = "Pilot"
    case commercialPilot = "Commercial Pilot"
    case nurse = "Nurse License"
    case electrician = "Electrician License"
    case plumber = "Plumber License"
    case bar = "Bar Admission"
    case professionalEngineer = "Professional Engineer"
    case architect = "Architect Licence"
    case pesticideApplicator = "Pesticide Applicator"
    case securityGuard = "Security Guard Licence"
    case masterElectrician = "Master Electrician License"
    case masterPlumber = "Master Plumber License"
    case airlineTransportPilot = "ATP"

    var id: String { rawValue }

    /// Legally-mandated credentials (former licences). These hard-gate hiring in
    /// every field; non-statutory trainings (former certifications) gate hiring
    /// only in regulated industries (see `Job.hardSkillsMet`).
    var isStatutory: Bool {
        switch self {
        case .drivers, .cdl, .pilot, .commercialPilot, .nurse, .electrician,
             .plumber, .bar, .professionalEngineer, .architect,
             .pesticideApplicator, .securityGuard, .masterElectrician,
             .masterPlumber, .airlineTransportPilot:
            return true
        default:
            return false
        }
    }

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
        case .drivers: return "Driver’s License"
        case .cdl: return "Commercial Driver’s License"
        case .pilot: return "Private Pilot License"
        case .commercialPilot: return "Commercial Pilot License"
        case .nurse: return "Nursing License"
        case .electrician: return "Electrician License"
        case .plumber: return "Plumber License"
        case .bar: return "Bar Admission (Lawyer)"
        case .professionalEngineer: return "Professional Engineer (PE)"
        case .architect: return "Architect Licence"
        case .pesticideApplicator: return "Pesticide Applicator Licence"
        case .securityGuard: return "Security Guard Licence"
        case .masterElectrician: return "Master Electrician License"
        case .masterPlumber: return "Master Plumber License"
        case .airlineTransportPilot: return "Airline Transport Pilot (ATP)"
        }
    }

    /// Plain-language explanation of the training, for the in-game info popover.
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
        case .drivers: return "Standard car licence. Needed for most jobs that involve any driving."
        case .cdl: return "Commercial Driver’s Licence — required to drive trucks, buses, and large delivery vehicles for paid work."
        case .pilot: return "Private pilot licence — lets you fly small planes for fun, but not for paid work."
        case .commercialPilot: return "Lets you fly planes for paid work — required to be hired by airlines and freight carriers."
        case .nurse: return "Government licence to work as a nurse. Earned after passing a national exam following a nursing degree."
        case .electrician: return "Government licence to wire buildings safely. Earned after an apprenticeship and an exam."
        case .plumber: return "Government licence to install and repair pipes, drains, and water systems."
        case .bar: return "Bar admission — the state-by-state exam and ethics review you must pass after law school before you can practise as a lawyer in court."
        case .professionalEngineer: return "Professional Engineer (PE) — state licence required to sign off on engineering plans for buildings, bridges, and public works. Needed for senior civil, mechanical, and electrical engineering roles."
        case .architect: return "State licence required to call yourself an Architect and stamp building plans. Earned after a degree, multi-year internship, and a national exam (NCARB)."
        case .pesticideApplicator: return "Government permit to apply restricted-use pesticides on farms or commercial landscapes. Required for many farming, landscaping, and pest-control jobs."
        case .securityGuard: return "State licence required to work as an unarmed security guard. Covers law, ethics, and basic emergency response."
        case .masterElectrician: return "The senior electrician licence. Earned after years as a licensed journeyman, it lets you pull permits, run jobs, and supervise apprentices — required to become a Master Electrician."
        case .masterPlumber: return "The senior plumbing licence. Earned after journeyman experience, it lets you design systems, pull permits, and lead a crew — required to become a Master Plumber."
        case .airlineTransportPilot: return "The highest-level pilot certificate. Required to serve as captain (pilot-in-command) of a commercial airliner."
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
        case .drivers: return "🚗"
        case .cdl: return "🚚"
        case .pilot: return "🛩️"
        case .commercialPilot: return "✈️"
        case .nurse: return "🩺"
        case .electrician: return "⚡️"
        case .plumber: return "🔧"
        case .bar: return "⚖️"
        case .professionalEngineer: return "🏗️"
        case .architect: return "📐"
        case .pesticideApplicator: return "🌱"
        case .securityGuard: return "🛡️"
        case .masterElectrician: return "⚡️"
        case .masterPlumber: return "🔧"
        case .airlineTransportPilot: return "✈️"
        }
    }

    /// The realistic all-in cost the player stakes when attempting the training:
    /// prep course / program materials **plus** the exam and licensing fees. The
    /// separate degree prerequisite (EQF) is *not* included — that's paid through
    /// the education system — so these are the incremental credential costs only.
    var cost: Int {
        switch self {
        case .aws: return 500          // exam ~$150 + prep course/labs
        case .azure: return 500        // exam ~$165 + prep course/labs
        case .google: return 500       // exam ~$200 + prep course/labs
        case .scrum: return 1200       // CSM/PSM course (exam included)
        case .security: return 900     // Security+ exam ~$400 + prep
        case .cna: return 1500         // CNA course + state exam
        case .dentalAssistant: return 4000   // assisting program + exam
        case .medicalAssistant: return 6000  // MA certificate program + exam
        case .flightAttendantCert: return 1500  // initial training + FAA cert
        case .teachingCertificate: return 5000  // alt-cert program + licensure exams
        case .culinaryDiploma: return 15000  // culinary school diploma
        case .paralegal: return 5000    // paralegal certificate program
        case .cosmetology: return 15000 // cosmetology school + state exam
        case .emt: return 1800          // EMT-Basic course + state exam
        case .cpa: return 4000          // review course + 4 exam sections
        case .cfa: return 5000          // enrollment + 3 exam levels + materials
        case .pmp: return 2000          // exam ~$555 + prep bootcamp
        case .shrm: return 1200         // exam ~$410 + prep/materials
        case .comptiaA: return 1000     // 2 exams ~$500 + prep
        case .ase: return 500           // multi-test certification + prep
        case .osha10: return 150        // short safety-card course
        case .boardCertified: return 4000  // specialty board exam + prep
        case .drivers: return 1200      // driving school + DMV road/written test
        case .cdl: return 5000          // CDL training program + exam
        case .pilot: return 14000       // PPL ground school + flight hours + checkride
        case .commercialPilot: return 25000  // added hours + commercial checkride
        case .nurse: return 1000        // NCLEX + licensing + review course
        case .electrician: return 1500  // exam prep + licence application
        case .plumber: return 1500      // exam prep + licence application
        case .bar: return 5000          // bar-prep course + bar exam fees
        case .professionalEngineer: return 2000  // FE + PE exams + review
        case .architect: return 2500    // ARE multi-division exam + prep
        case .pesticideApplicator: return 300   // applicator course + state exam
        case .securityGuard: return 300 // pre-licensing course + guard card
        case .masterElectrician: return 2500  // master exam + licensing
        case .masterPlumber: return 2500      // master exam + licensing
        case .airlineTransportPilot: return 30000  // ATP hours + type rating + checkride
        }
    }

    /// Life stages in which this training is offered. Driver's and private pilot
    /// are reachable at 16/17 so they surface in the teen sheet; every other
    /// training presumes the player is a young adult or older.
    var stages: Set<LifeStage> {
        switch self {
        case .drivers, .pilot:
            return [.teen, .youngAdult, .adult]
        default:
            return [.youngAdult, .adult]
        }
    }

    /// Minimum age required to attempt this training.
    var minAge: Int {
        switch self {
        case .drivers: return 16
        case .pilot: return 17
        default: return 18
        }
    }

    /// Minimum EQF (education) level required before attempting this training.
    var minEQF: Int {
        switch self {
        case .bar:
            return 7  // requires a Doctor of Law (J.D.)
        case .boardCertified:
            return 7  // requires a completed medical doctorate
        case .teachingCertificate, .cpa, .cfa, .pmp, .shrm,
             .architect, .professionalEngineer, .airlineTransportPilot:
            return 5  // requires a Bachelor (or final-year status)
        case .paralegal, .nurse, .electrician, .plumber,
             .masterElectrician, .masterPlumber:
            return 4  // associate / vocational trade training
        case .osha10:
            return 0  // safety card has no education prerequisite
        default:
            return 3  // high-school diploma for all others
        }
    }

    /// Minimum years of work experience required before attempting this training.
    /// Reserved for senior credentials that realistically demand time on the job
    /// (journeyman years before a master licence, PIC hours before an ATP, and
    /// so on). Checked against `Player.totalYearsWorked`.
    var minYearsExperience: Int {
        switch self {
        case .masterElectrician, .masterPlumber: return 4
        case .professionalEngineer: return 4
        case .cfa: return 4
        case .pmp: return 3
        case .boardCertified: return 3
        case .airlineTransportPilot: return 5
        default: return 0
        }
    }

    /// Trainings that must already be held before this one can be attempted — the
    /// prerequisite chain (a CDL needs a Driver's License first, an ATP builds on
    /// a Commercial Pilot License, a master trade licence on its journeyman
    /// licence). `requirements` enforces it at runtime and `CareerGraph` reads it
    /// to validate the chain stays acyclic.
    var prerequisites: [Training] {
        switch self {
        case .cdl: return [.drivers]
        case .commercialPilot: return [.pilot]
        case .masterElectrician: return [.electrician]
        case .masterPlumber: return [.plumber]
        case .airlineTransportPilot: return [.commercialPilot]
        default: return []
        }
    }

    /// Soft-skill axes that drive the odds of passing this training's exam, with
    /// the level at which each is a perfect fit. These are *not* a hard gate (see
    /// `passProbability`); they only set the pass chance.
    var softSkillThresholds: [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch self {
        case .aws, .azure, .google:
            return [(\.analyticalReasoningAndProblemSolving, 3),
                    (\.carefulnessAndAttentionToDetail, 2),
                    (\.selfDisciplineAndPerseverance, 2)]
        case .scrum:
            return [(\.communicationAndNetworking, 3),
                    (\.collaborationAndTeamwork, 2),
                    (\.timeManagementAndPlanning, 2)]
        case .security:
            return [(\.analyticalReasoningAndProblemSolving, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.selfDisciplineAndPerseverance, 2)]
        case .cna:
            return [(\.communicationAndNetworking, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.stressResistanceAndEmotionalRegulation, 2),
                    (\.resilienceAndEndurance, 2)]
        case .dentalAssistant:
            return [(\.tinkeringAndFingerPrecision, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.communicationAndNetworking, 2),
                    (\.stressResistanceAndEmotionalRegulation, 2)]
        case .medicalAssistant:
            return [(\.communicationAndNetworking, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.tinkeringAndFingerPrecision, 2),
                    (\.stressResistanceAndEmotionalRegulation, 2)]
        case .flightAttendantCert:
            return [(\.communicationAndNetworking, 3),
                    (\.stressResistanceAndEmotionalRegulation, 3),
                    (\.presentationAndStorytelling, 2),
                    (\.collaborationAndTeamwork, 2)]
        case .teachingCertificate:
            return [(\.communicationAndNetworking, 4),
                    (\.stressResistanceAndEmotionalRegulation, 3),
                    (\.presentationAndStorytelling, 3),
                    (\.timeManagementAndPlanning, 2)]
        case .culinaryDiploma:
            return [(\.creativityAndInsightfulThinking, 3),
                    (\.timeManagementAndPlanning, 3),
                    (\.carefulnessAndAttentionToDetail, 2),
                    (\.resilienceAndEndurance, 2)]
        case .paralegal:
            return [(\.analyticalReasoningAndProblemSolving, 3),
                    (\.carefulnessAndAttentionToDetail, 4),
                    (\.communicationAndNetworking, 2)]
        case .cosmetology:
            return [(\.creativityAndInsightfulThinking, 3),
                    (\.tinkeringAndFingerPrecision, 3),
                    (\.communicationAndNetworking, 2)]
        case .emt:
            return [(\.stressResistanceAndEmotionalRegulation, 4),
                    (\.communicationAndNetworking, 3),
                    (\.carefulnessAndAttentionToDetail, 2),
                    (\.resilienceAndEndurance, 2)]
        case .cpa:
            return [(\.analyticalReasoningAndProblemSolving, 4),
                    (\.carefulnessAndAttentionToDetail, 4),
                    (\.selfDisciplineAndPerseverance, 3)]
        case .cfa:
            return [(\.analyticalReasoningAndProblemSolving, 4),
                    (\.selfDisciplineAndPerseverance, 4),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.timeManagementAndPlanning, 2)]
        case .pmp:
            return [(\.timeManagementAndPlanning, 4),
                    (\.communicationAndNetworking, 3),
                    (\.collaborationAndTeamwork, 2)]
        case .shrm:
            return [(\.communicationAndNetworking, 3),
                    (\.stressResistanceAndEmotionalRegulation, 2),
                    (\.carefulnessAndAttentionToDetail, 2),
                    (\.collaborationAndTeamwork, 2)]
        case .comptiaA:
            return [(\.analyticalReasoningAndProblemSolving, 2),
                    (\.carefulnessAndAttentionToDetail, 2),
                    (\.communicationAndNetworking, 2)]
        case .ase:
            return [(\.tinkeringAndFingerPrecision, 3),
                    (\.analyticalReasoningAndProblemSolving, 3),
                    (\.carefulnessAndAttentionToDetail, 2)]
        case .osha10:
            return [(\.carefulnessAndAttentionToDetail, 1)]
        case .boardCertified:
            return [(\.analyticalReasoningAndProblemSolving, 4),
                    (\.carefulnessAndAttentionToDetail, 4),
                    (\.stressResistanceAndEmotionalRegulation, 3),
                    (\.empathyAndInterpersonalCare, 2),
                    (\.selfDisciplineAndPerseverance, 3)]
        case .drivers:
            return [(\.spacialNavigationAndOrientation, 2),
                    (\.carefulnessAndAttentionToDetail, 2)]
        case .cdl:
            return [(\.spacialNavigationAndOrientation, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.stressResistanceAndEmotionalRegulation, 2),
                    (\.resilienceAndEndurance, 2),
                    (\.timeManagementAndPlanning, 2)]
        case .pilot:
            return [(\.spacialNavigationAndOrientation, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.analyticalReasoningAndProblemSolving, 2),
                    (\.stressResistanceAndEmotionalRegulation, 2)]
        case .commercialPilot:
            return [(\.spacialNavigationAndOrientation, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.stressResistanceAndEmotionalRegulation, 3),
                    (\.analyticalReasoningAndProblemSolving, 3)]
        case .nurse:
            return [(\.communicationAndNetworking, 3),
                    (\.empathyAndInterpersonalCare, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.stressResistanceAndEmotionalRegulation, 3),
                    (\.resilienceAndEndurance, 3)]
        case .electrician:
            return [(\.tinkeringAndFingerPrecision, 4),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.analyticalReasoningAndProblemSolving, 3),
                    (\.stressResistanceAndEmotionalRegulation, 2)]
        case .plumber:
            return [(\.tinkeringAndFingerPrecision, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.spacialNavigationAndOrientation, 2),
                    (\.resilienceAndEndurance, 2),
                    (\.outdoorAndWeatherResilience, 1)]
        case .bar:
            return [(\.analyticalReasoningAndProblemSolving, 4),
                    (\.communicationAndNetworking, 4),
                    (\.selfDisciplineAndPerseverance, 4),
                    (\.presentationAndStorytelling, 3),
                    (\.carefulnessAndAttentionToDetail, 3)]
        case .professionalEngineer:
            return [(\.analyticalReasoningAndProblemSolving, 4),
                    (\.spacialNavigationAndOrientation, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.selfDisciplineAndPerseverance, 3)]
        case .architect:
            return [(\.creativityAndInsightfulThinking, 3),
                    (\.spacialNavigationAndOrientation, 3),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.communicationAndNetworking, 2),
                    (\.selfDisciplineAndPerseverance, 2)]
        case .pesticideApplicator:
            return [(\.carefulnessAndAttentionToDetail, 3),
                    (\.outdoorAndWeatherResilience, 2),
                    (\.analyticalReasoningAndProblemSolving, 2)]
        case .securityGuard:
            return [(\.stressResistanceAndEmotionalRegulation, 3),
                    (\.communicationAndNetworking, 2),
                    (\.carefulnessAndAttentionToDetail, 2),
                    (\.resilienceAndEndurance, 2)]
        case .masterElectrician:
            return [(\.tinkeringAndFingerPrecision, 4),
                    (\.carefulnessAndAttentionToDetail, 4),
                    (\.analyticalReasoningAndProblemSolving, 3)]
        case .masterPlumber:
            return [(\.tinkeringAndFingerPrecision, 4),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.analyticalReasoningAndProblemSolving, 2)]
        case .airlineTransportPilot:
            return [(\.spacialNavigationAndOrientation, 4),
                    (\.carefulnessAndAttentionToDetail, 3),
                    (\.stressResistanceAndEmotionalRegulation, 4),
                    (\.analyticalReasoningAndProblemSolving, 3)]
        }
    }

    /// Hard gates on *attempting* this training: age, prerequisite trainings,
    /// education (EQF), and — for senior credentials — work experience. Soft
    /// skills are not a gate here; they set the odds of passing (see
    /// `passProbability`), so meeting the bar isn't required to attempt, just to
    /// stand a good chance.
    func requirements(_ player: Player) -> TrainingRequirementResult {
        if player.age < minAge {
            return .blocked(reason: "Requires age \(minAge)+")
        }
        for prereq in prerequisites where !player.hardSkills.trainings.contains(prereq) {
            return .blocked(reason: "Requires \(prereq.friendlyName) first")
        }
        let highestEQF = player.degrees.map(\.eqf).max() ?? 0
        if highestEQF < minEQF {
            let label = Education.Requirements(minEQF: minEQF).educationLabel()
            return .blocked(reason: "Requires \(label)")
        }
        if player.totalYearsWorked < minYearsExperience {
            return .blocked(reason: "Requires \(minYearsExperience)+ yr(s) work experience")
        }
        return .ok(cost: cost)
    }

    /// Probability (0.05…0.98) of passing this exam, from how well the player's
    /// soft skills meet the training's thresholds. Mirrors
    /// `Education.admissionProbability`: strong, relevant soft skills make a pass
    /// likely but never certain. Simplified mode stays deterministic (always
    /// passes).
    func passProbability(for player: Player) -> Double {
        if player.isSimplified { return 1.0 }
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
