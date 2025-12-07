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

    // Software needed to reasonably complete this portfolio item
    var requiredSoftware: Set<Software> {
        switch self {
        case .app:
            return [.programming]
        case .game:
            return [.programming, .gameEngine]
        case .website:
            // Graphic design represented by mediaEditing
            return [.programming, .mediaEditing]
        case .library:
            return [.programming]
        case .paper:
            return [.officeSuite]
        case .presentation:
            return [.officeSuite, .mediaEditing]
        }
    }

    // Gate selection based on required software the player already has
    func portfolioRequirements(_ player: Player) -> TrainingRequirementResult {
        let owned = player.hardSkills.software
        let missing = requiredSoftware.subtracting(owned)
        guard missing.isEmpty else {
            let reason = "Needs " + missing
                .map { $0.rawValue }
                .sorted()
                .joined(separator: ", ")
            return .blocked(reason: reason)
        }
        // No cost to add a portfolio item once requirements are met
        return .ok(cost: 0)
    }
}
