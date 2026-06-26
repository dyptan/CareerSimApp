import Foundation

/// Realistic-mode difficulty. Bundles the player's economic starting point —
/// how much of each paycheck is left to save after living costs (a low-income
/// family keeps far less than a high-income one) — with how turbulent the
/// economy is: how often downturns strike and how likely a downturn is to drag
/// on for years rather than clear after one. Has no effect in simplified mode.
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    /// High-income family, steady economy. A large share of income is saved and
    /// downturns are rare and usually brief.
    case comfortable
    /// Middle-income household, baseline volatility. The original realistic-mode
    /// balance.
    case middleClass
    /// Low-income family, turbulent economy. Living costs eat most of each
    /// paycheck, downturns hit often, and they frequently turn into multi-year
    /// recessions.
    case paycheckToPaycheck

    var id: String { rawValue }

    /// The default when a game starts before a difficulty is chosen.
    static let `default`: Difficulty = .middleClass

    var title: String {
        switch self {
        case .comfortable:        return "Comfortable"
        case .middleClass:        return "Middle Class"
        case .paycheckToPaycheck: return "Paycheck to Paycheck"
        }
    }

    var icon: String {
        switch self {
        case .comfortable:        return "🛟"
        case .middleClass:        return "⚖️"
        case .paycheckToPaycheck: return "🔥"
        }
    }

    var blurb: String {
        switch self {
        case .comfortable:
            return "High-income family. You keep a large share of every paycheck and the economy rarely falters."
        case .middleClass:
            return "A typical household budget and an ordinary, occasionally shaky economy."
        case .paycheckToPaycheck:
            return "Low-income family. Living costs swallow most of your pay, downturns hit often, and recessions drag on."
        }
    }

    /// Share of gross income that actually becomes savings after taxes and
    /// living costs. Low-income households must spend a larger fraction just to
    /// get by, so far less is left to bank (and compound) each year.
    var savingsRate: Double {
        switch self {
        case .comfortable:        return 0.12
        case .middleClass:        return 0.05
        case .paycheckToPaycheck: return 0.02
        }
    }

    /// Annual chance that a fresh economic downturn begins.
    var turmoilChance: Double {
        switch self {
        case .comfortable:        return 0.05
        case .middleClass:        return 0.10
        case .paycheckToPaycheck: return 0.18
        }
    }

    /// When a downturn begins, the chance it becomes *prolonged* — persisting
    /// for several more years (see `GameConstants.prolongedTurmoilExtraYears`)
    /// instead of clearing after the year it strikes.
    var prolongedTurmoilChance: Double {
        switch self {
        case .comfortable:        return 0.15
        case .middleClass:        return 0.30
        case .paycheckToPaycheck: return 0.50
        }
    }

    /// Multiplier applied to a job's baseline annual job-loss risk during a
    /// downturn. A company tier's `riskFactor` is the *calm-economy* layoff
    /// chance; in a recession layoffs spike, and the harsher the economy the
    /// harder they hit. Risky employers (startups, self-employment) are devastated
    /// on the toughest setting while genuinely stable posts (government) still
    /// mostly hold. Capped by `GameConstants.turmoilMaxLayoffChance`.
    var layoffSeverity: Double {
        switch self {
        case .comfortable:        return 2.0
        case .middleClass:        return 3.5
        case .paycheckToPaycheck: return 6.0
        }
    }
}
