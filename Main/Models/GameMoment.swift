import Foundation

/// Where a moment's option sends the player. Data rather than a closure, so a
/// moment stays comparable and testable and carries no captured scope — the
/// presenter is the only thing that knows how to open a sheet.
enum MomentRoute: String, Codable, Hashable {
    case education
    case careers
    case trainings
    case projects
    case ventures
    case boardroom
    case hobbies
    case sports
    case events
    /// Acknowledge and carry on.
    case dismiss
}

/// A decision the game puts in front of the player *at the moment it matters*,
/// rather than leaving them to find the right button among everything the
/// footer offers.
///
/// Moments route into the sheets that already exist — they add guidance, not
/// content. Deliberately rationed: at most one a year, always skippable, and
/// fired by a change of state rather than a standing condition, so the game
/// doesn't trade a wall of buttons for a conveyor of pop-ups.
struct GameMoment: Identifiable, Hashable {
    /// Stable identity, also used to remember the once-only moments.
    let id: String
    let icon: String
    let title: String
    let body: String
    let options: [Option]
    /// Higher wins when several would fire in the same year.
    let priority: Int
    /// Whether this may only ever fire once in a run.
    let onlyOnce: Bool

    struct Option: Identifiable, Hashable {
        let label: String
        let route: MomentRoute
        /// The one the player most likely wants; rendered prominently.
        var isPrimary: Bool = false
        var id: String { label }
    }

    init(id: String, icon: String, title: String, body: String,
         options: [Option], priority: Int = 0, onlyOnce: Bool = false) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.options = options
        self.priority = priority
        self.onlyOnce = onlyOnce
    }
}

/// The moments the game can raise. Each is a pure function of player state, so
/// what fires is decided in one place and can be reasoned about without running
/// a year.
enum MomentCatalog {

    /// Every moment whose trigger is satisfied this year, unsorted.
    ///
    /// `justGraduated` and `justLostJob` are passed in rather than read off the
    /// player because they describe what happened *this* turn — the distinction
    /// between a change and a standing condition that keeps these rationed.
    static func candidates(for player: Player,
                           justGraduated: Bool,
                           justLostJob: Bool) -> [GameMoment] {
        var moments: [GameMoment] = []

        if justGraduated {
            moments.append(GameMoment(
                id: "graduated",
                icon: "🎓",
                title: "You've graduated",
                body: "That qualification is behind you. What now?",
                options: [
                    .init(label: "Look for work", route: .careers, isPrimary: true),
                    .init(label: "Study further", route: .education),
                    .init(label: "Spend a year on projects", route: .projects),
                    .init(label: "Decide later", route: .dismiss),
                ],
                priority: 70
            ))
        }

        if justLostJob {
            moments.append(GameMoment(
                id: "laid-off",
                icon: "💼",
                title: "You're out of work",
                body: "The role is gone. You can look for another, retrain for a different field, or back yourself and start something.",
                options: [
                    .init(label: "Find work", route: .careers, isPrimary: true),
                    .init(label: "Retrain", route: .trainings),
                    .init(label: "Start a venture", route: .ventures),
                    .init(label: "Take the year off", route: .dismiss),
                ],
                priority: 80
            ))
        }

        if player.age == GameConstants.minimumEntrepreneurAge {
            moments.append(GameMoment(
                id: "old-enough-to-found",
                icon: "🚀",
                title: "You can start a business now",
                body: "At \(GameConstants.minimumEntrepreneurAge) you're old enough to found a venture. It stakes your own money and becomes your job — riskier than a salary, and the only route to owning what you build.",
                options: [
                    .init(label: "See the ventures", route: .ventures, isPrimary: true),
                    .init(label: "Not yet", route: .dismiss),
                ],
                priority: 40,
                onlyOnce: true
            ))
        }

        // The education penalty on promotions is now measurable, so this can say
        // something specific rather than nagging in general.
        if let job = player.currentOccupation,
           !player.isSimplified,
           job.educationPromotionTerm(for: player) < 0 {
            let shortfall = job.educationShortfall(for: player)
            moments.append(GameMoment(
                id: "under-credentialled",
                icon: "📚",
                title: "Your schooling is holding you back",
                body: "\(job.baseTitle) normally expects \(job.requirements.education.educationLabel()). You're \(shortfall) level\(shortfall == 1 ? "" : "s") short, and it's costing you on every promotion — and on every application to a role like this.",
                options: [
                    .init(label: "Look at courses", route: .education, isPrimary: true),
                    .init(label: "Carry on regardless", route: .dismiss),
                ],
                priority: 50,
                onlyOnce: true
            ))
        }

        if player.currentOccupation?.isExecutive == true {
            moments.append(GameMoment(
                id: "boardroom-open",
                icon: "🏛",
                title: "You have a seat at the table",
                body: "Your role is senior enough for strategy plays — raising a round, taking equity, selling out. They're in the Boardroom.",
                options: [
                    .init(label: "Open the Boardroom", route: .boardroom, isPrimary: true),
                    .init(label: "Later", route: .dismiss),
                ],
                priority: 60,
                onlyOnce: true
            ))
        }

        return moments
    }

    /// The single moment to raise this year, if any: the highest-priority
    /// candidate the player hasn't already seen. One a year, by design.
    static func next(for player: Player,
                     justGraduated: Bool,
                     justLostJob: Bool,
                     alreadySeen: Set<String>) -> GameMoment? {
        candidates(for: player, justGraduated: justGraduated, justLostJob: justLostJob)
            .filter { !($0.onlyOnce && alreadySeen.contains($0.id)) }
            .max { $0.priority < $1.priority }
    }
}


/// What the footer offers this year: the few actions that matter now, with the
/// rest a tap away under **More**.
///
/// A pure function of player state, deliberately kept out of the view so what
/// the player is steered toward can be reasoned about — and tested — without
/// rendering anything. Availability is unchanged from when the footer listed
/// everything at once; only how much of it reaches the surface is new.
enum FooterActions {

    struct Action: Identifiable, Hashable {
        let label: String
        let route: MomentRoute
        var id: String { label }
    }

    /// Most actions on the surface at once. Beyond this the row stops reading as
    /// "what should I do this year?" and starts reading as a menu — which is
    /// what **More** and the contextual moments are for.
    static let surfacedLimit = 3

    /// Everything currently available, in catalogue order. Each condition is the
    /// gate the footer already applied: a button only appears when its sheet
    /// would have something in it.
    static func available(for player: Player) -> [Action] {
        let stage = LifeStage.forAge(player.age)
        var actions: [Action] = []
        if hobbies.contains(where: { $0.stages.contains(stage) }) {
            actions.append(.init(label: "Hobbies", route: .hobbies))
        }
        if Sport.allCases.contains(where: { $0.stages.contains(stage) }) {
            actions.append(.init(label: "Sports", route: .sports))
        }
        if !player.isSimplified, !player.experience.isEmpty {
            actions.append(.init(label: "Events", route: .events))
        }
        // Trainings: realistic mode, EQF >= Primary, and a stage-eligible
        // training in the catalogue.
        if !player.isSimplified, (player.degrees.last?.eqf ?? 0) >= 1,
           Training.allCases.contains(where: { $0.stages.contains(stage) }) {
            actions.append(.init(label: "Trainings", route: .trainings))
        }
        // Jobs open at legal working age; before that the player is in school
        // and nothing in the list applies.
        if player.age >= GameConstants.minimumWorkingAge {
            actions.append(.init(label: "Jobs", route: .careers))
        }
        if SideHustleCatalog.all.contains(where: { $0.stages.contains(stage) }) {
            actions.append(.init(label: "Projects", route: .projects))
        }
        // The founder path is a realistic-mode adult play, and only one venture
        // runs at a time — once founded it becomes the occupation, so this hides
        // until the player exits it.
        if !player.isSimplified,
           player.age >= GameConstants.minimumEntrepreneurAge,
           player.currentOccupation?.isEntrepreneurial != true {
            actions.append(.init(label: "Ventures", route: .ventures))
        }
        if player.canMakeExecutiveDecisions {
            actions.append(.init(label: "Boardroom", route: .boardroom))
        }
        // Higher education matters only after high school; before that schooling
        // progresses on its own.
        if player.age >= GameConstants.minimumTertiaryAge {
            actions.append(.init(label: "Education", route: .education))
        }
        return actions
    }

    /// How much an action matters *right now*. Keyed on the player's situation
    /// rather than life stage alone, because "unemployed at 30" and "employed at
    /// 30" want different things first.
    static func prominence(of route: MomentRoute, for player: Player) -> Int {
        let stage = LifeStage.forAge(player.age)
        let schoolAge = stage == .child || stage == .teen
        switch route {
        case .careers:
            // Out of work is the most urgent thing on screen — unless the player
            // is still school-age, where schooling comes first.
            if player.currentOccupation != nil { return 45 }
            return schoolAge ? 60 : 100
        case .education:
            // `currentEducation` tracks *all* schooling and a new player starts
            // enrolled in primary school, so this asks whether the study in
            // progress is tertiary. Otherwise every player counts as mid-degree
            // and Education never leaves the surface.
            let studyingTertiary = (player.currentEducation?.eqf ?? 0) >= 4
            return studyingTertiary ? 90 : (schoolAge ? 70 : 35)
        case .boardroom:  return 85   // rare, and the point of having got there
        case .hobbies:    return schoolAge ? 80 : 30
        case .sports:     return schoolAge ? 75 : 25
        case .projects:   return schoolAge ? 40 : 65   // a working adult's staple
        case .events:     return 60
        case .trainings:  return 50
        // A big, rare decision rather than a yearly one — and the coming-of-age
        // moment already announces it, so it needn't hold a permanent slot.
        case .ventures:   return 40
        case .dismiss:    return 0
        }
    }

    /// The few that reach the footer itself, in catalogue order so buttons don't
    /// jump around between turns as prominence shifts.
    static func surfaced(for player: Player) -> [Action] {
        let all = available(for: player)
        let top = all
            .sorted { prominence(of: $0.route, for: player) > prominence(of: $1.route, for: player) }
            .prefix(surfacedLimit)
        let keep = Set(top.map(\.id))
        return all.filter { keep.contains($0.id) }
    }

    /// Everything else — one tap away under **More**, never dropped.
    static func overflow(for player: Player) -> [Action] {
        let keep = Set(surfaced(for: player).map(\.id))
        return available(for: player).filter { !keep.contains($0.id) }
    }
}
