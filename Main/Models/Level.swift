enum Level: String, CaseIterable, Identifiable {
    case Kindergarten
    case PrimarySchool
    case MiddleSchool
    case HighSchool
    case Vocational
    case Bachelor
    case Master
    case Doctorate
    
    var id: String { rawValue }

    var eqf: Int {
        switch self {
        case .Kindergarten : return 1
        case .PrimarySchool : return 2
        case .MiddleSchool : return 3
        case .HighSchool : return 4
        case .Vocational : return 5
        case .Bachelor: return 6
        case .Master: return 7
        case .Doctorate: return 8
        }
    }
    
    func yearsToComplete(_ isUS: Bool = false) -> Int {
        switch (self, isUS) {
        case (.Kindergarten, _): return 4
        case (.PrimarySchool, _): return 4
        case (.MiddleSchool, true): return 4
        case (.MiddleSchool, false): return 5
        case (.HighSchool, true): return 4
        case (.HighSchool, false): return 3
        case (.Vocational, _): return 2
        case (.Bachelor, true): return 4
        case (.Bachelor, false): return 3
        case (.Master, _): return 2
        case (.Doctorate, _): return 3
        }
    }

    var next: [Level] {
        switch self {
        case .Kindergarten: return [.PrimarySchool]
        case .PrimarySchool: return [.MiddleSchool]
        case .MiddleSchool: return [.HighSchool]
        case .HighSchool: return [.Vocational, .Bachelor]
        case .Vocational: return [.Bachelor]
        case .Bachelor: return [.Master]
        case .Master: return [.Doctorate]
        case .Doctorate: return []
        }
    }

    var degree: String {
        switch self {
        case .Kindergarten: return "👶"
        case .PrimarySchool: return "Primary School 🧒"
        case .MiddleSchool: return "Middle School 👦"
        case .HighSchool: return "High School 👱‍♂️"
        case .Vocational: return "Associate Degree 🧑‍🔧"
        case .Bachelor: return "Bachelor’s Degree 👨‍🎓"
        case .Master: return "Master’s Degree 🎓"
        case .Doctorate: return "Doctorate (PhD) 💼"
        }
    }
}

enum TertiaryProfile: String, CaseIterable, Identifiable {
    case stem = "STEM"
    case arts = "Arts"
    case business = "Business"
    case health = "Health"
    case humanities = "Humanities"
    case trades = "Trades & Tech"
    case law = "Law"
    case education = "Education"
    case media = "Media & Communication"
    case hospitality = "Hospitality & Tourism"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .stem: return "Science, Technology, Engineering, Mathematics"
        case .arts: return "Visual/Performing Arts, Design, Language"
        case .business: return "Business, Management, Economics, Entrepreneurship"
        case .health: return "Medicine, Nursing, Care, Allied Health"
        case .humanities: return "History, Philosophy, Literature, Social Studies"
        case .trades: return "Construction, Mechanics, Skilled Trades, Tech"
        case .law: return "Law, Legal Studies, Jurisprudence"
        case .education: return "Teaching, Child Development, Educational Leadership"
        case .media: return "Journalism, PR, Broadcasting, Content Creation"
        case .hospitality: return "Hospitality, Tourism, Events, Customer Service"
        }
    }

    func applyBoost(to abilities: SoftSkills, for level: Level = .Bachelor, isUS: Bool = false) -> SoftSkills {
        var updated = abilities

        let years = level.yearsToComplete(isUS)
        updated.communicationAndNetworking += years
        updated.leadershipAndInfluence += years

        switch self {
        case .stem:
            updated.analyticalReasoningAndProblemSolving += 12
            updated.carefulnessAndAttentionToDetail += 10
            updated.tinkeringAndFingerPrecision += 8
            updated.perseveranceAndGrit += 6
            updated.spacialNavigation += 3

        case .arts:
            updated.creativityAndInsightfulThinking += 12
            updated.communicationAndNetworking += 6
            updated.carefulnessAndAttentionToDetail += 6
            updated.leadershipAndInfluence += 4
            updated.perseveranceAndGrit += 3

        case .business:
            updated.leadershipAndInfluence += 12
            updated.creativityAndInsightfulThinking += 10
            updated.courageAndRiskTolerance += 6
            updated.communicationAndNetworking += 6
            updated.analyticalReasoningAndProblemSolving += 3
            updated.carefulnessAndAttentionToDetail += 3

        case .health:
            updated.carefulnessAndAttentionToDetail += 12
            updated.communicationAndNetworking += 6
            updated.perseveranceAndGrit += 6
            updated.resilienceAndEndurance += 4
            updated.physicalStrength += 2

        case .humanities:
            updated.communicationAndNetworking += 8
            updated.analyticalReasoningAndProblemSolving += 4
            updated.creativityAndInsightfulThinking += 4
            updated.perseveranceAndGrit += 3
            updated.carefulnessAndAttentionToDetail += 3

        case .trades:
            updated.tinkeringAndFingerPrecision += 12
            updated.spacialNavigation += 6
            updated.resilienceAndEndurance += 6
            updated.physicalStrength += 4
            updated.carefulnessAndAttentionToDetail += 4

        case .law:
            updated.analyticalReasoningAndProblemSolving += 12
            updated.carefulnessAndAttentionToDetail += 10
            updated.communicationAndNetworking += 8
            updated.perseveranceAndGrit += 6
            updated.leadershipAndInfluence += 4

        case .education:
            updated.communicationAndNetworking += 12
            updated.leadershipAndInfluence += 8
            updated.perseveranceAndGrit += 6
            updated.carefulnessAndAttentionToDetail += 4
            updated.creativityAndInsightfulThinking += 4

        case .media:
            updated.communicationAndNetworking += 12
            updated.creativityAndInsightfulThinking += 8
            updated.leadershipAndInfluence += 6
            updated.carefulnessAndAttentionToDetail += 4

        case .hospitality:
            updated.communicationAndNetworking += 10
            updated.leadershipAndInfluence += 6
            updated.resilienceAndEndurance += 6
            updated.carefulnessAndAttentionToDetail += 3
        }

        return updated
    }
}
