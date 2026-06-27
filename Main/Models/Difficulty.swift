import Foundation

/// The single difficulty choice made once at launch. It rolls together how much
/// of the simulation's complexity is in play (the kid-friendly "Simplified"
/// setting strips skills, tiers, negotiation, and the economy entirely) with —
/// for the realistic settings — the player's economic starting point: how much
/// of each paycheck is left to save after living costs, and how turbulent the
/// economy is (how often downturns strike and how likely they are to drag on).
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    // NOTE: the raw case names are persisted (Codable) and referenced across the
    // app, so they stay fixed. Only the player-facing `title`/`blurb` track the
    // displayed names (Simplified / Relaxed / Real Life).

    /// "Simplified". Kid-friendly: getting hired needs only the right degree plus
    /// enough years in the field. No soft-skill hiring score, hard skills, company
    /// tiers, education tiers, salary negotiation, or economy simulation.
    /// Junior→senior still progresses through years of experience.
    case simplified
    /// "Relaxed". High-income family, no recessions, and opportunities tilted in
    /// the player's favour — a large share of income is saved, the economy never
    /// falters, and hiring and college admission come easier.
    case comfortable
    /// "Real Life". Middle-income household, baseline volatility. The original
    /// realistic-mode balance.
    case middleClass

    var id: String { rawValue }

    /// The default when a game starts before a difficulty is chosen.
    static let `default`: Difficulty = .middleClass

    /// True when only the basic (degree + experience) rules apply — no skills,
    /// tiers, negotiation, or economy simulation.
    var isSimplified: Bool { self == .simplified }

    var title: String {
        switch self {
        case .simplified:  return "Simplified"
        case .comfortable: return "Relaxed"
        case .middleClass: return "Real Life"
        }
    }

    var icon: String {
        switch self {
        case .simplified:  return "🧸"
        case .comfortable: return "🛟"
        case .middleClass: return "⚖️"
        }
    }

    var blurb: String {
        switch self {
        case .simplified:
            return "Pick a degree, work your way up from junior to senior. Easy to follow — great for younger players."
        case .comfortable:
            return "High-income family. You keep a large share of every paycheck, the economy never falters, and doors open more easily at work and school."
        case .middleClass:
            return "A typical household budget and an ordinary, occasionally shaky economy."
        }
    }

    /// Short name of this setting's win condition, shown in the picker and header.
    var goalHeadline: String {
        switch self {
        case .simplified:             return "Make it to the top"
        case .comfortable, .middleClass: return "Earn your first million"
        }
    }

    var goalIcon: String {
        switch self {
        case .simplified:             return "👔"
        case .comfortable, .middleClass: return "💰"
        }
    }

    /// Share of gross income that actually becomes savings after taxes and
    /// living costs. Low-income households must spend a larger fraction just to
    /// get by, so far less is left to bank (and compound) each year. Unused in
    /// Simplified, which banks the whole paycheck.
    var savingsRate: Double {
        switch self {
        case .simplified:  return 1.0
        case .comfortable: return 0.12
        case .middleClass: return 0.05
        }
    }

    /// Annual chance that a fresh economic downturn begins. No economy in
    /// Simplified.
    var turmoilChance: Double {
        switch self {
        case .simplified:  return 0.0
        case .comfortable: return 0.0
        case .middleClass: return 0.10
        }
    }

    /// Additive boost to hiring and college-admission odds in realistic settings.
    /// "Relaxed" tilts opportunities in the player's favour; the others leave the
    /// underlying odds untouched.
    var opportunityBonus: Double {
        switch self {
        case .simplified:  return 0.0
        case .comfortable: return 0.15
        case .middleClass: return 0.0
        }
    }

    /// When a downturn begins, the chance it becomes *prolonged* — persisting
    /// for several more years (see `GameConstants.prolongedTurmoilExtraYears`)
    /// instead of clearing after the year it strikes.
    var prolongedTurmoilChance: Double {
        switch self {
        case .simplified:  return 0.0
        case .comfortable: return 0.15
        case .middleClass: return 0.30
        }
    }

    /// Multiplier applied to the baseline annual job-loss risk during a downturn.
    /// `GameConstants.baseLayoffRisk` is the *calm-economy* layoff chance; in a
    /// recession layoffs spike, and the harsher the economy the harder they hit.
    /// Capped by `GameConstants.turmoilMaxLayoffChance`.
    var layoffSeverity: Double {
        switch self {
        case .simplified:  return 0.0
        case .comfortable: return 2.0
        case .middleClass: return 3.5
        }
    }
}
