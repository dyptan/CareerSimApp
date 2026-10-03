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
        case .PrimarySchool: return String(localized: "Primary School", comment: "Education stage, ages roughly 6–10 (generic name, used where the country has no school name of its own).")
        case .MiddleSchool: return String(localized: "Middle School", comment: "Education stage, ages roughly 11–13 (lower secondary school).")
        case .HighSchool: return String(localized: "High School", comment: "Education stage, ages roughly 14–17 (upper secondary school).")
        case .Vocational: return String(localized: "Vocational Diploma", comment: "Education stage: a hands-on trade qualification, after school and before university.")
        case .Bachelor: return String(localized: "Bachelor", comment: "Education stage: the first university degree, as a level name on its own (not “Bachelor of …”).")
        case .Master: return String(localized: "Master", comment: "Education stage: the second university degree, as a level name on its own (not “Master of …”).")
        case .Doctorate: return String(localized: "Doctorate", comment: "Education stage: the highest degree (PhD, medical or law doctorate), as a level name on its own.")
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
        case .PrimarySchool: return String(localized: "Elementary School", comment: "US name for the first school stage, ages roughly 6–10.")
        case .MiddleSchool: return L("Middle School")
        case .HighSchool: return L("High School")
        case .Vocational: return String(localized: "Trade Certificate", comment: "US name for a vocational qualification in a skilled trade.")
        case .Bachelor: return L("Bachelor’s Degree")
        case .Master: return L("Master’s Degree")
        case .Doctorate: return L("Doctoral Degree")
        }
    }

    /// Plain-language explanation of the education level, for the in-game info popover.
    var description: String {
        switch stage {
        case .PrimarySchool: return L("Ages roughly 6–10. Reading, writing, basic math — the foundation everything else builds on.")
        case .MiddleSchool: return L("Ages roughly 11–13. Subjects branch out into science, history, languages, and the arts.")
        case .HighSchool: return L("Ages roughly 14–17. A diploma is needed for most jobs and to apply to college or vocational programmes.")
        case .Vocational: return L("Hands-on training (1–3 years) for a specific trade — like welding, plumbing, nursing assistant, or electrician work. Faster and cheaper than a Bachelor’s.")
        case .Bachelor: return L("Four years of university. The most common entry point to professional jobs.")
        case .Master: return L("One to two more years of focused study after a Bachelor. Opens up senior roles and research careers.")
        case .Doctorate: return L("Four years after a Bachelor — medical school, law school, or a research PhD. Required for physicians, lawyers, professors and scientists. Medicine and law are expensive and selective.")
        }
    }

    /// Number of in-game years typically needed to complete this level
    func yearsToComplete() -> Int {
        switch stage {
        case .PrimarySchool: return 5
        case .MiddleSchool: return 3
        case .HighSchool: return 3
        case .Vocational: return 2
        case .Bachelor: return 4
        case .Master: return 2
        case .Doctorate: return 4
        }
    }
}
