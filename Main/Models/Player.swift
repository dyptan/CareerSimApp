import Foundation
import SwiftUI

/// A milestone entry shown in the `StatusBarView` event log: a player-facing
/// note tagged with the age at which it happened. Identifiable so SwiftUI can
/// diff the list when new entries arrive.
struct StatusEvent: Identifiable, Hashable {
    let id = UUID()
    let age: Int
    let icon: String
    let message: String
}

/// A single entry on the player's fame shelf: a named accolade that
/// builds reputation — a competition trophy, a fame-building side hustle, or a
/// noticed spare-time project. Fame is the third pillar of career
/// capital alongside soft and hard skills: *what you're known for*, rather than
/// what you can do. Each entry carries its own display icon and reputation
/// `weight`; `count` levels it up when the same accolade is earned again (a
/// repeatable project shipped three good years reads as ×3, not three rows).
/// `category` scopes the reputation to one of the five `FameCategory` buckets —
/// it only lifts hiring odds for roles whose industry maps to that same bucket
/// (see `Player.fameHireBonus(for:)`); `nil` is general renown that helps a
/// little everywhere.
struct FameAward: Identifiable, Hashable {
    let title: String
    let icon: String
    let category: FameCategory?
    let weight: Double
    var count: Int = 1

    var id: String { title }

    /// Total reputation this shelf entry contributes: per-instance `weight`
    /// multiplied by the number of times it's been earned.
    var totalWeight: Double { weight * Double(count) }
}

final class Player: ObservableObject {
    /// The single difficulty choice the game runs under: how much complexity is
    /// in play (Simplified strips skills, tiers, negotiation, and the economy)
    /// plus, for the realistic settings, savings rate and economic volatility.
    /// Set from the launch picker.
    @Published var difficulty: Difficulty = .default
    /// Convenience: true when only the basic (degree + experience) rules apply.
    var isSimplified: Bool { difficulty.isSimplified }

    /// The player's chosen avatar emoji, picked on the launch screen. Shown in
    /// the header. Purely cosmetic.
    @Published var avatar: String = Player.avatarOptions[0]

    /// Selectable launch-screen avatars.
    static let avatarOptions: [String] = [
        "🧒", "👦", "👧", "🧑", "👨", "👩", "🧑‍🦱", "🧑‍🦰",
        "🦸", "🧑‍🎤", "🧑‍🚀", "🤖", "🦊", "🐱", "🐵", "🦄"
    ]

    /// The player's fame shelf: every accolade they've earned —
    /// competition trophies, fame-building side hustles, and noticed spare-time
    /// projects — as `FameAward` entries. This is the third pillar of career
    /// capital alongside `softSkills` and `hardSkills`, surfaced in its own
    /// SkillsView section. Reputation is industry-scoped (see `fameHireBonus`),
    /// and repeats level an existing entry rather than duplicating it (see
    /// `award`).
    @Published var fameAwards: [FameAward] = []

    /// Banks an accolade on the fame shelf, levelling an existing
    /// entry of the same title rather than adding a duplicate row.
    func award(_ title: String, icon: String, category: FameCategory?, weight: Double) {
        if let i = fameAwards.firstIndex(where: { $0.title == title }) {
            fameAwards[i].count += 1
        } else {
            fameAwards.append(FameAward(title: title, icon: icon, category: category, weight: weight))
        }
    }

    /// Number of competitions won in the year just advanced (0 when none).
    /// Surfaced in the header alongside the confetti.
    @Published var lastCompetitionWins: Int = 0

    /// Drives the competition-win celebration dialog. Set when the automatic
    /// yearly contest for the sport trained this year is won (see `advanceYear`).
    @Published var showCompetitionWinAlert: Bool = false
    @Published var competitionWinMessage: String = ""

    /// Weighted sum of every banked trophy, where each title's contribution
    /// comes from its source's `fameWeight` (a local 5K is worth less than an
    /// Olympic medal). Drives both `fameHireBonus(for:)` and the fame lift on
    /// Show Business side hustles.
    var fameScore: Double {
        fameAwards.reduce(0.0) { $0 + $1.totalWeight }
    }

    /// Weighted fame relevant to a fame bucket: awards banked in that same
    /// `FameCategory` plus general (bucket-less) renown. Only this counts toward
    /// the hire and promotion fame bonuses — a tech portfolio does nothing for a
    /// stage audition. Passing `nil` (a job family outside every bucket) counts
    /// only the general renown. Each `FameAward` carries the bucket it was earned
    /// in (see `FameAward.category`).
    func famePoints(for category: FameCategory?) -> Double {
        fameAwards.reduce(0.0) { acc, award in
            if award.category == nil { return acc + award.totalWeight }  // general renown
            return award.category == category ? acc + award.totalWeight : acc
        }
    }

    /// Fame totals grouped by the bucket each award was earned in, for display.
    /// A `nil` category is general (bucket-less) renown. Ordered by score,
    /// highest first, so the field the player is best known in leads.
    var fameByCategory: [(category: FameCategory?, score: Double)] {
        var totals: [FameCategory?: Double] = [:]
        for award in fameAwards {
            totals[award.category, default: 0] += award.totalWeight
        }
        return totals
            .map { (category: $0.key, score: $0.value) }
            .sorted { $0.score > $1.score }
    }

    /// Additive hire-probability boost from fame for a role in `jobCategory`,
    /// mapping the industry to its `FameCategory` bucket. Fame is chiefly earned
    /// by shipping **accomplished projects** (see `SideHustle` fame plays), and a
    /// noticed body of that work is a significant hiring lever — ordinary roles
    /// lift a strong +0.07 per reputation point up to a +0.35 cap (a serious
    /// portfolio nearly rivals the soft-skill fit term). **Top positions** weight
    /// reputation even more heavily — a public profile is often what separates the
    /// shortlist for a leadership seat — so they earn a steeper per-point rate and
    /// a higher cap (+0.50). See `Job.isTopLeadership` / `Job.hireProbability`.
    ///
    /// For an **executive seat** a business (💼) name counts too — whichever is
    /// higher — since running a company is the credential a board hires for,
    /// whatever the industry.
    func fameHireBonus(for jobCategory: JobCategory, topPosition: Bool = false, executive: Bool = false) -> Double {
        let rate = topPosition ? 0.12 : 0.07
        let cap = topPosition ? 0.50 : 0.35
        var points = famePoints(for: jobCategory.fameCategory)
        if executive { points = max(points, famePoints(for: .business)) }
        return min(cap, points * rate)
    }

    /// The chance of clearing the C-suite scarcity hurdle: the base
    /// `GameConstants.executiveSeatChance`, eased by a business track record —
    /// years running ventures, rounds, exits — up to +30 points.
    var executiveSeatChance: Double {
        let trackRecord = min(GameConstants.executiveTrackRecordCap,
                              famePoints(for: .business) * GameConstants.executiveTrackRecordPerPoint)
        return min(1, GameConstants.executiveSeatChance + trackRecord)
    }

    /// Years a prolonged recession still has to run. While positive, each
    /// `advanceYear` keeps the downturn in force (hiring freeze + layoff risk)
    /// and counts down. Zero means the economy is not in an ongoing recession.
    @Published var turmoilYearsRemaining: Int = 0

    /// Whether the economy is in a downturn this year (a fresh or ongoing
    /// recession). Drives the header recession note and drags every industry's
    /// trend down — how hard depends on the industry (see `advanceIndustryTrends`).
    @Published var economyInRecession: Bool = false

    /// The national business cycle, in -1...1 — the one number every sector's
    /// fortunes are derived from. A persistent random walk, dragged down while a
    /// declared recession runs (see `advanceIndustryTrends`).
    @Published var macroTrend: Double = 0

    /// What is happening to each sector *on its own account*, with the national
    /// cycle taken out — a platform shift, a drug approval, an oil shock. Added
    /// to the sector's share of `macroTrend` to give its published trend.
    @Published var industryIdiosyncratic: [Industry: Double] = [:]

    /// The overall economy's climate, for the Economy panel's headline.
    var macroClimate: IndustryClimate { IndustryClimate(trend: macroTrend) }

    /// Each sector's fortunes this year, as a continuous trend in -1...1.
    /// Bucketed into an `IndustryClimate` for everything that reads it — hiring,
    /// promotions, projects and the Economy panel.
    ///
    /// Keyed by `Industry`, the sector an employer trades in, **not** by
    /// `JobCategory`. A category is a discipline, not a market: "Design" is not
    /// something anyone's revenue depends on, whereas advertising and carmaking
    /// are, and they can move in opposite directions while employing the same
    /// designers. Each posting states its sector (see `Job.industry`).
    @Published var industryTrend: [Industry: Double] = [:]

    /// This year's climate for a sector.
    func climate(for industry: Industry) -> IndustryClimate {
        IndustryClimate(trend: industryTrend[industry] ?? 0)
    }

    /// This year's climate for a fame bucket — the mean across the sectors that
    /// bank into it, so a project rides the market it would make its name in.
    func climate(forFame fame: FameCategory) -> IndustryClimate {
        let sectors = Industry.allCases.filter { $0.fameCategory == fame }
        guard !sectors.isEmpty else { return .steady }
        let total = sectors.reduce(0.0) { $0 + (industryTrend[$1] ?? 0) }
        return IndustryClimate(trend: total / Double(sectors.count))
    }

    /// Sectors ordered best-to-worst for the Economy panel.
    var industriesByClimate: [(industry: Industry, climate: IndustryClimate)] {
        Industry.allCases
            .map { (industry: $0, climate: climate(for: $0)) }
            .sorted {
                let a = industryTrend[$0.industry] ?? 0, b = industryTrend[$1.industry] ?? 0
                return a == b ? $0.industry.rawValue < $1.industry.rawValue : a > b
            }
    }

    /// Rolls the economy forward one year.
    ///
    /// One national cycle moves first: most of last year carries over, a shock
    /// moves it, and a declared recession drags it down (otherwise it reverts
    /// gently toward neutral, so no boom lasts forever). Then each sector's own
    /// deviation moves on the same pattern, scaled by its `volatility`.
    ///
    /// A sector's published trend is its share of the national cycle — its
    /// `beta` — plus that deviation. That is the whole model: one economy,
    /// transmitted unevenly, plus whatever is happening to each sector alone.
    func advanceIndustryTrends(recession: Bool) {
        let macroShock = Double.random(in: -GameConstants.macroTrendShock...GameConstants.macroTrendShock)
        let macroCycle = recession
            ? -GameConstants.recessionDrag
            : -macroTrend * GameConstants.industryMeanReversion
        macroTrend = min(1.0, max(-1.0,
            macroTrend * GameConstants.macroTrendPersistence + macroShock + macroCycle))

        for sector in Industry.allCases {
            let previous = industryIdiosyncratic[sector] ?? 0
            let shock = Double.random(in: -GameConstants.industryTrendShock...GameConstants.industryTrendShock)
                * sector.volatility
            let deviation = previous * GameConstants.industryTrendPersistence + shock
            industryIdiosyncratic[sector] = min(1.0, max(-1.0, deviation))
            industryTrend[sector] = min(1.0, max(-1.0, macroTrend * sector.beta + deviation))
        }
    }

    /// Size of last year's promotion raise as a whole-number percent (0 when the
    /// player wasn't promoted). Quoted in the pop-up and the status log.
    @Published var lastPromotionRaisePct: Int = 0

    /// One-shot trigger for the promotion congratulations pop-up, set the moment a
    /// raise is earned; the alert clears it when dismissed (the status log
    /// keeps the milestone afterward).
    @Published var showPromotionAlert: Bool = false

    /// The promotion pop-up's message, capturing the raise and the new pay.
    @Published var promotionMessage: String = ""

    /// One-shot trigger for the graduation congratulations pop-up. Set the
    /// moment a degree finishes (whether through the tertiary-track timer or
    /// the school-age transitions in `RootView`). The alert clears it on
    /// dismiss; `StatusBarView` still keeps the milestone in its history.
    @Published var showGraduationAlert: Bool = false

    /// The graduation pop-up's message, capturing the degree just earned.
    @Published var graduationMessage: String = ""

    /// The graduation pop-up's text: a short congratulations. What the degree
    /// opens up is discoverable in the Education and Jobs sheets — the pop-up
    /// just marks the moment.
    func graduationMessage(for degree: Education) -> String {
        if degree.level == .HighSchool {
            let gpa = highSchoolGPA
            return "Congratulations! You graduated from High School with a \(Player.formatGPA(gpa)) GPA (\(Player.letterGrade(gpa)))."
        }
        return "Congratulations! You completed your \(degree.degreeName)."
    }

    // MARK: - School grades

    /// The grade earned in each high-school year completed, on the US 4.0
    /// scale. Recorded by `advanceYear`; averaged into `highSchoolGPA`, which
    /// universities weigh at admission (see `Education.admissionProbability`).
    @Published var highSchoolGrades: [Double] = []

    /// The skills schoolwork runs on: working problems out, getting details
    /// right, sticking at it, and planning the load.
    static let academicAxes: [WritableKeyPath<SoftSkills, Int>] = [
        \.analyticalReasoningAndProblemSolving,
        \.carefulnessAndAttentionToDetail,
        \.selfDisciplineAndPerseverance,
        \.timeManagementAndPlanning,
    ]

    /// This year's grade: the academic skills set the band, and a year spent on
    /// a Study activity lifts it. Skills alone top out at a B+; a straight A
    /// takes both.
    func yearGrade(studied: Bool) -> Double {
        let reference = Double(GameConstants.gradeSkillReference)
        let fit = Player.academicAxes.reduce(0.0) { acc, kp in
            acc + min(Double(softSkills[keyPath: kp]) / reference, 1.0)
        } / Double(Player.academicAxes.count)
        let grade = GameConstants.gradeFloor
            + GameConstants.gradeSkillSpan * fit
            + (studied ? GameConstants.studyGradeBonus : 0)
        return min(4.0, grade)
    }

    /// The high-school grade point average. A player who started the game past
    /// high school has no recorded years, so their record is read off the
    /// skills they arrived with — the grade those skills earn without extra study.
    var highSchoolGPA: Double {
        guard !highSchoolGrades.isEmpty else { return yearGrade(studied: false) }
        return highSchoolGrades.reduce(0, +) / Double(highSchoolGrades.count)
    }

    /// The GPA as 0...1 for admission: a C average (2.0) counts for nothing, a
    /// straight-A 4.0 for everything.
    var academicFit: Double {
        max(0, min(1, (highSchoolGPA - GameConstants.gradeFloor) / (4.0 - GameConstants.gradeFloor)))
    }

    /// Trophies and accolades as 0...1 for admission: the fame shelf's total
    /// weight against `GameConstants.accoladeReference`, so an olympiad medal
    /// counts for more than a sports-day ribbon.
    var accoladeFit: Double {
        min(1, fameScore / GameConstants.accoladeReference)
    }

    static func formatGPA(_ gpa: Double) -> String {
        String(format: "%.1f", gpa)
    }

    /// The familiar letter for a GPA, for players who think in grades.
    static func letterGrade(_ gpa: Double) -> String {
        switch gpa {
        case 3.85...:     return "A"
        case 3.5..<3.85:  return "A-"
        case 3.15..<3.5:  return "B+"
        case 2.85..<3.15: return "B"
        case 2.5..<2.85:  return "B-"
        case 2.15..<2.5:  return "C+"
        case 1.85..<2.15: return "C"
        default:          return "D"
        }
    }

    /// Whether a downturn cost the player their job in the year just advanced.
    @Published var lostJobThisYear: Bool = false

    /// One-shot trigger for the layoff pop-up. Set the moment a downturn fires
    /// the player; the alert clears it when dismissed (the status log keeps a
    /// "Laid off" line as the reminder).
    @Published var showLayoffAlert: Bool = false

    /// One-shot trigger for the venture-failure pop-up. Set the year a running
    /// venture folds (see the ongoing venture risk in `advanceYear`); the alert
    /// clears it when dismissed. Founders aren't laid off — their businesses fail.
    @Published var showVentureFailureAlert: Bool = false
    /// Message for the venture-failure pop-up, naming the venture that folded.
    @Published var ventureFailureMessage: String = ""

    /// One-shot trigger for the job-application result pop-up. Applying spends
    /// the year whether or not it lands, so the sheet closes and the answer
    /// arrives here instead of inline.
    @Published var showApplicationOutcomeAlert: Bool = false
    /// Title of the application result pop-up — it differs on an offer and a no.
    @Published var applicationOutcomeTitle: String = ""
    /// Body of the application result pop-up: on a rejection, why and what to do.
    @Published var applicationOutcomeMessage: String = ""

    /// Raises the result pop-up for a job application or a venture launch.
    func reportApplicationOutcome(title: String, message: String) {
        applicationOutcomeTitle = title
        applicationOutcomeMessage = message
        showApplicationOutcomeAlert = true
    }

    /// One-shot trigger for the spare-time project result pop-up. Every project
    /// costs the year whether or not it lands, so the year always reports back.
    @Published var showProjectOutcomeAlert: Bool = false
    /// Title of the project result pop-up — it differs on a hit and a flop.
    @Published var projectOutcomeTitle: String = ""
    /// Body of the project result pop-up, naming the project and what it earned.
    @Published var projectOutcomeMessage: String = ""

    /// Incremented on a celebratory stroke of luck (a promotion, or a long-shot
    /// college admission); the game view watches it to fire the confetti cannon.
    /// Bump it through `celebrateIfLucky(_:)` rather than directly, so every
    /// stochastic payoff applies the same threshold.
    @Published var celebrationTrigger: Int = 0

    /// Fires the celebration confetti when a win came in against long odds
    /// (below `GameConstants.luckyWinThreshold`) — the single home of that rule,
    /// called by every stochastic payoff. Several bumps inside one `advanceYear`
    /// coalesce into a single burst, since the view observes the counter once per
    /// render pass.
    func celebrateIfLucky(_ odds: Double) {
        if odds < GameConstants.luckyWinThreshold { celebrate() }
    }

    /// Fires the celebration confetti unconditionally — for wins that are worth
    /// celebrating however likely they were, such as landing a spare-time
    /// project. Everything stochastic should go through `celebrateIfLucky(_:)`
    /// instead, so long-shot wins stay the rule rather than the exception.
    func celebrate() {
        celebrationTrigger += 1
    }

    /// Running log of player-facing milestones — completions, promotions, hires,
    /// layoffs, unlocked credentials — surfaced by `StatusBarView` (collapsed
    /// shows the latest, expanded shows the full history). Append-only inside
    /// `Player`; cleared on `reset()`.
    @Published var statusEvents: [StatusEvent] = []

    /// This player's odds on a spare-time project right now — the single place
    /// the inputs are assembled, so the number the Projects sheet shows is the
    /// one the year actually rolls against.
    func projectOdds(for hustle: SideHustle) -> Double {
        guard canTakeProject(hustle) else { return 0 }
        return hustle.successProbability(
            for: softSkills,
            famePoints: famePoints(for: hustle.fameCategory),
            totalExperienceYears: totalExperienceYears,
            fieldExperienceYears: hustle.experienceCategory.map { industryExperience(for: $0) } ?? 0,
            climate: projectClimate(for: hustle)
        )
    }

    /// Whether the player holds the award a project requires (the star
    /// projects open only to a name the big break has made).
    func canTakeProject(_ hustle: SideHustle) -> Bool {
        guard let award = hustle.requiresAward else { return true }
        return fameAwards.contains { $0.title == award }
    }

    /// What a landed project would pay this year, on the player's current fame
    /// in its field.
    func projectPay(for hustle: SideHustle) -> Int {
        hustle.pay(famePoints: famePoints(for: hustle.fameCategory))
    }

    /// Yearly endorsement income: brands pay a famous entertainment name —
    /// athletes, stars and creators alike — to carry their products. Nothing
    /// below `GameConstants.endorsementFameThreshold`, then steeply rising.
    var endorsementIncome: Int {
        let fame = famePoints(for: .entertainment)
        guard fame >= GameConstants.endorsementFameThreshold else { return 0 }
        let pay = GameConstants.endorsementBase * pow(fame, GameConstants.endorsementFameExponent)
        return min(GameConstants.endorsementMax, Int(pay.rounded()))
    }

    /// Gross pay last year from landed projects, and from endorsements — shown
    /// in Finances next to the salary.
    @Published var lastYearProjectPay: Int = 0
    @Published var lastYearEndorsements: Int = 0

    /// The climate a project rides: its own industry when it has one, otherwise
    /// the average across the fame bucket it would make its name in.
    func projectClimate(for hustle: SideHustle) -> IndustryClimate {
        climate(forFame: hustle.fameCategory)
    }

    /// Raises the result pop-up for a resolved spare-time project. Every project
    /// costs the year whether or not it lands, so the year always reports back —
    /// a flop names the odds it rolled against so a long shot reads as bad luck
    /// rather than a broken game. Kept short; the details live in the sheets.
    func reportProjectOutcome(_ outcome: SideHustle.Outcome) {
        let hustle = outcome.hustle
        let chance = "\(Int((outcome.odds * 100).rounded()))%"
        if outcome.success {
            projectOutcomeTitle = "\(hustle.icon) It landed!"
            let earned = outcome.grantedFame.map { " You earned the “\($0.title)” title." } ?? ""
            let paid = outcome.pay > 0 ? " It paid \(outcome.pay.formatted(.number)) $." : ""
            projectOutcomeMessage = "\(hustle.label) paid off!" + paid + earned
        } else {
            projectOutcomeTitle = "\(hustle.icon) It didn't land"
            projectOutcomeMessage = "\(hustle.label) didn't pan out — it was a \(chance) shot. You kept the practice: the skills it draws on improved anyway."
        }
        showProjectOutcomeAlert = true
    }

    /// Appends a milestone to `statusEvents`, tagged with the player's current
    /// age. Called from year-progression hooks and from the few mutating
    /// helpers (hiring, founding a venture, graduating) that don't pass
    /// through `advanceYear`.
    func recordStatus(_ icon: String, _ message: String) {
        statusEvents.append(StatusEvent(age: age, icon: icon, message: message))
    }

    /// Whether the player has met the current setting's win condition. Only the
    /// Simplified mode has a fixed *target* — reaching a top leadership
    /// ("C-suite") role. The realistic settings set no target, just a running
    /// `leaderboardScore` the player banks by finishing early or at
    /// `GameConstants.retirementAge`, whichever comes first (see
    /// `hasRetired` and `RetirementView`).
    var goalMet: Bool {
        guard isSimplified else { return false }
        return currentOccupation?.isTopLeadership ?? false
    }

    /// Whether the run has reached its horizon. At `GameConstants.retirementAge`
    /// the career is over and the score is final — `advanceYear` stops advancing
    /// and the Game Over sheet becomes the only way out. See that constant for
    /// why a finite number of years is what makes the score meaningful.
    var hasRetired: Bool { age >= GameConstants.retirementAge }

    @Published var age: Int

    /// Outstanding balance of a loan taken to fund a venture beyond the player's
    /// savings (see `foundVenture` / `maxVentureLoan`). Accrues interest and is
    /// repaid from savings each year in `advanceYear`; it counts against net worth
    /// for the leaderboard. Zero when the player owes nothing.
    @Published var outstandingLoan: Int = 0

    // MARK: Venture state (the business the player founded, if any)

    /// Age at which the running venture was founded; `nil` when not a founder.
    @Published var ventureFoundedAge: Int?
    /// 0...1 how well prepared the founder was at launch — sets the yearly
    /// fold risk and the breakout chance (see `ventureFoldRisk`).
    @Published var venturePreparation: Double = 0
    /// What was staked at launch; a fold recovers a share of it.
    @Published var ventureStake: Int = 0
    /// The income the business pays once established — year one and two pay a
    /// share of it, and each year swings around it (see `advanceYear`).
    @Published var ventureMatureIncome: Int = 0
    /// Investment rounds closed — each lifts what the founder's stake is worth.
    @Published var ventureRoundsRaised: Int = 0
    /// Whether a scalable venture has broken out — the rare jackpot.
    @Published var ventureBrokeOut: Bool = false

    /// Years the current venture has been running (1 in its first year-end).
    var ventureYears: Int { ventureFoundedAge.map { age - $0 } ?? 0 }

    /// 0...1 founder preparation for `job` at `stake`: the preparation score
    /// (`Job.founderSuccessProbability`) rescaled to its own range.
    func founderPreparation(for job: Job, stake: Int) -> Double {
        let score = job.founderSuccessProbability(for: self, investedCapital: stake)
        let floor = 0.03
        return max(0, min(1, (score - floor) / (GameConstants.founderMaxSuccess - floor)))
    }

    /// The chance a business folds in its `year`-th year (1-based) in a calm
    /// economy: the survival curve, scaled from 1.5× (unprepared) to 0.5×
    /// (fully prepared).
    static func ventureFoldRisk(year: Int, preparation: Double) -> Double {
        let curve = GameConstants.ventureFoldRiskByYear
        let base = curve[min(max(year, 1), curve.count) - 1]
        return base * (1.5 - preparation)
    }

    /// The chance a business launched now survives its first year — what the
    /// Ventures sheet shows before the player commits.
    func firstYearSurvival(for job: Job, stake: Int) -> Double {
        1 - Player.ventureFoldRisk(year: 1, preparation: founderPreparation(for: job, stake: stake))
    }

    /// A venture's income in its `year`-th year as a share of its full income.
    static func ventureRamp(year: Int) -> Double {
        let ramp = GameConstants.ventureIncomeRamp
        return year >= 1 && year <= ramp.count ? ramp[year - 1] : 1.0
    }

    /// Clears the venture state when the player stops being a founder.
    private func clearVenture() {
        ventureFoundedAge = nil
        venturePreparation = 0
        ventureStake = 0
        ventureMatureIncome = 0
        ventureRoundsRaised = 0
        ventureBrokeOut = false
    }

    /// Outstanding student-loan balance from tuition the player couldn't cover in
    /// cash (see the tuition charge in `advanceYear`). Accrues interest each year
    /// at `GameConstants.studentLoanAnnualInterest` and is repaid from savings once
    /// the player is earning — so reaching for an expensive degree early is a debt
    /// that follows you. Counts against net worth for the leaderboard. Zero when
    /// the player owes nothing (paid cash, or has cleared it).
    @Published var studentLoan: Int = 0

    /// The fixed annual instalments on each loan, set when money is borrowed
    /// (see `annualLoanPayment`). Zero when the loan is clear.
    @Published var ventureLoanPayment: Int = 0
    @Published var studentLoanPayment: Int = 0

    /// The fixed annual instalment that repays `balance` over
    /// `GameConstants.loanTermYears` at `rate` — the standard amortising loan.
    static func annualLoanPayment(balance: Int, rate: Double) -> Int {
        guard balance > 0 else { return 0 }
        let n = Double(GameConstants.loanTermYears)
        let payment = Double(balance) * rate / (1 - pow(1 + rate, -n))
        return Int(payment.rounded())
    }

    /// This year's instalments due on both loans (interest included), capped
    /// at what each balance will be once this year's interest is added.
    private var loanInstalmentsDue: Int {
        func due(_ balance: Int, _ payment: Int, _ rate: Double) -> Int {
            guard balance > 0 else { return 0 }
            let owed = Int((Double(balance) * (1 + rate)).rounded())
            let instalment = payment > 0 ? payment : Player.annualLoanPayment(balance: balance, rate: rate)
            return min(instalment, owed)
        }
        return due(outstandingLoan, ventureLoanPayment, GameConstants.ventureLoanAnnualInterest)
            + due(studentLoan, studentLoanPayment, GameConstants.studentLoanAnnualInterest)
    }

    /// One year of a loan: interest accrues, then the instalment is paid —
    /// from income set aside for it first, then from savings. Whatever can't be
    /// paid stays owed and keeps accruing. Returns true when the loan clears.
    private func serviceLoan(_ balance: inout Int, payment: inout Int, rate: Double, income: inout Int) -> Bool {
        guard balance > 0 else { return false }
        balance = Int((Double(balance) * (1 + rate)).rounded())
        let instalment = min(balance, payment > 0 ? payment : Player.annualLoanPayment(balance: balance, rate: rate))
        let fromIncome = min(instalment, income)
        income -= fromIncome
        let fromSavings = min(instalment - fromIncome, max(0, savings))
        savings -= fromSavings
        balance -= fromIncome + fromSavings
        if balance == 0 { payment = 0; return true }
        return false
    }

    /// How much the player can borrow right now to top up a venture stake — a
    /// multiple of current annual income (`GameConstants.ventureLoanIncomeMultiple`).
    /// Zero when unemployed: a bank lends against income.
    var maxVentureLoan: Int {
        Int((Double(currentOccupation?.annualIncome ?? 0) * GameConstants.ventureLoanIncomeMultiple).rounded())
    }

    /// The most the player can stake on a venture right now: their savings plus
    /// whatever they can borrow against income. The authoritative cap — the
    /// launch UI and `foundVenture` both read it, so the slider can never offer
    /// money the model would clamp away.
    var maxVentureStake: Int { savings + maxVentureLoan }

    /// How much of `stake` has to be borrowed: savings fund a venture first, and
    /// only the shortfall becomes debt.
    func borrowedPortion(ofStake stake: Int) -> Int { max(0, stake - savings) }

    /// What the player is actually worth: banked savings less any outstanding
    /// venture loan and student debt. Can go negative while debt is being repaid.
    var netWorth: Int { savings - outstandingLoan - studentLoan }

    /// The player's running score, recalculated from current state (so it's
    /// always up to date each year): "wealth velocity" — net worth (savings minus
    /// any outstanding loan) per year of life. Reaching wealth younger scores
    /// higher. Floored at 0. This is what a realistic-mode run is playing for;
    /// finishing the game banks it to the Game Center leaderboard.
    var leaderboardScore: Int { age > 0 ? max(0, netWorth) / age : 0 }

    @Published var degrees: [Education]

    /// The player's best formal qualification, in EQF levels: the highest
    /// degree held, not the most recent one — taking a vocational course after
    /// a Master's isn't a downgrade. Every education gate reads this.
    var highestEQF: Int { degrees.map(\.eqf).max() ?? 0 }

    /// The degrees the player could enrol in next (see
    /// `availableNextEducations`). Empty before adulthood: tuition is money,
    /// and an under-18 player is never shown a priced option — courses and
    /// licences carry their own age gates and are unaffected.
    var offeredDegrees: [Education] {
        guard age >= GameConstants.minimumTertiaryAge else { return [] }
        return availableNextEducations(holds: degrees)
    }

    /// Years of work experience per industry. Key is the job's `JobCategory`,
    /// value is total years accumulated across all jobs in that industry.
    /// Used by standalone roles (entry-level jobs and top capstones that have
    /// no junior rung to climb).
    @Published var experience: [JobCategory: Int]
    /// Years of experience per role family (the job's base title, e.g.
    /// "Financial Analyst"). Drives seniority progression: a senior rung only
    /// counts years spent in that same role, not unrelated jobs in the industry.
    @Published var experienceByRole: [String: Int] = [:]
    @Published var softSkills: SoftSkills
    @Published var hardSkills: HardSkills
    @Published var currentOccupation: Job? {
        // Leaving a venture any way at all — selling out, a fold, taking a
        // job, enrolling full-time — ends the founder's bookkeeping with it.
        didSet {
            if currentOccupation?.isEntrepreneurial != true, ventureFoundedAge != nil {
                clearVenture()
            }
        }
    }
    @Published var currentEducation: Education?
    @Published var savings: Int
    @Published var lockedTrainings: Set<Training>
    /// Professional network built by attending industry `CareerEvent`s, keyed by
    /// the event's industry. Improves hiring odds on that field's postings and
    /// the chance of promotion while working in it (see `networkBonus`).
    @Published var networkByCategory: [JobCategory: Int] = [:]

    /// Total years trained in each `Sport`. A new year is added at year-end for
    /// every sport the player committed their spare-time slot to. Drives the
    /// competition sport gate (a sport must have ≥1 year for its tagged
    /// competitions to appear) and the `sportFit` bonus inside `winProbability`.
    @Published var sportYears: [Sport: Int] = [:]

    /// The disciplines practised in the year just advanced. The Activities rows
    /// only reveal their contest details (the 🏆 button) for these — a player
    /// who kept at something last year gets to see what it's building toward.
    @Published var lastYearSports: Set<Sport> = []
    /// Executive decisions (see `ExecutiveDecision`) taken this year, by id.
    /// Cleared by `advanceYear`.
    @Published var executiveActionsThisYear: Set<String> = []
    /// Jobs offered to the player this year. Re-shuffled (and re-rolled for
    /// salary variance) every time `advanceYear` runs, so the listing feels
    /// different each game year.
    @Published var availableJobs: [Job] = []

    init(
        age: Int = GameConstants.startingAge,
        softSkills: SoftSkills = SoftSkills(
            analyticalReasoningAndProblemSolving: Int.random(in: 0...1),
            creativityAndInsightfulThinking: Int.random(in: 0...1),
            communicationAndNetworking: Int.random(in: 0...1),
            carefulnessAndAttentionToDetail: Int.random(in: 0...1),
            tinkeringAndFingerPrecision: Int.random(in: 0...1),
            spacialNavigationAndOrientation: Int.random(in: 0...1),
            resilienceAndEndurance: Int.random(in: 0...1),
            stressResistanceAndEmotionalRegulation: Int.random(in: 0...1),
            empathyAndInterpersonalCare: Int.random(in: 0...1),
            collaborationAndTeamwork: Int.random(in: 0...1),
            timeManagementAndPlanning: Int.random(in: 0...1),
            selfDisciplineAndPerseverance: Int.random(in: 0...1)
        ),
        hardSkills: HardSkills = HardSkills(),
        degrees: [Education] = [],
        experience: [JobCategory: Int] = [:],
        currentOccupation: Job? = nil,
        savings: Int = 0,
        lockedTrainings: Set<Training> = []
    ) {
        self.age = age
        self.softSkills = softSkills
        self.hardSkills = hardSkills
        self.degrees = degrees
        self.experience = experience
        self.currentOccupation = currentOccupation
        self.currentEducation = Education(Level.Stage.PrimarySchool)
        self.savings = savings
        self.lockedTrainings = lockedTrainings
        self.availableJobs = JobCatalog.allJobs().shuffled()
        // Seed a calm, mildly uneven starting economy rather than a flat one, so
        // the first year the player looks already has industries worth choosing
        // between.
        macroTrend = Double.random(in: -0.15...0.15)
        for sector in Industry.allCases {
            let deviation = Double.random(in: -0.2...0.2) * sector.volatility
            industryIdiosyncratic[sector] = deviation
            industryTrend[sector] = min(1.0, max(-1.0, macroTrend * sector.beta + deviation))
        }
    }

    /// Rebuilds and reshuffles `availableJobs`. Call when the game year advances
    /// or the mode is chosen, so the listing feels fresh each year.
    func regenerateAvailableJobs() {
        availableJobs = JobCatalog.allJobs().shuffled()
    }

    /// Sets `age` and seeds the K-12 record to match a chosen starting age
    /// (7–18), so the player begins with the EQF level they'd have reached by
    /// then: each schooling stage already finished is banked as a degree, and
    /// the stage in progress (if any) becomes `currentEducation`. Mirrors the
    /// age-10/14/18 transitions in `RootView`. Returns true when the player
    /// starts old enough (18) that the post-high-school decision should fire.
    @discardableResult
    func configureStart(age startAge: Int) -> Bool {
        age = startAge
        var earned: [Education] = []
        if startAge >= 10 { earned.append(Education(Level.Stage.PrimarySchool)) }
        if startAge >= 14 { earned.append(Education(Level.Stage.MiddleSchool)) }
        if startAge >= 18 { earned.append(Education(Level.Stage.HighSchool)) }
        degrees = earned
        if startAge < 10 {
            currentEducation = Education(Level.Stage.PrimarySchool)
        } else if startAge < 14 {
            currentEducation = Education(Level.Stage.MiddleSchool)
        } else if startAge < 18 {
            currentEducation = Education(Level.Stage.HighSchool)
        } else {
            currentEducation = nil
        }
        return startAge >= 18
    }

    // MARK: - Soft-skill boosts

    /// Applies a selection's soft-skill boosts, clamped at the 10-point cap —
    /// the single home of that rule for activities, events, and trainings.
    /// Taking an activity commits the year on the spot (the sheet closes and
    /// the year runs), so there is no toggle-off path to reverse.
    private func applySkillBoosts(_ boosts: [WeightedAbility]) {
        for boost in boosts {
            softSkills[keyPath: boost.keyPath] = min(softSkills[keyPath: boost.keyPath] + boost.weight, 10)
        }
    }

    // MARK: - Activity selection

    /// Commits the year's spare-time slot to practising `sport` (any Activities
    /// discipline): bumps its soft skills now and registers it in
    /// `selectedActivities` (slot accounting) plus `selectedSports`
    /// (type-safe selection). Year-end (`advanceYear`) banks the year into
    /// `sportYears` for the unlocked-competition gate and the win-odds bonus.
    func selectSport(_ sport: Sport, into selectedActivities: inout Set<String>, sports: inout Set<Sport>) {
        guard !sports.contains(sport) else { return }
        sports.insert(sport)
        selectedActivities.insert(sport.label)
        applySkillBoosts(sport.abilities)
    }

    // MARK: - Professional events & network

    /// Takes the stage at a professional event, applying its soft-skill nudges
    /// and banking its network points in the event's industry. The fame award
    /// presenting earns is deferred to `advanceYear` with the rest of the
    /// year-end accounting.
    func attendEvent(_ event: CareerEvent, into selectedEvents: inout Set<String>) {
        guard !selectedEvents.contains(event.id) else { return }
        // Taking the stage needs the veteran gate in this event's field
        // (safety net; the view locks these rows too).
        guard event.canPresent(with: experience) else { return }
        selectedEvents.insert(event.id)
        applySkillBoosts(event.abilities)
        networkByCategory[event.category, default: 0] += event.networkPoints
    }

    /// Years of work experience that count toward roles in `category`: the years
    /// banked directly in that industry plus any years in industries it credits
    /// (see `JobCategory.creditedExperienceCategories`). This is how
    /// entrepreneurship experience — whether from running a founder venture or
    /// from spare-time entrepreneurship projects — counts toward Business roles,
    /// and vice versa.
    func industryExperience(for category: JobCategory) -> Int {
        category.creditedYears(in: experience)
    }

    /// Every year the player has worked, in any field. Spare-time projects lean
    /// on this rather than on one industry: a working life teaches you to finish
    /// things, whatever the job was (see `SideHustle.experienceFit`).
    var totalExperienceYears: Int {
        experience.values.reduce(0, +)
    }

    /// Total professional-network points relevant to a field, built by taking
    /// the stage at its events.
    func networkPoints(for category: JobCategory) -> Int {
        networkByCategory[category, default: 0]
    }

    /// Additive boost to a job's realistic-mode hire probability from the
    /// player's network in that field. Diminishing — each point adds 1.5% up to
    /// a 0.12 ceiling, so a network helps without ever guaranteeing an offer.
    func networkBonus(for category: JobCategory) -> Double {
        min(0.12, Double(networkPoints(for: category)) * 0.015)
    }

    /// Additive hire/founder-probability lift from the player's skill-building
    /// trainings relevant to `category` — the coding/game-dev/design/performing
    /// programs (see `Training.careerBoost`). Credentials don't stack: the single
    /// strongest relevant one applies, so a shelf full of certificates isn't a
    /// shortcut. Zero for the licence-style trainings, which gate rather than nudge.
    func trainingCareerBonus(for category: JobCategory) -> Double {
        hardSkills.trainings
            .compactMap(\.careerBoost)
            .filter { $0.categories.contains(category) }
            .map(\.weight)
            .max() ?? 0.0
    }

    /// Additive boost to the annual promotion probability from the player's
    /// network in their current field. Smaller than the hiring bonus (0.6% per
    /// point, capped at 0.05) — knowing the right people helps you move up, but
    /// performance (soft skills) still carries most of the weight.
    func networkPromotionBonus(for category: JobCategory) -> Double {
        min(0.05, Double(networkPoints(for: category)) * 0.006)
    }

    /// Additive boost to the annual promotion probability from the player's fame
    /// in their current field. A *significant* lever — 3% per weighted point up
    /// to a 0.15 ceiling, three times the network bonus's reach — because a known
    /// name is first in line for the next rung, especially the senior ones.
    func famePromotionBonus(for category: JobCategory) -> Double {
        min(0.15, famePoints(for: category.fameCategory) * 0.03)
    }

    // MARK: - Training purchase / refund

    /// Enrols in this year's training: consumes the training slot and earns the
    /// credential (committed at year end). Once the hard requirements are met the
    /// course is assumed to be passed — students who put in the year pass the exam
    /// — so there's no roll. Completing the course also nudges the transferable
    /// soft skills it builds (see `Training.softSkillBoosts`), capped at 10.
    /// Returns whether enrolment succeeded.
    @discardableResult
    func attemptTraining(_ training: Training, into selectedTrainings: inout Set<Training>, activities selectedActivities: inout Set<String>) -> Bool {
        guard case .ok = training.requirements(self) else { return false }
        guard !selectedTrainings.contains(training) else { return false }
        selectedActivities.insert("training:\(training.rawValue)")
        selectedTrainings.insert(training)
        applySkillBoosts(training.softSkillBoosts)
        return true
    }

    // MARK: - Promotion

    /// The per-term breakdown behind `promotionChance`, so the UI can explain the
    /// odds the same way the hire-probability InfoHint does. `promotes` is false
    /// for unskilled roles that never promote in place (all other terms zero).
    struct PromotionOdds {
        let promotes: Bool
        /// 0...1: skill fit for the role held — how well you do the job.
        let performance: Double
        /// 0...1: skill fit for the next rung — how ready you are for the job
        /// above. Equal to `performance` at the top of a ladder, where a raise is
        /// judged on the job you already do.
        let readiness: Double
        /// 0...1: time in the role against `GameConstants.promotionSeniorityYears`.
        let seniority: Double
        let tenureYears: Int
        /// The rung above, when the ladder has one.
        let nextRole: Job?
        /// The industry's weights for the three merit terms.
        let culture: (performance: Double, readiness: Double, seniority: Double)
        /// The merit terms, weighted by the industry and scaled into a chance.
        let merit: Double
        let network: Double
        let fame: Double
        /// The industry's climate this year, whose `promotionDelta` is folded
        /// into `total` (and which zeroes it outright in a slump).
        let climate: IndustryClimate
        /// Formal education measured against what the role expects — negative
        /// while under-credentialled (see `Job.educationPromotionTerm`).
        let education: Double
        let total: Double
    }

    /// The next rung of `job`'s ladder in this year's postings, if it has one.
    /// Requirements aren't checked — this is the role the player is measured
    /// against, not a guarantee they can step into it.
    func nextRung(after job: Job) -> Job? {
        availableJobs.first { $0.baseTitle == job.baseTitle && $0.rung == job.rung + 1 }
    }

    /// Full breakdown of the annual promotion odds for `job`. Single source of
    /// truth for both `promotionChance` and the Occupation section's hint.
    ///
    /// Merit is three things, weighted the way the job's industry weighs them
    /// (`Industry.promotionCulture`): **performance** in the role held (skill fit
    /// for it), **readiness** for the next rung (skill fit for the role above —
    /// where the leadership and planning a ladder adds begin to count), and
    /// **seniority**. A civil servant climbs mostly on years served; a
    /// consultant mostly on already working at the next level.
    func promotionOdds(for job: Job) -> PromotionOdds {
        let culture = job.industry.promotionCulture
        let climate = self.climate(for: job.industry)
        let years = experienceByRole[job.baseTitle, default: 0]
        // Unskilled jobs don't promote in place — in real life a raise-and-title
        // bump rarely lands in work needing no post-secondary training; the
        // player advances by applying upward instead.
        // Founders aren't promoted: their pay moves with the business — its age,
        // its market and its luck (see `advanceVenture`).
        guard !job.isLowSkilled, !job.isEntrepreneurial else {
            return PromotionOdds(promotes: false, performance: 0, readiness: 0, seniority: 0,
                                 tenureYears: years, nextRole: nil, culture: culture, merit: 0,
                                 network: 0, fame: 0, climate: climate, education: 0, total: 0)
        }
        let next = nextRung(after: job)
        let performance = job.softSkillFit(for: self)
        let readiness = next?.softSkillFit(for: self) ?? performance
        let seniority = min(1.0, Double(years) / Double(GameConstants.promotionSeniorityYears))
        let weighted = culture.performance * performance
            + culture.readiness * readiness
            + culture.seniority * seniority
        let floor = GameConstants.promotionMeritFloor
        let merit = GameConstants.promotionMeritChance * (floor + (1 - floor) * weighted)

        let network = networkPromotionBonus(for: job.category)
        let fame = famePromotionBonus(for: job.category)
        // Formal education against what the role expects. Being hired without
        // the qualification is possible outside the regulated professions, but
        // it holds back the climb until you go and earn it.
        let education = job.educationPromotionTerm(for: self)
        // What the industry is doing. A contracting field freezes raises outright
        // — which is what the blanket recession freeze used to do to every field
        // at once, now scoped to the industries actually in trouble.
        let total = climate.freezesRaises
            ? 0
            : max(0, min(1.0, merit + network + fame + education + climate.promotionDelta))
        return PromotionOdds(promotes: true, performance: performance, readiness: readiness,
                             seniority: seniority, tenureYears: years, nextRole: next,
                             culture: culture, merit: merit, network: network, fame: fame,
                             climate: climate, education: education, total: total)
    }

    /// Annual promotion probability for a job — see `promotionOdds` for the
    /// terms: industry-weighted merit (performance, readiness for the next rung,
    /// seniority), plus network, fame, education and the industry's climate.
    func promotionChance(for job: Job) -> Double {
        promotionOdds(for: job).total
    }

    // MARK: - Year progression

    func advanceYear(appUIState: AppUIState) {
        // Past the horizon there are no more years to live: the score is final,
        // so nothing may change it. Belt and braces — the UI also stops offering
        // the controls that would get here.
        guard !hasRetired else {
            appUIState.showRetirementSheet = true
            return
        }
        // The life stage the year was *lived* in, captured before the birthday:
        // competitions entered this year resolve against it, so a 17-year-old's
        // junior season doesn't get judged by adult-stage rules.
        let competedStage = LifeStage.forAge(age)
        // Read before the birthday: the age-18 transition in `RootView` ends
        // high school, and the year just lived still needs its grade.
        let wasInHighSchool = currentEducation?.level == .HighSchool
        age += 1
        lastPromotionRaisePct = 0
        lastCompetitionWins = 0
        showCompetitionWinAlert = false
        competitionWinMessage = ""
        lostJobThisYear = false

        let newTrainings = appUIState.selectedTrainings.subtracting(hardSkills.trainings)
        hardSkills.trainings.formUnion(appUIState.selectedTrainings)
        for training in newTrainings {
            recordStatus(training.isStatutory ? "🪪" : "📜", "Earned \(training.friendlyName)")
        }

        // Bank the year's sport training. Each sport practised adds one to
        // `sportYears`, which gates the matching Competitions and adds to the
        // sport-fit bonus inside `Competition.winProbability`. The set is
        // captured first so the competition loop below can compete in exactly
        // the sport(s) trained this year.
        let competedSports = appUIState.selectedSports
        for sport in competedSports {
            sportYears[sport, default: 0] += 1
        }
        lastYearSports = competedSports

        // The school year's grade — high school only, since that's the record
        // universities read. A Study activity this year lifts it.
        if wasInHighSchool {
            let grade = yearGrade(studied: competedSports.contains { $0.kind == .study })
            highSchoolGrades.append(grade)
            recordStatus("📝", "Finished the school year with a \(Player.letterGrade(grade)) (\(Player.formatGPA(grade)))")
        }
        appUIState.selectedSports.removeAll()

        lockedTrainings.formUnion(appUIState.selectedTrainings)
        // This year's picks are now permanent (hard skills + locked); clear the
        // pending set so next year starts fresh, mirroring activities/events.
        appUIState.selectedTrainings.removeAll()

        appUIState.selectedActivities.removeAll()
        // Events applied their network/soft-skill effects when attended. Bank the
        // fame award each presenter role earns, then clear this year's picks.
        for id in appUIState.selectedEvents {
            guard let event = EventCatalog.byId[id] else { continue }
            award(event.presenterFameTitle, icon: event.icon,
                  category: event.category.fameCategory, weight: event.presenterFameWeight)
            recordStatus("🎤", "Presented at \(event.name)")
        }
        appUIState.selectedEvents.removeAll()

        // Charge tuition for the year the player is enrolled in a tertiary
        // program. Simplified mode is money-free where school is concerned —
        // education costs are hidden, so nothing is deducted.
        // The year just lived was at `age - 1`: an under-18 player never pays
        // or takes on debt (they can't legitimately be enrolled in tertiary
        // study anyway — this is the model-level guarantee of that rule).
        if !isSimplified,
           age - 1 >= GameConstants.minimumTertiaryAge,
           let edu = currentEducation,
           let yearsLeft = appUIState.yearsLeftToGraduation,
           yearsLeft > 0,
           edu.profile != nil {
            // Pay what savings allow; borrow the rest as a student loan that
            // accrues interest and is repaid later (see the servicing below), so
            // reaching for a pricey degree with no means is a lasting cost rather
            // than a free negative balance.
            let tuition = edu.annualTuition
            let fromSavings = min(max(0, savings), tuition)
            savings -= fromSavings
            let borrowed = tuition - fromSavings
            if borrowed > 0 {
                studentLoan += borrowed
                studentLoanPayment = Player.annualLoanPayment(
                    balance: studentLoan, rate: GameConstants.studentLoanAnnualInterest)
            }
        }

        appUIState.yearsLeftToGraduation? -= 1
        if appUIState.yearsLeftToGraduation == 0 {
            if let currentEducation {
                degrees.append(currentEducation)
                recordStatus("🎓", "Graduated — \(currentEducation.degreeName)")
                graduationMessage = graduationMessage(for: currentEducation)
                showGraduationAlert = true
            }
            appUIState.yearsLeftToGraduation = nil
            currentEducation = nil
        }

        executiveActionsThisYear.removeAll()
        // Re-roll the job market for the new year (fresh tiers and salaries).
        regenerateAvailableJobs()

        // Economic turmoil (realistic mode only): a downturn can cost the player
        // their current job and freezes hiring at unstable employers. An ongoing
        // (prolonged) recession keeps running; otherwise this year may trigger a
        // new one, whose odds and likelihood of dragging on depend on difficulty.
        // Tracks whether the economy is in a downturn this year; promotions freeze
        // while it is — employers don't hand out raises in a recession.
        var recessionThisYear = false
        if !isSimplified {
            if turmoilYearsRemaining > 0 {
                turmoilYearsRemaining -= 1
                recessionThisYear = true
                applyEconomicTurmoil()
            } else if Double.random(in: 0...1) < difficulty.turmoilChance {
                recessionThisYear = true
                if Double.random(in: 0...1) < difficulty.prolongedTurmoilChance {
                    turmoilYearsRemaining = Int.random(in: GameConstants.prolongedTurmoilExtraYears)
                }
                applyEconomicTurmoil()
            }
        }
        economyInRecession = recessionThisYear

        // Roll the industry cycle. Simplified mode has no economy at all, so its
        // industries stay neutral and every climate term reads 1.0 / 0.0.
        if !isSimplified {
            advanceIndustryTrends(recession: recessionThisYear)
            // Postings dry up in a contracting field — the industry-scoped
            // version of the blanket cyclical-sector freeze this replaces.
            availableJobs = availableJobs.filter { !climate(for: $0.industry).freezesRaises }
        }

        // Investment growth (realistic mode only): the accumulated balance
        // compounds each year at a market-like return, whether or not the player
        // is employed. Skipped while in the red — no returns on a negative balance.
        if !isSimplified, savings > 0 {
            savings += Int((Double(savings) * GameConstants.investmentReturn).rounded())
        }

        // Bank the year's pay and experience — skipped if a layoff just cleared
        // the occupation, since an unemployed year earns nothing. Realistic mode
        // saves only the personal-saving-rate share of income (the rest is taxes
        // and living costs); simplified mode banks the whole paycheck.
        // Loan instalments are a fixed bill, not a saving: they come out of pay
        // first (up to the debt-service ceiling), and only what's left is
        // subject to the saving rate. The set-aside is spent in the servicing
        // below.
        var incomeForLoans = 0
        if let job = currentOccupation {
            incomeForLoans = isSimplified ? 0 : min(
                loanInstalmentsDue,
                Int((Double(job.annualIncome) * GameConstants.maxDebtServiceShare).rounded())
            )
            let saved = isSimplified
                ? job.annualIncome
                : Int((Double(job.annualIncome - incomeForLoans) * difficulty.savingsRate).rounded())
            savings += saved
            experience[job.category, default: 0] += 1
            experienceByRole[job.baseTitle, default: 0] += 1
            // A year running your own venture builds commercial/founder acumen on
            // top of the trade itself, so a CEO year also banks entrepreneurship
            // experience — which credits Business roles (see industryExperience).
            if job.isEntrepreneurial, job.category != .entrepreneurship {
                experience[.entrepreneurship, default: 0] += 1
            }

            // Promotion (realistic mode): a yearly shot at a raise, its odds set
            // by industry-weighted merit (performance, readiness, seniority) plus
            // network, fame and education — see `promotionOdds`.
            // A win bumps pay and fires the celebration confetti. Frozen during a
            // downturn — no raises while the economy is in a recession.
            if !isSimplified, !recessionThisYear, let current = currentOccupation {
                let odds = promotionChance(for: current)
                if Double.random(in: 0...1) < odds {
                    // Prefer a real rung change: step to the next rung of the
                    // same ladder, provided the player now meets its full
                    // requirements (degree, credential, and the tenure just
                    // banked). Only fall back to an in-place merit raise when
                    // there's no rung above, or the player doesn't yet meet its
                    // bar. The ladder declares its own order, so "the next rung"
                    // is a single unambiguous job. Read off this year's postings
                    // (regenerated above, and unpruned since promotions are
                    // frozen in a recession) so the rung pays what its posting
                    // advertises.
                    let base = current.baseTitle
                    let nextIndex = current.rung + 1
                    var nextRung = availableJobs.first {
                        $0.baseTitle == base && $0.rung == nextIndex
                            && $0.allRequirementsMet(for: self)
                    }

                    // C-suite scarcity: taking an executive seat clears one more
                    // competitive hurdle — there are few of them and many contenders.
                    // Miss it and you keep climbing, banking an in-place raise this
                    // year instead of the title (founders make their own seat, exempt).
                    if let candidate = nextRung, candidate.isExecutive, !candidate.isEntrepreneurial,
                       Double.random(in: 0...1) >= executiveSeatChance {
                        nextRung = nil
                    }

                    // Never a pay cut on a promotion: take the higher of the new
                    // rung's pay and a raise on the current salary. With no rung
                    // to move into, the raise applies in place.
                    let raise = Double.random(in: GameConstants.promotionRaise)
                    let raised = Int((Double(current.annualIncome) * (1 + raise)).rounded())
                    var promoted = nextRung ?? current
                    promoted.annualIncome = max(promoted.annualIncome, raised)
                    currentOccupation = promoted
                    lastPromotionRaisePct = current.annualIncome > 0
                        ? max(0, Int((((Double(promoted.annualIncome) / Double(current.annualIncome)) - 1) * 100).rounded()))
                        : 0
                    celebrateIfLucky(odds)
                    showPromotionAlert = true
                    if nextRung != nil {
                        promotionMessage = "You've been promoted to \(promoted.displayTitle) — \(promoted.annualIncome.formatted(.number)) $ a year."
                        recordStatus("⬆️", "Promoted to \(promoted.id)")
                    } else {
                        promotionMessage = "You got a raise — +\(lastPromotionRaisePct)%, now \(promoted.annualIncome.formatted(.number)) $ a year."
                        recordStatus("⬆️", "Promoted in \(current.baseTitle) — pay +\(lastPromotionRaisePct)%")
                    }
                }
            }

            // A founder's year (realistic mode): the business may fold, may —
            // rarely — break out, and otherwise earns next year's income.
            if !isSimplified, job.isEntrepreneurial {
                advanceVenture(job, recession: recessionThisYear)
            }
        }

        // Spare-time projects. Nothing is staked but the year, and nothing is
        // locked: any project can be attempted at any time, and the odds —
        // talent fit plus the working life behind it, see
        // SideHustle.successProbability — carry the whole decision.
        //
        // The year's two payoffs come apart. Soft-skill growth is unconditional:
        // a year spent writing, building or performing sharpens the same axes
        // whether or not anyone notices, and those founder-cluster axes are ones
        // no hobby can build. Recognition is what the roll is for — only a hit
        // banks an industry-scoped fame award. So a flop still moves the player
        // forward, just quietly. All are repeatable year after year.
        lastYearProjectPay = 0
        for id in appUIState.selectedSideHustles {
            guard let hustle = SideHustleCatalog.byId[id], canTakeProject(hustle) else { continue }
            // A year committed to an experience-building venture (the
            // entrepreneurship plays) counts as real work experience in its
            // field — banked whether or not the venture pays off, because the
            // reps happen either way. Because Business credits entrepreneurship
            // (see `JobCategory.creditedExperienceCategories`), this also moves
            // the player toward Business roles. The odds are read *before* the
            // increment, so this year's attempt rolls against the career the
            // player brought into it.
            let fieldYears = hustle.experienceCategory.map { industryExperience(for: $0) } ?? 0
            let careerYears = totalExperienceYears
            if let cat = hustle.experienceCategory {
                experience[cat, default: 0] += 1
                recordStatus("📅", "Banked a year of \(cat.rawValue) experience running \(hustle.label)")
            }
            // Reputation compounds inside its own bucket: a name made shipping
            // software opens the next software project, and does nothing for a
            // record. The bucket-scoped figure is the one hiring already uses,
            // so a fame point means the same thing everywhere it's read.
            let outcome = hustle.resolve(for: softSkills,
                                         famePoints: famePoints(for: hustle.fameCategory),
                                         totalExperienceYears: careerYears,
                                         fieldExperienceYears: fieldYears,
                                         climate: projectClimate(for: hustle))
            // The practice lands either way — applied before the roll is read,
            // so nothing about the outcome can gate it.
            for ability in hustle.growth {
                softSkills[keyPath: ability.keyPath] = min(softSkills[keyPath: ability.keyPath] + ability.weight, 10)
            }
            if outcome.success {
                // Fame pays: the project's earnings, banked like any income.
                if outcome.pay > 0 {
                    lastYearProjectPay += outcome.pay
                    savings += isSimplified
                        ? outcome.pay
                        : Int((Double(outcome.pay) * difficulty.savingsRate).rounded())
                    recordStatus("💵", "\(hustle.label) paid \(outcome.pay.formatted(.number)) $")
                }
                if let grant = outcome.grantedFame {
                    award(grant.title, icon: hustle.icon, category: grant.category, weight: grant.weight)
                    recordStatus("🌟", "\(hustle.label) earned fame in \(grant.category.rawValue)")
                }
                // A landed project is worth the confetti whatever the odds were —
                // it cost a year of the player's life to find out.
                celebrate()
            } else {
                recordStatus(hustle.icon, "\(hustle.label) didn't land — but the practice counts")
            }
            reportProjectOutcome(outcome)
        }
        appUIState.selectedSideHustles.removeAll()

        // Endorsements: a famous entertainment name is paid to carry brands,
        // year in, year out — on top of whatever else the year earned.
        lastYearEndorsements = endorsementIncome
        if lastYearEndorsements > 0 {
            savings += isSimplified
                ? lastYearEndorsements
                : Int((Double(lastYearEndorsements) * difficulty.savingsRate).rounded())
        }

        // Competitions: practising a discipline automatically enters you into
        // its top eligible contest — no menu, no entry fee. Win odds start low
        // and climb with the trained years (and the soft skills training builds).
        // A win pays no money — it banks a lasting achievement (fame in the
        // discipline's own bucket: an athlete's in Entertainment, a coder's in
        // Technology) and surfaces a celebration dialog.
        var competitionWins = 0
        for sport in competedSports {
            let years = sportYears[sport, default: 0]
            guard let competition = CompetitionCatalog.bestCompetition(
                forSport: sport, stage: competedStage, years: years
            ) else { continue }
            let odds = competition.winProbability(for: softSkills, years: years)
            if Double.random(in: 0...1) < odds {
                award(competition.achievement, icon: competition.icon,
                      category: sport.fameCategory, weight: competition.fameWeight)
                competitionWins += 1
                celebrateIfLucky(odds)
                recordStatus("🏆", "Won \(competition.achievement)")
                competitionWinMessage = "You won the \(competition.name) and earned the “\(competition.achievement)” title!"
                showCompetitionWinAlert = true
            }
        }
        lastCompetitionWins = competitionWins

        // Service the loans: interest accrues, then the year's instalment is
        // paid from the income set aside for it, then from savings. A folded
        // venture still owes — the debt outlives the business — and whatever
        // can't be paid stays owed and keeps accruing.
        if serviceLoan(&outstandingLoan, payment: &ventureLoanPayment,
                       rate: GameConstants.ventureLoanAnnualInterest, income: &incomeForLoans) {
            recordStatus("🏦", "Paid off your venture loan")
        }
        if serviceLoan(&studentLoan, payment: &studentLoanPayment,
                       rate: GameConstants.studentLoanAnnualInterest, income: &incomeForLoans) {
            recordStatus("🎓", "Paid off your student loan")
        }
        // Any set-aside the instalments didn't need is ordinary pay again.
        savings += Int((Double(incomeForLoans) * difficulty.savingsRate).rounded())

        // The year just lived may have been the last one. Raise the Game Over
        // sheet after everything else has settled, so the final score already
        // includes this year's pay, growth and loan servicing.
        if hasRetired {
            recordStatus("🎂", "Reached \(GameConstants.retirementAge) — career over")
            appUIState.showRetirementSheet = true
        }
    }

    /// Resolves an economic downturn for the year: pulls risky offers from the
    /// market and rolls the player's current job against the base job-loss risk.
    /// The downturn is surfaced to the player only through the header recession
    /// note (see `economyInRecession`), not a pop-up.
    private func applyEconomicTurmoil() {
        // Postings are pulled by industry rather than by a blanket cyclical-sector
        // rule now — see the climate filter in `advanceYear`, which runs after the
        // trends are rolled and so knows which fields are actually contracting.
        guard currentOccupation != nil else { return }
        // Founders own their business — they aren't laid off. A downturn still
        // squeezes them elsewhere (frozen hiring/raises, and thinner odds of
        // finding a buyer if they try to sell their stake in the Boardroom).
        if currentOccupation?.isEntrepreneurial == true { return }
        // Job-loss probability is the calm-economy base risk amplified by how
        // severe the downturn is on this difficulty (e.g. 0.08 × 6, capped).
        let lossChance = min(
            GameConstants.turmoilMaxLayoffChance,
            GameConstants.baseLayoffRisk * difficulty.layoffSeverity
        )
        if Double.random(in: 0...1) < lossChance {
            let lost = currentOccupation
            currentOccupation = nil
            lostJobThisYear = true
            showLayoffAlert = true
            if let lost {
                recordStatus("💼", "Laid off from \(lost.baseTitle)")
            }
        }
    }

    /// Applies for admission to a school — a roll in every mode. Records the
    /// attempt (one per school per year) and returns whether the player was
    /// admitted, celebrating a place won against long odds. The caller performs
    /// enrollment on success.
    @discardableResult
    func applyToSchool(_ education: Education) -> Bool {
        let odds = education.admissionProbability(player: self)
        guard Double.random(in: 0...1) < odds else { return false }
        celebrateIfLucky(odds)
        return true
    }

    /// Applies for a job at the given salary. Returns true if hired.
    /// Side effects: marks the job as applied; if hired, sets currentOccupation with the agreed salary.
    @discardableResult
    func applyForJob(_ job: Job, requestedSalary: Int) -> Bool {
        let probability = job.hireProbability(for: self, requestedSalary: Double(requestedSalary))
        let hired = Double.random(in: 0...1) < probability
        if hired {
            var hiredJob = job
            hiredJob.annualIncome = requestedSalary
            currentOccupation = hiredJob
            recordStatus("💼", "Hired as \(hiredJob.baseTitle) — \(requestedSalary.formatted(.number)) $/year")
        }
        return hired
    }

    /// Launches a venture with `investedCapital` staked. Savings fund the stake
    /// first; any shortfall (up to `maxVentureLoan`) is borrowed and booked as
    /// an `outstandingLoan` that must be repaid whatever happens to the business.
    ///
    /// The business always opens — nearly every real one does. What preparation
    /// (industry experience, skill fit, capital, credentials, the market; see
    /// `Job.founderSuccessProbability`) decides is how well it *survives*: the
    /// yearly fold risk and, for a scalable venture, the breakout chance (see
    /// `advanceVenture`). Year one pays a fraction of the full income while the
    /// business finds its customers. Returns false only when refused outright
    /// (a minor, or nothing to stake).
    @discardableResult
    func foundVenture(_ job: Job, investedCapital: Int) -> Bool {
        // Staking capital — and borrowing — is an adult play: an under-18
        // player can never pay money or go into debt. The footer hides
        // Ventures until then; this is the model-level guarantee.
        guard age >= GameConstants.minimumEntrepreneurAge else { return false }
        // A stake of nothing is the one thing that closes a venture outright —
        // capital is the only hard requirement.
        let stake = min(max(0, investedCapital), maxVentureStake)
        guard stake > 0 else { return false }
        let borrowed = borrowedPortion(ofStake: stake)
        let preparation = founderPreparation(for: job, stake: stake)
        savings -= (stake - borrowed)          // spend savings first
        if borrowed > 0 {
            outstandingLoan += borrowed        // the rest is a loan
            ventureLoanPayment = Player.annualLoanPayment(
                balance: outstandingLoan, rate: GameConstants.ventureLoanAnnualInterest)
            recordStatus("🏦", "Borrowed \(borrowed.formatted(.number)) $ to fund your venture")
        }

        let previous = currentOccupation
        clearVenture()
        ventureFoundedAge = age
        venturePreparation = preparation
        ventureStake = stake
        ventureMatureIncome = job.annualIncome
        var venture = job
        venture.annualIncome = Int((Double(job.annualIncome) * Player.ventureRamp(year: 1)).rounded())
        currentOccupation = venture             // the venture is now the player's job
        if let previous, previous.id != job.id {
            recordStatus("🚪", "Left \(previous.baseTitle) to go all-in on your venture")
        }
        recordStatus("🚀", "Founded \(job.baseTitle) — you're now CEO")
        return true
    }

    /// One year-end for a running venture: the fold roll on the survival curve
    /// (with a share of the stake recovered if it folds), then — for a scalable
    /// venture — the breakout roll, then next year's income: the ramp while the
    /// business is young, times the industry's climate, times a random swing.
    private func advanceVenture(_ job: Job, recession: Bool) {
        let year = max(1, ventureYears)
        let foldRisk = min(
            GameConstants.ventureMaxFailureRisk,
            Player.ventureFoldRisk(year: year, preparation: venturePreparation)
                * (recession ? difficulty.layoffSeverity : 1.0)
        )
        if Double.random(in: 0...1) < foldRisk {
            let recovered = Int((Double(ventureStake) * GameConstants.ventureFoldRecovery).rounded())
            savings += recovered
            currentOccupation = nil
            clearVenture()
            showVentureFailureAlert = true
            ventureFailureMessage = "\(job.baseTitle) folded this year. Selling off what was left recovered \(recovered.formatted(.number)) $ of your stake — but any loan must still be repaid."
            recordStatus("📉", "\(job.baseTitle) folded — recovered \(recovered.formatted(.number)) $")
            // A fold costs no reputation — the lessons count for something.
            award("Founder's Lessons", icon: "📚", category: .business, weight: GameConstants.founderFoldFame)
            return
        }

        // Another year in business builds the founder's name.
        award("Founder of \(job.baseTitle)", icon: job.icon, category: .business, weight: GameConstants.founderYearFame)

        let climate = self.climate(for: job.industry)
        if job.isScalableVenture, !ventureBrokeOut, year >= 2 {
            let boom = climate == .boom ? 1.5 : 1.0
            let chance = GameConstants.ventureBreakoutChance * (0.5 + venturePreparation) * boom
            if Double.random(in: 0...1) < chance {
                ventureBrokeOut = true
                ventureMatureIncome = Int((Double(ventureMatureIncome) * GameConstants.ventureBreakoutIncomeMultiple).rounded())
                award("Breakout Startup", icon: "🦄", category: job.industry.fameCategory ?? .business, weight: 2.0)
                recordStatus("🦄", "\(job.baseTitle) broke out — revenue tripled and your stake is worth a fortune")
                reportApplicationOutcome(
                    title: "🦄 Breakout!",
                    message: "\(job.baseTitle) took off: revenue tripled, and your stake is now worth many times more. Sell it in the Boardroom, or keep riding it."
                )
            }
        }

        let swing = Double.random(in: (1 - GameConstants.ventureIncomeSwing)...(1 + GameConstants.ventureIncomeSwing))
        let factor = Player.ventureRamp(year: year + 1) * climate.revenueFactor * swing
        var venture = job
        venture.annualIncome = max(0, Int((Double(ventureMatureIncome) * factor).rounded()))
        currentOccupation = venture
    }

    // MARK: - Executive decisions (Boardroom)

    /// Whether the player currently holds a seat that unlocks the Boardroom's
    /// equity/strategy plays (see `Job.isExecutive`). The Boardroom is part of
    /// the entrepreneurial/equity path (investment rounds, share sales) and
    /// leans on soft skills, fame, and the economy — all absent in Simplified —
    /// so it never unlocks there.
    var canMakeExecutiveDecisions: Bool {
        guard !isSimplified else { return false }
        return currentOccupation?.isExecutive ?? false
    }

    /// Whether the given decision has already been used this year (each plays
    /// once per year).
    func hasUsedExecutiveDecision(_ decision: ExecutiveDecision) -> Bool {
        executiveActionsThisYear.contains(decision.id)
    }

    /// Founder-cluster soft skills weighed when investors size up a round, with
    /// their share of the fit. A raise is won in the pitch, so persuasion leads;
    /// vision is what's being sold, and communication and leadership back it up.
    static let investmentRoundSkills: [(keyPath: WritableKeyPath<SoftSkills, Int>, weight: Double)] = [
        (\.persuasionAndNegotiation, 0.40),
        (\.visionaryThinkingAndAmbition, 0.25),
        (\.communicationAndNetworking, 0.20),
        (\.leadershipAndInfluence, 0.15),
    ]
    /// Skill level at which an investment-round axis is a perfect fit.
    private static let investmentRoundSkillReference = 8
    /// Per-point weight of business fame on an investment round, and its cap.
    /// Deliberately steep: raising capital turns on who the market has heard of,
    /// so a well-known founder's reputation is the single biggest swing after
    /// raw skill fit. Reaching the cap takes ~5 points of business (💼) fame.
    private static let investmentRoundFameRate = 0.11
    private static let investmentRoundFameCap = 0.55

    /// The player's business (💼) fame contribution to an investment round —
    /// exposed so the Boardroom can show how much of the odds reputation is
    /// carrying. Business fame is used regardless of the venture's own industry:
    /// a raise is a business-reputation play, so a famous tech founder and a
    /// famous retail founder both trade on the same 💼 renown.
    func investmentRoundFameBonus() -> Double {
        min(Player.investmentRoundFameCap,
            famePoints(for: .business) * Player.investmentRoundFameRate)
    }

    /// Probability (0.05...0.95) that an announced investment round closes. Built
    /// from the founder-cluster soft-skill fit, the player's network in their
    /// field, and — weighted heavily — their **business fame**: a known,
    /// well-connected founder with a compelling vision raises money far more
    /// reliably, and reputation is what most separates a closed round from a
    /// quarter wasted chasing term sheets.
    func investmentRoundOdds() -> Double {
        guard let job = currentOccupation else { return 0 }
        let fit = investmentRoundSkillFit()
        let network = networkBonus(for: job.category)   // up to +0.12
        let fame = investmentRoundFameBonus()           // up to +0.55 (business fame)
        return max(0.05, min(0.95, 0.12 + fit * 0.40 + network + fame))
    }

    /// 0...1 weighted fit of the pitch skills (see `investmentRoundSkills`).
    func investmentRoundSkillFit() -> Double {
        Player.investmentRoundSkills.reduce(0.0) { acc, entry in
            acc + entry.weight * min(Double(softSkills[keyPath: entry.keyPath]) / Double(Player.investmentRoundSkillReference), 1.0)
        }
    }


    /// Fair-market value of the player's equity stake — the anchor the Boardroom's
    /// asking-price slider is built around and the yardstick a buyer measures an
    /// offer against. Vested value grows with pay and tenure in the seat (~0.75×
    /// pay on day one up to a 2.5× cap).
    ///
    /// A founder's stake is priced off the business's full income rather than
    /// this year's swinging pay — small businesses sell for 2–3× owner earnings
    /// — and each investment round and a breakout multiply it.
    func shareStakeValue() -> Int {
        guard let job = currentOccupation else { return 0 }
        let years = job.isEntrepreneurial && ventureFoundedAge != nil
            ? ventureYears
            : experienceByRole[job.baseTitle, default: 0]
        var multiple = min(0.75 + Double(years) * 0.15, 2.5)
        var income = Double(job.annualIncome)
        if job.isEntrepreneurial, ventureMatureIncome > 0 {
            income = Double(ventureMatureIncome)
            multiple *= pow(GameConstants.investmentRoundValueGrowth, Double(ventureRoundsRaised))
            if ventureBrokeOut { multiple *= GameConstants.ventureBreakoutValueMultiple }
        }
        return Int((income * multiple).rounded())
    }

    /// Whether the player can take the company to investors: only a founder of
    /// a scalable venture — well under 1% of real businesses ever raise venture
    /// capital, and a restaurant isn't one of them.
    var canRaiseInvestmentRound: Bool {
        currentOccupation?.isScalableVenture == true
    }

    /// Bounds for the asking-price slider: a buyer will entertain anything from a
    /// half-price bargain up to 2.5× the fair valuation (beyond which no one
    /// bites). Returns `(min, fair, max)` so the view can seed the slider at fair.
    func shareAskingBounds() -> (min: Int, fair: Int, max: Int) {
        let fair = shareStakeValue()
        return (Int(Double(fair) * 0.5), fair, Int(Double(fair) * 2.5))
    }

    /// Probability (0.02...0.98) that a buyer takes the stake at `askPrice`.
    /// Buyers anchor on the fair valuation: price at or below fair and it sells
    /// readily; each step above fair steepens the odds of no takers (a logistic
    /// decay in the ask/fair ratio, centred a little above fair so a fair-priced
    /// stake still finds a buyer ~7 years in 10). A recession thins the buyer
    /// pool, dropping the odds across the board.
    func shareSaleOdds(askPrice: Int) -> Double {
        let fair = shareStakeValue()
        guard fair > 0 else { return 0 }
        let ratio = Double(askPrice) / Double(fair)
        let odds = 1.0 / (1.0 + exp(3.0 * (ratio - 1.3)))
        let economy = economyInRecession ? 0.55 : 1.0
        return max(0.02, min(0.98, odds * economy))
    }

    /// Resolves an executive decision immediately, applying its effects and
    /// returning the outcome for the Boardroom view to display. Marks the
    /// decision used for the year. No-op-ish (returns an empty failure) if the
    /// player somehow isn't in an executive seat.
    @discardableResult
    func resolveExecutiveDecision(_ decision: ExecutiveDecision, askPrice: Int? = nil) -> ExecutiveDecision.Outcome {
        executiveActionsThisYear.insert(decision.id)
        guard let job = currentOccupation else {
            return ExecutiveDecision.Outcome(decision: decision, success: false, cash: 0, fameTitle: nil)
        }
        switch decision.kind {
        case .sellShares:
            // A sale isn't a sure thing: the player names a price and the
            // market decides. Odds fall the higher they ask relative to the fair
            // valuation, and a recession thins the buyers.
            let ask = askPrice ?? shareStakeValue()
            let sold = Double.random(in: 0...1) < shareSaleOdds(askPrice: ask)
            guard sold else {
                recordStatus("🤝", "No buyer for your \(job.baseTitle) stake at \(ask.formatted(.number)) $ this year")
                return ExecutiveDecision.Outcome(decision: decision, success: false, cash: 0, fameTitle: nil)
            }
            savings += ask
            // An owner-founder who sells their stake exits the venture entirely —
            // the seat is gone, freeing them to start something new (and the
            // Ventures button returns). Ownership is what an entrepreneurial seat
            // means. A hired executive just cashes out vested equity, keeps their
            // seat, and can sell again in a later year.
            if job.isEntrepreneurial {
                currentOccupation = nil            // clears the venture state too
                // A successful exit is the strongest founder credential there is.
                award("Successful Exit", icon: decision.icon, category: .business, weight: GameConstants.founderExitFame)
                recordStatus(decision.icon, "Sold your stake in \(job.baseTitle) for \(ask.formatted(.number)) $ — exited the venture")
            } else {
                recordStatus(decision.icon, "Sold vested shares in \(job.baseTitle) for \(ask.formatted(.number)) $")
            }
            return ExecutiveDecision.Outcome(decision: decision, success: true, cash: ask, fameTitle: nil)
        case .investmentRound:
            let odds = investmentRoundOdds()
            let succeeded = Double.random(in: 0...1) < odds
            guard succeeded else {
                recordStatus("🚫", "Investment round for \(job.baseTitle) fell through")
                return ExecutiveDecision.Outcome(decision: decision, success: false, cash: 0, fameTitle: nil)
            }
            // The money goes into the company, not the founder's pocket: the
            // funded business grows (a bigger income it can pay) and the stake
            // is worth more even after the dilution the investors took.
            ventureRoundsRaised += 1
            ventureMatureIncome = Int((Double(ventureMatureIncome) * GameConstants.investmentRoundIncomeGrowth).rounded())
            var grown = job
            grown.annualIncome = Int((Double(job.annualIncome) * GameConstants.investmentRoundIncomeGrowth).rounded())
            currentOccupation = grown
            let title = "Raised a Round"
            // Closing a round is a business milestone: it banks business (💼)
            // fame, which in turn lifts the odds on the next round — a founder's
            // reputation compounds.
            award(title, icon: decision.icon, category: .business, weight: 1.5)
            let growthAxes: [WritableKeyPath<SoftSkills, Int>] =
                [\.visionaryThinkingAndAmbition, \.persuasionAndNegotiation]
            for kp in growthAxes {
                softSkills[keyPath: kp] = min(softSkills[keyPath: kp] + 1, 10)
            }
            celebrateIfLucky(odds)
            recordStatus(decision.icon, "Closed an investment round for \(job.baseTitle) — the company is worth more and can pay you more")
            return ExecutiveDecision.Outcome(decision: decision, success: true, cash: 0, fameTitle: title)
        }
    }

    func reset() {
        let fresh = Player()
        difficulty = fresh.difficulty
        avatar = fresh.avatar
        fameAwards = fresh.fameAwards
        lastCompetitionWins = fresh.lastCompetitionWins
        showCompetitionWinAlert = fresh.showCompetitionWinAlert
        competitionWinMessage = fresh.competitionWinMessage
        showVentureFailureAlert = fresh.showVentureFailureAlert
        ventureFailureMessage = fresh.ventureFailureMessage
        showApplicationOutcomeAlert = fresh.showApplicationOutcomeAlert
        applicationOutcomeTitle = fresh.applicationOutcomeTitle
        applicationOutcomeMessage = fresh.applicationOutcomeMessage
        showProjectOutcomeAlert = fresh.showProjectOutcomeAlert
        projectOutcomeTitle = fresh.projectOutcomeTitle
        projectOutcomeMessage = fresh.projectOutcomeMessage
        turmoilYearsRemaining = fresh.turmoilYearsRemaining
        economyInRecession = fresh.economyInRecession
        lastPromotionRaisePct = fresh.lastPromotionRaisePct
        showPromotionAlert = fresh.showPromotionAlert
        promotionMessage = fresh.promotionMessage
        showGraduationAlert = fresh.showGraduationAlert
        graduationMessage = fresh.graduationMessage
        statusEvents = fresh.statusEvents
        lostJobThisYear = fresh.lostJobThisYear
        showLayoffAlert = fresh.showLayoffAlert
        age = fresh.age
        softSkills = fresh.softSkills
        hardSkills = fresh.hardSkills
        degrees = fresh.degrees
        experience = fresh.experience
        experienceByRole = fresh.experienceByRole
        currentOccupation = fresh.currentOccupation
        currentEducation = fresh.currentEducation
        savings = fresh.savings
        outstandingLoan = fresh.outstandingLoan
        ventureLoanPayment = fresh.ventureLoanPayment
        lastYearProjectPay = fresh.lastYearProjectPay
        lastYearEndorsements = fresh.lastYearEndorsements
        studentLoanPayment = fresh.studentLoanPayment
        ventureFoundedAge = fresh.ventureFoundedAge
        venturePreparation = fresh.venturePreparation
        ventureStake = fresh.ventureStake
        ventureMatureIncome = fresh.ventureMatureIncome
        ventureRoundsRaised = fresh.ventureRoundsRaised
        ventureBrokeOut = fresh.ventureBrokeOut
        studentLoan = fresh.studentLoan
        lockedTrainings = fresh.lockedTrainings
        macroTrend = fresh.macroTrend
        industryIdiosyncratic = fresh.industryIdiosyncratic
        industryTrend = fresh.industryTrend
        networkByCategory = fresh.networkByCategory
        sportYears = fresh.sportYears
        lastYearSports = fresh.lastYearSports
        highSchoolGrades = fresh.highSchoolGrades
        executiveActionsThisYear = []
        availableJobs = fresh.availableJobs
    }
}

