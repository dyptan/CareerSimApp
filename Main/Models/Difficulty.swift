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

    /// "Simplified". Kid-friendly: getting hired needs only the right degree —
    /// the level *and* a field the role accepts, for every role — plus enough
    /// years in the field and being old enough; meet that and the offer is
    /// certain. No soft-skill hiring score, hard skills, company tiers,
    /// education tiers, salary negotiation, or economy simulation.
    /// Junior→senior still progresses through years of experience.
    case simplified
    /// "Relaxed". High-income family, no recessions, and opportunities tilted in
    /// the player's favour — a large share of income is saved, the economy never
    /// falters (layoffs are rare), and hiring and college admission come easier.
    case comfortable
    /// "Real Life". Middle-income household, baseline volatility: a recession
    /// every seven years or so, and a small yearly layoff risk that depends on
    /// the employer's sector.
    case middleClass

    var id: String { rawValue }

    /// The default when a game starts before a difficulty is chosen.
    static let `default`: Difficulty = .middleClass

    /// Who each setting is aimed at, shown as a chip in the picker so players
    /// (and parents) can self-select. The game is meant to be approachable for
    /// kids and challenging for adults — this makes that split explicit rather
    /// than leaving it to the blurb.
    var audience: String {
        switch self {
        case .simplified:  return "Ages 7+ · easiest"
        case .comfortable: return "Teens & up · forgiving"
        case .middleClass: return "Adults · full challenge"
        }
    }

    /// The setting suggested to a first-time player. Surfaced as a "Start here"
    /// badge in the picker; the simplified rules are the gentlest on-ramp.
    var isRecommendedForNewPlayers: Bool { self == .simplified }

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
            return "High-income family. Your family pays for college, you keep more of every paycheck, the economy never falters, layoffs are rare, and doors open more easily at work and school."
        case .middleClass:
            return "A typical household budget and an ordinary, occasionally shaky economy — a recession every several years, and layoffs that hit some industries harder than others."
        }
    }

    /// Short name of this setting's goal, shown in the picker and header. The
    /// realistic settings set no target to hit — just a score to grow across a
    /// career that runs until `GameConstants.retirementAge` (or until the player
    /// finishes early).
    var goalHeadline: String {
        switch self {
        case .simplified:                return "Make it to the top"
        case .comfortable, .middleClass: return "Best score by \(GameConstants.retirementAge)"
        }
    }

    var goalIcon: String {
        switch self {
        case .simplified:                return "👔"
        case .comfortable, .middleClass: return "🏅"
        }
    }

    /// Share of gross income *above the living-cost floor* (`livingCostFloor`)
    /// that becomes savings once taxes are paid — up to
    /// `GameConstants.highEarnerThreshold`, above which the higher
    /// `highEarnerSavingsRate` applies (see `Player.annualSaving`). A low
    /// earner spends nearly everything just to get by; a professional banks a
    /// real share. Effective rates come out near Vanguard's plan-participant
    /// averages: ~4 % of gross at $45k, ~10 % at $100k, ~19 % at $400k.
    /// Unused in Simplified, which banks the whole paycheck.
    var savingsRate: Double {
        switch self {
        case .simplified:  return 1.0
        case .comfortable: return 0.16
        case .middleClass: return 0.15
        }
    }

    /// A year's basic living costs (rent, food, transport) — nothing is saved
    /// below it. Relaxed's well-off family covers some of the basics (a car, a
    /// room at home), so its floor is lower. None in Simplified.
    var livingCostFloor: Int {
        switch self {
        case .simplified:  return 0
        case .comfortable: return 30_000
        case .middleClass: return 32_000
        }
    }

    /// Share of tuition the student's family pays. Real Life: a typical
    /// middle-income parent contribution, which leaves a state bachelor's
    /// graduate near the College Board's ~$29k average debt. Relaxed: a
    /// high-income family pays it all.
    var familyTuitionShare: Double {
        switch self {
        case .simplified:  return 1.0
        case .comfortable: return 1.0
        case .middleClass: return 0.40
        }
    }

    /// Annual chance that a fresh economic downturn begins in a calm year. No
    /// economy in Simplified, and none in Relaxed. Real Life: with the chance a
    /// downturn drags on (`prolongedTurmoilChance`) this puts ~15% of years in
    /// recession and a new one every 7–9 years — the NBER post-war record
    /// (expansions ~64 months, contractions ~10).
    var turmoilChance: Double {
        switch self {
        case .simplified:  return 0.0
        case .comfortable: return 0.0
        case .middleClass: return 0.14
        }
    }

    /// Additive boost to college-admission odds in realistic settings. "Relaxed"
    /// tilts opportunities in the player's favour; the others leave the
    /// underlying odds untouched. Hiring uses `opportunityHireMultiplier`
    /// instead.
    var opportunityBonus: Double {
        switch self {
        case .simplified:  return 0.0
        case .comfortable: return 0.15
        case .middleClass: return 0.0
        }
    }

    /// Multiplier on every job application's odds (before the floor and
    /// ceiling; see `Job.hireBreakdown`). "Relaxed" makes hiring ~25% easier for
    /// everyone. A multiplier rather than an added bonus, so it can't turn an
    /// unqualified long shot into a near coin-flip — an additive lift helps a
    /// weak profile far more, in relative terms, than a strong one.
    var opportunityHireMultiplier: Double {
        switch self {
        case .simplified:  return 1.0
        case .comfortable: return 1.25
        case .middleClass: return 1.0
        }
    }

    /// When a downturn begins, the chance it becomes *prolonged* — persisting
    /// for another year or two (see `GameConstants.prolongedTurmoilExtraYears`)
    /// instead of clearing after the year it strikes. Most US recessions are
    /// over within a year.
    var prolongedTurmoilChance: Double {
        switch self {
        case .simplified:  return 0.0
        case .comfortable: return 0.15
        case .middleClass: return 0.15
        }
    }

    /// Multiplier on every employee's yearly layoff risk (see
    /// `Player.layoffRisk(for:)`), which is rolled every year, not only in a
    /// recession: `GameConstants.baseLayoffRisk` × the sector's beta × its
    /// climate × this, capped by `GameConstants.turmoilMaxLayoffChance`. Real
    /// Life carries the plain risk (~2% a year in an average sector); Relaxed
    /// half of it; Simplified none.
    var layoffSeverity: Double {
        switch self {
        case .simplified:  return 0.0
        case .comfortable: return 0.5
        case .middleClass: return 1.0
        }
    }
}
