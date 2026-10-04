import Foundation

/// A professional event — a summit, conference, expo, festival, or pitch
/// competition. Distinct from an Activities discipline (`Sport`): events are a Real Life feature
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
    private let nameResource: LocalizedStringResource
    /// The event's name, in the player's language.
    var name: String { String(localized: nameResource) }
    /// The event's English name — only for code that needs a stable text (the id of the
    /// default "<name> — Speaker" fame award); never shown.
    var englishName: String { nameResource.key }
    let icon: String
    private let blurbResource: LocalizedStringResource
    /// What the event is, in a sentence.
    var blurb: String { String(localized: blurbResource) }
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
    /// The stage role on this event's one button — "Present" for a conference, but
    /// "Perform" at a festival, "Compete" at a pitch, and so on. Purely cosmetic; the
    /// mechanic is identical. An id, not text: `label` / `pastLabel` / `statusLine`
    /// give each language its own wording of the pair.
    let presenterAction: PresenterAction
    private let presenterFameTitleResource: LocalizedStringResource?
    /// An open call — a casting, a festival's emerging-artist stage, a pitch
    /// competition, a call for talks — that anyone may enter, in the field or
    /// not; the acceptance odds are the only gate.
    let isOpenCall: Bool

    /// What a presenter does at an event. Each case carries its own button verb and its own
    /// past-tense status line, so no language has to derive one from the other.
    enum PresenterAction {
        case present, perform, appear, speak, compete, demo

        /// The imperative on the event's button.
        var label: String {
            switch self {
            case .present: return String(localized: "Present", comment: "Button on an event row: give a talk or presentation at the event. A verb.")  // i18n:ignore translator comment
            case .perform: return String(localized: "Perform", comment: "Button on an event row: perform on stage at a festival. A verb.")  // i18n:ignore translator comment
            case .appear:  return String(localized: "Appear", comment: "Button on an event row: appear on a TV show. A verb.")  // i18n:ignore translator comment
            case .speak:   return String(localized: "Speak", comment: "Button on an event row: give a talk at a conference. A verb.")  // i18n:ignore translator comment
            case .compete: return String(localized: "Compete", comment: "Button on an event row: compete in a pitch competition. A verb.")  // i18n:ignore translator comment
            case .demo:    return String(localized: "Demo", comment: "Button on an event row: demonstrate your work at an expo. A verb.")  // i18n:ignore translator comment
            }
        }

        /// The past tense, alone.
        var pastLabel: String {
            switch self {
            case .present: return String(localized: "Presented", comment: "Past tense of the event button 'Present'")  // i18n:ignore translator comment
            case .perform: return String(localized: "Performed", comment: "Past tense of the event button 'Perform'")  // i18n:ignore translator comment
            case .appear:  return String(localized: "Appeared", comment: "Past tense of the event button 'Appear'")  // i18n:ignore translator comment
            case .speak:   return String(localized: "Spoke", comment: "Past tense of the event button 'Speak'")  // i18n:ignore translator comment
            case .compete: return String(localized: "Competed", comment: "Past tense of the event button 'Compete'")  // i18n:ignore translator comment
            case .demo:    return String(localized: "Demoed", comment: "Past tense of the event button 'Demo'")  // i18n:ignore translator comment
            }
        }

        /// The title of an advisor card inviting the player to take the stage ("Present at Tech Summit").
        func cardTitle(at event: String) -> String {
            switch self {
            case .present: return L("Present at \(event)")
            case .perform: return L("Perform at \(event)")
            case .appear:  return L("Appear at \(event)")
            case .speak:   return L("Speak at \(event)")
            case .compete: return L("Compete at \(event)")
            case .demo:    return L("Demo at \(event)")
            }
        }

        /// The status-log line for a stage taken at `event` ("Presented at Tech Summit").
        func statusLine(at event: String) -> String {
            switch self {
            case .present: return L("Presented at \(event)")
            case .perform: return L("Performed at \(event)")
            case .appear:  return L("Appeared at \(event)")
            case .speak:   return L("Spoke at \(event)")
            case .compete: return L("Competed at \(event)")
            case .demo:    return L("Demoed at \(event)")
            }
        }
    }

    init(id: String, name: LocalizedStringResource, icon: String, blurb: LocalizedStringResource,
         category: JobCategory, abilities: [WeightedAbility], networkWeight: Int,
         presenterAction: PresenterAction = .present,
         presenterFameTitleOverride: LocalizedStringResource? = nil,
         isOpenCall: Bool = false) {
        self.id = id
        self.nameResource = name
        self.icon = icon
        self.blurbResource = blurb
        self.category = category
        self.abilities = abilities
        self.networkWeight = networkWeight
        self.presenterAction = presenterAction
        self.presenterFameTitleResource = presenterFameTitleOverride
        self.isOpenCall = isOpenCall
    }

    /// Professional-network points taking the stage here banks in all — the
    /// base for going plus more, since a presenter draws the room (see
    /// `GameConstants.presenterNetworkBonus`).
    var networkPoints: Int { networkWeight + GameConstants.presenterNetworkBonus }

    /// The stage role on the button ("Present", "Perform" …), in the player's language.
    var presenterActionLabel: String { presenterAction.label }

    /// The stage role in the past tense, alone.
    var presenterPastLabel: String { presenterAction.pastLabel }

    /// The status-log line for taking the stage here: "Presented at Tech Summit".
    var presenterStatusLine: String { presenterAction.statusLine(at: name) }

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
    /// scoped to the event's industry, in the player's language. Spotlight events
    /// have a bespoke title ("Festival Performer"); the rest read "<name> — Speaker".
    /// Its stable id is `presenterFameKey`.
    var presenterFameTitle: String {
        if let presenterFameTitleResource { return String(localized: presenterFameTitleResource) }
        return L("\(name) — Speaker")
    }

    /// The English title of that accolade: the id of the `FameAward` it banks. Never shown.
    var presenterFameKey: String {
        presenterFameTitleResource?.key ?? "\(englishName) — Speaker"
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
            presenterAction: .demo
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
            presenterAction: .demo
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
            presenterAction: .demo
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
            presenterAction: .perform,
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
            presenterAction: .appear,
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
            presenterAction: .speak,
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
            presenterAction: .compete,
            presenterFameTitleOverride: "Pitch Winner",
            isOpenCall: true
        ),
    ]

    static let byId: [String: CareerEvent] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )
}
