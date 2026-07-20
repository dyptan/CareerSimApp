import Foundation

/// A strategic play a player can make while holding a senior leadership seat —
/// C-suite, director, partner, or a founder venture (see `Job.isExecutive`).
/// Unlike a spare-time venture, an executive decision is resolved *immediately*
/// (the year the player makes it, from the Boardroom sheet) rather than banked
/// for `advanceYear`, mirroring `Player.foundVenture` / `applyForJob`. Each
/// decision can be taken at most once per year (see
/// `Player.executiveActionsThisYear`).
///
/// Two decisions ship today, tuned as a risk/reward pair:
/// - **Announce an Investment Round** — a gamble. A successful year realises a
///   large capital raise as equity liquidity (a multiple of the player's pay)
///   and banks industry fame; a failure yields nothing but the opportunity cost.
///   The odds turn on the founder-cluster soft skills, plus the player's network
///   and reputation in the field.
/// - **Sell Your Stake** — put your equity on the market at a price you name. The
///   higher you ask relative to the company's fair valuation, the less likely a
///   buyer bites, and a recession thins the buyers further. A founder who lands a
///   sale exits the venture; a hired exec just cashes out vested equity.
struct ExecutiveDecision: Identifiable, Hashable {
    /// How the decision resolves. Each kind has its own odds/payout maths on
    /// `Player`, so the catalogue stays declarative.
    enum Kind: String, Hashable {
        /// A high-variance capital raise: big cash + fame on success, else nothing.
        case investmentRound
        /// A guaranteed, tenure-scaled equity cash-out.
        case sellShares
    }

    let id: String
    let kind: Kind
    let label: String
    let icon: String
    let blurb: String
    /// Soft-skill axes the decision leans on. Drives the odds for a gamble
    /// (`investmentRound`); shown as context for the guaranteed `sellShares`.
    let talents: [WritableKeyPath<SoftSkills, Int>]

    static func == (lhs: ExecutiveDecision, rhs: ExecutiveDecision) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// The result of resolving a decision, handed back to the view for display.
    /// `Player` has already applied the effects (cash, fame, growth) by the time
    /// this returns.
    struct Outcome {
        let decision: ExecutiveDecision
        /// True for a guaranteed sell-shares, or a successful investment round.
        let success: Bool
        /// Cash added to savings this decision (0 on a failed round).
        let cash: Int
        /// Title of any fame award banked (investment round success only).
        let fameTitle: String?
    }
}

/// The decisions on offer in the Boardroom. Small and fixed for now; structured
/// as a catalogue so more executive plays can be added without touching the view.
enum ExecutiveDecisionCatalog {
    static let all: [ExecutiveDecision] = [
        ExecutiveDecision(
            id: "investmentRound",
            kind: .investmentRound,
            label: "Announce an Investment Round",
            icon: "🚀",
            blurb: "Take the company to investors and raise a growth round. Land it and your equity is worth a fortune — and the business press takes notice. Fall short and you've spent the quarter chasing term sheets for nothing.",
            talents: [\.visionaryThinkingAndAmbition, \.persuasionAndNegotiation,
                      \.leadershipAndInfluence, \.communicationAndNetworking]
        ),
        ExecutiveDecision(
            id: "sellShares",
            kind: .sellShares,
            label: "Sell Your Stake",
            icon: "💸",
            blurb: "Put your equity on the market at a price you set. Ask near its fair value and a buyer bites readily; hold out for a premium and you may find no takers this year. A recession thins the buyers further.",
            talents: [\.persuasionAndNegotiation, \.riskTakingAndInitiative]
        ),
    ]

    static let byId: [String: ExecutiveDecision] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
