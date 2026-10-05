import Foundation

// MARK: - One simulated life, driven exactly the way the SwiftUI views drive it
//
// Every action below is a line-for-line mirror of the view code that performs
// it in the app, so the model sees the same calls in the same order:
//
//   * Year loop        — RootView.spendYear(closing:) → Player.advanceYear, then
//                        RootView.onChange(of: player.age) for the K-12 steps.
//   * Start of game    — ModeSelectionView.start(_:).
//   * Job application  — JobsView → (SeniorityOffersView) → JobDetail: the posting
//                        is shown `atBaseSalary()`, the slider opens at (and a
//                        posted-rate role pays) `job.offeredSalary(for:)`, the
//                        Apply button is disabled unless `allRequirementsMet`,
//                        then `applyForJob` + onCommit.
//   * Education        — EducationView → DegreesSubmenuView → InstitutionTiersView
//                        .apply/.enroll (drops the job, sets currentEducation and
//                        yearsLeftToGraduation, then onCommit).
//   * Courses/licences — TrainingRow (Take button; hidden when earned, disabled
//                        when `requirements` is blocked) → attemptTraining.
//   * Activities       — ActivityListView row → Player.selectSport.
//   * Ventures         — EntrepreneurshipView.launch (one-tap stake).
//   * Boardroom        — ExecutiveDecisionsView card button.
//   * Skip             — HeaderView's Skip button → advanceYear directly.
//
// Footer visibility (which sheets can be opened at all) mirrors FooterView.

/// Everything recorded about one life, for the metric tables.
struct LifeRecord {
    var finalNetWorth = 0
    var finalScore = 0
    var finalSavings = 0
    var salaryEarnings = 0          // gross pay actually banked by advanceYear (half in a layoff year)
    var otherIncome = 0             // endorsements (gross) — projects pay nothing
    var highestEQF = 0
    var studentLoanAt30 = 0
    var ageFirstJob: Int?
    var salaryAt: [Int: Int] = [:]  // age → annual pay of the job held at that age
    var employedAt: [Int: Bool] = [:]
    var peakSalary = 0
    var yearsTracked = 0            // years lived at ages 22...64
    var yearsUnemployed = 0         // … with no pay and not enrolled in tertiary study
    var yearsStudying = 0           // … enrolled in tertiary study and not paid
    var everTopLeadership = false
    var ageTopLeadership: Int?
    var everExecutive = false       // non-founder executive seat
    var everStar = false            // a show-business star title, or a pro-athlete contract
    var everProAthlete = false      // any rung of the "Player" ladder
    var everScreenStar = false      // a screen/music star title only (Breakout Role, Hit Record, …)
    var everFounder = false
    var everChief = false           // a "Chief …" seat (CEO, CTO, CMO, CMO-health) — the literal C-suite
    var everRegulated = false       // a job in a degree-mandatory profession (health, law, engineering, science, education)
    var everDoctorateJob = false    // a job expecting a doctorate (physician, lawyer, pharmacist, …)
    var juniorChampionBy18 = false
    var gpa = 0.0                   // high-school GPA as universities read it at 18
    var venturesFounded = 0
    var ventureFolds = 0
    var rungPromotions = 0
    var raises = 0                  // years with a merit (step) raise
    var recessionYears = 0          // years lived in a declared recession (ages 22–64)
    var layoffs = 0
    var hires = 0
    var jobSwitches = 0             // hires made while already employed
    var applications = 0
    var schoolApplications = 0
    var schoolAdmissions = 0
    var trainings = 0
    var activities = 0
    var skips = 0
    var studyWhileWorkingYears = 0  // years paid by a job while enrolled in a degree
    var goalAge: Int?               // Simplified: age the top-leadership goal was met
    var firstJob: String?
    var jobAt25: String?
    var jobAt45: String?
    var jobAt45MinEQF: Int?         // education the job held at 45 expects
    var eqfAt45 = 0                 // highest education held at 45
    var boardroomCash = 0           // cash banked from Boardroom share sales
    var actionMix: [String: Int] = [:]
}

/// Star titles from the show-business projects (see `SideHustleCatalog`): the big
/// breaks and the star projects they open.
let starAwardTitles: Set<String> = ["Breakout Role", "Hit Record", "Film Star", "Headliner"]

final class Game {
    let player = Player()
    let ui = AppUIState()
    var rec = LifeRecord()

    /// ModeSelectionView.start(_:)
    init(difficulty: Difficulty, startAge: Int, country: Country = .default) {
        player.difficulty = difficulty
        player.country = country
        // (avatar is cosmetic)
        player.configureStart(age: startAge)
        player.regenerateAvailableJobs()
        ui.hasSelectedMode = true
        noteMilestones()
        if startAge >= 18 { rec.gpa = player.highSchoolGPA }
    }

    var age: Int { player.age }
    var isOver: Bool { player.hasRetired }

    // MARK: Footer visibility (FooterView)

    var jobsOpen: Bool { player.age >= GameConstants.minimumWorkingAge }
    var educationOpen: Bool {
        player.currentEducation == nil && player.age >= GameConstants.minimumTertiaryAge
    }
    var activitiesOpen: Bool { !ActivitiesView.availableTabs(for: player).isEmpty }
    var venturesOpen: Bool {
        !player.isSimplified && player.age >= GameConstants.minimumEntrepreneurAge
            && player.currentOccupation?.isEntrepreneurial != true
    }
    var boardroomOpen: Bool { player.canMakeExecutiveDecisions }

    /// Enrolled in a degree (vocational or above). K-12 carries no profile.
    var isStudying: Bool { player.currentEducation?.profile != nil }

    // MARK: What the sheets list

    /// JobsView.filteredJobs with the default filters (any setting, not
    /// qualified-only): every salaried posting this year.
    var listedJobs: [Job] { player.availableJobs.filter { !$0.isEntrepreneurial } }

    /// The job exactly as JobDetail presents it — JobsView/SeniorityOffersView
    /// hand it over `atBaseSalary()`, and the industry picker (administration
    /// roles only) defaults to the posting's own industry.
    func offer(_ posting: Job) -> Job { posting.atBaseSalary() }

    /// The hire probability JobDetail displays at the slider's opening position
    /// (`requestedSalary = job.offeredSalary(for: player)`).
    func odds(_ posting: Job) -> Double {
        let job = offer(posting)
        return job.hireProbability(for: player, requestedSalary: Double(job.offeredSalary(for: player)))
    }

    /// JobDetail's Apply button is disabled unless every hard requirement is met.
    func canApply(_ posting: Job) -> Bool { offer(posting).allRequirementsMet(for: player) }

    /// TrainingRow.available(for:) — the courses on offer this year.
    var offeredTrainings: [Training] {
        let stage = LifeStage.forAge(player.age)
        return Training.allCases
            .filter { $0.stages.contains(stage) }
            .filter { player.age >= $0.minAge(in: player.country) }
            .sorted { $0.friendlyName < $1.friendlyName }
    }

    /// TrainingRow: the Take button exists only while not earned, and is
    /// disabled while `requirements` is blocked.
    func canTake(_ training: Training) -> Bool {
        guard educationOpen, offeredTrainings.contains(training) else { return false }
        if player.lockedTrainings.contains(training) || player.hardSkills.trainings.contains(training) { return false }
        if case .ok = training.requirements(player) { return true }
        return false
    }

    /// Every activity the Activities sheet lists right now.
    var offeredActivities: [Sport] {
        ActivitiesView.availableTabs(for: player).flatMap { ActivityListView.offered(to: player, kind: $0) }
    }

    /// InstitutionTiersView.tiers for a (level, profile) row.
    func tiers(level: Level.Stage, profile: TertiaryProfile) -> [Education] {
        EducationTier.offered(level: level, profile: profile, simplified: player.isSimplified)
            .map { Education(level, profile: profile, tier: $0) }
    }

    /// The school a row resolves to at a requested tier (Simplified has only one).
    func school(level: Level.Stage, profile: TertiaryProfile, tier: EducationTier) -> Education {
        let options = tiers(level: level, profile: profile)
        return options.first { $0.tier == tier } ?? options.last!
    }

    /// Whether a degree row is listed (EducationView → DegreesSubmenuView lists
    /// `player.offeredDegrees`) and its Apply button enabled.
    func canApplyToSchool(_ education: Education) -> Bool {
        guard educationOpen else { return false }
        let listed = player.offeredDegrees.contains { $0.level == education.level && $0.profile == education.profile }
        return listed && education.meetsRequirements(player: player)
    }

    // MARK: Actions — each one spends the year

    /// HeaderView's Skip button.
    func skip(_ why: String = "skip") {
        rec.skips += 1
        rec.actionMix[why, default: 0] += 1
        spendYear()
    }

    /// JobDetail's Apply button. Returns whether the offer landed.
    @discardableResult
    func apply(to posting: Job, tag: String = "apply") -> Bool {
        guard jobsOpen, canApply(posting) else { skip("apply-blocked"); return false }
        let job = offer(posting)
        // .onAppear { requestedSalary = job.offeredSalary(for: player) }
        let requestedSalary = Double(job.offeredSalary(for: player))
        let salary = requestedSalary.isFinite ? Int(requestedSalary) : job.offeredSalary(for: player)
        let wasEmployed = player.currentOccupation != nil
        let hired = player.applyForJob(job, requestedSalary: salary)
        player.reportApplicationOutcome(title: hired ? "🎉 Offer accepted!" : "❌ No offer this time.", message: "")
        rec.applications += 1
        rec.actionMix[tag, default: 0] += 1
        if hired {
            rec.hires += 1
            if wasEmployed { rec.jobSwitches += 1 }
            if rec.ageFirstJob == nil {
                rec.ageFirstJob = player.age
                rec.firstJob = job.id
            }
        }
        noteMilestones()      // RootView.onChange(of: currentOccupation) → goal check
        spendYear()
        return hired
    }

    /// InstitutionTiersView.apply(to:admission:) + enroll(in:). Returns admission.
    @discardableResult
    func applyToSchool(_ education: Education, tag: String = "school") -> Bool {
        guard canApplyToSchool(education) else { skip("school-blocked"); return false }
        rec.schoolApplications += 1
        rec.actionMix[tag, default: 0] += 1
        if player.applyToSchool(education) {
            rec.schoolAdmissions += 1
            // enroll(in:)
            player.currentOccupation = nil
            player.currentEducation = education
            ui.yearsLeftToGraduation = education.yearsToComplete
            spendYear()
            return true
        } else {
            spendYear()
            return false
        }
    }

    /// TrainingRow's Take button.
    func takeTraining(_ training: Training, tag: String = "training") {
        guard canTake(training) else { skip("training-blocked"); return }
        player.attemptTraining(training, into: &ui.selectedTrainings, activities: &ui.selectedActivities)
        rec.trainings += 1
        rec.actionMix[tag, default: 0] += 1
        spendYear()
    }

    /// ActivityListView's Take button.
    func takeActivity(_ sport: Sport, tag: String = "activity") {
        guard activitiesOpen, offeredActivities.contains(sport) else { skip("activity-blocked"); return }
        player.selectSport(sport, into: &ui.selectedActivities, sports: &ui.selectedSports)
        rec.activities += 1
        rec.actionMix[tag, default: 0] += 1
        spendYear()
    }

    /// SideHustleRow's Take button (PrivateProjectsView lists this stage's
    /// projects; a project needing an award is locked without it).
    func takeProject(_ id: String, tag: String = "project") {
        let stage = LifeStage.forAge(player.age)
        guard let hustle = SideHustleCatalog.byId[id], hustle.stages.contains(stage),
              player.canTakeProject(hustle) else { skip("project-blocked"); return }
        ui.selectedSideHustles = [hustle.id]
        rec.actionMix[tag, default: 0] += 1
        spendYear()
    }

    /// EntrepreneurshipView.launch(_:) with VentureRow.stake(for:player:).
    @discardableResult
    func launchVenture(_ posting: Job, tag: String = "venture") -> Bool {
        guard venturesOpen, posting.isEntrepreneurial else { skip("venture-blocked"); return false }
        let venture = posting.atBaseSalary()
        let capital = min(venture.targetCapital ?? 0, player.maxVentureStake)
        guard player.foundVenture(venture, investedCapital: capital) else { skip("venture-blocked"); return false }
        rec.venturesFounded += 1
        rec.everFounder = true
        rec.actionMix[tag, default: 0] += 1
        if rec.ageFirstJob == nil {
            rec.ageFirstJob = player.age
            rec.firstJob = venture.id
        }
        noteMilestones()
        spendYear()
        return true
    }

    /// ExecutiveDecisionsView card button (sell at the slider's default = fair).
    func boardroom(_ kind: ExecutiveDecision.Kind, tag: String = "boardroom") {
        guard boardroomOpen, let decision = ExecutiveDecisionCatalog.all.first(where: { $0.kind == kind }) else {
            skip("boardroom-blocked"); return
        }
        if kind == .investmentRound, !player.canRaiseInvestmentRound { skip("boardroom-blocked"); return }
        let savingsBefore = player.savings
        let outcome = kind == .sellShares
            ? player.resolveExecutiveDecision(decision, askPrice: player.shareStakeValue())
            : player.resolveExecutiveDecision(decision)
        if outcome.success, kind == .sellShares { rec.boardroomCash += player.savings - savingsBefore }
        rec.actionMix[tag, default: 0] += 1
        spendYear()
    }

    // MARK: The year itself

    /// RootView.spendYear(closing:) — the sheet is closed, then the year runs;
    /// followed by RootView's `.onChange(of: player.age)` handler.
    private func spendYear() {
        // The pop-ups the previous year raised have been dismissed by now.
        player.showPromotionAlert = false
        player.showLayoffAlert = false
        player.showVentureFailureAlert = false
        player.showApplicationOutcomeAlert = false
        player.showGraduationAlert = false

        let ageBefore = player.age
        let jobBefore = player.currentOccupation
        let studyingBefore = isStudying

        player.advanceYear(appUIState: ui)
        if player.age != ageBefore { onAgeChange(player.age) }

        // Pay banked this year: advanceYear banks the occupation held when the
        // year runs — only `layoffYearPayShare` of it if a layoff cut the year
        // short (`Player.layoffYearPay`).
        let paid = jobBefore.map { player.lostJobThisYear ? Player.layoffYearPay(for: $0) : $0.annualIncome } ?? 0
        rec.salaryEarnings += paid
        rec.otherIncome += player.lastYearEndorsements
        if paid > 0, studyingBefore { rec.studyWhileWorkingYears += 1 }

        if (22...64).contains(ageBefore) {
            rec.yearsTracked += 1
            if paid == 0 {
                if studyingBefore { rec.yearsStudying += 1 } else { rec.yearsUnemployed += 1 }
            }
        }
        if player.lostJobThisYear { rec.layoffs += 1 }
        if player.showVentureFailureAlert { rec.ventureFolds += 1 }
        // Every promotion is a rung step; a merit raise is the same job at
        // higher pay, with no pop-up.
        if player.showPromotionAlert { rec.rungPromotions += 1 }
        if let before = jobBefore, let now = player.currentOccupation, now.id == before.id,
           !now.isEntrepreneurial, now.annualIncome > before.annualIncome {
            rec.raises += 1
        }
        if (22...64).contains(ageBefore), player.economyInRecession { rec.recessionYears += 1 }
        noteMilestones()

        let a = player.age
        if [25, 35, 45, 55].contains(a) {
            if let job = player.currentOccupation {
                rec.salaryAt[a] = job.annualIncome
                rec.employedAt[a] = true
            } else {
                rec.employedAt[a] = false
            }
        }
        if a == 25 { rec.jobAt25 = player.currentOccupation?.id }
        if a == 45 {
            rec.jobAt45 = player.currentOccupation?.id
            rec.jobAt45MinEQF = player.currentOccupation?.requirements.education.minEQF
            rec.eqfAt45 = player.highestEQF
        }
        if a == 30 { rec.studentLoanAt30 = player.studentLoan }
        if a == 18 {
            rec.juniorChampionBy18 = player.fameAwards.contains { $0.key == "Junior Champion" }
            rec.gpa = player.highSchoolGPA
        }
        if player.hasRetired { finish() }
    }

    /// RootView `.onChange(of: player.age)`: the K-12 transitions live in the view.
    private func onAgeChange(_ newValue: Int) {
        switch newValue {
        case 10:
            let degree = Education(Level.Stage.PrimarySchool)
            player.degrees.append(degree)
            player.recordStatus("🎓", "Graduated — \(degree.degreeName(in: player.country))")
            player.currentEducation = Education(Level.Stage.MiddleSchool)
        case 14:
            let degree = Education(Level.Stage.MiddleSchool)
            player.degrees.append(degree)
            player.recordStatus("🎓", "Graduated — \(degree.degreeName(in: player.country))")
            player.currentEducation = Education(Level.Stage.HighSchool)
        case 18:
            let degree = Education(Level.Stage.HighSchool)
            player.degrees.append(degree)
            player.recordStatus("🎓", player.graduationStatus(for: degree))
            player.graduationMessage = player.graduationMessage(for: degree)
            player.showGraduationAlert = true
            player.currentEducation = nil
        case 68:
            ui.showRetirementSheet = true
        default:
            break
        }
    }

    /// Ladder/goal milestones, checked whenever the occupation can have changed.
    private func noteMilestones() {
        if let job = player.currentOccupation {
            rec.peakSalary = max(rec.peakSalary, job.annualIncome)
            if job.isTopLeadership, !rec.everTopLeadership {
                rec.everTopLeadership = true
                rec.ageTopLeadership = player.age
            }
            if job.isExecutive && !job.isEntrepreneurial { rec.everExecutive = true }
            if job.baseTitle == "Player" {
                rec.everProAthlete = true
                if job.rung >= 1 { rec.everStar = true }
            }
            if job.isEntrepreneurial { rec.everFounder = true }
            if job.id.hasPrefix("Chief") { rec.everChief = true }
            if job.educationIsMandatory { rec.everRegulated = true }
            if job.requirements.education.minEQF >= 7 { rec.everDoctorateJob = true }
        }
        if player.fameAwards.contains(where: { starAwardTitles.contains($0.key) }) {
            rec.everStar = true
            rec.everScreenStar = true
        }
        if player.goalMet, rec.goalAge == nil { rec.goalAge = player.age }
    }

    private func finish() {
        rec.finalNetWorth = player.netWorth
        rec.finalScore = player.leaderboardScore
        rec.finalSavings = player.savings
        rec.highestEQF = player.highestEQF
    }

    /// Plays the life to the retirement horizon with `policy` choosing every year.
    func play(_ policy: Policy) {
        var guardYears = 0
        while !player.hasRetired && guardYears < 80 {
            policy.act(self)
            guardYears += 1
        }
        if player.hasRetired { finish() }
    }
}
