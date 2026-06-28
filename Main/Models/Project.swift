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

    /// The soft skills a project *demands*, with the level at which each counts
    /// as fully met (the `weight`). This is the mirror image of a `Hobby`: a
    /// hobby *grants* soft skills for free, whereas a project *spends* the soft
    /// skills you've already built — the better you meet these requirements, the
    /// likelier the project comes together (see `successProbability`). Build the
    /// matching hobby first, then cash those skills in on the deliverable.
    var requirements: [WeightedAbility] {
        switch self {
        case .app:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
                    .init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 1)]
        case .website:
            return [.init(keyPath: \.communicationAndNetworking, weight: 2),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 2),
                    .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)]
        case .library:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 3),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                    .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)]
        case .paper:
            return [.init(keyPath: \.communicationAndNetworking, weight: 2),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 2),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .presentation:
            return [.init(keyPath: \.presentationAndStorytelling, weight: 2),
                    .init(keyPath: \.communicationAndNetworking, weight: 2),
                    .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)]
        case .paintingPortfolio:
            return [.init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                    .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1)]
        case .photoPortfolio:
            return [.init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                    .init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 1)]
        case .musicAlbum:
            return [.init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
                    .init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
                    .init(keyPath: \.presentationAndStorytelling, weight: 1)]
        case .recipeBook:
            return [.init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 1)]
        case .lessonPlan:
            return [.init(keyPath: \.communicationAndNetworking, weight: 2),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 2),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        }
    }

    /// The bare soft-skill axes a project draws on, derived from `requirements`.
    /// Kept for any caller that only needs the axes, not the required levels.
    var talents: [WritableKeyPath<SoftSkills, Int>] {
        requirements.map(\.keyPath)
    }

    /// 0...1 measure of how well the player meets this project's soft-skill
    /// requirements: each axis scores `min(have / needed, 1)`, weighted by its
    /// required level and averaged. A player who meets every requirement scores
    /// 1.0; an empty requirement list is treated as fully met.
    func requirementFit(for soft: SoftSkills) -> Double {
        let totalWeight = requirements.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 1 }
        let met = requirements.reduce(0.0) { acc, req in
            let have = Double(soft[keyPath: req.keyPath])
            let need = Double(req.weight)
            return acc + min(have / need, 1.0) * Double(req.weight)
        }
        return met / Double(totalWeight)
    }

    /// Probability (0.1...0.9) that a year spent on this project ships a finished
    /// portfolio piece, driven entirely by how well the player meets its
    /// soft-skill requirements. Even a perfect fit leaves room for a flop, and a
    /// weak fit still leaves a slim chance.
    func successProbability(for soft: SoftSkills) -> Double {
        max(0.1, min(0.9, 0.15 + requirementFit(for: soft) * 0.75))
    }

    /// Soft-skill bumps granted when a project ships. Reserved for the
    /// "founder cluster" — Risk-Taker, Visionary, Persuader, Leader — axes
    /// you can only sharpen by actually putting your own work into the world.
    /// Each delta is applied (and capped at 5) inside `Player.advanceYear`
    /// when the project ships its portfolio piece.
    var boosts: [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch self {
        case .app:
            return [(\.riskTakingAndInitiative, 1), (\.visionaryThinkingAndAmbition, 1)]
        case .website:
            return [(\.persuasionAndNegotiation, 1)]
        case .library:
            return [(\.leadershipAndInfluence, 1), (\.visionaryThinkingAndAmbition, 1)]
        case .paper:
            return [(\.visionaryThinkingAndAmbition, 1)]
        case .presentation:
            return [(\.persuasionAndNegotiation, 2)]
        case .paintingPortfolio, .photoPortfolio:
            return [(\.visionaryThinkingAndAmbition, 1)]
        case .musicAlbum:
            return [(\.visionaryThinkingAndAmbition, 1), (\.riskTakingAndInitiative, 1)]
        case .recipeBook:
            return [(\.persuasionAndNegotiation, 1)]
        case .lessonPlan:
            return [(\.leadershipAndInfluence, 1)]
        }
    }

    /// A titled fame trophy a project can earn when it ships — reputation that
    /// no hobby can buy. The marquee creative pieces (a body of paintings, a
    /// breakout album, an acclaimed photo set) put your name out into the world;
    /// the quietly technical pieces (an app, a library) build professional skill
    /// instead and grant no fame. `nil` means this project never builds fame.
    /// Banked into `Player.achievements` on a successful year and surfaced
    /// through `Player.fameMetadata(for:)` (see `Player.fameRegistry`).
    var fameAward: String? {
        switch self {
        case .paintingPortfolio: return "Exhibited Artist"
        case .photoPortfolio: return "Acclaimed Photographer"
        case .musicAlbum: return "Breakout Album"
        case .paper: return "Published Researcher"
        case .presentation: return "Keynote Speaker"
        case .recipeBook: return "Celebrated Cook"
        case .app, .website, .library, .lessonPlan: return nil
        }
    }

    /// Reputation weight this project's trophy carries in the player's fame
    /// score (see `Player.fameScore`). Marquee outputs are tuned higher; only
    /// meaningful when `fameAward` is non-nil.
    var fameWeight: Double {
        switch self {
        case .musicAlbum, .paper: return 1.5
        default: return 1.0
        }
    }

    /// Whether a successful year of this project banks a fame trophy.
    var buildsFame: Bool { fameAward != nil }
}

