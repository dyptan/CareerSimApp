import Foundation

/// What really decides a hard-to-reach role — and the narrow way through it.
///
/// `AdvisorCoach.guide` says what's *missing* (skills, degree, licence, years).
/// For a role like CEO that's the least of it: skills are one term in one
/// formula, and the formula ends in a lottery. This reads the game's own hire
/// breakdown (`Job.HireBreakdown`) and answers the harder questions:
///
/// * **How narrow is it?** The role's yearly odds at four points — today, once
///   qualified, with everything employers see maxed, and with the best seat a
///   founder's record can win.
/// * **What are the gates?** Qualify (the hard requirements), stand out (merit
///   up to the ceiling), win the seat (the share of ideal applicants who get it).
/// * **Which levers move it, and by how much?** Skills, fame in the field,
///   network, school prestige, a course, years of experience, the founder track
///   record — each sized by re-asking the game's own formula with that lever
///   pulled, so "more fame changes nothing now, you're already at the cap" is a
///   computed fact, not a hunch. Each lever lists the concrete plays that build it
///   (events, projects, ventures, schools, feeder jobs) with the button that
///   opens the right sheet.
///
/// Like the rest of the advisor it adds no rules and mutates nothing: every
/// number is the game's (`Player.fameHireRate`, `Job.prestigeBonus`,
/// `Job.seatChance`, `HireBreakdown.odds`, …), read, never copied.
enum AdvisorPathway {

    // MARK: - What the advisor works out

    /// A role's yearly hire odds at four points along the way.
    struct Odds: Equatable {
        /// If the player applied today — 0 while a hard requirement is missing.
        let now: Double
        /// Once every hard requirement is met, at today's skills, fame, network and school.
        let qualified: Double
        /// … with everything employers see at its most (skills, fame, network,
        /// school prestige, a course), at today's seat chance.
        let maxed: Double
        /// … and at the best seat chance a founder's record can win.
        let best: Double
        /// The share of ideal applicants who clear the seat, today and at best
        /// (1 for a role with no scarce seat).
        let seat: Double
        let bestSeat: Double
        /// 0…1: how much of a top candidate's application the player has — 1 means
        /// the game's odds ceiling is already reached, so more polish changes nothing.
        let strength: Double
    }

    /// One thing the hire odds turn on.
    struct Lever: Identifiable, Equatable {
        enum Kind: Int {
            case breakthrough, experience, skills, fame, network, prestige, credential, seat
        }

        enum State: Equatable {
            /// More of it still raises the odds.
            case open
            /// Already the most the game counts.
            case maxed
            /// Room is left in the formula, but the application is already at the
            /// ceiling — more of it changes nothing until something else moves.
            case capped
        }

        let kind: Kind
        let icon: String
        let title: String
        /// Where the player stands, in a phrase: "0 of 5 points".
        let standing: String
        /// How the game weighs it.
        let mechanics: String
        /// Yearly odds this lever alone would add if maxed (0…1).
        let potential: Double
        let state: State
        /// The plays that build it — each with the button that opens its sheet.
        let sources: [AdvisorCard]

        var id: Int { kind.rawValue }
    }

    struct Pathway: Equatable {
        let title: String
        /// Even the best case is worse than a coin flip each year.
        let isNarrow: Bool
        let odds: Odds
        /// The narrowness in a sentence.
        let headline: String
        /// The funnel: qualify → stand out → win the seat.
        let gates: [AdvisorCard]
        /// Biggest lever first.
        let levers: [Lever]
        /// How it works in the real world, when there's a note for the role.
        let note: AdvisorRealWorld.Note?

        /// The lever most worth pulling next — the biggest open one that has a
        /// play to make right now.
        var bestMove: (lever: Lever, source: AdvisorCard)? {
            for lever in levers where lever.state == .open {
                if let source = lever.sources.first(where: { !$0.actions.isEmpty }) { return (lever, source) }
            }
            return nil
        }

        /// Levers with room in the formula that the ceiling makes pointless for now.
        var cappedLevers: [Lever] { levers.filter { $0.state == .capped } }

        /// The levers as cards: the four that matter most, each with the plays
        /// that build it and the buttons that open them, then a line for the rest.
        var leverCards: [AdvisorCard] {
            let shown = levers.filter {
                $0.state == .open && ($0.potential >= 0.005 || $0.kind == .breakthrough || $0.kind == .seat)
            }
            .prefix(4)
            var cards = shown.map { lever -> AdvisorCard in
                var detail = lever.mechanics
                if lever.potential >= 0.005 {
                    detail += "\nWorth about +\(AdvisorPathway.points(lever.potential)) chance a year."
                }
                let ways = lever.sources.filter { !$0.detail.isEmpty }.prefix(3)
                if !ways.isEmpty {
                    detail += "\n" + ways.map { "• \($0.title): \($0.detail)" }.joined(separator: "\n")
                }
                var actions: [AdvisorAction] = []
                for way in ways {
                    for action in way.actions where !actions.contains(where: { $0.id == action.id }) {
                        actions.append(action)
                    }
                }
                return AdvisorCard(icon: lever.icon, title: "\(lever.title) · \(lever.standing)",
                                   detail: detail, actions: actions)
            }
            let rest = levers.filter { lever in !shown.contains { $0.id == lever.id } }
            if !rest.isEmpty {
                let lines = rest.map { lever -> String in
                    switch lever.state {
                    case .maxed: return "• \(lever.title): \(lever.standing) — already the most that counts."
                    case .capped: return "• \(lever.title): \(lever.standing) — enough for now; more changes nothing."
                    case .open: return "• \(lever.title): \(lever.standing) — worth under 1% a year."
                    }
                }
                cards.append(AdvisorCard(icon: "✔️", title: "The rest", detail: lines.joined(separator: "\n")))
            }
            return cards
        }

        /// Everything a model may quote about the pathway, one fact per line.
        var facts: [String] {
            // Short on purpose: a small model answers better from a few clear
            // lines than from every lever.
            var facts = [headline] + gates.map(\.detail)
            for (index, lever) in levers.prefix(3).enumerated() {
                var line = "\(lever.title): \(lever.standing). \(lever.mechanics)"
                switch lever.state {
                case .open where lever.potential >= 0.005:
                    line += " Worth about +\(AdvisorPathway.points(lever.potential)) chance a year."
                case .capped:
                    line += " Already enough — more of it changes nothing for now."
                default: break
                }
                facts.append(line)
                if index == 0, let source = lever.sources.first { facts.append("Way to build it: \(source.detail)") }
            }
            return facts
        }
    }

    // MARK: - The pathway

    /// The pathway to `guide`'s role from where the player stands. Nil in
    /// Simplified (which has no odds, fame or network to weigh), for a player
    /// who already holds the top of the ladder, and for a promotion — that has
    /// its own maths (`Player.promotionOdds`).
    static func pathway(for guide: AdvisorCoach.RoleGuide, player: Player) -> Pathway? {
        guard !player.isSimplified, !guide.atTop, !guide.isPromotion else { return nil }
        let job = guide.focus
        let b = job.hireBreakdown(for: player, requestedSalary: Double(CareerAdvisor.offer(job, player)))
        let context = Context(player: player, job: job, guide: guide, b: b)
        if b.breakthroughMissing { return breakthroughPathway(context) }

        let room = context.room
        let maxed = b.odds(requirementFactor: context.qualifiedFactor, extraMerit: room.total)
        let bestSeat = context.bestSeat
        let odds = Odds(
            now: guide.closed ? 0 : (guide.odds ?? 0),
            qualified: context.qualified,
            maxed: maxed,
            best: b.seat > 0 ? min(1, maxed * bestSeat / b.seat) : maxed,
            seat: b.seat, bestSeat: bestSeat, strength: context.strength)

        let levers = [
            experienceLever(context), skillsLever(context), fameLever(context), networkLever(context),
            prestigeLever(context), credentialLever(context), seatLever(context),
        ]
            .compactMap { $0 }
            .sorted { lhs, rhs in
                (lhs.potential, -lhs.kind.rawValue) > (rhs.potential, -rhs.kind.rawValue)
            }
        let narrow = odds.best < 0.5
        return Pathway(
            title: guide.title, isNarrow: narrow, odds: odds,
            headline: headline(guide.title, odds: odds, exec: job.isExecutive, narrow: narrow),
            gates: gates(context, odds: odds, levers: levers),
            levers: levers, note: AdvisorRealWorld.note(for: job))
    }

    // MARK: - Working it out

    /// What the levers are read against: the player, the rung, and the game's
    /// own breakdown of their application.
    private struct Context {
        let player: Player
        let job: Job
        let guide: AdvisorCoach.RoleGuide
        let b: Job.HireBreakdown

        var top: Bool { job.isTopLeadership }
        var fameBucket: FameCategory? { job.category.fameCategory }

        /// The requirement factors once every gate is cleared: the degree at its
        /// best, the stated years held. (Age and licences are pass/fail: 1.)
        var qualifiedFactor: Double {
            let degreeLevel = !job.educationIsMandatory && job.requirements.education.minEQF >= 4
            let education = max(b.requirements.education, degreeLevel ? GameConstants.relevantDegreeMultiplier : 1.0)
            return education * job.experienceFactor(ratio: 1.0)
        }

        var qualified: Double { b.odds(requirementFactor: qualifiedFactor) }

        /// How much each merit term can still grow before the game stops counting it.
        var room: (skills: Double, fame: Double, network: Double, prestige: Double, credential: Double, total: Double) {
            let skills = max(0, GameConstants.hireSkillWeight - b.skill)
            let fame = fameBucket == nil ? 0 : max(0, Player.fameHireCap(topPosition: top) - b.fame)
            let network = max(0, Player.networkHireCap - b.network)
            let prestige = degreeLevel ? max(0, Job.prestigeBonus(forPrestige: 3) - b.prestige) : 0
            let credential = max(0, credentialMax - b.credential)
            return (skills, fame, network, prestige, credential, skills + fame + network + prestige + credential)
        }

        /// Prestige only counts on a degree-level role.
        var degreeLevel: Bool { job.requirements.education.minEQF >= 4 }

        /// The strongest skill-building course covering the role's field.
        var credentialMax: Double {
            Training.helpfulByCategory[job.category]?.compactMap { $0.careerBoost?.weight }.max() ?? 0
        }

        /// The seat chance a founder's record can reach: the role's own seat plus
        /// the most a track record adds, on a commercial executive seat.
        var bestSeat: Double {
            guard let base = job.seatScarcity else { return 1 }
            return min(1, base + (job.isExecutive ? GameConstants.executiveTrackRecordCap : 0))
        }

        /// The application's strength: the score the game clamps, against its ceiling.
        var strength: Double {
            let scaled = b.merit * qualifiedFactor * b.salaryFit * b.demand * b.rungDecay
                * b.climate * b.unemployment
            return b.ceiling > 0 ? min(1, scaled / b.ceiling) : 1
        }

        /// The yearly odds gained if merit grew by `extra`, once qualified.
        func gain(_ extra: Double) -> Double {
            guard extra > 0 else { return 0 }
            return max(0, b.odds(requirementFactor: qualifiedFactor, extraMerit: extra) - qualified)
        }

        func state(room: Double, gain: Double) -> Lever.State {
            if room <= 0.0005 { return .maxed }
            return gain < 0.0005 ? .capped : .open
        }
    }

    // MARK: Levers

    private static func experienceLever(_ c: Context) -> Lever? {
        let wanted = c.job.requirements.minYearsExperience
        guard wanted > 0 else { return nil }
        let have = c.job.relevantYears(for: c.player)
        let door = c.job.minimumQualifyingYears(simplified: false)
        let credited = c.job.category.creditedExperienceCategories
        let scope = c.job.experienceLadder ?? c.job.category.rawValue
        let venturesCount = c.job.experienceLadder == nil && !credited.isEmpty
        var mechanics = door < wanted
            ? "It expects \(wanted) years in \(scope). Under \(door) you're not considered at all; between \(door) and \(wanted) your chance is scaled down; past \(wanted) a veteran gets a small bonus."
            : "It expects \(wanted) years in \(scope). Under that you're not considered at all; past it a veteran gets a small bonus."
        if venturesCount { mechanics += " Years running your own business count too." }
        let potential = max(0, c.qualified - (c.guide.closed ? 0 : (c.guide.odds ?? 0)))
        var sources = feederCards(c)
        if venturesCount {
            sources += ventureExperienceCards(c)
        }
        return Lever(kind: .experience, icon: "🧭", title: "Years of experience",
                     standing: "\(have) of \(wanted) years", mechanics: mechanics,
                     potential: potential, state: have >= wanted ? .maxed : .open, sources: sources)
    }

    private static func skillsLever(_ c: Context) -> Lever? {
        let asked = c.job.askedSoftSkills
        guard !asked.isEmpty else { return nil }
        let room = c.room.skills
        let potential = c.gain(room)
        let strong = c.job.softSkillsHelpfulScore(for: c.player)
        let gaps = AdvisorCoach.skillNeeds(for: c.job, player: c.player)
        var mechanics = "Your skills count for up to +\(percent(GameConstants.hireSkillWeight)) of your chance — the biggest single term. Each skill the job asks for is scored against the level it wants."
        if !gaps.isEmpty {
            mechanics += " Furthest behind: " + AdvisorCoach.list(gaps.prefix(4).map { "\($0.pictogram) \($0.label) \($0.have)/\($0.need)" }) + "."
        }
        let plan = skillPlan(c)
        var sources: [AdvisorCard] = []
        if let plan, !plan.moves.isEmpty {
            let years = plan.years > 12 ? "more than a decade" : "about \(plan.years) year\(plan.years == 1 ? "" : "s")"
            sources.append(AdvisorCard(
                icon: "🗓️", title: "A plan for your skills",
                detail: "One move a year — \(AdvisorCoach.list(plan.moves.map(\.label))) — closes the whole gap in \(years)."))
        }
        sources += skillMoves(c).prefix(3).map(\.card)
        return Lever(kind: .skills, icon: "🧠", title: "Skills the job asks for",
                     standing: "\(strong) of \(asked.count) strong enough (\(percent(c.b.skillFit)) match)",
                     mechanics: mechanics, potential: potential,
                     state: c.state(room: room, gain: potential), sources: sources)
    }

    private static func fameLever(_ c: Context) -> Lever? {
        guard let bucket = c.fameBucket else { return nil }
        let rate = Player.fameHireRate(topPosition: c.top), cap = Player.fameHireCap(topPosition: c.top)
        let points = c.player.famePoints(for: bucket)
        let room = c.room.fame
        let potential = c.gain(room)
        var mechanics = "Each point of \(bucket.icon) \(bucket.rawValue) fame adds +\(percent(rate)) to your chance, up to +\(percent(cap))."
        if c.top { mechanics += " For a top seat, a public name counts for more than for an ordinary job." }
        return Lever(kind: .fame, icon: bucket.icon, title: "\(bucket.rawValue) fame",
                     standing: "\(decimal(points)) of \(decimal(cap / rate)) points",
                     mechanics: mechanics, potential: potential,
                     state: c.state(room: room, gain: potential),
                     sources: eventCards(c) + projectFameCards(c, bucket: bucket))
    }

    private static func networkLever(_ c: Context) -> Lever? {
        let points = c.player.networkPoints(for: c.job.category)
        let room = c.room.network
        let potential = c.gain(room)
        return Lever(kind: .network, icon: "🤝", title: "Network in \(c.job.category.rawValue)",
                     standing: "\(points) of \(Int((Player.networkHireCap / Player.networkHirePerPoint).rounded())) points",
                     mechanics: "Each point adds +\(decimal(Player.networkHirePerPoint * 100))% to your chance, up to +\(percent(Player.networkHireCap)). It's built at that field's events — going adds some, and being accepted to speak adds more.",
                     potential: potential, state: c.state(room: room, gain: potential),
                     sources: c.fameBucket == nil ? eventCards(c) : [])
    }

    private static func prestigeLever(_ c: Context) -> Lever? {
        guard c.degreeLevel else { return nil }
        let room = c.room.prestige
        let potential = c.gain(room)
        let standing: String
        switch c.b.prestige {
        case Job.prestigeBonus(forPrestige: 3)...: standing = "an elite university"
        case Job.prestigeBonus(forPrestige: 2)...: standing = "a state university"
        default: standing = "no ranked school yet"
        }
        return Lever(kind: .prestige, icon: "🏆", title: "School prestige",
                     standing: standing,
                     mechanics: "A relevant degree from an elite university adds +\(percent(Job.prestigeBonus(forPrestige: 3))) to your chance, a state university +\(percent(Job.prestigeBonus(forPrestige: 2))).",
                     potential: potential, state: c.state(room: room, gain: potential),
                     sources: prestigeCards(c))
    }

    private static func credentialLever(_ c: Context) -> Lever? {
        guard c.credentialMax > 0, let courses = Training.helpfulByCategory[c.job.category] else { return nil }
        let room = c.room.credential
        let potential = c.gain(room)
        let held = courses.filter { c.player.hardSkills.trainings.contains($0) }
        let cards = courses
            .filter { !c.player.hardSkills.trainings.contains($0) }
            .prefix(2)
            .map { course -> AdvisorCard in
                let weight = course.careerBoost?.weight ?? 0
                switch course.requirements(c.player) {
                case .ok:
                    return AdvisorCard(icon: "📜", title: course.friendlyName,
                                       detail: "Adds +\(percent(weight)) to your chance for \(c.job.category.rawValue) jobs. Not required — a credential that shows you're serious. One course counts; they don't stack.",
                                       actions: openable(.education, c.player))
                case .blocked(let reason):
                    return AdvisorCard(icon: "📜", title: course.friendlyName,
                                       detail: "Adds +\(percent(weight)) to your chance for \(c.job.category.rawValue) jobs. Not open to you yet: \(reason).")
                }
            }
        return Lever(kind: .credential, icon: "📜", title: "A course for the field",
                     standing: held.isEmpty ? "none yet" : held.map(\.friendlyName).joined(separator: ", "),
                     mechanics: "One skill-building credential covering \(c.job.category.rawValue) adds up to +\(percent(c.credentialMax)) to your chance. It isn't required, and they don't stack.",
                     potential: potential, state: c.state(room: room, gain: potential), sources: Array(cards))
    }

    private static func seatLever(_ c: Context) -> Lever? {
        guard let base = c.job.seatScarcity else { return nil }
        let exec = c.job.isExecutive
        let record = c.player.founderTrackRecordPoints
        let capPoints = GameConstants.executiveTrackRecordCap / GameConstants.executiveTrackRecordPerPoint
        var mechanics = "Only \(percent(base)) of the people who qualify get a seat like this each year — however strong the application."
        var standing = "\(percent(c.b.seat)) of ideal candidates get it each year"
        var potential = 0.0
        var state = Lever.State.maxed
        var sources: [AdvisorCard] = []
        if exec {
            mechanics += " Having run your own company eases it: each point of founder track record adds +\(percent(GameConstants.executiveTrackRecordPerPoint)), up to +\(percent(GameConstants.executiveTrackRecordCap))."
            standing += " · track record \(decimal(record)) of \(decimal(capPoints)) points"
            potential = c.qualified * max(0, c.bestSeat / c.b.seat - 1)
            state = record >= capPoints - 0.001 ? .maxed : .open
            sources = founderCards(c, record: record, capPoints: capPoints)
        }
        return Lever(kind: .seat, icon: "🎟️", title: "The seat", standing: standing, mechanics: mechanics,
                     potential: potential, state: state, sources: sources)
    }

    // MARK: Gates and headline

    private static func headline(_ title: String, odds: Odds, exec: Bool, narrow: Bool) -> String {
        let flawless = chance(odds.maxed)
        var line: String
        if narrow {
            line = "\(title) is a narrow path: even a flawless candidate is hired only about \(flawless) of the years they apply"
        } else if odds.maxed >= 0.85 {
            line = "\(title) is open to a well-prepared candidate: at your very best you'd be hired about \(flawless) of the years you apply"
        } else {
            line = "\(title) is competitive but not a lottery: at your very best you'd be hired about \(flawless) of the years you apply"
        }
        if exec, odds.bestSeat > odds.seat + 0.001 {
            line += " (about \(chance(odds.best)) with a founder's track record)"
        }
        line += narrow ? " — so it usually takes many attempts." : "."
        return line
    }

    private static func gates(_ c: Context, odds: Odds, levers: [Lever]) -> [AdvisorCard] {
        var cards: [AdvisorCard] = []

        // 1 · Qualify
        var qualify = c.guide.closed
            ? "Closed today. Still missing: \(AdvisorCoach.list(c.guide.needs))."
            : "Open — you meet the hard requirements."
        if c.guide.closed, c.guide.needs.isEmpty { qualify = "Closed today — see the steps above." }
        if let line = timeline(c) { qualify += " " + line }
        cards.append(AdvisorCard(icon: "①", title: "Get through the door", detail: qualify))

        // 2 · Stand out
        let stand: String
        if odds.strength >= 0.999 {
            stand = "Your application is already as strong as the game counts — the chance is capped at \(percent(c.b.ceiling)). More polish changes nothing; what's left is the seat."
        } else {
            let ways = levers.filter { $0.state == .open && $0.kind != .seat && $0.kind != .experience && $0.potential >= 0.005 }
                .prefix(3).map { "\($0.title) (+\(points($0.potential)))" }
            stand = "At today's skills, fame, network and school your application is \(percent(odds.strength)) of a top candidate's."
                + (ways.isEmpty ? "" : " Biggest ways up: \(AdvisorCoach.list(Array(ways))).")
        }
        cards.append(AdvisorCard(icon: "②", title: "Stand out", detail: stand))

        // 3 · Win the seat — or beat the crowd
        if c.b.seat < 1 {
            var seat = "Only \(percent(c.b.seat)) of applicants who are otherwise ideal get the seat each year."
            if c.job.isExecutive, odds.bestSeat > odds.seat + 0.001 {
                seat += " A founder's track record can raise that to \(percent(odds.bestSeat))."
            }
            seat += " Each application spends a whole year, so it pays to lift these odds first rather than apply at a long shot."
            cards.append(AdvisorCard(icon: "③", title: "Win the seat", detail: seat))
        } else if c.b.demand < 1 {
            cards.append(AdvisorCard(
                icon: "③", title: "Beat the crowd",
                detail: "Far more people want this job than there are openings, so your chance is cut to \(percent(c.b.demand)) of what it would otherwise be."))
        }
        return cards
    }

    /// When the door could open, if the player did everything in the obvious
    /// order: study first (full-time), then the years.
    private static func timeline(_ c: Context) -> String? {
        let job = c.job
        let wanted = job.requirements.minYearsExperience
        let studying = c.player.currentEducation?.profile != nil
        var start = max(c.player.age, job.minimumHireAge)
        let edu = job.requirements.education
        if !job.educationMet(for: c.player), edu.minEQF >= 4, !studying {
            let begin = max(c.player.age, GameConstants.minimumTertiaryAge)
            let accepted = edu.acceptedProfiles ?? []
            let options = availableNextEducations(holds: c.player.degrees).filter { degree in
                accepted.isEmpty || degree.profile.map(accepted.contains) == true
            }
            if let degree = CareerAdvisor.bestDegree(options, toward: edu.minEQF) {
                start = max(start, begin + CareerAdvisor.yearsOfStudy(from: degree, to: edu.minEQF))
            }
        }
        let have = job.relevantYears(for: c.player)
        let door = start + max(0, job.minimumQualifyingYears(simplified: false) - have)
        let full = start + max(0, wanted - have)
        guard door > c.player.age else { return nil }
        if wanted == 0 || door == full {
            return "Earliest realistic: about age \(door)."
        }
        return "Earliest realistic: the door opens around age \(door), at full strength around \(full)."
    }

    // MARK: Sources — the plays that build each lever

    private static func openable(_ destination: CareerAdvisor.Destination, _ player: Player) -> [AdvisorAction] {
        guard canOpen(destination, player) else { return [] }
        return [AdvisorAction(label: destination.buttonLabel, effect: .go(destination))]
    }

    /// Whether the footer would offer the sheet — a link mustn't lead where the
    /// player can't go.
    private static func canOpen(_ destination: CareerAdvisor.Destination, _ player: Player) -> Bool {
        switch destination {
        case .events: return EventCatalog.all.contains(where: player.canJoinEvent)
        case .projects: return SideHustleCatalog.all.contains { $0.stages.contains(LifeStage.forAge(player.age)) }
        case .ventures:
            return !player.isSimplified && player.age >= GameConstants.minimumEntrepreneurAge
                && player.currentOccupation?.isEntrepreneurial != true
        case .boardroom: return player.canMakeExecutiveDecisions
        case .education: return CareerAdvisor.canOpenEducation(player)
        default: return true
        }
    }

    /// Industry events in the role's field — where fame and network come from.
    private static func eventCards(_ c: Context, limit: Int = 2) -> [AdvisorCard] {
        let joinable = EventCatalog.all.filter { event in
            (event.category == c.job.category || (c.fameBucket != nil && event.category.fameCategory == c.fameBucket))
                && c.player.canJoinEvent(event)
        }
        guard !joinable.isEmpty else {
            let anyEvent = EventCatalog.all.contains {
                $0.category == c.job.category || (c.fameBucket != nil && $0.category.fameCategory == c.fameBucket)
            }
            guard anyEvent else { return [] }
            return [AdvisorCard(icon: "🎟️", title: "Industry events",
                                detail: "Events in this field open once you're 18 and have worked or studied in it. Build a first year or two, then take the stage.")]
        }
        return joinable
            .sorted { lhs, rhs in
                let l = c.player.presentOdds(lhs) * lhs.presenterFameWeight + Double(lhs.networkPoints)
                let r = c.player.presentOdds(rhs) * rhs.presenterFameWeight + Double(rhs.networkPoints)
                return (l, rhs.name) > (r, lhs.name)
            }
            .prefix(limit)
            .map { event in
                let odds = c.player.presentOdds(event)
                let bucket = event.category.fameCategory
                let fame = bucket.map { "+\(weight(event.presenterFameWeight)) \($0.icon) fame" }
                let builds = event.category == c.job.category
                var accepted = [fame].compactMap { $0 }
                if builds { accepted.append("+\(event.networkPoints) network in \(event.category.rawValue)") }
                var detail = "\(percent(odds)) chance the organisers accept you to \(event.presenterActionLabel.lowercased())."
                if !accepted.isEmpty { detail += " If they do: \(AdvisorCoach.list(accepted))." }
                if builds { detail += " Just going adds +\(event.networkWeight) network." }
                return AdvisorCard(icon: event.icon, title: "\(event.presenterActionLabel) at \(event.name)",
                                   detail: detail, actions: openable(.events, c.player))
            }
    }

    /// Spare-time projects that bank fame in the field's bucket.
    private static func projectFameCards(_ c: Context, bucket: FameCategory, limit: Int = 2) -> [AdvisorCard] {
        let stage = LifeStage.forAge(c.player.age)
        return SideHustleCatalog.all
            .filter { $0.fameCategory == bucket && $0.stages.contains(stage) && c.player.canTakeProject($0) }
            .sorted { lhs, rhs in
                let l = c.player.projectOdds(for: lhs) * lhs.fameWeight
                let r = c.player.projectOdds(for: rhs) * rhs.fameWeight
                return (l, rhs.label) > (r, lhs.label)
            }
            .prefix(limit)
            .map { hustle in
                let odds = c.player.projectOdds(for: hustle)
                var detail = "\(percent(odds)) a year to land. A hit banks +\(weight(hustle.fameWeight)) \(bucket.icon) fame."
                let grows = hustle.growth.compactMap { ability -> String? in
                    guard let label = SoftSkills.label(forKeyPath: ability.keyPath) else { return nil }
                    return "\(label) +\(ability.weight)"
                }
                if !grows.isEmpty { detail += " Hit or miss, the year builds \(AdvisorCoach.list(grows))." }
                if let field = hustle.experienceCategory {
                    detail += " It also counts as a year of \(field.rawValue) experience."
                }
                return AdvisorCard(icon: hustle.icon, title: hustle.label, detail: detail,
                                   actions: openable(.projects, c.player))
            }
    }

    /// Jobs in the role's field the player can apply for now, whose years count toward it.
    private static func feederCards(_ c: Context, limit: Int = 2) -> [AdvisorCard] {
        let fields = c.job.category.creditedExperienceCategories.union([c.job.category])
        let reachable = CareerAdvisor.catalogue(c.player)
            .filter { fields.contains($0.category) && $0.baseTitle != c.job.baseTitle && $0.seatScarcity == nil }
            .compactMap { job -> (job: Job, odds: Double)? in
                let odds = job.hireProbability(for: c.player, requestedSalary: Double(CareerAdvisor.offer(job, c.player)))
                return odds >= CareerAdvisor.minimumApplyOdds ? (job, odds) : nil
            }
        // One line per role: the best-paid rung the player can actually be hired at.
        let bestPerRole = Dictionary(grouping: reachable, by: \.job.baseTitle)
            .compactMap { $0.value.max { ($0.job.income, $1.job.id) < ($1.job.income, $0.job.id) } }
        return bestPerRole
            .sorted { ($0.job.income, $1.job.baseTitle) > ($1.job.income, $0.job.baseTitle) }
            .prefix(limit)
            .map { feeder in
                AdvisorCard(icon: feeder.job.icon, title: "Work as \(CareerAdvisor.article(for: feeder.job.id)) \(feeder.job.id)",
                            detail: "\(percent(feeder.odds)) chance to get it, \(CareerAdvisor.payStory(feeder.job, c.player)). Every year in \(feeder.job.category.rawValue) counts toward the \(c.job.requirements.minYearsExperience) this job expects.",
                            actions: [AdvisorAction(label: "See job listings", effect: .go(.listing(feeder.job.baseTitle)))])
            }
    }

    /// Ways to bank *business* experience without a job: running a venture, or a
    /// crowdfunding campaign — both credit Entrepreneurship, which counts as Business.
    private static func ventureExperienceCards(_ c: Context) -> [AdvisorCard] {
        var cards: [AdvisorCard] = []
        if canOpen(.ventures, c.player) {
            cards.append(AdvisorCard(
                icon: "🏗️", title: "Run a business of your own",
                detail: "Every year running a venture counts as a year of experience toward this job — whatever the business sells.",
                actions: openable(.ventures, c.player)))
        }
        if let campaign = SideHustleCatalog.all.first(where: {
            guard let field = $0.experienceCategory else { return false }
            return c.job.category.creditedExperienceCategories.contains(field) && $0.stages.contains(LifeStage.forAge(c.player.age))
        }) {
            cards.append(AdvisorCard(
                icon: campaign.icon, title: campaign.label,
                detail: "A year on it counts as a year of \(campaign.experienceCategory?.rawValue ?? "") experience, which counts toward \(c.job.category.rawValue) jobs — hit or miss.",
                actions: openable(.projects, c.player)))
        }
        return cards
    }

    private static func prestigeCards(_ c: Context) -> [AdvisorCard] {
        let edu = c.job.requirements.education
        let accepted = edu.acceptedProfiles ?? []
        let profile = accepted.first ?? c.player.degrees.compactMap(\.profile).first
        guard let profile, c.b.prestige < Job.prestigeBonus(forPrestige: 3) else { return [] }
        let level: Level.Stage = edu.minEQF >= 7 ? .Doctorate : edu.minEQF >= 6 ? .Master : .Bachelor
        let field = profile.rawValue.capitalized
        guard CareerAdvisor.canOpenEducation(c.player), !c.job.educationMet(for: c.player) else {
            return [AdvisorCard(icon: "🏆", title: "Aim for an elite university",
                                detail: "When you choose a school for your \(field) degree, an elite one adds +\(percent(Job.prestigeBonus(forPrestige: 3))) to your chance for the rest of your career. It admits by grades, skills and awards — start building them now.")]
        }
        let elite = Education(level, profile: profile, tier: .elite)
        let state = Education(level, profile: profile, tier: .state)
        return [AdvisorCard(
            icon: "🏆", title: "Get into an elite \(field) programme",
            detail: "Elite adds +\(percent(Job.prestigeBonus(forPrestige: 3))), a state university +\(percent(Job.prestigeBonus(forPrestige: 2))). Your chance of admission: \(percent(elite.admissionProbability(player: c.player))) at an elite school, \(percent(state.admissionProbability(player: c.player))) at a state one. Elite costs more in tuition.",
            actions: openable(.education, c.player))]
    }

    /// The plays that build a founder's track record — the seat's only lever.
    private static func founderCards(_ c: Context, record: Double, capPoints: Double) -> [AdvisorCard] {
        var cards: [AdvisorCard] = []
        let year = GameConstants.founderYearFame
        if c.player.currentOccupation?.isEntrepreneurial == true {
            cards.append(AdvisorCard(
                icon: "🏗️", title: "Keep your company alive",
                detail: "Each year it survives banks +\(decimal(year)) of track record (repeat years of the same company count for less, so a second, different one adds more). A fold only costs the lessons: +\(decimal(GameConstants.founderFoldFame))."))
            if c.player.canMakeExecutiveDecisions {
                cards.append(AdvisorCard(
                    icon: "💸", title: "Sell your stake, or raise a round",
                    detail: "Selling your stake in the Boardroom is a Successful Exit: +\(weight(GameConstants.founderExitFame)) points. Closing an investment round adds +\(decimal(GameConstants.investmentRoundFame)). A scalable business (\(AdvisorCoach.list(JobCatalog.scalableVentureTitles.sorted()))) can also break out for +\(weight(GameConstants.founderBreakoutFame)).",
                    actions: openable(.boardroom, c.player)))
            }
        } else if canOpen(.ventures, c.player) {
            let capital = c.player.maxVentureStake > 0
                ? ""
                : " You need some savings to stake first — capital is the only hard requirement."
            cards.append(AdvisorCard(
                icon: "🏗️", title: "Found a company",
                detail: "Every year it survives banks +\(decimal(year)) of track record (a second, different company adds more than a longer first one); a fold still leaves +\(decimal(GameConstants.founderFoldFame)). A breakout or a sale is worth +\(weight(GameConstants.founderExitFame)) each, so a scalable business (\(AdvisorCoach.list(JobCatalog.scalableVentureTitles.sorted()))) can fill the \(decimal(capPoints)) points fast — if it works. Its years also count as business experience.\(capital)",
                actions: openable(.ventures, c.player)))
        } else {
            cards.append(AdvisorCard(
                icon: "🏗️", title: "Found a company",
                detail: "Founding opens to adults in a realistic game. Every year it survives banks +\(decimal(year)) of track record; a breakout or a sale is worth +\(weight(GameConstants.founderExitFame)) each."))
        }
        return cards
    }

    // MARK: Skills

    /// A way to spend a year that grows skills, and what it's worth to this role.
    private struct SkillMove {
        let label: String
        let abilities: [WeightedAbility]
        let card: AdvisorCard
    }

    /// Activities, open projects and events that grow skills — with what each is
    /// worth to the role, best first.
    private static func skillMoves(_ c: Context) -> [(gain: Double, card: AdvisorCard)] {
        allSkillMoves(c)
            .map { (gain: skillGain($0.abilities, c.job, skills: c.player.softSkills), move: $0) }
            .filter { $0.gain > 0 }
            .sorted { ($0.gain, $1.move.label) > ($1.gain, $0.move.label) }
            .map { entry in
                let builds = entry.move.abilities.compactMap { ability -> String? in
                    guard let label = SoftSkills.label(forKeyPath: ability.keyPath),
                          c.job.askedSoftSkills.contains(ability.keyPath) else { return nil }
                    return "\(label) +\(ability.weight)"
                }
                var card = entry.move.card
                card = AdvisorCard(icon: card.icon, title: card.title,
                                   detail: "Adds ≈ +\(decimal(entry.gain * 100))% to your chance a year, from \(AdvisorCoach.list(builds)).",
                                   actions: card.actions)
                return (entry.gain, card)
            }
    }

    private static func allSkillMoves(_ c: Context) -> [SkillMove] {
        let stage = LifeStage.forAge(c.player.age)
        var moves: [SkillMove] = CareerAdvisor.offeredActivities(c.player).map { sport in
            SkillMove(label: sport.label, abilities: sport.abilities,
                      card: AdvisorCard(icon: sport.pictogram, title: sport.label, detail: "",
                                        actions: [AdvisorAction(label: "Open Activities", effect: .go(.activities(sport.kind)))]))
        }
        moves += SideHustleCatalog.all
            .filter { $0.stages.contains(stage) && c.player.canTakeProject($0) }
            .map { hustle in
                SkillMove(label: hustle.label, abilities: hustle.growth,
                          card: AdvisorCard(icon: hustle.icon, title: hustle.label, detail: "",
                                            actions: openable(.projects, c.player)))
            }
        moves += EventCatalog.all.filter(c.player.canJoinEvent).map { event in
            SkillMove(label: event.name, abilities: event.abilities,
                      card: AdvisorCard(icon: event.icon, title: event.name, detail: "",
                                        actions: openable(.events, c.player)))
        }
        return moves
    }

    /// The merit `abilities` would add for `job`: the game's graded skill fit, in
    /// merit terms — each asked axis closes toward its level, capped at the level.
    private static func skillGain(_ abilities: [WeightedAbility], _ job: Job, skills: SoftSkills) -> Double {
        let asked = job.askedSoftSkills
        guard !asked.isEmpty else { return 0 }
        var total = 0.0
        for keyPath in asked {
            let need = job.requirements.softSkills[keyPath: keyPath]
            let have = skills[keyPath: keyPath]
            guard have < need, let boost = abilities.first(where: { $0.keyPath == keyPath })?.weight else { continue }
            total += Double(min(boost, need - have)) / Double(need)
        }
        return total / Double(asked.count) * GameConstants.hireSkillWeight
    }

    /// One move a year, always the best one left: how many years until the skill
    /// gap closes, and the first few moves in order.
    private static func skillPlan(_ c: Context) -> (years: Int, moves: [SkillMove])? {
        let candidates = allSkillMoves(c)
        guard !candidates.isEmpty else { return nil }
        var skills = c.player.softSkills
        var chosen: [SkillMove] = []
        var years = 0
        while years < 13 {
            guard let best = candidates
                .map({ (move: $0, gain: skillGain($0.abilities, c.job, skills: skills)) })
                .filter({ $0.gain > 0.0001 })
                .max(by: { ($0.gain, $1.move.label) < ($1.gain, $0.move.label) }) else { break }
            years += 1
            if !chosen.contains(where: { $0.label == best.move.label }), chosen.count < 3 { chosen.append(best.move) }
            for ability in best.move.abilities {
                skills[keyPath: ability.keyPath] = min(skills[keyPath: ability.keyPath] + ability.weight, 10)
            }
        }
        return (years, chosen)
    }

    // MARK: Breakthrough careers

    /// A career like Professional Player: the odds sit at the floor, whatever else
    /// the player does, until a signature title is won — so that title *is* the path.
    private static func breakthroughPathway(_ c: Context) -> Pathway? {
        guard let award = c.job.breakthroughFame else { return nil }
        var sources: [AdvisorCard] = []
        let stage = LifeStage.forAge(c.player.age)
        if let contest = CompetitionCatalog.all.first(where: { $0.achievement == award }) {
            let sports = (contest.sports ?? []).sorted { $0.rawValue < $1.rawValue }
            let practised = sports.max { c.player.sportYears[$0, default: 0] < c.player.sportYears[$1, default: 0] }
            let years = practised.map { c.player.sportYears[$0, default: 0] } ?? 0
            var detail = "The \(contest.name) is the door. It enters you automatically each year you train \(AdvisorCoach.list(sports.map(\.label), conjunction: "or"))"
            detail += contest.minSportYears > 0 ? ", once you've trained \(contest.minSportYears) year\(contest.minSportYears == 1 ? "" : "s")." : "."
            if contest.stages.contains(stage), let sport = practised {
                let odds = contest.winProbability(for: c.player.softSkills, years: years + 1)
                detail += " Your chance to win it this year: \(percent(odds))."
                sources.append(AdvisorCard(icon: contest.icon, title: "Win the \(contest.name)", detail: detail,
                                           actions: [AdvisorAction(label: "Open Activities", effect: .go(.activities(sport.kind)))]))
            } else {
                detail += " It's open only to \(AdvisorCoach.list(contest.stages.map(\.displayName).sorted())) — you're not in that stage."
                sources.append(AdvisorCard(icon: contest.icon, title: "Win the \(contest.name)", detail: detail))
            }
        }
        let lever = Lever(kind: .breakthrough, icon: "🔑", title: "The “\(award)” title",
                          standing: "not won yet",
                          mechanics: "Without it your chance stays at \(percent(c.b.floor)) whatever your skills. Holding it adds +\(percent(Job.breakthroughBonus)) and opens the door.",
                          potential: 0, state: .open, sources: sources)
        let odds = Odds(now: 0, qualified: c.b.floor * c.b.seat, maxed: c.b.floor * c.b.seat, best: c.b.floor * c.b.seat,
                        seat: c.b.seat, bestSeat: c.b.seat, strength: 0)
        return Pathway(
            title: c.guide.title, isNarrow: true, odds: odds,
            headline: "\(c.guide.title) has one door: the “\(award)” title. Without it your chance stays at about \(chance(c.b.floor)), whatever else you do.",
            gates: [AdvisorCard(icon: "①", title: "Win the door-opener",
                                detail: "Win the “\(award)” title first. Only then do skills, fame and the rest count.")],
            levers: [lever], note: AdvisorRealWorld.note(for: c.job))
    }

    // MARK: - Words

    /// "30%" — a share as a whole percentage.
    static func percent(_ share: Double) -> String { "\(Int((share * 100).rounded()))%" }

    /// A yearly chance: "under 1%" rather than a misleading "0%".
    static func chance(_ probability: Double) -> String {
        probability > 0 && probability < 0.005 ? "under 1%" : percent(probability)
    }

    /// Percentage points of chance, for a lever's worth: "4%".
    static func points(_ delta: Double) -> String {
        delta < 0.005 ? "under 1%" : percent(delta)
    }

    /// One decimal, dropping a trailing ".0": 0.3, 2, 4.5.
    static func decimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(rounded)
    }

    /// A fame weight: 4 rather than 4.0.
    private static func weight(_ value: Double) -> String { decimal(value) }
}
