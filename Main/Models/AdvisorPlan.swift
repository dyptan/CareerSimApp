import Foundation

/// Where the player stands with the career advisor's coaching: whether it has
/// asked yet, which way they answered, and the yardstick progress is measured
/// against. Lives on `Player` (`Player.advisorPlan`), so it outlasts the
/// advisor's sheet and starts over with the game.
///
/// Plain data: the judgement — what to advise, what counts as progress — is
/// `AdvisorCoach`'s.
struct AdvisorPlan: Equatable {
    enum Path: Equatable {
        /// The advisor hasn't asked its opening question yet.
        case unasked
        /// The player hasn't picked a role: they're trying things to find one.
        case exploring
        /// The player is working toward this role (a `Job.baseTitle`).
        case target(String)
    }

    var path: Path = .unasked

    /// Age when the current path began — the moves made since are the years
    /// since (see `moves(for:)`).
    var startedAge = 0

    /// Skills and practice when the path began: what "gained" is measured from.
    var baselineSkills = SoftSkills()
    var baselineSportYears: [Sport: Int] = [:]

    /// The last review's state, so the next one can say what changed.
    var lastMark: Mark?

    /// The advisor's yearly reviews, oldest first, capped at
    /// `AdvisorCoach.maxCheckIns`.
    var checkIns: [AdvisorCheckIn] = []

    /// Reviews the player hasn't opened the advisor to read yet — what puts the
    /// badge on the header's Advice button.
    var unreadCount = 0

    /// The role being worked toward, if the player has picked one.
    var target: String? {
        if case .target(let title) = path { return title }
        return nil
    }

    /// Whether the advisor has something waiting: its opening question, or a
    /// review the player hasn't read.
    var needsAttention: Bool { path == .unasked || unreadCount > 0 }

    /// Years since the current path began.
    func moves(for player: Player) -> Int {
        max(0, player.age - startedAge)
    }

    /// A snapshot of the player against the role being worked toward — what a
    /// review compares itself with.
    struct Mark: Equatable {
        let age: Int
        let skills: SoftSkills
        let licences: Set<Training>
        let educationLevel: Int
        /// Years of experience that count toward the role.
        let years: Int
        /// The role's hire odds then; nil in Simplified, or when there's no role.
        let odds: Double?
        /// Whether the player already worked the target's ladder.
        let onLadder: Bool
        /// Fame in the role's field, professional network in it, and founder
        /// track record — the levers a hard-to-reach seat turns on.
        var fame: Double = 0
        var network: Int = 0
        var founderPoints: Double = 0
    }
}

/// A button the advisor puts under a message: where to go, or what to decide.
struct AdvisorAction: Identifiable, Equatable {
    enum Effect: Equatable {
        /// Close the advisor and open the sheet the move is made in.
        case go(CareerAdvisor.Destination)
        /// Make this role (a `Job.baseTitle`) the goal.
        case aim(String)
    }

    let label: String
    let effect: Effect

    var id: String { label }
}

/// One point on an advisor message: an icon and a sentence, with the button
/// that acts on it when there is one.
struct AdvisorCard: Identifiable, Equatable {
    let icon: String
    var title: String = ""
    let detail: String
    var actions: [AdvisorAction] = []

    var id: String { icon + title + detail }
}

/// The advisor's review of one move: how the player is doing against the
/// plan, what changed, and what to change. Built by `AdvisorCoach.checkIn`
/// when a year passes and kept on the plan.
struct AdvisorCheckIn: Identifiable, Equatable {
    enum Verdict: Equatable {
        /// Moving toward the role; nothing to fix.
        case onTrack
        /// Not moving, or slipping: the corrections say what to try.
        case needsCorrection
        /// Every requirement is met — the role can be applied for.
        case ready
        /// The top of the role's ladder is held.
        case goalReached
        /// Still trying things to find a role.
        case exploring
        /// Enough has been tried for the advisor to suggest roles.
        case readyToSuggest
    }

    /// The player's age when the year closed.
    let age: Int
    let verdict: Verdict
    /// The role the review is about, when there is one.
    let role: String?
    /// The verdict in a sentence.
    let headline: String
    /// What changed since the last review.
    let progress: [String]
    /// What to change, each with the button that does it when there is one.
    let corrections: [AdvisorCard]
    /// Roles worth a look — set with `.readyToSuggest`.
    let suggestions: [String]

    var id: Int { age }
}
