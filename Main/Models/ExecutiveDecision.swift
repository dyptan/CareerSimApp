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
/// - **Announce an Investment Round** — a gamble. A successful round grows the
///   company (and with it the founder's stake) and banks business fame; a
///   failure yields nothing but the opportunity cost.
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
        /// A high-variance capital raise: company growth + fame on success, else nothing.
        case investmentRound
        /// A tenure-scaled equity cash-out at the player's asking price, if a buyer bites.
        case sellShares
    }

    let id: String
    let kind: Kind
    private let labelResource: LocalizedStringResource
    /// The decision's name, in the player's language.
    var label: String { String(localized: labelResource) }
    let icon: String
    private let blurbResource: LocalizedStringResource
    /// The play's pitch, in the player's language.
    var blurb: String { String(localized: blurbResource) }
    /// Soft-skill axes the decision leans on. Drives the odds for a gamble
    /// (`investmentRound`).
    let talents: [WritableKeyPath<SoftSkills, Int>]

    /// The catalogue rows pass their text as literals, which the compiler extracts into the
    /// String Catalog; `label` and `blurb` read it back.
    init(id: String, kind: Kind, label: LocalizedStringResource, icon: String,
         blurb: LocalizedStringResource, talents: [WritableKeyPath<SoftSkills, Int>]) {
        self.id = id
        self.kind = kind
        self.labelResource = label
        self.icon = icon
        self.blurbResource = blurb
        self.talents = talents
    }

    static func == (lhs: ExecutiveDecision, rhs: ExecutiveDecision) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// The result of resolving a decision, handed back to the view for display.
    /// `Player` has already applied the effects (cash, fame, growth) by the time
    /// this returns.
    struct Outcome {
        let decision: ExecutiveDecision
        /// True when a buyer takes the stake, or the investment round closes.
        let success: Bool
        /// Cash added to savings this decision: a sale's proceeds after tax and
        /// fees. 0 for a round (its money goes into the company) or an unsold stake.
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
            blurb: "Ask investors to put money into your company. If they say yes, the company grows — and so does your share of it. If they say no, you've spent the year trying.",
            talents: [\.visionaryThinkingAndAmbition, \.persuasionAndNegotiation,
                      \.leadershipAndInfluence, \.communicationAndNetworking]
        ),
        ExecutiveDecision(
            id: "sellShares",
            kind: .sellShares,
            label: "Sell Your Stake",
            icon: "💸",
            blurb: "Sell your share of the company for a price you choose. Ask close to what it's worth and someone will probably buy; ask for much more and nobody may buy this year. When the economy is bad, there are fewer buyers.",
            talents: [\.persuasionAndNegotiation, \.visionaryThinkingAndAmbition]
        ),
    ]

    static let byId: [String: ExecutiveDecision] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}
