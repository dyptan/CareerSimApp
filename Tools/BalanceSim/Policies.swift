import Foundation

/// A way of playing: once per year it performs exactly one action on the
/// `Game` (every action spends the year, as in the app).
protocol Policy: AnyObject {
    func act(_ g: Game)
}

// MARK: - Shared helpers

extension Game {
    /// Current pay, as the advisor reads it.
    var currentPay: Int { player.currentOccupation?.annualIncome ?? 0 }

    /// Salaried postings the Apply button is enabled for, with their odds.
    func applicablePostings() -> [(posting: Job, odds: Double, income: Int)] {
        listedJobs.compactMap { posting in
            guard canApply(posting) else { return nil }
            let o = odds(posting)
            guard o > 0 else { return nil }
            return (posting, o, posting.income)
        }
    }

    /// The offered activity that best closes the gaps between the player's soft
    /// skills and what better-paid postings ask for (0 when nothing helps).
    func bestSkillActivity() -> Sport? {
        let pay = currentPay
        var jobs = listedJobs.map { $0.atBaseSalary() }.filter { $0.income > pay }
        if jobs.isEmpty { jobs = listedJobs.map { $0.atBaseSalary() } }
        var best: (sport: Sport, score: Double)?
        for sport in offeredActivities {
            var score = 0.0
            for job in jobs {
                let asked = max(1, job.askedSoftSkills.count)
                for ability in sport.abilities {
                    let need = job.requirements.softSkills[keyPath: ability.keyPath]
                    let have = player.softSkills[keyPath: ability.keyPath]
                    guard need > have else { continue }
                    score += Double(min(ability.weight, need - have)) / Double(need) / Double(asked)
                }
            }
            if score > (best?.score ?? 0) { best = (sport, score) }
        }
        return best?.sport
    }
}

// MARK: - 1. Advisor: always act on CareerAdvisor's top actionable tip

final class AdvisorPolicy: Policy {
    func act(_ g: Game) {
        for tip in CareerAdvisor.tips(for: g.player) {
            if perform(tip, g) { return }
        }
        // No tip (or none actionable): the activity that best raises the skills
        // postings ask for, else let the year pass.
        if g.activitiesOpen, let sport = g.bestSkillActivity() {
            g.takeActivity(sport, tag: "advisor:fallback-activity")
        } else {
            g.skip("advisor:no-tip")
        }
    }

    /// Carries out a tip the way its destination sheet would. Returns false when
    /// the tip can't be acted on through the UI right now.
    func perform(_ tip: CareerAdvisor.Tip, _ g: Game) -> Bool {
        let p = g.player
        switch tip.kind {
        case .applyNow:
            guard g.jobsOpen,
                  let posting = g.listedJobs.first(where: { $0.id == tip.job.id }),
                  g.canApply(posting) else { return false }
            g.apply(to: posting, tag: "advisor:applyNow")
            return true

        case .train:
            // The course the tip names: the first missing credential for the
            // role, in the order `CareerAdvisor.trainTip` sorts them.
            let job = tip.job
            let needed = job.requirements.hardSkills.trainings
                .filter { $0.isStatutory || job.category.requiresCredentials }
            let missing = needed.subtracting(p.hardSkills.trainings).sorted { $0.rawValue < $1.rawValue }
            guard let first = missing.first, g.canTake(first) else { return false }
            g.takeTraining(first, tag: "advisor:train")
            return true

        case .study:
            // The degree the tip names ("Study for a <degreeName>"), at the tier
            // `offeredDegrees` carries (state) — community in Simplified, which
            // offers only one school.
            guard let degree = p.offeredDegrees.first(where: { "Study for a \($0.degreeName)" == tip.title }),
                  let profile = degree.profile else { return false }
            let school = g.school(level: degree.level, profile: profile, tier: degree.tier)
            guard g.canApplyToSchool(school) else { return false }
            g.applyToSchool(school, tag: "advisor:study")
            return true

        case .buildSkill:
            guard let range = tip.title.range(of: " with ") else { return false }
            let label = String(tip.title[range.upperBound...])
            guard g.activitiesOpen, let sport = g.offeredActivities.first(where: { $0.label == label }) else { return false }
            g.takeActivity(sport, tag: "advisor:buildSkill")
            return true

        case .climb:
            // Stay for the promotion; spend the spare slot on the lever activity
            // when the tip names one.
            if tip.destination != nil,
               let lever = CareerAdvisor.biggestTrainableGap(for: tip.job, player: p)?.activity,
               g.activitiesOpen, g.offeredActivities.contains(lever) {
                g.takeActivity(lever, tag: "advisor:climb-lever")
            } else {
                g.skip("advisor:climb-stay")
            }
            return true
        }
    }
}

// MARK: - 2. Typical: a plausible average person

final class TypicalPolicy: Policy {
    enum Plan { case undecided, university, vocationalFallback, work }
    var plan: Plan = .undecided
    var bachelorProfile: TertiaryProfile?
    var masterDecided = false
    var nextLookAge = 0

    /// Lowest pay a job-seeker holds out for, by qualification.
    func reservationWage(_ p: Player) -> Int {
        switch p.highestEQF {
        case ...3: return 0
        case 4: return 35_000
        case 5: return 45_000
        default: return 55_000
        }
    }

    func act(_ g: Game) {
        let p = g.player
        // Childhood and school: K-12 runs by itself; now and then a hobby.
        if p.age < GameConstants.minimumTertiaryAge {
            if g.activitiesOpen, Double.random(in: 0..<1) < 0.35, let sport = g.offeredActivities.randomElement() {
                g.takeActivity(sport, tag: "typical:hobby")
            } else {
                g.skip("typical:school")
            }
            return
        }

        // The post-high-school decision.
        if plan == .undecided {
            plan = Double.random(in: 0..<1) < 0.40 ? .university : .work
        }
        if plan == .university, g.educationOpen {
            let profile = TertiaryProfile.allCases.randomElement()!
            bachelorProfile = profile
            let school = g.school(level: .Bachelor, profile: profile, tier: .state)
            let admitted = g.applyToSchool(school, tag: "typical:bachelor")
            plan = admitted ? .work : .vocationalFallback
            return
        }
        if plan == .vocationalFallback, g.educationOpen {
            plan = .work
            let vocational = TertiaryProfile.allCases.filter(\.allowsVocational)
            let profile = bachelorProfile.flatMap { vocational.contains($0) ? $0 : nil } ?? vocational.randomElement()!
            g.applyToSchool(g.school(level: .Vocational, profile: profile, tier: .community), tag: "typical:vocational")
            return
        }
        // A few bachelor's graduates go straight on to a master's.
        if !masterDecided, g.educationOpen,
           let bachelor = p.degrees.first(where: { $0.level == .Bachelor }), let profile = bachelor.profile {
            masterDecided = true
            // ~15 % go on to a master's and ~8 % to a doctorate (MD, JD, PhD) —
            // about 4 % of US adults hold a professional or doctoral degree.
            let roll = Double.random(in: 0..<1)
            if roll < 0.15 {
                g.applyToSchool(g.school(level: .Master, profile: profile, tier: .state), tag: "typical:master")
                return
            }
            if roll < 0.23 {
                g.applyToSchool(g.school(level: .Doctorate, profile: profile, tier: .state), tag: "typical:doctorate")
                return
            }
        }

        // Studying: no job hunting, the occasional hobby.
        if g.isStudying {
            hobbyOrSkip(g)
            return
        }

        let postings = g.applicablePostings()
        if p.currentOccupation == nil {
            // Unemployed: the best-odds posting paying at least the reservation wage.
            let floor = reservationWage(p)
            let pick = postings.filter { $0.income >= floor }
                .max { ($0.odds, $0.income) < ($1.odds, $1.income) }
            let fallback = postings.max { ($0.odds, $0.income) < ($1.odds, $1.income) }
            let choice = (pick.map { $0.odds >= 0.15 } ?? false) ? pick : fallback
            if let choice {
                g.apply(to: choice.posting, tag: "typical:job-hunt")
            } else {
                g.skip("typical:no-posting")
            }
            return
        }

        // Employed: every ~3 years, look for a better-paid posting with decent odds.
        if p.age >= nextLookAge {
            nextLookAge = p.age + Int.random(in: 2...4)
            let pay = g.currentPay
            if let better = postings.filter({ $0.income > pay && $0.odds >= 0.4 })
                .max(by: { ($0.income, $0.odds) < ($1.income, $1.odds) }) {
                g.apply(to: better.posting, tag: "typical:job-change")
                return
            }
        }
        hobbyOrSkip(g)
    }

    func hobbyOrSkip(_ g: Game) {
        if g.activitiesOpen, Double.random(in: 0..<1) < 0.15, let sport = g.offeredActivities.randomElement() {
            g.takeActivity(sport, tag: "typical:hobby")
        } else {
            g.skip("typical:stay")
        }
    }
}

// MARK: - 3. Passive: school, then the likeliest job, then nothing

final class PassivePolicy: Policy {
    func act(_ g: Game) {
        let p = g.player
        guard p.age >= GameConstants.minimumTertiaryAge, p.currentOccupation == nil, g.jobsOpen else {
            g.skip("passive:stay")
            return
        }
        if let best = g.applicablePostings().max(by: { ($0.odds, $0.income) < ($1.odds, $1.income) }) {
            g.apply(to: best.posting, tag: "passive:job-hunt")
        } else {
            g.skip("passive:no-posting")
        }
    }
}

// MARK: - 4. Striver: the advisor, plus the upside ladders the advisor ignores

/// Plays the advisor's career, but also reaches for the power-law payoffs:
/// launches a venture once it has the experience and the stake for one
/// (Ventures sheet, one-tap stake), raises rounds for a scalable venture, sells
/// a founder stake after a good run, and — holding a hired executive seat —
/// sells vested shares in the Boardroom every year.
final class StriverPolicy: Policy {
    let advisor = AdvisorPolicy()
    var lastFoldAge = -100
    var foldsSeen = 0

    func act(_ g: Game) {
        let p = g.player
        if g.rec.ventureFolds > foldsSeen {
            foldsSeen = g.rec.ventureFolds
            lastFoldAge = p.age
        }

        // Boardroom plays.
        if g.boardroomOpen, let job = p.currentOccupation {
            if job.isEntrepreneurial {
                if p.canRaiseInvestmentRound, p.ventureRoundsRaised < 3, p.investmentRoundOdds() >= 0.35 {
                    g.boardroom(.investmentRound, tag: "striver:round"); return
                }
                if p.ventureBrokeOut || p.ventureYears >= 6 {
                    g.boardroom(.sellShares, tag: "striver:exit"); return
                }
            } else {
                g.boardroom(.sellShares, tag: "striver:sell-vested"); return
            }
        }

        // Found a venture once prepared: the industry years it expects, most of
        // its target capital within reach, and a good first-year survival.
        if g.venturesOpen, !g.isStudying, p.age >= 25, g.rec.venturesFounded < 3,
           p.age - lastFoldAge >= 3 {
            let ventures = p.availableJobs.filter(\.isEntrepreneurial).map { $0.atBaseSalary() }
            let ready = ventures.filter { v in
                let target = v.targetCapital ?? 0
                let stake = min(target, p.maxVentureStake)
                return p.industryExperience(for: v.category) >= v.requirements.minYearsExperience
                    && Double(stake) >= 0.5 * Double(target)
                    && v.income > g.currentPay
                    && p.firstYearSurvival(for: v, stake: stake) >= 0.8
            }
            if let pick = ready.max(by: { $0.income < $1.income }) {
                g.launchVenture(pick, tag: "striver:launch")
                return
            }
        }
        advisor.act(g)
    }
}

// MARK: - 5. Dreamer: chases the spotlight for a whole life

/// Plays soccer every year of school (the Junior Championship is the gateway
/// to the pro "Player" ladder). With the junior title, applies up the Player
/// ladder. Without it, holds the likeliest day job and spends every year on
/// the Projects sheet chasing a Breakout Role — then starring in films once
/// the big break lands.
final class DreamerPolicy: Policy {
    func act(_ g: Game) {
        let p = g.player
        if p.age < GameConstants.minimumTertiaryAge {
            if g.offeredActivities.contains(.soccer) { g.takeActivity(.soccer, tag: "dreamer:soccer") } else { g.skip("dreamer:school") }
            return
        }
        let postings = g.applicablePostings()
        // The pro track: sign with a club, then apply up the ladder (the Player
        // ladder is low-skilled, so it never promotes in place).
        if p.fameAwards.contains(where: { $0.title == "Junior Champion" }) {
            let current = p.currentOccupation
            let playerRungs = postings.filter { $0.posting.baseTitle == "Player" }
            if let next = playerRungs.filter({ current?.baseTitle != "Player" || $0.posting.rung > current!.rung })
                .max(by: { $0.posting.rung < $1.posting.rung }) {
                g.apply(to: next.posting, tag: "dreamer:pro-contract"); return
            }
            if current?.baseTitle == "Player" { g.skip("dreamer:pro-stay"); return }
        }
        // A day job pays the rent.
        if p.currentOccupation == nil {
            if let best = postings.max(by: { ($0.odds, $0.income) < ($1.odds, $1.income) }) {
                g.apply(to: best.posting, tag: "dreamer:day-job")
            } else {
                g.skip("dreamer:no-posting")
            }
            return
        }
        if p.fameAwards.contains(where: { $0.title == "Breakout Role" }) {
            g.takeProject("starFilm", tag: "dreamer:star-film")
        } else {
            g.takeProject("bigBreakActing", tag: "dreamer:big-break")
        }
    }
}

func makePolicy(_ name: String) -> Policy {
    switch name {
    case "advisor": return AdvisorPolicy()
    case "typical": return TypicalPolicy()
    case "passive": return PassivePolicy()
    case "striver": return StriverPolicy()
    case "dreamer": return DreamerPolicy()
    default: fatalError("unknown policy \(name)")
    }
}
