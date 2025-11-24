import Foundation

enum PortfolioItem: String, CaseIterable, Codable, Hashable, Identifiable {
    case app = "App"
    case game = "Game"
    case website = "Website"
    case library = "Library"
    case paper = "Paper"
    case presentation = "Presentation"

    var id: String { rawValue }

    var pictogram: String {
        switch self {
        case .app: return "📱"
        case .game: return "🎮"
        case .website: return "🌐"
        case .library: return "📦"
        case .paper: return "📄"
        case .presentation: return "🖥️"
        }
    }
}
