import CoreGraphics

enum GameConstants {
    /// One spare-time slot per year, shared across hobbies, certifications, and
    /// licenses (they all draw from `selectedActivities`). The player commits to
    /// a single self-improvement each year, whatever their life stage — kept
    /// deliberately simple. (Side projects are free and no longer use this slot.)
    static let maxHobbiesPerYear: Int = 1
    static let trainingActivitySlotCost: Int = 1

    /// Realistic mode: how many professional events (summits, conferences,
    /// networking mixers) the player can attend in one year. Free to attend;
    /// separate from the hobby/training spare-time slot.
    static let maxEventsPerYear: Int = 1

    /// Years of same-industry work experience required to attend an event as a
    /// **presenter** rather than a participant. You speak once you're an
    /// established name in the field. See `CareerEvent.canPresent(with:)`.
    static let presenterExperienceYears: Int = 5

    /// Extra professional-network points a presenter banks over a participant
    /// at the same event — being on stage puts more of the room in your orbit.
    /// See `CareerEvent.networkPoints(for:)`.
    static let presenterNetworkBonus: Int = 2

    /// Realistic mode: how many spare-time ventures (money hustles + fame
    /// projects, now one system) the player can take on in one year. Spare time
    /// is limited, so every venture competes for the same hours.
    static let maxSideHustlesPerYear: Int = 1

    static let previewWindowWidth: CGFloat = 1000
    static let previewWindowHeight: CGFloat = 700

    /// Realistic mode: annual nominal return the accumulated balance compounds
    /// at (a balanced-portfolio, long-run figure). Compounding — not raw salary —
    /// is what steadily grows a diligent saver's score over a career.
    static let investmentReturn: Double = 0.06

    /// Age at which a new game begins (childhood start). The player's age
    /// advances by one with each in-game year.
    static let startingAge: Int = 7

    /// Minimum age at which a player can take an unskilled job (one that
    /// requires no formal education). Reflects real-world child-labour rules
    /// that permit limited teenage work from around 14 onward. Jobs with any
    /// education requirement clear this gate implicitly via schooling time.
    static let minimumWorkingAge: Int = 14

    /// Age at which higher (tertiary) education — vocational training and
    /// university — becomes relevant. Until then the player is progressing
    /// through primary/middle/high school automatically (see `RootView`), so the
    /// Education menu stays hidden. Matches the age high school wraps up.
    static let minimumTertiaryAge: Int = 18

    /// Realistic mode: when a downturn turns out to be *prolonged*, how many
    /// extra years (beyond the year it strikes) it drags on for. The exact
    /// length is rolled from this range. See `Difficulty.prolongedTurmoilChance`.
    static let prolongedTurmoilExtraYears: ClosedRange<Int> = 2...3

    /// Ceiling on the amplified job-loss probability during a downturn, so that
    /// even on the harshest difficulty no job is an outright guaranteed layoff.
    /// See `Difficulty.layoffSeverity`.
    static let turmoilMaxLayoffChance: Double = 0.85

    /// A gain whose success probability was below this counts as a genuine long
    /// shot — the only kind of win the confetti celebrates. Applied uniformly to
    /// every stochastic payoff: admissions, promotions, competition wins, fame
    /// projects, and investment rounds. Likely or guaranteed gains (e.g. simply
    /// graduating) fire no confetti.
    static let luckyWinThreshold: Double = 0.20

    /// Multiplier applied to the fame a shipped **project** banks (see `SideHustle`
    /// fame plays). Like taking the stage at an event, a completed project is a
    /// significant, industry-scoped fame driver — worth well more than its raw
    /// catalogue weight — feeding the hiring fame bonus (`Player.fameHireBonus`).
    static let projectFameMultiplier: Double = 2.0

    /// How much a founder can borrow to top up a venture stake once their savings
    /// are spent, as a multiple of their current annual income — a bank lends
    /// against what you earn. Zero income means no borrowing headroom.
    static let ventureLoanIncomeMultiple: Double = 2.0

    /// Annual interest charged on an outstanding venture loan. Applied each year
    /// before that year's repayment, so carrying debt has a real cost — and if the
    /// venture flops, the loan (and its interest) still has to be paid back.
    static let ventureLoanAnnualInterest: Double = 0.10

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
