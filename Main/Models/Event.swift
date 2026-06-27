import Foundation

/// A paid professional event — a summit, conference, expo, or networking
/// mixer. Distinct from a `Hobby`: events cost money, are a realistic-mode
/// feature, and build an industry **professional network** that improves both
/// the hiring odds on that field's job postings and the chance of promotion
/// while working in it (see `Player.network`, `Player.networkBonus`, and
/// `Player.promotionChance`). They also nudge the networking-flavoured soft
/// skills, applied immediately on attendance the way a hobby is.
struct CareerEvent: Identifiable {
    let id: String
    let name: String
    let icon: String
    let blurb: String
    /// Registration + travel, charged from savings when attended (refunded if
    /// the player drops it again before the year advances).
    let cost: Int
    /// Industry this event serves. `nil` marks a cross-industry event whose
    /// network counts toward **every** field (general professional exposure).
    let category: JobCategory?
    /// Soft-skill nudges, applied immediately on attendance (like a hobby).
    let abilities: [WeightedAbility]
    /// Professional-network points one attendance adds (1–3). Accumulates in
    /// `Player.network`/`Player.generalNetwork` and feeds hiring + promotion.
    let networkWeight: Int
}

enum EventCatalog {
    /// The events on offer. Costs span ~$200–$4,000 so the cheap mixers stay
    /// reachable early while the flagship summits are an investment. Each is
    /// tagged to the industry whose network it builds; `nil` events build a
    /// general network that helps in any field.
    static let all: [CareerEvent] = [
        CareerEvent(
            id: "tech-summit",
            name: "Tech Summit",
            icon: "💻",
            blurb: "Keynotes and hallway-track contacts across the tech industry.",
            cost: 1_500,
            category: .technology,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.visionaryThinkingAndAmbition, weight: 2)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "investor-pitch-night",
            name: "Startup & Investor Pitch Night",
            icon: "🚀",
            blurb: "Pitch founders and angels — the room where business deals start.",
            cost: 800,
            category: .business,
            abilities: [
                .init(keyPath: \.persuasionAndNegotiation, weight: 2),
                .init(keyPath: \.riskTakingAndInitiative, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "finance-forum",
            name: "Finance & Markets Forum",
            icon: "💰",
            blurb: "Analysts, bankers, and traders comparing notes on the markets.",
            cost: 2_000,
            category: .finance,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "medical-congress",
            name: "Medical Congress",
            icon: "🩺",
            blurb: "Clinical updates and the people who run hospitals and clinics.",
            cost: 2_500,
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
            cost: 1_200,
            category: .science,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "engineering-expo",
            name: "Engineering Expo",
            icon: "🛠️",
            blurb: "Trade-floor demos and the firms hiring for the next big build.",
            cost: 1_000,
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
            cost: 900,
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
            cost: 1_800,
            category: .law,
            abilities: [
                .init(keyPath: \.persuasionAndNegotiation, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "design-week",
            name: "Design Week",
            icon: "🎨",
            blurb: "Studios and clients mingling around the season's best work.",
            cost: 700,
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
            cost: 200,
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
            cost: 2_200,
            category: nil,
            abilities: [
                .init(keyPath: \.leadershipAndInfluence, weight: 2),
                .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "world-economic-summit",
            name: "World Economic Summit",
            icon: "🌐",
            blurb: "The flagship gathering of executives and policymakers worldwide.",
            cost: 4_000,
            category: nil,
            abilities: [
                .init(keyPath: \.visionaryThinkingAndAmbition, weight: 2),
                .init(keyPath: \.leadershipAndInfluence, weight: 1),
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
            cost: 400,
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
            cost: 800,
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
            cost: 3_000,
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
