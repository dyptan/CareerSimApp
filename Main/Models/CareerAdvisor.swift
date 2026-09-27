import Foundation

/// A rule-based career advisor: reads the player's state and suggests the few
/// moves most likely to pay off, each ranked by the same yardstick.
///
/// It introduces **no rules of its own**. Every number it quotes comes from the
/// formulas the game actually rolls — `Job.hireProbability`,
/// `Player.promotionOdds`, `Job.requirementFit`, `Training.requirements`,
/// `Education.admissionProbability` — so its advice can't drift from the game
/// it's advising on. It only ever looks at this year's postings
/// (`Player.availableJobs`), the same list the Jobs sheet shows, so every role
/// it names is one the player can find and every odds figure matches the one
/// quoted there.
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
    /// sector in a slump, whose postings are withdrawn, is never recommended).
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

    /// Jobs that would pay more than the player earns today.
    private static func upgrades(_ player: Player, _ jobs: [Job]) -> [Job] {
        let pay = currentPay(player)
        let heldId = player.currentOccupation?.id
        return jobs.filter { $0.income > pay && $0.id != heldId }
    }

    /// The part of a role's hire odds that doesn't depend on its hard gates:
    /// the soft-skill fit, the formula's dominant term. Used for roles the
    /// player can't apply to yet, where `hireProbability` would only say zero;
    /// the caller multiplies in the requirement factors the move would leave.
    static func estimatedOdds(for job: Job, player: Player) -> Double {
        if player.isSimplified { return 1.0 }
        return max(0.05, min(0.95, 0.2 + 0.7 * job.softSkillFit(for: player)))
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
            let odds = job.hireProbability(for: player, requestedSalary: Double(job.income))
            guard odds >= minimumApplyOdds else { continue }
            var value = careerValue(odds: odds, raise: job.income - pay, delay: 0, player: player)
            // Simplified mode's finish line is a top-leadership seat, not a
            // number — a role that reaches it outranks a merely better-paid one.
            if player.isSimplified, job.isTopLeadership { value *= 2 }
            if beats(value, job, best.map { ($0.value, $0.job.id) }) { best = (job, odds, value) }
        }
        guard let best else { return nil }
        let job = best.job
        var detail = player.isSimplified
            ? "You qualify. \(money(job.income)) a year"
            : "\(percent(best.odds)) chance of an offer · \(money(job.income)) a year"
        detail += pay > 0 ? " (+\(money(job.income - pay)) on today)." : "."
        detail += " Find it under \(job.category.rawValue)."
        if player.isSimplified, job.isTopLeadership {
            detail += " 🏆 This reaches your goal!"
        }
        return Tip(kind: .applyNow, icon: job.icon, title: "Apply to be \(article(for: job.id)) \(job.id)",
                   detail: detail, destination: .jobs(job.workSetting), job: job, value: best.value)
    }

    /// Staying put for a promotion — with the one lever that would help most.
    ///
    /// Mirrors how `Player.advanceYear` pays a promotion out: a win steps up to
    /// the next rung only when the player already meets its requirements (and,
    /// for an executive seat, wins the seat roll too); otherwise it's a raise
    /// in place. Realistic mode only — simplified mode never promotes, the way
    /// up there is applying, which `applyNowTip` covers.
    static func climbTip(_ player: Player) -> Tip? {
        guard !player.isSimplified, let job = player.currentOccupation else { return nil }
        let odds = player.promotionOdds(for: job)
        guard odds.promotes, odds.total > 0 else { return nil }

        let current = job.annualIncome
        let raise = (GameConstants.promotionRaise.lowerBound + GameConstants.promotionRaise.upperBound) / 2
        let raised = Double(current) * (1 + raise)
        let next = odds.nextRole
        let stepsUp = next.map { $0.allRequirementsMet(for: player) } ?? false
        var expectedPay = raised
        if let next, stepsUp {
            let seat = (next.isExecutive && !next.isEntrepreneurial) ? player.executiveSeatChance : 1.0
            expectedPay = seat * max(Double(next.income), raised) + (1 - seat) * raised
        }
        let value = careerValue(odds: odds.total, raise: Int(expectedPay) - current, delay: 1, player: player)

        let title: String
        var detail: String
        var destination: Destination?
        if let next, stepsUp {
            title = "Aim for \(next.id)"
            detail = "\(percent(odds.total)) promotion odds this year → up to \(money(next.income)) a year."
        } else {
            title = "Push for a raise as \(job.id)"
            detail = "\(percent(odds.total)) odds of a raise this year."
            if let next {
                let gaps = CareerGraph.missingHardRequirements(for: next, player: player)
                if let gap = gaps.first {
                    detail += " \(next.id) is out of reach until you clear: \(gap)."
                }
            }
        }
        if odds.education < 0 {
            // Studying full-time means leaving the job — no button that would
            // undo the very climb this tip is about.
            detail += " Your missing \(job.requirements.education.educationLabel()) holds promotions back, but studying for it means leaving this job."
        } else if let lever = biggestTrainableGap(for: next ?? job, player: player) {
            detail += " Biggest lever: \(lever.gap.axis.pictogram) \(lever.gap.axis.label) (\(lever.gap.have)/\(lever.gap.need)) — \(lever.activity.label) trains it."
            destination = .activities(lever.activity.kind)
        }
        return Tip(kind: .climb, icon: "📈", title: title,
                   detail: detail, destination: destination, job: next ?? job, value: value)
    }

    /// A course the player can enrol in today that opens a better role.
    static func trainTip(_ player: Player, _ jobs: [Job]) -> Tip? {
        // Simplified mode hires without licences, and the courses live on the
        // Education sheet, which only opens between studies.
        guard !player.isSimplified, canOpenEducation(player) else { return nil }
        let pay = currentPay(player)
        let held = player.hardSkills.trainings
        var best: (job: Job, missing: [Training], value: Double)?
        for job in upgrades(player, jobs) where !lacksBreakthrough(job, player) {
            let fit = job.requirementFit(for: player)
            // Only roles the courses alone stand between the player and.
            let others = fit.age * fit.education * fit.experience
            guard fit.credentials == 0, others > 0 else { continue }
            let needed = job.requirements.hardSkills.trainings
                .filter { $0.isStatutory || job.category.requiresCredentials }
            let missing = needed.subtracting(held).sorted { $0.rawValue < $1.rawValue }
            guard !missing.isEmpty, missing.count <= maxTrainingSteps,
                  missing.allSatisfy({ enrollable($0, player) }) else { continue }
            // The odds once the credential is held: the fit today with the
            // credentials factor lifted from 0 to 1.
            let odds = min(0.95, estimatedOdds(for: job, player: player) * others)
            // One spare-time slot a year, so each course is a year.
            let value = careerValue(odds: odds, raise: job.income - pay,
                                    delay: missing.count, player: player)
            if beats(value, job, best.map { ($0.value, $0.job.id) }) { best = (job, missing, value) }
        }
        guard let best, let first = best.missing.first else { return nil }
        var detail = "Opens \(best.job.id) at \(money(best.job.income)) a year"
        detail += best.missing.count > 1 ? " — together with \(best.missing[1].friendlyName)." : "."
        return Tip(kind: .train, icon: "📜", title: "Take \(first.friendlyName)",
                   detail: detail, destination: .education, job: best.job, value: best.value)
    }

    /// A degree the player can enrol in today that opens — or starts the road
    /// to — a better role, net of the pay and tuition it costs.
    static func studyTip(_ player: Player, _ jobs: [Job]) -> Tip? {
        guard canOpenEducation(player) else { return nil }
        let offered = player.offeredDegrees
        guard !offered.isEmpty else { return nil }
        let pay = currentPay(player)
        var best: (job: Job, degree: Education, years: Int, value: Double)?
        for job in upgrades(player, jobs) where !job.educationMet(for: player) && !lacksBreakthrough(job, player) {
            let fit = job.requirementFit(for: player)
            // Only roles education is the limiter on.
            let others = fit.age * fit.credentials * fit.experience
            guard others > 0 else { continue }
            let accepted = job.requirements.education.acceptedProfiles ?? []
            let fitting = offered.filter { degree in
                accepted.isEmpty || degree.profile.map(accepted.contains) == true
            }
            guard let degree = bestDegree(fitting, toward: job.requirements.education.minEQF) else { continue }
            let years = yearsOfStudy(from: degree, to: job.requirements.education.minEQF)
            // The education factor today against the one the degree earns: a
            // pass/fail gate in the regulated fields and simplified mode, the
            // relevant-degree premium everywhere else.
            let educationAfter = (job.educationIsMandatory || player.isSimplified)
                ? 1.0 : GameConstants.relevantDegreeMultiplier
            let estimate = estimatedOdds(for: job, player: player) * others
            let gain = min(0.95, estimate * educationAfter) - min(0.95, estimate * fit.education)
            guard gain > 0 else { continue }
            // Admission is a roll of its own — a rejection still spends the year.
            let admission = degree.admissionProbability(player: player)
            // Study is full-time: the job (and its pay) goes, and — outside
            // simplified mode — tuition is due.
            let tuition = player.isSimplified ? 0 : degree.totalTuition
            let cost = Double(pay * degree.yearsToComplete + tuition)
            let value = admission * careerValue(odds: gain, raise: job.income - pay,
                                                delay: years, player: player) - cost
            if beats(value, job, best.map { ($0.value, $0.job.id) }) { best = (job, degree, years, value) }
        }
        guard let best else { return nil }
        let firstStep = best.degree.eqf < best.job.requirements.education.minEQF
        var detail = firstStep
            ? "First step toward \(best.job.id) (\(money(best.job.income)) a year) — about \(best.years) years of study in all."
            : "Opens \(best.job.id) at \(money(best.job.income)) a year after \(best.years) years of study."
        if pay > 0 { detail += " You'd give up your job while studying." }
        return Tip(kind: .study, icon: best.degree.pictogram, title: "Study for a \(best.degree.degreeName)",
                   detail: detail, destination: .education, job: best.job, value: best.value)
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
            let factor = isChild ? 1.0 : min(1.0, fit.factor)
            guard factor > 0 else { continue }
            let asked = job.askedSoftSkills
            for keyPath in asked {
                let need = job.requirements.softSkills[keyPath: keyPath]
                let have = player.softSkills[keyPath: keyPath]
                guard have < need,
                      let (activity, weight) = bestActivity(for: keyPath, among: activities),
                      let axis = SoftSkills.allAxes.first(where: { $0.keyPath == keyPath }) else { continue }
                // How much one year of it lifts this role's fit, and so its odds.
                let gained = Double(min(have + weight, need) - have) / Double(need) / Double(asked.count)
                let value = careerValue(odds: 0.7 * gained * factor, raise: job.income - pay,
                                        delay: 1, player: player)
                if beats(value, job, best.map { ($0.value, $0.job.id) }) {
                    best = (job, SkillGap(axis: axis, have: have, need: need), activity, value)
                }
            }
        }
        guard let best else { return nil }
        let gap = best.gap
        let detail = isChild
            ? "Aiming for \(best.job.id) one day (\(money(best.job.income)) a year)? It asks \(gap.axis.label) \(gap.need) — you're at \(gap.have)."
            : "\(best.job.id) (\(money(best.job.income)) a year) asks \(gap.axis.label) \(gap.need) — you're at \(gap.have)."
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
        let ladder: [Level.Stage] = [.Master, .Doctorate]
        let further = ladder
            .filter { Level(stage: $0).eqf > degree.eqf && Level(stage: $0).eqf <= target }
            .reduce(0) { $0 + Level(stage: $1).yearsToComplete() }
        return degree.yearsToComplete + further
    }

    private static func enrollable(_ training: Training, _ player: Player) -> Bool {
        if case .ok = training.requirements(player) { return true }
        return false
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
