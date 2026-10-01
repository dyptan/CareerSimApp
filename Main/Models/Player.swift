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
///
/// **Identity vs display.** `key` is the accolade's stable English name — the id
/// the game merges repeats on, looks up requirements by (`SideHustle.requiresAward`,
/// the job gates) and keeps in a save; it never changes. `title` is what the
/// player reads, looked up in the `Catalogue` string table as `fame.award.<key>`
/// (see `FameAward.title(forKey:)`). Compare awards by `key`, never by `title`.
struct FameAward: Identifiable, Hashable {
    let key: String
    let icon: String
    let category: FameCategory?
    let weight: Double
    var count: Int = 1

    var id: String { key }

    /// What the player reads for this accolade, in their language.
    var title: String { FameAward.title(forKey: key) }

    /// The key prefix of the per-venture accolade a founder banks each year
    /// ("Founder of Specialty Coffee Roastery").
    static let founderKeyPrefix = "Founder of "  // i18n:ignore award key prefix, not displayed

    /// The key of the accolade for running `venture` (a venture's `baseTitle`).
    static func founderKey(venture: String) -> String { founderKeyPrefix + venture }

    /// Whether `key` is one of the per-venture "Founder of …" accolades.
    static func isFounderKey(_ key: String) -> Bool { key.hasPrefix(founderKeyPrefix) }

    /// The display title for an accolade known by its English `key` — a trophy,
    /// a project's title, a founder credential. The one place award names are
    /// shown from; falls back to the key where there is no translation.
    static func title(forKey key: String) -> String {
        if isFounderKey(key) {
            let venture = Job.displayBaseTitle(forBaseTitle: String(key.dropFirst(founderKeyPrefix.count)))
            return L("Founder of \(venture)")
        }
        return L10n.catalogue("fame.award.\(key)", english: key)  // i18n:ignore catalogue key
    }

    /// Total reputation this shelf entry contributes: per-instance `weight`
    /// scaled by the square root of the times it's been earned. Repeating the
    /// same accolade still builds a name, but with diminishing returns — the
    /// tenth season of club gigs is not ten times the first.
    var totalWeight: Double { weight * Double(count).squareRoot() }
}

final class Player: ObservableObject {
    /// The single difficulty choice the game runs under: how much complexity is
    /// in play (Simplified strips skills, tiers, negotiation, and the economy)
    /// plus, in Real Life, savings rate and economic volatility.
    /// Set from the launch picker.
    @Published var difficulty: Difficulty = .default
    /// Convenience: true when only the basic (degree + experience) rules apply.
    var isSimplified: Bool { difficulty.isSimplified }

    /// Where the player grows up: the currency, pay, school costs and living
    /// costs the game is priced in (see `Country`). Set from the launch picker,
    /// before the first postings are built.
    @Published var country: Country = .default

    /// An amount in the player's currency: "45.000 €".
    func money(_ amount: Int) -> String { country.money(amount) }

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
    /// `key` is the accolade's English name (see `FameAward.key`), not its display text.
    func award(_ key: String, icon: String, category: FameCategory?, weight: Double) {
        if let i = fameAwards.firstIndex(where: { $0.key == key }) {
            fameAwards[i].count += 1
        } else {
            fameAwards.append(FameAward(key: key, icon: icon, category: category, weight: weight))
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
    /// a higher cap (+0.50). See `Job.isTopLeadership` / `Job.hireBreakdown`.
    ///
    /// Only the field's own bucket counts — an executive seat no longer swaps in
    /// business fame as well, because a founder's record already eases the seat
    /// hurdle (`executiveTrackRecord`); counting it in both places made the
    /// same points pay twice.
    func fameHireBonus(for jobCategory: JobCategory, topPosition: Bool = false) -> Double {
        min(Player.fameHireCap(topPosition: topPosition),
            famePoints(for: jobCategory.fameCategory) * Player.fameHireRate(topPosition: topPosition))
    }

    /// Hire-odds lift per point of fame in the field, and the most it can add.
    /// A tie-breaker in hiring, not a substitute for the skills and credentials
    /// an employer screens on: at most +0.20 (+0.30 for a top seat, where
    /// reputation weighs more), against the skill term's 0.60. Shared with the
    /// advisor, which sizes how much more fame is still worth having.
    static func fameHireRate(topPosition: Bool) -> Double { topPosition ? 0.06 : 0.04 }
    static func fameHireCap(topPosition: Bool) -> Double { topPosition ? 0.30 : 0.20 }

    /// How much a founder's track record — years running ventures, rounds,
    /// exits, even a fold — eases the seat hurdle on a commercial executive
    /// seat (`Job.seatChance`): `executiveTrackRecordPerPoint` a point of
    /// business (💼) fame, up to `executiveTrackRecordCap`.
    var executiveTrackRecord: Double {
        min(GameConstants.executiveTrackRecordCap,
            founderTrackRecordPoints * GameConstants.executiveTrackRecordPerPoint)
    }

    /// Fame earned by actually founding and running companies — ventures run,
    /// folded, broken out, funded or sold. Boards hire operators with a P&L
    /// behind them, so a pitch-night slot or a crowdfunding campaign (business
    /// fame too) doesn't count here.
    var founderTrackRecordPoints: Double {
        fameAwards
            .filter { award in
                FameAward.isFounderKey(award.key) || Player.founderTrackRecordTitles.contains(award.key)
            }
            .reduce(0) { $0 + $1.totalWeight }
    }

    static let founderTrackRecordTitles: Set<String> = [
        "Founder's Lessons", "Breakout Startup", "Successful Exit", "Raised a Round",  // i18n:ignore award keys
    ]

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
    /// moves it, and a declared recession drags it down; otherwise it drifts
    /// gently upward (`expansionDrift` — growth is the economy's normal state)
    /// while reverting toward neutral, so no boom lasts forever. Then each
    /// sector's own deviation moves on the same pattern, scaled by its
    /// `volatility`.
    ///
    /// A sector's published trend is its share of the national cycle — its
    /// `beta` — plus that deviation. That is the whole model: one economy,
    /// transmitted unevenly, plus whatever is happening to each sector alone.
    func advanceIndustryTrends(recession: Bool) {
        let macroShock = Double.random(in: -GameConstants.macroTrendShock...GameConstants.macroTrendShock)
        let macroCycle = recession
            ? -GameConstants.recessionDrag
            : GameConstants.expansionDrift - macroTrend * GameConstants.industryMeanReversion
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
            return L("Congratulations! You finished \(degree.degreeName(in: country)) — \(country.schooling.gradeName): \(country.gradeLabel(highSchoolGPA)).")
        }
        return L("Congratulations! You completed your \(degree.degreeName(in: country)).")
    }

    /// The status-log line for finishing `degree`. Leaving school is the one
    /// moment the grade is reported: "Graduated — Abitur · Abitur grade 1.6 (good)".
    func graduationStatus(for degree: Education) -> String {
        if degree.level == .HighSchool {
            return L("Graduated — \(degree.degreeName(in: country)) · \(country.schooling.gradeName) \(country.gradeLabel(highSchoolGPA))")
        }
        return L("Graduated — \(degree.degreeName(in: country))")
    }

    // MARK: - School grades

    /// The grade earned in each high-school year completed, on the US 4.0
    /// scale — the game's internal scale in every country; players see it as
    /// their own (`Country.gradeLabel`). Recorded by `advanceYear`; averaged into `highSchoolGPA`, which
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
        Fmt.decimal(gpa)
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
    /// Body of the project result pop-up, naming the project and the title it earned.
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
            climate: projectClimate(for: hustle),
            age: age
        )
    }

    /// Whether the player holds the award a project requires (the star
    /// projects open only to a name the big break has made).
    func canTakeProject(_ hustle: SideHustle) -> Bool {
        guard let award = hustle.requiresAward else { return true }
        return fameAwards.contains { $0.key == award }
    }

    /// Yearly endorsement income: brands pay a famous entertainment name —
    /// athletes, stars and creators alike — to carry their products. Nothing
    /// below `GameConstants.endorsementFameThreshold`, then steeply rising.
    var endorsementIncome: Int {
        let fame = famePoints(for: .entertainment)
        guard fame >= GameConstants.endorsementFameThreshold else { return 0 }
        let pay = GameConstants.endorsementBase * pow(fame, GameConstants.endorsementFameExponent)
            * country.generalPayScale
        return min(Int(Double(GameConstants.endorsementMax) * country.generalPayScale), Int(pay.rounded()))
    }

    /// Gross pay last year from endorsements — shown in Finances next to the
    /// salary. (Projects pay nothing: they build fame and skills.)
    @Published var lastYearEndorsements: Int = 0

    /// The climate a project rides: its own industry when it has one, otherwise
    /// the average across the fame bucket it would make its name in.
    func projectClimate(for hustle: SideHustle) -> IndustryClimate {
        climate(forFame: hustle.fameCategory)
    }

    /// The status-log line for taking `event`'s stage: one whole sentence per
    /// stage role (the event's button verb), since the verb changes the grammar.
    private func presenterStatusLine(for event: CareerEvent) -> String {
        switch event.presenterActionLabel {
        case "Present": return L("Presented at \(event.name)")
        case "Perform": return L("Performed at \(event.name)")
        case "Appear":  return L("Appeared at \(event.name)")
        case "Speak":   return L("Spoke at \(event.name)")
        case "Compete": return L("Competed at \(event.name)")
        case "Demo":    return L("Demoed at \(event.name)")
        default:        return L("Took the stage at \(event.name)")
        }
    }

    /// Raises the result pop-up for a resolved spare-time project. Every project
    /// costs the year whether or not it lands, so the year always reports back —
    /// a flop names the odds it rolled against so a long shot reads as bad luck
    /// rather than a broken game. Kept short; the details live in the sheets.
    func reportProjectOutcome(_ outcome: SideHustle.Outcome) {
        let hustle = outcome.hustle
        let chance = Fmt.percent(outcome.odds)
        if outcome.success {
            projectOutcomeTitle = "\(hustle.icon) " + L("It landed!")
            if let grant = outcome.grantedFame {
                projectOutcomeMessage = L("\(hustle.label) worked out! You earned the “\(FameAward.title(forKey: grant.title))” title.")
            } else {
                projectOutcomeMessage = L("\(hustle.label) worked out!")
            }
        } else {
            projectOutcomeTitle = "\(hustle.icon) " + L("It didn't land")
            projectOutcomeMessage = L("\(hustle.label) didn't pan out — it was a \(chance) shot. You kept the practice: the skills it draws on improved anyway.")
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
    /// ("C-suite") role. Real Life sets no target, just a running
    /// `leaderboardScore` the player banks by finishing early or at
    /// `GameConstants.retirementAge`, whichever comes first (see
    /// `hasRetired` and `RetirementView`). Simplified keeps no score
    /// (`Difficulty.keepsScore`).
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
        // An interest-free loan (German student support) is repaid in equal
        // parts; the amortising formula would divide zero by zero.
        let payment = rate > 0 ? Double(balance) * rate / (1 - pow(1 + rate, -n)) : Double(balance) / n
        // Rounded up, so the loan is cleared within its term rather than
        // leaving a dollar of rounding behind.
        return Int(payment.rounded(.up))
    }

    /// One year of a loan: interest accrues, then the instalment is paid —
    /// from income set aside for it first, then from savings. Whatever can't be
    /// paid stays owed and keeps accruing. Returns true when the loan clears.
    private func serviceLoan(_ balance: inout Int, payment: inout Int, rate: Double, income: inout Int) -> Bool {
        guard balance > 0 else { return false }
        balance = Int((Double(balance) * (1 + rate)).rounded())
        let instalment = min(balance, payment > 0 ? payment : Player.annualLoanPayment(balance: balance, rate: rate))
        // Part from savings, part by spending less (`income` is what spending
        // can give up this year), then savings again for anything left.
        let fromSaved = min(Int((Double(instalment) * GameConstants.debtServiceFromSavingsShare).rounded()),
                            max(0, savings))
        savings -= fromSaved
        let fromIncome = min(instalment - fromSaved, income)
        income -= fromIncome
        let fromSavings = min(instalment - fromSaved - fromIncome, max(0, savings))
        savings -= fromSavings
        balance -= fromSaved + fromIncome + fromSavings
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
    var netWorth: Int { savings - outstandingLoan - studentLoan + heldEquityValue }

    /// Equity the player holds but hasn't sold, at what it would fetch: a
    /// running business at `privateEquityDiscount` of its stake value (illiquid,
    /// key-person risk, taxed on sale), a hired executive's vested shares after
    /// the income tax due on them. The Fed's SCF counts both in net worth.
    var heldEquityValue: Int {
        guard !isSimplified, let job = currentOccupation else { return 0 }
        if job.isEntrepreneurial {
            return Int((Double(shareStakeValue()) * GameConstants.privateEquityDiscount).rounded())
        }
        guard job.isExecutive else { return 0 }
        return Int((Double(shareStakeValue()) * (1 - GameConstants.equitySaleTaxRate)).rounded())
    }

    /// What a year's gross income (pay and endorsements) adds to
    /// savings: nothing below the mode's living-cost floor, `savingsRate` of
    /// the slice above it, and `highEarnerSavingsRate` of anything past
    /// `highEarnerThreshold`. A minor living at home has no floor. Simplified
    /// banks everything. One rule, read by the year's banking and the views.
    func annualSaving(gross: Int, atAge livedAge: Int) -> Int {
        guard gross > 0 else { return 0 }
        if isSimplified { return gross }
        let floor = livedAge < GameConstants.adultRoleAge ? 0 : livingCostFloor
        let threshold = country.highEarnerThreshold
        let base = max(0, min(gross, threshold) - floor)
        let top = max(0, gross - threshold)
        return Int((Double(base) * difficulty.savingsRate
                    + Double(top) * GameConstants.highEarnerSavingsRate).rounded())
    }

    /// A year's basic living costs in this mode and country — nothing is saved
    /// below it (`Difficulty.livingCostFloor(in:)`).
    var livingCostFloor: Int { difficulty.livingCostFloor(in: country) }

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
            // A new position — a hire, a promotion, a venture founded, or
            // leaving work — starts the clock in the role again. The same job
            // re-stated (a merit raise, a venture's new year of income) doesn't.
            if currentOccupation?.id != oldValue?.id {
                yearsInRole = 0
                equityVestedYears = 0
            }
        }
    }

    /// Full years banked in the current position — since the last hire,
    /// promotion or venture founded (reset by `currentOccupation`). Drives
    /// promotion seniority and being passed over (`promotionOdds`) and the step
    /// in the merit-raise schedule (`stepRaise`). Distinct from
    /// `experienceByRole`, which counts the whole ladder and never resets.
    @Published var yearsInRole: Int = 0

    /// Years of equity grants vested and not yet sold in a hired executive seat
    /// (see `shareStakeValue`). Grants vest a year at a time; selling realises
    /// them and the count starts again. Reset by a new position.
    @Published var equityVestedYears: Int = 0

    /// Consecutive years an adult has spent with no job and not enrolled in
    /// study — the length of the current spell out of work. A year worked, even
    /// one cut short by a layoff, or a year of study ends it. Drives
    /// `unemploymentHireMultiplier`.
    @Published var consecutiveUnemployedYears: Int = 0
    @Published var currentEducation: Education?
    @Published var savings: Int
    @Published var lockedTrainings: Set<Training>
    /// Professional network built at industry `CareerEvent`s, keyed by
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

    /// How the career advisor is coaching the player: the path they chose
    /// (a role in mind, or still exploring) and its yearly reviews. Reviewed
    /// at the end of every `advanceYear` (see `AdvisorCoach.checkIn`).
    @Published var advisorPlan = AdvisorPlan()

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
        self.availableJobs = JobCatalog.allJobs(in: .default).shuffled()
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
        availableJobs = JobCatalog.allJobs(in: country).shuffled()
    }

    /// Sets `age` and seeds the K-12 record to match a chosen starting age
    /// (7–18), so the player begins with the EQF level they'd have reached by
    /// then: each schooling stage already finished is banked as a degree, and
    /// the stage in progress (if any) becomes `currentEducation`. Mirrors the
    /// age-10/14/18 transitions in `RootView`. Returns true when the player
    /// starts old enough (18) that the post-high-school decision should fire.
    ///
    /// The years before a later start weren't played, so each leaves a random
    /// soft-skill boost (`seedSkippedYears`). Call it once per new game.
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
        seedSkippedYears(before: startAge)
        return startAge >= 18
    }

    /// The chance that the year lived at `age` — one a later start skipped —
    /// leaves a random skill boost: certain through school, then halving with
    /// each adult year (`GameConstants.skippedAdultYearFalloff`).
    static func skippedYearYield(atAge age: Int) -> Double {
        guard age >= GameConstants.skippedYearsFullValueBelowAge else { return 1 }
        return pow(GameConstants.skippedAdultYearFalloff,
                   Double(age - GameConstants.skippedYearsFullValueBelowAge + 1))
    }

    /// Starting at `startAge` skips the years from `GameConstants.startingAge`
    /// up to it. Each leaves `skippedYearSkillPoints` in one skill picked at
    /// random — any of them, not the ones a goal needs — so starting late is
    /// never a way round the early choices a narrow path is built on.
    private func seedSkippedYears(before startAge: Int) {
        guard startAge > GameConstants.startingAge else { return }
        for lived in GameConstants.startingAge..<startAge
        where Double.random(in: 0..<1) < Self.skippedYearYield(atAge: lived) {
            guard let axis = SoftSkills.allAxes.randomElement() else { continue }
            applySkillBoosts([WeightedAbility(keyPath: axis.keyPath, weight: GameConstants.skippedYearSkillPoints)])
        }
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

    /// Whether the player works in, has worked in, or is studying toward
    /// `category` — enough to get into its industry events.
    func isInField(_ category: JobCategory, studyProfiles: [TertiaryProfile]) -> Bool {
        if industryExperience(for: category) > 0 { return true }
        if currentOccupation?.category == category { return true }
        if let profile = currentEducation?.profile, studyProfiles.contains(profile) { return true }
        return false
    }

    /// Whether the player may take part in `event` at all: an adult in a
    /// realistic mode, in the event's field — or anyone, for an open call.
    func canJoinEvent(_ event: CareerEvent) -> Bool {
        guard !isSimplified, age >= GameConstants.minimumTertiaryAge else { return false }
        return event.isOpenCall || isInField(event.category, studyProfiles: event.studyProfiles)
    }

    /// The chance an application to take `event`'s stage is accepted: years in
    /// its field (full marks at `GameConstants.presenterExperienceYears`), how
    /// well the player communicates, and the fame they already have there. A
    /// newcomer is a long shot, a known veteran nearly always gets the slot.
    func presentOdds(_ event: CareerEvent) -> Double {
        let years = Double(industryExperience(for: event.category))
        let seniority = min(years / Double(GameConstants.presenterExperienceYears), 1) * 0.50
        let voice = min(Double(softSkills.communicationAndNetworking) / 8, 1) * 0.25
        let fame = min(famePoints(for: event.category.fameCategory) * 0.05, 0.15)
        return min(0.95, 0.05 + seniority + voice + fame)
    }

    /// Applies to take `event`'s stage — the one way to take part in an event.
    /// The player goes either way, so its soft-skill nudges and base network in
    /// the field land now; the application is decided with the rest of the
    /// year-end accounting in `advanceYear`. Spends the year.
    func applyToPresent(_ event: CareerEvent, into selectedEvents: inout Set<String>) {
        guard canJoinEvent(event), !selectedEvents.contains(event.id) else { return }
        applySkillBoosts(event.abilities)
        networkByCategory[event.category, default: 0] += event.networkWeight
        selectedEvents.insert(event.id)
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
        min(Player.networkHireCap, Double(networkPoints(for: category)) * Player.networkHirePerPoint)
    }

    /// What each network point adds to a hire, and the most a network can add.
    static let networkHirePerPoint = 0.015
    static let networkHireCap = 0.12

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
    /// network in their current field. Smaller than the hiring bonus
    /// (`networkPromotionPerPoint` a point up to `networkPromotionCap`) —
    /// knowing the right people helps you move up, but performance (soft
    /// skills) still carries most of the weight.
    func networkPromotionBonus(for category: JobCategory) -> Double {
        min(GameConstants.networkPromotionCap,
            Double(networkPoints(for: category)) * GameConstants.networkPromotionPerPoint)
    }

    /// Additive boost to the annual promotion probability from the player's fame
    /// in their current field: `famePromotionPerPoint` a weighted point up to
    /// `famePromotionCap`. A known name is first in line for the next rung, but
    /// it tips a close call rather than deciding it.
    func famePromotionBonus(for category: JobCategory) -> Double {
        min(GameConstants.famePromotionCap,
            famePoints(for: category.fameCategory) * GameConstants.famePromotionPerPoint)
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
    /// when the role has no rung above it — a standalone role, the top of a
    /// ladder, a founder — and every other term is then zero: only a real rung
    /// change is a promotion (pay otherwise grows by merit raises; see
    /// `stepRaise(for:)`).
    struct PromotionOdds {
        let promotes: Bool
        /// 0...1: skill fit for the role held — how well you do the job.
        let performance: Double
        /// 0...1: skill fit for the next rung — how ready you are for the job
        /// above.
        let readiness: Double
        /// 0...1: time in the role against `GameConstants.promotionSeniorityYears`.
        let seniority: Double
        /// Years in the current role (`Player.yearsInRole`).
        let tenureYears: Int
        /// The rung above.
        let nextRole: Job?
        /// The industry's weights for the three merit terms.
        let culture: (performance: Double, readiness: Double, seniority: Double)
        /// `GameConstants.promotionRungDecay` per rung the role sits above its
        /// ladder's entry — the pyramid narrowing.
        let rungDecay: Double
        /// The merit terms, weighted by the industry, scaled into a chance and
        /// narrowed by `rungDecay`.
        let merit: Double
        let network: Double
        let fame: Double
        /// Formal education measured against what the role expects — negative
        /// while under-credentialled (see `Job.educationPromotionTerm`).
        let education: Double
        /// The industry's climate this year, whose `promotionFactor` multiplies
        /// the sum.
        let climate: IndustryClimate
        /// Multiplier fading the odds after `promotionPassedOverAfterYears` in
        /// one role — being passed over.
        let passedOver: Double
        /// Multiplier fading the odds late in a career.
        let ageFade: Double
        /// `(merit + network + fame + education) × climate × passed over × age
        /// fade`, clamped to 0…1 — the year's roll, before the rung's own bars.
        let roll: Double
        /// Whether the player meets the rung above's full requirements — its
        /// degree and licences *and* all of its stated years (`experienceMet`).
        let eligible: Bool
        /// The seat on the rung above (`Job.promotionSeatChance`).
        let seat: Double
        /// The chance of stepping up this year: `roll × seat` when eligible,
        /// otherwise 0.
        let total: Double
    }

    /// The next rung of `job`'s ladder — read off the catalogue, not this
    /// year's postings, so a slump that withdraws the posting (or a random
    /// draw that posts it in another sector) can't cancel the player's own
    /// promotion. Requirements aren't checked — this is the role the player is
    /// measured against, not a guarantee they can step into it.
    func nextRung(after job: Job) -> Job? {
        guard !job.isEntrepreneurial else { return nil }
        return JobCatalog.rung(above: job, in: country)
    }

    /// Late-career fade on the promotion odds: 1 up to
    /// `promotionAgeFadeStart`, falling linearly to `promotionAgeFadeFloor` at
    /// `promotionAgeFadeEnd`, and staying there.
    static func promotionAgeFade(age: Int) -> Double {
        let start = GameConstants.promotionAgeFadeStart, end = GameConstants.promotionAgeFadeEnd
        guard age > start else { return 1.0 }
        let t = min(1.0, Double(age - start) / Double(end - start))
        return 1.0 - t * (1.0 - GameConstants.promotionAgeFadeFloor)
    }

    /// Being passed over: 1 for the first `promotionPassedOverAfterYears` in a
    /// role, then `promotionPassedOverRate` less a year, down to
    /// `promotionPassedOverFloor`.
    static func promotionPassedOver(yearsInRole: Int) -> Double {
        let over = max(0, yearsInRole - GameConstants.promotionPassedOverAfterYears)
        return max(GameConstants.promotionPassedOverFloor,
                   1.0 - GameConstants.promotionPassedOverRate * Double(over))
    }

    /// Full breakdown of the annual promotion odds for `job`. Single source of
    /// truth for `promotionChance`, the roll in `advanceYear`, the Occupation
    /// section's hint and the advisor.
    ///
    /// Merit is three things, weighted the way the job's industry weighs them
    /// (`Industry.promotionCulture`): **performance** in the role held (skill fit
    /// for it), **readiness** for the next rung (skill fit for the role above —
    /// where the leadership and planning a ladder adds begin to count), and
    /// **seniority** — years in the current role, so it resets on the way up.
    /// A civil servant climbs mostly on years served; a consultant mostly on
    /// already working at the next level. Merit narrows by
    /// `promotionRungDecay` a rung, so the pyramid thins toward the top.
    ///
    /// Network, fame and education add to it, and the sum is multiplied by the
    /// industry's climate (a slump thins promotions, it doesn't stop them),
    /// by being passed over after years in one role, and by the late-career
    /// fade. A win moves up one rung only when the player meets that rung's
    /// full requirements — its years included — and clears its seat.
    func promotionOdds(for job: Job) -> PromotionOdds {
        let culture = job.industry.promotionCulture
        let climate = self.climate(for: job.industry)
        let years = yearsInRole
        // Founders aren't promoted: their pay moves with the business (see
        // `advanceVenture`). And with no rung above there is nothing to be
        // promoted to — the top of a ladder, or a standalone role.
        guard let next = nextRung(after: job) else {
            return PromotionOdds(promotes: false, performance: 0, readiness: 0, seniority: 0,
                                 tenureYears: years, nextRole: nil, culture: culture, rungDecay: 1,
                                 merit: 0, network: 0, fame: 0, education: 0, climate: climate,
                                 passedOver: 1, ageFade: 1, roll: 0, eligible: false, seat: 1, total: 0)
        }
        let performance = job.softSkillFit(for: self)
        let readiness = next.softSkillFit(for: self)
        let seniority = min(1.0, Double(years) / Double(GameConstants.promotionSeniorityYears))
        let weighted = culture.performance * performance
            + culture.readiness * readiness
            + culture.seniority * seniority
        let floor = GameConstants.promotionMeritFloor
        let rungDecay = pow(GameConstants.promotionRungDecay, Double(job.rung))
        let merit = GameConstants.promotionMeritChance * (floor + (1 - floor) * weighted) * rungDecay

        let network = networkPromotionBonus(for: job.category)
        let fame = famePromotionBonus(for: job.category)
        // Formal education against what the role expects. Being hired without
        // the qualification is possible outside the regulated professions, but
        // it holds back the climb until you go and earn it.
        let education = job.educationPromotionTerm(for: self)
        let passedOver = Player.promotionPassedOver(yearsInRole: years)
        let ageFade = Player.promotionAgeFade(age: age)
        let contested = max(0, min(1.0, (merit + network + fame + education)
                                   * climate.promotionFactor * passedOver * ageFade))
        let eligible = next.allRequirementsMet(for: self) && next.experienceMet(for: self)
        // A training rung (a medical residency) isn't a contest: finishing it
        // is what makes you the next rung, so the step is certain once the
        // years are served.
        let roll = job.rungLabel == "Resident" ? 1.0 : contested  // i18n:ignore rung id, not displayed
        let seat = next.promotionSeatChance(for: self)
        return PromotionOdds(promotes: true, performance: performance, readiness: readiness,
                             seniority: seniority, tenureYears: years, nextRole: next,
                             culture: culture, rungDecay: rungDecay, merit: merit,
                             network: network, fame: fame, education: education, climate: climate,
                             passedOver: passedOver, ageFade: ageFade, roll: roll,
                             eligible: eligible, seat: seat, total: eligible ? roll * seat : 0)
    }

    /// Annual promotion probability for a job — see `promotionOdds` for the
    /// terms: industry-weighted merit (performance, readiness for the next rung,
    /// seniority), plus network, fame and education, through the climate, the
    /// plateau and the rung's own bars and seat.
    func promotionChance(for job: Job) -> Double {
        promotionOdds(for: job).total
    }

    /// Pay on a rung step: a raise of `raise` on current pay, clamped into the
    /// new rung's band — `promotionPayFloorShare…promotionPayCeilingShare` of
    /// its catalogue median (`income`, not a posting's) — and never below
    /// current pay: a promotion is never a pay cut.
    static func promotionPay(current: Int, next: Job, raise: Double) -> Int {
        let raised = Double(current) * (1 + raise)
        let band = min(max(raised, Double(next.income) * GameConstants.promotionPayFloorShare),
                       Double(next.income) * GameConstants.promotionPayCeilingShare)
        return max(current, Int(band.rounded()))
    }

    // MARK: - Merit raises

    /// This year's step (merit) raise for `job` as a fraction of pay, before
    /// the band cap: `annualStepRaiseByTenure` for the years in the role
    /// (then `annualStepRaiseLate`), scaled by 0.5 + performance fit — so 1–3%
    /// early on. Zero for a founder and in a slumping industry, where raises
    /// are paused. Every employee gets it, a cashier as much as an engineer.
    func stepRaise(for job: Job) -> Double {
        guard !job.isEntrepreneurial, !climate(for: job.industry).pausesMeritRaises else { return 0 }
        let schedule = GameConstants.annualStepRaiseByTenure
        let step = yearsInRole < schedule.count ? schedule[yearsInRole] : GameConstants.annualStepRaiseLate
        return step * (0.5 + job.softSkillFit(for: self))
    }

    /// Pay after this year's merit raise: `stepRaise` on current pay, stopped
    /// at the role's band (`Job.payCeiling`) and never lowering it — pay already
    /// above the band simply stops growing.
    func payAfterStepRaise(for job: Job) -> Int {
        let raised = Int((Double(job.annualIncome) * (1 + stepRaise(for: job))).rounded())
        return max(job.annualIncome, min(raised, job.payCeiling))
    }

    // MARK: - Layoffs and time out of work

    /// This year's chance an employee in `job` is laid off, rolled every
    /// realistic year: `baseLayoffRisk` × the employer sector's beta (never
    /// below `layoffBetaFloor`) × its climate's `layoffFactor` × the
    /// difficulty's `layoffSeverity`, capped at `turmoilMaxLayoffChance`. A
    /// government nurse faces a fraction of a builder's risk; a slumping sector
    /// several times a booming one's. Founders aren't laid off — their
    /// businesses fold (see `advanceVenture`).
    func layoffRisk(for job: Job) -> Double {
        guard !isSimplified, !job.isEntrepreneurial else { return 0 }
        let risk = GameConstants.baseLayoffRisk
            * max(GameConstants.layoffBetaFloor, job.industry.beta)
            * climate(for: job.industry).layoffFactor
            * difficulty.layoffSeverity
        return min(GameConstants.turmoilMaxLayoffChance, risk)
    }

    /// Gross pay banked in the year `job` is lost to a layoff:
    /// `layoffYearPayShare` of a year — the months worked, severance and
    /// unemployment insurance.
    static func layoffYearPay(for job: Job) -> Int {
        Int((Double(job.annualIncome) * GameConstants.layoffYearPayShare).rounded())
    }

    /// Duration dependence on the hire odds: 1 for the first year out of work,
    /// then `unemploymentHirePenalty` for each consecutive year beyond it, down
    /// to `unemploymentHireFloor`. Realistic modes only.
    var unemploymentHireMultiplier: Double {
        guard !isSimplified else { return 1.0 }
        let beyondFirst = max(0, consecutiveUnemployedYears - 1)
        return max(GameConstants.unemploymentHireFloor,
                   pow(GameConstants.unemploymentHirePenalty, Double(beyondFirst)))
    }

    // MARK: - Year progression

    /// This year's chance that a professional playing career ends at `age`
    /// (`GameConstants.athleteRetirementChanceByAge`).
    static func athleteRetirementChance(atAge age: Int) -> Double {
        GameConstants.athleteRetirementChanceByAge.last { age >= $0.fromAge }?.chance ?? 0
    }

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
        // Whether this year was spent enrolled in a degree — read before the
        // graduation step clears it. A year of study isn't time out of work.
        let studiedThisYear = currentEducation?.profile != nil
            && (appUIState.yearsLeftToGraduation ?? 0) > 0
        age += 1
        lastPromotionRaisePct = 0
        lastCompetitionWins = 0
        showCompetitionWinAlert = false
        competitionWinMessage = ""
        lostJobThisYear = false

        let newTrainings = appUIState.selectedTrainings.subtracting(hardSkills.trainings)
        hardSkills.trainings.formUnion(appUIState.selectedTrainings)
        for training in newTrainings {
            recordStatus(training.isStatutory ? "🪪" : "📜", L("Earned \(training.friendlyName)"))
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
        // universities read. A Study activity this year lifts it. It is kept
        // quietly: the log reports the final grade once, at graduation
        // (`graduationStatus`); the running average is on the Occupation row.
        if wasInHighSchool {
            let grade = yearGrade(studied: competedSports.contains { $0.kind == .study })
            highSchoolGrades.append(grade)
        }
        appUIState.selectedSports.removeAll()

        lockedTrainings.formUnion(appUIState.selectedTrainings)
        // This year's picks are now permanent (hard skills + locked); clear the
        // pending set so next year starts fresh, mirroring activities/events.
        appUIState.selectedTrainings.removeAll()

        appUIState.selectedActivities.removeAll()
        // Events applied their base effects when the application went in.
        // Decide each one: accepted, it banks the presenter's extra network and
        // a fame award; turned down, the player still went and keeps the base.
        for id in appUIState.selectedEvents {
            guard let event = EventCatalog.byId[id] else { continue }
            if Double.random(in: 0...1) < presentOdds(event) {
                networkByCategory[event.category, default: 0] += GameConstants.presenterNetworkBonus
                award(event.presenterFameTitle, icon: event.icon,
                      category: event.category.fameCategory, weight: event.presenterFameWeight)
                recordStatus("🎤", presenterStatusLine(for: event))
            } else {
                recordStatus("🎟️", L("\(event.name) said no this time — you still went and met people"))
            }
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
            // The family covers its share (`familyTuitionShare`); the student
            // finances the rest.
            let tuition = Int((Double(edu.annualTuition(in: country)) * (1 - difficulty.familyTuitionShare)).rounded())
            let fromSavings = min(max(0, savings), tuition)
            savings -= fromSavings
            let borrowed = tuition - fromSavings
            if borrowed > 0 {
                studentLoan += borrowed
                studentLoanPayment = Player.annualLoanPayment(
                    balance: studentLoan, rate: country.studentLoanInterest)
            }
        }

        appUIState.yearsLeftToGraduation? -= 1
        if appUIState.yearsLeftToGraduation == 0 {
            if let currentEducation {
                degrees.append(currentEducation)
                recordStatus("🎓", L("Graduated — \(currentEducation.degreeName(in: country))"))
                graduationMessage = graduationMessage(for: currentEducation)
                showGraduationAlert = true
            }
            appUIState.yearsLeftToGraduation = nil
            currentEducation = nil
        }

        executiveActionsThisYear.removeAll()
        // Re-roll the job market for the new year (fresh tiers and salaries).
        regenerateAvailableJobs()

        // The business cycle (realistic mode only). An ongoing (prolonged)
        // recession keeps running; otherwise this year may trigger a new one,
        // whose odds and likelihood of dragging on depend on difficulty. A
        // recession drags every sector down through its beta — which thins
        // hiring and promotions and raises layoff risk sector by sector; it no
        // longer freezes anything outright.
        var recessionThisYear = false
        var downturnStarted = false
        if !isSimplified {
            if turmoilYearsRemaining > 0 {
                turmoilYearsRemaining -= 1
                recessionThisYear = true
            } else if Double.random(in: 0...1) < difficulty.turmoilChance {
                recessionThisYear = true
                downturnStarted = true
                if Double.random(in: 0...1) < difficulty.prolongedTurmoilChance {
                    turmoilYearsRemaining = Int.random(in: GameConstants.prolongedTurmoilExtraYears)
                }
            }
        }
        economyInRecession = recessionThisYear

        // Roll the industry cycle. Simplified mode has no economy at all, so its
        // industries stay neutral and every climate term reads 1.0.
        if !isSimplified {
            advanceIndustryTrends(recession: recessionThisYear)
            withdrawSlumpingPostings()
        }

        // Layoffs (realistic mode): every employee faces a small risk every
        // year, set by the employer's sector and its climate (`layoffRisk`).
        // Rolled once the year's climate is known and before pay is banked —
        // a layoff year still banks part of its pay (below).
        let laidOff = rollLayoff()

        // Investment growth (realistic mode only): the accumulated balance
        // compounds each year at a real market return, whether or not the player
        // is employed — and takes a hit in the year a downturn begins. Skipped
        // while in the red — no returns on a negative balance.
        if !isSimplified, savings > 0 {
            let rate = downturnStarted ? GameConstants.downturnStartReturn : GameConstants.investmentReturn
            savings += Int((Double(savings) * rate).rounded())
        }

        // Tally the year's gross income — pay here, endorsements below — and
        // bank what it leaves once living costs and taxes are paid, in one go
        // at the end (`annualSaving`). A layoff year
        // earns `layoffYearPayShare` of the pay (months worked, severance and
        // unemployment insurance) and banks no experience.
        var grossThisYear = 0
        let bankedJob = laidOff ?? currentOccupation
        if let job = bankedJob {
            grossThisYear += laidOff != nil ? Player.layoffYearPay(for: job) : job.annualIncome
        }
        if laidOff == nil, let job = currentOccupation {
            experience[job.category, default: 0] += 1
            experienceByRole[job.baseTitle, default: 0] += 1
            // A year running your own venture builds commercial/founder acumen on
            // top of the trade itself, so a CEO year also banks entrepreneurship
            // experience — which credits Business roles (see industryExperience).
            if job.isEntrepreneurial, job.category != .entrepreneurship {
                experience[.entrepreneurship, default: 0] += 1
            }
            // The step in this year's merit raise is read before the year is
            // counted, so the first year in a role earns the first step.
            let meritRaise = isSimplified ? job.annualIncome : payAfterStepRaise(for: job)
            yearsInRole += 1
            if job.isExecutive, !job.isEntrepreneurial { equityVestedYears += 1 }

            // Promotion (realistic mode): a yearly shot at the next rung, its
            // odds set by industry-weighted merit (performance, readiness,
            // seniority) plus network, fame and education, through the climate
            // and the plateau — and only when the player meets that rung's full
            // requirements and clears its seat (see `promotionOdds`). There is
            // no in-place "promotion": a year without a rung step earns the
            // merit raise instead.
            var promoted = false
            if !isSimplified, !job.isEntrepreneurial {
                promoted = rollPromotion(from: job)
            }

            // The merit raise (realistic mode): every employee's pay creeps up
            // a little each year in the role, up to the band's top. Paused in a
            // slumping industry; a year with a promotion already got its raise.
            if !isSimplified, !promoted, !job.isEntrepreneurial, meritRaise > job.annualIncome {
                let pct = Int(((Double(meritRaise) / Double(job.annualIncome) - 1) * 100).rounded())
                var raised = job
                raised.annualIncome = meritRaise
                currentOccupation = raised
                if pct > 0 {
                    recordStatus("💵", L("Merit raise of \(Fmt.percent(Double(pct) / 100)) — now \(money(meritRaise)) a year"))
                } else {
                    recordStatus("💵", L("Merit raise — now \(money(meritRaise)) a year"))
                }
            }

            // A founder's year (realistic mode): the business may fold, may —
            // rarely — break out, and otherwise earns next year's income.
            if !isSimplified, job.isEntrepreneurial {
                advanceVenture(job, recession: recessionThisYear)
            }

            // A professional athlete's body sets the end of the career, not the
            // ladder: most pros are done by their mid-30s. The fame stays — it
            // opens broadcasting, coaching and endorsement doors afterwards.
            if job.baseTitle == "Player", job.rung >= 1,  // i18n:ignore role id, not displayed
               Double.random(in: 0...1) < Player.athleteRetirementChance(atAge: age) {
                currentOccupation = nil
                recordStatus("🏁", L("Retired from professional sport at \(age)"))
            }
        }

        // The spell out of work: a year with no job at all, lived as an adult
        // and not spent studying, lengthens it; a year worked (even one cut
        // short by a layoff) or studied ends it.
        if bankedJob == nil, !studiedThisYear, age - 1 >= GameConstants.adultRoleAge {
            consecutiveUnemployedYears += 1
        } else {
            consecutiveUnemployedYears = 0
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
                recordStatus("📅", L("Banked a year of \(cat.displayName) experience running \(hustle.label)"))
            }
            // Reputation compounds inside its own bucket: a name made shipping
            // software opens the next software project, and does nothing for a
            // record. The bucket-scoped figure is the one hiring already uses,
            // so a fame point means the same thing everywhere it's read.
            let outcome = hustle.resolve(for: softSkills,
                                         famePoints: famePoints(for: hustle.fameCategory),
                                         totalExperienceYears: careerYears,
                                         fieldExperienceYears: fieldYears,
                                         climate: projectClimate(for: hustle),
                                         age: age - 1)
            // The practice lands either way — applied before the roll is read,
            // so nothing about the outcome can gate it.
            for ability in hustle.growth {
                softSkills[keyPath: ability.keyPath] = min(softSkills[keyPath: ability.keyPath] + ability.weight, 10)
            }
            if outcome.success {
                if let grant = outcome.grantedFame {
                    award(grant.title, icon: hustle.icon, category: grant.category, weight: grant.weight)
                    recordStatus("🌟", L("\(hustle.label) earned fame in \(grant.category.displayName)"))
                }
                // A landed project is worth the confetti whatever the odds were —
                // it cost a year of the player's life to find out.
                celebrate()
            } else {
                recordStatus(hustle.icon, L("\(hustle.label) didn't land — but the practice counts"))
            }
            reportProjectOutcome(outcome)
        }
        appUIState.selectedSideHustles.removeAll()

        // Endorsements: a famous entertainment name is paid to carry brands,
        // year in, year out — on top of whatever else the year earned.
        lastYearEndorsements = endorsementIncome
        grossThisYear += lastYearEndorsements

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
                let achievement = FameAward.title(forKey: competition.achievement)
                recordStatus("🏆", L("Won \(achievement)"))
                competitionWinMessage = L("You won the \(competition.name) and earned the “\(achievement)” title!")
                showCompetitionWinAlert = true
            }
        }
        lastCompetitionWins = competitionWins

        // Bank what the year's income leaves after living costs and tax. An
        // adult with less than the living-cost floor coming in (out of work,
        // not studying) draws the shortfall's share from savings instead —
        // rent doesn't stop with the paycheck — but never goes into the red.
        let livedAge = age - 1
        savings += annualSaving(gross: grossThisYear, atAge: livedAge)
        if !isSimplified, livedAge >= GameConstants.adultRoleAge, !studiedThisYear,
           grossThisYear < livingCostFloor {
            let draw = Int((Double(livingCostFloor - grossThisYear) * GameConstants.unemployedDrawShare).rounded())
            savings -= min(max(0, savings), draw)
        }

        // Service the loans: interest accrues, then the year's instalment is
        // paid — partly from savings, partly by spending less (see
        // `serviceLoan`). A folded venture still owes — the debt outlives the
        // business — and whatever can't be paid stays owed and keeps accruing.
        // Student loans are deferred while enrolled (interest still accrues),
        // as federal loans are.
        var spendingCut = isSimplified ? 0 : Int((Double(grossThisYear) * GameConstants.maxDebtServiceShare).rounded())
        if serviceLoan(&outstandingLoan, payment: &ventureLoanPayment,
                       rate: GameConstants.ventureLoanAnnualInterest, income: &spendingCut) {
            recordStatus("🏦", L("Paid off your venture loan"))
        }
        if studiedThisYear, studentLoan > 0 {
            studentLoan = Int((Double(studentLoan) * (1 + country.studentLoanInterest)).rounded())
        } else if serviceLoan(&studentLoan, payment: &studentLoanPayment,
                              rate: country.studentLoanInterest, income: &spendingCut) {
            recordStatus("🎓", L("Paid off your student loan"))
        }

        // The advisor reviews the year once it has fully settled — the new
        // postings, the economy, any hire or promotion — so what it reports is
        // what the player now faces. Nothing to review until they've answered
        // its opening question.
        if !hasRetired, let review = AdvisorCoach.checkIn(for: self) {
            advisorPlan.record(review)
        }

        // The year just lived may have been the last one. Raise the Game Over
        // sheet after everything else has settled, so the final score already
        // includes this year's pay, growth and loan servicing.
        if hasRetired {
            recordStatus("🎂", L("Reached \(GameConstants.retirementAge) — career over"))
            appUIState.showRetirementSheet = true
        }
    }

    /// Withdraws part of a slumping sector's postings: each role whose
    /// industry is in a slump — every rung of a ladder together — is pulled
    /// from this year's market with `slumpPostingWithdrawalChance`. Openings
    /// fall sharply in a contraction, but never to zero, so a laid-off worker
    /// can still find something to apply for. Promotions read the catalogue,
    /// not this list (see `nextRung`), so the player's own ladder is untouched.
    private func withdrawSlumpingPostings() {
        var withdrawn: [String: Bool] = [:]
        availableJobs = availableJobs.filter { job in
            guard climate(for: job.industry) == .slump else { return true }
            if let decided = withdrawn[job.baseTitle] { return !decided }
            let pull = Double.random(in: 0...1) < GameConstants.slumpPostingWithdrawalChance
            withdrawn[job.baseTitle] = pull
            return !pull
        }
    }

    /// Rolls this year's layoff (see `layoffRisk`). On a layoff the job is
    /// gone, the pop-up and the status line fire, and the job lost is returned
    /// so the year can bank its partial pay; nil when the player keeps their
    /// job (or has none, or is a founder — businesses fold instead).
    private func rollLayoff() -> Job? {
        guard let job = currentOccupation else { return nil }
        let risk = layoffRisk(for: job)
        guard risk > 0, Double.random(in: 0...1) < risk else { return nil }
        currentOccupation = nil
        lostJobThisYear = true
        showLayoffAlert = true
        recordStatus("💼", L("Laid off from \(job.displayBaseTitle) — paid about half the year, with severance"))
        return job
    }

    /// Rolls the year's promotion for `job` (see `promotionOdds`) and, on a
    /// win, steps up one rung at the same employer: pay rises by
    /// `promotionRaise`, clamped into the new rung's band (`promotionPay`).
    /// Returns whether the player was promoted.
    private func rollPromotion(from job: Job) -> Bool {
        let odds = promotionOdds(for: job)
        guard odds.total > 0, let next = odds.nextRole,
              Double.random(in: 0...1) < odds.total else { return false }
        var promoted = next
        // A promotion is at the same employer: the sector stays put.
        promoted.industry = job.industry
        promoted.annualIncome = Player.promotionPay(current: job.annualIncome, next: next,
                                                    raise: Double.random(in: GameConstants.promotionRaise))
        currentOccupation = promoted        // restarts the years in the role
        lastPromotionRaisePct = job.annualIncome > 0
            ? max(0, Int(((Double(promoted.annualIncome) / Double(job.annualIncome) - 1) * 100).rounded()))
            : 0
        celebrateIfLucky(odds.total)
        showPromotionAlert = true
        promotionMessage = L("You've been promoted to \(promoted.displayTitle) — \(money(promoted.annualIncome)) a year.")
        recordStatus("⬆️", L("Promoted to \(promoted.catalogueTitle) — pay +\(Fmt.percent(Double(lastPromotionRaisePct) / 100))"))
        return true
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
            // No one is paid under the minimum wage, whatever they asked for.
            hiredJob.annualIncome = job.isEntrepreneurial ? requestedSalary : max(country.minimumAnnualPay, requestedSalary)
            currentOccupation = hiredJob
            yearsInRole = 0                 // a new position, even under the same title
            recordStatus("💼", L("Hired as \(hiredJob.displayBaseTitle) — \(money(hiredJob.annualIncome))/year"))
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
            recordStatus("🏦", L("Borrowed \(money(borrowed)) to fund your venture"))
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
            recordStatus("🚪", L("Left \(previous.displayBaseTitle) to go all-in on your venture"))
        }
        recordStatus("🚀", L("Founded \(job.displayBaseTitle) — you're now CEO"))
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
                * (recession ? GameConstants.ventureRecessionFoldMultiplier : 1.0)
        )
        if Double.random(in: 0...1) < foldRisk {
            let recovered = Int((Double(ventureStake) * GameConstants.ventureFoldRecovery).rounded())
            savings += recovered
            currentOccupation = nil
            clearVenture()
            showVentureFailureAlert = true
            ventureFailureMessage = L("\(job.displayBaseTitle) had to close this year. Selling what was left got back \(money(recovered)) — but you still have to pay back any loan.")
            recordStatus("📉", L("\(job.displayBaseTitle) folded — recovered \(money(recovered))"))
            // A fold costs no reputation — the lessons count for something.
            award("Founder's Lessons", icon: "📚", category: .business, weight: GameConstants.founderFoldFame)
            return
        }

        // Another year in business builds the founder's name.
        award(FameAward.founderKey(venture: job.baseTitle), icon: job.icon, category: .business, weight: GameConstants.founderYearFame)

        let climate = self.climate(for: job.industry)
        if job.isScalableVenture, !ventureBrokeOut, year >= 2 {
            let boom = climate == .boom ? 1.5 : 1.0
            let chance = GameConstants.ventureBreakoutChance * (0.5 + venturePreparation) * boom
            if Double.random(in: 0...1) < chance {
                ventureBrokeOut = true
                ventureMatureIncome = Int((Double(ventureMatureIncome) * GameConstants.ventureBreakoutIncomeMultiple).rounded())
                award("Breakout Startup", icon: "🦄", category: job.industry.fameCategory ?? .business,  // i18n:ignore award key
                      weight: GameConstants.founderBreakoutFame)
                recordStatus("🦄", L("\(job.displayBaseTitle) broke out — revenue tripled and your stake is worth a fortune"))
                reportApplicationOutcome(
                    title: L("🦄 Breakout!"),
                    message: L("\(job.displayBaseTitle) took off: revenue tripled, and your stake is now worth many times more. Sell it in the Boardroom, or keep riding it.")
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
    private static let investmentRoundFameRate = 0.06
    private static let investmentRoundFameCap = 0.25

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
        return max(0.05, min(GameConstants.investmentRoundMaxOdds, 0.12 + fit * 0.40 + network + fame))
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
        // A hired executive owns only the equity grants that have vested since
        // they last sold — each year a fraction of pay (`execEquityGrantShare`),
        // up to `execEquityMaxMultiple` years' worth. Selling uses it up.
        if !job.isEntrepreneurial {
            let grant = job.id.contains("Chief")
                ? GameConstants.execEquityGrantShareCSuite
                : GameConstants.execEquityGrantShare
            let multiple = min(Double(equityVestedYears) * grant, GameConstants.execEquityMaxMultiple)
            return Int((Double(job.annualIncome) * multiple).rounded())
        }
        let years = ventureFoundedAge != nil ? ventureYears : experienceByRole[job.baseTitle, default: 0]
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
        // Investors want a year of traction first, and a company rarely raises
        // more than a seed plus a few priced rounds (A–C) before an exit.
        currentOccupation?.isScalableVenture == true
            && ventureYears >= 1
            && ventureRoundsRaised < GameConstants.maxInvestmentRounds
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
                recordStatus("🤝", L("No buyer for your \(job.displayBaseTitle) stake at \(money(ask)) this year"))
                return ExecutiveDecision.Outcome(decision: decision, success: false, cash: 0, fameTitle: nil)
            }
            // What reaches the bank: a hired executive's vested shares are taxed
            // as income; a founder's exit pays broker fees and capital-gains tax.
            let kept = job.isEntrepreneurial ? 1 - GameConstants.founderExitCostRate : 1 - GameConstants.equitySaleTaxRate
            let proceeds = Int((Double(ask) * kept).rounded())
            savings += proceeds
            // An owner-founder who sells their stake exits the venture entirely —
            // the seat is gone, freeing them to start something new (and the
            // Ventures button returns). Ownership is what an entrepreneurial seat
            // means. A hired executive just cashes out vested equity, keeps their
            // seat, and can sell again in a later year.
            if job.isEntrepreneurial {
                currentOccupation = nil            // clears the venture state too
                // A successful exit is the strongest founder credential there is.
                award("Successful Exit", icon: decision.icon, category: .business, weight: GameConstants.founderExitFame)  // i18n:ignore award key
                recordStatus(decision.icon, L("Sold your stake in \(job.displayBaseTitle) for \(money(ask)) (\(money(proceeds)) after fees and tax) — exited the venture"))
            } else {
                equityVestedYears = 0
                recordStatus(decision.icon, L("Sold vested shares in \(job.displayBaseTitle) for \(money(ask)) (\(money(proceeds)) after tax)"))
            }
            return ExecutiveDecision.Outcome(decision: decision, success: true, cash: proceeds, fameTitle: nil)
        case .investmentRound:
            let odds = investmentRoundOdds()
            let succeeded = Double.random(in: 0...1) < odds
            guard succeeded else {
                recordStatus("🚫", L("Investment round for \(job.displayBaseTitle) fell through"))
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
            award(title, icon: decision.icon, category: .business, weight: GameConstants.investmentRoundFame)
            let growthAxes: [WritableKeyPath<SoftSkills, Int>] =
                [\.visionaryThinkingAndAmbition, \.persuasionAndNegotiation]
            for kp in growthAxes {
                softSkills[keyPath: kp] = min(softSkills[keyPath: kp] + 1, 10)
            }
            celebrateIfLucky(odds)
            recordStatus(decision.icon, L("Closed an investment round for \(job.displayBaseTitle) — the company is worth more and can pay you more"))
            return ExecutiveDecision.Outcome(decision: decision, success: true, cash: 0, fameTitle: FameAward.title(forKey: title))
        }
    }

    func reset() {
        let fresh = Player()
        difficulty = fresh.difficulty
        country = fresh.country
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
        consecutiveUnemployedYears = fresh.consecutiveUnemployedYears
        age = fresh.age
        softSkills = fresh.softSkills
        hardSkills = fresh.hardSkills
        degrees = fresh.degrees
        experience = fresh.experience
        experienceByRole = fresh.experienceByRole
        currentOccupation = fresh.currentOccupation
        yearsInRole = fresh.yearsInRole
        equityVestedYears = fresh.equityVestedYears
        currentEducation = fresh.currentEducation
        savings = fresh.savings
        outstandingLoan = fresh.outstandingLoan
        ventureLoanPayment = fresh.ventureLoanPayment
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
        advisorPlan = fresh.advisorPlan
    }
}

