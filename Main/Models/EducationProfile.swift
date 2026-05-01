import Foundation

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
        case .law: return "Learn rules, rights, and justice systems to help people follow the law."
        case .design: return "Make things useful and beautiful."
        case .service: return "Help others with important everyday tasks."
        }
    }

    /// What the degree means (plain language)
    var degreeMeaning: String {
        switch self {
        case .business:
            return "You learn how money, teams, and products work together to make a business succeed."
        case .engineering:
            return "You learn math, science, and design to make machines, bridges, and technologies work."
        case .health:
            return "You learn how the body works and how to care for people in clinics and hospitals."
        case .arts:
            return "You practice creative skills like drawing, music, acting, or cooking to express ideas."
        case .science:
            return "You learn to ask questions, test ideas, and discover new knowledge about nature and the universe."
        case .education:
            return "You learn how people learn, and how to teach different subjects to students."
        case .technology:
            return "You learn coding, systems, and security to build software and manage data."
        case .sports:
            return "You learn about movement, training, and health to improve athletic performance."
        case .agriculture:
            return "You learn how to grow crops, care for animals, and manage farms sustainably."
        case .humanities:
            return "You study language, culture, and history to understand people and societies."
        case .law:
            return "You learn rules, rights, and justice systems to help people follow the law."
        case .design:
            return "You learn to plan how things look and work so they’re easy and fun to use."
        case .service:
            return "You learn practical skills to support people in daily life and at work."
        }
    }

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

    var isSTEM: Bool {
        switch self {
        case .engineering, .science, .technology:
            return true
        default:
            return false
        }
    }

    var allowsVocational: Bool {
        switch self {
        case .engineering, .technology, .health, .agriculture, .design, .service, .sports:
            return true
        case .business, .arts, .science, .education, .humanities, .law:
            return false
        }
    }
}
