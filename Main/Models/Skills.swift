enum Language: String, Codable, Hashable, CaseIterable, Identifiable {
    case swift = "swift"
    case C = "C"
    case python = "python"
    case java = "java"
    case english = "english"
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .swift: return "🦅"
        case .C: return "💾"
        case .python: return "🐍"
        case .java: return "☕️"
        case .english: return "🇬🇧"
        }
    }
}

enum PortfolioItem: String, Codable, Hashable, CaseIterable, Identifiable {
    case app, website, game, library, paper, presentation
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .app: return "📱"
        case .website: return "🌐"
        case .game: return "🎮"
        case .library: return "📚"
        case .paper: return "📄"
        case .presentation: return "📊"
        }
    }
}

enum Certification: String, Codable, Hashable, CaseIterable, Identifiable{
    case aws, azure, google, scrum, security
    // Skilled trades
    case cwi           // Certified Welding Inspector
    case epa608        // EPA 608 (HVAC)
    case nate          // NATE (HVAC)
    case faaAMP        // FAA A&P (Aircraft Mechanic)
    // Healthcare support
    case cna           // Certified Nursing Assistant
    case dentalAssistant
    case medicalAssistant
    case pharmacyTech
    // Business and finance
    case cfp           // Certified Financial Planner
    case series65
    // Transportation and logistics
    case flightAttendantCert
    
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .aws: return "☁️"
        case .azure: return "🌥️"
        case .google: return "🔎"
        case .scrum: return "🏉"
        case .security: return "🔒"
        case .cwi: return "🧪"
        case .epa608: return "🌡️"
        case .nate: return "❄️"
        case .faaAMP: return "✈️"
        case .cna: return "🩺"
        case .dentalAssistant: return "🦷"
        case .medicalAssistant: return "🏥"
        case .pharmacyTech: return "💊"
        case .cfp: return "📈"
        case .series65: return "💹"
        case .flightAttendantCert: return "🛫"
        }
    }
    
    var friendlyName: String {
        switch self {
        case .aws: return "AWS Cloud Badge \(pictogram)"
        case .azure: return "Azure Cloud Badge \(pictogram)"
        case .google: return "Google Tech Badge \(pictogram)"
        case .scrum: return "Teamwork (Scrum) Badge \(pictogram)"
        case .security: return "Online Safety Badge \(pictogram)"
        case .cwi: return "Welding Inspector (CWI) \(pictogram)"
        case .epa608: return "HVAC Clean Air (EPA 608) \(pictogram)"
        case .nate: return "HVAC Pro (NATE) \(pictogram)"
        case .faaAMP: return "Airplane Fixer (FAA A&P) \(pictogram)"
        case .cna: return "Care Helper (CNA) \(pictogram)"
        case .dentalAssistant: return "Tooth Helper (Dental Assistant) \(pictogram)"
        case .medicalAssistant: return "Clinic Helper (Medical Assistant) \(pictogram)"
        case .pharmacyTech: return "Medicine Helper (Pharmacy Tech) \(pictogram)"
        case .cfp: return "Money Planner (CFP) \(pictogram)"
        case .series65: return "Investing Helper (Series 65) \(pictogram)"
        case .flightAttendantCert: return "Flight Helper (Attendant Cert) \(pictogram)"
        }
    }
}

enum Software: String, Codable, Hashable, CaseIterable, Identifiable {
    case macOS, linux, unity, photoshop, blender, excel
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .macOS: return "🍏"
        case .linux: return "🐧"
        case .unity: return "🕹️"
        case .photoshop: return "🖌️"
        case .blender: return "🎨"
        case .excel: return "📊"
        }
    }
}

enum License: String, Codable, Hashable, CaseIterable, Identifiable {
    case drivers, pilot, nurse
    case electrician
    case plumber
    case cdl
    case commercialPilot
    case realEstateAgent
    case insuranceAgent
    
    var id: String { rawValue }
    
    var pictogram: String {
        switch self {
        case .drivers: return "🚗"
        case .pilot: return "✈️"
        case .nurse: return "🩺"
        case .electrician: return "🔌"
        case .plumber: return "🔧"
        case .cdl: return "🚚"
        case .commercialPilot: return "🛫"
        case .realEstateAgent: return "🏠"
        case .insuranceAgent: return "🛡️"
        }
    }
    
    var friendlyName: String {
        switch self {
        case .drivers: return "Driver’s License \(pictogram)"
        case .pilot: return "Pilot License \(pictogram)"
        case .nurse: return "Nurse License \(pictogram)"
        case .electrician: return "Electrician License \(pictogram)"
        case .plumber: return "Plumber License \(pictogram)"
        case .cdl: return "Commercial Driver’s License \(pictogram)"
        case .commercialPilot: return "Commercial Pilot License \(pictogram)"
        case .realEstateAgent: return "Real Estate Agent License \(pictogram)"
        case .insuranceAgent: return "Insurance Agent License \(pictogram)"
        }
    }
}

struct HardSkills: Codable, Hashable {
    var languages = Set(Language.allCases)
    var portfolioItems = Set(PortfolioItem.allCases)
    var certifications = Set(Certification.allCases)
    var software = Set(Software.allCases)
    var licenses = Set(License.allCases)
}

struct SoftSkills: Codable, Hashable {
    // Kid-friendly names
    var problemSolving: Int            // was analyticalReasoning
    var creativity: Int                // was creativeExpression
    var communication: Int             // was socialCommunication
    var leadershipAndFriends: Int      // merged teamLeadership + influenceAndNetworking
    var riskTaking: Int                // was riskTolerance
    var navigation: Int                // was spatialThinking
    var carefulness: Int               // was attentionToDetail
    var tinkering: Int                 // was mechanicalOperation
    var strength: Int                  // was physicalAbility
    var focusAndGrit: Int              // was resilienceCognitive
    var stamina: Int                   // was resiliencePhysical
    var weatherEndurance: Int          // was outdoorOrientation
    var entrepreneurship: Int          // was opportunityRecognition

    static let skillNames: [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String)] = [
        (\.problemSolving, "Problem Solving", "🧩"),
        (\.creativity, "Creativity", "🎨"),
        (\.communication, "Communication", "💬"),
        (\.leadershipAndFriends, "Leadership & Friends", "👥🤝"),
        (\.riskTaking, "Risk Taking", "🎲"),
        (\.navigation, "Navigation", "🧭"),
        (\.carefulness, "Carefulness", "🔎"),
        (\.tinkering, "Tinkering", "🔧"),
        (\.strength, "Strength", "💪"),
        (\.focusAndGrit, "Focus & Grit", "🧠💪"),
        (\.stamina, "Stamina", "🛡️"),
        (\.weatherEndurance, "Weather Endurance", "🌦️💪"),
        (\.entrepreneurship, "Entrepreneurship", "💡💼")
    ]
}
