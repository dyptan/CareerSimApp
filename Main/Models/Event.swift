import Foundation

/// The capacity in which the player attends an event.
enum EventRole: String {
    /// You're in the audience: soft-skill nudges plus network points.
    case participant
    /// You're on stage: more network, and a fame **award** banked in the
    /// event's industry when the year advances. Restricted to industry events
    /// and gated behind years of experience (see `CareerEvent.canPresent`).
    case presenter
}

/// A professional event — a summit, conference, expo, festival, or pitch
/// competition. Distinct from a `Hobby`: events are a realistic-mode feature
/// that build an industry **professional network** improving both the hiring
/// odds on that field's job postings and the chance of promotion while working
/// in it (see `Player.networkBonus` and `Player.promotionChance`). They also
/// nudge the networking-flavoured soft skills, applied immediately the way a
/// hobby is. The player takes part as a **presenter** — taking the stage
/// (industry events only, and only once you're a veteran of the field) banks
/// the field's network plus a fame award in that industry.
struct CareerEvent: Identifiable {
    let id: String
    let name: String
    let icon: String
    let blurb: String
    /// Industry this event serves. `nil` marks a cross-industry event whose
    /// network counts toward **every** field (general professional exposure).
    /// Only industry events (`category != nil`) can be presented at.
    let category: JobCategory?
    /// Soft-skill nudges, applied immediately on attendance (like a hobby).
    let abilities: [WeightedAbility]
    /// Professional-network points one attendance as a *participant* adds (1–3).
    /// Accumulates in `Player.networkByCategory`/`Player.generalNetwork` and
    /// feeds hiring + promotion. A presenter banks more (see `networkPoints`).
    let networkWeight: Int
    /// Verb for the "take the stage" role on this event's row — "Present" for a
    /// conference, but "Perform" at a festival, "Compete" at a pitch, and so on.
    /// Purely cosmetic; the mechanic is identical (see `EventRole.presenter`).
    let presenterActionLabel: String
    /// Bespoke title for the fame award a presenter banks (e.g. "Festival
    /// Performer", "Pitch Winner"). `nil` falls back to "<name> — Speaker".
    let presenterFameTitleOverride: String?

    init(id: String, name: String, icon: String, blurb: String, category: JobCategory?,
         abilities: [WeightedAbility], networkWeight: Int,
         presenterActionLabel: String = "Present",
         presenterFameTitleOverride: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.blurb = blurb
        self.category = category
        self.abilities = abilities
        self.networkWeight = networkWeight
        self.presenterActionLabel = presenterActionLabel
        self.presenterFameTitleOverride = presenterFameTitleOverride
    }

    /// Whether the player has the ≥1 year of same-industry work experience
    /// needed to get into this event — you network your way in once you're
    /// actually in the field. Cross-industry events (nil `category`) are open to
    /// everyone.
    func meetsExperienceRequirement(for experience: [JobCategory: Int]) -> Bool {
        guard let category else { return true }
        return (experience[category] ?? 0) >= 1
    }

    /// Whether this event offers a presenter role at all — industry events only;
    /// a general, cross-industry gathering has no single field to headline in.
    var supportsPresenter: Bool { category != nil }

    /// Whether the player is established enough in this event's industry to take
    /// the stage: `GameConstants.presenterExperienceYears` of experience in it.
    func canPresent(with experience: [JobCategory: Int]) -> Bool {
        guard let category else { return false }
        return (experience[category] ?? 0) >= GameConstants.presenterExperienceYears
    }

    /// Professional-network points a given role banks. A presenter draws more of
    /// the room than a participant (see `GameConstants.presenterNetworkBonus`).
    func networkPoints(for role: EventRole) -> Int {
        role == .presenter ? networkWeight + GameConstants.presenterNetworkBonus : networkWeight
    }

    /// The fame accolade banked (when the year advances) for presenting here,
    /// scoped to the event's industry. `nil` for general events, which have no
    /// presenter role. Spotlight events override the default speaker wording.
    var presenterFameTitle: String? {
        guard supportsPresenter else { return nil }
        return presenterFameTitleOverride ?? "\(name) — Speaker"
    }

    /// Reputation weight of the presenter fame award. Taking the stage at an
    /// industry event is a veteran-gated accomplishment — you only get the podium
    /// once you're established in the field — so it banks meaningfully more fame
    /// than its raw network points: a significant hiring lever in that same
    /// industry (see `Player.fameHireBonus`), and it compounds each year you
    /// present. Flagship summits (higher `networkWeight`) are worth proportionally
    /// more.
    var presenterFameWeight: Double { Double(networkWeight) * 2.0 }
}

enum EventCatalog {
    /// The events on offer. Each is tagged to the industry whose network it
    /// builds, and is taken by presenting — you take the stage once you're a
    /// veteran of the field (see `CareerEvent.canPresent`).
    static let all: [CareerEvent] = [
        CareerEvent(
            id: "tech-summit",
            name: "Tech Summit",
            icon: "💻",
            blurb: "Keynotes and hallway-track contacts across the tech industry.",
            category: .technology,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "investor-pitch-night",
            name: "Startup & Investor Pitch Night",
            icon: "🚀",
            blurb: "Pitch founders and angels — the room where business deals start.",
            category: .business,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "finance-forum",
            name: "Finance & Markets Forum",
            icon: "💰",
            blurb: "Analysts, bankers, and traders comparing notes on the markets.",
            category: .finance,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "medical-congress",
            name: "Medical Congress",
            icon: "🩺",
            blurb: "Clinical updates and the people who run hospitals and clinics.",
            category: .health,
            abilities: [
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "science-symposium",
            name: "Science Symposium",
            icon: "🔬",
            blurb: "Present findings and meet researchers shaping the field.",
            category: .science,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "engineering-expo",
            name: "Engineering Expo",
            icon: "🛠️",
            blurb: "Trade-floor demos and the firms hiring for the next big build.",
            category: .engineering,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "media-creators-conference",
            name: "Media & Creators Conference",
            icon: "🎬",
            blurb: "Editors, producers, and creators — where bylines and gigs trade hands.",
            category: .showBusiness,
            abilities: [
                .init(keyPath: \.presentationAndStorytelling, weight: 2),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "legal-bar-convention",
            name: "Legal Bar Convention",
            icon: "⚖️",
            blurb: "Partners and counsel networking over precedent and practice.",
            category: .law,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "design-week",
            name: "Design Week",
            icon: "🎨",
            blurb: "Studios and clients mingling around the season's best work.",
            category: .design,
            abilities: [
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.presentationAndStorytelling, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 1
        ),
        // Spotlight & competitive events — organized happenings you take the
        // stage at (once you're a veteran of the field), banking the field's
        // network plus industry fame. These were formerly spare-time *projects*,
        // but they're participation in someone else's event rather than a
        // self-initiated work, so they belong here.
        CareerEvent(
            id: "music-festival",
            name: "Music Festival",
            icon: "🎪",
            blurb: "Work the crowd and the backstage scene — or take the stage and play your set.",
            category: .showBusiness,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
            ],
            networkWeight: 2,
            presenterActionLabel: "Perform",
            presenterFameTitleOverride: "Festival Performer"
        ),
        CareerEvent(
            id: "tv-casting",
            name: "TV Show Casting",
            icon: "📺",
            blurb: "Network the production — or land a spot on screen and get seen.",
            category: .showBusiness,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
            ],
            networkWeight: 2,
            presenterActionLabel: "Appear",
            presenterFameTitleOverride: "TV Personality"
        ),
        CareerEvent(
            id: "conference-talk",
            name: "Conference Talk",
            icon: "🖥️",
            blurb: "Attend to meet the field — or take the podium and land your idea in front of the room.",
            category: .business,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.presentationAndStorytelling, weight: 1)
            ],
            networkWeight: 1,
            presenterActionLabel: "Speak",
            presenterFameTitleOverride: "Noted Speaker"
        ),
        CareerEvent(
            id: "pitch-competition",
            name: "Pitch Competition",
            icon: "🎤",
            blurb: "Work the room of founders and investors — or take the stage to pitch your idea and win it.",
            category: .entrepreneurship,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.persuasionAndNegotiation, weight: 1)
            ],
            networkWeight: 2,
            presenterActionLabel: "Compete",
            presenterFameTitleOverride: "Pitch Winner"
        ),
    ]

    static let byId: [String: CareerEvent] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )
}
