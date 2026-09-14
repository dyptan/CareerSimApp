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
