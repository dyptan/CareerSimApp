import Foundation

/// A rule-based career advisor: reads the player's state and suggests the few
/// moves most likely to pay off, each ranked by the same yardstick.
///
/// It introduces **no rules of its own**. Every number it quotes comes from the
/// formulas the game actually rolls — `Job.hireBreakdown` (behind
/// `Job.hireProbability`, asked at `Job.offeredSalary`), `Player.promotionOdds`
/// and `Player.promotionPay`, `Job.requirementFit`,
/// `Training.requirements`, `Education.admissionProbability` — so its advice
/// can't drift from the game it's advising on. It only ever looks at this
/// year's postings (`Player.availableJobs`), the same list the Jobs sheet
/// shows, so every role it names is one the player can find and every odds
/// figure matches the one quoted there.
///
/// Deterministic and side-effect free: it never mutates the player, and the
/// same state always yields the same tips (ties break on the role's title),
/// which is what lets a view call it from `body` and a test call it on a
/// hand-built player.
///
/// **The yardstick** is expected extra lifetime pay: the chance the move works,
/// times the raise it brings over today's pay, times the working years left
/// once it lands (`careerValue`). That one currency lets "apply now at 40%",
/// "take a two-year course" and "study four years" compete fairly — and it
/// naturally stops recommending a doctorate at 58.
enum CareerAdvisor {

    /// The sheet a tip sends the player to, with what it needs to land them in
    /// the right place.
    enum Destination: Equatable {
        /// The Jobs sheet, showing roles of this setting.
        case jobs(WorkSetting)
        case education
        /// The Activities sheet, on this tab.
        case activities(ActivityKind)

        var buttonLabel: String {
            switch self {
            case .jobs: return "Open Jobs"
            case .education: return "Open Education"
            case .activities: return "Open Activities"
            }
        }
    }

    struct Tip: Identifiable {
        enum Kind: String {
            case applyNow, climb, train, study, buildSkill
        }
        let kind: Kind
        let icon: String
        let title: String
        let detail: String
        let destination: Destination?
        /// The role the move is aimed at.
        let job: Job
        /// Expected extra lifetime pay in dollars — what tips are ranked by.
        let value: Double

        var id: String { kind.rawValue }
    }

    /// Below these odds an application is a wasted year more often than not,
    /// so the advisor won't suggest it — even when a big salary makes the
    /// long shot look good on paper.
    static let minimumApplyOdds = 0.25

    /// Paths longer than this many prerequisite steps aren't "the next move".
    static let maxTrainingSteps = 2

    /// The best few moves for the player right now, best first. Empty when the
    /// advisor finds nothing that beats staying the course.
    static func tips(for player: Player, limit: Int = 3) -> [Tip] {
        let jobs = catalogue(player)
        let candidates: [Tip?] = [
            applyNowTip(player, jobs),
            climbTip(player),
            trainTip(player, jobs),
            studyTip(player, jobs),
            buildSkillTip(player, jobs),
        ]
        return candidates
            .compactMap { $0 }
            .filter { $0.value > 0 }
            .sorted { ($0.value, $1.kind.rawValue) > ($1.value, $0.kind.rawValue) }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - The yardstick

    /// This year's employee postings at their published median salary — the
    /// roles the Jobs sheet lists, each in the industry it's posted in (so a
    /// posting a slump withdrew this year is never recommended).
    /// Founder ventures are left out: they carry their own capital-and-grit
    /// maths and sheet.
    static func catalogue(_ player: Player) -> [Job] {
        player.availableJobs
            .filter { !$0.isEntrepreneurial }
            .map { $0.atBaseSalary() }
    }

    static func yearsLeft(_ player: Player) -> Int {
        max(0, GameConstants.retirementAge - player.age)
    }

    static func currentPay(_ player: Player) -> Int {
        player.currentOccupation?.annualIncome ?? 0
    }

    /// What `job` would pay the player if they landed it: the offer for their
    /// experience (`Job.offeredSalary`) — the salary the Jobs sheet opens the
    /// application at, and what a posted-rate role pays.
    static func offer(_ job: Job, _ player: Player) -> Int {
        job.offeredSalary(for: player)
    }

    /// Expected extra lifetime pay from a move that succeeds with `odds`,
    /// raises pay by `raise` a year, and starts paying after `delay` years.
    static func careerValue(odds: Double, raise: Int, delay: Int, player: Player) -> Double {
        odds * Double(raise) * Double(max(0, yearsLeft(player) - delay))
    }

    /// Whether a candidate beats the best so far. Ties go to the title that
    /// sorts first, so the shuffled order of the postings never changes advice.
    private static func beats(_ value: Double, _ job: Job, _ best: (value: Double, id: String)?) -> Bool {
        guard let best else { return value > 0 }
        return value > best.value || (value == best.value && job.id < best.id)
    }

    /// Jobs that would pay more than the player earns today — and, in
    /// Simplified mode, any top-leadership seat not yet reached, whatever it
    /// pays (see `goalAdjustedRaise`). A Simplified player already *in* such a
    /// seat is never advised to step off the finish line for more money, or
    /// the advice would swing them between the goal and a better-paid job
    /// below it every year.
    private static func upgrades(_ player: Player, _ jobs: [Job]) -> [Job] {
        let pay = currentPay(player)
        let heldId = player.currentOccupation?.id
        let holdsGoal = player.isSimplified && player.goalMet
        return jobs.filter { job in
            guard job.id != heldId, !holdsGoal || job.isTopLeadership else { return false }
            return offer(job, player) > pay || reachesGoal(job, player)
        }
    }

    /// Whether landing `job` would meet Simplified mode's goal (a top
    /// leadership seat — see `Player.goalMet`).
    static func reachesGoal(_ job: Job, _ player: Player) -> Bool {
        player.isSimplified && job.isTopLeadership && !player.goalMet
    }

    /// The yearly gain a move toward `job` is valued at: the rise its offer
    /// (`offer`) brings over today's pay — or, for a seat that meets
    /// Simplified's goal, twice its whole pay. Simplified mode's finish line is a top-leadership seat, not a
    /// number, so reaching it outranks a merely better-paid role even when it
    /// pays less than the job it replaces (a surgeon stepping up to chief
    /// medical officer). Before degrees gated every Simplified role, the best-
    /// paid path happened to end in the C-suite; now it can end at a surgeon's
    /// salary, one seat short of the goal.
    static func goalAdjustedRaise(_ job: Job, pay: Int, player: Player) -> Int {
        reachesGoal(job, player) ? 2 * offer(job, player) : prospectPay(job, player) - pay
    }

    /// What a role is worth over the career it starts, not just its first
    /// year: the average pay over the next `prospectHorizonYears`, assuming
    /// each rung above is reached once its stated years are served. A medical
    /// residency pays $68k, but it is three years at the door of a $245–300k
    /// attending career — judged by the residency alone, medicine would never
    /// look worth it. A standalone role is worth its offer.
    static func prospectPay(_ job: Job, _ player: Player) -> Int {
        let now = offer(job, player)
        guard let rungs = ladderRungs[job.baseTitle], rungs.count > 1 else { return now }
        let start = job.requirements.minYearsExperience
        let above = rungs.filter { $0.rung > job.rung }.sorted { $0.rung < $1.rung }
        var total = 0.0
        var pay = Double(now)
        var year = 0
        for rung in above {
            let reachedAt = min(prospectHorizonYears, max(year, rung.minYears - start))
            total += pay * Double(reachedAt - year)
            year = reachedAt
            pay = max(pay, Double(rung.income))
        }
        total += pay * Double(prospectHorizonYears - year)
        return Int((total / Double(prospectHorizonYears)).rounded())
    }

    /// A role's pay in words: its offer, and — when the ladder it starts pays
    /// much more later (a residency, an apprenticeship) — what it grows to.
    static func payStory(_ job: Job, _ player: Player) -> String {
        let start = offer(job, player)
        let later = prospectPay(job, player)
        guard Double(later) >= Double(start) * 1.25 else { return "\(money(start)) a year" }
        return "\(money(start)) a year to start, growing to about \(money(later)) later"
    }

    /// How far ahead a ladder's prospects are counted (see `prospectPay`).
    static let prospectHorizonYears = 20

    /// Every ladder's rungs at their catalogue pay, by base title — built once.
    private static let ladderRungs: [String: [(rung: Int, minYears: Int, income: Int)]] =
        Dictionary(grouping: JobCatalog.allJobs().filter { !$0.isEntrepreneurial }, by: \.baseTitle)
            .mapValues { $0.map { (rung: $0.rung, minYears: $0.requirements.minYearsExperience, income: $0.income) } }

    /// An application or an admission is a roll the player can take again
    /// next year: the chance of succeeding within `retryAttempts` tries, and
    /// the years the failed tries are expected to cost. Judging every move by
    /// a single year's odds would make the long, selective routes (medical
    /// school, then a residency match) look far worse than they are.
    static func retryOutlook(_ odds: Double) -> (chance: Double, extraYears: Int) {
        guard odds > 0 else { return (0, 0) }
        let chance = 1 - pow(1 - min(1, odds), Double(retryAttempts))
        let extra = min(retryAttempts - 1, Int(((1 - odds) / odds).rounded()))
        return (chance, max(0, extra))
    }

    static let retryAttempts = 3

    /// A role's hire odds once a move has changed its requirement factors — for
    /// roles the player can't apply to yet, where `hireProbability` would only
    /// say zero. It is the game's own breakdown (`Job.hireBreakdown`, asking
    /// the salary on offer) with the product of the requirement factors — age,
    /// education, licences, experience — neutralised and replaced by
    /// `requirementFactor`, the product the move would leave: every other term
    /// (merit, demand, rung decay, climate, the difficulty, the floor, the
    /// ceiling and the seat) is exactly what the roll would use.
    static func estimatedOdds(for job: Job, player: Player, requirementFactor: Double) -> Double {
        job.hireBreakdown(for: player, requestedSalary: Double(offer(job, player)))
            .odds(requirementFactor: requirementFactor)
    }

    /// Careers like Professional Player sit at the odds floor without their
    /// breakthrough award, whatever else the player does — so no skill,
    /// course or degree is worth recommending toward them.
    private static func lacksBreakthrough(_ job: Job, _ player: Player) -> Bool {
        guard let award = job.breakthroughFame else { return false }
        return !player.fameAwards.contains { $0.title == award }
    }

    // MARK: - Tips

    /// The best role the player can apply for today, by expected value.
    static func applyNowTip(_ player: Player, _ jobs: [Job]) -> Tip? {
        guard player.age >= GameConstants.minimumWorkingAge else { return nil }
        let pay = currentPay(player)
        var best: (job: Job, odds: Double, value: Double)?
        for job in upgrades(player, jobs) {
            let odds = job.hireProbability(for: player, requestedSalary: Double(offer(job, player)))
            guard odds >= minimumApplyOdds else { continue }
            let outlook = retryOutlook(odds)
            let value = careerValue(odds: outlook.chance, raise: goalAdjustedRaise(job, pay: pay, player: player),
                                    delay: outlook.extraYears, player: player)
            if beats(value, job, best.map { ($0.value, $0.job.id) }) { best = (job, odds, value) }
        }
        guard let best else { return nil }
        let job = best.job
        let salary = offer(job, player)
        var detail = player.isSimplified
            ? "You can get this job! It pays \(money(salary)) a year"
            : "You have a \(percent(best.odds)) chance to get it. It pays \(payStory(job, player))"
        detail += pay > 0 && salary > pay ? " — \(money(salary - pay)) more than you earn now." : "."
        detail += " Look for it under \(job.category.rawValue)."
        if reachesGoal(job, player) {
            detail += " 🏆 Getting this job reaches your goal!"
        }
        return Tip(kind: .applyNow, icon: job.icon, title: "Apply to be \(article(for: job.id)) \(job.id)",
                   detail: detail, destination: .jobs(job.workSetting), job: job, value: best.value)
    }

    /// Staying put for a promotion — with the one lever that would help most.
    ///
    /// Mirrors how `Player.advanceYear` pays a promotion out: a win steps up to
    /// the next rung — only once the player meets its full requirements, all of
    /// its years included, and clears its seat (`Job.promotionSeatChance`) —
    /// at a raise clamped into the new rung's band (`Player.promotionPay`).
    /// There is no in-place raise to wait for any more, so a role with no rung
    /// above offers no climb. When only years stand between the player and the
    /// rung, the tip counts the wait; any other gap (a degree, a licence) is
    /// the train and study tips' business. Realistic mode only — simplified
    /// mode never promotes, the way up there is applying, which `applyNowTip`
    /// covers.
    static func climbTip(_ player: Player) -> Tip? {
        guard !player.isSimplified, let job = player.currentOccupation else { return nil }
        let odds = player.promotionOdds(for: job)
        guard odds.promotes, let next = odds.nextRole else { return nil }
        let wait: Int
        if odds.eligible {
            wait = 0
        } else {
            let fit = next.requirementFit(for: player)
            guard fit.age * fit.education * fit.credentials > 0 else { return nil }
            wait = max(0, next.requirements.minYearsExperience - next.relevantYears(for: player))
        }
        let chance = odds.roll * odds.seat
        guard chance > 0 else { return nil }

        let current = job.annualIncome
        let raise = (GameConstants.promotionRaise.lowerBound + GameConstants.promotionRaise.upperBound) / 2
        let expectedPay = Player.promotionPay(current: current, next: next, raise: raise)
        let value = careerValue(odds: chance, raise: expectedPay - current, delay: 1 + wait, player: player)

        let years = wait == 1 ? "1 more year" : "\(wait) more years"
        var detail = wait == 0
            ? "You have a \(percent(chance)) chance to move up this year. You'd earn about \(money(expectedPay)) a year."
            : "Keep going for \(years) — you need \(next.requirements.minYearsExperience) years as \(next.experienceLadder ?? job.baseTitle) first. Then you'll have about a \(percent(chance)) chance each year to move up and earn about \(money(expectedPay)) a year."
        var destination: Destination?
        if odds.education < 0 {
            // Studying full-time means leaving the job — no button that would
            // undo the very climb this tip is about.
            detail += " Not having a \(job.requirements.education.educationLabel()) holds you back — but going back to school means leaving this job."
        } else if let lever = biggestTrainableGap(for: next, player: player) {
            detail += " Best way to help: grow your \(lever.gap.axis.pictogram) \(lever.gap.axis.label) (\(lever.gap.have) of \(lever.gap.need)). \(lever.activity.label) is good practice for it."
            destination = .activities(lever.activity.kind)
        }
        return Tip(kind: .climb, icon: "📈", title: "Work toward \(next.id)",
                   detail: detail, destination: destination, job: next, value: value)
    }

    /// A course the player can enrol in today that opens a better role.
    static func trainTip(_ player: Player, _ jobs: [Job]) -> Tip? {
        // Simplified mode hires without licences, and the courses live on the
        // Education sheet, which only opens between studies.
        guard !player.isSimplified, canOpenEducation(player) else { return nil }
        let pay = currentPay(player)
        var best: (job: Job, missing: [Training], value: Double)?
        for job in upgrades(player, jobs) where !lacksBreakthrough(job, player) {
            let fit = job.requirementFit(for: player)
            guard fit.credentials == 0 else { continue }
            let missing = missingCredentials(for: job, player: player)
            guard !missing.isEmpty, missing.count <= maxTrainingSteps,
                  missing.allSatisfy({ enrollable($0, player) }) else { continue }
            // Only roles the courses alone stand between the player and — with
            // age judged when the courses are done (one spare-time slot a year,
            // so each course is a year).
            let others = ageFactor(job, player, inYears: missing.count) * fit.education * fit.experience
            guard others > 0 else { continue }
            // The odds once the credential is held: the fit today with the
            // credentials factor lifted from 0 to 1.
            let outlook = retryOutlook(estimatedOdds(for: job, player: player, requirementFactor: others))
            let value = careerValue(odds: outlook.chance, raise: goalAdjustedRaise(job, pay: pay, player: player),
                                    delay: missing.count + outlook.extraYears, player: player)
            if beats(value, job, best.map { ($0.value, $0.job.id) }) { best = (job, missing, value) }
        }
        guard let best, let first = best.missing.first else { return nil }
        var detail = "This opens the \(best.job.id) job, which pays \(payStory(best.job, player))"
        detail += best.missing.count > 1 ? ". You'll also need \(best.missing[1].friendlyName)." : "."
        return Tip(kind: .train, icon: "📜", title: "Take \(first.friendlyName)",
                   detail: detail, destination: .education, job: best.job, value: best.value)
    }

    /// A degree the player can enrol in today that opens — or starts the road
    /// to — a better role, net of the pay and tuition it costs.
    ///
    /// Counts the roles a degree opens only together with a licence taken after
    /// it — a physician's medical licence, a lawyer's bar, a nurse's RN, a
    /// pharmacist's board exam — when the degree is what makes those licences
    /// enrollable: each is a further year before the role pays.
    static func studyTip(_ player: Player, _ jobs: [Job]) -> Tip? {
        guard canOpenEducation(player) else { return nil }
        let offered = player.offeredDegrees
        guard !offered.isEmpty else { return nil }
        let pay = currentPay(player)
        var best: (job: Job, degree: Education, years: Int, licences: [Training], value: Double)?
        for job in upgrades(player, jobs) where !job.educationMet(for: player) && !lacksBreakthrough(job, player) {
            let fit = job.requirementFit(for: player)
            let minEQF = job.requirements.education.minEQF
            // Experience doesn't grow while studying full-time.
            guard fit.experience > 0 else { continue }
            let accepted = job.requirements.education.acceptedProfiles ?? []
            let fitting = offered.filter { degree in
                accepted.isEmpty || degree.profile.map(accepted.contains) == true
            }
            guard let degree = bestDegree(fitting, toward: minEQF) else { continue }
            let years = yearsOfStudy(from: degree, to: minEQF)
            // Only roles education is the limiter on — or education plus the
            // licences the finished degree makes enrollable.
            var licences: [Training] = []
            if fit.credentials == 0 {
                let missing = missingCredentials(for: job, player: player)
                guard !missing.isEmpty, missing.count <= maxTrainingSteps,
                      missing.allSatisfy({
                          enrollableAfterDegree($0, eqf: minEQF, alongside: Set(missing),
                                                player: player, inYears: years)
                      }) else { continue }
                licences = missing
            }
            // Admission can be retried: the chance of getting in within a few
            // tries, and the years the failed tries cost.
            let admission = retryOutlook(degree.admissionProbability(player: player))
            let delay = years + licences.count + admission.extraYears
            // The education factor today against the one the degree earns: a
            // pass/fail gate in the regulated fields and simplified mode, the
            // relevant-degree premium everywhere else.
            let educationAfter = (job.educationIsMandatory || player.isSimplified)
                ? 1.0 : GameConstants.relevantDegreeMultiplier
            let after = estimatedOdds(for: job, player: player,
                                      requirementFactor: ageFactor(job, player, inYears: delay)
                                          * fit.experience * educationAfter)
            let now = estimatedOdds(for: job, player: player, requirementFactor: fit.factor)
            // Applications can be retried too: what the degree buys is the
            // chance of landing the role within a few tries.
            let hire = retryOutlook(after)
            let gain = hire.chance - retryOutlook(now).chance
            guard gain > 0 else { continue }
            // Study is full-time: the job (and its pay) goes, and — outside
            // simplified mode — the student's share of tuition is due, for the
            // degree after this one too when this is only the first step.
            let cost = Double(pay * degree.yearsToComplete + studentTuition(degree, toward: minEQF, player: player))
            let value = admission.chance * careerValue(odds: gain, raise: goalAdjustedRaise(job, pay: pay, player: player),
                                                       delay: delay + hire.extraYears, player: player) - cost
            if beats(value, job, best.map { ($0.value, $0.job.id) }) {
                best = (job, degree, years, licences, value)
            }
        }
        guard let best else { return nil }
        let firstStep = best.degree.eqf < best.job.requirements.education.minEQF
        var detail = firstStep
            ? "This is the first step to becoming \(article(for: best.job.id)) \(best.job.id) (\(payStory(best.job, player))). It's about \(best.years) years of school in total"
            : "This opens the \(best.job.id) job (\(payStory(best.job, player))) after \(best.years) years of school"
        if !best.licences.isEmpty {
            let names = best.licences.map(\.friendlyName).joined(separator: " and ")
            detail += ", then \(names) (\(best.licences.count) more year\(best.licences.count == 1 ? "" : "s"))"
        }
        detail += "."
        if pay > 0 { detail += " You'd have to leave your job while you study." }
        return Tip(kind: .study, icon: best.degree.pictogram, title: "Study for a \(best.degree.degreeName)",
                   detail: detail, destination: .education, job: best.job, value: best.value)
    }

    /// The tuition the student pays (net of the family's share) to hold EQF
    /// `target` starting with `degree` — the next degree up priced at a state
    /// school in the same field.
    static func studentTuition(_ degree: Education, toward target: Int, player: Player) -> Int {
        guard !player.isSimplified else { return 0 }
        var total = degree.totalTuition
        if let profile = degree.profile, degree.eqf < target {
            let next: Level.Stage = target >= Level(stage: .Doctorate).eqf ? .Doctorate : .Master
            total += Education(next, profile: profile, tier: .state).totalTuition
        }
        return Int((Double(total) * (1 - player.difficulty.familyTuitionShare)).rounded())
    }

    /// One year of the right activity toward a role that pays more — or, for a
    /// child, toward the role their strengths already point at.
    static func buildSkillTip(_ player: Player, _ jobs: [Job]) -> Tip? {
        // Simplified mode doesn't score soft skills when hiring, so only the
        // young — for whom they shape admissions — are pointed at them there.
        let isChild = player.age < GameConstants.minimumWorkingAge
        guard isChild || !player.isSimplified else { return nil }
        let activities = offeredActivities(player)
        guard !activities.isEmpty else { return nil }
        let pay = currentPay(player)
        var best: (job: Job, gap: SkillGap, activity: Sport, value: Double)?
        for job in upgrades(player, jobs) where !lacksBreakthrough(job, player) {
            let fit = job.requirementFit(for: player)
            // Children are years from any hire, so they're measured on skills alone.
            guard isChild || fit.factor > 0 else { continue }
            let breakdown = job.hireBreakdown(for: player, requestedSalary: Double(offer(job, player)))
            let asked = job.askedSoftSkills
            for keyPath in asked {
                let need = job.requirements.softSkills[keyPath: keyPath]
                let have = player.softSkills[keyPath: keyPath]
                guard have < need,
                      let (activity, weight) = bestActivity(for: keyPath, among: activities),
                      let axis = SoftSkills.allAxes.first(where: { $0.keyPath == keyPath }) else { continue }
                // How much one year of it lifts this role's fit, and so its
                // odds: for an adult, the breakdown's own odds with the fit's
                // added merit against today's; a child's skill term alone.
                let gained = Double(min(have + weight, need) - have) / Double(need) / Double(asked.count)
                let lift = gained * GameConstants.hireSkillWeight
                let odds = isChild ? lift : breakdown.odds(extraMerit: lift) - breakdown.final
                let value = careerValue(odds: odds, raise: goalAdjustedRaise(job, pay: pay, player: player),
                                        delay: 1, player: player)
                if beats(value, job, best.map { ($0.value, $0.job.id) }) {
                    best = (job, SkillGap(axis: axis, have: have, need: need), activity, value)
                }
            }
        }
        guard let best else { return nil }
        let gap = best.gap
        let detail = isChild
            ? "Want to be \(article(for: best.job.id)) \(best.job.id) one day? It pays \(money(best.job.income)) a year and needs \(gap.axis.label) \(gap.need). You're at \(gap.have) — keep practising!"
            : "The \(best.job.id) job (\(money(offer(best.job, player))) a year) needs \(gap.axis.label) \(gap.need). You're at \(gap.have)."
        return Tip(kind: .buildSkill, icon: gap.axis.pictogram,
                   title: "Build \(gap.axis.label) with \(best.activity.label)",
                   detail: detail, destination: .activities(best.activity.kind),
                   job: best.job, value: best.value)
    }

    // MARK: - Helpers

    struct SkillGap {
        let axis: SoftSkillAxis
        let have: Int
        let need: Int
    }

    /// The soft skill furthest below what `job` asks (relative to the ask)
    /// among those an activity open to the player actually trains — so a tip
    /// never points at a sheet that can't help.
    static func biggestTrainableGap(for job: Job, player: Player) -> (gap: SkillGap, activity: Sport)? {
        let activities = offeredActivities(player)
        return job.askedSoftSkills
            .compactMap { keyPath -> (gap: SkillGap, activity: Sport)? in
                let need = job.requirements.softSkills[keyPath: keyPath]
                let have = player.softSkills[keyPath: keyPath]
                guard have < need,
                      let (activity, _) = bestActivity(for: keyPath, among: activities),
                      let axis = SoftSkills.allAxes.first(where: { $0.keyPath == keyPath }) else { return nil }
                return (SkillGap(axis: axis, have: have, need: need), activity)
            }
            .max { lhs, rhs in
                let l = Double(lhs.gap.need - lhs.gap.have) / Double(lhs.gap.need)
                let r = Double(rhs.gap.need - rhs.gap.have) / Double(rhs.gap.need)
                return (l, rhs.gap.axis.label) < (r, lhs.gap.axis.label)
            }
    }

    /// Every activity the Activities sheet offers the player right now.
    static func offeredActivities(_ player: Player) -> [Sport] {
        ActivitiesView.availableTabs(for: player)
            .flatMap { ActivityListView.offered(to: player, kind: $0) }
    }

    /// The offered activity that trains `keyPath` hardest, with its yearly gain.
    private static func bestActivity(for keyPath: WritableKeyPath<SoftSkills, Int>,
                                     among activities: [Sport]) -> (Sport, Int)? {
        activities
            .compactMap { sport -> (Sport, Int)? in
                guard let boost = sport.abilities.first(where: { $0.keyPath == keyPath }) else { return nil }
                return (sport, boost.weight)
            }
            .max { ($0.1, $1.0.rawValue) < ($1.1, $0.0.rawValue) }
    }

    /// Of the degrees on offer, the shortest one that meets `minEQF`, or failing
    /// that the highest one — the first step toward it.
    private static func bestDegree(_ degrees: [Education], toward minEQF: Int) -> Education? {
        let sufficient = degrees.filter { $0.eqf >= minEQF }
        if let shortest = sufficient.min(by: { ($0.yearsToComplete, $0.id) < ($1.yearsToComplete, $1.id) }) {
            return shortest
        }
        return degrees.max { ($0.eqf, $1.id) < ($1.eqf, $0.id) }
    }

    /// Years from enrolling in `degree` to holding EQF `target` — the degree
    /// itself plus each higher level still to climb after it.
    static func yearsOfStudy(from degree: Education, to target: Int) -> Int {
        // A doctorate follows a bachelor's directly, so the climb to EQF 7
        // skips the master's; only a master's-level target needs one.
        let next: Level.Stage? = target >= Level(stage: .Doctorate).eqf ? .Doctorate
            : target >= Level(stage: .Master).eqf ? .Master : nil
        guard let next, Level(stage: next).eqf > degree.eqf else { return degree.yearsToComplete }
        return degree.yearsToComplete + Level(stage: next).yearsToComplete()
    }

    private static func enrollable(_ training: Training, _ player: Player) -> Bool {
        if case .ok = training.requirements(player) { return true }
        return false
    }

    /// The credentials `job` gates on that the player doesn't hold — the ones
    /// `Job.hardSkillsMet` checks: statutory licences everywhere, every listed
    /// credential in a regulated field. Sorted so advice is deterministic.
    static func missingCredentials(for job: Job, player: Player) -> [Training] {
        job.requirements.hardSkills.trainings
            .filter { $0.isStatutory || job.category.requiresCredentials }
            .subtracting(player.hardSkills.trainings)
            .sorted { $0.rawValue < $1.rawValue }
    }

    /// The age factor for `job` once `years` have passed — a move that takes
    /// time lands when the player is older (see `Job.minimumHireAge`).
    static func ageFactor(_ job: Job, _ player: Player, inYears years: Int) -> Double {
        player.age + years >= job.minimumHireAge ? 1.0 : 0.0
    }

    /// Whether `training` could be taken right after finishing a degree at EQF
    /// `eqf`, `years` from now — `Training.requirements` with the degree
    /// counted as held and the other credentials in `alongside` counted
    /// toward its prerequisites (they're taken in turn). Experience doesn't
    /// grow while studying, so an experience gate must already be met.
    static func enrollableAfterDegree(_ training: Training, eqf: Int, alongside: Set<Training>,
                                      player: Player, inYears years: Int) -> Bool {
        guard player.age + years >= training.minAge,
              max(player.highestEQF, eqf) >= training.minEQF else { return false }
        let held = player.hardSkills.trainings
        guard training.prerequisites.allSatisfy({ held.contains($0) || alongside.contains($0) }) else {
            return false
        }
        if training.minYearsExperience > 0 {
            let years = training.field.map { player.industryExperience(for: $0) } ?? player.totalExperienceYears
            guard years >= training.minYearsExperience else { return false }
        }
        return true
    }

    /// Mirrors the footer's gate on the **Education** button.
    static func canOpenEducation(_ player: Player) -> Bool {
        player.currentEducation == nil && player.age >= GameConstants.minimumTertiaryAge
    }

    /// "a" or "an" for a job title, by its first letter — good enough for the
    /// catalogue's titles ("an Insurance Agent", "a Software Engineer").
    static func article(for title: String) -> String {
        guard let first = title.lowercased().first else { return "a" }
        return "aeiou".contains(first) ? "an" : "a"
    }

    static func money(_ amount: Int) -> String { "\(amount.formatted(.number)) $" }

    static func percent(_ probability: Double) -> String { "\(Int((probability * 100).rounded()))%" }
}
