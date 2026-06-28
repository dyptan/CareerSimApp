import CoreGraphics

enum GameConstants {
    /// One spare-time slot per year, shared across hobbies, certifications, and
    /// licenses (they all draw from `selectedActivities`). The player commits to
    /// a single self-improvement each year, whatever their life stage — kept
    /// deliberately simple. (Side projects are free and no longer use this slot.)
    static let maxHobbiesPerYear: Int = 1
    static let trainingActivitySlotCost: Int = 1

    /// Realistic mode: how many professional events (summits, conferences,
    /// networking mixers) the player can attend in one year. Separate from the
    /// hobby/training slot — events cost money rather than the spare-time slot.
    static let maxEventsPerYear: Int = 1

    /// Realistic mode: how many side hustles the player can take on in one year.
    /// Spare time is limited, so monetizing talents competes for the same hours.
    static let maxSideHustlesPerYear: Int = 1

    /// Realistic mode: how many competitions (athletic or e-sports) the player
    /// can enter in one year. Each costs an entry fee and is a skill-based shot
    /// at prize money and a reputation-building achievement.
    static let maxCompetitionsPerYear: Int = 2
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

    /// Minimum age at which a player can take an unskilled job (one that
    /// requires no formal education). Reflects real-world child-labour rules
    /// that permit limited teenage work from around 14 onward. Jobs with any
    /// education requirement clear this gate implicitly via schooling time.
    static let minimumWorkingAge: Int = 14

    /// Realistic mode: when a downturn turns out to be *prolonged*, how many
    /// extra years (beyond the year it strikes) it drags on for. The exact
    /// length is rolled from this range. See `Difficulty.prolongedTurmoilChance`.
    static let prolongedTurmoilExtraYears: ClosedRange<Int> = 2...3

    /// Ceiling on the amplified job-loss probability during a downturn, so that
    /// even on the harshest difficulty no job is an outright guaranteed layoff.
    /// See `Difficulty.layoffSeverity`.
    static let turmoilMaxLayoffChance: Double = 0.85

    /// Admission odds at or below this count as a long shot: getting in anyway is
    /// celebrated with confetti. See `InstitutionTiersView`.
    static let luckyAdmissionThreshold: Double = 0.35

    /// Lowest education level (EQF) a role can require and still offer in-place
    /// promotions. Roles below this — unskilled work needing no post-secondary
    /// training (EQF 1–3: primary/middle/high school) — are never promoted, since
    /// raise-in-place promotions rarely happen in such jobs in real life; the
    /// player advances out of them by applying upward instead. EQF 4 = vocational.
    /// See `Job.isLowSkilled` / `Player.promotionChance`.
    static let promotionMinEQF: Int = 4

    /// Base annual probability that an employer promotes the player, before the
    /// player's promotion-readiness soft skills, tenure, and network scale it.
    /// Flat across all jobs now that company tiers are gone. See
    /// `Player.promotionChance`.
    static let promotionBaseChance: Double = 0.15

    /// Salary bump applied on a promotion, as a fraction of current pay. Flat
    /// across all jobs now that company tiers are gone. See `Player.advanceYear`.
    static let promotionRaise: ClosedRange<Double> = 0.06...0.18

    /// Calm-economy annual probability that a job is lost involuntarily. Used as
    /// the base layoff risk during a downturn (scaled by `Difficulty.layoffSeverity`).
    /// Flat across all jobs now that company tiers are gone. See
    /// `Player.applyEconomicTurmoil`.
    static let baseLayoffRisk: Double = 0.08
}
