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
    func fameHireBonus(for jobCategory: JobCategory, topPosition: Bool = false) -> Double {
        let rate = topPosition ? 0.12 : 0.07
        let cap = topPosition ? 0.50 : 0.35
        return min(cap, famePoints(for: jobCategory.fameCategory) * rate)
    }

    /// Years a prolonged recession still has to run. While positive, each
    /// `advanceYear` keeps the downturn in force (hiring freeze + layoff risk)
    /// and counts down. Zero means the economy is not in an ongoing recession.
    @Published var turmoilYearsRemaining: Int = 0

    /// Whether the economy is in a downturn this year (a fresh or ongoing
    /// recession). Drives the header recession note; while true, hiring at risky
    /// employers and promotions are frozen.
    @Published var economyInRecession: Bool = false

    /// Last year's side-hustle takings (payouts banked in full; no stakes).
    /// Surfaced in the header; positive when the ventures paid off.
    @Published var lastSideHustleEarnings: Int = 0

    /// Size of last year's promotion raise as a whole-number percent (0 when the
    /// player wasn't promoted). Surfaced in the header alongside the confetti.
    @Published var lastPromotionRaisePct: Int = 0

    /// One-shot trigger for the promotion congratulations pop-up, set the moment a
    /// raise is earned; the alert clears it when dismissed (the header note,
    /// driven by `lastPromotionRaisePct`, lingers for the rest of the year).
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

    /// The graduation pop-up's text: congratulations, then what the qualification
    /// actually opens — the courses and licences that needed this much schooling,
    /// the roles whose education bar it clears, and the degree above it. Named
    /// concretely rather than as "the next step", so the years just spent read as
    /// a door opening rather than a number going up.
    func graduationMessage(for degree: Education, previousEQF: Int) -> String {
        let congratulations = "Congratulations! You completed your \(degree.degreeName)."
        var unlocks: [String] = []

        // Courses and licences that were out of reach at the old level.
        let opened = Training.allCases
            .filter { $0.minEQF > previousEQF && $0.minEQF <= degree.eqf }
            .sorted { $0.friendlyName < $1.friendlyName }
        if !opened.isEmpty {
            let named = opened.prefix(4).map { "\($0.pictogram) \($0.friendlyName)" }
            let rest = opened.count - named.count
            let tail = rest > 0 ? ", and \(rest) more" : ""
            unlocks.append("Courses and licences you can now take: \(named.joined(separator: ", "))\(tail).")
        }

        // Roles whose education bar this clears, counted by role family so a
        // ladder's four rungs don't read as four separate openings.
        let roles = Set(
            JobCatalog.allJobs()
                .filter { !$0.isEntrepreneurial }
                .filter { $0.requirements.education.minEQF > previousEQF }
                .filter { $0.requirements.education.minEQF <= degree.eqf }
                .map(\.baseTitle)
        )
        if !roles.isEmpty {
            unlocks.append("\(roles.count) role\(roles.count == 1 ? "" : "s") that ask for this level of schooling.")
        }

        // The rung above, when there is one.
        if let next = availableNextEducations(holds: degrees + [degree]).map(\.eqf).max(),
           next > degree.eqf {
            unlocks.append("You can study further: \(Education.Requirements(minEQF: next).educationLabel()).")
        }

        guard !unlocks.isEmpty else { return congratulations }
        return congratulations + "\n\nThis opens up:\n\n• " + unlocks.joined(separator: "\n\n• ")
    }

    /// Whether a downturn cost the player their job in the year just advanced.
    /// Drives the header layoff notice so a sudden firing doesn't go unnoticed.
    @Published var lostJobThisYear: Bool = false

    /// One-shot trigger for the layoff pop-up. Set the moment a downturn fires
    /// the player; the alert clears it when dismissed (the header note, driven
    /// by `lostJobThisYear`, lingers for the rest of the year as a reminder).
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
        hustle.successProbability(
            for: softSkills,
            fameScore: fameScore,
            totalExperienceYears: totalExperienceYears,
            fieldExperienceYears: hustle.experienceCategory.map { industryExperience(for: $0) } ?? 0
        )
    }

    /// Raises the result pop-up for a resolved spare-time project. Every project
    /// costs the year whether or not it lands, so the year always reports back —
    /// a flop is news too, and the message names the odds it was rolled against
    /// so a long shot reads as bad luck rather than a broken game.
    func reportProjectOutcome(_ outcome: SideHustle.Outcome) {
        let hustle = outcome.hustle
        let chance = "\(Int((outcome.odds * 100).rounded()))%"
        if outcome.success {
            projectOutcomeTitle = "\(hustle.icon) It landed!"
            var earned: [String] = []
            if outcome.credit > 0 {
                earned.append("It paid \(outcome.credit.formatted(.number)) $.")
            }
            if let grant = outcome.grantedFame {
                earned.append("You earned the “\(grant.title)” title and \(grant.category.icon) \(grant.category.rawValue) fame.")
            }
            projectOutcomeMessage = "\(hustle.label) paid off — a \(chance) shot that came in. "
                + earned.joined(separator: " ")
        } else {
            projectOutcomeTitle = "\(hustle.icon) It didn't land"
            projectOutcomeMessage = "\(hustle.label) went nowhere this year — it was a \(chance) shot. "
                + "Build the skills it draws on and the years behind you, then try again."
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
    /// Simplified mode has a fixed finish line — reaching a top leadership
    /// ("C-suite") role. The realistic settings are open-ended: there is no
    /// target to hit, just a running `leaderboardScore` the player banks whenever
    /// they choose to finish the game (see `RetirementView`).
    var goalMet: Bool {
        guard isSimplified else { return false }
        return currentOccupation?.isTopLeadership ?? false
    }

    @Published var age: Int

    /// Outstanding balance of a loan taken to fund a venture beyond the player's
    /// savings (see `foundVenture` / `maxVentureLoan`). Accrues interest and is
    /// repaid from savings each year in `advanceYear`; it counts against net worth
    /// for the leaderboard. Zero when the player owes nothing.
    @Published var outstandingLoan: Int = 0

    /// Outstanding student-loan balance from tuition the player couldn't cover in
    /// cash (see the tuition charge in `advanceYear`). Accrues interest each year
    /// at `GameConstants.studentLoanAnnualInterest` and is repaid from savings once
    /// the player is earning — so reaching for an expensive degree early is a debt
    /// that follows you. Counts against net worth for the leaderboard. Zero when
    /// the player owes nothing (paid cash, or has cleared it).
    @Published var studentLoan: Int = 0

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

    /// The player's running score, recalculated from current state (so it's
    /// always up to date each year): "wealth velocity" — net worth (savings minus
    /// any outstanding loan) per year of life. Reaching wealth younger scores
    /// higher. Floored at 0. This is what a realistic-mode run is playing for;
    /// finishing the game banks it to the Game Center leaderboard.
    var leaderboardScore: Int { age > 0 ? max(0, savings - outstandingLoan - studentLoan) / age : 0 }

    @Published var degrees: [Education]
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
    @Published var currentOccupation: Job?
    @Published var currentEducation: Education?
    @Published var savings: Int
    @Published var lockedTrainings: Set<Training>
    @Published var lockedHobbies: Set<String>
    /// Professional network built by attending industry `CareerEvent`s, keyed by
    /// the event's industry. Improves hiring odds on that field's postings and
    /// the chance of promotion while working in it (see `networkBonus`).
    @Published var networkByCategory: [JobCategory: Int] = [:]

    /// Total years trained in each `Sport`. A new year is added at year-end for
    /// every sport the player committed their spare-time slot to. Drives the
    /// competition sport gate (a sport must have ≥1 year for its tagged
    /// competitions to appear) and the `sportFit` bonus inside `winProbability`.
    @Published var sportYears: [Sport: Int] = [:]
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
            outdoorAndWeatherResilience: Int.random(in: 0...1),
            collaborationAndTeamwork: Int.random(in: 0...1),
            timeManagementAndPlanning: Int.random(in: 0...1),
            selfDisciplineAndPerseverance: Int.random(in: 0...1),
            presentationAndStorytelling: Int.random(in: 0...1)
        ),
        hardSkills: HardSkills = HardSkills(),
        degrees: [Education] = [],
        experience: [JobCategory: Int] = [:],
        currentOccupation: Job? = nil,
        savings: Int = 0,
        lockedTrainings: Set<Training> = [],
        lockedHobbies: Set<String> = []
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
        self.lockedHobbies = lockedHobbies
        self.availableJobs = JobCatalog.allJobs().shuffled()
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

    // MARK: - Hobby selection

    func selectHobby(_ hobby: Hobby, into selectedActivities: inout Set<String>) {
        selectedActivities.insert(hobby.label)
        for ability in hobby.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] = min(softSkills[keyPath: kp] + ability.weight, 10)
        }
    }

    func deselectHobby(_ hobby: Hobby, from selectedActivities: inout Set<String>) {
        guard selectedActivities.remove(hobby.label) != nil else { return }
        for ability in hobby.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] -= ability.weight
        }
    }

    // MARK: - Sport selection

    /// Commits the year's spare-time slot to training in `sport`. Mirrors
    /// `selectHobby`: bumps the sport's soft skills now and registers it in
    /// `selectedActivities` (slot accounting) plus `selectedSports`
    /// (type-safe selection). Year-end (`advanceYear`) banks the year into
    /// `sportYears` for the unlocked-competition gate and the win-odds bonus.
    func selectSport(_ sport: Sport, into selectedActivities: inout Set<String>, sports: inout Set<Sport>) {
        guard !sports.contains(sport) else { return }
        sports.insert(sport)
        selectedActivities.insert(sport.label)
        for ability in sport.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] = min(softSkills[keyPath: kp] + ability.weight, 10)
        }
    }

    /// Reverses `selectSport` if the player toggles a sport off before the
    /// year ends. Symmetric to `deselectHobby`.
    func deselectSport(_ sport: Sport, from selectedActivities: inout Set<String>, sports: inout Set<Sport>) {
        guard sports.remove(sport) != nil else { return }
        selectedActivities.remove(sport.label)
        for ability in sport.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] -= ability.weight
        }
    }

    // MARK: - Professional events & network

    /// Takes the stage at a professional event, applying its soft-skill nudges
    /// and banking its network points in the event's industry. The fame award
    /// presenting earns is deferred to `advanceYear` so a selection toggled off
    /// before the year advances stays fully reversible (mirror of `dropEvent`).
    func attendEvent(_ event: CareerEvent, into selectedEvents: inout Set<String>) {
        guard !selectedEvents.contains(event.id) else { return }
        // Taking the stage needs the veteran gate in this event's field
        // (safety net; the view locks these rows too).
        guard event.canPresent(with: experience) else { return }
        selectedEvents.insert(event.id)
        for ability in event.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] = min(softSkills[keyPath: kp] + ability.weight, 10)
        }
        networkByCategory[event.category, default: 0] += event.networkPoints
    }

    func dropEvent(_ event: CareerEvent, from selectedEvents: inout Set<String>) {
        guard selectedEvents.remove(event.id) != nil else { return }
        for ability in event.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] -= ability.weight
        }
        networkByCategory[event.category, default: 0] -= event.networkPoints
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

    /// Total years the player has spent working, summed across every industry —
    /// the work-experience gate on senior trainings (see
    /// `Training.minYearsExperience`).
    var totalYearsWorked: Int { experience.values.reduce(0, +) }

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
        for boost in training.softSkillBoosts {
            softSkills[keyPath: boost.keyPath] = min(softSkills[keyPath: boost.keyPath] + boost.weight, 10)
        }
        return true
    }

    /// Reverses `attemptTraining` if the player toggles a training off before the
    /// year ends: frees the spare-time slot, un-selects the credential, and
    /// rolls back the soft-skill nudges. Symmetric to `deselectHobby`.
    func cancelTraining(_ training: Training, from selectedTrainings: inout Set<Training>, activities selectedActivities: inout Set<String>) {
        guard selectedTrainings.remove(training) != nil else { return }
        selectedActivities.remove("training:\(training.rawValue)")
        for boost in training.softSkillBoosts {
            softSkills[keyPath: boost.keyPath] -= boost.weight
        }
    }

    // MARK: - Promotion

    /// Soft-skill axes an employer weighs when deciding to promote you.
    private static let promotionSkills: [WritableKeyPath<SoftSkills, Int>] = [
        \.leadershipAndInfluence,
        \.communicationAndNetworking,
        \.visionaryThinkingAndAmbition,
        \.persuasionAndNegotiation,
        \.selfDisciplineAndPerseverance,
        \.collaborationAndTeamwork,
    ]
    /// Skill level at which a promotion axis is a perfect fit (caps its share).
    private static let promotionSkillReference = 6

    /// 0...1 promotion readiness from the player's career-advancement soft skills.
    private var promotionReadiness: Double {
        let total = Player.promotionSkills.reduce(0.0) { acc, kp in
            acc + min(Double(softSkills[keyPath: kp]) / Double(Player.promotionSkillReference), 1.0)
        }
        return total / Double(Player.promotionSkills.count)
    }

    /// The per-term breakdown behind `promotionChance`, so the UI can explain the
    /// odds the same way the hire-probability InfoHint does. `promotes` is false
    /// for unskilled roles that never promote in place (all other terms zero).
    struct PromotionOdds {
        let promotes: Bool
        /// Readiness-scaled base chance (soft skills).
        let readinessBase: Double
        let network: Double
        let fame: Double
        let tenure: Double
        let tenureYears: Int
        /// Formal education measured against what the role expects — negative
        /// while under-credentialled (see `Job.educationPromotionTerm`).
        let education: Double
        let total: Double
    }

    /// Full breakdown of the annual promotion odds for `job`. Single source of
    /// truth for both `promotionChance` and the header InfoHint.
    func promotionOdds(for job: Job) -> PromotionOdds {
        // Unskilled jobs don't promote in place — in real life a raise-and-title
        // bump rarely lands in work needing no post-secondary training; the
        // player advances by applying upward instead.
        guard !job.isLowSkilled else {
            return PromotionOdds(promotes: false, readinessBase: 0, network: 0,
                                 fame: 0, tenure: 0, tenureYears: 0, education: 0, total: 0)
        }
        let base = GameConstants.promotionBaseChance
        // Base chance scaled by promotion readiness (40%–100% of the base, so
        // soft skills move the odds).
        let core = base * (0.4 + 0.6 * promotionReadiness)
        // Tenure in the current role makes a promotion more likely — seasoned
        // employees are next in line — with diminishing returns (capped +0.10).
        let years = experienceByRole[job.baseTitle, default: 0]
        let tenureBoost = min(0.10, Double(years) * 0.02)
        let network = networkPromotionBonus(for: job.category)
        let fame = famePromotionBonus(for: job.category)
        // Formal education against what the role expects. Being hired without
        // the qualification is possible outside the regulated professions, but
        // it holds back the climb until you go and earn it.
        let education = job.educationPromotionTerm(for: self)
        let total = max(0, min(1.0, core + network + fame + tenureBoost + education))
        return PromotionOdds(promotes: true, readinessBase: core, network: network,
                             fame: fame, tenure: tenureBoost, tenureYears: years,
                             education: education, total: total)
    }

    /// Annual promotion probability for a job: a flat base chance
    /// (`GameConstants.promotionBaseChance`) scaled by promotion readiness
    /// (40%–100% of the base, so soft skills move the odds), plus a
    /// professional-network bonus for the job's industry — attending that
    /// field's summits and conferences makes a raise more likely — a significant
    /// fame bonus for reputation built in the field, and a tenure bonus for years
    /// already spent in the role.
    func promotionChance(for job: Job) -> Double {
        promotionOdds(for: job).total
    }

    // MARK: - Year progression

    func advanceYear(appUIState: AppUIState) {
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
        appUIState.selectedSports.removeAll()

        lockedTrainings.formUnion(appUIState.selectedTrainings)
        // This year's picks are now permanent (hard skills + locked); clear the
        // pending set so next year starts fresh, mirroring sports/hobbies/events.
        appUIState.selectedTrainings.removeAll()

        // Bank this year's hobbies into the player's practised-hobby history,
        // locking a hobby from being retaken (HobbiesView). `selectedActivities`
        // also carries sport and training: entries, so intersect with the hobby
        // catalogue to keep only real hobby labels.
        lockedHobbies.formUnion(
            appUIState.selectedActivities.intersection(Set(hobbies.map(\.label)))
        )

        appUIState.selectedActivities.removeAll()
        // Events applied their network/soft-skill effects when attended. Bank the
        // fame award each presenter role earns (deferred to here so the
        // within-year toggle stayed reversible), then clear this year's picks.
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
        if !isSimplified,
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
            if borrowed > 0 { studentLoan += borrowed }
        }

        appUIState.yearsLeftToGraduation? -= 1
        if appUIState.yearsLeftToGraduation == 0 {
            let priorEQF = degrees.map(\.eqf).max() ?? 0
            if let currentEducation {
                degrees.append(currentEducation)
                recordStatus("🎓", "Graduated — \(currentEducation.degreeName)")
                graduationMessage = graduationMessage(for: currentEducation, previousEQF: priorEQF)
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
        if let job = currentOccupation {
            let saved = isSimplified
                ? job.annualIncome
                : Int((Double(job.annualIncome) * difficulty.savingsRate).rounded())
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
            // by the player's promotion-readiness soft skills, tenure, and network.
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
                       Double.random(in: 0...1) >= GameConstants.executiveSeatChance {
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
                        promotionMessage = "Your hard work paid off — you've been promoted from \(current.displayTitle) to \(promoted.displayTitle). Your pay rises to \(promoted.annualIncome.formatted(.number)) $ a year."
                        recordStatus("⬆️", "Promoted to \(promoted.id)")
                    } else {
                        promotionMessage = "Your hard work paid off — you've been promoted in your role as \(current.baseTitle). Your pay rises \(lastPromotionRaisePct)% to \(promoted.annualIncome.formatted(.number)) $ a year."
                        recordStatus("⬆️", "Promoted in \(current.baseTitle) — pay +\(lastPromotionRaisePct)%")
                    }
                }
            }

            // Ongoing venture risk (realistic mode): a founder isn't laid off like
            // a salaried worker — but their business can fail outright in any year,
            // and a downturn makes that far likelier. A fold clears the occupation
            // (and its income); the player keeps what they've banked, and any
            // venture loan outlives the business (serviced below).
            if !isSimplified, job.isEntrepreneurial {
                let failChance = min(
                    GameConstants.ventureMaxFailureRisk,
                    GameConstants.ventureAnnualFailureRisk * (recessionThisYear ? difficulty.layoffSeverity : 1.0)
                )
                if Double.random(in: 0...1) < failChance {
                    currentOccupation = nil
                    showVentureFailureAlert = true
                    ventureFailureMessage = "Your venture, \(job.baseTitle), folded this year. The business — and its income — are gone, but you keep what you've saved. Any outstanding venture loan still has to be repaid. You can found a new venture whenever you're ready."
                    recordStatus("📉", "\(job.baseTitle) folded")
                }
            }
        }

        // Spare-time projects (business ventures + creative projects, one system).
        // Nothing is staked but the year, and nothing is locked: any project can
        // be attempted at any time, and the odds — talent fit plus the working
        // life behind it, see SideHustle.successProbability — carry the whole
        // decision. A successful year banks an industry-scoped fame award —
        // Business fame for the commercial/entrepreneurial ventures, field fame
        // for the creative projects — and grows the soft skills it drew on, the
        // founder-cluster axes no hobby can build. A flop yields nothing but the
        // lost year. All are repeatable year after year.
        var sideHustleNet = 0
        for id in appUIState.selectedSideHustles {
            guard let hustle = SideHustleCatalog.byId[id] else { continue }
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
            let outcome = hustle.resolve(for: softSkills, fameScore: fameScore,
                                         totalExperienceYears: careerYears,
                                         fieldExperienceYears: fieldYears)
            if outcome.success {
                savings += outcome.credit
                sideHustleNet += outcome.credit
                if outcome.credit > 0 {
                    recordStatus(hustle.icon, "\(hustle.label) paid \(outcome.credit.formatted(.number)) $")
                }
                if let grant = outcome.grantedFame {
                    award(grant.title, icon: hustle.icon, category: grant.category, weight: grant.weight)
                    for ability in hustle.growth {
                        softSkills[keyPath: ability.keyPath] = min(softSkills[keyPath: ability.keyPath] + ability.weight, 10)
                    }
                    recordStatus("🌟", "\(hustle.label) earned fame in \(grant.category.rawValue)")
                }
                // A landed project is worth the confetti whatever the odds were —
                // it cost a year of the player's life to find out.
                celebrate()
            } else {
                recordStatus(hustle.icon, "\(hustle.label) didn't pan out this year")
            }
            reportProjectOutcome(outcome)
        }
        lastSideHustleEarnings = sideHustleNet
        appUIState.selectedSideHustles.removeAll()

        // Competitions: training a sport now automatically enters you into its
        // top eligible contest — no menu, no entry fee. Win odds start low and
        // climb with the trained years (and the soft skills training builds).
        // A win pays no money — it banks a lasting achievement (Entertainment
        // fame that helps land spotlight roles) and surfaces a celebration dialog.
        var competitionWins = 0
        let currentStage = LifeStage.forAge(age)
        for sport in competedSports {
            let years = sportYears[sport, default: 0]
            guard let competition = CompetitionCatalog.bestCompetition(
                forSport: sport, stage: currentStage, years: years
            ) else { continue }
            let odds = competition.winProbability(for: softSkills, years: years)
            if Double.random(in: 0...1) < odds {
                award(competition.achievement, icon: competition.icon,
                      category: .entertainment, weight: competition.fameWeight)
                competitionWins += 1
                celebrateIfLucky(odds)
                recordStatus("🏆", "Won \(competition.achievement)")
                competitionWinMessage = "You won the \(competition.name) and earned the “\(competition.achievement)” title — a lasting boost to your reputation."
                showCompetitionWinAlert = true
            }
        }
        lastCompetitionWins = competitionWins

        // Service any venture loan: interest accrues first, then it's repaid from
        // this year's savings as far as they stretch. A flopped venture still owes
        // — the debt (and its interest) outlives the venture that borrowed it.
        if outstandingLoan > 0 {
            outstandingLoan = Int((Double(outstandingLoan) * (1 + GameConstants.ventureLoanAnnualInterest)).rounded())
            let repayment = min(max(0, savings), outstandingLoan)
            savings -= repayment
            outstandingLoan -= repayment
            if outstandingLoan == 0 && repayment > 0 {
                recordStatus("🏦", "Paid off your venture loan")
            }
        }

        // Service any student loan: interest accrues (at a gentler rate than a
        // venture loan), then it's repaid from whatever savings are left after the
        // venture loan. It lingers through lean years and clears once earnings
        // catch up — an expensive early degree stays with you until then.
        if studentLoan > 0 {
            studentLoan = Int((Double(studentLoan) * (1 + GameConstants.studentLoanAnnualInterest)).rounded())
            let repayment = min(max(0, savings), studentLoan)
            savings -= repayment
            studentLoan -= repayment
            if studentLoan == 0 && repayment > 0 {
                recordStatus("🎓", "Paid off your student loan")
            }
        }
    }

    /// Resolves an economic downturn for the year: pulls risky offers from the
    /// market and rolls the player's current job against the base job-loss risk.
    /// The downturn is surfaced to the player only through the header recession
    /// note (see `economyInRecession`), not a pop-up.
    private func applyEconomicTurmoil() {
        // Hiring freezes for this year's list in cyclical, discretionary-spending
        // sectors (travel, dining, entertainment, retail) — first to pull postings
        // in a bear market.
        availableJobs = availableJobs.filter { !$0.category.isCyclical }

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

    /// Attempts to launch an entrepreneurial venture by investing `investedCapital`
    /// of the player's own savings — topped up, once savings run out, by a loan of
    /// up to `maxVentureLoan` (2× annual income). The stake is committed up front;
    /// success makes the venture the player's occupation (earning its income),
    /// while failure loses the entire stake. Any borrowed portion becomes an
    /// `outstandingLoan` that must be repaid regardless of the outcome. Odds come
    /// from `Job.founderSuccessProbability` (industry experience + soft-skill fit,
    /// with capital a supporting factor). Returns true on success.
    @discardableResult
    func foundVenture(_ job: Job, investedCapital: Int) -> Bool {
        // Savings fund the stake first; anything beyond them (up to the loan cap)
        // is borrowed against income and booked as debt.
        let stake = min(max(0, investedCapital), maxVentureStake)
        let borrowed = borrowedPortion(ofStake: stake)
        let probability = job.founderSuccessProbability(for: self, investedCapital: stake)
        savings -= (stake - borrowed)          // spend savings first
        if borrowed > 0 {
            outstandingLoan += borrowed        // the rest is a loan
            recordStatus("🏦", "Borrowed \(borrowed.formatted(.number)) $ to fund your venture")
        }
        let success = Double.random(in: 0...1) < probability
        if success {
            let previous = currentOccupation
            currentOccupation = job             // the venture is now the player's job
            if let previous, previous.id != job.id {
                recordStatus("🚪", "Left \(previous.baseTitle) to go all-in on your venture")
            }
            recordStatus("🚀", "Founded \(job.baseTitle) — you're now CEO")
        }
        // On failure the committed stake is lost in full.
        return success
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

    /// Founder-cluster soft skills weighed when investors size up a round.
    private static let investmentRoundSkills: [WritableKeyPath<SoftSkills, Int>] = [
        \.visionaryThinkingAndAmbition, \.persuasionAndNegotiation,
        \.leadershipAndInfluence, \.communicationAndNetworking,
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
        let fit = Player.investmentRoundSkills.reduce(0.0) { acc, kp in
            acc + min(Double(softSkills[keyPath: kp]) / Double(Player.investmentRoundSkillReference), 1.0)
        } / Double(Player.investmentRoundSkills.count)
        let network = networkBonus(for: job.category)   // up to +0.12
        let fame = investmentRoundFameBonus()           // up to +0.55 (business fame)
        return max(0.05, min(0.95, 0.12 + fit * 0.35 + network + fame))
    }

    /// Headline capital a *successful* investment round realises for the player
    /// as equity liquidity — a multiple of their current pay. The actual payout
    /// is this value jittered in `resolveExecutiveDecision`.
    func investmentRoundProjectedRaise() -> Int {
        guard let job = currentOccupation else { return 0 }
        return job.annualIncome * 3
    }

    /// Fair-market value of the player's equity stake — the anchor the Boardroom's
    /// asking-price slider is built around and the yardstick a buyer measures an
    /// offer against. Vested value grows with pay and tenure in the seat (~0.75×
    /// pay on day one up to a 2.5× cap).
    func shareStakeValue() -> Int {
        guard let job = currentOccupation else { return 0 }
        let years = experienceByRole[job.baseTitle, default: 0]
        let multiple = min(0.75 + Double(years) * 0.15, 2.5)
        return Int((Double(job.annualIncome) * multiple).rounded())
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
                currentOccupation = nil
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
            let base = Double(investmentRoundProjectedRaise())
            let cash = Int((base * Double.random(in: 0.8...1.4)).rounded())
            savings += cash
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
            recordStatus(decision.icon, "Closed an investment round for \(job.baseTitle) — raised \(cash.formatted(.number)) $")
            return ExecutiveDecision.Outcome(decision: decision, success: true, cash: cash, fameTitle: title)
        }
    }

    func reset() {
        let fresh = Player()
        difficulty = fresh.difficulty
        avatar = fresh.avatar
        fameAwards = fresh.fameAwards
        lastCompetitionWins = fresh.lastCompetitionWins
        turmoilYearsRemaining = fresh.turmoilYearsRemaining
        economyInRecession = fresh.economyInRecession
        lastSideHustleEarnings = fresh.lastSideHustleEarnings
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
        lockedTrainings = fresh.lockedTrainings
        lockedHobbies = fresh.lockedHobbies
        networkByCategory = fresh.networkByCategory
        sportYears = fresh.sportYears
        executiveActionsThisYear = []
        availableJobs = fresh.availableJobs
    }
}

