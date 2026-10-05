import Foundation

/// The single difficulty choice made once at launch. Two settings: "Simplified",
/// a tutorial that strips skills, tiers, negotiation, and the economy entirely,
/// and "Real Life", the full simulation — a middle-income household, and an
/// economy whose downturns strike now and then and sometimes drag on.
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    // NOTE: the raw case names are persisted (Codable) and referenced across the
    // app, so they stay fixed. Only the player-facing `title`/`blurb` track the
    // displayed names (Simplified / Real Life).

    /// "Simplified". A kid-friendly tutorial: getting hired needs only the right
    /// degree — the level *and* a field the role accepts, for every role — plus
    /// enough years in the field and being old enough; meet that and the offer
    /// is certain. No soft-skill hiring score, hard skills, company tiers,
    /// education tiers, salary negotiation, or economy simulation.
    /// Junior→senior still progresses through years of experience. It ends at a
    /// goal, not a score, so it keeps no score and never reaches the leaderboard
    /// (see `keepsScore`).
    case simplified
    /// "Real Life". Middle-income household, baseline volatility: a recession
    /// every seven years or so, and a small yearly layoff risk that depends on
    /// the employer's sector.
    case middleClass

    var id: String { rawValue }

    /// The default when a game starts before a difficulty is chosen.
    static let `default`: Difficulty = .middleClass

    /// Who each setting is aimed at.
    var audience: String {
        switch self {
        case .simplified:
            return String(localized: "Ages 7+ · easiest",
                          comment: "Audience chip on the Simplified game-mode card: the youngest players, the gentlest mode.")
        case .middleClass:
            return String(localized: "Teens & up · full challenge",
                          comment: "Audience chip on the Real Life game-mode card: older players, the full simulation.")
        }
    }

    /// The setting suggested to a first-time player. Surfaced as a "Start here"
    /// badge in the picker; the Simplified rules are the gentlest on-ramp.
    var isRecommendedForNewPlayers: Bool { self == .simplified }

    /// True when only the basic (degree + experience) rules apply — no skills,
    /// tiers, negotiation, or economy simulation.
    var isSimplified: Bool { self == .simplified }

    /// Whether the run is scored — net worth ÷ age, shown on the score sheet
    /// and submitted to Game Center (`Player.leaderboardScore`). Simplified is
    /// the tutorial: it banks the whole paycheck and has no living costs or
    /// tuition, so its numbers aren't comparable with a Real Life run's and
    /// must never share a leaderboard with them.
    var keepsScore: Bool { self == .middleClass }

    var title: String {
        switch self {
        case .simplified:
            return String(localized: "Simplified",
                          comment: "Name of the easy, tutorial-style game mode (no skills, tiers or economy).")
        case .middleClass:
            return String(localized: "Real Life",
                          comment: "Name of the full-simulation game mode (skills, hiring odds, money, a shifting economy).")
        }
    }

    var icon: String {
        switch self {
        case .simplified:  return "🧸"
        case .middleClass: return "⚖️"
        }
    }

    /// One short line for the picker card; the rest is in `details`.
    var blurb: String {
        switch self {
        case .simplified:  return L("Pick a degree and climb from junior to senior.")
        case .middleClass: return L("Skills, odds, money and a shifting economy.")
        }
    }

    /// Everything the picker card leaves out — who it's for, the goal and the
    /// assumptions behind the numbers — for the card's ⓘ.
    func details(in country: Country) -> String {
        switch self {
        case .simplified:
            return [
                L("Ages 7+ · easiest. The gentlest way in — a good first game."),
                "",
                L("🎯 Goal: \(goalHeadline) — reach a top leadership job."),
                "",
                L("• Getting hired only takes the right degree, enough years of work and being old enough. Meet those and the job is yours."),
                L("• No hiring odds, salary talks, school tiers or economy."),
                L("• You keep all your pay. There's no rent, tuition or loans."),
                L("• There's no score and no leaderboard."),
            ].joined(separator: "\n")
        case .middleClass:
            return [
                L("Teens & up · full challenge."),
                "",
                L("🎯 Goal: \(goalHeadline) — your net worth divided by your age when the career ends at \(GameConstants.retirementAge)."),
                "",
                L("• Hiring is a roll: skills, fame, network, school prestige and the job market all count."),
                L("• 💵 A typical household: the first \(country.money(livingCostFloor(in: country))) of pay goes on living costs, and you save \(Fmt.percent(savingsRate)) of the rest. Your family pays \(Fmt.percent(familyTuitionShare)) of tuition; you borrow the rest."),
                L("• 📉 About a \(Fmt.percent(turmoilChance)) chance each calm year that a recession starts, and layoffs that hit some industries harder than others."),
                L("• Scores go to the Game Center leaderboard."),
            ].joined(separator: "\n")
        }
    }

    /// Short name of this setting's goal, shown in the picker and header. Real
    /// Life sets no target to hit — just a score to grow across a career that
    /// runs until `GameConstants.retirementAge` (or until the player finishes
    /// early).
    var goalHeadline: String {
        switch self {
        case .simplified:
            return String(localized: "Make it to the top",
                          comment: "Short name of the Simplified mode's goal, shown in the picker and the header.")
        case .middleClass:
            return String(localized: "Best score by \(GameConstants.retirementAge)",
                          comment: "Short name of the Real Life mode's goal, shown in the picker and the header. The number is the retirement age.")
        }
    }

    var goalIcon: String {
        switch self {
        case .simplified:  return "👔"
        case .middleClass: return "🏅"
        }
    }

    /// Share of gross income *above the living-cost floor* (`livingCostFloor`)
    /// that becomes savings once taxes are paid — up to
    /// `Country.highEarnerThreshold`, above which the higher
    /// `highEarnerSavingsRate` applies (see `Player.annualSaving`). A low
    /// earner spends nearly everything just to get by; a professional banks a
    /// real share. Effective rates come out near Vanguard's plan-participant
    /// averages: ~4 % of gross at $45k, ~10 % at $100k, ~19 % at $400k.
    /// Unused in Simplified, which banks the whole paycheck.
    var savingsRate: Double {
        switch self {
        case .simplified:  return 1.0
        case .middleClass: return 0.15
        }
    }

    /// A year's basic living costs (rent, food, transport) — nothing is saved
    /// below it. None in Simplified; in Real Life, the country's
    /// (`Country.livingCostFloor`).
    func livingCostFloor(in country: Country) -> Int {
        isSimplified ? 0 : country.livingCostFloor
    }

    /// Share of tuition the student's family pays. Real Life: a typical
    /// middle-income parent contribution, which leaves a state bachelor's
    /// graduate near the College Board's ~$29k average debt. Simplified has no
    /// tuition to pay.
    var familyTuitionShare: Double {
        switch self {
        case .simplified:  return 1.0
        case .middleClass: return 0.40
        }
    }

    /// Annual chance that a fresh economic downturn begins in a calm year. No
    /// economy in Simplified. Real Life: with the chance a
    /// downturn drags on (`prolongedTurmoilChance`) this puts ~15% of years in
    /// recession and a new one every 7–9 years — the NBER post-war record
    /// (expansions ~64 months, contractions ~10).
    var turmoilChance: Double {
        switch self {
        case .simplified:  return 0.0
        case .middleClass: return 0.14
        }
    }

    /// When a downturn begins, the chance it becomes *prolonged* — persisting
    /// for another year or two (see `GameConstants.prolongedTurmoilExtraYears`)
    /// instead of clearing after the year it strikes. Most US recessions are
    /// over within a year.
    var prolongedTurmoilChance: Double {
        switch self {
        case .simplified:  return 0.0
        case .middleClass: return 0.15
        }
    }

    /// Multiplier on every employee's yearly layoff risk (see
    /// `Player.layoffRisk(for:)`), which is rolled every year, not only in a
    /// recession: `GameConstants.baseLayoffRisk` × the sector's beta × its
    /// climate × this, capped by `GameConstants.turmoilMaxLayoffChance`. Real
    /// Life carries the plain risk (~2% a year in an average sector);
    /// Simplified none.
    var layoffSeverity: Double {
        switch self {
        case .simplified:  return 0.0
        case .middleClass: return 1.0
        }
    }
}
