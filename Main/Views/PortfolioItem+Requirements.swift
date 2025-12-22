import Foundation

extension PortfolioItem {
    // Build user-facing ProjectRequirements using the app's real models
    func requirements(for player: Player) -> ProjectRequirements {
        // Map soft skills from Player.SoftSkills keyed properties
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

        // Helper to build a soft requirement
        func soft(_ label: String, _ emoji: String, required: Int) -> ProjectRequirements.SoftRequirement {
            ProjectRequirements.SoftRequirement(
                label: label,
                emoji: emoji,
                required: required,
                current: softSkillCurrent(label)
            )
        }

        // Helper to build a hard requirement based on Software possession
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

