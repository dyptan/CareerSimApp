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

/// A professional event — a summit, conference, expo, or networking mixer.
/// Distinct from a `Hobby`: events are a realistic-mode feature that build an
/// industry **professional network** improving both the hiring odds on that
/// field's job postings and the chance of promotion while working in it (see
/// `Player.networkBonus` and `Player.promotionChance`). They also nudge the
/// networking-flavoured soft skills, applied immediately on attendance the way
/// a hobby is. Attending as a **presenter** (industry events only, and only
/// once you're a veteran of the field) banks extra network plus a fame
/// fame award in that industry.
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
    /// presenter role.
    var presenterFameTitle: String? {
        supportsPresenter ? "\(name) — Speaker" : nil
    }

    /// Reputation weight of the presenter fame award — flagship summits (higher
    /// `networkWeight`) are worth more on the shelf. See `Player.fameHireBonus`.
    var presenterFameWeight: Double { Double(networkWeight) }
}

enum EventCatalog {
    /// The events on offer. Each is tagged to the industry whose network it
    /// builds; `nil` events build a general network that helps in any field.
    /// Industry events can also be presented at once you're a veteran of the
    /// field (see `CareerEvent.canPresent`).
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
        CareerEvent(
            id: "career-fair-mixer",
            name: "Career Fair & Networking Mixer",
            icon: "🤝",
            blurb: "An affordable, come-one-come-all evening of introductions.",
            category: nil,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.empathyAndInterpersonalCare, weight: 1)
            ],
            networkWeight: 1
        ),
        CareerEvent(
            id: "leadership-retreat",
            name: "Leadership Retreat",
            icon: "🧗",
            blurb: "An immersive week with senior leaders from every industry.",
            category: nil,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "world-economic-summit",
            name: "World Economic Summit",
            icon: "🌐",
            blurb: "The flagship gathering of executives and policymakers worldwide.",
            category: nil,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 2)
            ],
            networkWeight: 3
        ),
        // Learning & training — paid skill-building rather than pure networking,
        // so these lean on soft-skill gains with only a small general network.
        CareerEvent(
            id: "skills-workshop",
            name: "Skills Workshop",
            icon: "🛠️",
            blurb: "A hands-on weekend workshop to sharpen a practical skill.",
            category: nil,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 1
        ),
        CareerEvent(
            id: "instructor-led-training",
            name: "Instructor-Led Training",
            icon: "🧑‍🏫",
            blurb: "A structured course led by an expert instructor, ending in a certificate of completion.",
            category: nil,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
            ],
            networkWeight: 1
        ),
        CareerEvent(
            id: "intensive-bootcamp",
            name: "Intensive Bootcamp",
            icon: "🥾",
            blurb: "Weeks of immersive, intensive training that rebuild your skill set fast.",
            category: nil,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
            ],
            networkWeight: 1
        )
    ]

    static let byId: [String: CareerEvent] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )
}
