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

extension FameCategory {
    var displayName: String {
        switch self {
        case .entertainment:
            return String(localized: "Entertainment", comment: "A field of fame and of work: film, TV, music, performing and sport. Shown on the fame shelf and in job and industry lists.")  // i18n:ignore translator comment
        case .technology:
            return String(localized: "Technology", comment: "A field of work and fame: computing, software and gadgets (not engineering). Also an industry and a degree field.")  // i18n:ignore translator comment
        case .arts:
            return String(localized: "Arts", comment: "A field of fame: the creative arts - painting, design, writing, language. Plural noun, not the school subject.")  // i18n:ignore translator comment
        case .business:
            return String(localized: "Business", comment: "A field of work and fame: commerce, management and finance. Also a degree field.")  // i18n:ignore translator comment
        case .science:
            return String(localized: "Science", comment: "A field of work and fame: research, labs and discovery. Also a degree field.")  // i18n:ignore translator comment
        }
    }
}

extension WorkSetting {
    var displayName: String {
        switch self {
        case .office:
            return String(localized: "Office", comment: "Where a job is done: at a desk, on a screen. A filter on the jobs list, next to Field and People-facing.")  // i18n:ignore translator comment
        case .field:
            return String(localized: "Field", comment: "Where a job is done: hands-on and on your feet - building sites, kitchens, farms, vehicles. A filter on the jobs list; not a sports field or a field of study.")  // i18n:ignore translator comment
        case .peopleFacing:
            return String(localized: "People-facing", comment: "Where a job is done: dealing with people face to face - serving, teaching, caring, selling. A filter on the jobs list, next to Office and Field.")  // i18n:ignore translator comment
        }
    }
}

extension JobCategory {
    var displayName: String {
        switch self {
        case .engineering:
            return String(localized: "Engineering", comment: "A field of work (job category): designing and building machines, structures and systems. Also a degree field.")  // i18n:ignore translator comment
        case .showBusiness:
            return String(localized: "Show Business", comment: "A field of work (job category): acting, music, film, TV, creators and professional sport.")  // i18n:ignore translator comment
        case .publicServices:
            return String(localized: "Public Services", comment: "A field of work (job category): police, fire brigade, city services - work for the community.")  // i18n:ignore translator comment
        case .health:
            return String(localized: "Health", comment: "A field of work (job category): doctors, nurses and other health-care jobs. Also a degree field.")  // i18n:ignore translator comment
        case .technology:
            return String(localized: "Technology", comment: "A field of work and fame: computing, software and gadgets (not engineering). Also an industry and a degree field.")  // i18n:ignore translator comment
        case .education:
            return String(localized: "Education", comment: "A field of work and an industry: teaching and schools. Also a degree field.")  // i18n:ignore translator comment
        case .agriculture:
            return String(localized: "Agriculture", comment: "A field of work (job category): farming and growing food.")  // i18n:ignore translator comment
        case .design:
            return String(localized: "Design", comment: "A field of work (job category): graphic, product, fashion and game design. Also a degree field.")  // i18n:ignore translator comment
        case .law:
            return String(localized: "Law", comment: "A field of work (job category): lawyers, judges and legal work. Also a degree field.")  // i18n:ignore translator comment
        case .business:
            return String(localized: "Business", comment: "A field of work and fame: commerce, management and finance. Also a degree field.")  // i18n:ignore translator comment
        case .construction:
            return String(localized: "Construction", comment: "A field of work (job category): building homes, roads and cities.")  // i18n:ignore translator comment
        case .retail:
            return String(localized: "Retail", comment: "A field of work (job category): selling goods to customers in shops and online.")  // i18n:ignore translator comment
        case .science:
            return String(localized: "Science", comment: "A field of work and fame: research, labs and discovery. Also a degree field.")  // i18n:ignore translator comment
        case .hospitality:
            return String(localized: "Hospitality", comment: "A field of work (job category): hotels, restaurants, travel and events - looking after guests.")  // i18n:ignore translator comment
        case .service:
            return String(localized: "Personal Services", comment: "A field of work (job category): personal grooming and beauty services such as hairdressing - not public services.")  // i18n:ignore translator comment
        case .manufacturing:
            return String(localized: "Manufacturing", comment: "A field of work (job category): making products in factories and workshops.")  // i18n:ignore translator comment
        case .entrepreneurship:
            return String(localized: "Entrepreneurship", comment: "A field of work (job category): starting and running your own business.")  // i18n:ignore translator comment
        case .transportation:
            return String(localized: "Transportation", comment: "A field of work (job category): moving people and goods by road, air and rail.")  // i18n:ignore translator comment
        case .administration:
            return String(localized: "Administration", comment: "A field of work (job category): office back-room work - accounting, payroll, HR, keeping things organised.")  // i18n:ignore translator comment
        }
    }
}

extension Industry {
    var displayName: String {
        switch self {
        case .software:
            return String(localized: "Software & Internet", comment: "An industry (sector of the economy, what the employer sells): software and online services.")  // i18n:ignore translator comment
        case .hardware:
            return String(localized: "Computing Hardware", comment: "An industry (sector of the economy): computers, chips and electronic devices.")  // i18n:ignore translator comment
        case .telecom:
            return String(localized: "Telecoms", comment: "An industry (sector of the economy): phone and network companies.")  // i18n:ignore translator comment
        case .automotive:
            return String(localized: "Automotive", comment: "An industry (sector of the economy): carmakers and their suppliers.")  // i18n:ignore translator comment
        case .aerospaceDefense:
            return String(localized: "Aerospace & Defence", comment: "An industry (sector of the economy): aircraft, space and the military.")  // i18n:ignore translator comment
        case .energy:
            return String(localized: "Energy & Utilities", comment: "An industry (sector of the economy): power, oil and gas, water.")  // i18n:ignore translator comment
        case .finance:
            return String(localized: "Banking & Finance", comment: "An industry (sector of the economy): banks, insurers and investment firms.")  // i18n:ignore translator comment
        case .healthcare:
            return String(localized: "Healthcare", comment: "An industry (sector of the economy): hospitals, clinics and care services.")  // i18n:ignore translator comment
        case .pharmaBiotech:
            return String(localized: "Pharma & Biotech", comment: "An industry (sector of the economy): medicines and biotechnology.")  // i18n:ignore translator comment
        case .education:
            return String(localized: "Education", comment: "A field of work and an industry: teaching and schools. Also a degree field.")  // i18n:ignore translator comment
        case .government:
            return String(localized: "Government & Public Sector", comment: "An industry (sector of the economy): government and publicly funded bodies.")  // i18n:ignore translator comment
        case .retailTrade:
            return String(localized: "Retail & Consumer", comment: "An industry (sector of the economy): shops and consumer goods.")  // i18n:ignore translator comment
        case .hospitalityTourism:
            return String(localized: "Hospitality & Tourism", comment: "An industry (sector of the economy): hotels, restaurants and travel.")  // i18n:ignore translator comment
        case .mediaEntertainment:
            return String(localized: "Media & Entertainment", comment: "An industry (sector of the economy): publishing, broadcasting, film, music and games - media as in news media.")  // i18n:ignore translator comment
        case .construction:
            return String(localized: "Construction & Property", comment: "An industry (sector of the economy): builders and property developers.")  // i18n:ignore translator comment
        case .agriFood:
            return String(localized: "Agriculture & Food", comment: "An industry (sector of the economy): farming and food production.")  // i18n:ignore translator comment
        case .logistics:
            return String(localized: "Transport & Logistics", comment: "An industry (sector of the economy): freight, delivery, warehouses and airlines.")  // i18n:ignore translator comment
        case .manufacturing:
            return String(localized: "Industrial Manufacturing", comment: "An industry (sector of the economy): factories making machinery and equipment.")  // i18n:ignore translator comment
        case .professionalServices:
            return String(localized: "Professional Services", comment: "An industry (sector of the economy): consultancies, law and accounting firms, agencies - firms that sell expertise.")  // i18n:ignore translator comment
        }
    }
}

extension IndustryClimate {
    /// How an industry is doing this year: "Booming" … "Slump".
    var displayName: String {
        switch self {
        case .boom:
            return String(localized: "Booming", comment: "How an industry is doing this year: the best state, lots of hiring. Next to Growing, Steady, Slowing, Slump.")  // i18n:ignore translator comment
        case .growth:
            return String(localized: "Growing", comment: "How an industry is doing this year: expanding. Next to Booming, Steady, Slowing, Slump.")  // i18n:ignore translator comment
        case .steady:
            return String(localized: "Steady", comment: "How an industry is doing this year: neither growing nor shrinking. Next to Booming, Growing, Slowing, Slump.")  // i18n:ignore translator comment
        case .slowdown:
            return String(localized: "Slowing", comment: "How an industry is doing this year: shrinking a little. Next to Booming, Growing, Steady, Slump.")  // i18n:ignore translator comment
        case .slump:
            return String(localized: "Slump", comment: "How an industry is doing this year: the worst state, with job losses. A noun, as in an economic slump.")  // i18n:ignore translator comment
        }
    }
}

extension Job {
    /// The job's own title, in the player's language (`id` is the English title). Not the same as
    /// `displayTitle` (Job.swift), which is how an *occupation* reads — "CEO, <venture>" for a venture.
    var catalogueTitle: String { L10n.catalogue("job.title.\(id)", english: id) }  // i18n:ignore catalogue key
    /// The role without its seniority ("Software Engineer"), in the player's language.
    var displayBaseTitle: String { L10n.catalogue("job.base.\(baseTitle)", english: baseTitle) }  // i18n:ignore catalogue key
    /// The seniority word ("Senior", "Lead") alone — empty for the bare role.
    var displayRungLabel: String {
        rungLabel.isEmpty ? "" : L10n.catalogue("job.rung.\(rungLabel)", english: rungLabel)  // i18n:ignore catalogue key
    }
    /// What the job is, in a sentence or two.
    var displaySummary: String { L10n.catalogue("job.summary.\(id)", english: summary) }  // i18n:ignore catalogue key
    /// The career ladder named in prose ("as a Teacher"), in the player's language; nil when none.
    var displayExperienceLadder: String? {
        experienceLadder.map { L10n.catalogue("job.ladder.\($0)", english: $0) }  // i18n:ignore catalogue key
    }
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

extension ActivityKind {
    /// The Activities sheet's tab.
    var displayName: String {
        switch self {
        case .sports:       return String(localized: "Sports", comment: "Activities tab: athletic disciplines such as running and soccer")  // i18n:ignore translator comment
        case .artsAndMinds: return String(localized: "Arts & Minds", comment: "Activities tab: creative and mental disciplines such as music, chess and coding")  // i18n:ignore translator comment
        case .study:        return String(localized: "Study", comment: "Activities tab: school subjects such as maths and science")  // i18n:ignore translator comment
        }
    }
}

extension ActivityLevel {
    /// How far along the player is in a discipline, named from the years practised.
    var displayName: String {
        switch self {
        case .beginner:     return String(localized: "Beginner", comment: "Activity level after the first year of practice")  // i18n:ignore translator comment
        case .intermediate: return String(localized: "Intermediate", comment: "Activity level after two to three years of practice")  // i18n:ignore translator comment
        case .advanced:     return String(localized: "Advanced", comment: "Activity level after four to six years of practice")  // i18n:ignore translator comment
        case .expert:       return String(localized: "Expert", comment: "Activity level after seven or more years of practice")  // i18n:ignore translator comment
        }
    }
}

extension Competition.Discipline {
    /// The kind of contest a competition is.
    var displayName: String {
        switch self {
        case .athletic: return String(localized: "Athletic", comment: "Kind of contest: a sports event")  // i18n:ignore translator comment
        case .esports:  return String(localized: "E-Sports", comment: "Kind of contest: a competitive video-gaming tournament")  // i18n:ignore translator comment
        case .creative: return String(localized: "Creative", comment: "Kind of contest: an arts prize")  // i18n:ignore translator comment
        case .mind:     return String(localized: "Mind", comment: "Kind of contest: a contest of the mind such as chess or debate")  // i18n:ignore translator comment
        case .academic: return String(localized: "Academic", comment: "Kind of contest: a school-subject olympiad or fair")  // i18n:ignore translator comment
        }
    }
}

extension Sport {
    /// What the player reads for a discipline ("Martial Arts"); `rawValue` is the id. Also `label`.
    var displayName: String {
        switch self {
        case .running:        return String(localized: "Running", comment: "Sport")  // i18n:ignore translator comment
        case .swimming:       return String(localized: "Swimming", comment: "Sport")  // i18n:ignore translator comment
        case .cycling:        return String(localized: "Cycling", comment: "Sport")  // i18n:ignore translator comment
        case .soccer:         return String(localized: "Soccer", comment: "Sport: team football")  // i18n:ignore translator comment
        case .basketball:     return String(localized: "Basketball", comment: "Sport")  // i18n:ignore translator comment
        case .tennis:         return String(localized: "Tennis", comment: "Sport")  // i18n:ignore translator comment
        case .martialArts:    return String(localized: "Martial Arts", comment: "Sport: karate, judo, boxing")  // i18n:ignore translator comment
        case .gymnastics:     return String(localized: "Gymnastics", comment: "Sport")  // i18n:ignore translator comment
        case .skateboarding:  return String(localized: "Skateboarding & BMX", comment: "Sport")  // i18n:ignore translator comment
        case .esports:        return String(localized: "E-Sports", comment: "Sport: competitive video gaming")  // i18n:ignore translator comment
        case .music:          return String(localized: "Music", comment: "Hobby: learning an instrument")  // i18n:ignore translator comment
        case .drawing:        return String(localized: "Drawing & Painting", comment: "Hobby")  // i18n:ignore translator comment
        case .photography:    return String(localized: "Photography", comment: "Hobby")  // i18n:ignore translator comment
        case .cooking:        return String(localized: "Cooking", comment: "Hobby")  // i18n:ignore translator comment
        case .dance:          return String(localized: "Dance", comment: "Hobby")  // i18n:ignore translator comment
        case .coding:         return String(localized: "Coding", comment: "Hobby: programming")  // i18n:ignore translator comment
        case .chess:          return String(localized: "Chess", comment: "Hobby")  // i18n:ignore translator comment
        case .debate:         return String(localized: "Debate", comment: "Hobby: competitive debating")  // i18n:ignore translator comment
        case .studentCouncil: return String(localized: "Student Council", comment: "School activity: elected pupils' body")  // i18n:ignore translator comment
        case .math:           return String(localized: "Mathematics", comment: "School subject")  // i18n:ignore translator comment
        case .science:        return String(localized: "activity.science", defaultValue: "Science", comment: "School subject (the field of work is a different key)")  // i18n:ignore translator comment
        case .literature:     return String(localized: "Reading & Writing", comment: "School subject")  // i18n:ignore translator comment
        case .history:        return String(localized: "History & Geography", comment: "School subject")  // i18n:ignore translator comment
        case .languages:      return String(localized: "Foreign Languages", comment: "School subject")  // i18n:ignore translator comment
        }
    }
}


// MARK: - Requests from other sections
// Add `extension Type { var displayName: String { … } } // wanted by <section>` here; the owner takes it over.

extension Job {
    /// `displayBaseTitle` for a role known only by its `baseTitle` id — a venture's name in the
    /// "Founder of …" fame-award title. Same lookup as the instance member. // wanted by player model (FameAward)
    static func displayBaseTitle(forBaseTitle baseTitle: String) -> String { baseTitle }
}

// wanted by jobs & skills screens (owner: jobs & catalogue): a role known only by its `baseTitle` id —
// the experience list, the role list's sort — shown in the player's language.
extension JobCatalog {
    static func displayBaseTitle(for baseTitle: String) -> String { baseTitle }
}

// wanted by jobs & skills screens (owner: activities, which awards them): a fame award known by its English
// title id (`FameAward.key`, `Job.breakthroughFame`), shown in the player's language.
extension FameAward {
    static func displayTitle(forId id: String) -> String { id }
    var displayTitle: String { Self.displayTitle(forId: key) }
}
