enum PersonaGroup: String, CaseIterable, Identifiable, Codable {
    case people = "People"
    case tools = "Tools"
    case creative = "Creative"
    case outdoors = "Outdoors"
    case sports = "Sports"
    case science = "Science"
    case mechanical = "Mechanical"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .people: return "🤝"
        case .tools: return "🛠️"
        case .creative: return "🎨"
        case .outdoors: return "🌿"
        case .sports: return "🏅"
        case .science: return "🔬"
        case .mechanical: return "🚂"
        }
    }
    
    var examples: String {
        switch self {
        case .people: return "Helping others, teaching friends, keeping people safe"
        case .tools: return "Building things, fixing stuff, solving puzzles"
        case .creative: return "Drawing, singing, dancing, making cool art"
        case .outdoors: return "Feeding animals, fishing, planting and growing"
        case .sports: return "Running, team games, friendly contests"
        case .science: return "Exploring bugs and stars, trying fun experiments"
        case .mechanical: return "Driving trains and cars, flying drones, using big machines"
        }
    }
}
