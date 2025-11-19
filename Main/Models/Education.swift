// Level.swift

import Foundation

// Stage-only representation of education level
struct Level: Codable, Hashable, Identifiable {
    enum Stage: String, CaseIterable, Codable, Hashable {
        case PrimarySchool
        case MiddleSchool
        case HighSchool
        case Vocational
        case Bachelor
        case Master
        case Doctorate
    }

    var stage: Stage

    var id: String { stage.rawValue }

    // EQF mapping by stage
    var eqf: Int {
        switch stage {
        case .PrimarySchool: return 1
        case .MiddleSchool: return 2
        case .HighSchool: return 3
        case .Vocational: return 4
        case .Bachelor: return 5
        case .Master: return 6
        case .Doctorate: return 7
        }
    }

    /// Human-readable generic degree label (EU default)
    var degree: String {
        switch stage {
        case .PrimarySchool: return "Primary School"
        case .MiddleSchool: return "Middle School"
        case .HighSchool: return "High School"
        case .Vocational: return "Vocational Diploma"
        case .Bachelor: return "Bachelor"
        case .Master: return "Master"
        case .Doctorate: return "Doctorate"
        }
    }

    /// Human-readable generic degree label (US variant)
    var degreeUS: String {
        switch stage {
        case .PrimarySchool: return "Elementary School"
        case .MiddleSchool: return "Middle School"
        case .HighSchool: return "High School"
        case .Vocational: return "Trade Certificate"
        case .Bachelor: return "Bachelor’s Degree"
        case .Master: return "Master’s Degree"
        case .Doctorate: return "Doctoral Degree"
        }
    }

    /// Number of in-game years typically needed to complete this level
    func yearsToComplete() -> Int {
        switch stage {
        case .PrimarySchool: return 5
        case .MiddleSchool: return 3
        case .HighSchool: return 3
        case .Vocational: return 2
        case .Bachelor: return 3
        case .Master: return 2
        case .Doctorate: return 3
        }
    }
}

// Profiles for tertiary education
enum TertiaryProfile: String, CaseIterable, Codable, Hashable, Identifiable {
    case business
    case engineering
    case health
    case arts
    case science
    case education
    case technology
    case sports
    case agriculture
    case humanities
    case law
    case design
    case service

    var id: String { rawValue }

    /// Human-readable description for each profile
    var description: String {
        switch self {
        case .business: return "Business, management, and entrepreneurship."
        case .engineering:
            return "Design, build, and solve technical challenges."
        case .health: return "Medical, care, and wellbeing professions."
        case .arts: return "Visual, performing, and creative arts."
        case .science: return "Research, discovery, and experiments."
        case .education: return "Teaching and supporting learners."
        case .technology: return "Computers, programming, and digital."
        case .sports: return "Physical activity, coaching, and competition."
        case .agriculture: return "Farming, food production, and animals."
        case .humanities: return "Culture, history, and society."
        case .law: return "Legal, justice, and social order."
        case .design: return "Making things functional and beautiful."
        case .service: return "Help, care, and support roles."
        }
    }

    /// Short kid-friendly summary (very brief)
    var shortKidSummary: String {
        switch self {
        case .business: return "Learn how to start, run, and grow a company."
        case .engineering: return "Build cool things and solve real problems."
        case .health: return "Help people feel better and stay healthy."
        case .arts: return "Create music, drawings, and performances."
        case .science: return "Explore how the world works with experiments."
        case .education: return "Teach and guide students to learn."
        case .technology: return "Make apps, games, and smart machines."
        case .sports: return "Train bodies and minds to perform their best."
        case .agriculture: return "Grow food and care for plants and animals."
        case .humanities: return "Study people, cultures, and history."
        case .law: return "Learn rules and how to keep things fair."
        case .design: return "Make things useful and beautiful."
        case .service: return "Help others with important everyday tasks."
        }
    }

    /// What the degree means (plain language)
    var degreeMeaning: String {
        switch self {
        case .business:
            return
                "You learn how money, teams, and products work together to make a business succeed."
        case .engineering:
            return
                "You learn math, science, and design to make machines, bridges, and technologies work."
        case .health:
            return
                "You learn how the body works and how to care for people in clinics and hospitals."
        case .arts:
            return
                "You practice creative skills like drawing, music, acting, or cooking to express ideas."
        case .science:
            return
                "You learn to ask questions, test ideas, and discover new knowledge about nature and the universe."
        case .education:
            return
                "You learn how people learn, and how to teach different subjects to students."
        case .technology:
            return
                "You learn coding, systems, and security to build software and manage data."
        case .sports:
            return
                "You learn about movement, training, and health to improve athletic performance."
        case .agriculture:
            return
                "You learn how to grow crops, care for animals, and manage farms sustainably."
        case .humanities:
            return
                "You study language, culture, and history to understand people and societies."
        case .law:
            return
                "You learn rules, rights, and justice systems to help people follow the law."
        case .design:
            return
                "You learn to plan how things look and work so they’re easy and fun to use."
        case .service:
            return
                "You learn practical skills to support people in daily life and at work."
        }
    }

    /// Which jobs this helps you land (examples)
    var helpfulJobs: String {
        switch self {
        case .business:
            return "Manager, marketer, accountant, entrepreneur"
        case .engineering:
            return "Civil, mechanical, electrical, robotics engineer"
        case .health:
            return "Nurse, therapist, lab tech, clinic assistant"
        case .arts:
            return "Designer, musician, chef, actor"
        case .science:
            return "Researcher, lab technician, data analyst"
        case .education:
            return "Teacher, tutor, school counselor"
        case .technology:
            return "Developer, tester, cybersecurity, data engineer"
        case .sports:
            return "Coach, trainer, sports scientist, physiologist"
        case .agriculture:
            return "Farmer, agronomist, animal caretaker"
        case .humanities:
            return "Historian, writer, museum guide, analyst"
        case .law:
            return "Paralegal, legal assistant, compliance officer"
        case .design:
            return "Graphic, UX/UI, fashion, interior designer"
        case .service:
            return "Hospitality worker, customer support, operations"
        }
    }

    /// Broad grouping useful for rules (e.g. STEM vs non-STEM)
    var isSTEM: Bool {
        switch self {
        case .engineering, .science, .technology:
            return true
        default:
            return false
        }
    }

    /// Whether this profile has a sensible Vocational (dual) track
    var allowsVocational: Bool {
        switch self {
        case .engineering, .technology, .health, .agriculture, .design,
            .service, .sports:
            return true
        case .business, .arts, .science, .education, .humanities, .law:
            return false
        }
    }

}

// Concrete education choice: stage + optional profile
struct Education: Codable, Hashable, Identifiable {
    var level: Level.Stage
    var profile: TertiaryProfile?  // nil for early education

    var id: String {
        if let p = profile {
            return "\(level.rawValue)-\(p.rawValue)"
        } else {
            return level.rawValue
        }
    }

    // Convenience initializers
    init(_ level: Level.Stage) {
        self.level = level
        self.profile = nil
    }

    init(_ level: Level.Stage, profile: TertiaryProfile) {
        self.level = level
        self.profile = profile
    }

    // Delegated properties
    var eqf: Int { Level(stage: level).eqf }
    var yearsToComplete: Int { Level(stage: level).yearsToComplete() }

    /// Profile-aware degree label (EU default)
    var degreeName: String {
        switch (level, profile) {
        // Vocational: profile-aware where applicable, generic otherwise
        case (.Vocational, .some(let prof)) where prof.allowsVocational:
            let title = prof.rawValue.capitalized
            return "Vocational Diploma in \(title)"
        case (.Vocational, _):
            return "Vocational Diploma"

        // Bachelor: long names by profile (EU style)
        case (.Bachelor, .some(let prof)):
            switch prof {
            case .business: return "Bachelor of Business Administration"
            case .engineering: return "Bachelor of Engineering"
            case .health: return "Bachelor of Health Sciences"
            case .arts: return "Bachelor of Arts"
            case .science: return "Bachelor of Science"
            case .education: return "Bachelor of Education"
            case .technology:
                return "Bachelor of Science in Information Technology"
            case .agriculture: return "Bachelor of Agriculture"
            case .humanities: return "Bachelor of Arts in Humanities"
            case .law: return "Bachelor of Laws"
            case .design: return "Bachelor of Design"
            case .service: return "Bachelor of Science in Service Management"
            case .sports: return "Bachelor of Science in Sports Science"
            }

        // Master: long names by profile (EU style)
        case (.Master, .some(let prof)):
            switch prof {
            case .business: return "Master of Business Administration"
            case .engineering: return "Master of Engineering"
            case .health: return "Master of Health Sciences"
            case .arts: return "Master of Arts"
            case .science: return "Master of Science"
            case .education: return "Master of Education"
            case .technology:
                return "Master of Science in Information Technology"
            case .agriculture: return "Master of Agriculture"
            case .humanities: return "Master of Arts in Humanities"
            case .law: return "Master of Laws"
            case .design: return "Master of Design"
            case .service: return "Master of Science in Service Management"
            case .sports: return "Master of Science in Sports Science"
            }

        // Doctorate: long names by profile (EU style)
        case (.Doctorate, .some(let prof)):
            switch prof {
            case .business: return "Doctor of Business Administration"
            case .engineering: return "Doctor of Philosophy in Engineering"
            case .health: return "Doctor of Philosophy in Health Sciences"
            case .arts: return "Doctor of Fine Arts"
            case .science: return "Doctor of Philosophy in Science"
            case .education: return "Doctor of Education"
            case .technology:
                return "Doctor of Philosophy in Information Technology"
            case .agriculture: return "Doctor of Philosophy in Agriculture"
            case .humanities: return "Doctor of Philosophy in Humanities"
            case .law: return "Doctor of Juridical Science"
            case .design: return "Doctor of Design"
            case .service: return "Doctor of Philosophy in Service Management"
            case .sports: return "Doctor of Philosophy in Sports Science"
            }

        default:
            // Early education or unsupported combinations
            return Level(stage: level).degree
        }
    }

    /// Profile-aware degree label (US variant)
    var degreeUS: String {
        switch (level, profile) {
        // Vocational
        case (.Vocational, .some(let prof)) where prof.allowsVocational:
            let title = prof.rawValue.capitalized
            return "Associate of Applied Science in \(title)"
        case (.Vocational, _):
            return "Trade Certificate"

        // Bachelor (US style)
        case (.Bachelor, .some(let prof)):
            switch prof {
            case .business: return "Bachelor of Business Administration"
            case .engineering: return "Bachelor of Science in Engineering"
            case .health: return "Bachelor of Science in Health Sciences"
            case .arts: return "Bachelor of Arts in Arts"
            case .science: return "Bachelor of Science"
            case .education: return "Bachelor of Education"
            case .technology:
                return "Bachelor of Science in Information Technology"
            case .agriculture: return "Bachelor of Science in Agriculture"
            case .humanities: return "Bachelor of Arts in Humanities"
            case .law: return "Bachelor of Arts in Law"
            case .design: return "Bachelor of Arts in Design"
            case .service: return "Bachelor of Science in Service Management"
            case .sports: return "Bachelor of Science in Kinesiology"
            }

        // Master (US style)
        case (.Master, .some(let prof)):
            switch prof {
            case .business: return "Master of Business Administration"
            case .engineering: return "Master of Science in Engineering"
            case .health: return "Master of Science in Health Sciences"
            case .arts: return "Master of Arts in Arts"
            case .science: return "Master of Science"
            case .education: return "Master of Education"
            case .technology:
                return "Master of Science in Information Technology"
            case .agriculture: return "Master of Science in Agriculture"
            case .humanities: return "Master of Arts in Humanities"
            case .law: return "Master of Laws"
            case .design: return "Master of Arts in Design"
            case .service: return "Master of Science in Service Management"
            case .sports: return "Master of Science in Kinesiology"
            }

        // Doctorate (US style)
        case (.Doctorate, .some(let prof)):
            switch prof {
            case .business: return "Doctor of Business Administration"
            case .engineering: return "Doctor of Philosophy in Engineering"
            case .health: return "Doctor of Philosophy in Health Sciences"
            case .arts: return "Doctor of Fine Arts"
            case .science: return "Doctor of Philosophy in Science"
            case .education: return "Doctor of Education"
            case .technology:
                return "Doctor of Philosophy in Information Technology"
            case .agriculture: return "Doctor of Philosophy in Agriculture"
            case .humanities: return "Doctor of Philosophy in Humanities"
            case .law: return "Doctor of Juridical Science"
            case .design: return "Doctor of Design"
            case .service: return "Doctor of Philosophy in Service Management"
            case .sports: return "Doctor of Philosophy in Kinesiology"
            }

        default:
            return Level(stage: level).degreeUS
        }
    }
}

func availableNextEducations(holds: [Education]) -> [Education] {
    var available: [Education] = []

    // Default: Always show Bachelor and Vocational options across all profiles
    for profile in TertiaryProfile.allCases {
        // Add Bachelor options for all profiles
        let bachelor = Education(.Bachelor, profile: profile)
        available.append(bachelor)

        // Add Vocational options only for profiles that allow it
        if profile.allowsVocational {
            let vocational = Education(.Vocational, profile: profile)
            available.append(vocational)
        }
    }

    // Check if player holds a Bachelor degree in any profile
    let bachelorDegrees = holds.filter { $0.level == .Bachelor }
    for bachelor in bachelorDegrees {
        if let profile = bachelor.profile {
            let master = Education(.Master, profile: profile)
            available.append(master)
        }
    }

    // Check if player holds a Master degree in any profile
    let masterDegrees = holds.filter { $0.level == .Master }
    for master in masterDegrees {
        if let profile = master.profile {
            let doctorate = Education(.Doctorate, profile: profile)
            available.append(doctorate)
        }
    }

    return available

}
