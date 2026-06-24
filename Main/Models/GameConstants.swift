import CoreGraphics

enum GameConstants {
    static let maxSoftActivitiesPerYear: Int = 3
    static let trainingActivitySlotCost: Int = 1
    static let previewWindowWidth: CGFloat = 1000
    static let previewWindowHeight: CGFloat = 700

    /// Savings target that wins the game in realistic mode ("first million").
    static let millionGoal: Int = 1_000_000

    /// Realistic mode: the share of each year's income that actually becomes
    /// savings — the rest goes to taxes and living costs. Tracks the US personal
    /// saving rate (≈5% in the mid-2020s; the long-run average is closer to 8%).
    static let savingsRate: Double = 0.05

    /// Realistic mode: annual nominal return the accumulated balance compounds
    /// at (a balanced-portfolio, long-run figure). Compounding — not raw salary —
    /// is what realistically carries a diligent saver to the first million.
    static let investmentReturn: Double = 0.06

    /// Age at which a new game begins (childhood start). The player's age
    /// advances by one with each in-game year.
    static let startingAge: Int = 7

    /// Realistic mode: each in-game year has this chance of an economic downturn.
    static let turmoilChance: Double = 0.10

    /// During a downturn, job offers at company tiers whose annual job-loss risk
    /// is at or above this level are pulled from the market for that year
    /// (unstable employers freeze hiring). selfEmployed (0.18) and startup (0.22)
    /// clear this bar; small businesses and steadier tiers do not.
    static let turmoilUnstableTierRisk: Double = 0.15
}
