import Foundation

/// A professional credential the player can earn in their spare time — the
/// merger of what used to be separate `Certification` and `License` types. The
/// catalogue is deliberately limited to credentials that are *actually required*
/// to hold a specific role in real life: statutory occupational licences (a
/// nurse, electrician, lawyer, or pilot cannot legally practise without one) and
/// the handful of non-statutory credentials a role is defined by (CNA, EMT,
/// teaching certificate, board certification, CPA). Optional résumé-boosters
/// (cloud certs, Scrum, PMP, CFA, CompTIA, OSHA, …) are intentionally left out —
/// they help a real career but gate no position, so they'd be busywork here.
///
/// Every training is pursued the same way: it takes a spare-time slot for the
/// year, and enrolling earns the credential — a student who puts in the year is
/// assumed to pass the exam, so there's no roll. Hard gates — age, education
/// (EQF), prerequisite trainings, and, for senior credentials, work experience —
/// decide whether you may *enrol*.
///
/// `isStatutory` marks the legally-mandated credentials (former licences): they
/// hard-gate hiring in every field, whereas the rest (former certifications)
/// only gate hiring in regulated industries (see `Job.hardSkillsMet`).
enum Training: String, CaseIterable, Codable, Hashable, Identifiable {
    // MARK: Role-defining certifications
    case cna = "CNA"
    case dentalAssistant = "Dental Assistant"
    case flightAttendantCert = "Flight Attendant"
    case teachingCertificate = "Teaching Certificate"
    case cosmetology = "Cosmetology Licence"
    case emt = "EMT"
    case cpa = "CPA"
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
        case .cna: return "Certified Nursing Assistant"
        case .dentalAssistant: return "Dental Assistant"
        case .flightAttendantCert: return "Flight Attendant"
        case .teachingCertificate: return "Teaching"
        case .cosmetology: return "Cosmetology"
        case .emt: return "Emergency Medical Technician"
        case .cpa: return "Certified Public Accountant"
        case .boardCertified: return "Medical Specialist"
        case .drivers: return "Car Driving"
        case .cdl: return "Commercial Driving"
        case .pilot: return "Private Pilot"
        case .commercialPilot: return "Commercial Pilot"
        case .nurse: return "Nursing"
        case .electrician: return "Electrician"
        case .plumber: return "Plumber"
        case .bar: return "Bar Admission (Lawyer)"
        case .professionalEngineer: return "Professional Engineer (PE)"
        case .architect: return "Architect"
        case .pesticideApplicator: return "Pesticide Applicator"
        case .securityGuard: return "Security Guard"
        case .masterElectrician: return "Master Electrician"
        case .masterPlumber: return "Master Plumber"
        case .airlineTransportPilot: return "Airline Transport Pilot (ATP)"
        }
    }

    /// Plain-language explanation of the training, for the in-game info popover.
    var description: String {
        switch self {
        case .cna: return "Certified Nursing Assistant. The first step into nursing — basic patient care under a nurse’s supervision."
        case .dentalAssistant: return "Trained to help dentists during procedures, take X-rays, and prepare patients."
        case .flightAttendantCert: return "FAA-issued certificate proving you can keep passengers safe on commercial flights."
        case .teachingCertificate: return "State or country licence to teach in a public school. Earned after a teacher-training programme and supervised classroom hours."
        case .cosmetology: return "State licence to cut hair and provide skin and nail services in a salon. Earned after attending a cosmetology school and passing a state exam."
        case .emt: return "Emergency Medical Technician — qualifies you to provide pre-hospital emergency care on an ambulance crew. The first step toward becoming a paramedic."
        case .cpa: return "Certified Public Accountant — the licence required to sign off on tax filings, audit financial statements, and lead corporate finance roles."
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
        case .cna: return "🏥"
        case .dentalAssistant: return "🦷"
        case .flightAttendantCert: return "🧳"
        case .teachingCertificate: return "📚"
        case .cosmetology: return "💇"
        case .emt: return "🚑"
        case .cpa: return "📒"
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
    /// Only credentials that *genuinely* require a university degree carry a
    /// tertiary gate (Bar, Board, CPA, Teaching, Nurse, PE, Architect). Trade
    /// licences and the rest are earned through work and an exam, not a diploma,
    /// so they gate on experience (see `minYearsExperience` / `field`) instead.
    var minEQF: Int {
        switch self {
        case .bar:
            return 7  // requires a Doctor of Law (J.D.)
        case .boardCertified:
            return 7  // requires a completed medical doctorate
        case .teachingCertificate, .cpa, .architect, .professionalEngineer:
            return 5  // requires a Bachelor (or final-year status)
        case .nurse:
            return 4  // requires a nursing associate/bachelor degree
        case .drivers, .pilot, .cdl, .commercialPilot,
             .airlineTransportPilot, .securityGuard, .pesticideApplicator:
            return 0  // no education prerequisite — training/hours/exam only
        default:
            return 3  // a high-school baseline for the rest
        }
    }

    /// Minimum years of work experience required before attempting this training.
    /// This is the primary gate for the credentials that are earned on the job
    /// rather than in a lecture hall — trade licences (apprenticeship years), the
    /// airline transport pilot (flight hours), the master trades, and the senior
    /// professional licences. Counted against experience in `field` when set,
    /// else `totalYearsWorked`.
    var minYearsExperience: Int {
        switch self {
        case .airlineTransportPilot: return 5
        case .masterElectrician, .masterPlumber: return 4
        case .professionalEngineer: return 4
        case .boardCertified: return 3
        case .electrician, .plumber: return 3
        case .architect: return 2
        default: return 0
        }
    }

    /// The industry whose on-the-job experience counts toward `minYearsExperience`
    /// — a credential is earned by working *in its field*, not by clocking years
    /// in any job. `nil` falls back to total years worked. Only meaningful where
    /// `minYearsExperience > 0`. Categories are chosen from those the job
    /// catalogue actually uses (pilots sit under `.transportation`) so every
    /// gated credential stays reachable through real jobs.
    var field: JobCategory? {
        switch self {
        case .boardCertified: return .health
        case .professionalEngineer: return .engineering
        case .electrician, .plumber, .masterElectrician, .masterPlumber, .architect:
            return .construction
        case .airlineTransportPilot: return .transportation
        default: return nil
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

    /// Soft skills a completed course nudges upward — the transferable skills the
    /// training builds along the way. Modest by design (a +1 or two): a course is
    /// a nudge, not a substitute for years of practice. Applied once on
    /// completion in `Player.attemptTraining`, capped at the global max of 10.
    var softSkillBoosts: [WeightedAbility] {
        switch self {
        case .cna:
            return [.init(keyPath: \.communicationAndNetworking, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.empathyAndInterpersonalCare, weight: 1)]
        case .dentalAssistant:
            return [.init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .flightAttendantCert:
            return [.init(keyPath: \.communicationAndNetworking, weight: 1),
                    .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)]
        case .teachingCertificate:
            return [.init(keyPath: \.communicationAndNetworking, weight: 1),
                    .init(keyPath: \.presentationAndStorytelling, weight: 1)]
        case .cosmetology:
            return [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                    .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1)]
        case .emt:
            return [.init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.resilienceAndEndurance, weight: 1)]
        case .cpa:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .boardCertified:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.empathyAndInterpersonalCare, weight: 1)]
        case .drivers:
            return [.init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .cdl:
            return [.init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .pilot:
            return [.init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .commercialPilot:
            return [.init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                    .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)]
        case .nurse:
            return [.init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)]
        case .electrician:
            return [.init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)]
        case .plumber:
            return [.init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .bar:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                    .init(keyPath: \.communicationAndNetworking, weight: 1),
                    .init(keyPath: \.presentationAndStorytelling, weight: 1)]
        case .professionalEngineer:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                    .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .architect:
            return [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                    .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .pesticideApplicator:
            return [.init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.outdoorAndWeatherResilience, weight: 1)]
        case .securityGuard:
            return [.init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .masterElectrician:
            return [.init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.leadershipAndInfluence, weight: 1)]
        case .masterPlumber:
            return [.init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.leadershipAndInfluence, weight: 1)]
        case .airlineTransportPilot:
            return [.init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                    .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
                    .init(keyPath: \.leadershipAndInfluence, weight: 1)]
        }
    }

    /// Hard gates on *enrolling* in this training: age, prerequisite trainings,
    /// education (EQF), and — for senior credentials — work experience. Meet them
    /// and the credential is earned; there's no exam roll.
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
        if minYearsExperience > 0 {
            let years = field.map { player.experience[$0] ?? 0 } ?? player.totalYearsWorked
            if years < minYearsExperience {
                let fieldName = field?.rawValue ?? "the workforce"
                return .blocked(reason: "Requires \(minYearsExperience)+ yr(s) in \(fieldName)")
            }
        }
        return .ok
    }
}
