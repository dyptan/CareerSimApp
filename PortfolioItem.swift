// PortfolioItem.swift
import Foundation

enum PortfolioItem: String, CaseIterable, Codable, Hashable, Identifiable {
    case app = "App"
    case game = "Game"
    case website = "Website"
    case presentation = "Presentation"
    case paper = "Paper"
    case library = "Library"

    var id: String { rawValue }

    var pictogram: String {
        switch self {
        case .app: return "📱"
        case .game: return "🎮"
        case .website: return "🕸️"
        case .presentation: return "🖼️"
        case .paper: return "📄"
        case .library: return "📦"
        }
    }

    // Prerequisites for each portfolio item
    func portfolioRequirements(_ player: Player) -> TrainingRequirementResult {
        switch self {
        case .app, .game, .website, .library:
            if !player.hardSkills.software.contains(.programming) {
                return .blocked(reason: "Requires Programming")
            }
            return .ok(cost: 0)
        case .presentation:
            if player.softSkills.presentationAndStorytelling < 1 {
                return .blocked(reason: "Needs Presentation")
            }
            return .ok(cost: 0)
        case .paper:
            if player.softSkills.analyticalReasoningAndProblemSolving < 1
                && player.softSkills.selfDisciplineAndStudyHabits < 1 {
                return .blocked(reason: "Needs Study Habits or Problem Solving")
            }
            return .ok(cost: 0)
        }
    }
}
