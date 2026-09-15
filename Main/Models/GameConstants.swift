import CoreGraphics

enum GameConstants {
    // One activity per year needs no constant: taking anything — a hobby, a
    // sport, a course, an event, a project — spends the year on the spot, so
    // the "one slot" rule is enforced by the flow itself.

    /// Years of same-industry work experience required to take the stage at one
    /// of its events. You speak once you're an established name in the field.
    /// See `CareerEvent.canPresent(with:)`.
    static let presenterExperienceYears: Int = 5

    /// Extra professional-network points taking the stage banks over the event's
    /// raw weight — being on stage puts more of the room in your orbit.
    /// See `CareerEvent.networkPoints`.
    static let presenterNetworkBonus: Int = 2

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

    /// Minimum age at which the entrepreneurial surface (founder ventures) opens
    /// up. Staking capital on a business is an adult play, so — like the
    /// Boardroom, which gates on holding an executive seat — Ventures stays
    /// hidden from children even in realistic mode, keeping the young-player
    /// footer uncluttered. Matches the age formal adulthood begins.
    static let minimumEntrepreneurAge: Int = 18

    /// Realistic mode: when a downturn turns out to be *prolonged*, how many
    /// extra years (beyond the year it strikes) it drags on for. The exact
    /// length is rolled from this range. See `Difficulty.prolongedTurmoilChance`.
    static let prolongedTurmoilExtraYears: ClosedRange<Int> = 2...3

    /// Ceiling on the amplified job-loss probability during a downturn, so that
    /// even on the harshest difficulty no job is an outright guaranteed layoff.
    /// See `Difficulty.layoffSeverity`.
    static let turmoilMaxLayoffChance: Double = 0.85

    /// A gain whose success probability was below this counts as a win worth
    /// celebrating — the only kind the confetti fires for. Applied uniformly to
    /// every stochastic payoff: admissions, promotions, competition wins, fame
    /// projects, and investment rounds. Likely or guaranteed gains (e.g. simply
    /// graduating) fire no confetti.
    static let luckyWinThreshold: Double = 0.50

    /// Multiplier applied to the fame an **accomplishment** banks — a shipped
    /// project (see `SideHustle` fame plays) or taking the stage at an event
    /// (see `CareerEvent.presenterFameWeight`). Both are significant,
    /// industry-scoped fame drivers, worth well more than their raw catalogue
    /// weight, and feed the hiring fame bonus (`Player.fameHireBonus`).
    static let accomplishmentFameMultiplier: Double = 2.0

    /// How much a founder can borrow to top up a venture stake once their savings
    /// are spent, as a multiple of their current annual income — a bank lends
    /// against what you earn. Zero income means no borrowing headroom.
    static let ventureLoanIncomeMultiple: Double = 2.0

    /// Annual interest charged on an outstanding venture loan. Applied each year
    /// before that year's repayment, so carrying debt has a real cost — and if the
    /// venture flops, the loan (and its interest) still has to be paid back.
    static let ventureLoanAnnualInterest: Double = 0.10

    /// Annual interest on an outstanding student loan (tuition borrowed beyond the
    /// player's savings). Gentler than a venture loan — student debt is cheaper —
    /// but it still compounds each year until earnings clear it, so an expensive
    /// early degree is a lasting cost. See `Player.advanceYear`.
    static let studentLoanAnnualInterest: Double = 0.05

    /// The most likely a founding attempt can ever be, however experienced,
    /// skilled, funded, and credentialed the founder. Founding a business is a
    /// genuine gamble — even the best-prepared founder is closer to a coin-flip
    /// than a sure thing — so the launch odds top out here rather than near
    /// certainty. See `Job.founderSuccessProbability`.
    static let founderMaxSuccess: Double = 0.55

    /// Base annual chance that a running venture fails outright in a calm economy.
    /// Unlike a salaried worker (who faces layoffs only in a downturn), a founder
    /// carries this risk *every* year — a business can always fold. A recession
    /// multiplies it by `Difficulty.layoffSeverity`, capped at
    /// `ventureMaxFailureRisk`. See `Player.advanceYear`.
    static let ventureAnnualFailureRisk: Double = 0.07

    /// Ceiling on the amplified annual venture-failure probability, so even a
    /// harsh downturn never makes a fold a certainty.
    static let ventureMaxFailureRisk: Double = 0.25

    /// C-suite scarcity: there are only a handful of executive seats, so landing
    /// one is competitive even for a qualified insider. Applied as a multiplier to
    /// the odds of being *hired into* or *promoted into* an executive (non-founder)
    /// role — CEO, CTO, CMO, director, partner — so reaching the top of a business
    /// track is rare rather than a foregone conclusion. Founders are unaffected
    /// (they make their own seat). See `Job.hireProbability` / `Player.advanceYear`.
    static let executiveSeatChance: Double = 0.30

    /// Lowest education level (EQF) a role can require and still offer in-place
    /// promotions. Roles below this — unskilled work needing no post-secondary
    /// training (EQF 1–3: primary/middle/high school) — are never promoted, since
    /// raise-in-place promotions rarely happen in such jobs in real life; the
    /// player advances out of them by applying upward instead. EQF 4 = vocational.
    /// See `Job.isLowSkilled` / `Player.promotionChance`.
    static let promotionMinEQF: Int = 4

    /// The education expectation at which a role's pay becomes negotiable rather
    /// than a posted rate (EQF 4 = vocational/college). Set here rather than at
    /// bachelor's so the trained creative professions — a designer, an animator,
    /// an editor — argue over a fee the way they do in life; below it a role
    /// takes the band it is offered. See `Job.salaryIsNegotiable`.
    static let negotiableSalaryMinEQF: Int = 4

    /// Base annual probability that an employer promotes the player, before the
    /// player's promotion-readiness soft skills, tenure, and network scale it.
    /// Flat across all jobs. See
    /// `Player.promotionChance`.
    static let promotionBaseChance: Double = 0.15

    // MARK: - Education's pull on the odds
    //
    // Outside the regulated professions a degree is deliberately not a hard gate
    // — talent, portfolio and experience can stand in for it (see
    // `JobCategory.educationIsMandatory`). It is, however, the single biggest
    // thing an employer screens on after skills, so it carries real weight in
    // the score rather than being a rounding error.

    /// Hire-odds *multiplier* lost per EQF level the applicant falls short of
    /// what the role expects. Two levels short (high school for a bachelor's
    /// role) multiplies the odds by 0.70.
    static let educationShortfallPerLevel: Double = 0.15

    /// Floor on that multiplier, so no schooling at all for a degree-level role
    /// is a long shot rather than an impossibility — an exceptional candidate
    /// can still talk their way in.
    static let educationShortfallFloor: Double = 0.25

    /// Multiplier for holding the expected level in a field the role accepts.
    /// The right degree, not merely a degree.
    static let relevantDegreeMultiplier: Double = 1.10

    /// Multiplier for clearing the level in an unrelated field — the
    /// qualification counts for something, just not for much.
    static let unrelatedDegreeMultiplier: Double = 1.03

    /// Most a seasoned applicant's surplus experience can multiply the odds by.
    static let experienceVeteranMultiplier: Double = 1.10

    /// How fast surplus experience earns that lift, per whole extra multiple of
    /// the expected years.
    static let experienceVeteranRate: Double = 0.10

    /// Promotion-odds cost per EQF level short of the role's expected education.
    /// Smaller than the hiring penalty in absolute terms, but the promotion base
    /// is far smaller too — being under-credentialled caps your ceiling.
    static let promotionEducationPerLevel: Double = -0.03

    /// Floor on the promotion education penalty.
    static let promotionEducationFloor: Double = -0.10

    /// Promotion-odds lift for holding an accepted degree at or above the bar.
    static let promotionRelevantDegreeBonus: Double = 0.03

    /// Salary bump applied on a promotion, as a fraction of current pay. Flat
    /// across all jobs. See `Player.advanceYear`.
    static let promotionRaise: ClosedRange<Double> = 0.06...0.18

    /// Calm-economy annual probability that a job is lost involuntarily. Used as
    /// the base layoff risk during a downturn (scaled by `Difficulty.layoffSeverity`).
    /// Flat across all jobs. See
    /// `Player.applyEconomicTurmoil`.
    static let baseLayoffRisk: Double = 0.08
}
