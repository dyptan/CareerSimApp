import Foundation

enum ProgrammingLanguage: String, CaseIterable, Codable, Hashable, Identifiable {
    case english = "English"
    case swift = "Swift"
    case python = "Python"
    case java = "Java"
    case C = "C"

    var id: String { rawValue }

    var pictogram: String {
        switch self {
        case .english: return "🗣️"
        case .swift: return "🦅"
        case .python: return "🐍"
        case .java: return "☕️"
        case .C: return "🔧"
        }
    }
}
