import CoreGraphics

enum GameConstants {
    static let maxSoftActivitiesPerYear: Int = 3
    static let trainingActivitySlotCost: Int = 1

    /// Realistic mode: how many side hustles the player can take on in one year.
    /// Spare time is limited, so monetizing talents competes for the same hours.
    static let maxSideHustlesPerYear: Int = 2
    static let previewWindowWidth: CGFloat = 1000
    static let previewWindowHeight: CGFloat = 700

    /// Savings target that wins the game in realistic mode ("first million").
    static let millionGoal: Int = 1_000_000

    /// Realistic mode: annual nominal return the accumulated balance compounds
    /// at (a balanced-portfolio, long-run figure). Compounding — not raw salary —
    /// is what realistically carries a diligent saver to the first million.
    static let investmentReturn: Double = 0.06

    /// Age at which a new game begins (childhood start). The player's age
    /// advances by one with each in-game year.
    static let startingAge: Int = 7

    /// Realistic mode: when a downturn turns out to be *prolonged*, how many
    /// extra years (beyond the year it strikes) it drags on for. The exact
    /// length is rolled from this range. See `Difficulty.prolongedTurmoilChance`.
    static let prolongedTurmoilExtraYears: ClosedRange<Int> = 2...4

    /// During a downturn, job offers at company tiers whose annual job-loss risk
    /// is at or above this level are pulled from the market for that year
    /// (unstable employers freeze hiring). selfEmployed (0.18) and startup (0.22)
    /// clear this bar; small businesses and steadier tiers do not.
    static let turmoilUnstableTierRisk: Double = 0.15

    /// Ceiling on the amplified job-loss probability during a downturn, so that
    /// even on the harshest difficulty no job is an outright guaranteed layoff.
    /// See `Difficulty.layoffSeverity`.
    static let turmoilMaxLayoffChance: Double = 0.85

    /// Admission odds at or below this count as a long shot: getting in anyway is
    /// celebrated with confetti. See `InstitutionTiersView`.
    static let luckyAdmissionThreshold: Double = 0.35
}
