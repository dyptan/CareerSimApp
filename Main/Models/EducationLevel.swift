import Foundation

// Stage-only representation of education level
struct Level: Codable, Hashable, Identifiable {
    enum Stage: String, CaseIterable, Codable, Hashable {
        case PrimarySchool
        case MiddleSchool
        case HighSchool
        case Vocational
        case Bachelor
        case Master
        case Doctorate
    }

    var stage: Stage

    var id: String { stage.rawValue }

    // EQF mapping by stage
    var eqf: Int {
        switch stage {
        case .PrimarySchool: return 1
        case .MiddleSchool: return 2
        case .HighSchool: return 3
        case .Vocational: return 4
        case .Bachelor: return 5
        case .Master: return 6
        case .Doctorate: return 7
        }
    }

    /// Human-readable generic degree label (EU default)
    var degree: String {
        switch stage {
        case .PrimarySchool: return "Primary School"
        case .MiddleSchool: return "Middle School"
        case .HighSchool: return "High School"
        case .Vocational: return "Vocational Diploma"
        case .Bachelor: return "Bachelor"
        case .Master: return "Master"
        case .Doctorate: return "Doctorate"
        }
    }

    var pictogram: String {
        switch stage {
        case .PrimarySchool: return "🧒"
        case .MiddleSchool:  return "👦"
        case .HighSchool:    return "🧑"
        case .Vocational:    return "👷"
        case .Bachelor:      return "👨‍🎓"
        case .Master:        return "🎓"
        case .Doctorate:     return "👨‍🔬"
        }
    }

    /// Human-readable generic degree label (US variant)
    var degreeUS: String {
        switch stage {
        case .PrimarySchool: return "Elementary School"
        case .MiddleSchool: return "Middle School"
        case .HighSchool: return "High School"
        case .Vocational: return "Trade Certificate"
        case .Bachelor: return "Bachelor’s Degree"
        case .Master: return "Master’s Degree"
        case .Doctorate: return "Doctoral Degree"
        }
    }

    /// Plain-language explanation of the education level, for the in-game info popover.
    var description: String {
        switch stage {
        case .PrimarySchool: return "Ages roughly 6–10. Reading, writing, basic math — the foundation everything else builds on."
        case .MiddleSchool: return "Ages roughly 11–13. Subjects branch out into science, history, languages, and the arts."
        case .HighSchool: return "Ages roughly 14–17. A diploma is needed for most jobs and to apply to college or vocational programmes."
        case .Vocational: return "Hands-on training (1–3 years) for a specific trade — like welding, plumbing, nursing assistant, or electrician work. Faster and cheaper than a Bachelor’s."
        case .Bachelor: return "Three to four years of university. The most common entry point to professional jobs."
        case .Master: return "One to two more years of focused study after a Bachelor. Opens up senior roles and research careers."
        case .Doctorate: return "Three or more years of original research after a Master. Required for university professors, scientists, and physicians."
        }
    }

    /// Number of in-game years typically needed to complete this level
    func yearsToComplete() -> Int {
        switch stage {
        case .PrimarySchool: return 5
        case .MiddleSchool: return 3
        case .HighSchool: return 3
        case .Vocational: return 2
        case .Bachelor: return 3
        case .Master: return 2
        case .Doctorate: return 3
        }
    }
}
