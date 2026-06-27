import Foundation
import SwiftUI

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

    /// Titled trophies won in `Competition`s. Each win appends its achievement
    /// title; the count drives `achievementHireBonus`. Cosmetic titles double as
    /// a fame score that helps land Show Business roles.
    @Published var achievements: [String] = []

    /// Number of competitions won in the year just advanced (0 when none).
    /// Surfaced in the header alongside the confetti.
    @Published var lastCompetitionWins: Int = 0

    /// Additive hire-probability boost for fame-driven Show Business roles from
    /// the player's competition achievements. Diminishing, capped at +0.20 — a
    /// decorated competitor is a draw for casting directors and sponsors.
    var achievementHireBonus: Double { min(0.20, Double(achievements.count) * 0.04) }

    /// Years a prolonged recession still has to run. While positive, each
    /// `advanceYear` keeps the downturn in force (hiring freeze + layoff risk)
    /// and counts down. Zero means the economy is not in an ongoing recession.
    @Published var turmoilYearsRemaining: Int = 0

    /// Whether the economy is in a downturn this year (a fresh or ongoing
    /// recession). Drives the header recession note; while true, hiring at risky
    /// employers and promotions are frozen.
    @Published var economyInRecession: Bool = false

    /// Net result of last year's side hustles (payouts and salvage minus the
    /// stakes). Surfaced in the header; positive when the ventures paid off.
    @Published var lastSideHustleEarnings: Int = 0

    /// Size of last year's promotion raise as a whole-number percent (0 when the
    /// player wasn't promoted). Surfaced in the header alongside the confetti.
    @Published var lastPromotionRaisePct: Int = 0

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
    @Published var lockedCertifications: Set<Certification>
    @Published var lockedPortfolio: Set<Project>
    @Published var lockedLicenses: Set<License>
    @Published var lockedHobbies: Set<String>
    /// Professional network built by attending industry `CareerEvent`s, keyed by
    /// the event's industry. Improves hiring odds on that field's postings and
    /// the chance of promotion while working in it (see `networkBonus`).
    @Published var networkByCategory: [JobCategory: Int] = [:]
    /// Network from cross-industry events (`CareerEvent.category == nil`). Counts
    /// toward every field on top of the industry-specific totals.
    @Published var generalNetwork: Int = 0
    @Published var appliedJobIds: Set<String> = []
    /// Schools (by `Education.id`) the player has already applied to this year.
    /// One admission attempt per school per year, so a rejection can't be
    /// brute-forced — the player must try another school or wait a year.
    @Published var appliedSchoolIds: Set<String> = []
    /// Certifications whose exam has been attempted this year (by `rawValue`).
    /// One attempt per cert per year — a failed exam can't be brute-forced;
    /// the player must improve their skills and retry next year. Cleared in
    /// `advanceYear`.
    @Published var attemptedCertificationIds: Set<String> = []
    /// Jobs offered to the player this year. Re-shuffled (and re-rolled for
    /// company tier / salary variance) every time `advanceYear` runs, so the
    /// listing feels different each game year.
    @Published var availableJobs: [Job] = []

    init(
        age: Int = GameConstants.startingAge,
        softSkills: SoftSkills = SoftSkills(
            analyticalReasoningAndProblemSolving: Int.random(in: 0...1),
            creativityAndInsightfulThinking: Int.random(in: 0...1),
            communicationAndNetworking: Int.random(in: 0...1),
            persuasionAndNegotiation: Int.random(in: 0...1),
            leadershipAndInfluence: Int.random(in: 0...1),
            visionaryThinkingAndAmbition: Int.random(in: 0...1),
            riskTakingAndInitiative: Int.random(in: 0...1),
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
        lockedCertifications: Set<Certification> = [],
        lockedPortfolio: Set<Project> = [],
        lockedLicenses: Set<License> = [],
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
        self.lockedCertifications = lockedCertifications
        self.lockedPortfolio = lockedPortfolio
        self.lockedLicenses = lockedLicenses
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
            softSkills[keyPath: kp] += ability.weight
        }
    }

    func deselectHobby(_ hobby: Hobby, from selectedActivities: inout Set<String>) {
        guard selectedActivities.remove(hobby.label) != nil else { return }
        for ability in hobby.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] -= ability.weight
        }
    }

    // MARK: - Professional events & network

    /// Attends a professional event: charges its cost, applies its soft-skill
    /// nudges, and banks its network points (per-industry, or general for a
    /// cross-industry event). Mirror of `dropEvent` so a selection toggled off
    /// before the year advances is fully reversed.
    func attendEvent(_ event: CareerEvent, into selectedEvents: inout Set<String>) {
        guard !selectedEvents.contains(event.id) else { return }
        selectedEvents.insert(event.id)
        savings -= event.cost
        for ability in event.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] += ability.weight
        }
        if let category = event.category {
            networkByCategory[category, default: 0] += event.networkWeight
        } else {
            generalNetwork += event.networkWeight
        }
    }

    func dropEvent(_ event: CareerEvent, from selectedEvents: inout Set<String>) {
        guard selectedEvents.remove(event.id) != nil else { return }
        savings += event.cost
        for ability in event.abilities {
            let kp = ability.keyPath as WritableKeyPath<SoftSkills, Int>
            softSkills[keyPath: kp] -= ability.weight
        }
        if let category = event.category {
            networkByCategory[category, default: 0] -= event.networkWeight
        } else {
            generalNetwork -= event.networkWeight
        }
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

    // MARK: - Training purchase / refund

    /// Sits this year's certification exam: pays the fee and consumes the
    /// training slot (win or lose), then rolls a pass against the cert's
    /// `passProbability`. A pass selects the cert (committed at year end); a
    /// fail leaves the player out the fee. One attempt per cert per year — a
    /// fail means studying again next year. Returns whether the exam was passed.
    @discardableResult
    func attemptCertification(_ cert: Certification, into selectedCertifications: inout Set<Certification>, activities selectedActivities: inout Set<String>) -> Bool {
        guard case .ok(let cost) = cert.certificationRequirements(self) else { return false }
        guard !attemptedCertificationIds.contains(cert.rawValue) else { return false }
        attemptedCertificationIds.insert(cert.rawValue)
        selectedActivities.insert("cert:\(cert.rawValue)")
        savings -= cost
        let passed = Double.random(in: 0...1) < cert.passProbability(for: self)
        if passed {
            selectedCertifications.insert(cert)
        }
        return passed
    }

    func purchaseLicense(_ lic: License, into selectedLicenses: inout Set<License>, activities selectedActivities: inout Set<String>) {
        guard case .ok(let cost) = lic.licenseRequirements(self) else { return }
        selectedLicenses.insert(lic)
        selectedActivities.insert("lic:\(lic.rawValue)")
        savings -= cost
    }

    func refundLicense(_ lic: License, from selectedLicenses: inout Set<License>, activities selectedActivities: inout Set<String>) {
        guard selectedLicenses.remove(lic) != nil else { return }
        selectedActivities.remove("lic:\(lic.rawValue)")
        savings += lic.costForLicense
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

    /// Annual promotion probability for a job: the employer tier's base chance
    /// scaled by promotion readiness (40%–100% of the base, so soft skills move
    /// the odds while the tier keeps startups ahead of enterprises), plus a
    /// professional-network bonus for the job's industry — attending that
    /// field's summits and conferences makes a raise more likely — and a tenure
    /// bonus for years already spent in the role.
    func promotionChance(for job: Job) -> Double {
        let base = job.companyTier.promotionBaseChance
        guard base > 0 else { return 0 }
        let core = base * (0.4 + 0.6 * promotionReadiness)
        // Tenure in the current role makes a promotion more likely — seasoned
        // employees are next in line — with diminishing returns (capped +0.10).
        let tenure = experienceByRole[job.baseTitle, default: 0]
        let tenureBoost = min(0.10, Double(tenure) * 0.02)
        return min(1.0, core + networkPromotionBonus(for: job.category) + tenureBoost)
    }

    // MARK: - Year progression

    func advanceYear(appUIState: AppUIState) {
        age += 1
        lastPromotionRaisePct = 0
        lastCompetitionWins = 0
        lostJobThisYear = false

        hardSkills.certifications.formUnion(appUIState.selectedCertifications)
        hardSkills.licenses.formUnion(appUIState.selectedLicenses)
        hardSkills.portfolioItems.formUnion(appUIState.selectedPortfolio)

        lockedCertifications.formUnion(appUIState.selectedCertifications)
        lockedPortfolio.formUnion(appUIState.selectedPortfolio)
        lockedLicenses.formUnion(appUIState.selectedLicenses)

        appUIState.selectedActivities.removeAll()
        // Events were charged and their network/soft-skill effects applied when
        // attended; just clear this year's picks so next year starts fresh.
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
            appUIState.decisionText = "You're done with your degree! What's your next step?"
            appUIState.showDecisionSheet.toggle()
            if let currentEducation {
                degrees.append(currentEducation)
            }
            appUIState.yearsLeftToGraduation = nil
            currentEducation = nil
        }

        appliedJobIds.removeAll()
        appliedSchoolIds.removeAll()
        attemptedCertificationIds.removeAll()
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
            currentOccupation?.companyTier = CompanyTier.random(category: job.category, income: job.income, isEntrepreneurial: job.isEntrepreneurial)
            let saved = isSimplified
                ? job.annualIncome
                : Int((Double(job.annualIncome) * difficulty.savingsRate).rounded())
            savings += saved
            experience[job.category, default: 0] += 1
            experienceByRole[job.baseTitle, default: 0] += 1

            // Promotion (realistic mode): a yearly shot at a raise, its odds set
            // by the player's promotion-readiness soft skills and the employer
            // tier (startups promote fast, enterprises slowly). A win bumps pay
            // and fires the celebration confetti. Frozen during a downturn — no
            // raises while the economy is in a recession.
            if !isSimplified, !recessionThisYear, let current = currentOccupation,
               Double.random(in: 0...1) < promotionChance(for: current) {
                let raise = Double.random(in: current.companyTier.promotionRaise)
                let newIncome = Int((Double(current.annualIncome) * (1 + raise)).rounded())
                currentOccupation?.annualIncome = newIncome
                lastPromotionRaisePct = Int((raise * 100).rounded())
                celebrationTrigger += 1
            }
        }

        // Side hustles: resolve every venture taken on this year. Each stakes its
        // capital up front — paid even if it pushes savings into debt — success
        // pays out (banked in full, unlike salary) and a flop salvages half the
        // stake. The year's net is surfaced in the header.
        var sideHustleNet = 0
        for id in appUIState.selectedSideHustles {
            guard let hustle = SideHustleCatalog.byId[id] else { continue }
            savings -= hustle.startupCost
            let outcome = hustle.resolve(for: softSkills)
            savings += outcome.credit
            sideHustleNet += outcome.credit - hustle.startupCost
        }
        lastSideHustleEarnings = sideHustleNet
        appUIState.selectedSideHustles.removeAll()

        // Competitions: resolve every contest entered this year. The entry fee is
        // staked up front (even into debt); a win pays the prize and banks a
        // lasting achievement (reputation that helps land Show Business roles).
        var competitionWins = 0
        for id in appUIState.selectedCompetitions {
            guard let competition = CompetitionCatalog.byId[id] else { continue }
            savings -= competition.entryFee
            if Double.random(in: 0...1) < competition.winProbability(for: softSkills) {
                savings += competition.prize
                achievements.append(competition.achievement)
                competitionWins += 1
            }
        }
        lastCompetitionWins = competitionWins
        if competitionWins > 0 { celebrationTrigger += 1 }
        appUIState.selectedCompetitions.removeAll()
    }

    /// Resolves an economic downturn for the year: pulls risky offers from the
    /// market and rolls the player's current job against its tier's job-loss
    /// risk. The downturn is surfaced to the player only through the header
    /// recession note (see `economyInRecession`), not a pop-up.
    private func applyEconomicTurmoil() {
        // Hiring freezes for this year's list on two fronts:
        //  • Unstable employers (startups and freelance/self-employment, whose
        //    job-loss risk clears the bar) stop hiring entirely.
        //  • Cyclical, discretionary-spending sectors (travel, dining,
        //    entertainment, retail) are first to pull postings in a bear market.
        availableJobs = availableJobs.filter { job in
            job.companyTier.riskFactor < GameConstants.turmoilUnstableTierRisk
                && !job.category.isCyclical
        }

        guard let job = currentOccupation else { return }
        // Job-loss probability is the occupation's calm-economy company-tier risk
        // amplified by how severe the downturn is on this difficulty: a startup on
        // the harshest setting is in grave danger (0.22 × 6, capped), while a
        // government post barely flinches (0.01 × 6 ≈ 6%).
        let lossChance = min(
            GameConstants.turmoilMaxLayoffChance,
            job.companyTier.riskFactor * difficulty.layoffSeverity
        )
        if Double.random(in: 0...1) < lossChance {
            currentOccupation = nil
            lostJobThisYear = true
            showLayoffAlert = true
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
        }
        return hired
    }

    /// Attempts to launch an entrepreneurial venture by investing `investedCapital`
    /// of the player's own savings. The stake is committed up front; success makes
    /// the player a founder (earning the rung's income), while failure salvages
    /// half the stake. Returns true on success.
    @discardableResult
    func foundVenture(_ job: Job, investedCapital: Int) -> Bool {
        appliedJobIds.insert(job.applicationKey)
        let stake = min(max(0, investedCapital), savings)
        let probability = job.founderSuccessProbability(for: self, investedCapital: stake)
        savings -= stake                       // commit the capital
        let success = Double.random(in: 0...1) < probability
        if success {
            currentOccupation = job             // keeps the rung's annualIncome
        } else {
            savings += stake / 2                // salvage half of a failed venture
        }
        return success
    }

    func reset() {
        let fresh = Player()
        difficulty = fresh.difficulty
        avatar = fresh.avatar
        achievements = fresh.achievements
        lastCompetitionWins = fresh.lastCompetitionWins
        turmoilYearsRemaining = fresh.turmoilYearsRemaining
        economyInRecession = fresh.economyInRecession
        lastSideHustleEarnings = fresh.lastSideHustleEarnings
        lastPromotionRaisePct = fresh.lastPromotionRaisePct
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
        lockedCertifications = fresh.lockedCertifications
        lockedPortfolio = fresh.lockedPortfolio
        lockedLicenses = fresh.lockedLicenses
        lockedHobbies = fresh.lockedHobbies
        networkByCategory = fresh.networkByCategory
        generalNetwork = fresh.generalNetwork
        appliedJobIds = []
        appliedSchoolIds = []
        attemptedCertificationIds = []
        availableJobs = fresh.availableJobs
    }
}

