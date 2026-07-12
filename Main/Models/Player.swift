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

/// The player's currently-active startup (realistic mode only). Founded by
/// taking on a founder Job; each year `advanceYear` rolls for a buyout offer
/// and — on a hit — sets `Player.pendingStartupOffer` so the UI can present a
/// Sell-or-Hold dialog. Holding advances `rungIndex` to the next founder rung
/// (and updates `currentOccupation` accordingly); selling banks the offer and
/// clears `activeStartup`. A recession forces a fire-sale liquidation.
///
/// `rungIndex` corresponds to the four founder rungs declared in `JobCatalog`
/// (0 = Side Hustler … 3 = Serial Entrepreneur). `yearsHeld` is the count of
/// year-rolls since the venture was founded (or last grew), purely informational
/// for the dialog copy.
struct ActiveStartup: Hashable {
    var rungIndex: Int
    var yearsHeld: Int
}

/// A single entry on the player's fame shelf: a named accolade that
/// builds reputation — a competition trophy, a fame-building side hustle, or a
/// noticed spare-time project. Fame is the third pillar of career
/// capital alongside soft and hard skills: *what you're known for*, rather than
/// what you can do. Each entry carries its own display icon and reputation
/// `weight`; `count` levels it up when the same accolade is earned again (a
/// repeatable project shipped three good years reads as ×3, not three rows).
/// `industry` scopes the reputation — it only lifts hiring odds for roles in
/// that same `JobCategory` (see `Player.fameHireBonus(for:)`); `nil` is general
/// renown that helps a little everywhere.
struct FameAward: Identifiable, Hashable {
    let title: String
    let icon: String
    let industry: JobCategory?
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
    func award(_ title: String, icon: String, industry: JobCategory?, weight: Double) {
        if let i = fameAwards.firstIndex(where: { $0.title == title }) {
            fameAwards[i].count += 1
        } else {
            fameAwards.append(FameAward(title: title, icon: icon, industry: industry, weight: weight))
        }
    }

    /// Number of competitions won in the year just advanced (0 when none).
    /// Surfaced in the header alongside the confetti.
    @Published var lastCompetitionWins: Int = 0

    /// Drives the competition-win celebration dialog. Set when the automatic
    /// yearly contest for the sport trained this year is won (see `advanceYear`).
    @Published var showCompetitionWinAlert: Bool = false
    @Published var competitionWinMessage: String = ""

    /// The player's current startup if they're operating one (realistic mode
    /// only). Created when a founder Job is launched via `foundVenture`;
    /// resolved annually by `advanceYear` into either a buyout dialog or a
    /// recession-driven bankruptcy. `nil` outside the startup loop.
    @Published var activeStartup: ActiveStartup?

    /// Buyout amount waiting on a Sell-or-Hold decision from the player. Set
    /// by `advanceYear` when the annual roll lands an offer; cleared the moment
    /// the player resolves the offer via `acceptStartupOffer` or `holdStartup`.
    @Published var pendingStartupOffer: Int?

    /// One-shot trigger for the buyout-offer sheet. Bound by `RootView`; the
    /// `Sell` / `Hold & grow` buttons flip it off.
    @Published var showStartupOfferSheet: Bool = false

    /// One-shot trigger for the bankruptcy notice that fires when a recession
    /// forces a fire-sale of the player's startup.
    @Published var showStartupBankruptcyAlert: Bool = false

    /// Salvage value paid out by the most recent forced bankruptcy. Used by
    /// the bankruptcy alert message; not a header note.
    @Published var lastBankruptcySalvage: Int = 0

    /// Weighted sum of every banked trophy, where each title's contribution
    /// comes from its source's `fameWeight` (a local 5K is worth less than an
    /// Olympic medal). Drives both `fameHireBonus(for:)` and the fame lift on
    /// Show Business side hustles.
    var fameScore: Double {
        fameAwards.reduce(0.0) { $0 + $1.totalWeight }
    }

    /// Weighted fame relevant to a field: same-industry awards plus general
    /// (industry-less) renown. Only this counts toward the hire and promotion
    /// fame bonuses — a tech portfolio does nothing for a stage audition. Each
    /// `FameAward` carries the industry it was earned in (see `FameAward.industry`).
    func famePoints(for category: JobCategory) -> Double {
        fameAwards.reduce(0.0) { acc, award in
            (award.industry == category || award.industry == nil) ? acc + award.totalWeight : acc
        }
    }

    /// Fame totals grouped by the industry each award was earned in, for display.
    /// A `nil` industry is general (industry-less) renown. Ordered by score,
    /// highest first, so the field the player is best known in leads.
    var fameByIndustry: [(industry: JobCategory?, score: Double)] {
        var totals: [JobCategory?: Double] = [:]
        for award in fameAwards {
            totals[award.industry, default: 0] += award.totalWeight
        }
        return totals
            .map { (industry: $0.key, score: $0.value) }
            .sorted { $0.score > $1.score }
    }

    /// Additive hire-probability boost from fame for a role in `category`.
    /// Ordinary roles get a modest lift (capped +0.20). **Top positions** weight
    /// reputation far more heavily — a public profile is often what separates the
    /// shortlist for a leadership seat — so they earn a steeper per-point rate and
    /// a higher cap (+0.40). See `Job.isTopLeadership` / `Job.hireProbability`.
    func fameHireBonus(for category: JobCategory, topPosition: Bool = false) -> Double {
        let rate = topPosition ? 0.08 : 0.04
        let cap = topPosition ? 0.40 : 0.20
        return min(cap, famePoints(for: category) * rate)
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

    /// Whether a downturn cost the player their job in the year just advanced.
    /// Drives the header layoff notice so a sudden firing doesn't go unnoticed.
    @Published var lostJobThisYear: Bool = false

    /// One-shot trigger for the layoff pop-up. Set the moment a downturn fires
    /// the player; the alert clears it when dismissed (the header note, driven
    /// by `lostJobThisYear`, lingers for the rest of the year as a reminder).
    @Published var showLayoffAlert: Bool = false

    /// Incremented on a celebratory stroke of luck (a promotion, or a long-shot
    /// college admission); the game view watches it to fire the confetti cannon.
    @Published var celebrationTrigger: Int = 0

    /// Running log of player-facing milestones — completions, promotions, hires,
    /// layoffs, unlocked credentials — surfaced by `StatusBarView` (collapsed
    /// shows the latest, expanded shows the full history). Append-only inside
    /// `Player`; cleared on `reset()`.
    @Published var statusEvents: [StatusEvent] = []

    /// Appends a milestone to `statusEvents`, tagged with the player's current
    /// age. Called from year-progression hooks and from the few mutating
    /// helpers (hiring, founding a venture, graduating) that don't pass
    /// through `advanceYear`.
    func recordStatus(_ icon: String, _ message: String) {
        statusEvents.append(StatusEvent(age: age, icon: icon, message: message))
    }

    /// Whether the player has met the current setting's win condition:
    /// a top leadership ("C-suite") role in Simplified, or a million in
    /// savings in the realistic settings.
    var goalMet: Bool {
        if isSimplified {
            return currentOccupation?.isTopLeadership ?? false
        }
        return savings >= GameConstants.millionGoal
    }

    @Published var age: Int

    /// Game Center leaderboard score: "wealth velocity" — savings per year of
    /// life. Reaching wealth younger scores higher. Floored at 0.
    var leaderboardScore: Int { age > 0 ? max(0, savings) / age : 0 }

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
    /// Network from cross-industry events (`CareerEvent.category == nil`). Counts
    /// toward every field on top of the industry-specific totals.
    @Published var generalNetwork: Int = 0

    /// Total years trained in each `Sport`. A new year is added at year-end for
    /// every sport the player committed their spare-time slot to. Drives the
    /// competition sport gate (a sport must have ≥1 year for its tagged
    /// competitions to appear) and the `sportFit` bonus inside `winProbability`.
    @Published var sportYears: [Sport: Int] = [:]
    @Published var appliedJobIds: Set<String> = []
    /// Schools (by `Education.id`) the player has already applied to this year.
    /// One admission attempt per school per year, so a rejection can't be
    /// brute-forced — the player must try another school or wait a year.
    @Published var appliedSchoolIds: Set<String> = []
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

    /// Attends a professional event in the given `role`, applying its soft-skill
    /// nudges and banking its network points (per-industry, or general for a
    /// cross-industry event). A presenter banks more network; the fame
    /// award presenting earns is deferred to `advanceYear` so a selection
    /// toggled off before the year advances stays fully reversible (mirror of
    /// `dropEvent`).
    func attendEvent(
        _ event: CareerEvent,
        role: EventRole = .participant,
        into selectedEvents: inout [String: EventRole]
    ) {
        guard selectedEvents[event.id] == nil else { return }
        // Industry events need ≥1 year in that field; presenting needs the full
        // veteran gate (safety net; the view locks these too).
        guard event.meetsExperienceRequirement(for: experience) else { return }
        let role = (role == .presenter && event.canPresent(with: experience)) ? role : .participant
        selectedEvents[event.id] = role
        for ability in event.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] = min(softSkills[keyPath: kp] + ability.weight, 10)
        }
        let points = event.networkPoints(for: role)
        if let category = event.category {
            networkByCategory[category, default: 0] += points
        } else {
            generalNetwork += points
        }
    }

    func dropEvent(_ event: CareerEvent, from selectedEvents: inout [String: EventRole]) {
        guard let role = selectedEvents.removeValue(forKey: event.id) else { return }
        for ability in event.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] -= ability.weight
        }
        let points = event.networkPoints(for: role)
        if let category = event.category {
            networkByCategory[category, default: 0] -= points
        } else {
            generalNetwork -= points
        }
    }

    /// Years of work experience that count toward roles in `category`: the years
    /// banked directly in that industry plus any years in industries it credits
    /// (see `JobCategory.creditedExperienceCategories`). This is how
    /// entrepreneurship experience — whether from running a founder venture or
    /// from spare-time entrepreneurship projects — counts toward Business roles,
    /// and vice versa.
    func industryExperience(for category: JobCategory) -> Int {
        let own = experience[category] ?? 0
        let credited = category.creditedExperienceCategories.reduce(0) { total, other in
            total + (experience[other] ?? 0)
        }
        return own + credited
    }

    /// Total professional-network points relevant to a field: its industry
    /// network plus the general (cross-industry) network.
    func networkPoints(for category: JobCategory) -> Int {
        networkByCategory[category, default: 0] + generalNetwork
    }

    /// Additive boost to a job's realistic-mode hire probability from the
    /// player's network in that field. Diminishing — each point adds 1.5% up to
    /// a 0.12 ceiling, so a network helps without ever guaranteeing an offer.
    func networkBonus(for category: JobCategory) -> Double {
        min(0.12, Double(networkPoints(for: category)) * 0.015)
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
        min(0.15, famePoints(for: category) * 0.03)
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
                                 fame: 0, tenure: 0, tenureYears: 0, total: 0)
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
        let total = min(1.0, core + network + fame + tenureBoost)
        return PromotionOdds(promotes: true, readinessBase: core, network: network,
                             fame: fame, tenure: tenureBoost, tenureYears: years, total: total)
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
        for (id, role) in appUIState.selectedEvents where role == .presenter {
            guard let event = EventCatalog.byId[id],
                  let title = event.presenterFameTitle else { continue }
            award(title, icon: event.icon, industry: event.category, weight: event.presenterFameWeight)
            recordStatus("🎤", "Presented at \(event.name)")
        }
        appUIState.selectedEvents.removeAll()

        // Charge tuition for the year the player is enrolled in a tertiary program.
        if let edu = currentEducation,
           let yearsLeft = appUIState.yearsLeftToGraduation,
           yearsLeft > 0,
           edu.profile != nil {
            savings -= edu.annualTuition
        }

        appUIState.yearsLeftToGraduation? -= 1
        if appUIState.yearsLeftToGraduation == 0 {
            if let currentEducation {
                degrees.append(currentEducation)
                recordStatus("🎓", "Graduated — \(currentEducation.degreeName)")
                graduationMessage = "Congratulations! You completed your \(currentEducation.degreeName). Time to figure out the next step."
                showGraduationAlert = true
                celebrationTrigger += 1
            }
            appUIState.yearsLeftToGraduation = nil
            currentEducation = nil
        }

        appliedJobIds.removeAll()
        appliedSchoolIds.removeAll()
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

            // Promotion (realistic mode): a yearly shot at a raise, its odds set
            // by the player's promotion-readiness soft skills, tenure, and network.
            // A win bumps pay and fires the celebration confetti. Frozen during a
            // downturn — no raises while the economy is in a recession.
            if !isSimplified, !recessionThisYear, let current = currentOccupation,
               Double.random(in: 0...1) < promotionChance(for: current) {
                let raise = Double.random(in: GameConstants.promotionRaise)
                let newIncome = Int((Double(current.annualIncome) * (1 + raise)).rounded())
                currentOccupation?.annualIncome = newIncome
                lastPromotionRaisePct = Int((raise * 100).rounded())
                celebrationTrigger += 1
                showPromotionAlert = true
                promotionMessage = "Your hard work paid off — you've been promoted in your role as \(current.baseTitle). Your pay rises \(lastPromotionRaisePct)% to \(newIncome.formatted(.number)) $ a year."
                recordStatus("⬆️", "Promoted in \(current.baseTitle) — pay +\(lastPromotionRaisePct)%")
            }
        }

        // Spare-time ventures (money hustles + fame projects, now one system).
        // No money is staked. A money venture pays out in full on success (unlike
        // salary), surfaced in the header. A fame venture banks an industry-scoped
        // award and grows the soft skills it drew on — the founder-cluster axes no
        // hobby can build. A flop yields nothing. Fame ventures snowball with the
        // player's reputation (see SideHustle.successProbability); all are
        // repeatable year after year.
        var sideHustleNet = 0
        var famedVentures = 0
        for id in appUIState.selectedSideHustles {
            guard let hustle = SideHustleCatalog.byId[id],
                  hustle.meetsPrerequisite(for: softSkills) else { continue }
            // A year committed to an experience-building venture (the
            // entrepreneurship plays) counts as real work experience in its
            // field — banked whether or not the venture pays off, because the
            // reps happen either way. Because Business credits entrepreneurship
            // (see `JobCategory.creditedExperienceCategories`), this also moves
            // the player toward Business roles. The player's existing years then
            // lift the odds below.
            let experienceYears = hustle.experienceCategory.map { industryExperience(for: $0) } ?? 0
            if let cat = hustle.experienceCategory {
                experience[cat, default: 0] += 1
                recordStatus("📅", "Banked a year of \(cat.rawValue) experience running \(hustle.label)")
            }
            let outcome = hustle.resolve(for: softSkills, fameScore: fameScore, experienceYears: experienceYears)
            if outcome.success {
                savings += outcome.credit
                sideHustleNet += outcome.credit
                if outcome.credit > 0 {
                    recordStatus(hustle.icon, "\(hustle.label) paid \(outcome.credit.formatted(.number)) $")
                }
                if let grant = outcome.grantedFame {
                    award(grant.title, icon: hustle.icon, industry: grant.industry, weight: grant.weight)
                    for ability in hustle.growth {
                        softSkills[keyPath: ability.keyPath] = min(softSkills[keyPath: ability.keyPath] + ability.weight, 10)
                    }
                    famedVentures += 1
                    recordStatus("🌟", "\(hustle.label) earned fame in \(grant.industry.rawValue)")
                }
            } else {
                recordStatus(hustle.icon, "\(hustle.label) didn't pan out this year")
            }
        }
        if famedVentures > 0 { celebrationTrigger += 1 }
        lastSideHustleEarnings = sideHustleNet
        appUIState.selectedSideHustles.removeAll()

        // Competitions: training a sport now automatically enters you into its
        // top eligible contest — no menu, no entry fee. Win odds start low and
        // climb with the trained years (and the soft skills training builds).
        // A win pays the prize and banks a lasting achievement (reputation that
        // helps land Show Business roles), then surfaces a celebration dialog.
        var competitionWins = 0
        let currentStage = LifeStage.forAge(age)
        for sport in competedSports {
            let years = sportYears[sport, default: 0]
            guard let competition = CompetitionCatalog.bestCompetition(
                forSport: sport, stage: currentStage, years: years
            ) else { continue }
            if Double.random(in: 0...1) < competition.winProbability(for: softSkills, years: years) {
                savings += competition.prize
                award(competition.achievement, icon: competition.icon,
                      industry: .showBusiness, weight: competition.fameWeight)
                competitionWins += 1
                recordStatus("🏆", "Won \(competition.achievement)")
                competitionWinMessage = "You won the \(competition.name) and earned the “\(competition.achievement)” title — a \(competition.prize.formatted(.number)) $ prize and a boost to your reputation."
                showCompetitionWinAlert = true
            }
        }
        lastCompetitionWins = competitionWins
        if competitionWins > 0 { celebrationTrigger += 1 }

        // Startup loop (realistic mode only): while the player runs an active
        // venture, each year either pays out a buyout offer (Sell or Hold &
        // grow), brushes off without an offer (operating as usual), or — in a
        // recession — forces a fire-sale liquidation. The rung's salary is
        // already banked by the occupation pay block above.
        if !isSimplified, var startup = activeStartup,
           let founderJob = currentOccupation,
           let target = founderJob.targetCapital {
            startup.yearsHeld += 1
            if recessionThisYear {
                let payout = FounderLadder.bankruptcyPayout(forRungIndex: startup.rungIndex, targetCapital: target)
                savings += payout
                lastBankruptcySalvage = payout
                showStartupBankruptcyAlert = true
                recordStatus("📉", "Bankruptcy — sold \(founderJob.baseTitle) at fire-sale for \(payout.formatted(.number)) $")
                activeStartup = nil
                pendingStartupOffer = nil
                showStartupOfferSheet = false
                currentOccupation = nil
            } else {
                let chance = FounderLadder.offerProbability(
                    forRungIndex: startup.rungIndex,
                    founderSkillFit: founderJob.founderSkillFit(for: self)
                )
                if Double.random(in: 0...1) < chance {
                    let offer = FounderLadder.randomOffer(forRungIndex: startup.rungIndex, targetCapital: target)
                    pendingStartupOffer = offer
                    showStartupOfferSheet = true
                    celebrationTrigger += 1
                    recordStatus("💼", "Buyout offer for \(founderJob.baseTitle): \(offer.formatted(.number)) $")
                }
                activeStartup = startup
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
        // Founders don't get laid off — they go bankrupt, which the startup
        // loop in `advanceYear` handles as a forced fire-sale liquidation.
        // Skipping the regular layoff roll prevents a double-impact (clearing
        // the occupation here while the startup loop also resolves the sale).
        if activeStartup != nil { return }
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

    /// Applies for admission to a school (realistic mode). Records the attempt
    /// (one per school per year) and returns whether the player was admitted. The
    /// caller performs enrollment on success.
    @discardableResult
    func applyToSchool(_ education: Education) -> Bool {
        appliedSchoolIds.insert(education.id)
        return Double.random(in: 0...1) < education.admissionProbability(player: self)
    }

    /// Applies for a job at the given salary. Returns true if hired.
    /// Side effects: marks the job as applied; if hired, sets currentOccupation with the agreed salary.
    @discardableResult
    func applyForJob(_ job: Job, requestedSalary: Int) -> Bool {
        appliedJobIds.insert(job.applicationKey)
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
    /// of the player's own savings. The stake is committed up front; success makes
    /// the player a founder (earning the rung's income), while failure salvages
    /// half the stake. In realistic mode, success also bootstraps the multi-year
    /// startup loop (`activeStartup` is set to the rung index so subsequent
    /// `advanceYear` calls roll for buyouts and surface a Sell-or-Hold dialog).
    /// Returns true on success.
    @discardableResult
    func foundVenture(_ job: Job, investedCapital: Int) -> Bool {
        appliedJobIds.insert(job.applicationKey)
        let stake = min(max(0, investedCapital), savings)
        let probability = job.founderSuccessProbability(for: self, investedCapital: stake)
        savings -= stake                       // commit the capital
        let success = Double.random(in: 0...1) < probability
        if success {
            currentOccupation = job             // keeps the rung's annualIncome
            recordStatus("🚀", "Founded as \(job.baseTitle)")
            if !isSimplified, let rung = FounderLadder.rungIndex(forTitle: job.id) {
                activeStartup = ActiveStartup(rungIndex: rung, yearsHeld: 0)
            }
        } else {
            savings += stake / 2                // salvage half of a failed venture
        }
        return success
    }

    /// Accepts the pending buyout offer: banks the cash, ends the venture, and
    /// clears the founder occupation. The player is now between jobs (free to
    /// apply for the next thing or found again from scratch). No-op if there
    /// is no offer pending.
    func acceptStartupOffer() {
        guard let offer = pendingStartupOffer else { return }
        savings += offer
        let exitedBaseTitle = currentOccupation?.baseTitle ?? "venture"
        recordStatus("🤝", "Sold \(exitedBaseTitle) for \(offer.formatted(.number)) $")
        activeStartup = nil
        pendingStartupOffer = nil
        showStartupOfferSheet = false
        currentOccupation = nil
        celebrationTrigger += 1
    }

    /// Holds & grows: declines the offer in exchange for advancing to the next
    /// founder rung. Updates `currentOccupation` to the next rung's Job so the
    /// player earns its (larger) salary going forward. At the top rung the
    /// venture simply keeps running — next year's roll re-prices the offer.
    func holdStartup() {
        guard var startup = activeStartup else {
            pendingStartupOffer = nil
            showStartupOfferSheet = false
            return
        }
        let nextRung = min(startup.rungIndex + 1, FounderLadder.count - 1)
        if nextRung != startup.rungIndex {
            startup.rungIndex = nextRung
            startup.yearsHeld = 0
            if let upgraded = FounderLadder.job(at: nextRung, in: availableJobs)
                ?? FounderLadder.job(at: nextRung, in: JobCatalog.allJobs()) {
                currentOccupation = upgraded
                recordStatus("📈", "Held & grew into \(upgraded.baseTitle)")
            }
        } else {
            recordStatus("📈", "Declined buyout — kept growing the company")
        }
        activeStartup = startup
        pendingStartupOffer = nil
        showStartupOfferSheet = false
    }

    func reset() {
        let fresh = Player()
        difficulty = fresh.difficulty
        avatar = fresh.avatar
        fameAwards = fresh.fameAwards
        lastCompetitionWins = fresh.lastCompetitionWins
        activeStartup = fresh.activeStartup
        pendingStartupOffer = fresh.pendingStartupOffer
        showStartupOfferSheet = fresh.showStartupOfferSheet
        showStartupBankruptcyAlert = fresh.showStartupBankruptcyAlert
        lastBankruptcySalvage = fresh.lastBankruptcySalvage
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
        lockedTrainings = fresh.lockedTrainings
        lockedHobbies = fresh.lockedHobbies
        networkByCategory = fresh.networkByCategory
        generalNetwork = fresh.generalNetwork
        sportYears = fresh.sportYears
        appliedJobIds = []
        appliedSchoolIds = []
        availableJobs = fresh.availableJobs
    }
}

