import Foundation

/// Tier of the institution awarding a degree.
/// Affects tuition, admission soft-skill bar, and post-graduation hiring bonus.
/// Only meaningful for tertiary levels (Vocational, Bachelor, Master, Doctorate).
enum EducationTier: String, Codable, Hashable, CaseIterable {
    case community = "Community"  // i18n:ignore id
    case state = "State"  // i18n:ignore id
    case elite = "Elite"  // i18n:ignore id

    var friendlyName: String {
        switch self {
        case .community: return String(localized: "Community College", comment: "Institution tier: an open-admission two-year college (US).")
        case .state:     return String(localized: "State University", comment: "Institution tier: a mainstream public university.")
        case .elite:     return String(localized: "Elite / Ivy League", comment: "Institution tier: a top, highly selective university (Ivy League is the US group of elite universities).")
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
            return L("Almost everyone gets in. A great place to start if grades are tight.")
        case .state:
            return L("A good, well-known university. You need decent grades and skills to get in.")
        case .elite:
            return L("One of the very best schools. Very hard to get into — but it gives your career a big boost.")
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

    /// Extra soft-skill target added on top of the profile's base ones — it makes
    /// a strong applicant harder to be, not admission impossible. Only elite
    /// schools raise the bar; state matches community.
    var requirementBonus: Int {
        switch self {
        case .community: return 0
        case .state:     return 0
        case .elite:     return 1
        }
    }

    /// How much of the admission fit high-school grades make up, against soft
    /// skills, for a first degree (see `Education.gradeWeight`). An open-door
    /// community college barely looks at a transcript; an elite school reads it
    /// first.
    var gradeWeight: Double {
        switch self {
        case .community: return 0.1
        case .state:     return 0.35
        case .elite:     return 0.5
        }
    }

    /// How much of the admission fit trophies and accolades make up (see
    /// `Education.accoladeWeight`). An open-door college doesn't ask; a
    /// selective school wants to know what you've won.
    var accoladeWeight: Double {
        switch self {
        case .community: return 0
        case .state:     return 0.1
        case .elite:     return 0.2
        }
    }

    /// The share of thin applicants this school still takes — the bottom of its
    /// admission band (see `Education.admissionProbability`). A community college
    /// runs open admission, which is what a community college *is*, so it takes
    /// almost anyone who walks in; an elite school takes almost nobody on a thin
    /// record however open the door formally is.
    var admissionFloor: Double {
        // Community colleges are open access; more than half of four-year
        // colleges admit two-thirds of applicants or more (Pew 2019); Ivy-plus
        // schools admit ~4 % (Class of 2029).
        switch self {
        case .community: return 0.95
        case .state:     return 0.45
        case .elite:     return 0.01
        }
    }

    /// How far a flawless soft-skill record lifts the odds above `admissionFloor`.
    /// Narrow at community, where there was little to earn, and wide above it, so
    /// the years a player spends building skills are what buys them a better
    /// school. The sum is the ceiling: 98% community, 90% state, and 65% elite —
    /// even a perfect applicant is turned away from an elite place a third of the
    /// time, so getting in is earned over years rather than given.
    var admissionFitSpan: Double {
        switch self {
        case .community: return 0.03
        case .state:     return 0.47
        case .elite:     return 0.34
        }
    }

    /// How steeply the band rewards fit (`raw = floor + span × fit^exponent`).
    /// Linear for open and state schools; steep at an elite school, where a
    /// merely good record barely moves the odds and only an outstanding one
    /// does — most top-scoring applicants are still turned away.
    var admissionFitExponent: Double {
        switch self {
        case .community, .state: return 1.0
        case .elite:             return 2.5
        }
    }

    /// The schools that offer `level` in `profile` — one source for the
    /// Education sheet and the balance harness. Simplified has a single
    /// neutral community school. Elite institutions exist only for white-
    /// collar fields; community colleges award no master's or doctorates.
    static func offered(level: Level.Stage, profile: TertiaryProfile, simplified: Bool) -> [EducationTier] {
        if simplified { return [.community] }
        return allCases.filter { tier in
            (tier != .elite || profile.isWhiteCollar)
                && (tier != .community || (level != .Master && level != .Doctorate))
        }
    }

    /// Annual tuition in USD for the given degree level and field — the net
    /// price a middle-income student has to finance (College Board 2025-26:
    /// public 4-year ~$11.9k published, private nonprofit ~$16.9k net). A
    /// research doctorate is funded; a professional doctorate is not:
    /// medicine (AAMC median debt $200k) and law (ABA: $32k public, $58k
    /// private) are among the costliest degrees there are.
    func annualTuition(for level: Level.Stage, profile: TertiaryProfile? = nil) -> Int {
        if level == .Doctorate, let profile {
            switch (self, profile) {
            case (.elite, .health): return 75_000
            case (_, .health):      return 60_000
            case (.elite, .law):    return 58_000
            case (_, .law):         return 32_000
            default:                break
            }
        }
        switch (self, level) {
        case (.community, .Vocational): return 4_000
        case (.community, .Bachelor):   return 4_000
        case (.community, .Master):     return 7_000
        case (.community, .Doctorate):  return 0       // funded

        case (.state, .Vocational):     return 8_000
        case (.state, .Bachelor):       return 10_000
        case (.state, .Master):         return 22_000
        case (.state, .Doctorate):      return 3_000   // mostly funded; nominal fees

        case (.elite, .Vocational):     return 18_000
        case (.elite, .Bachelor):       return 30_000   // net of heavy need-based aid
        case (.elite, .Master):         return 55_000
        case (.elite, .Doctorate):      return 8_000   // funded; some private fees

        default:                        return 0  // K-12 is free in this sim
        }
    }

}
