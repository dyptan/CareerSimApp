import Foundation

enum Software: String, CaseIterable, Codable, Hashable, Identifiable {
    case officeSuite = "Office"
    case gameEngine = "Game Engine"
    case mediaEditing = "Photo/Video Editing"
    case programming = "Programming"

    var id: String { rawValue }

    var pictogram: String {
        switch self {
        case .officeSuite: return "📊"
        case .gameEngine: return "🕹️"
        case .mediaEditing: return "🖌️"
        case .programming: return "💻"
        }
    }
    
    func softwareRequirements(_ player: Player) -> TrainingRequirementResult {
        if player.softSkills.analyticalReasoningAndProblemSolving < 1 {
            return .blocked(reason: "Needs more Problem Solving")
        }
        return .ok(cost: 0)
    }
}
