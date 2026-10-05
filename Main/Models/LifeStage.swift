struct WeightedAbility {
    let keyPath: WritableKeyPath<SoftSkills, Int>
    let weight: Int
}

// Age-driven life stages that gate which activities and competitions are open.
// Tagged on each `Sport` and `Competition`; the Activities sheet filters by the
// player's current stage. (Paid professional networking — summits,
// conferences — lives separately in `CareerEvent` / `EventCatalog`.)
enum LifeStage: String, CaseIterable, Hashable {
    case child       // 7–10  (primary school)
    case teen        // 11–17 (middle / high school)
    case youngAdult  // 18–24 (college, early career)
    case adult       // 25+   (working life)

    static func forAge(_ age: Int) -> LifeStage {
        switch age {
        case ..<11: return .child
        case 11...17: return .teen
        case 18...24: return .youngAdult
        default: return .adult
        }
    }

    var displayName: String {
        switch self {
        case .child: return String(localized: "Childhood", comment: "Life stage, ages 7–10: primary school years.")
        case .teen: return String(localized: "Teen Years", comment: "Life stage, ages 11–17: middle and high school years.")
        case .youngAdult: return String(localized: "Young Adult", comment: "Life stage, ages 18–24: college and early career.")
        case .adult: return String(localized: "Working Life", comment: "Life stage, age 25 and over: the working years.")
        }
    }
}
