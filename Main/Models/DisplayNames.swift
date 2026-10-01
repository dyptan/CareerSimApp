import Foundation

// What the player reads for the game's named things.
//
// **Identity never changes; display is looked up.** `JobCategory.rawValue`, `Job.id`, `Training.rawValue`
// … are English ids: dictionary keys, `Set` members, `Codable` values, test fixtures. They are never
// shown in prose, a title, a button or a list. The player reads `displayName` (enums) or
// `displayTitle` / `displaySummary` (jobs), which are looked up in the String Catalog.
//
//     Text(job.displayTitle)                       // not Text(job.id)
//     L("Years in \(category.displayName)")        // not "\(category.rawValue)"
//
// Never `.capitalized`, `.lowercased()` or `+ "s"` on a display name: they are wrong in German,
// French, Ukrainian … Write the sentence so the name needs no change.
//
// Each section is owned by one part of the localisation work; edit only your own. Until a section's
// owner replaces its stub, a name is its English id, so the game behaves exactly as before.

// MARK: - World: jobs, categories, industries (owner: jobs & catalogue)

extension FameCategory { var displayName: String { rawValue } }
extension WorkSetting { var displayName: String { rawValue } }
extension JobCategory { var displayName: String { rawValue } }
extension Industry { var displayName: String { rawValue } }
extension IndustryClimate { var displayName: String { rawValue } }

extension Job {
    /// The job's own title, in the player's language (`id` is the English title). Not the same as
    /// `displayTitle` (Job.swift), which is how an *occupation* reads — "CEO, <venture>" for a venture.
    var catalogueTitle: String { id }
    /// The role without its seniority ("Software Engineer"), in the player's language.
    var displayBaseTitle: String { baseTitle }
    /// The seniority word ("Senior", "Lead") alone — empty for the bare role.
    var displayRungLabel: String { rungLabel }
    /// What the job is, in a sentence or two.
    var displaySummary: String { summary }
    /// The career ladder named in prose ("as a Teacher"), in the player's language; nil when none.
    var displayExperienceLadder: String? { experienceLadder }
}


// MARK: - Education and training (owner: education & training)

extension Level.Stage {
    /// The stage's generic name ("Bachelor", "High School"). Where a country has its own school names
    /// (Abitur, A-levels) the player reads `Education.degreeName(in:)` instead.
    var displayName: String { Level(stage: self).degree }
}

extension TertiaryProfile {
    /// A field of study as a heading or inside a degree title ("Business", "Health"). Never
    /// `rawValue.capitalized`: that is the English id.
    var displayName: String {
        switch self {
        case .business: return String(localized: "Business", comment: "Field of study (degree subject): business, management and entrepreneurship.")
        case .engineering: return String(localized: "Engineering", comment: "Field of study (degree subject): engineering.")
        case .health: return String(localized: "Health", comment: "Field of study (degree subject): medicine, nursing and care professions.")
        case .arts: return String(localized: "Arts", comment: "Field of study (degree subject): visual, performing and creative arts (music, drawing, acting, cooking).")
        case .science: return String(localized: "Science", comment: "Field of study (degree subject): natural science and research.")
        // A distinct key: the plain word “Education” is also the title of the Education screen.
        case .education: return String(localized: "field.education", defaultValue: "Education", comment: "Field of study (degree subject): teaching and pedagogy (not the Education screen).")
        case .technology: return String(localized: "Technology", comment: "Field of study (degree subject): computing, programming and information technology.")
        case .sports: return String(localized: "Sports", comment: "Field of study (degree subject): sport science, coaching and athletics.")
        case .agriculture: return String(localized: "Agriculture", comment: "Field of study (degree subject): farming and food production.")
        case .law: return String(localized: "Law", comment: "Field of study (degree subject): legal studies.")
        case .design: return String(localized: "Design", comment: "Field of study (degree subject): graphic, product, fashion and interior design.")
        case .service: return String(localized: "Service", comment: "Field of study (degree subject): hospitality, customer service and everyday support roles (the service industry).")
        }
    }
}

extension Training {
    /// The credential's short name — what the player reads in a sentence ("Earn the …") or a list.
    /// `rawValue` is the English id (dictionary keys, saves, requirement tables), never shown.
    /// Many of these are US-specific licences or abbreviations; the comments say which.
    var displayName: String {
        switch self {
        case .cna: return String(localized: "CNA", comment: "Training: Certified Nursing Assistant, a US entry-level nursing credential. Abbreviation (CNA).")
        case .dentalAssistant: return String(localized: "Dental Assistant", comment: "Training: certificate to work as a dental assistant (helps the dentist, takes X-rays).")
        case .flightAttendantCert: return String(localized: "Flight Attendant", comment: "Training: certificate to work as cabin crew on commercial flights.")
        case .teachingCertificate: return String(localized: "Teaching Certificate", comment: "Training: state licence to teach in a public school (US-style teaching credential).")
        case .cosmetology: return String(localized: "Cosmetology Licence", comment: "Training: state licence to cut hair and give skin and nail services in a salon (US-style cosmetology licence).")
        case .emt: return String(localized: "EMT", comment: "Training: Emergency Medical Technician, ambulance crew qualification. Abbreviation (EMT).")
        case .cpa: return String(localized: "CPA", comment: "Training: Certified Public Accountant, a US accounting licence. Abbreviation (CPA); use the local equivalent title if there is one.")
        case .boardCertified: return String(localized: "Board Certification", comment: "Training: specialty board certification for physicians after residency (US medical system).")
        case .pharmacyTechnician: return String(localized: "Pharmacy Technician", comment: "Training: registered pharmacy technician (works under a pharmacist, no doctorate).")
        case .drivers: return String(localized: "Driver's License", comment: "Training: the ordinary car driving licence (US spelling “License”, US Class D).")
        case .cdl: return String(localized: "CDL", comment: "Training: Commercial Driver's License, US licence to drive trucks and buses for work. Abbreviation (CDL).")
        case .pilot: return String(localized: "Pilot", comment: "Training: private pilot licence (flying small planes, not for pay). Short name of the licence, not the job title.")
        case .commercialPilot: return String(localized: "Commercial Pilot", comment: "Training: commercial pilot licence (flying for pay). Short name of the licence, not the job title.")
        case .lpn: return String(localized: "LPN", comment: "Training: Licensed Practical Nurse, a US nursing licence below registered nurse (RN). Abbreviation (LPN).")
        case .nurse: return String(localized: "Nurse License", comment: "Training: licence to work as a registered nurse (RN).")
        case .np: return String(localized: "Nurse Practitioner", comment: "Training: advanced-practice nursing licence (US): an RN who may diagnose, treat and prescribe.")
        case .medicalLicense: return String(localized: "Medical License", comment: "Training: licence to practise medicine as a physician (US spelling “License”).")
        case .dentalLicense: return String(localized: "Dental License", comment: "Training: licence to practise dentistry (US spelling “License”).")
        case .pharmacistLicense: return String(localized: "Pharmacist License", comment: "Training: licence to practise as a pharmacist (US spelling “License”).")
        case .veterinaryLicense: return String(localized: "Veterinary License", comment: "Training: licence to practise veterinary medicine (US spelling “License”).")
        case .electrician: return String(localized: "Electrician License", comment: "Training: journeyman electrician licence (US trades system; US spelling “License”).")
        case .plumber: return String(localized: "Plumber License", comment: "Training: journeyman plumber licence (US trades system; US spelling “License”).")
        case .bar: return String(localized: "Bar Admission", comment: "Training: admission to the bar, the licence to practise as a lawyer (US, state by state).")
        case .professionalEngineer: return String(localized: "Professional Engineer", comment: "Training: Professional Engineer (PE) licence, a US state licence to sign off engineering plans.")
        case .architect: return String(localized: "Architect Licence", comment: "Training: state licence to call yourself an architect and stamp building plans.")
        case .pesticideApplicator: return String(localized: "Pesticide Applicator", comment: "Training: government permit to apply restricted-use pesticides (US-style certification).")
        case .securityGuard: return String(localized: "Security Guard Licence", comment: "Training: state licence to work as a security guard.")
        case .masterElectrician: return String(localized: "Master Electrician License", comment: "Training: senior electrician licence above journeyman (US trades system).")
        case .masterPlumber: return String(localized: "Master Plumber License", comment: "Training: senior plumber licence above journeyman (US trades system).")
        case .airlineTransportPilot: return String(localized: "ATP", comment: "Training: Airline Transport Pilot certificate, the highest US pilot certificate. Abbreviation (ATP).")
        case .airframePowerplant: return String(localized: "A&P Certificate", comment: "Training: Airframe & Powerplant mechanic certificate (US FAA). Abbreviation (A&P).")
        case .policeAcademy: return String(localized: "Police Academy", comment: "Training: recruit training that qualifies you to be sworn in as a police officer.")
        case .psychologyLicense: return String(localized: "Psychologist License", comment: "Training: state licence to practise psychology (US spelling “License”).")
        case .physicalTherapyLicense: return String(localized: "Physical Therapy License", comment: "Training: state licence to practise physical therapy (US spelling “License”).")
        case .epaRefrigerant: return String(localized: "EPA 608", comment: "Training: US EPA Section 608 certification for handling refrigerants. Proper name, US-specific.")
        case .codingBootcamp: return String(localized: "Coding Bootcamp", comment: "Training: an intensive software-development course.")
        case .gameDevProgram: return String(localized: "Game Development Program", comment: "Training: a course in game design and programming.")
        case .productDesign: return String(localized: "Product Design Certificate", comment: "Training: a UX and product-design certificate.")
        case .musicProduction: return String(localized: "Music Production Certificate", comment: "Training: a course in recording, mixing and producing music.")
        }
    }
}


// MARK: - Activities, contests, events (owner: activities)

extension ActivityKind { var displayName: String { rawValue } }
extension ActivityLevel { var displayName: String { rawValue } }
extension Competition.Discipline { var displayName: String { rawValue } }


// MARK: - Requests from other sections
// Add `extension Type { var displayName: String { … } } // wanted by <section>` here; the owner takes it over.
