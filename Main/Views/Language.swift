import Foundation

enum Language: String, CaseIterable, Codable, Hashable, Identifiable {
    case english = "English"
    case french = "French"
    case spanish = "Spanish"
    case german = "German"
    case chinese = "Chinese"
    case japanese = "Japanese"
    case russian = "Russian"
    case italian = "Italian"
    case portuguese = "Portuguese"
    case arabic = "Arabic"
    // Add other languages as needed

    var id: String { rawValue }

    var pictogram: String {
        switch self {
        case .english: return "🇬🇧"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        case .chinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .russian: return "🇷🇺"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .arabic: return "🇸🇦"
        }
    }
}
