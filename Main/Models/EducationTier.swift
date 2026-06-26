import Foundation

/// Tier of the institution awarding a degree.
/// Affects tuition, admission soft-skill bar, and post-graduation hiring bonus.
/// Only meaningful for tertiary levels (Vocational, Bachelor, Master, Doctorate).
enum EducationTier: String, Codable, Hashable, CaseIterable {
    case community = "Community"
    case state = "State"
    case elite = "Elite"

    var friendlyName: String {
        switch self {
        case .community: return "Community College"
        case .state:     return "State University"
        case .elite:     return "Elite / Ivy League"
        }
    }

    var pictogram: String {
        switch self {
        case .community: return "🏫"
        case .state:     return "🏛️"
        case .elite:     return "🏆"
        }
    }

    var description: String {
        switch self {
        case .community:
            return "Open admissions, low tuition, practical focus. Great way to start when budget or grades are tight."
        case .state:
            return "Solid mainstream university — moderate tuition, broad recognition, balanced admission bar."
        case .elite:
            return "Highly selective top-ranked school — steep tuition, demanding admissions, but strong career boost."
        }
    }

    /// 1 = unranked / open-access, 2 = mainstream, 3 = elite.
    var prestige: Int {
        switch self {
        case .community: return 1
        case .state:     return 2
        case .elite:     return 3
        }
    }

    /// Extra soft-skill threshold added on top of the profile's base requirements.
    /// Only elite schools raise the admission bar; state matches community.
    var requirementBonus: Int {
        switch self {
        case .community: return 0
        case .state:     return 0
        case .elite:     return 1
        }
    }

    /// Selectivity modifier folded into the admission-probability calculation
    /// (see `Education.admissionProbability`). Community runs near-open admission;
    /// elite turns away even well-qualified applicants.
    var admissionSelectivity: Double {
        switch self {
        case .community: return 0.10
        case .state:     return 0.0
        case .elite:     return -0.18
        }
    }

    /// Annual tuition in USD for the given degree level.
    /// Reflects rough US averages: community ≪ state ≪ private elite. Doctorates
    /// are largely funded (assistantships/stipends), so they cost little to nothing.
    func annualTuition(for level: Level.Stage) -> Int {
        switch (self, level) {
        case (.community, .Vocational): return 4_000
        case (.community, .Bachelor):   return 4_000
        case (.community, .Master):     return 7_000
        case (.community, .Doctorate):  return 0       // funded

        case (.state, .Vocational):     return 8_000
        case (.state, .Bachelor):       return 12_000
        case (.state, .Master):         return 22_000
        case (.state, .Doctorate):      return 3_000   // mostly funded; nominal fees

        case (.elite, .Vocational):     return 18_000
        case (.elite, .Bachelor):       return 58_000
        case (.elite, .Master):         return 55_000
        case (.elite, .Doctorate):      return 8_000   // funded; some private fees

        default:                        return 0  // K-12 is free in this sim
        }
    }

    /// Hire-probability bonus a degree from this tier confers post-graduation.
    /// Compounds with the rest of the hire-probability calculation.
    var hireBonus: Double {
        switch self {
        case .community: return 0.0
        case .state:     return 0.05
        case .elite:     return 0.10
        }
    }
}
