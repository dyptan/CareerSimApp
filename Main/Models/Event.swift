import Foundation

/// A professional event — a summit, conference, expo, festival, or pitch
/// competition. Distinct from an Activities discipline (`Sport`): events are a realistic-mode feature
/// that build an industry **professional network** improving both the hiring
/// odds on that field's job postings and the chance of promotion while working
/// in it (see `Player.networkBonus` and `Player.promotionChance`). They also
/// nudge the networking-flavoured soft skills, applied immediately the way an
/// activity's are.
///
/// Two ways to take part, as at a real conference: **attend** — open to anyone
/// working in or studying toward the field (and to anyone at all for an open
/// call) — which banks the event's network; or **apply to take the stage**,
/// an application with acceptance odds (see `Player.presentOdds`) that, if
/// accepted, banks more network plus a fame award in that industry. A rejected
/// application still counts as attending.
struct CareerEvent: Identifiable {
    let id: String
    let name: String
    let icon: String
    let blurb: String
    /// Industry this event serves: presenting here builds that field's network
    /// and banks a fame award in it.
    let category: JobCategory
    /// Soft-skill nudges, applied immediately on attendance (like an activity).
    let abilities: [WeightedAbility]
    /// Base professional-network points this event is worth (1–3). Accumulates
    /// in `Player.networkByCategory` and feeds hiring + promotion; taking the
    /// stage banks more than this (see `networkPoints`).
    let networkWeight: Int
    /// Verb for the "take the stage" role on this event's row — "Present" for a
    /// conference, but "Perform" at a festival, "Compete" at a pitch, and so on.
    /// Purely cosmetic; the mechanic is identical.
    let presenterActionLabel: String
    /// Bespoke title for the fame award a presenter banks (e.g. "Festival
    /// Performer", "Pitch Winner"). `nil` falls back to "<name> — Speaker".
    let presenterFameTitleOverride: String?
    /// An open call — a casting, a festival's emerging-artist stage, a pitch
    /// competition, a call for talks — that anyone may enter, in the field or
    /// not; the acceptance odds are the only gate.
    let isOpenCall: Bool

    init(id: String, name: String, icon: String, blurb: String, category: JobCategory,
         abilities: [WeightedAbility], networkWeight: Int,
         presenterActionLabel: String = "Present",
         presenterFameTitleOverride: String? = nil,
         isOpenCall: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.blurb = blurb
        self.category = category
        self.abilities = abilities
        self.networkWeight = networkWeight
        self.presenterActionLabel = presenterActionLabel
        self.presenterFameTitleOverride = presenterFameTitleOverride
        self.isOpenCall = isOpenCall
    }

    /// Professional-network points taking the stage here banks — more than
    /// attending, since a presenter draws the room (see
    /// `GameConstants.presenterNetworkBonus`).
    var networkPoints: Int { networkWeight + GameConstants.presenterNetworkBonus }

    /// The stage role in the past tense, for the status log.
    var presenterPastLabel: String {
        switch presenterActionLabel {
        case "Present": return "Presented"
        case "Perform": return "Performed"
        case "Appear":  return "Appeared"
        case "Speak":   return "Spoke"
        case "Compete": return "Competed"
        case "Demo":    return "Demoed"
        default:        return "Took the stage"
        }
    }

    /// Degree fields whose students count as being in this event's field.
    var studyProfiles: [TertiaryProfile] {
        if let profiles = JobCatalog.defaultAcceptedProfiles(for: category) { return profiles }
        switch category {
        case .construction, .manufacturing: return [.engineering]
        case .hospitality:                  return [.service]
        case .retail:                       return [.business]
        case .transportation:               return [.engineering, .business]
        case .publicServices:               return [.law, .service]
        default:                            return []
        }
    }

    /// The fame accolade banked (when the year advances) for presenting here,
    /// scoped to the event's industry. Spotlight events override the default
    /// speaker wording.
    var presenterFameTitle: String {
        presenterFameTitleOverride ?? "\(name) — Speaker"
    }

    /// Reputation weight of the presenter fame award. Being accepted onto the
    /// stage is a genuine accomplishment, so it banks meaningfully more fame
    /// than its raw network points: a significant hiring lever in that same
    /// industry (see `Player.fameHireBonus`), and it compounds each year you
    /// present. Flagship summits (higher `networkWeight`) are worth proportionally
    /// more.
    var presenterFameWeight: Double {
        Double(networkWeight) * GameConstants.accomplishmentFameMultiplier
    }
}

enum EventCatalog {
    /// The events on offer — at least one for every field people work in. Each
    /// is tagged to the industry whose network it builds.
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
            category: .business,
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
                .init(keyPath: \.communicationAndNetworking, weight: 3)
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
                .init(keyPath: \.communicationAndNetworking, weight: 2)
            ],
            networkWeight: 1
        ),
        // Every other field's gathering — so a teacher, a chef, a builder or a
        // civil servant can network in their trade too.
        CareerEvent(
            id: "education-conference",
            name: "Teaching & Learning Conference",
            icon: "🍎",
            blurb: "Teachers and school leaders swapping what works in the classroom.",
            category: .education,
            abilities: [
                .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "hospitality-expo",
            name: "Hospitality & Food Expo",
            icon: "🍽️",
            blurb: "Chefs, hoteliers and suppliers — tastings, trends and who's hiring.",
            category: .hospitality,
            abilities: [
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2,
            presenterActionLabel: "Demo"
        ),
        CareerEvent(
            id: "retail-expo",
            name: "Retail & Consumer Expo",
            icon: "🛍️",
            blurb: "Brands, buyers and store managers on what shoppers want next.",
            category: .retail,
            abilities: [
                .init(keyPath: \.persuasionAndNegotiation, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 1
        ),
        CareerEvent(
            id: "wellness-expo",
            name: "Beauty & Wellness Expo",
            icon: "💇",
            blurb: "Stylists, therapists and trainers showing their craft to the trade.",
            category: .service,
            abilities: [
                .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 1,
            presenterActionLabel: "Demo"
        ),
        CareerEvent(
            id: "trades-expo",
            name: "Construction & Trades Expo",
            icon: "🏗️",
            blurb: "Contractors, trades and suppliers — new tools, big projects, the crews behind them.",
            category: .construction,
            abilities: [
                .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2,
            presenterActionLabel: "Demo"
        ),
        CareerEvent(
            id: "manufacturing-show",
            name: "Manufacturing & Robotics Show",
            icon: "🏭",
            blurb: "Factory floors of the future and the people who run them.",
            category: .manufacturing,
            abilities: [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "logistics-summit",
            name: "Logistics & Transport Summit",
            icon: "🚚",
            blurb: "Fleets, freight and supply chains — the people who keep things moving.",
            category: .transportation,
            abilities: [
                .init(keyPath: \.timeManagementAndPlanning, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 1
        ),
        CareerEvent(
            id: "farm-show",
            name: "Farm Show",
            icon: "🚜",
            blurb: "Growers, breeders and machinery dealers — the year's big agricultural gathering.",
            category: .agriculture,
            abilities: [
                .init(keyPath: \.resilienceAndEndurance, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 1
        ),
        CareerEvent(
            id: "public-service-forum",
            name: "Public Service Forum",
            icon: "🏛️",
            blurb: "City, state and emergency services leaders on running things for everyone.",
            category: .publicServices,
            abilities: [
                .init(keyPath: \.collaborationAndTeamwork, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 2
        ),
        CareerEvent(
            id: "operations-summit",
            name: "Office & Operations Summit",
            icon: "🗂️",
            blurb: "The people who keep organisations running — admins, office managers, operations leads.",
            category: .administration,
            abilities: [
                .init(keyPath: \.timeManagementAndPlanning, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ],
            networkWeight: 1
        ),
        // Spotlight & competitive events — open calls anyone may enter, in the
        // field or not: the acceptance odds are the gate. They're participation
        // in someone else's event rather than a self-initiated work, which is
        // what separates them from spare-time *projects*.
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
            presenterFameTitleOverride: "Festival Performer",
            isOpenCall: true
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
            presenterFameTitleOverride: "TV Personality",
            isOpenCall: true
        ),
        CareerEvent(
            id: "conference-talk",
            name: "Conference Talk",
            icon: "🖥️",
            blurb: "Attend to meet the field — or take the podium and land your idea in front of the room.",
            category: .business,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 2)
            ],
            networkWeight: 1,
            presenterActionLabel: "Speak",
            presenterFameTitleOverride: "Noted Speaker",
            isOpenCall: true
        ),
        CareerEvent(
            id: "pitch-competition",
            name: "Pitch Competition",
            icon: "🎤",
            blurb: "Work the room of founders and investors — or take the stage to pitch your idea and win it.",
            category: .business,
            abilities: [
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.persuasionAndNegotiation, weight: 1)
            ],
            networkWeight: 2,
            presenterActionLabel: "Compete",
            presenterFameTitleOverride: "Pitch Winner",
            isOpenCall: true
        ),
    ]

    static let byId: [String: CareerEvent] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )
}
