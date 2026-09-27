import Foundation

/// A professional event — a summit, conference, expo, festival, or pitch
/// competition. Distinct from an Activities discipline (`Sport`): events are a realistic-mode feature
/// that build an industry **professional network** improving both the hiring
/// odds on that field's job postings and the chance of promotion while working
/// in it (see `Player.networkBonus` and `Player.promotionChance`). They also
/// nudge the networking-flavoured soft skills, applied immediately the way an
/// activity's are.
///
/// One way to take part: **apply to take the stage** — speak, present,
/// perform or pitch — an application with acceptance odds (see
/// `Player.presentOdds`), open to anyone working in or studying toward the
/// field, and to anyone at all for an open call. The player goes either way,
/// which banks the event's base network; accepted, they bank more network plus
/// a fame award in that industry.
struct CareerEvent: Identifiable {
    let id: String
    let name: String
    let icon: String
    let blurb: String
    /// Industry this event serves: presenting here builds that field's network
    /// and banks a fame award in it.
    let category: JobCategory
    /// Soft-skill nudges, applied immediately on applying (like an activity).
    let abilities: [WeightedAbility]
    /// Base professional-network points this event is worth (1–3), banked by
    /// going at all — a turned-down applicant still goes. Accumulates in
    /// `Player.networkByCategory` and feeds hiring + promotion; taking the
    /// stage banks more than this (see `networkPoints`).
    let networkWeight: Int
    /// Verb on this event's one button — "Present" for a conference, but
    /// "Perform" at a festival, "Compete" at a pitch, and so on. Purely
    /// cosmetic; the mechanic is identical.
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

    /// Professional-network points taking the stage here banks in all — the
    /// base for going plus more, since a presenter draws the room (see
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
            blurb: "The tech world's big yearly meetup — talks on new apps, gadgets and ideas.",
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
            blurb: "Where people with business ideas meet the investors who fund them.",
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
            blurb: "Bankers and investors talk about money and where the markets are heading.",
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
            blurb: "Doctors and nurses share the latest in medicine.",
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
            blurb: "Scientists share their newest discoveries.",
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
            blurb: "Engineers show off new machines and plans for big builds.",
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
            blurb: "Writers, filmmakers and online creators meet and share their work.",
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
            blurb: "Lawyers and judges talk about the law and big cases.",
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
            blurb: "Designers show off the year's best work.",
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
            blurb: "Teachers share what works best in the classroom.",
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
            blurb: "Chefs and hotel people show off new dishes and ideas.",
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
            blurb: "Shops and brands show what people will want to buy next.",
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
            blurb: "Hairdressers, therapists and trainers show off their skills.",
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
            blurb: "Builders and tradespeople show off new tools and big projects.",
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
            blurb: "Factories show off their newest robots and machines.",
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
            blurb: "The people who move things around by truck, train, ship and plane.",
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
            blurb: "Farmers show off their animals, crops and new machines.",
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
            blurb: "People who run towns, cities and emergency services share ideas.",
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
            blurb: "Office managers and assistants share how to keep a workplace running.",
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
            blurb: "Play your music on the festival stage in front of a big crowd.",
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
            blurb: "Get a spot on a TV show and let everyone see you.",
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
            blurb: "Give a talk and share your big idea with a room full of people.",
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
            blurb: "Pitch your business idea on stage and try to win.",
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
