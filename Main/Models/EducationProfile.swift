import Foundation

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
    case law
    case design
    case service

    var id: String { rawValue }

    var description: String {
        switch self {
        case .business: return L("Business, management, and entrepreneurship.")
        case .engineering:
            return L("Design, build, and solve technical challenges.")
        case .health: return L("Medical, care, and wellbeing professions.")
        case .arts: return L("Visual, performing, and creative arts.")
        case .science: return L("Research, discovery, and experiments.")
        case .education: return L("Teaching and supporting learners.")
        case .technology: return L("Computers, programming, and digital.")
        case .sports: return L("Physical activity, coaching, and competition.")
        case .agriculture: return L("Farming, food production, and animals.")
        case .law: return L("Legal, justice, and social order.")
        case .design: return L("Making things functional and beautiful.")
        case .service: return L("Help, care, and support roles.")
        }
    }

    var shortKidSummary: String {
        switch self {
        case .business: return L("Learn how to start, run, and grow a company.")
        case .engineering: return L("Build cool things and solve real problems.")
        case .health: return L("Help people feel better and stay healthy.")
        case .arts: return L("Create music, drawings, and performances.")
        case .science: return L("Explore how the world works with experiments.")
        case .education: return L("Teach and guide students to learn.")
        case .technology: return L("Make apps, games, and smart machines.")
        case .sports: return L("Train bodies and minds to perform their best.")
        case .agriculture: return L("Grow food and care for plants and animals.")
        case .law: return L("Learn rules, rights, and justice systems to help people follow the law.")
        case .design: return L("Make things useful and beautiful.")
        case .service: return L("Help others with important everyday tasks.")
        }
    }

    var degreeMeaning: String {
        switch self {
        case .business:
            return L("You learn how money, teams, and products work together to make a business succeed.")
        case .engineering:
            return L("You learn math, science, and design to make machines, bridges, and technologies work.")
        case .health:
            return L("You learn how the body works and how to care for people in clinics and hospitals.")
        case .arts:
            return L("You practice creative skills like drawing, music, acting, or cooking to express ideas.")
        case .science:
            return L("You learn to ask questions, test ideas, and discover new knowledge about nature and the universe.")
        case .education:
            return L("You learn how people learn, and how to teach different subjects to students.")
        case .technology:
            return L("You learn coding, systems, and security to build software and manage data.")
        case .sports:
            return L("You learn about movement, training, and health to improve athletic performance.")
        case .agriculture:
            return L("You learn how to grow crops, care for animals, and manage farms sustainably.")
        case .law:
            return L("You learn rules, rights, and justice systems to help people follow the law.")
        case .design:
            return L("You learn to plan how things look and work so they’re easy and fun to use.")
        case .service:
            return L("You learn practical skills to support people in daily life and at work.")
        }
    }

    var helpfulJobs: String {
        switch self {
        case .business:
            return L("Manager, marketer, accountant, entrepreneur")
        case .engineering:
            return L("Civil, mechanical, electrical, robotics engineer")
        case .health:
            return L("Nurse, therapist, lab tech, clinic assistant")
        case .arts:
            return L("Designer, musician, chef, actor")
        case .science:
            return L("Researcher, lab technician, data analyst")
        case .education:
            return L("Teacher, tutor, school counselor")
        case .technology:
            return L("Developer, tester, cybersecurity, data engineer")
        case .sports:
            return L("Coach, trainer, sports scientist, physiologist")
        case .agriculture:
            return L("Farmer, agronomist, animal caretaker")
        case .law:
            return L("Paralegal, legal assistant, compliance officer")
        case .design:
            return L("Graphic, UX/UI, fashion, interior designer")
        case .service:
            return L("Hospitality worker, customer support, operations")
        }
    }

    var isSTEM: Bool {
        switch self {
        case .engineering, .science, .technology:
            return true
        default:
            return false
        }
    }

    /// Whether the profile leads primarily into white-collar work — the
    /// knowledge-economy and professional fields where an elite-tier
    /// institution's prestige actually opens doors. Blue-collar / service /
    /// athletic paths are hidden from elite tier in `InstitutionTiersView`.
    var isWhiteCollar: Bool {
        switch self {
        case .business, .engineering, .health, .arts, .science, .education,
             .technology, .law, .design:
            return true
        case .sports, .agriculture, .service:
            return false
        }
    }

    var allowsVocational: Bool {
        switch self {
        case .engineering, .technology, .health, .agriculture, .design, .service, .sports:
            return true
        case .business, .arts, .science, .education, .law:
            return false
        }
    }
}
