import Foundation

enum Project: String, CaseIterable, Codable, Hashable, Identifiable {
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

    func requirements(for player: Player) -> ProjectRequirements {
        func softSkillCurrent(_ label: String) -> Int {
            switch label {
            case "Creativity":
                return player.softSkills.creativityAndInsightfulThinking
            case "Communication":
                return player.softSkills.communicationAndNetworking
            case "Problem Solving":
                return player.softSkills.analyticalReasoningAndProblemSolving
            case "Organization":
                return player.softSkills.timeManagementAndPlanning
            case "Attention to Detail":
                return player.softSkills.carefulnessAndAttentionToDetail
            default:
                return 0
            }
        }

        func soft(_ label: String, _ emoji: String, required: Int) -> ProjectRequirements.SoftRequirement {
            ProjectRequirements.SoftRequirement(
                label: label,
                emoji: emoji,
                required: required,
                current: softSkillCurrent(label)
            )
        }

        func hard(_ software: Software, label: String, emoji: String, required: Int) -> ProjectRequirements.HardRequirement {
            let owned = player.hardSkills.software.contains(software) ? 1 : 0
            return ProjectRequirements.HardRequirement(
                label: label,
                emoji: emoji,
                required: required,
                current: owned
            )
        }

        switch self {
        case .app:
            return ProjectRequirements(
                softSkills: [
                    soft("Creativity", "🎨", required: 3),
                    soft("Communication", "🗣️", required: 2)
                ],
                hardSkills: [
                    hard(.programming, label: "Programming", emoji: "💻", required: 1)
                ]
            )

        case .game:
            return ProjectRequirements(
                softSkills: [
                    soft("Creativity", "🎨", required: 4),
                    soft("Problem Solving", "🧩", required: 3)
                ],
                hardSkills: [
                    hard(.programming, label: "Programming", emoji: "💻", required: 1),
                    hard(.gameEngine, label: "Game Engine", emoji: "🎮", required: 1)
                ]
            )

        case .website:
            return ProjectRequirements(
                softSkills: [
                    soft("Communication", "🗣️", required: 3),
                    soft("Organization", "🗂️", required: 2)
                ],
                hardSkills: [
                    hard(.programming, label: "Programming", emoji: "💻", required: 1),
                    hard(.mediaEditing, label: "Media Editing", emoji: "🎨", required: 1)
                ]
            )

        case .library:
            return ProjectRequirements(
                softSkills: [
                    soft("Problem Solving", "🧩", required: 4),
                    soft("Attention to Detail", "🔎", required: 3)
                ],
                hardSkills: [
                    hard(.programming, label: "Programming", emoji: "💻", required: 1)
                ]
            )

        case .paper:
            return ProjectRequirements(
                softSkills: [
                    soft("Communication", "🗣️", required: 4),
                    soft("Organization", "🗂️", required: 3)
                ],
                hardSkills: [
                    hard(.officeSuite, label: "Office Suite", emoji: "📄", required: 1)
                ]
            )

        case .presentation:
            return ProjectRequirements(
                softSkills: [
                    soft("Communication", "🗣️", required: 5),
                    soft("Creativity", "🎨", required: 2)
                ],
                hardSkills: [
                    hard(.officeSuite, label: "Office Suite", emoji: "📄", required: 1),
                    hard(.mediaEditing, label: "Media Editing", emoji: "🎨", required: 1)
                ]
            )
        }
    }
}

public struct ProjectRequirements {
    public struct SoftRequirement {
        public let label: String
        public let emoji: String
        public let required: Int
        public let current: Int
        public init(label: String, emoji: String, required: Int, current: Int) {
            self.label = label
            self.emoji = emoji
            self.required = required
            self.current = current
        }
    }
    public struct HardRequirement {
        public let label: String
        public let emoji: String
        public let required: Int
        public let current: Int
        public init(label: String, emoji: String, required: Int, current: Int) {
            self.label = label
            self.emoji = emoji
            self.required = required
            self.current = current
        }
    }

    public let minEQF: Int?
    public let softSkills: [SoftRequirement]
    public let hardSkills: [HardRequirement]

    public init(minEQF: Int? = nil, softSkills: [SoftRequirement] = [], hardSkills: [HardRequirement] = []) {
        self.minEQF = minEQF
        self.softSkills = softSkills
        self.hardSkills = hardSkills
    }
}

