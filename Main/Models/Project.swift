import Foundation

enum Project: String, CaseIterable, Codable, Hashable, Identifiable {
    case app = "App"
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

    /// Plain-language explanation of the side/hobby project, for the in-game
    /// info popover. Projects are personal passion projects you build in your
    /// own time — not work deliverables — but a strong body of work catches an
    /// employer's eye when you go job-hunting.
    var description: String {
        switch self {
        case .app: return "A little mobile or desktop app you build in your spare time — to scratch an itch or just to learn. A working side project speaks louder than a résumé when you look for software work."
        case .website: return "A personal site you design and build on the side — a blog, a fan page, a favour for a friend. Hands-on proof you can ship for the web."
        case .library: return "An open-source code library you make in your free time and share for other tinkerers to use. A passion project that quietly shows real engineering chops."
        case .paper: return "A long-form article or deep-dive you write out of pure curiosity. Finishing one shows you can dig into a subject and explain it clearly."
        case .presentation: return "A talk or slide deck you put together for a meetup, club, or hobby community. Great practice at making an idea land in front of a room."
        case .paintingPortfolio: return "A collection of paintings and drawings you make for the love of it. A body of work that speaks for your eye and craft."
        case .photoPortfolio: return "A curated set of your favourite shots, taken and edited in your own time. Your personal best, gathered into one body of work."
        case .musicAlbum: return "A set of songs you write, record, and produce as a labour of love — proof you can take music from idea to finished tracks."
        case .recipeBook: return "A personal collection of recipes you've cooked, photographed, and written up — a foodie passion project."
        case .lessonPlan: return "A set of lessons you design for fun — to tutor a sibling, run a club, or teach something you love. Shows you can structure and explain a topic."
        }
    }

    var pictogram: String {
        switch self {
        case .app: return "📱"
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

    /// Life stages in which this portfolio piece is offered. Creative kid-friendly
    /// outputs (drawing, photos, music) are available from childhood; technical
    /// and adult-career pieces (library, recipe book, lesson plan) unlock later.
    var stages: Set<LifeStage> {
        switch self {
        case .paintingPortfolio, .photoPortfolio, .musicAlbum:
            return [.child, .teen, .youngAdult, .adult]
        case .app, .website, .paper, .presentation:
            return [.teen, .youngAdult, .adult]
        case .library, .recipeBook, .lessonPlan:
            return [.youngAdult, .adult]
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

