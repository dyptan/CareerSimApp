enum Level: String, CaseIterable, Identifiable {
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
        case .PrimarySchool: return "Primary School Diploma"
        case .MiddleSchool: return "Middle School Diploma"
        case .HighSchool: return "High School Diploma"
        case .Vocational: return "Associate Degree"
        case .Bachelor: return "Bachelor’s Degree"
        case .Master: return "Master’s Degree"
        case .Doctorate: return "Doctorate (PhD)"
        
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
    var id: String { rawValue }

    var description: String {
        switch self {
        case .stem: return "Science, Technology, Engineering, Mathematics"
        case .arts: return "Visual/Performing Arts, Design, Language"
        case .business: return "Business, Management, Economics"
        case .health: return "Medicine, Nursing, Care"
        case .humanities: return "History, Philosophy, Literature, behavioral/social psychology"
        case .trades: return "Construction, Mechanics, Skilled Trades"
        case .law: return "Law, Legal Studies, Jurisprudence"
        }
    }

    func applyBoost(to abilities: SoftSkills) -> SoftSkills {
        var updatedAbilities = abilities
        switch self {
        case .stem:
            updatedAbilities.analyticalReasoning += 12
            updatedAbilities.attentionToDetail += 10
            updatedAbilities.influenceAndNetworking += 5
            updatedAbilities.socialCommunication += 5
        case .arts:
            updatedAbilities.creativeExpression += 12
            updatedAbilities.influenceAndNetworking += 5
            updatedAbilities.socialCommunication += 5
        case .business:
            updatedAbilities.influenceAndNetworking += 15
            updatedAbilities.teamLeadership += 10
            updatedAbilities.riskTolerance += 5
            updatedAbilities.socialCommunication += 5
        case .health:
            updatedAbilities.attentionToDetail += 10
            updatedAbilities.socialCommunication += 5
            updatedAbilities.resilienceCognitive += 5
            updatedAbilities.physicalAbility += 2
        case .humanities:
            updatedAbilities.socialCommunication += 5
            updatedAbilities.analyticalReasoning += 1
            updatedAbilities.creativeExpression += 3
        case .trades:
            updatedAbilities.mechanicalOperation += 10
            updatedAbilities.spatialThinking += 5
            updatedAbilities.resiliencePhysical += 5
        case .law:
            updatedAbilities.analyticalReasoning += 12
            updatedAbilities.attentionToDetail += 10
            updatedAbilities.socialCommunication += 8
            updatedAbilities.influenceAndNetworking += 6
            updatedAbilities.resilienceCognitive += 4
        }
        return updatedAbilities
    }
}
