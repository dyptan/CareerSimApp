import Foundation

enum Project: String, CaseIterable, Codable, Hashable, Identifiable {
    case app = "App"
    case game = "Game"
    case website = "Website"
    case library = "Library"
    case paper = "Paper"
    case presentation = "Presentation"
    case paintingPortfolio = "Painting Portfolio"
    case photoPortfolio = "Photo Portfolio"
    case musicAlbum = "Music Album"
    case recipeBook = "Recipe Book"
    case lessonPlan = "Lesson Plan"

    var id: String { rawValue }

    /// Plain-language explanation of the portfolio project type, for the in-game info popover.
    var description: String {
        switch self {
        case .app: return "A small mobile or desktop app you build to show off in interviews. Demonstrates that you can ship working software end-to-end."
        case .game: return "A playable video game project. Strong portfolio piece for game-developer roles — shows you can combine code, design, and visuals."
        case .website: return "A real website you’ve designed and built. Most common portfolio piece for web developers and designers."
        case .library: return "A reusable code library that other developers can install and use. Signals strong engineering and documentation skills."
        case .paper: return "A written research paper or long-form article. Counts toward science, humanities, and academic careers."
        case .presentation: return "A polished talk or pitch deck. Useful for business, marketing, design, and education roles."
        case .paintingPortfolio: return "A collection of paintings or drawings to show galleries, art schools, and clients. The standard entry portfolio for visual artists."
        case .photoPortfolio: return "A curated set of your best photos, edited and presented as a body of work. Required for photography and photojournalism jobs."
        case .musicAlbum: return "A finished collection of recorded songs. Demonstrates writing, performing, and producing skills to record labels and venues."
        case .recipeBook: return "A collection of original recipes, photographed and written up. Builds your reputation as a chef or food creator."
        case .lessonPlan: return "A set of structured lessons with objectives, activities, and assessments. Required portfolio piece for teaching and tutoring jobs."
        }
    }

    var pictogram: String {
        switch self {
        case .app: return "📱"
        case .game: return "🎮"
        case .website: return "🌐"
        case .library: return "📦"
        case .paper: return "📄"
        case .presentation: return "🖥️"
        case .paintingPortfolio: return "🖼️"
        case .photoPortfolio: return "📷"
        case .musicAlbum: return "🎵"
        case .recipeBook: return "🍳"
        case .lessonPlan: return "🍎"
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
            case "Perseverance":
                return player.softSkills.selfDisciplineAndPerseverance
            case "Finger Precision":
                return player.softSkills.tinkeringAndFingerPrecision
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

        switch self {
        case .app:
            return ProjectRequirements(
                softSkills: [
                    soft("Creativity", "🎨", required: 3),
                    soft("Communication", "🗣️", required: 2)
                ],
                hardSkills: []
            )

        case .game:
            return ProjectRequirements(
                softSkills: [
                    soft("Creativity", "🎨", required: 4),
                    soft("Problem Solving", "🧩", required: 3)
                ],
                hardSkills: []
            )

        case .website:
            return ProjectRequirements(
                softSkills: [
                    soft("Communication", "🗣️", required: 3),
                    soft("Organization", "🗂️", required: 2)
                ],
                hardSkills: []
            )

        case .library:
            return ProjectRequirements(
                softSkills: [
                    soft("Problem Solving", "🧩", required: 4),
                    soft("Attention to Detail", "🔎", required: 3)
                ],
                hardSkills: []
            )

        case .paper:
            return ProjectRequirements(
                softSkills: [
                    soft("Communication", "🗣️", required: 4),
                    soft("Organization", "🗂️", required: 3)
                ],
                hardSkills: []
            )

        case .presentation:
            return ProjectRequirements(
                softSkills: [
                    soft("Communication", "🗣️", required: 5),
                    soft("Creativity", "🎨", required: 2)
                ],
                hardSkills: []
            )

        case .paintingPortfolio:
            return ProjectRequirements(
                softSkills: [
                    soft("Creativity", "🎨", required: 4),
                    soft("Attention to Detail", "🔎", required: 3),
                    soft("Finger Precision", "🛠️", required: 2)
                ],
                hardSkills: []
            )

        case .photoPortfolio:
            return ProjectRequirements(
                softSkills: [
                    soft("Creativity", "🎨", required: 3),
                    soft("Attention to Detail", "🔎", required: 3)
                ],
                hardSkills: []
            )

        case .musicAlbum:
            return ProjectRequirements(
                softSkills: [
                    soft("Creativity", "🎨", required: 4),
                    soft("Perseverance", "🏆", required: 3)
                ],
                hardSkills: []
            )

        case .recipeBook:
            return ProjectRequirements(
                softSkills: [
                    soft("Creativity", "🎨", required: 3),
                    soft("Attention to Detail", "🔎", required: 3),
                    soft("Organization", "🗂️", required: 2)
                ],
                hardSkills: []
            )

        case .lessonPlan:
            return ProjectRequirements(
                softSkills: [
                    soft("Communication", "🗣️", required: 3),
                    soft("Organization", "🗂️", required: 3),
                    soft("Attention to Detail", "🔎", required: 2)
                ],
                hardSkills: []
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

