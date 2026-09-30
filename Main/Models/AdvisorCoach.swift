import Foundation

/// The advisor's coaching — every fact it tells the player, before any words
/// are put around it.
///
/// Where `CareerAdvisor` ranks the best moves *right now*, the coach follows a
/// player over years, and in the way they chose:
///
/// * **A role in mind** — `guide` says what stands between the player and it
///   (skills, degree, licences, years), which activity builds each skill, and
///   where the postings are.
/// * **Not decided** — `activityIdeas` points at different things to try, and
///   after a few moves `suggestions` names roles that use the skills gained.
/// * **Every move** — `checkIn` compares the player with the last review and
///   says what changed and what to correct.
///
/// Like `CareerAdvisor` it introduces no rules of its own: odds, requirements
/// and the activities' yields all come from the game's own formulas, and
/// nothing here mutates a player. The language layer (`AdvisorLanguage`) only
/// ever rephrases what this produces, so a sentence about the game can be
/// checked against the facts it came from.
enum AdvisorCoach {

    // MARK: - Tuning

    /// Moves spent trying things before the advisor names roles.
    static let exploreMoves = 3
    /// Different activities tried before a role can be read from the skills
    /// they built — a single practised skill says little about taste.
    static let minTriedActivities = 2
    /// Skill points gained (by activities, courses or events) that count as
    /// enough signal on their own.
    static let minimumGainedPoints = 3
    static let suggestionCount = 3
    static let activityIdeaCount = 3
    static let maxCheckIns = 12
    /// A fall in hire odds this big is worth a correction; a change this big is
    /// worth a mention.
    static let oddsDropWorthFlagging = 0.08
    static let oddsChangeWorthMentioning = 0.03

    // MARK: - The roles

    /// One role at every seniority level — what the player picks as a goal.
    /// Ventures are left out: they have their own capital-and-grit sheet.
    struct RoleFamily: Identifiable {
        let baseTitle: String
        let icon: String
        let category: JobCategory
        /// Entry rung first, at catalogue pay.
        let rungs: [Job]

        var id: String { baseTitle }
        var entry: Job { rungs[0] }
    }

    /// Every role in the game, by title. Built once: a rung's requirements and
    /// catalogue pay are fixed (only the employer's sector varies from year to
    /// year, and `guide` reads that off this year's postings).
    static let families: [RoleFamily] = {
        let jobs = JobCatalog.allJobs().filter { !$0.isEntrepreneurial }
        return Dictionary(grouping: jobs, by: \.baseTitle)
            .map { title, rungs -> RoleFamily in
                let ordered = rungs.sorted { $0.rung < $1.rung }.map { $0.atBaseSalary() }
                return RoleFamily(baseTitle: title, icon: ordered[0].icon,
                                  category: ordered[0].category, rungs: ordered)
            }
            .sorted { $0.baseTitle < $1.baseTitle }
    }()

    private static let familiesByTitle: [String: RoleFamily] =
        Dictionary(uniqueKeysWithValues: families.map { ($0.baseTitle, $0) })

    static func family(_ baseTitle: String) -> RoleFamily? { familiesByTitle[baseTitle] }

    /// The fields that have roles to pick from, in alphabetical order.
    static let fields: [JobCategory] =
        Array(Set(families.map(\.category))).sorted { $0.rawValue < $1.rawValue }

    static func families(in category: JobCategory) -> [RoleFamily] {
        families.filter { $0.category == category }
    }

    /// Words that carry no information in "I want to be a nurse".
    private static let fillerWords: Set<String> = [
        "i", "im", "want", "wanna", "to", "be", "a", "an", "the", "work", "working", "as", "job", "jobs",
        "become", "like", "would", "love", "am", "in", "on", "for", "and", "or", "of", "my", "me", "do",
        "something", "with", "it", "is", "so", "maybe", "think", "really", "one", "day",
    ]

    /// The words of `text` that say something: "I want to be a nurse" → ["nurse"].
    static func contentWords(_ text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 1 && !fillerWords.contains($0) }
    }

    /// The roles a player's words point at, best match first: whole title, then
    /// title words, then a rung's name ("junior developer"), then the field.
    /// Deterministic, so it works — and is what the tests pin — with no language
    /// model at all.
    static func search(_ query: String, limit: Int = 6) -> [RoleFamily] {
        let words = contentWords(query)
        guard !words.isEmpty else { return [] }
        let phrase = words.joined(separator: " ")

        func matches(_ a: String, _ b: String) -> Bool {
            if a == b { return true }
            let (short, long) = a.count <= b.count ? (a, b) : (b, a)
            guard short.count >= 4 else { return false }
            return long.hasPrefix(short) || short.commonPrefix(with: long).count >= max(4, short.count - 2)
        }
        func tokens(_ text: String) -> [String] {
            text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        }

        return families
            .compactMap { family -> (family: RoleFamily, score: Int)? in
                let title = family.baseTitle.lowercased()
                let titleWords = tokens(title)
                var score = 0
                if title == phrase { score += 20 } else if title.contains(phrase) { score += 10 }
                for word in words {
                    if titleWords.contains(where: { matches(word, $0) }) { score += 4 }
                    else if family.rungs.contains(where: { tokens($0.id).contains { matches(word, $0) } }) { score += 3 }
                    if family.category.rawValue.lowercased().contains(word) { score += 2 }
                    if family.entry.summary.lowercased().contains(word) { score += 1 }
                }
                return score > 0 ? (family, score) : nil
            }
            .sorted { ($0.score, $1.family.baseTitle) > ($1.score, $0.family.baseTitle) }
            .prefix(limit)
            .map(\.family)
    }

    // MARK: - Trying things

    /// Skills gained since the advisor's path began, biggest first.
    struct SkillGain: Equatable {
        let label: String
        let pictogram: String
        let gained: Int
    }

    static func skillGains(_ player: Player) -> [SkillGain] {
        let baseline = player.advisorPlan.baselineSkills
        return SoftSkills.allAxes
            .compactMap { axis -> SkillGain? in
                let gained = player.softSkills[keyPath: axis.keyPath] - baseline[keyPath: axis.keyPath]
                return gained > 0 ? SkillGain(label: axis.label, pictogram: axis.pictogram, gained: gained) : nil
            }
            .sorted { ($0.gained, $1.label) > ($1.gained, $0.label) }
    }

    /// The activities practised at least once since the path began.
    static func triedSince(_ player: Player) -> [Sport] {
        let baseline = player.advisorPlan.baselineSportYears
        return Sport.allCases.filter {
            player.sportYears[$0, default: 0] > baseline[$0, default: 0]
        }
    }

    struct ActivityIdea: Equatable, Identifiable {
        let sport: Sport
        /// What a year of it builds, e.g. "🎨 Creator +2".
        let builds: [String]

        var id: Sport { sport }
    }

    /// Different things to try: activities open to the player that they've
    /// practised least and that build skills the other picks — and the player —
    /// don't already have. Spreading the picks over different skills is the
    /// point: the goal is to find out what the player likes, not to grind one thing.
    static func activityIdeas(for player: Player, limit: Int = activityIdeaCount) -> [ActivityIdea] {
        var pool = CareerAdvisor.offeredActivities(player)
        let tried = Set(triedSince(player))
        var covered = Set<WritableKeyPath<SoftSkills, Int>>()
        var picks: [Sport] = []

        func novelty(_ sport: Sport) -> Double {
            var value = 0.0
            if player.sportYears[sport, default: 0] == 0 { value += 2 }
            if !tried.contains(sport) { value += 1 }
            for ability in sport.abilities where !covered.contains(ability.keyPath) {
                // Skills the player is already good at teach them less.
                let room = player.softSkills[keyPath: ability.keyPath] < 4 ? 1.0 : 0.4
                value += Double(ability.weight) * room
            }
            return value
        }

        while picks.count < limit, !pool.isEmpty {
            guard let best = pool.max(by: { (novelty($0), $1.rawValue) < (novelty($1), $0.rawValue) }) else { break }
            picks.append(best)
            pool.removeAll { $0 == best }
            covered.formUnion(best.abilities.map(\.keyPath))
        }
        return picks.map { sport in
            ActivityIdea(sport: sport, builds: sport.abilities.map { ability in
                let label = SoftSkills.label(forKeyPath: ability.keyPath) ?? "Skill"
                let pictogram = SoftSkills.pictogram(forKeyPath: ability.keyPath) ?? ""
                return "\(pictogram) \(label) +\(ability.weight)"
            })
        }
    }

    // MARK: - Reading the skills

    struct RoleSuggestion: Equatable, Identifiable {
        let baseTitle: String
        let icon: String
        let category: JobCategory
        /// The skills that make it a fit, the ones the player has grown first —
        /// e.g. "🎨 Creator".
        let matches: [String]
        let pay: String
        /// What it would take beyond that: a degree, a licence, years of work.
        let needs: [String]
        let score: Double

        var id: String { baseTitle }
    }

    /// Roles that put the skills the player has *gained* to use. Each role's
    /// score blends how much of its skill ask the player already covers with
    /// how much of what they practised it uses, and how many of its skills they
    /// grew — so a job built on the things they tried outranks one that merely
    /// asks for a lot. One per field first, so the picks aren't five flavours
    /// of the same job.
    static func suggestions(for player: Player, limit: Int = suggestionCount) -> [RoleSuggestion] {
        let reading = SkillReading(player)
        guard reading.totalGain > 0 else { return [] }
        let scored = families
            .compactMap { reading.candidate($0, player: player) }
            .sorted { ($0.score, $1.family.baseTitle) > ($1.score, $0.family.baseTitle) }

        // One per field first, then whatever fills the rest.
        var seen = Set<JobCategory>()
        var picks = scored.filter { seen.insert($0.family.category).inserted }.prefix(limit).map { $0 }
        if picks.count < limit {
            let chosen = Set(picks.map(\.family.baseTitle))
            picks += scored.filter { !chosen.contains($0.family.baseTitle) }.prefix(limit - picks.count)
        }
        return picks
            .sorted { ($0.score, $1.family.baseTitle) > ($1.score, $0.family.baseTitle) }
            .map { suggestion(from: $0, player: player) }
    }

    /// The suggestion for one role, if the skills gained point at it at all.
    static func suggestion(_ baseTitle: String, player: Player) -> RoleSuggestion? {
        guard let family = family(baseTitle),
              let candidate = SkillReading(player).candidate(family, player: player) else { return nil }
        return suggestion(from: candidate, player: player)
    }

    private static func suggestion(from candidate: SkillReading.Candidate, player: Player) -> RoleSuggestion {
        RoleSuggestion(
            baseTitle: candidate.family.baseTitle, icon: candidate.family.icon, category: candidate.family.category,
            matches: candidate.matches, pay: CareerAdvisor.payStory(candidate.family.entry, player),
            needs: guide(for: candidate.family.baseTitle, player: player)?.needs ?? [], score: candidate.score)
    }

    /// The skills gained since the path began, ready to be held against a role.
    private struct SkillReading {
        struct Candidate {
            let family: RoleFamily
            let matches: [String]
            let score: Double
        }

        var gained: [WritableKeyPath<SoftSkills, Int>: Int] = [:]
        let totalGain: Int

        init(_ player: Player) {
            let baseline = player.advisorPlan.baselineSkills
            for axis in SoftSkills.allAxes {
                let delta = player.softSkills[keyPath: axis.keyPath] - baseline[keyPath: axis.keyPath]
                if delta > 0 { gained[axis.keyPath] = delta }
            }
            totalGain = gained.values.reduce(0, +)
        }

        /// How well `family`'s entry rung uses what was gained; nil when it
        /// uses none of it.
        func candidate(_ family: RoleFamily, player: Player) -> Candidate? {
            let job = family.entry
            guard totalGain > 0, !CareerAdvisor.lacksBreakthrough(job, player) else { return nil }
            let asked = job.askedSoftSkills
            guard !asked.isEmpty else { return nil }
            var used = 0
            var hits: [(label: String, gained: Int)] = []
            for keyPath in asked {
                guard let grown = gained[keyPath] else { continue }
                used += min(grown, job.requirements.softSkills[keyPath: keyPath])
                let label = SoftSkills.label(forKeyPath: keyPath) ?? "Skill"
                let pictogram = SoftSkills.pictogram(forKeyPath: keyPath) ?? ""
                hits.append((label: "\(pictogram) \(label)", gained: grown))
            }
            guard !hits.isEmpty else { return nil }
            let fit = job.softSkillFit(for: player)
            let coverage = Double(used) / Double(totalGain)
            let precision = Double(hits.count) / Double(asked.count)
            let ranked = hits.sorted { ($0.gained, $1.label) > ($1.gained, $0.label) }.prefix(3).map(\.label)
            return Candidate(family: family, matches: Array(ranked),
                             score: 0.4 * fit + 0.3 * coverage + 0.3 * precision)
        }
    }

    // MARK: - A role in mind

    /// One skill the role asks more of than the player has.
    struct SkillNeed: Equatable, Identifiable {
        let label: String
        let pictogram: String
        let have: Int
        let need: Int
        /// The activity on offer that builds it fastest, and its yearly yield.
        let activity: Sport?
        let perYear: Int?

        var id: String { label }

        /// Years of that activity to close the gap.
        var years: Int? {
            perYear.map { Int((Double(need - have) / Double(max(1, $0))).rounded(.up)) }
        }
    }

    /// One thing between the player and a role, in the order to do it.
    struct Step: Equatable {
        enum Kind: Equatable { case listing, age, education, licence, skill, experience, apply, climb }
        let kind: Kind
        let card: AdvisorCard
    }

    /// What it takes to reach a role, from where the player stands.
    struct RoleGuide {
        let family: RoleFamily
        /// The rung the advice is aimed at: the entry rung — or, for a player
        /// already on the ladder, the one above theirs.
        let focus: Job
        /// Whether that rung is among this year's postings (the Jobs sheet
        /// lists only those).
        let posted: Bool
        /// Whether the player already works this role's ladder.
        let onLadder: Bool
        /// Whether they hold its top rung.
        let atTop: Bool
        /// Hire odds today — nil in Simplified, which hires with certainty
        /// once the requirements are met.
        let odds: Double?
        /// A hard requirement (age, degree, licence, years) is missing, so the
        /// role is closed today.
        let closed: Bool
        let skills: [SkillNeed]
        let steps: [Step]
        /// What it would take, in a phrase each: a degree, licences, years.
        let needs: [String]
        let pay: String

        var title: String { family.baseTitle }
        var cards: [AdvisorCard] { steps.map(\.card) }
        var canApply: Bool { !closed && (odds.map { $0 >= CareerAdvisor.minimumApplyOdds } ?? true) }
        /// Whether the advice is about the next rung up rather than getting in.
        var isPromotion: Bool { onLadder && !atTop }
    }

    /// The rung advice is aimed at: the entry rung — or, on the ladder, the next
    /// one up, or the top rung held.
    private static func focusRung(of family: RoleFamily, player: Player) -> (job: Job, onLadder: Bool, atTop: Bool) {
        guard let current = player.currentOccupation, current.baseTitle == family.baseTitle else {
            return (family.entry, false, false)
        }
        if let next = family.rungs.first(where: { $0.rung == current.rung + 1 }) {
            return (next, true, false)
        }
        return (family.rungs.last ?? family.entry, true, true)
    }

    /// The skills `job` asks more of than the player has, the biggest gap first.
    static func skillNeeds(for job: Job, player: Player) -> [SkillNeed] {
        let activities = CareerAdvisor.offeredActivities(player)
        return job.askedSoftSkills
            .compactMap { keyPath -> SkillNeed? in
                let need = job.requirements.softSkills[keyPath: keyPath]
                let have = player.softSkills[keyPath: keyPath]
                guard have < need, let axis = SoftSkills.allAxes.first(where: { $0.keyPath == keyPath }) else { return nil }
                let best = CareerAdvisor.bestActivity(for: keyPath, among: activities)
                return SkillNeed(label: axis.label, pictogram: axis.pictogram, have: have, need: need,
                                 activity: best?.0, perYear: best?.1)
            }
            .sorted { lhs, rhs in
                let l = Double(lhs.need - lhs.have) / Double(lhs.need)
                let r = Double(rhs.need - rhs.have) / Double(rhs.need)
                return (l, rhs.label) > (r, lhs.label)
            }
    }

    /// The qualification a role's education floor stands for, in words.
    static func degreePhrase(minEQF: Int) -> String {
        switch minEQF {
        case ..<4: return "a school diploma"
        case 4: return "a college or vocational diploma"
        case 5: return "a bachelor's degree"
        case 6: return "a master's degree"
        default: return "a doctorate"
        }
    }

    /// What the advisor tells a player who has picked `baseTitle`. Nil for a
    /// title that isn't a role.
    static func guide(for baseTitle: String, player: Player) -> RoleGuide? {
        guard let family = family(baseTitle) else { return nil }
        let (rung, onLadder, atTop) = focusRung(of: family, player: player)
        let posting = player.availableJobs.first { $0.id == rung.id && !$0.isEntrepreneurial }
        let focus = (posting ?? rung).atBaseSalary()
        let simplified = player.isSimplified
        let fit = focus.requirementFit(for: player)
        let odds: Double? = simplified ? nil
            : focus.hireProbability(for: player, requestedSalary: Double(CareerAdvisor.offer(focus, player)))
        let closed = fit.isBlocked

        // Soft skills don't count when Simplified hires — except for the young,
        // for whom they shape admissions.
        let scoresSkills = !simplified || player.age < GameConstants.minimumWorkingAge
        let skills = scoresSkills && !atTop ? skillNeeds(for: focus, player: player) : []

        var steps: [Step] = []
        var needs: [String] = []
        func add(_ kind: Step.Kind, _ icon: String, _ detail: String, title: String = "", _ actions: [AdvisorAction] = []) {
            steps.append(Step(kind: kind, card: AdvisorCard(icon: icon, title: title, detail: detail, actions: actions)))
        }

        let pay = CareerAdvisor.payStory(focus, player)
        let listed = !onLadder && posting != nil
        if !onLadder {
            if listed {
                add(.listing, "🔎", "See who's hiring \(family.baseTitle)s this year.",
                    [AdvisorAction(label: "See job listings", effect: .go(.listing(family.baseTitle)))])
            } else {
                add(.listing, "🔎", "Nobody is posting \(family.baseTitle) jobs this year — the market changes every year, so check again next year.")
            }
        }

        if atTop { return finish() }

        // Too young.
        if fit.age == 0 {
            let years = max(1, focus.minimumHireAge - player.age)
            add(.age, "🎂", "You have to be \(focus.minimumHireAge) for this job — \(years) more year\(years == 1 ? "" : "s").")
        }

        // The degree.
        let edu = focus.requirements.education
        let inSchool = player.currentEducation != nil
        let fields = list((edu.acceptedProfiles ?? []).map { $0.rawValue.capitalized }, conjunction: "or")
        let inField = fields.isEmpty ? "" : " in \(fields)"
        if !focus.educationMet(for: player), edu.minEQF >= 4 || !inSchool {
            let phrase = degreePhrase(minEQF: edu.minEQF) + inField
            needs.append(phrase)
            if let studying = player.currentEducation, studying.profile != nil,
               studying.eqf >= edu.minEQF,
               (edu.acceptedProfiles ?? []).isEmpty || studying.profile.map({ (edu.acceptedProfiles ?? []).contains($0) }) == true {
                add(.education, "🎓", "Keep studying — your \(studying.degreeName) is what this job asks for.")
            } else if CareerAdvisor.canOpenEducation(player) {
                add(.education, "🎓", "Get \(phrase). It's the longest step, so start early.",
                    [AdvisorAction(label: "Open Education", effect: .go(.education))])
            } else {
                add(.education, "🎓", "You'll need \(phrase) — that comes after school.")
            }
        }

        // The licences.
        for licence in CareerAdvisor.missingCredentials(for: focus, player: player).prefix(2) {
            needs.append(licence.friendlyName)
            switch licence.requirements(player) {
            case .ok:
                add(.licence, "🪪", "Earn the \(licence.friendlyName) — this job won't hire without it.",
                    [AdvisorAction(label: "Open Education", effect: .go(.education))])
            case .blocked(let reason):
                add(.licence, "🪪", "Earn the \(licence.friendlyName) — this job won't hire without it. (\(reason).)")
            }
        }

        // The skills.
        for need in skills.prefix(3) {
            var detail = "Grow \(need.label) from \(need.have) to \(need.need)."
            var actions: [AdvisorAction] = []
            if let activity = need.activity, let perYear = need.perYear, let years = need.years {
                detail += " \(activity.label) adds +\(perYear) a year — about \(years) year\(years == 1 ? "" : "s")."
                actions = [AdvisorAction(label: "Open Activities", effect: .go(.activities(activity.kind)))]
            }
            add(.skill, need.pictogram, detail, actions)
        }

        // The years.
        let wanted = focus.requirements.minYearsExperience
        let years = focus.relevantYears(for: player)
        if wanted > 0, years < wanted {
            needs.append("\(wanted) years of experience")
            let field = focus.experienceLadder ?? focus.category.rawValue
            add(.experience, "🧭",
                "This job expects \(wanted) years of experience; you have \(years). Working in \(field) builds it.",
                [AdvisorAction(label: "Open Jobs", effect: .go(.jobs(focus.workSetting)))])
        }

        // The way in — or up.
        if onLadder {
            if let tip = CareerAdvisor.climbTip(player), tip.job.baseTitle == family.baseTitle {
                add(.climb, "📈", tip.detail, tip.destination.map { [AdvisorAction(label: $0.buttonLabel, effect: .go($0))] } ?? [])
            } else {
                add(.climb, "📈", "Keep working — the next step up is \(focus.id) (\(pay)).")
            }
        } else if !closed {
            if listed {
                let shot = odds ?? 1
                let text: String
                if simplified {
                    text = "You can apply for \(focus.id) now!"
                } else if shot >= CareerAdvisor.minimumApplyOdds {
                    text = "You can apply for \(focus.id) now — a \(CareerAdvisor.percent(shot)) chance."
                } else {
                    // Applying spends the whole year, so a long shot is a real cost.
                    text = "You could apply for \(focus.id) now, but it's a long shot (\(AdvisorPathway.chance(shot))) — and an application spends the year. Lift your chances first."
                }
                add(.apply, shot >= CareerAdvisor.minimumApplyOdds || simplified ? "✅" : "🎲", text,
                    [AdvisorAction(label: "See job listings", effect: .go(.listing(family.baseTitle)))])
            } else {
                add(.apply, "✅", "You could apply for \(focus.id) — but there are no postings this year.")
            }
        }

        return finish()

        func finish() -> RoleGuide {
            RoleGuide(family: family, focus: focus, posted: posting != nil, onLadder: onLadder, atTop: atTop,
                      odds: odds, closed: closed, skills: skills, steps: steps, needs: needs, pay: pay)
        }
    }

    /// The opening line of a guide: the role, its pay and where the player stands.
    static func introduction(_ guide: RoleGuide, player: Player) -> String {
        let focus = guide.focus
        if guide.atTop { return "You've reached the top of the \(guide.title) ladder — \(focus.id)! 🏆" }
        if guide.isPromotion, let current = player.currentOccupation {
            return "You're working as \(current.id). The next step up is \(focus.id): \(guide.pay)."
        }
        // A ladder's entry rung has a name of its own ("First Officer"): say how
        // it relates to the role the player picked ("Airline Pilot").
        var line = focus.id == guide.title
            ? "\(guide.family.icon) \(guide.title) pays \(guide.pay)."
            : "\(guide.family.icon) To be \(CareerAdvisor.article(for: guide.title)) \(guide.title), you start as \(CareerAdvisor.article(for: focus.id)) \(focus.id), which pays \(guide.pay)."
        if guide.closed {
            line += " You can't be hired for it yet."
        } else if let odds = guide.odds {
            line += " Your chance to be hired today is \(CareerAdvisor.percent(odds))."
        } else {
            line += " You can apply for it now!"
        }
        return line
    }

    /// The facts a guide rests on, one per line — what the language layer may
    /// draw numbers from.
    static func facts(_ guide: RoleGuide, player: Player) -> [String] {
        var facts = [introduction(guide, player: player)]
        // Phrased as what is still to do, so a model can't read a suggestion
        // ("Cycling adds +3 a year") as something the player already does.
        facts += guide.steps
            .filter { ![.listing, .apply].contains($0.kind) && !$0.card.detail.isEmpty }
            .prefix(5)
            .map { "Still to do: \($0.card.detail)" }
        return facts
    }

    // MARK: - Every move

    /// Starts (or restarts) a path: fixes the baseline the skills gained and
    /// the progress made are measured from. Returns the plan; the caller stores it.
    static func begin(_ path: AdvisorPlan.Path, for player: Player) -> AdvisorPlan {
        var plan = player.advisorPlan
        plan.path = path
        plan.startedAge = player.age
        plan.baselineSkills = player.softSkills
        plan.baselineSportYears = player.sportYears
        plan.checkIns = []
        plan.unreadCount = 0
        plan.lastMark = mark(for: player, guide: plan.target.flatMap { guide(for: $0, player: player) })
        return plan
    }

    static func mark(for player: Player, guide: RoleGuide?) -> AdvisorPlan.Mark {
        var mark = AdvisorPlan.Mark(age: player.age, skills: player.softSkills, licences: player.hardSkills.trainings,
                                    educationLevel: player.highestEQF,
                                    years: guide?.focus.relevantYears(for: player) ?? 0,
                                    odds: guide?.odds, onLadder: guide?.onLadder ?? false)
        if let job = guide?.focus {
            mark.fame = player.famePoints(for: job.category.fameCategory)
            mark.network = player.networkPoints(for: job.category)
        }
        mark.founderPoints = player.founderTrackRecordPoints
        return mark
    }

    /// The review of the year that has just passed: how the player stands
    /// against the plan, what changed since the last review, and what to change.
    /// Nil when there's nothing to review — the advisor hasn't asked yet, or a
    /// finished goal has already been celebrated.
    static func checkIn(for player: Player) -> (checkIn: AdvisorCheckIn, mark: AdvisorPlan.Mark)? {
        switch player.advisorPlan.path {
        case .unasked: return nil
        case .exploring: return exploringCheckIn(player)
        case .target(let title): return targetCheckIn(title, player)
        }
    }

    private static func exploringCheckIn(_ player: Player) -> (checkIn: AdvisorCheckIn, mark: AdvisorPlan.Mark)? {
        let moves = player.advisorPlan.moves(for: player)
        let tried = triedSince(player)
        let gains = skillGains(player)
        let gainedPoints = gains.reduce(0) { $0 + $1.gained }
        let canPractise = !CareerAdvisor.offeredActivities(player).isEmpty
        let hasSignal = tried.count >= minTriedActivities || gainedPoints >= minimumGainedPoints || !canPractise

        var progress: [String] = []
        if !tried.isEmpty {
            progress.append("🧪 You've tried \(list(tried.map(\.label))).")
        }
        if !gains.isEmpty {
            progress.append("📈 Skills you've grown: " + gains.prefix(4).map { "\($0.pictogram) \($0.label) +\($0.gained)" }.joined(separator: ", ") + ".")
        }

        let verdict: AdvisorCheckIn.Verdict
        let headline: String
        var suggestions: [String] = []
        var corrections: [AdvisorCard] = []
        let picks = moves >= exploreMoves && hasSignal ? Self.suggestions(for: player) : []
        if !picks.isEmpty {
            verdict = .readyToSuggest
            headline = "You've tried a few things — I found jobs that might suit you!"
            suggestions = picks.map(\.baseTitle)
        } else {
            verdict = .exploring
            let left = exploreMoves - moves
            headline = left > 0
                ? "\(left) more move\(left == 1 ? "" : "s") of trying new things, and I'll suggest jobs that fit you."
                : "Try a couple more different things, so I can see what you like."
            let ideas = activityIdeas(for: player)
            if let idea = ideas.first, canPractise {
                if player.lastYearSports.isEmpty {
                    corrections.append(AdvisorCard(
                        icon: idea.sport.pictogram, title: "Try something",
                        detail: "You didn't practise anything last year. This year, try \(idea.sport.label) — it builds \(list(idea.builds)).",
                        actions: [AdvisorAction(label: "Open Activities", effect: .go(.activities(idea.sport.kind)))]))
                } else if tried.count == 1, moves >= 2, let first = tried.first {
                    corrections.append(AdvisorCard(
                        icon: idea.sport.pictogram, title: "Try something different",
                        detail: "You've stuck with \(first.label). To find what you like, try \(idea.sport.label) — it builds \(list(idea.builds)).",
                        actions: [AdvisorAction(label: "Open Activities", effect: .go(.activities(idea.sport.kind)))]))
                }
            }
        }
        let check = AdvisorCheckIn(age: player.age, verdict: verdict, role: nil, headline: headline,
                                   progress: progress, corrections: corrections, suggestions: suggestions)
        return (check, mark(for: player, guide: nil))
    }

    private static func targetCheckIn(_ title: String, _ player: Player) -> (checkIn: AdvisorCheckIn, mark: AdvisorPlan.Mark)? {
        guard let guide = guide(for: title, player: player) else { return nil }
        let plan = player.advisorPlan
        let now = mark(for: player, guide: guide)
        let focus = guide.focus

        // What changed since the last review.
        var progress: [String] = []
        var moved = false
        if let before = plan.lastMark {
            if !before.onLadder, now.onLadder {
                progress.append("🎉 You got a job on the \(title) ladder!")
                moved = true
            }
            for need in scoredNeeds(of: focus, player: player) {
                let then = before.skills[keyPath: need.keyPath]
                let have = player.softSkills[keyPath: need.keyPath]
                guard have > then else { continue }
                moved = true
                progress.append(have >= need.need
                    ? "✅ \(need.pictogram) \(need.label) is now \(have) — the job asks for \(need.need)."
                    : "📈 \(need.pictogram) \(need.label) went from \(then) to \(have) (the job asks for \(need.need)).")
            }
            if now.educationLevel > before.educationLevel, let degree = player.degrees.last {
                moved = true
                progress.append("🎓 You earned your \(degree.degreeName).")
            }
            let earned = now.licences.subtracting(before.licences)
            if !earned.isEmpty {
                moved = true
                progress.append("🪪 You earned the \(list(earned.map(\.friendlyName).sorted())).")
            }
            let wanted = focus.requirements.minYearsExperience
            if wanted > 0, now.years > before.years, now.years <= wanted {
                moved = true
                progress.append("🧭 Another year of experience: \(now.years) of the \(wanted) this job expects.")
            }
            if let bucket = focus.category.fameCategory, now.fame > before.fame + 0.05 {
                moved = true
                progress.append("🌟 Your \(bucket.icon) \(bucket.rawValue) fame went from \(AdvisorPathway.decimal(before.fame)) to \(AdvisorPathway.decimal(now.fame)).")
            }
            if now.network > before.network {
                moved = true
                progress.append("🤝 Your network in \(focus.category.rawValue) grew from \(before.network) to \(now.network).")
            }
            if now.founderPoints > before.founderPoints + 0.05, focus.isExecutive {
                moved = true
                let capPoints = GameConstants.executiveTrackRecordCap / GameConstants.executiveTrackRecordPerPoint
                progress.append("🏗️ Your founder track record grew from \(AdvisorPathway.decimal(before.founderPoints)) to \(AdvisorPathway.decimal(now.founderPoints)) of \(AdvisorPathway.decimal(capPoints)) — the seat chance is now \(AdvisorPathway.percent(focus.seatChance(for: player))).")
            }
            if let was = before.odds, let odds = now.odds, abs(odds - was) >= oddsChangeWorthMentioning {
                progress.append("🎯 Your chance to be hired went from \(CareerAdvisor.percent(was)) to \(CareerAdvisor.percent(odds)).")
            }
        }

        // Where that leaves them.
        let verdict: AdvisorCheckIn.Verdict
        let headline: String
        if guide.atTop {
            verdict = .goalReached
            headline = "You made it! You're at the top of the \(title) ladder: \(focus.id). 🏆"
            // Celebrated once, not every year after.
            if plan.checkIns.last?.verdict == .goalReached { return nil }
        } else if guide.isPromotion {
            verdict = .onTrack
            headline = "You're working toward \(focus.id) — the next step up the \(title) ladder."
        } else if guide.canApply && guide.posted {
            verdict = .ready
            headline = guide.odds.map { "You're ready to apply for \(focus.id) — your chance is \(CareerAdvisor.percent($0))." }
                ?? "You're ready to apply for \(focus.id)!"
        } else if guide.canApply {
            // Qualified, but nobody is hiring this year.
            verdict = .onTrack
            headline = "You're qualified for \(focus.id) — now it's a matter of waiting for a posting."
        } else if moved {
            verdict = .onTrack
            headline = "You're getting closer to \(title). Nice work!"
        } else {
            verdict = .needsCorrection
            headline = "This year didn't move you closer to \(title)."
        }

        // What to change.
        var corrections: [AdvisorCard] = []
        if !guide.atTop {
            if !guide.posted, !guide.onLadder {
                corrections.append(AdvisorCard(
                    icon: "⏳", title: "Not hiring right now",
                    detail: "Nobody is posting \(title) jobs this year. Keep building your skills and check again next year."))
            }
            if let was = plan.lastMark?.odds, let odds = now.odds, was - odds >= oddsDropWorthFlagging {
                let slump = player.climate(for: focus.industry) == .slump
                    ? " The \(focus.industry.rawValue) industry is in a slump, so employers are hiring less. Keep building skills and try again when it recovers."
                    : ""
                corrections.append(AdvisorCard(
                    icon: "📉", title: "Your chances fell",
                    detail: "Your chance to be hired dropped from \(CareerAdvisor.percent(was)) to \(CareerAdvisor.percent(odds)).\(slump)"))
            }
            // Where the odds really turn — the levers of a hard-to-reach role.
            let path = AdvisorPathway.pathway(for: guide, player: player)
            if let path {
                if path.odds.strength >= 0.999, !path.cappedLevers.isEmpty {
                    let names = list(path.cappedLevers.filter { $0.kind != .seat }.map { $0.title.lowercased() })
                    var detail = "Your application is already at the game's ceiling, so more \(names) changes nothing for now."
                    if let next = path.bestMove { detail += " What's left: \(next.lever.title.lowercased())." }
                    corrections.append(AdvisorCard(icon: "🎯", title: "Enough polish", detail: detail,
                                                   actions: path.bestMove?.source.actions ?? []))
                }
                if !moved, let next = path.bestMove {
                    var detail = "\(next.lever.title) is worth about +\(AdvisorPathway.points(next.lever.potential)) chance a year."
                    detail += " \(next.source.title): \(next.source.detail)"
                    corrections.append(AdvisorCard(icon: next.lever.icon, title: "Your biggest lever", detail: detail,
                                                   actions: next.source.actions))
                }
            }
            if path == nil, !moved, let lead = guide.skills.first, let activity = lead.activity, let perYear = lead.perYear {
                let practised = player.lastYearSports
                let helped = practised.contains { sport in
                    guide.skills.contains { need in sport.abilities.contains { SoftSkills.label(forKeyPath: $0.keyPath) == need.label } }
                }
                if !helped {
                    let detail = practised.isEmpty
                        ? "Last year didn't build any of the skills this job asks for. Try \(activity.label) — it adds \(lead.label) +\(perYear) a year (you're at \(lead.have), the job asks for \(lead.need))."
                        : "Last year you practised \(list(practised.map(\.label).sorted())) — good, but it doesn't build what \(title) asks for. Try \(activity.label) for \(lead.label) (you're at \(lead.have), the job asks for \(lead.need))."
                    corrections.append(AdvisorCard(
                        icon: lead.pictogram, title: "Practise what the job needs", detail: detail,
                        actions: [AdvisorAction(label: "Open Activities", effect: .go(.activities(activity.kind)))]))
                }
            }
            // Never leave a stalled year without a next step.
            if verdict == .needsCorrection, corrections.isEmpty,
               let next = guide.steps.first(where: { ![.listing, .apply].contains($0.kind) }) {
                corrections.append(AdvisorCard(icon: next.card.icon, title: "Your next step",
                                               detail: next.card.detail, actions: next.card.actions))
            }
        }

        let check = AdvisorCheckIn(age: player.age, verdict: verdict, role: title, headline: headline,
                                   progress: progress, corrections: Array(corrections.prefix(3)), suggestions: [])
        return (check, now)
    }

    /// The soft skills a role asks for, with their pictograms — for reading
    /// what a year changed. Empty where Simplified hiring ignores skills.
    private static func scoredNeeds(of job: Job, player: Player)
        -> [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String, need: Int)] {
        guard !player.isSimplified || player.age < GameConstants.minimumWorkingAge else { return [] }
        return job.askedSoftSkills.compactMap { keyPath in
            guard let axis = SoftSkills.allAxes.first(where: { $0.keyPath == keyPath }) else { return nil }
            return (keyPath, axis.label, axis.pictogram, job.requirements.softSkills[keyPath: keyPath])
        }
    }

    /// The facts a review rests on, one per line.
    static func facts(_ checkIn: AdvisorCheckIn) -> [String] {
        [checkIn.headline] + checkIn.progress + checkIn.corrections.map(\.detail)
    }

    /// What the advisor knows about the player, one fact per line — what a
    /// free question is answered from.
    static func playerFacts(_ player: Player) -> [String] {
        var facts = ["The player is \(player.age) years old."]
        if let job = player.currentOccupation {
            facts.append("They work as \(job.id), earning \(CareerAdvisor.money(job.annualIncome)) a year.")
        } else {
            facts.append("They have no job right now.")
        }
        facts.append("Their best qualification: \(player.degrees.max { $0.eqf < $1.eqf }?.degreeName ?? "none yet").")
        let strongest = SoftSkills.allAxes
            .map { (label: $0.label, value: player.softSkills[keyPath: $0.keyPath]) }
            .filter { $0.value > 0 }
            .sorted { ($0.value, $1.label) > ($1.value, $0.label) }
            .prefix(4)
        if !strongest.isEmpty {
            facts.append("Their strongest skills (out of 10): " + strongest.map { "\($0.label) \($0.value)" }.joined(separator: ", ") + ".")
        }
        switch player.advisorPlan.path {
        case .target(let title):
            if let guide = guide(for: title, player: player) {
                facts.append("Their goal is \(title).")
                facts += Self.facts(guide, player: player)
                if let path = AdvisorPathway.pathway(for: guide, player: player) { facts += path.facts }
                if let note = AdvisorRealWorld.note(for: guide.focus) { facts += note.facts }
            }
        case .exploring:
            facts.append("They haven't chosen a role and are trying different activities to find one.")
        case .unasked:
            break
        }
        return facts
    }

    /// "a, b and c" — or "a, b or c".
    static func list(_ items: [String], conjunction: String = "and") -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        default: return items.dropLast().joined(separator: ", ") + " \(conjunction) " + items[items.count - 1]
        }
    }
}

extension AdvisorPlan {
    /// Files a year's review: it becomes the yardstick for the next one and
    /// waits, unread, for the player to open the advisor.
    mutating func record(_ review: (checkIn: AdvisorCheckIn, mark: Mark)) {
        lastMark = review.mark
        checkIns.append(review.checkIn)
        if checkIns.count > AdvisorCoach.maxCheckIns {
            checkIns.removeFirst(checkIns.count - AdvisorCoach.maxCheckIns)
        }
        unreadCount += 1
    }
}
