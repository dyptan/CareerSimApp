enum ProgrammingLanguage: String, Codable, Hashable, CaseIterable, Identifiable {
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
    var languages = Set(ProgrammingLanguage.allCases)
    var portfolioItems = Set(PortfolioItem.allCases)
    var certifications = Set(Certification.allCases)
    var software = Set(Software.allCases)
    var licenses = Set(License.allCases)
}

struct SoftSkills: Codable, Hashable {
    var analyticalReasoningAndProblemSolving: Int = 0
    var creativityAndInsightfulThinking: Int = 0
    var communicationAndNetworking: Int = 0
    var leadershipAndInfluence: Int = 0
    var courageAndRiskTolerance: Int = 0
    var carefulnessAndAttentionToDetail: Int = 0
    var tinkeringAndFingerPrecision: Int = 0
    var spacialNavigation: Int = 0
    var physicalStrength: Int = 0
    var coordinationAndBalance: Int = 0
    var perseveranceAndGrit: Int = 0
    var resilienceAndEndurance: Int = 0

    // Extra fields for game logic, if needed, but avoid duplication with computed aliases!
    var leadershipAndFriends: Int = 0
    var focusAndGrit: Int = 0
    var weatherEndurance: Int = 0
    var entrepreneurship: Int = 0

    static let skillNames: [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String)] = [
        (\.analyticalReasoningAndProblemSolving, "Problem Solving", "🧩"),
        (\.creativityAndInsightfulThinking, "Creativity", "🎨"),
        (\.communicationAndNetworking, "Communication", "💬"),
        (\.leadershipAndInfluence, "Leadership", "👥"),
        (\.courageAndRiskTolerance, "Courage", "🎲"),
        (\.carefulnessAndAttentionToDetail, "Carefulness", "🔎"),
        (\.tinkeringAndFingerPrecision, "Tinkering", "🔧"),
        (\.spacialNavigation, "Navigation", "🧭"),
        (\.physicalStrength, "Strength", "💪"),
        (\.coordinationAndBalance, "Coordination", "🤸"),
        (\.perseveranceAndGrit, "Perseverance", "🛡️"),
        (\.resilienceAndEndurance, "Endurance", "🌦️")
    ]

    // Short computed aliases
    var problemSolving: Int {
        get { analyticalReasoningAndProblemSolving }
        set { analyticalReasoningAndProblemSolving = newValue }
    }
    var creativity: Int {
        get { creativityAndInsightfulThinking }
        set { creativityAndInsightfulThinking = newValue }
    }
    var communication: Int {
        get { communicationAndNetworking }
        set { communicationAndNetworking = newValue }
    }
    var leadership: Int {
        get { leadershipAndInfluence }
        set { leadershipAndInfluence = newValue }
    }
    var courage: Int {
        get { courageAndRiskTolerance }
        set { courageAndRiskTolerance = newValue }
    }
    var carefulness: Int {
        get { carefulnessAndAttentionToDetail }
        set { carefulnessAndAttentionToDetail = newValue }
    }
    var tinkering: Int {
        get { tinkeringAndFingerPrecision }
        set { tinkeringAndFingerPrecision = newValue }
    }
    var navigation: Int {
        get { spacialNavigation }
        set { spacialNavigation = newValue }
    }
    var strength: Int {
        get { physicalStrength }
        set { physicalStrength = newValue }
    }
    var stamina: Int {
        get { resilienceAndEndurance }
        set { resilienceAndEndurance = newValue }
    }
    var perseverance: Int {
        get { perseveranceAndGrit }
        set { perseveranceAndGrit = newValue }
    }
    // Add similar computed properties for 'focusAndGrit', 'leadershipAndFriends', etc. if needed
}
