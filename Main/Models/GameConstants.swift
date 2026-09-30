import CoreGraphics

enum GameConstants {
    // One activity per year needs no constant: taking anything — a hobby, a
    // sport, a course, an event, a project — spends the year on the spot, so
    // the "one slot" rule is enforced by the flow itself.

    /// Years in an event's field at which experience counts in full toward
    /// being accepted to take its stage — a veteran is nearly always accepted,
    /// a newcomer is a long shot. See `Player.presentOdds`.
    static let presenterExperienceYears: Int = 5

    /// Extra professional-network points taking the stage banks over the event's
    /// raw weight — being on stage puts more of the room in your orbit.
    /// See `CareerEvent.networkPoints`.
    static let presenterNetworkBonus: Int = 2

    static let previewWindowWidth: CGFloat = 1000
    static let previewWindowHeight: CGFloat = 700

    /// Realistic mode: annual REAL (after-inflation) return the accumulated
    /// balance compounds at in an ordinary year. Salaries are fixed 2026 dollars,
    /// so the return has to be real too: a balanced portfolio has returned about
    /// 5 % real since 1926 and planners assume 4–5 % (CFA Institute RPC 2025).
    /// With `downturnStartReturn` the long-run average lands near 4 %.
    static let investmentReturn: Double = 0.045

    /// Real Life: the return in the first year of a new downturn — markets fall
    /// before the layoffs arrive (a 60/40 portfolio lost ~15–22 % real in 2008
    /// and 2022). Outside a downturn it earns `investmentReturn` flat.
    static let downturnStartReturn: Double = -0.12

    /// Pay above this is saved at `highEarnerSavingsRate` instead of the mode's
    /// `savingsRate`: saving rates climb steeply with income (Dynan, Skinner &
    /// Zeldes 2004), and a household at $400k banks far more than a flat share.
    static let highEarnerThreshold: Int = 250_000
    static let highEarnerSavingsRate: Double = 0.30

    /// Share of the living-cost floor an adult out of work draws from savings
    /// in a year with no income — rent and food don't stop with the paycheck,
    /// net of unemployment insurance and cutbacks (UI replaces under 40 % of
    /// wages for at most 26 weeks; spending falls ~7 % on job loss).
    static let unemployedDrawShare: Double = 0.30

    /// Age at which a new game begins (childhood start). The player's age
    /// advances by one with each in-game year.
    static let startingAge: Int = 7

    /// A player who starts later than `startingAge` didn't play the years
    /// before it: no yearly choices, no purposeful practice. Each skipped year
    /// still leaves a trace, but an unfocused one — this many soft-skill points
    /// in a skill picked at random (`Player.seedSkippedYears`) — where a year of
    /// chosen activity builds several points in the skills a goal needs (see
    /// `Sport.abilities`). That gap is the point: an ambitious path, an elite
    /// school say, is built from early choices, and a late start can't buy them back.
    static let skippedYearSkillPoints: Int = 1

    /// From this age the skipped years are adult ones, and they are worth less:
    /// past school, professional activity — experience, projects, a network —
    /// counts for more than the soft skills a year adds, and those have their own
    /// yearly choices. Each such year is only `skippedAdultYearFalloff` as likely
    /// to leave a boost as the one before it (the first is half as likely as a school year).
    static let skippedYearsFullValueBelowAge: Int = 18
    static let skippedAdultYearFalloff: Double = 0.5

    /// Minimum age at which a player can take any job at all — the age the Jobs
    /// sheet opens. FLSA child-labour rules (DOL Fact Sheet #43) let 14–15-year-
    /// olds work limited hours in non-hazardous retail and food-service jobs, so
    /// only those roles hire this young (see `Job.minimumHireAge`).
    static let minimumWorkingAge: Int = 14

    /// Minimum age for every other non-hazardous job: at 16 the FLSA lifts the
    /// hours and occupation limits outside the hazardous orders.
    static let minimumNonHazardousAge: Int = 16

    /// Minimum age for the FLSA's 17 Hazardous Occupations Orders (driving,
    /// roofing, power-driven machinery, excavation — construction,
    /// manufacturing and transportation work here) and for any role expecting a
    /// post-secondary qualification (EQF 4+), which nobody holds before 18.
    static let adultRoleAge: Int = 18

    /// Minimum age for a top leadership seat (`Job.isTopLeadership`). Even a
    /// store manager is a first-line supervisor with several years behind them
    /// (BLS), so no one runs a shop floor, a ward or a company before 21.
    static let minimumLeadershipAge: Int = 21

    /// Age at which higher (tertiary) education — vocational training and
    /// university — becomes relevant. Until then the player is progressing
    /// through primary/middle/high school automatically (see `RootView`), so the
    /// Education menu stays hidden. Matches the age high school wraps up.
    static let minimumTertiaryAge: Int = 18

    // MARK: - School grades

    /// A high-school year's grade (US 4.0 scale) with no academic skill and no
    /// studying — the bottom of the band. See `Player.yearGrade(studied:)`.
    static let gradeFloor: Double = 2.0
    /// What fully developed academic skills (analysis, care, discipline,
    /// planning) add on top of `gradeFloor` without any extra study.
    static let gradeSkillSpan: Double = 1.4
    /// What spending the year on a Study activity adds. Skills alone top out at
    /// 3.4 (a B+); only studying reaches a straight-A 4.0.
    static let studyGradeBonus: Double = 0.6
    /// Academic-skill level a high-schooler needs to score an axis in full.
    static let gradeSkillReference: Int = 6

    /// Fame points (the summed `fameWeight` of every trophy and accolade) at
    /// which an application's accolades count in full — roughly a national
    /// title plus a handful of local wins. See `Player.accoladeFit`.
    static let accoladeReference: Double = 3.0

    /// Minimum age at which the entrepreneurial surface (founder ventures) opens
    /// up. Staking capital on a business is an adult play, so — like the
    /// Boardroom, which gates on holding an executive seat — Ventures stays
    /// hidden from children even in realistic mode, keeping the young-player
    /// footer uncluttered. Matches the age formal adulthood begins.
    static let minimumEntrepreneurAge: Int = 18

    /// Realistic mode: when a downturn turns out to be *prolonged*, how many
    /// extra years (beyond the year it strikes) it drags on for. The exact
    /// length is rolled from this range. See `Difficulty.prolongedTurmoilChance`.
    /// NBER: the longest post-war contraction ran 18 months, so a prolonged
    /// recession lasts two or three game years in all, not four.
    static let prolongedTurmoilExtraYears: ClosedRange<Int> = 1...2

    /// Ceiling on a year's layoff risk (see `Player.layoffRisk(for:)`), so even
    /// a construction job in a slumping recession is a real risk rather than a
    /// likely loss: JOLTS layoffs in the worst-hit sector run ~2% a month in bad
    /// years, well under 15% a year.
    static let turmoilMaxLayoffChance: Double = 0.15

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

    // MARK: - Fame pays
    //
    // Projects pay no money — they build fame and skills. A famous
    // entertainment name, though, is paid by brands to carry their products.

    /// Entertainment fame at which brands start paying for endorsements, and
    /// what they pay: this base × fame^exponent a year.
    static let endorsementFameThreshold: Double = 5
    static let endorsementBase: Double = 1_500
    static let endorsementFameExponent: Double = 1.6
    static let endorsementMax: Int = 5_000_000

    /// How much a founder can borrow to top up a venture stake once their savings
    /// are spent, as a multiple of their current annual income — a bank lends
    /// against what you earn. Zero income means no borrowing headroom.
    static let ventureLoanIncomeMultiple: Double = 2.0

    /// Annual interest charged on an outstanding venture loan. Applied each year
    /// before that year's repayment, so carrying debt has a real cost — and if the
    /// venture flops, the loan (and its interest) still has to be paid back.
    static let ventureLoanAnnualInterest: Double = 0.075  // real: SBA 7(a) ~10–12 % nominal less ~3 % inflation

    /// Annual interest on an outstanding student loan (tuition borrowed beyond the
    /// player's savings). Gentler than a venture loan — student debt is cheaper —
    /// but it still compounds each year until earnings clear it, so an expensive
    /// early degree is a lasting cost. See `Player.advanceYear`.
    static let studentLoanAnnualInterest: Double = 0.04  // real: federal Direct Loan 6.5 % nominal less ~2.5 % inflation

    /// Years over which a loan is repaid in fixed annual instalments — the
    /// standard term for both a small-business (SBA 7(a)) loan and a US
    /// student loan. See `Player.annualLoanPayment`.
    static let loanTermYears: Int = 10

    /// The most of a year's gross income that can go to loan instalments by
    /// spending less — roughly the debt-to-income ceiling lenders allow.
    static let maxDebtServiceShare: Double = 0.4

    /// Share of each instalment that comes out of what the year would have
    /// saved; the rest is met by spending less (up to `maxDebtServiceShare` of
    /// gross), and savings cover anything left. Paying debt from savings only
    /// would leave low earners unable to clear any loan; paying it only by
    /// cutting consumption would make borrowing almost free.
    static let debtServiceFromSavingsShare: Double = 0.5

    /// The top of the founder-preparation score (`Job.founderSuccessProbability`),
    /// which no amount of experience, skill, capital or credentials exceeds.
    /// Preparation no longer decides whether a business opens — it always does —
    /// but how well it survives (see `Player.ventureFoldRisk`).
    static let founderMaxSuccess: Double = 0.55

    /// Chance an average-prepared business folds in its 1st, 2nd, 3rd and 4th-
    /// and-later year in a calm economy. Modelled on US business survival data:
    /// about a fifth close in year one and about half by year five, the risk
    /// falling as a business establishes itself. Preparation scales it between
    /// 0.5× and 1.5×, and a recession by `ventureRecessionFoldMultiplier`.
    static let ventureFoldRiskByYear: [Double] = [0.22, 0.14, 0.10, 0.06]

    /// Ceiling on the amplified annual fold risk, so even a harsh downturn
    /// never makes a fold a certainty.
    static let ventureMaxFailureRisk: Double = 0.45

    /// Share of the original stake a founder recovers when a business folds —
    /// equipment, stock and lease sold off.
    static let ventureFoldRecovery: Double = 0.25

    /// Share of a venture's full income it pays in its 1st and 2nd year, while
    /// it finds its customers; full income from year three.
    static let ventureIncomeRamp: [Double] = [0.4, 0.7]

    /// Year-to-year swing on a founder's income (± this share), on top of the
    /// industry climate.
    static let ventureIncomeSwing: Double = 0.15

    /// Annual chance an average-prepared scalable venture (software, games)
    /// breaks out once past its second year: the rare jackpot of the startup
    /// power law. Preparation and a booming market raise it.
    static let ventureBreakoutChance: Double = 0.04

    /// A breakout's effect on the venture's income, and on what the founder's
    /// stake is worth.
    static let ventureBreakoutIncomeMultiple: Double = 3.0
    static let ventureBreakoutValueMultiple: Double = 4.0

    /// A closed investment round: the company's value after dilution (the
    /// founder gives up a slice for the money), and the growth in the income
    /// the funded business can pay.
    static let investmentRoundValueGrowth: Double = 1.2

    /// Most priced rounds a venture can raise (seed, A, B, C). Carta: only
    /// 15–20 % of seed-stage startups even reach a Series A within two years.
    static let maxInvestmentRounds: Int = 4

    /// Best odds a round ever closes, however strong the pitch and the name.
    static let investmentRoundMaxOdds: Double = 0.75

    /// A hired executive's yearly equity grant as a share of pay — C-suite
    /// ("Chief …") and other executive seats (directors) — and the most
    /// unsold vested equity can reach, in years of pay. Grants vest yearly and
    /// a sale uses them up (see `Player.shareStakeValue`).
    static let execEquityGrantShareCSuite: Double = 0.50
    static let execEquityGrantShare: Double = 0.15
    static let execEquityMaxMultiple: Double = 2.0

    /// Tax on selling vested employee shares (taxed as income at vest), and a
    /// founder's cost of an exit (broker fees plus capital-gains tax).
    static let equitySaleTaxRate: Double = 0.25
    static let founderExitCostRate: Double = 0.15

    /// What an unsold stake in a running private business counts for in net
    /// worth: illiquid, dependent on its founder, and taxed when sold.
    static let privateEquityDiscount: Double = 0.6

    // Founder reputation: founding builds a business (💼) name that makes the
    // next venture easier — serial founders outperform first-timers, and even
    // a failed founder does no worse than one who never tried.
    /// Business fame banked for each year a venture survives.
    static let founderYearFame: Double = 0.3
    /// Business fame banked for selling a venture — a successful exit.
    static let founderExitFame: Double = 2.0
    /// Business fame banked when a venture folds — the lessons.
    static let founderFoldFame: Double = 0.1
    /// Business fame banked when a scalable venture breaks out (see
    /// `Player.advanceYear`), and when a Boardroom investment round closes.
    /// All of these count toward the founder track record (`Player.founderTrackRecordPoints`).
    static let founderBreakoutFame: Double = 2.0
    static let investmentRoundFame: Double = 0.75
    /// Preparation per point of business fame, and its cap (see
    /// `Job.founderSuccessProbability`).
    static let founderReputationPerPoint: Double = 0.04
    static let founderReputationCap: Double = 0.10
    /// How much each point of founder track record eases the seat hurdle on a
    /// commercial executive seat (`Player.executiveTrackRecord`, read by
    /// `Job.seatChance`), and the most it can add: boards hire people who have
    /// already run a company — failed founders included — but 84% of new S&P
    /// 1500 CEOs are first-timers (Spencer Stuart 2025), so it eases the odds
    /// rather than deciding them. A maxed record lifts a C-suite seat from 0.10
    /// to 0.25.
    static let executiveTrackRecordPerPoint: Double = 0.05
    static let executiveTrackRecordCap: Double = 0.15
    static let investmentRoundIncomeGrowth: Double = 1.2

    // MARK: - The business cycle
    //
    // The economy is one number — `Player.macroTrend`, the national cycle — plus
    // one number per sector for whatever is happening to that sector alone.
    // A sector's published trend is
    //
    //     trend = macroTrend × Industry.beta + idiosyncratic
    //
    // which is why a downturn can be brutal for construction (beta 1.8) and barely
    // visible in government (beta 0.3), and why pharma can boom through a
    // recession on its own pipeline (low beta, high volatility). Both halves are
    // persistent random walks, so trends last several years rather than
    // re-rolling from scratch.

    /// Share of last year's national cycle that carries into this one.
    static let macroTrendPersistence: Double = 0.80

    /// Half-width of the national cycle's own yearly shock.
    static let macroTrendShock: Double = 0.22

    /// Share of last year's *sector-specific* deviation that carries over. Lower
    /// than the macro figure: a company-level run of luck fades faster than an
    /// economy-wide cycle.
    static let industryTrendPersistence: Double = 0.65

    /// Half-width of a sector's own yearly shock, before its `volatility`
    /// scales it. This is the part of a sector's fortune that owes nothing to
    /// the economy.
    static let industryTrendShock: Double = 0.30

    /// How hard a declared downturn drags the *national* cycle each year it runs.
    /// Sectors feel it through their beta, not directly.
    static let recessionDrag: Double = 0.40

    /// The gentle upward pull of a calm year: US real GDP grows ~2% a year, so
    /// expansion is the normal state (NBER: expansions average 64 months,
    /// contractions 10). Without it the recession drag had no counterweight and
    /// the average year read as "Slowing"; with it the long-run mean of the
    /// cycle sits near zero and booms happen.
    static let expansionDrift: Double = 0.06

    /// Gentle pull back toward neutral in a calm economy (on top of
    /// `expansionDrift`), so a cycle that has run hot for years cools on its own
    /// rather than staying booming forever.
    static let industryMeanReversion: Double = 0.10

    /// C-suite scarcity: the share of qualified candidates who land a "Chief …"
    /// seat (CEO, CTO, Chief Medical Officer, Editor-in-Chief) in a given year.
    /// Applied as a multiplier *after* the odds floor (see `Job.seatChance`), to
    /// hires and to promotions into such a seat alike. Chief executives are
    /// ~0.2% of US employment and the S&P 1500 names ~170 new CEOs a year
    /// (Spencer Stuart 2025; BLS OOH top executives), so even a strong,
    /// qualified candidate needs several late-career attempts. Founders are
    /// unaffected — they make their own seat.
    static let cSuiteSeatChance: Double = 0.10

    /// Seat scarcity for the Director and Partner capstones (Marketing/Sales/Art
    /// Director, Managing Partner): senior, but several per organisation rather
    /// than one — scarce, not a lottery.
    static let directorSeatChance: Double = 0.30

    // MARK: - Hiring
    //
    // One application's odds (see `Job.hireBreakdown`):
    //
    //     merit = base(role's EQF) + skill fit × hireSkillWeight + prestige
    //             + network + fame + credential + breakthrough
    //     raw   = merit × requirement factors × salary fit × demand × rung decay
    //     odds  = clamp(raw × climate × time out of work, hireFloor…hireCeiling)
    //             × seat scarcity

    /// Starting merit by the role's expected education (`minEQF`, index 0…7):
    /// what an applicant brings before any skill is scored. Entry-level service
    /// work hires most comers, professional roles screen hard. Calibrated so a
    /// raw 18-year-old lands a cashier or fast-food job ~70% of the time and a
    /// degree-level role ≤ 3% — the JOLTS gap between accommodation/food hires
    /// and professional funnels (Goldman Sachs 2025 analysts: 0.72% of
    /// applicants).
    static let hireBaseByEQF: [Double] = [0.45, 0.45, 0.45, 0.35, 0.20, 0.10, 0.10, 0.10]

    /// Weight of the 0…1 soft-skill fit in merit — the largest single term, so a
    /// fully fitting degree-level applicant starts from 0.70.
    static let hireSkillWeight: Double = 0.60

    /// Lowest odds an open application ever shows — a long shot, not a lottery
    /// ticket. Also the odds of a breakthrough-gated career without its award.
    /// Seat scarcity is applied after it, so a C-suite long shot sits at 0.1%.
    static let hireFloor: Double = 0.01

    /// "Degree preferred": office roles paying at least
    /// `degreePreferredMinIncome` that don't require a degree still favour
    /// graduates — `degreePreferenceRatio` of the odds per level a non-graduate
    /// is below `degreePreferredEQF` (see `Job.prefersDegree`).
    static let degreePreferredEQF: Int = 5
    static let degreePreferredMinIncome: Int = 55_000
    static let degreePreferenceRatio: Double = 0.6

    /// Share of title-holding applicants a professional roster can take — the
    /// seat hurdle on every rung above Amateur of the Player ladder. NCAA:
    /// roughly 1–5 % of college players are drafted; most juniors who win a
    /// youth title never sign a pro contract.
    static let proRosterChance: Double = 0.10

    /// Oldest age at which a first professional contract is signed.
    static let latestProSigningAge: Int = 25

    /// Yearly chance a professional athlete's playing career ends, by age
    /// (ages below the first key never retire; the last value holds after).
    /// Average pro careers last 3–6 years and most end by the mid-30s.
    static let athleteRetirementChanceByAge: [(fromAge: Int, chance: Double)] = [
        (30, 0.15), (33, 0.30), (36, 0.50), (38, 1.0),
    ]

    /// Highest odds any application reaches before seat scarcity: somebody else
    /// can always get the job.
    static let hireCeiling: Double = 0.95

    /// Hiring narrows as the pyramid does: each rung above a ladder's entry
    /// multiplies an *outside* application by this (applications only —
    /// promotions from inside don't pay it). 73% of new CEOs are internal hires
    /// (Spencer Stuart 2025); senior seats mostly fill from within.
    static let externalHireRungDecay: Double = 0.85

    /// Below this share of a role's expected years the application is not
    /// considered at all; between it and the full figure the experience factor
    /// is the square of the share (4 of 5 years → ×0.64, 3 of 5 → ×0.36).
    /// Stretch hires below roughly two-thirds of the posted years are rare, and
    /// BLS bands experience requirements precisely because employers screen on
    /// them.
    static let experienceStretchMin: Double = 0.6

    /// For a seat-scarce role (C-suite, director, partner) the experience
    /// factor must reach this or the role is closed: a CEO search doesn't
    /// consider someone with a fraction of the expected record. With the square
    /// law that means ~71% of the expected years.
    static let executiveExperienceMinFactor: Double = 0.5

    /// Salary ask: asking at or below this share of the offer earns a small edge
    /// (`salaryAskDiscountBonus`); asking up to `salaryAskTolerance` of it costs
    /// nothing — employers expect a 5–10% counter; beyond that each point over
    /// costs `salaryAskPenaltyRate` points of odds (15% over → ×0.80, 55% over →
    /// no offer).
    static let salaryAskDiscountRatio: Double = 0.90
    static let salaryAskDiscountBonus: Double = 1.05
    static let salaryAskTolerance: Double = 1.05
    static let salaryAskPenaltyRate: Double = 2.0

    /// The education level (EQF 4 = vocational) below which a role counts as
    /// unskilled (`Job.isLowSkilled`) — and gets the lower pay band for merit
    /// raises (`payCeilingMultipleSubDegree`). It no longer decides who is
    /// promoted: any rung with a rung above it can be, police and trade
    /// apprentices included, and a role with no rung above has nothing to be
    /// promoted to.
    static let promotionMinEQF: Int = 4

    /// The education expectation at which a role's pay becomes negotiable rather
    /// than a posted rate (EQF 4 = vocational/college). Set here rather than at
    /// bachelor's so the trained creative professions — a designer, an animator,
    /// an editor — argue over a fee the way they do in life; below it a role
    /// takes the band it is offered. See `Job.salaryIsNegotiable`.
    static let negotiableSalaryMinEQF: Int = 4

    // MARK: - Promotions
    //
    // One year's promotion odds (see `Player.promotionOdds`):
    //
    //     merit = promotionMeritChance × (floor + (1 − floor) × weighted)
    //             × promotionRungDecay^rung
    //     odds  = (merit + network + fame + education)
    //             × climate × passed over × age fade
    //
    // and a win steps up one rung — there is no in-place "promotion" any more —
    // provided the player meets that rung's requirements *and* its full years,
    // and clears its seat (`Job.promotionSeatChance`).

    /// The annual promotion chance a flawless record earns on merit alone at a
    /// ladder's entry rung — top performance, fully ready for the next one, and
    /// seasoned — before network, fame, education and the climate move it.
    /// Pave: US tech promotes ~14% of staff a year, lower levels much more
    /// often than senior ones; Mercer: 8–10% of the whole workforce.
    static let promotionMeritChance: Double = 0.30
    /// The share of `promotionMeritChance` even a thin record keeps: nobody's
    /// odds are zero on merit, somebody always gets lucky.
    static let promotionMeritFloor: Double = 0.05
    /// Each rung up multiplies merit by this: the pyramid narrows, so a senior
    /// engineer waits far longer for staff than a junior for mid-level (Pave:
    /// promotion rates fall steeply with level; staff-and-above is ~10–15% of
    /// engineers).
    static let promotionRungDecay: Double = 0.70
    /// Years in the current role (`Player.yearsInRole`) at which seniority
    /// counts in full. Counted from the last promotion or hire, not the whole
    /// ladder, so it resets on the way up.
    static let promotionSeniorityYears: Int = 3
    /// Passed over: after this many years in one role the odds start to fade —
    /// by `promotionPassedOverRate` a year, to `promotionPassedOverFloor` — the
    /// plateau most careers reach, rather than forty independent rolls that
    /// eventually carry everyone to the top.
    static let promotionPassedOverAfterYears: Int = 6
    static let promotionPassedOverRate: Double = 0.10
    static let promotionPassedOverFloor: Double = 0.25
    /// Late-career fade: full odds up to `promotionAgeFadeStart`, falling
    /// linearly to `promotionAgeFadeFloor` at `promotionAgeFadeEnd` and staying
    /// there. BLS median weekly earnings plateau after 45 and dip after 55.
    static let promotionAgeFadeStart: Int = 48
    static let promotionAgeFadeEnd: Int = 60
    static let promotionAgeFadeFloor: Double = 0.35

    /// Promotion-odds lift per point of fame in the field, and its cap. A known
    /// name is first in line for the next rung, but it tips a close call rather
    /// than deciding it.
    static let famePromotionPerPoint: Double = 0.015
    static let famePromotionCap: Double = 0.06

    /// Promotion-odds lift per point of professional network in the field, and
    /// its cap.
    static let networkPromotionPerPoint: Double = 0.006
    static let networkPromotionCap: Double = 0.05

    /// The seat on a promotion into a top rung that is neither a "Chief …" nor
    /// a Director/Partner seat (those use `cSuiteSeatChance` /
    /// `directorSeatChance`): a staff engineer, a head chef, a charge nurse —
    /// fewer seats than contenders.
    static let leadershipSeatChance: Double = 0.25

    /// The seat on a promotion into a command post (`JobCatalog.commandPostTitles`:
    /// a precinct or fire-station commander, a school's head of academics, an
    /// executive chef). Police captains are ~2–5% of officers and principals
    /// ~2.5% of teachers.
    static let commandPostSeatChance: Double = 0.10

    // MARK: - Education's pull on the odds
    //
    // Outside the regulated professions a degree is deliberately not a hard gate
    // — talent, portfolio and experience can stand in for it (see
    // `JobCategory.educationIsMandatory`). It is, however, the single biggest
    // thing an employer screens on after skills, so it carries real weight in
    // the score rather than being a rounding error.

    /// Hire-odds multiplier per EQF level the applicant falls short of a
    /// degree-level role (minEQF ≥ 5), compounding: one level short ×0.30, two
    /// (high school for a bachelor's role) ×0.09. BLS attainment 2023-24: 86% of
    /// software developers and 89% of accountants hold a bachelor's or more and
    /// under 3% high school or less; dropping degree requirements raised non-BA
    /// hiring by only 3.5 pp (Burning Glass/HBS 2024) — relative odds of about
    /// 0.04–0.10 for high school against a bachelor's.
    static let educationShortfallRatioDegree: Double = 0.30

    /// The same per-level ratio for roles below degree level (vocational and
    /// high-school roles), where a missing certificate matters less: one level
    /// short ×0.60.
    static let educationShortfallRatioSubDegree: Double = 0.60

    /// Floor on the education multiplier, so no schooling at all for a
    /// degree-level role is a very long shot rather than an impossibility.
    static let educationShortfallFloor: Double = 0.02

    /// Multiplier for holding the expected level in a field the role accepts.
    /// The right degree, not merely a degree.
    static let relevantDegreeMultiplier: Double = 1.10

    /// Multiplier for clearing the level in a field the role doesn't list (it
    /// only applies to roles with accepted fields) — and for meeting the level
    /// only through equivalent experience. An unrelated major is screened far
    /// harder than the right one: new graduates outside the field land such
    /// roles at roughly half the rate.
    static let unrelatedDegreeMultiplier: Double = 0.60

    /// Equivalent experience: at most this many EQF levels of a shortfall can be
    /// made up by what the applicant has demonstrably done instead — a held
    /// credential whose `careerBoost` covers the field (a bootcamp portfolio),
    /// `equivalentExperienceFame` points of fame in the field, or
    /// `equivalentExperienceYears` years in it. See `Job.equivalentExperienceCredit`.
    static let equivalentExperienceMaxCredit: Int = 1
    static let equivalentExperienceFame: Double = 3.0
    static let equivalentExperienceYears: Int = 4

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

    /// The raise a rung step brings, as a fraction of current pay, before it is
    /// clamped into the new rung's band (`promotionPayFloorShare` …
    /// `promotionPayCeilingShare` of its catalogue median). Mercer 2025: the
    /// average promotional increase is 8.5–8.7%. See `Player.promotionPay`.
    static let promotionRaise: ClosedRange<Double> = 0.08...0.15
    static let promotionPayFloorShare: Double = 0.90
    static let promotionPayCeilingShare: Double = 1.25

    // MARK: - Pay over time

    /// The annual step (merit) raise by years in the role (`Player.yearsInRole`,
    /// index 0 = the first year): 2% for five years, 1% for five, then
    /// `annualStepRaiseLate`. Scaled by 0.5 + performance fit, so 1–3% early.
    /// Atlanta Fed: job stayers' median wage growth runs ~0.6–1% a year above
    /// inflation; police, fire and school pay scales are step schedules.
    static let annualStepRaiseByTenure: [Double] = [0.02, 0.02, 0.02, 0.02, 0.02,
                                                     0.01, 0.01, 0.01, 0.01, 0.01]
    static let annualStepRaiseLate: Double = 0.005

    /// Merit raises stop at this multiple of the role's catalogue median — the
    /// top of the pay band: roles below EQF 4 and skilled roles respectively.
    /// BLS within-occupation P90/P50 ratios run ~1.35 (truck drivers) to ~1.7
    /// (electricians). Only a new rung or a new job moves pay beyond it.
    static let payCeilingMultipleSubDegree: Double = 1.30
    static let payCeilingMultipleSkilled: Double = 1.50

    // MARK: - Layoffs

    /// A year's base layoff risk for a job in a steady sector that moves with
    /// the economy (beta 1), on Real Life. Scaled by the employer sector's beta
    /// (never below `layoffBetaFloor`), its climate (`IndustryClimate.layoffFactor`)
    /// and the difficulty (`Difficulty.layoffSeverity`), capped at
    /// `turmoilMaxLayoffChance`. BLS Displaced Workers Survey 2023–25: ~1.5% of
    /// the employed are displaced a year, ~3.5% a year in 2007–09.
    static let baseLayoffRisk: Double = 0.02

    /// The least a sector's beta scales layoff risk by: a public payroll barely
    /// feels the cycle, but people still lose government and hospital jobs
    /// (JOLTS: government layoffs ~0.4% a month).
    static let layoffBetaFloor: Double = 0.35

    /// Share of a year's pay banked in the year of a layoff: the months worked,
    /// severance and unemployment insurance. CPS 2025: the mean unemployment
    /// spell is ~23 weeks. Experience for that year is not banked.
    static let layoffYearPayShare: Double = 0.5

    /// In a slumping sector each role (every rung of a ladder together) is
    /// withdrawn from the year's postings with this chance. JOLTS 2007–09:
    /// openings fell ~50%, hires ~28% — sharply lower, never to zero.
    static let slumpPostingWithdrawalChance: Double = 0.40

    /// A running venture's fold risk is multiplied by this in a recession year
    /// (`Player.advanceVenture`) — its own constant, no longer the employee
    /// layoff severity.
    static let ventureRecessionFoldMultiplier: Double = 1.3

    // MARK: - Offers

    /// The salary offered to a new hire is the posting's median times
    /// `offerExperienceBase + offerExperiencePerYear × relevant years`, clamped
    /// to `offerExperienceBase…offerExperienceCap` (see `Job.offeredSalary`):
    /// a newcomer starts near the occupation's 25th percentile, a ten-year
    /// veteran well above the median. BLS P10/P90 spread is ~0.65×/1.6× the
    /// median, driven mostly by experience.
    static let offerExperienceBase: Double = 0.85
    static let offerExperiencePerYear: Double = 0.03
    static let offerExperienceCap: Double = 1.15

    /// Duration dependence: each consecutive year out of work beyond the first
    /// multiplies an adult's hire odds by this, down to `unemploymentHireFloor`
    /// (see `Player.unemploymentHireMultiplier`). Employers screen on résumé
    /// gaps; long-term unemployed callback rates fall sharply (Kroft, Lange &
    /// Notowidigdo 2013).
    static let unemploymentHirePenalty: Double = 0.85
    static let unemploymentHireFloor: Double = 0.6

    /// Age at which a run ends and its score is final.
    ///
    /// This exists to bound the score. `Player.leaderboardScore` is net worth ÷
    /// age, and savings compound at `investmentReturn` every year whether or not
    /// the player works — so net worth grows geometrically while age grows
    /// linearly. Past age 1/`investmentReturn` ≈ 22 that ratio rises every year
    /// on its own: idling raised the score forever, and the best strategy was to
    /// stop playing and hold **Skip**. A horizon caps the years available to
    /// every run equally, so the score is decided by what a career achieved
    /// inside a lifetime rather than by how long someone kept tapping.
    ///
    /// Note that capping passive growth instead would not have worked: any
    /// positive return, employed or not, reproduces the same unbounded ratio.
    /// Only a finite number of years closes it.
    static let retirementAge: Int = 65
}
