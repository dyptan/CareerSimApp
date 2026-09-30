import Foundation

/// How the hard-to-reach careers really work — the part the game only models.
///
/// A game can say "only 10% of ideal candidates get the seat"; it can't say
/// *why* boards behave that way, what people in that job actually did to get
/// there, or what the game leaves out. Each note pairs a real-world point with
/// the in-game counterpart, so the player learns the lesson and how the game
/// plays it. The words are curated, not generated: a model may rephrase them, but
/// it never supplies the facts.
///
/// Figures are the ones the game's own constants already cite (Spencer Stuart
/// 2025 on CEO appointments, NCAA draft rates, Goldman Sachs analyst intake, AAMC
/// on medical admission), stated loosely — "about", "roughly", "most" — because
/// they describe patterns, not rules. The in-game half is built from the
/// constants themselves, so it can't drift from the game.
///
/// Those sources are American, so a point that only holds there says so: it
/// carries a `tail` that is added for that country alone, or is limited to the
/// countries it is true in (`only`). Everyone else gets the general claim, and
/// a note left with nothing true to say for a country isn't shown to it.
///
/// Each point is written up to three ways, and `note(for:difficulty:voice:)`
/// picks the telling that is true for the player and pitched at their reading:
///
/// * `real` and `game` — the full picture, and what Real Life does about it;
/// * `simple` — the same point in a beginner's words (a point without one is
///   left out of the simple telling);
/// * `tutorial` — what the Simplified mode does instead, which is usually
///   *nothing*: it hires with certainty, so seats, fame and luck don't exist.
enum AdvisorRealWorld {

    /// One real-world point, with what the game does about it.
    struct Point: Equatable {
        let real: String
        /// What Real Life does about it.
        let game: String?
        /// The point for a beginner or a young reader; nil leaves it out of the simple telling.
        var simple: String?
        /// What the Simplified tutorial does about it; nil says nothing.
        var tutorial: String?
        /// The countries this is true in; nil means everywhere.
        var only: Set<Country>?
        /// A sentence added to `real` for one country — the local figure behind
        /// a general claim ("In the US, about 73% of new CEOs are inside hires").
        var tail: [Country: String]
        /// The same for the simple telling, in a beginner's words.
        var simpleTail: [Country: String]

        init(real: String, game: String?, simple: String? = nil, tutorial: String? = nil,
             only: Set<Country>? = nil, tail: [Country: String] = [:], simpleTail: [Country: String] = [:]) {
            self.real = real
            self.game = game
            self.simple = simple
            self.tutorial = tutorial
            self.only = only
            self.tail = tail
            self.simpleTail = simpleTail
        }
    }

    struct Note: Equatable {
        let title: String
        let points: [Point]

        /// This note as it is told to one player: the points in the reader's
        /// words, each beside what *their* mode does about it. A Simplified
        /// player never hears about seats, fame or luck the game doesn't have.
        func told(in difficulty: Difficulty, voice: AdvisorVoice, country: Country = .default) -> Note {
            let told = points.compactMap { point -> Point? in
                if let only = point.only, !only.contains(country) { return nil }
                var real: String
                switch voice {
                case .standard:
                    real = point.real
                    if let tail = point.tail[country] { real += " " + tail }
                case .simple:
                    guard let simple = point.simple else { return nil }
                    real = simple
                    if let tail = point.simpleTail[country] { real += " " + tail }
                }
                return Point(real: real, game: difficulty.isSimplified ? point.tutorial : point.game)
            }
            return Note(title: title, points: told)
        }

        /// One card per point, the game's half marked with 🎮.
        var cards: [AdvisorCard] {
            points.map { point in
                AdvisorCard(icon: "🌍", detail: point.real + (point.game.map { "\n🎮 In the game: \($0)" } ?? ""))
            }
        }

        /// What a model may quote about it, one fact per line.
        var facts: [String] {
            points.flatMap { point in
                ["In the real world: \(point.real)"] + (point.game.map { ["In the game: \($0)"] } ?? [])
            }
        }
    }

    /// The note for `job`'s role, told to this player — if it's one of the
    /// hard-to-reach careers.
    static func note(for job: Job, player: Player) -> Note? {
        note(for: job, difficulty: player.difficulty, voice: AdvisorVoice(player), country: player.country)
    }

    static func note(for job: Job, difficulty: Difficulty, voice: AdvisorVoice,
                     country: Country = .default) -> Note? {
        guard let told = fullNote(for: job, in: country)?.told(in: difficulty, voice: voice, country: country),
              !told.points.isEmpty else { return nil }
        return told
    }

    /// Countries where university costs little, so "often on loans" isn't the
    /// story: public universities there charge a few hundred to a couple of
    /// thousand a year (see `Country.annualTuition`).
    private static let lowTuition: Set<Country> = [.germany, .france, .italy]
    private static let highTuition = Set(Country.allCases).subtracting(lowTuition)

    /// Countries whose judges are chosen from experienced lawyers (common law).
    /// In the civil-law countries a judge is a career of its own, entered straight
    /// after the state exam, so the note has nothing true to say there.
    private static let commonLaw: Set<Country> = [.unitedStates, .canada, .unitedKingdom]

    /// Every telling of the role's note, before it is told to anyone.
    private static func fullNote(for job: Job, in country: Country) -> Note? {
        switch job.baseTitle {
        case "Chief Executive Officer": return ceo(job, country)
        case "Chief Technology Officer": return cto(job)
        case "Chief Medical Officer": return chiefMedicalOfficer(job)
        case "Marketing Director", "Sales Director": return director(job)
        case "Managing Partner": return managingPartner(job)
        case "Physician", "Surgeon", "Anesthesiologist", "Dentist", "Veterinarian", "Pharmacist": return doctor(job, country)
        case "Judge": return judge(job)
        case "Research Scientist": return scientist(job)
        case "Airline Pilot": return pilot(job)
        case "Player": return athlete(job)
        case "Investment Banker", "Management Consultant": return eliteFirm(job)
        case "TV Presenter": return presenter(job)
        default: return nil
        }
    }

    // MARK: - What Simplified says instead

    /// Simplified hires with certainty once the basics are met — the degree, the
    /// years — so where Real Life has a seat and odds, the tutorial has a short list.
    private static func basics(_ job: Job) -> String {
        var asks: [String] = []
        if job.requirements.education.minEQF >= 4 { asks.append(AdvisorCoach.educationPhrase(for: job)) }
        let years = job.requirements.minYearsExperience
        if years > 0 { asks.append("\(years) years of work in \(job.experienceLadder ?? job.category.rawValue)") }
        return asks.isEmpty
            ? "In Simplified mode there's no luck to it: the job is yours."
            : "In Simplified mode there's no luck to it: get \(AdvisorCoach.list(asks)), and the job is yours."
    }

    /// Simplified has no Ventures sheet, so the founder route isn't there.
    private static let noCompanies = "There are no companies to start in Simplified mode — you climb by working."

    // MARK: - The notes

    private static func ceo(_ job: Job, _ country: Country) -> Note {
        let wanted = job.requirements.minYearsExperience
        let door = job.minimumQualifyingYears(simplified: false)
        return Note(title: "Becoming a CEO", points: [
            Point(real: "There are only a few hundred CEO jobs at the biggest companies, and a board's search can run for a year.",
                  game: "That's the seat. Only \(pct(GameConstants.cSuiteSeatChance)) of otherwise-ideal applicants get a C-suite job in any year.",
                  simple: "A CEO is the boss of a whole company. There are only a few hundred CEO jobs at the biggest companies, so many good people never get one.",
                  tutorial: basics(job),
                  tail: [.unitedStates: "In the US, the 1,500 largest public companies name roughly 170 new CEOs a year."]),
            Point(real: "Most new CEOs come from inside the company. They typically spent years running a division with its own profit and loss, or served as COO or CFO, while the board watched.",
                  game: "Years open the door: \(wanted) years in Business, and nothing under about \(door). Any Business job counts, and so do years running your own company.",
                  simple: "Most new CEOs already worked at the company for years, running a big part of it while the bosses watched.",
                  tail: [.unitedStates: "In the US, about 73% of new CEOs are inside hires."]),
            Point(real: "Boards hire results — growth delivered, turnarounds, deals — and the ability to speak for the company to investors, staff and the press. A public reputation and friends on other boards help, but only on top of a record.",
                  game: "Business fame and your network add to your chance (up to +\(pct(Player.fameHireCap(topPosition: true))) and +\(pct(Player.networkHireCap))) — until your application is already at the cap, when more changes nothing."),
            Point(real: "The other door is to build a company yourself. A founder doesn't wait to be picked, though most start-ups fail. Boards like people who have run a business, even one that failed — yet most new big-company CEOs had never been a CEO before.",
                  game: "That's the founder track record: it lifts the seat from \(pct(GameConstants.cSuiteSeatChance)) to at most \(pct(GameConstants.cSuiteSeatChance + GameConstants.executiveTrackRecordCap)). It eases the odds; it never decides them.",
                  simple: "Some people start their own company instead. Most new companies fail, but people who tried still learn a lot — and bosses notice.",
                  tutorial: noCompanies,
                  tail: [.unitedStates: "In the US, about 84% of new big-company CEOs had not."]),
            Point(real: "The degree matters less than what you ran. Business and engineering degrees are common and a famous school opens doors early on, but nobody is hired as CEO for their school.",
                  game: "\(country.tierName(.elite)) adds +\(pct(Job.prestigeBonus(forPrestige: 3))) to your chance, \(country.tierName(.state)) +\(pct(Job.prestigeBonus(forPrestige: 2))) — small next to the seat."),
            Point(real: "Luck and timing are real: an industry's cycle, a predecessor leaving, a company in trouble that wants an outsider. Excellent candidates wait years, or never get the call.",
                  game: "Each year's job market multiplies your chance: a slump hurts, a boom helps."),
        ])
    }

    private static func cto(_ job: Job) -> Note {
        Note(title: "Becoming a CTO", points: [
            Point(real: "At a large company the CTO is usually a senior engineering leader — a VP or head of engineering who has run big teams and budgets. At a start-up it is often a co-founder.",
                  game: "It asks \(job.requirements.minYearsExperience) years in Technology, and only \(pct(GameConstants.cSuiteSeatChance)) of ideal applicants get a C-suite seat each year.",
                  simple: "A CTO is the boss of all the technology at a company. At a big company it is usually an engineer who grew into a leader; at a new company it is often one of the founders.",
                  tutorial: basics(job)),
            Point(real: "The job is half technology and half leadership: hiring, budgets, and explaining technical bets to the CEO and the board.",
                  game: "Leader and Visionary are the skills it weighs most."),
            Point(real: "Founding a technology company is the common shortcut: build the product, prove it works, and the title follows.",
                  game: "A founder track record eases the seat from \(pct(GameConstants.cSuiteSeatChance)) to at most \(pct(GameConstants.cSuiteSeatChance + GameConstants.executiveTrackRecordCap)).",
                  simple: "Starting your own tech company is a common shortcut: build something that works, and the title follows.",
                  tutorial: noCompanies),
        ])
    }

    private static func chiefMedicalOfficer(_ job: Job) -> Note {
        Note(title: "Becoming a Chief Medical Officer", points: [
            Point(real: "CMOs are senior physicians who took on management: department chief, then medical director, then the hospital system's top doctor-executive. Medicine comes first — years of medical school, hospital training and practice.",
                  game: "You need the medical licence and board certification, \(job.requirements.minYearsExperience) years in Health, and a \(pct(GameConstants.cSuiteSeatChance)) seat.",
                  simple: "A Chief Medical Officer is a doctor who became the boss of a hospital's doctors. Medicine comes first: many years of school and work as a doctor.",
                  tutorial: basics(job)),
            Point(real: "Many add management training, such as an MBA or a master's in health administration, because the job is budgets, quality and people rather than patients.",
                  game: "Leader and Communication are the skills it weighs most."),
        ])
    }

    private static func director(_ job: Job) -> Note {
        Note(title: "Becoming a director", points: [
            Point(real: "Directors are promoted from senior managers who ran a team and hit its numbers: a sales director has carried a quota, a marketing director has launched campaigns that worked.",
                  game: "It asks \(job.requirements.minYearsExperience) years in Business, and \(pct(GameConstants.directorSeatChance)) of ideal applicants get the seat each year.",
                  simple: "A director leads a team. Companies pick someone who already led a team well — for example, someone who reached their sales goals or ran ad campaigns that worked.",
                  tutorial: basics(job)),
            Point(real: "A senior sponsor who speaks for you in the room matters as much as the results — most promotions are decided by people, not by rules.",
                  game: "Your network and fame in Business add to your chance.",
                  simple: "It also helps to have a senior person who speaks up for you. Many promotions are decided by people, not by rules."),
            Point(real: "A company has several director seats rather than one, so it's competitive rather than a lottery.",
                  game: "That's why the seat is \(pct(GameConstants.directorSeatChance)), not \(pct(GameConstants.cSuiteSeatChance))."),
        ])
    }

    private static func managingPartner(_ job: Job) -> Note {
        Note(title: "Becoming a managing partner", points: [
            Point(real: "Law firms are “up or out”: after roughly seven to ten years as associates, most lawyers leave and only a minority are made partner.",
                  game: "You need a law doctorate, the bar and \(job.requirements.minYearsExperience) years — and only \(pct(GameConstants.directorSeatChance)) of ideal applicants get a partner seat.",
                  simple: "In a law firm, most young lawyers have to leave after about seven to ten years, and only a few are made partners.",
                  tutorial: basics(job)),
            Point(real: "Partners are judged on the clients they bring in — “rainmaking” — as much as on the quality of their work.",
                  game: "Persuader and Communication are among the skills it weighs most.",
                  simple: "Partners are picked for the clients they bring in as much as for their work."),
            Point(real: "A managing partner is chosen by the other partners: standing among your peers counts for more than any interview.",
                  game: "Few people want the job and fewer get it: the game's demand for it is only \(pct(job.hiringDemand))."),
        ])
    }

    private static func doctor(_ job: Job, _ country: Country) -> Note {
        let fee = country.money(country.annualTuition(tier: .state, level: .Bachelor, profile: .health))
        return Note(title: "Becoming a health specialist", points: [
            Point(real: "The road is long and every step is selective: a bachelor's degree, then a professional or doctoral programme that admits well under half of its applicants, then — for doctors — three to seven years of supervised hospital training before you practise alone.",
                  game: "Each step is a gate: the degree, then the licence, then years of experience.",
                  simple: "Becoming a doctor takes many years: a bachelor's degree, then medical school, then years of training in a hospital. Each step takes only some of the people who apply.",
                  tutorial: "In Simplified mode you still need the right school and years of work — but there's no licence to earn and no school bill."),
            Point(real: "Grades and entrance results decide admission — in some countries volunteering or research experience and interviews too — a record built over years, not one good year.",
                  game: "Your school grades, skills and awards set your chance of admission.",
                  simple: "Schools look at your grades, your skills and your prizes over many years, not just one good year.",
                  tutorial: "Your grades, skills and prizes decide if a school takes you — in Simplified mode too."),
            Point(real: "Competitive specialties such as surgery and anaesthesia are a second competition: training places go to the top-ranked candidates.",
                  game: "These jobs ask for more of skills like Fixer, Detective and Zen than most."),
            Point(real: "The cost is high, too: years of tuition, often on loans, before a first full salary.",
                  game: "The game charges tuition and you may owe a student loan — then the pay is among the highest.",
                  simple: "It costs a lot, too: many people borrow money to pay for school.",
                  tutorial: "Simplified mode has no school bills, so nobody has to borrow.",
                  only: highTuition),
            Point(real: "Study itself costs little here — public universities charge only modest fees — but the long road means years of study before a first full salary.",
                  game: "The game charges only about \(fee) a year at a public university, so few students borrow — then the pay is among the highest.",
                  simple: "School costs little here, but it takes many years before the first full salary.",
                  tutorial: "Simplified mode has no school bills, so nobody has to borrow.",
                  only: lowTuition),
        ])
    }

    private static func judge(_ job: Job) -> Note {
        Note(title: "Becoming a judge", points: [
            Point(real: "Judges are appointed or elected, usually after ten to twenty years as lawyers or prosecutors. There are few openings, and they rarely come up.",
                  game: "Very few jobs open: the game's demand for judges is \(pct(job.hiringDemand)) of a normal job's.",
                  simple: "Judges are chosen after ten to twenty years as lawyers. There are very few jobs, and they open up rarely.",
                  tutorial: basics(job),
                  only: commonLaw),
            Point(real: "Reputation in the legal community — and often politics — decides who is chosen.",
                  game: "You need a law doctorate, the bar and years practising.",
                  only: commonLaw),
        ])
    }

    private static func scientist(_ job: Job) -> Note {
        Note(title: "Becoming a research scientist", points: [
            Point(real: "A scientist needs a PhD — three to seven years of research — often followed by one or more short postdoctoral posts. There are far fewer permanent research jobs than PhD graduates, so many move to industry.",
                  game: "A doctorate is required, and the ladder climbs one rung at a time.",
                  simple: "A scientist usually needs a PhD, which is three to seven years of research. There are fewer research jobs than people with PhDs, so many scientists work in companies instead.",
                  tutorial: basics(job)),
            Point(real: "Careers are made by publications and by winning research funding: a record of results, and other scientists who cite your work.",
                  game: "Your fame in Science and your network in it add to your chance."),
        ])
    }

    private static func pilot(_ job: Job) -> Note {
        let years = (AdvisorCoach.family(job.baseTitle)?.rungs ?? []).map { "\($0.requirements.minYearsExperience)" }
        return Note(title: "Becoming an airline pilot", points: [
            Point(real: "An airline pilot needs an airline transport licence, which takes years of building flying hours. Most pilots build hours as instructors or on small aircraft, then join a regional airline before a major one.",
                  game: "Flight school and its licence are the gate; years of experience open each rung.",
                  simple: "Airline pilots need a special licence and lots of hours of flying. Most start by teaching flying or flying small planes, then join a bigger airline.",
                  tutorial: "Simplified mode skips the licence: years of work open each step up (\(AdvisorCoach.list(years))).",
                  tail: [.unitedStates: "In the US that normally means 1,500 flight hours (fewer through some approved flight schools)."],
                  simpleTail: [.unitedStates: "In the US that is about 1,500 hours."]),
            Point(real: "At airlines, seniority decides who flies the bigger aircraft and who becomes a captain — years of service count for more than talent.",
                  game: "Each rung asks for more years (\(AdvisorCoach.list(years))) and pays far more.",
                  simple: "The longer a pilot has worked for an airline, the bigger the plane they get to fly.",
                  tutorial: "Each step up asks for more years of work (\(AdvisorCoach.list(years))) and pays a lot more."),
        ])
    }

    private static func athlete(_ job: Job) -> Note {
        Note(title: "Becoming a professional athlete", points: [
            Point(real: "Very few young players turn professional, and most of those were noticed as teenagers.",
                  game: "The Junior Champion title opens the door, and even then only \(pct(GameConstants.proRosterChance)) of title-holders make a roster.",
                  simple: "Very few young players become professionals, and most were noticed as teenagers.",
                  tutorial: "The Junior Champion title opens the door — and in Simplified mode, once you have it, a team spot is yours.",
                  tail: [.unitedStates: "In US college sport roughly 1–5% are drafted."],
                  simpleTail: [.unitedStates: "In US college sport only about 1 to 5 in every 100 get picked."]),
            Point(real: "Careers are short and an injury can end one without warning, so most athletes need a second career.",
                  game: "Careers end early in the game too.",
                  simple: "A sports career can end suddenly with an injury, so most athletes need a second job.",
                  tutorial: "Sports careers end early in the game too."),
        ])
    }

    private static func eliteFirm(_ job: Job) -> Note {
        Note(title: "Getting into an elite firm", points: [
            Point(real: "These firms recruit mostly from a short list of universities, through campus events and internships. At the biggest banks, well under 1% of applicants for analyst jobs are hired.",
                  game: "A top-tier university adds +\(pct(Job.prestigeBonus(forPrestige: 3))) to your chance, and demand for the job is only \(pct(job.hiringDemand)) of a normal one's.",
                  simple: "Big banks and consulting firms mostly hire from a short list of universities, and fewer than 1 in 100 people who apply for a first job there get it.",
                  tutorial: basics(job)),
            Point(real: "Analysts are hired in yearly classes and expected to work very long hours. Many leave after a couple of years for other industries; the rest face “up or out” promotions.",
                  game: "Each rung above the entry level is harder to be hired into from outside.",
                  simple: "New analysts work very long hours, and many leave after a couple of years."),
        ])
    }

    private static func presenter(_ job: Job) -> Note {
        Note(title: "Becoming a TV presenter", points: [
            Point(real: "Presenters are found through auditions, showreels and being seen — small stations first, then national. Reliability on live TV and a following of viewers count for more than looks.",
                  game: "Entertainment fame is what employers weigh (up to +\(pct(Player.fameHireCap(topPosition: false)))): projects and events build it.",
                  simple: "TV presenters start with auditions and video clips of themselves, at small stations first. Staying calm on live TV and having viewers who like you matter more than looks.",
                  tutorial: basics(job)),
        ])
    }

    private static func pct(_ share: Double) -> String { AdvisorPathway.percent(share) }
}
