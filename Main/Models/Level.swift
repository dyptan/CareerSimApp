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

    // Apply profile-based boosts to soft skills.
    // Includes baseline +1 per year to communication and leadershipAndFriends.
    func applyBoost(to abilities: SoftSkills, for level: Level = .Bachelor, isUS: Bool = false) -> SoftSkills {
        var updated = abilities

        // Baseline: each year of study grows communication and leadership/teamwork.
        let years = level.yearsToComplete(isUS)
        updated.communication += years
        updated.leadershipAndFriends += years

        switch self {
        case .stem:
            // Strong technical/problem skills, carefulness, tinkering; some grit.
            updated.problemSolving += 12
            updated.carefulness += 10
            updated.tinkering += 8
            updated.focusAndGrit += 6
            // Optional smaller boosts
            updated.navigation += 3

        case .arts:
            // Creativity and communication, plus carefulness for craft.
            updated.creativity += 12
            updated.communication += 6
            updated.carefulness += 6
            // Some leadership via performances/projects
            updated.leadershipAndFriends += 4
            // Focus on practice
            updated.focusAndGrit += 3

        case .business:
            // Leadership, entrepreneurship, risk taking, communication.
            updated.leadershipAndFriends += 12
            updated.entrepreneurship += 10
            updated.riskTaking += 6
            updated.communication += 6
            // Some problem solving and carefulness (finance/ops)
            updated.problemSolving += 3
            updated.carefulness += 3

        case .health:
            // Accuracy, empathy/communication, grit; some physical/stamina.
            updated.carefulness += 12
            updated.communication += 6
            updated.focusAndGrit += 6
            updated.stamina += 4
            updated.strength += 2

        case .humanities:
            // Communication, reasoning, some creativity.
            updated.communication += 8
            updated.problemSolving += 4
            updated.creativity += 4
            updated.focusAndGrit += 3
            updated.carefulness += 3

        case .trades:
            // Hands-on, navigation, physical stamina and weather endurance.
            updated.tinkering += 12
            updated.navigation += 6
            updated.stamina += 6
            updated.weatherEndurance += 5
            updated.strength += 4
            // Some carefulness for precision work
            updated.carefulness += 4

        case .law:
            // Reasoning, carefulness, communication, grit; some leadership.
            updated.problemSolving += 12
            updated.carefulness += 10
            updated.communication += 8
            updated.focusAndGrit += 6
            updated.leadershipAndFriends += 4

        case .education:
            // Strong communication and leadership/teamwork; patience/grit.
            updated.communication += 12
            updated.leadershipAndFriends += 8
            updated.focusAndGrit += 6
            updated.carefulness += 4
            // Creativity for lesson design
            updated.creativity += 4

        case .media:
            // Communication, creativity, leadership/team projects; carefulness for accuracy.
            updated.communication += 12
            updated.creativity += 8
            updated.leadershipAndFriends += 6
            updated.carefulness += 4
            // Entrepreneurship for creators
            updated.entrepreneurship += 3

        case .hospitality:
            // Communication, leadership/teamwork, stamina; some entrepreneurship.
            updated.communication += 10
            updated.leadershipAndFriends += 6
            updated.stamina += 6
            updated.entrepreneurship += 3
            // Carefulness for service quality
            updated.carefulness += 3
        }

        return updated
    }
}
