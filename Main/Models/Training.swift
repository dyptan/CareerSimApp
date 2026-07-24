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
    case lpn = "LPN"
    case nurse = "Nurse License"
    case np = "Nurse Practitioner"
    case medicalLicense = "Medical License"
    case dentalLicense = "Dental License"
    case pharmacistLicense = "Pharmacist License"
    case veterinaryLicense = "Veterinary License"
    case atcCertification = "ATC Certification"
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

    // MARK: Skill-building programs (creative & digital fields)
    // Non-statutory, non-gating credentials for fields that legally require none
    // — tech, games, design, and show business. They earn no licence; their value
    // is the edge they give in landing a job in the field or launching a venture
    // there (see `careerBoost`), plus the soft skills they build.
    case codingBootcamp = "Coding Bootcamp"
    case gameDevProgram = "Game Development Program"
    case productDesign = "Product Design Certificate"
    // NOTE: serious acting training is a multi-year performing-arts degree, not a
    // one-year credential — it lives in the education system as an Arts degree
    // (see `TertiaryProfile.arts`), so it isn't a Training here.
    case musicProduction = "Music Production Certificate"

    var id: String { rawValue }

    /// Legally-mandated credentials (former licences). These hard-gate hiring in
    /// every field; non-statutory trainings (former certifications) gate hiring
    /// only in regulated industries (see `Job.hardSkillsMet`).
    var isStatutory: Bool {
        switch self {
        case .drivers, .cdl, .pilot, .commercialPilot, .lpn, .nurse, .np,
             .medicalLicense, .dentalLicense, .pharmacistLicense, .veterinaryLicense,
             .atcCertification, .electrician, .plumber, .bar, .professionalEngineer,
             .architect, .pesticideApplicator, .securityGuard, .masterElectrician,
             .masterPlumber, .airlineTransportPilot:
            return true
        default:
            return false
        }
    }

    /// Display name in the activity → (credential) style: the course or school
    /// you attend, with the qualification it earns in parentheses.
    var friendlyName: String {
        switch self {
        case .cna: return "Nursing Assistant Course (CNA)"
        case .dentalAssistant: return "Dental Assisting Course (Dental Assistant)"
        case .flightAttendantCert: return "Cabin Crew Training (Flight Attendant Certificate)"
        case .teachingCertificate: return "Teacher Training (Teaching Certificate)"
        case .cosmetology: return "Cosmetology School (Cosmetology License)"
        case .emt: return "EMT Course (Emergency Medical Technician)"
        case .cpa: return "Accounting Program (CPA License)"
        case .boardCertified: return "Medical Residency (Board Certification)"
        case .drivers: return "Driving School (Class D Driver's License)"
        case .cdl: return "Truck Driving School (Commercial Driver's License)"
        case .pilot: return "Flight School (Private Pilot License)"
        case .commercialPilot: return "Flight School (Commercial Pilot License)"
        case .lpn: return "Practical Nursing Program (LPN License)"
        case .nurse: return "Nursing Board Exam (RN License)"
        case .np: return "Nurse Practitioner Program (NP License)"
        case .medicalLicense: return "Medical Board Exam (Medical License)"
        case .dentalLicense: return "Dental Board Exam (Dental License)"
        case .pharmacistLicense: return "Pharmacy Board Exam (Pharmacist License)"
        case .veterinaryLicense: return "Veterinary Board Exam (Veterinary License)"
        case .atcCertification: return "FAA Academy (Air Traffic Control Certification)"
        case .electrician: return "Journeyman Electrician Exam (Electrician License)"
        case .plumber: return "Journeyman Plumber Exam (Plumber License)"
        case .bar: return "Law Bar Exam (Bar Admission)"
        case .professionalEngineer: return "PE Licensure (Professional Engineer)"
        case .architect: return "Architecture Licensure (Architect License)"
        case .pesticideApplicator: return "Applicator Course (Pesticide License)"
        case .securityGuard: return "Guard Training (Security Guard License)"
        case .masterElectrician: return "Master Electrician Program (Master Electrician License)"
        case .masterPlumber: return "Master Plumber Program (Master Plumber License)"
        case .airlineTransportPilot: return "Airline Pilot Training (ATP Certificate)"
        case .codingBootcamp: return "Coding Bootcamp (Full-Stack Certificate)"
        case .gameDevProgram: return "Game Dev Program (Game Development Certificate)"
        case .productDesign: return "Design Program (Product Design Certificate)"
        case .musicProduction: return "Music Production Course (Production Certificate)"
        }
    }

    /// Plain-language explanation of the training, for the in-game info popover.
    var description: String {
        switch self {
        case .cna: return "Certified Nursing Assistant. The first step into nursing — basic patient care under a nurse’s supervision."
        case .dentalAssistant: return "Trained to help dentists during procedures, take X-rays, and prepare patients."
        case .flightAttendantCert: return "FAA-issued certificate proving you can keep passengers safe on commercial flights."
        case .teachingCertificate: return "State license to teach in a public school. Earned after a teacher-training program and supervised classroom hours."
        case .cosmetology: return "State license to cut hair and provide skin and nail services in a salon. Earned after attending a cosmetology school and passing a state exam."
        case .emt: return "Emergency Medical Technician — qualifies you to provide pre-hospital emergency care on an ambulance crew. The first step toward becoming a paramedic."
        case .cpa: return "Certified Public Accountant — the licence required to sign off on tax filings, audit financial statements, and lead corporate finance roles."
        case .boardCertified: return "Specialty board certification earned after residency — the standard credential for attending physicians and medical leadership. Verifies mastery of a medical specialty."
        case .drivers: return "Standard Class D car license. Needed for most jobs that involve any driving."
        case .cdl: return "Commercial Driver’s License — required to drive trucks, buses, and large delivery vehicles for paid work."
        case .pilot: return "Private pilot license — lets you fly small planes for fun, but not for paid work."
        case .commercialPilot: return "Lets you fly planes for paid work — required to be hired by airlines and freight carriers."
        case .lpn: return "Licensed Practical Nurse — a state license to give basic nursing care under an RN or physician. Earned through a roughly one-year practical-nursing program and the NCLEX-PN exam. The common step up from a nursing aide toward becoming an RN."
        case .nurse: return "Government license to work as a nurse. Earned after passing a national exam following a nursing degree."
        case .np: return "Nurse Practitioner — an advanced-practice license letting an RN diagnose, treat, and prescribe with real autonomy. Earned after a Master of Science in Nursing on top of RN licensure and bedside experience."
        case .medicalLicense: return "State license to practice medicine as a physician. Earned after medical school by passing the national licensing exam (USMLE) — the credential every doctor must hold to treat patients."
        case .dentalLicense: return "State license to practice dentistry. Earned after dental school (DDS/DMD) and the national and state board exams."
        case .pharmacistLicense: return "State license to practice as a pharmacist. Earned after a Doctor of Pharmacy (PharmD) and the national board exam (NAPLEX)."
        case .veterinaryLicense: return "State license to practice veterinary medicine. Earned after a Doctor of Veterinary Medicine (DVM) and the national board exam (NAVLE)."
        case .atcCertification: return "FAA certification to safely direct air traffic. Earned at the FAA Academy — required to work as an air traffic controller."
        case .electrician: return "Government license to wire buildings safely. Earned after an apprenticeship and an exam."
        case .plumber: return "Government license to install and repair pipes, drains, and water systems. Earned after an apprenticeship and a journeyman exam."
        case .bar: return "Bar admission — the state-by-state exam and ethics review you must pass after law school before you can practice as a lawyer in court."
        case .professionalEngineer: return "Professional Engineer (PE) — state licence required to sign off on engineering plans for buildings, bridges, and public works. Needed for senior civil, mechanical, and electrical engineering roles."
        case .architect: return "State license required to call yourself an Architect and stamp building plans. Earned after a degree, multi-year internship, and a national exam (NCARB)."
        case .pesticideApplicator: return "Government permit to apply restricted-use pesticides on farms or commercial landscapes. Required for many farming, landscaping, and pest-control jobs."
        case .securityGuard: return "State license required to work as an unarmed security guard. Covers law, ethics, and basic emergency response."
        case .masterElectrician: return "The senior electrician license. Earned after years as a licensed journeyman, it lets you pull permits, run jobs, and supervise apprentices — required to become a Master Electrician."
        case .masterPlumber: return "The senior plumbing license. Earned after journeyman experience, it lets you design systems, pull permits, and lead a crew — required to become a Master Plumber."
        case .airlineTransportPilot: return "The highest-level pilot certificate. Required to serve as captain (pilot-in-command) of a commercial airliner."
        case .codingBootcamp: return "An intensive full-stack software program. No licence — but the skills and portfolio it builds give you a real edge landing tech and engineering roles, and launching a software venture of your own."
        case .gameDevProgram: return "A studio-style program in game design and engine programming. Builds the craft to break into a gaming studio — or to ship your own indie title."
        case .productDesign: return "A UX and product-design certificate: research, prototyping, and visual craft. Opens doors in design and fashion studios and sharpens the eye a design-led venture lives or dies by."
        case .musicProduction: return "Training in recording, mixing, and producing music. Builds the technical craft behind a career in show business — and behind releasing work that actually gets noticed."
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
        case .lpn: return "💉"
        case .nurse: return "🩺"
        case .np: return "🥼"
        case .medicalLicense: return "⚕️"
        case .dentalLicense: return "🦷"
        case .pharmacistLicense: return "💊"
        case .veterinaryLicense: return "🐾"
        case .atcCertification: return "🗼"
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
        case .codingBootcamp: return "💻"
        case .gameDevProgram: return "🎮"
        case .productDesign: return "🎨"
        case .musicProduction: return "🎚️"
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
        case .medicalLicense, .dentalLicense, .pharmacistLicense, .veterinaryLicense:
            return 7  // requires the profession's doctorate (MD/DDS/PharmD/DVM)
        case .np:
            return 6  // requires a Master of Science in Nursing (MSN)
        case .teachingCertificate, .cpa, .architect, .professionalEngineer:
            return 5  // requires a Bachelor (or final-year status)
        case .nurse:
            return 4  // requires a nursing associate/bachelor degree
        case .drivers, .pilot, .cdl, .commercialPilot,
             .airlineTransportPilot, .securityGuard, .pesticideApplicator,
             .atcCertification:
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
        case .np: return 2
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
        case .boardCertified, .np: return .health
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
        case .np: return [.nurse]
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
        case .lpn:
            return [.init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.resilienceAndEndurance, weight: 1)]
        case .nurse:
            return [.init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)]
        case .np:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                    .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
                    .init(keyPath: \.leadershipAndInfluence, weight: 1)]
        case .medicalLicense:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.empathyAndInterpersonalCare, weight: 1)]
        case .dentalLicense:
            return [.init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.empathyAndInterpersonalCare, weight: 1)]
        case .pharmacistLicense:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .veterinaryLicense:
            return [.init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                    .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)]
        case .atcCertification:
            return [.init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                    .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
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
        case .codingBootcamp:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 1)]
        case .gameDevProgram:
            return [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                    .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)]
        case .productDesign:
            return [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .musicProduction:
            return [.init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                    .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1)]
        }
    }

    /// The hiring/founding edge a *non-gating* skill-building credential confers,
    /// and the fields it applies to. Unlike the licences and role-defining certs —
    /// whose value is the hard gate they clear — these modern programs (coding,
    /// game dev, design, performing arts) legally gate nothing, so their payoff is
    /// this soft probability lift: a relevant credential meaningfully raises the
    /// odds of being hired into the field (`Job.hireProbability`) and of a venture
    /// in it succeeding (`Job.founderSuccessProbability`). `nil` for the licences,
    /// which don't move the odds — they open (or close) the door outright.
    var careerBoost: CareerBoost? {
        switch self {
        case .codingBootcamp:     return CareerBoost(categories: [.technology, .engineering], weight: 0.15)
        case .gameDevProgram:     return CareerBoost(categories: [.gaming, .technology], weight: 0.15)
        case .productDesign:      return CareerBoost(categories: [.design, .fashion], weight: 0.15)
        case .musicProduction:    return CareerBoost(categories: [.showBusiness], weight: 0.12)
        default:                  return nil
        }
    }

    /// A credential's soft edge in one or more career fields (see `careerBoost`).
    struct CareerBoost {
        /// Job categories the credential helps you land a role in / found a
        /// venture in.
        let categories: Set<JobCategory>
        /// Additive probability lift, applied in the field's hire/founder odds.
        let weight: Double
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
