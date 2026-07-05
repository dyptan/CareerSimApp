import Foundation

enum Project: String, CaseIterable, Codable, Hashable, Identifiable {
    case app = "Mobile App"
    case library = "Contribute to open-source project"
    case article = "Article"
    case presentation = "Presentation"
    case musicFestival = "Music Festival"
    case publishBook = "Coauthor a book or a paper"
    case game3d = "3D Game"

    var id: String { rawValue }

    /// Plain-language explanation of the side project, for the in-game info
    /// popover. Projects are spare-time passion projects you put yourself into —
    /// not work deliverables. Unlike a hobby (which quietly builds soft skills),
    /// a project *spends* the soft skills you've already built for a shot at
    /// fame and recognition — putting your name out into the world.
    var description: String {
        switch self {
        case .app: return "A little mobile or desktop app you build in your spare time — to scratch an itch or just to learn. Ship something people actually use and word gets around."
        case .library: return "An open-source project you contribute to in your free time, out in the open for other tinkerers to see. Land your work in something people depend on and your name travels with it."
        case .article: return "A long-form article or deep-dive you write out of pure curiosity. A piece that gets read and shared builds a quiet kind of renown."
        case .presentation: return "A talk you put together for a meetup, conference, or hobby community. Landing an idea in front of a room is how people start to know your name."
        case .musicFestival: return "You take the stage at a music festival. A good set in front of a crowd is the fastest way to get talked about."
        case .publishBook: return "You coauthor a book or a paper and see it published. A title with your name on the spine carries lasting recognition."
        case .game3d: return "A 3D game you model, build, and ship in your spare time — characters, worlds, and mechanics all your own. A standout indie title gets you noticed."
        }
    }

    var pictogram: String {
        switch self {
        case .app: return "📱"
        case .library: return "📦"
        case .article: return "📝"
        case .presentation: return "🖥️"
        case .musicFestival: return "🎵"
        case .publishBook: return "📖"
        case .game3d: return "🎮"
        }
    }

    /// Life stages in which this project is offered. Kid-friendly creative
    /// outings (a creative contest, a festival) are open from childhood;
    /// grown-up pieces (a published book/paper) unlock later.
    var stages: Set<LifeStage> {
        switch self {
        case .app, .library, .presentation, .game3d:
            return [.teen, .youngAdult, .adult]
        case .publishBook:
            return [.youngAdult, .adult]
        default:
            return [.child, .teen, .youngAdult, .adult]
        }
    }

    /// The soft skills a project *draws on*, with the level at which each counts
    /// as fully met (the `weight`). These are the axes surfaced in the project's
    /// info hint — the skills "considered" when the player takes it on. The
    /// better the player meets them, the likelier the year earns fame (see
    /// `successProbability` / `rollFameGain`). This is the mirror image of a
    /// `Hobby`: a hobby *grants* soft skills for free, whereas a project
    /// *spends* the soft skills you've already built for a shot at recognition.
    var requirements: [WeightedAbility] {
        switch self {
        case .app:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
                    .init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 1)]
        case .library:
            return [.init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 3),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                    .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)]
        case .article:
            return [.init(keyPath: \.communicationAndNetworking, weight: 2),
                    .init(keyPath: \.presentationAndStorytelling, weight: 2),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)]
        case .presentation:
            return [.init(keyPath: \.presentationAndStorytelling, weight: 2),
                    .init(keyPath: \.communicationAndNetworking, weight: 2),
                    .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)]
        case .musicFestival:
            return [.init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
                    .init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
                    .init(keyPath: \.presentationAndStorytelling, weight: 1)]
        case .publishBook:
            return [.init(keyPath: \.communicationAndNetworking, weight: 2),
                    .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                    .init(keyPath: \.timeManagementAndPlanning, weight: 1)]
        case .game3d:
            return [.init(keyPath: \.creativityAndInsightfulThinking, weight: 2),
                    .init(keyPath: \.spacialNavigationAndOrientation, weight: 2),
                    .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)]
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

    /// Probability (0.1...0.9) that a year on this project earns any fame at
    /// all, driven entirely by how well the player meets its soft-skill
    /// requirements. Even a perfect fit leaves room for a dud year, and a weak
    /// fit still leaves a slim chance of being noticed.
    func successProbability(for soft: SoftSkills) -> Double {
        max(0.1, min(0.9, 0.15 + requirementFit(for: soft) * 0.75))
    }

    /// The fame-and-recognition bump a year on this project earns: `1` when the
    /// year gets noticed, `0` when it doesn't. The single roll uses
    /// `successProbability`, so a strong soft-skill fit is far likelier to land
    /// the point. Banked as a `Player.Recognition` in the project's `fameIndustry` in
    /// `advanceYear`.
    func rollFameGain(for soft: SoftSkills) -> Int {
        Double.random(in: 0...1) < successProbability(for: soft) ? 1 : 0
    }

    /// Soft skills a *successful* year on this project grows (each capped at 5
    /// in `advanceYear`). Two kinds combine: the craft axes it draws on (its
    /// `requirements`, +1 each — you sharpen what you practise) and a curated
    /// founder-cluster bump (initiative / vision / leadership / persuasion — the
    /// axes no hobby can build, earned only by shipping real work into the
    /// world). This is the reward a hobby can't give: a hobby is passive
    /// practice, a shipped project is an achievement that grows you.
    var successBoosts: [(keyPath: WritableKeyPath<SoftSkills, Int>, delta: Int)] {
        requirements.map { (keyPath: $0.keyPath, delta: 1) } + founderBoosts
    }

    /// The leadership/founder axes a shipped project sharpens — the half of the
    /// soft-skill map hobbies never touch (see `successBoosts`).
    private var founderBoosts: [(keyPath: WritableKeyPath<SoftSkills, Int>, delta: Int)] {
        switch self {
        case .app:
            return [(\.riskTakingAndInitiative, 1), (\.visionaryThinkingAndAmbition, 1)]
        case .library:
            return [(\.leadershipAndInfluence, 1), (\.visionaryThinkingAndAmbition, 1)]
        case .article:
            return [(\.visionaryThinkingAndAmbition, 1), (\.persuasionAndNegotiation, 1)]
        case .presentation:
            return [(\.persuasionAndNegotiation, 2)]
        case .musicFestival:
            return [(\.riskTakingAndInitiative, 1), (\.visionaryThinkingAndAmbition, 1)]
        case .publishBook:
            return [(\.visionaryThinkingAndAmbition, 1), (\.leadershipAndInfluence, 1)]
        case .game3d:
            return [(\.riskTakingAndInitiative, 1), (\.visionaryThinkingAndAmbition, 1)]
        }
    }

    /// The personal-brand title a noticed year on this project earns, banked as
    /// a `Recognition` (levelling up on repeats). Reads as something you're
    /// *known for* — distinct from the fame-building side-hustle awards so the
    /// two never collide on the shelf.
    var recognitionTitle: String {
        switch self {
        case .app: return "App Maker"
        case .library: return "Open-Source Contributor"
        case .article: return "Bylined Writer"
        case .presentation: return "Noted Speaker"
        case .musicFestival: return "Festival Performer"
        case .publishBook: return "Book Coauthor"
        case .game3d: return "Indie Game Dev"
        }
    }

    /// The industry this project builds fame in. Fame is industry-scoped — it
    /// only lifts hiring odds for roles in this same `JobCategory` (see
    /// `Player.fameHireBonus(for:)`), so a coding project's renown helps land
    /// tech roles, not a spot on stage.
    var fameIndustry: JobCategory {
        switch self {
        case .app, .library: return .technology
        case .game3d: return .gaming
        case .article, .musicFestival: return .showBusiness
        case .presentation: return .business
        case .publishBook: return .science
        }
    }

    static func unlocked(byPractisedHobbies practisedHobbies: Set<String>) -> Set<Project> {
        var result: Set<Project> = []
        for hobby in hobbies where practisedHobbies.contains(hobby.label) {
            result.formUnion(hobby.unlocks)
        }
        return result
    }
}
