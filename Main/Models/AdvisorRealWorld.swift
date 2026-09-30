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
enum AdvisorRealWorld {

    /// One real-world point, with what the game does about it.
    struct Point: Equatable {
        let real: String
        let game: String?
    }

    struct Note: Equatable {
        let title: String
        let points: [Point]

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

    /// The note for `job`'s role, if it's one of the hard-to-reach careers.
    static func note(for job: Job) -> Note? {
        switch job.baseTitle {
        case "Chief Executive Officer": return ceo(job)
        case "Chief Technology Officer": return cto(job)
        case "Chief Medical Officer": return chiefMedicalOfficer(job)
        case "Marketing Director", "Sales Director": return director(job)
        case "Managing Partner": return managingPartner(job)
        case "Physician", "Surgeon", "Anesthesiologist", "Dentist", "Veterinarian", "Pharmacist": return doctor(job)
        case "Judge": return judge(job)
        case "Research Scientist": return scientist(job)
        case "Airline Pilot": return pilot(job)
        case "Player": return athlete(job)
        case "Investment Banker", "Management Consultant": return eliteFirm(job)
        case "TV Presenter": return presenter(job)
        default: return nil
        }
    }

    // MARK: - The notes

    private static func ceo(_ job: Job) -> Note {
        let wanted = job.requirements.minYearsExperience
        let door = job.minimumQualifyingYears(simplified: false)
        return Note(title: "Becoming a CEO", points: [
            Point(real: "There are only a few hundred CEO jobs at the biggest companies: the 1,500 largest US public companies name roughly 170 new CEOs a year, and a board's search can run for a year.",
                  game: "That's the seat. Only \(pct(GameConstants.cSuiteSeatChance)) of otherwise-ideal applicants get a C-suite job in any year."),
            Point(real: "Most new CEOs come from inside the company — about 73% of them. They typically spent years running a division with its own profit and loss, or served as COO or CFO, while the board watched.",
                  game: "Years open the door: \(wanted) years in Business, and nothing under about \(door). Any Business job counts, and so do years running your own company."),
            Point(real: "Boards hire results — growth delivered, turnarounds, deals — and the ability to speak for the company to investors, staff and the press. A public reputation and friends on other boards help, but only on top of a record.",
                  game: "Business fame and your network add to your chance (up to +\(pct(Player.fameHireCap(topPosition: true))) and +\(pct(Player.networkHireCap))) — until your application is already at the cap, when more changes nothing."),
            Point(real: "The other door is to build a company yourself. A founder doesn't wait to be picked, though most start-ups fail. Boards like people who have run a business, even one that failed — yet about 84% of new big-company CEOs had never been a CEO before.",
                  game: "That's the founder track record: it lifts the seat from \(pct(GameConstants.cSuiteSeatChance)) to at most \(pct(GameConstants.cSuiteSeatChance + GameConstants.executiveTrackRecordCap)). It eases the odds; it never decides them."),
            Point(real: "The degree matters less than what you ran. Business and engineering degrees are common and a famous school opens doors early on, but nobody is hired as CEO for their school.",
                  game: "An elite university adds +\(pct(Job.prestigeBonus(forPrestige: 3))) to your chance, a state one +\(pct(Job.prestigeBonus(forPrestige: 2))) — small next to the seat."),
            Point(real: "Luck and timing are real: an industry's cycle, a predecessor leaving, a company in trouble that wants an outsider. Excellent candidates wait years, or never get the call.",
                  game: "Each year's job market multiplies your chance: a slump hurts, a boom helps."),
        ])
    }

    private static func cto(_ job: Job) -> Note {
        Note(title: "Becoming a CTO", points: [
            Point(real: "At a large company the CTO is usually a senior engineering leader — a VP or head of engineering who has run big teams and budgets. At a start-up it is often a co-founder.",
                  game: "It asks \(job.requirements.minYearsExperience) years in Technology, and only \(pct(GameConstants.cSuiteSeatChance)) of ideal applicants get a C-suite seat each year."),
            Point(real: "The job is half technology and half leadership: hiring, budgets, and explaining technical bets to the CEO and the board.",
                  game: "Leader and Visionary are the skills it weighs most."),
            Point(real: "Founding a technology company is the common shortcut: build the product, prove it works, and the title follows.",
                  game: "A founder track record eases the seat from \(pct(GameConstants.cSuiteSeatChance)) to at most \(pct(GameConstants.cSuiteSeatChance + GameConstants.executiveTrackRecordCap))."),
        ])
    }

    private static func chiefMedicalOfficer(_ job: Job) -> Note {
        Note(title: "Becoming a Chief Medical Officer", points: [
            Point(real: "CMOs are senior physicians who took on management: department chief, then medical director, then the hospital system's top doctor-executive. Medicine comes first — years of medical school, residency and practice.",
                  game: "You need the medical licence and board certification, \(job.requirements.minYearsExperience) years in Health, and a \(pct(GameConstants.cSuiteSeatChance)) seat."),
            Point(real: "Many add management training, such as an MBA or a master's in health administration, because the job is budgets, quality and people rather than patients.",
                  game: "Leader and Communication are the skills it weighs most."),
        ])
    }

    private static func director(_ job: Job) -> Note {
        Note(title: "Becoming a director", points: [
            Point(real: "Directors are promoted from senior managers who ran a team and hit its numbers: a sales director has carried a quota, a marketing director has launched campaigns that worked.",
                  game: "It asks \(job.requirements.minYearsExperience) years in Business, and \(pct(GameConstants.directorSeatChance)) of ideal applicants get the seat each year."),
            Point(real: "A senior sponsor who speaks for you in the room matters as much as the results — most promotions are decided by people, not by rules.",
                  game: "Your network and fame in Business add to your chance."),
            Point(real: "A company has several director seats rather than one, so it's competitive rather than a lottery.",
                  game: "That's why the seat is \(pct(GameConstants.directorSeatChance)), not \(pct(GameConstants.cSuiteSeatChance))."),
        ])
    }

    private static func managingPartner(_ job: Job) -> Note {
        Note(title: "Becoming a managing partner", points: [
            Point(real: "Law firms are “up or out”: after roughly seven to ten years as associates, most lawyers leave and only a minority are made partner.",
                  game: "You need a law doctorate, the bar and \(job.requirements.minYearsExperience) years — and only \(pct(GameConstants.directorSeatChance)) of ideal applicants get a partner seat."),
            Point(real: "Partners are judged on the clients they bring in — “rainmaking” — as much as on the quality of their work.",
                  game: "Persuader and Communication are among the skills it weighs most."),
            Point(real: "A managing partner is chosen by the other partners: standing among your peers counts for more than any interview.",
                  game: "Few people want the job and fewer get it: the game's demand for it is only \(pct(job.hiringDemand))."),
        ])
    }

    private static func doctor(_ job: Job) -> Note {
        Note(title: "Becoming a health specialist", points: [
            Point(real: "The road is long and every step is selective: a bachelor's degree, then a professional or doctoral programme that admits well under half of its applicants, then — for doctors — a residency of three to seven years before you practise alone.",
                  game: "Each step is a gate: the degree, then the licence, then years of experience."),
            Point(real: "Grades, entrance-exam scores, volunteering or research experience and interviews decide admission — a record built over years, not one good year.",
                  game: "Your school grades, skills and awards set your chance of admission."),
            Point(real: "Competitive specialties such as surgery and anaesthesia are a second competition: residency places go to the top-ranked candidates.",
                  game: "These jobs ask for more of skills like Fixer, Detective and Zen than most."),
            Point(real: "The cost is high, too: years of tuition, often on loans, before a first full salary.",
                  game: "The game charges tuition and you may owe a student loan — then the pay is among the highest."),
        ])
    }

    private static func judge(_ job: Job) -> Note {
        Note(title: "Becoming a judge", points: [
            Point(real: "Judges are appointed or elected, usually after ten to twenty years as lawyers or prosecutors. There are few openings, and they rarely come up.",
                  game: "Very few jobs open: the game's demand for judges is \(pct(job.hiringDemand)) of a normal job's."),
            Point(real: "Reputation in the legal community — and often politics — decides who is chosen.",
                  game: "You need a law doctorate, the bar and years practising."),
        ])
    }

    private static func scientist(_ job: Job) -> Note {
        Note(title: "Becoming a research scientist", points: [
            Point(real: "A scientist needs a PhD — five to seven years of research — often followed by one or more short postdoctoral posts. There are far fewer permanent research jobs than PhD graduates, so many move to industry.",
                  game: "A doctorate is required, and the ladder climbs one rung at a time."),
            Point(real: "Careers are made by publications and by winning research funding: a record of results, and other scientists who cite your work.",
                  game: "Your fame in Science and your network in it add to your chance."),
        ])
    }

    private static func pilot(_ job: Job) -> Note {
        let years = (AdvisorCoach.family(job.baseTitle)?.rungs ?? []).map { "\($0.requirements.minYearsExperience)" }
        return Note(title: "Becoming an airline pilot", points: [
            Point(real: "In the US an airline pilot needs an Airline Transport Pilot licence, which normally takes 1,500 flight hours (fewer through some approved flight schools). Most pilots build hours as instructors or on small aircraft, then join a regional airline before a major one.",
                  game: "Flight school and its licence are the gate; years of experience open each rung."),
            Point(real: "At airlines, seniority decides who flies the bigger aircraft and who becomes a captain — years of service count for more than talent.",
                  game: "Each rung asks for more years (\(AdvisorCoach.list(years))) and pays far more."),
        ])
    }

    private static func athlete(_ job: Job) -> Note {
        Note(title: "Becoming a professional athlete", points: [
            Point(real: "Very few young players turn professional — in US college sport roughly 1–5% are drafted — and most of those were noticed as teenagers.",
                  game: "The Junior Champion title opens the door, and even then only \(pct(GameConstants.proRosterChance)) of title-holders make a roster."),
            Point(real: "Careers are short and an injury can end one without warning, so most athletes need a second career.",
                  game: "Careers end early in the game too."),
        ])
    }

    private static func eliteFirm(_ job: Job) -> Note {
        Note(title: "Getting into an elite firm", points: [
            Point(real: "These firms recruit mostly from a short list of universities, through campus events and internships. At the biggest banks, well under 1% of applicants for analyst jobs are hired.",
                  game: "An elite university adds +\(pct(Job.prestigeBonus(forPrestige: 3))) to your chance, and demand for the job is only \(pct(job.hiringDemand)) of a normal one's."),
            Point(real: "Analysts are hired in yearly classes and expected to work very long hours. Many leave after a couple of years for other industries; the rest face “up or out” promotions.",
                  game: "Each rung above the entry level is harder to be hired into from outside."),
        ])
    }

    private static func presenter(_ job: Job) -> Note {
        Note(title: "Becoming a TV presenter", points: [
            Point(real: "Presenters are found through auditions, showreels and being seen — small stations first, then national. Reliability on live TV and a following of viewers count for more than looks.",
                  game: "Entertainment fame is what employers weigh (up to +\(pct(Player.fameHireCap(topPosition: false)))): projects and events build it."),
        ])
    }

    private static func pct(_ share: Double) -> String { AdvisorPathway.percent(share) }
}
