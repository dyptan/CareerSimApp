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
    
    var softSkillThresholds: [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch self {
        case .officeSuite:
            return [
                (\.selfDisciplineAndPerseverance, 2),
                (\.timeManagementAndPlanning, 1),
            ]
        case .programming:
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.patienceAndPerseverance, 2),
            ]
        case .mediaEditing:
            return [
                (\.creativityAndInsightfulThinking, 3),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .gameEngine:
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.creativityAndInsightfulThinking, 3),
            ]
        }
    }

    func softwareRequirements(_ player: Player) -> TrainingRequirementResult {
        for (kp, required) in softSkillThresholds {
            guard player.softSkills[keyPath: kp] >= required else {
                let name = SoftSkills.label(forKeyPath: kp) ?? "skill"
                return .blocked(reason: "Needs more \(name)")
            }
        }
        return .ok(cost: 0)
    }
}
