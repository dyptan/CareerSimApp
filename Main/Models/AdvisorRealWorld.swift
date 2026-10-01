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
                    if let tail = point.tail[country] { real = AdvisorCoach.sentences([real, tail]) }
                case .simple:
                    guard let simple = point.simple else { return nil }
                    real = simple
                    if let tail = point.simpleTail[country] { real = AdvisorCoach.sentences([real, tail]) }
                }
                return Point(real: real, game: difficulty.isSimplified ? point.tutorial : point.game)
            }
            return Note(title: title, points: told)
        }

        /// One card per point, the game's half marked with 🎮.
        var cards: [AdvisorCard] {
            points.map { point in
                AdvisorCard(icon: "🌍", detail: point.real + (point.game.map { "\n" + L("🎮 In the game: \($0)") } ?? ""))
            }
        }

        /// What a model may quote about it, one fact per line. Written for the model, which is told
        /// which language to answer in, so the two labels stay English.
        var facts: [String] {
            points.flatMap { point in
                ["In the real world: \(point.real)"] + (point.game.map { ["In the game: \($0)"] } ?? []) // i18n:ignore model-facing fact
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
        case "Marketing Director", "Sales Director": return director(job) // i18n:ignore job ids
        case "Managing Partner": return managingPartner(job)
        case "Physician", "Surgeon", "Anesthesiologist", "Dentist", "Veterinarian", "Pharmacist": return doctor(job, country) // i18n:ignore job ids
        case "Judge": return judge(job)
        case "Research Scientist": return scientist(job)
        case "Airline Pilot": return pilot(job)
        case "Player": return athlete(job)
        case "Investment Banker", "Management Consultant": return eliteFirm(job) // i18n:ignore job ids
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
        if years > 0 {
            asks.append(job.displayExperienceLadder.map {
                String(localized: "\(years) years of work as \($0)", comment: "One requirement in a list, e.g. '5 years of work as Teacher'. The first argument is a count; the second a career ladder (a role)")
            } ?? String(localized: "\(years) years of work in \(job.category.displayName)", comment: "One requirement in a list, e.g. '5 years of work in Business'. The first argument is a count; the second a job field"))
        }
        return asks.isEmpty
            ? String(localized: "In Simplified mode there's no luck to it: the job is yours.", comment: "Advisor real-world note, tutorial (Simplified mode) telling: this job has no requirements, so it is certain")
            : String(localized: "In Simplified mode there's no luck to it: get \(AdvisorCoach.list(asks)), and the job is yours.", comment: "Advisor real-world note, tutorial (Simplified mode) telling. The argument is a list of requirements, e.g. 'a bachelor's degree and 5 years of work in Business'")
    }

    /// Simplified has no Ventures sheet, so the founder route isn't there.
    private static var noCompanies: String {
        String(localized: "There are no companies to start in Simplified mode — you climb by working.", comment: "Advisor real-world note, tutorial (Simplified mode): founding a company is not possible there")
    }

    /// The label of a soft skill, for a note that names the skills a role weighs most.
    private static func skill(_ keyPath: WritableKeyPath<SoftSkills, Int>) -> String {
        SoftSkills.label(forKeyPath: keyPath) ?? ""
    }

    // MARK: - The notes

    private static func ceo(_ job: Job, _ country: Country) -> Note {
        let wanted = job.requirements.minYearsExperience
        let door = String(job.minimumQualifyingYears(simplified: false))
        let seat = pct(GameConstants.cSuiteSeatChance)
        let business = JobCategory.business.displayName
        return Note(title: String(localized: "Becoming a CEO", comment: "Title of an advisor real-world note about becoming a chief executive"), points: [
            Point(real: String(localized: "There are only a few hundred CEO jobs at the biggest companies, and a board's search can run for a year.", comment: "CEO note, point 1 (scarcity of CEO jobs): the real-world claim, for adults. General claim"),
                  game: String(localized: "That's the seat. Only \(seat) of otherwise-ideal applicants get a C-suite job in any year.", comment: "CEO note, point 1: what the game does about it. The argument is a percentage"),
                  simple: String(localized: "A CEO is the boss of a whole company. There are only a few hundred CEO jobs at the biggest companies, so many good people never get one.", comment: "CEO note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: basics(job),
                  tail: [.unitedStates: String(localized: "In the US, the 1,500 largest public companies name roughly 170 new CEOs a year.", comment: "CEO note, point 1: US-only statistic, shown to US players only")]),
            Point(real: String(localized: "Most new CEOs come from inside the company. They typically spent years running a division with its own profit and loss, or served as COO or CFO, while the board watched.", comment: "CEO note, point 2 (CEOs are inside hires): the real-world claim, for adults. General claim"),
                  game: String(localized: "Years open the door: \(wanted) years in \(business), and nothing under about \(door). Any \(business) job counts, and so do years running your own company.", comment: "CEO note, point 2: what the game does about it. Arguments: required years, the job field Business (twice), the minimum years that still count"),
                  simple: String(localized: "Most new CEOs already worked at the company for years, running a big part of it while the bosses watched.", comment: "CEO note, point 2: the same fact in a beginner's or child's words"),
                  tail: [.unitedStates: String(localized: "In the US, about \(usShare(0.73)) of new CEOs are inside hires.", comment: "CEO note, point 2: US-only statistic, shown to US players only. The argument is a percentage")]),
            Point(real: String(localized: "Boards hire results — growth delivered, turnarounds, deals — and the ability to speak for the company to investors, staff and the press. A public reputation and friends on other boards help, but only on top of a record.", comment: "CEO note, point 3 (what boards hire): the real-world claim, for adults. General claim"),
                  game: String(localized: "\(business) fame and your network add to your chance (up to +\(pct(Player.fameHireCap(topPosition: true))) and +\(pct(Player.networkHireCap))) — until your application is already at the cap, when more changes nothing.", comment: "CEO note, point 3: what the game does about it. Arguments: the fame field Business, then two percentages")),
            Point(real: String(localized: "The other door is to build a company yourself. A founder doesn't wait to be picked, though most start-ups fail. Boards like people who have run a business, even one that failed — yet most new big-company CEOs had never been a CEO before.", comment: "CEO note, point 4 (founders): the real-world claim, for adults. General claim"),
                  game: String(localized: "That's the founder track record: it lifts the seat from \(seat) to at most \(pct(GameConstants.cSuiteSeatChance + GameConstants.executiveTrackRecordCap)). It eases the odds; it never decides them.", comment: "CEO note, point 4: what the game does about it. Arguments: two percentages"),
                  simple: String(localized: "Some people start their own company instead. Most new companies fail, but people who tried still learn a lot — and bosses notice.", comment: "CEO note, point 4: the same fact in a beginner's or child's words"),
                  tutorial: noCompanies,
                  tail: [.unitedStates: String(localized: "In the US, about \(usShare(0.84)) of new big-company CEOs had not.", comment: "CEO note, point 4: US-only statistic, shown to US players only. The argument is a percentage. 'Had not' refers to never having been a CEO before")]),
            Point(real: String(localized: "The degree matters less than what you ran. Business and engineering degrees are common and a famous school opens doors early on, but nobody is hired as CEO for their school.", comment: "CEO note, point 5 (the degree matters less): the real-world claim, for adults. General claim"),
                  game: String(localized: "\(country.tierName(.elite)) adds +\(pct(Job.prestigeBonus(forPrestige: 3))) to your chance, \(country.tierName(.state)) +\(pct(Job.prestigeBonus(forPrestige: 2))) — small next to the seat.", comment: "CEO note, point 5: what the game does about it. Arguments: the country's name for elite schools, a percentage, its name for mainstream schools, a percentage")),
            Point(real: String(localized: "Luck and timing are real: an industry's cycle, a predecessor leaving, a company in trouble that wants an outsider. Excellent candidates wait years, or never get the call.", comment: "CEO note, point 6 (luck and timing): the real-world claim, for adults. General claim"),
                  game: String(localized: "Each year's job market multiplies your chance: a slump hurts, a boom helps.", comment: "CEO note, point 6: what the game does about it")),
        ])
    }

    private static func cto(_ job: Job) -> Note {
        let seat = pct(GameConstants.cSuiteSeatChance)
        return Note(title: String(localized: "Becoming a CTO", comment: "Title of an advisor real-world note about becoming a chief technology officer"), points: [
            Point(real: String(localized: "At a large company the CTO is usually a senior engineering leader — a VP or head of engineering who has run big teams and budgets. At a start-up it is often a co-founder.", comment: "CTO note, point 1 (who becomes CTO): the real-world claim, for adults. General claim"),
                  game: String(localized: "It asks \(job.requirements.minYearsExperience) years in \(JobCategory.technology.displayName), and only \(seat) of ideal applicants get a C-suite seat each year.", comment: "CTO note, point 1: what the game does about it. Arguments: required years, the job field Technology, a percentage"),
                  simple: String(localized: "A CTO is the boss of all the technology at a company. At a big company it is usually an engineer who grew into a leader; at a new company it is often one of the founders.", comment: "CTO note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: basics(job)),
            Point(real: String(localized: "The job is half technology and half leadership: hiring, budgets, and explaining technical bets to the CEO and the board.", comment: "CTO note, point 2 (the job itself): the real-world claim, for adults. General claim"),
                  game: String(localized: "\(skill(\.leadershipAndInfluence)) and \(skill(\.visionaryThinkingAndAmbition)) are the skills it weighs most.", comment: "CTO note, point 2: what the game does about it. The arguments are the names of two of the game's skills")),
            Point(real: String(localized: "Founding a technology company is the common shortcut: build the product, prove it works, and the title follows.", comment: "CTO note, point 3 (founding a company): the real-world claim, for adults. General claim"),
                  game: String(localized: "A founder track record eases the seat from \(seat) to at most \(pct(GameConstants.cSuiteSeatChance + GameConstants.executiveTrackRecordCap)).", comment: "CTO note, point 3: what the game does about it. Arguments: two percentages"),
                  simple: String(localized: "Starting your own tech company is a common shortcut: build something that works, and the title follows.", comment: "CTO note, point 3: the same fact in a beginner's or child's words"),
                  tutorial: noCompanies),
        ])
    }

    private static func chiefMedicalOfficer(_ job: Job) -> Note {
        Note(title: String(localized: "Becoming a Chief Medical Officer", comment: "Title of an advisor real-world note about becoming a hospital's chief medical officer"), points: [
            Point(real: String(localized: "CMOs are senior physicians who took on management: department chief, then medical director, then the hospital system's top doctor-executive. Medicine comes first — years of medical school, hospital training and practice.", comment: "Chief Medical Officer note, point 1 (the path): the real-world claim, for adults. General claim"),
                  game: String(localized: "You need the medical licence and board certification, \(job.requirements.minYearsExperience) years in \(JobCategory.health.displayName), and a \(pct(GameConstants.cSuiteSeatChance)) seat.", comment: "Chief Medical Officer note, point 1: what the game does about it. Arguments: required years, the job field Health, the seat chance as a percentage"),
                  simple: String(localized: "A Chief Medical Officer is a doctor who became the boss of a hospital's doctors. Medicine comes first: many years of school and work as a doctor.", comment: "Chief Medical Officer note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: basics(job)),
            Point(real: String(localized: "Many add management training, such as an MBA or a master's in health administration, because the job is budgets, quality and people rather than patients.", comment: "Chief Medical Officer note, point 2 (management training): the real-world claim, for adults. General claim"),
                  game: String(localized: "\(skill(\.leadershipAndInfluence)) and \(skill(\.communicationAndNetworking)) are the skills it weighs most.", comment: "Chief Medical Officer note, point 2: what the game does about it. The arguments are the names of two of the game's skills")),
        ])
    }

    private static func director(_ job: Job) -> Note {
        let business = JobCategory.business.displayName
        let seat = pct(GameConstants.directorSeatChance)
        return Note(title: String(localized: "Becoming a director", comment: "Title of an advisor real-world note about becoming a marketing or sales director"), points: [
            Point(real: String(localized: "Directors are promoted from senior managers who ran a team and hit its numbers: a sales director has carried a quota, a marketing director has launched campaigns that worked.", comment: "Director note, point 1 (who is promoted): the real-world claim, for adults. General claim"),
                  game: String(localized: "It asks \(job.requirements.minYearsExperience) years in \(business), and \(seat) of ideal applicants get the seat each year.", comment: "Director note, point 1: what the game does about it. Arguments: required years, the job field Business, a percentage"),
                  simple: String(localized: "A director leads a team. Companies pick someone who already led a team well — for example, someone who reached their sales goals or ran ad campaigns that worked.", comment: "Director note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: basics(job)),
            Point(real: String(localized: "A senior sponsor who speaks for you in the room matters as much as the results — most promotions are decided by people, not by rules.", comment: "Director note, point 2 (sponsors): the real-world claim, for adults. General claim"),
                  game: String(localized: "Your network and fame in \(business) add to your chance.", comment: "Director note, point 2: what the game does about it. The argument is the job field Business"),
                  simple: String(localized: "It also helps to have a senior person who speaks up for you. Many promotions are decided by people, not by rules.", comment: "Director note, point 2: the same fact in a beginner's or child's words")),
            Point(real: String(localized: "A company has several director seats rather than one, so it's competitive rather than a lottery.", comment: "Director note, point 3 (several seats): the real-world claim, for adults. General claim"),
                  game: String(localized: "That's why the seat is \(seat), not \(pct(GameConstants.cSuiteSeatChance)).", comment: "Director note, point 3: what the game does about it. Arguments: the director seat chance, the C-suite seat chance, both percentages")),
        ])
    }

    private static func managingPartner(_ job: Job) -> Note {
        Note(title: String(localized: "Becoming a managing partner", comment: "Title of an advisor real-world note about becoming a law firm's managing partner"), points: [
            Point(real: String(localized: "Law firms are “up or out”: after roughly seven to ten years as associates, most lawyers leave and only a minority are made partner.", comment: "Managing partner note, point 1 (up or out): the real-world claim, for adults. General claim about law firms"),
                  game: String(localized: "You need a law doctorate, the bar and \(job.requirements.minYearsExperience) years — and only \(pct(GameConstants.directorSeatChance)) of ideal applicants get a partner seat.", comment: "Managing partner note, point 1: what the game does about it. Arguments: required years, a percentage"),
                  simple: String(localized: "In a law firm, most young lawyers have to leave after about seven to ten years, and only a few are made partners.", comment: "Managing partner note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: basics(job)),
            Point(real: String(localized: "Partners are judged on the clients they bring in — “rainmaking” — as much as on the quality of their work.", comment: "Managing partner note, point 2 (rainmaking): the real-world claim, for adults. General claim. 'Rainmaking' is the trade term for winning new clients"),
                  game: String(localized: "\(skill(\.persuasionAndNegotiation)) and \(skill(\.communicationAndNetworking)) are among the skills it weighs most.", comment: "Managing partner note, point 2: what the game does about it. The arguments are the names of two of the game's skills"),
                  simple: String(localized: "Partners are picked for the clients they bring in as much as for their work.", comment: "Managing partner note, point 2: the same fact in a beginner's or child's words")),
            Point(real: String(localized: "A managing partner is chosen by the other partners: standing among your peers counts for more than any interview.", comment: "Managing partner note, point 3 (chosen by peers): the real-world claim, for adults. General claim"),
                  game: String(localized: "Few people want the job and fewer get it: the game's demand for it is only \(pct(job.hiringDemand)).", comment: "Managing partner note, point 3: what the game does about it. The argument is a percentage")),
        ])
    }

    private static func doctor(_ job: Job, _ country: Country) -> Note {
        let fee = country.money(country.annualTuition(tier: .state, level: .Bachelor, profile: .health))
        return Note(title: String(localized: "Becoming a health specialist", comment: "Title of an advisor real-world note about becoming a doctor, dentist, vet or pharmacist"), points: [
            Point(real: String(localized: "The road is long and every step is selective: a bachelor's degree, then a professional or doctoral programme that admits well under half of its applicants, then — for doctors — three to seven years of supervised hospital training before you practise alone.", comment: "Health specialist note, point 1 (a long, selective road): the real-world claim, for adults. General claim"),
                  game: String(localized: "Each step is a gate: the degree, then the licence, then years of experience.", comment: "Health specialist note, point 1: what the game does about it"),
                  simple: String(localized: "Becoming a doctor takes many years: a bachelor's degree, then medical school, then years of training in a hospital. Each step takes only some of the people who apply.", comment: "Health specialist note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: String(localized: "In Simplified mode you still need the right school and years of work — but there's no licence to earn and no school bill.", comment: "Health specialist note, point 1: what the Simplified tutorial mode does instead")),
            Point(real: String(localized: "Grades and entrance results decide admission — in some countries volunteering or research experience and interviews too — a record built over years, not one good year.", comment: "Health specialist note, point 2 (admission): the real-world claim, for adults. General claim"),
                  game: String(localized: "Your school grades, skills and awards set your chance of admission.", comment: "Health specialist note, point 2: what the game does about it"),
                  simple: String(localized: "Schools look at your grades, your skills and your prizes over many years, not just one good year.", comment: "Health specialist note, point 2: the same fact in a beginner's or child's words"),
                  tutorial: String(localized: "Your grades, skills and prizes decide if a school takes you — in Simplified mode too.", comment: "Health specialist note, point 2: what the Simplified tutorial mode does instead")),
            Point(real: String(localized: "Competitive specialties such as surgery and anaesthesia are a second competition: training places go to the top-ranked candidates.", comment: "Health specialist note, point 3 (competitive specialties): the real-world claim, for adults. General claim"),
                  game: String(localized: "These jobs ask for more of skills like \(skill(\.tinkeringAndFingerPrecision)), \(skill(\.carefulnessAndAttentionToDetail)) and \(skill(\.stressResistanceAndEmotionalRegulation)) than most.", comment: "Health specialist note, point 3: what the game does about it. The arguments are the names of three of the game's skills")),
            Point(real: String(localized: "The cost is high, too: years of tuition, often on loans, before a first full salary.", comment: "Health specialist note, point 4a (high cost of study): the real-world claim, for adults. Shown in countries where university is costly (not Germany, France, Italy)"),
                  game: String(localized: "The game charges tuition and you may owe a student loan — then the pay is among the highest.", comment: "Health specialist note, point 4a: what the game does about it. Shown in countries where university is costly"),
                  simple: String(localized: "It costs a lot, too: many people borrow money to pay for school.", comment: "Health specialist note, point 4a: the same fact in a beginner's or child's words. Countries where university is costly"),
                  tutorial: String(localized: "Simplified mode has no school bills, so nobody has to borrow.", comment: "Health specialist note, point 4a: what the Simplified tutorial mode does instead"),
                  only: highTuition),
            Point(real: String(localized: "Study itself costs little here — public universities charge only modest fees — but the long road means years of study before a first full salary.", comment: "Health specialist note, point 4b (low cost of study): the real-world claim, for adults. Shown only in Germany, France and Italy, where public universities are almost free"),
                  game: String(localized: "The game charges only about \(fee) a year at a public university, so few students borrow — then the pay is among the highest.", comment: "Health specialist note, point 4b: what the game does about it. Germany, France and Italy only. The argument is a yearly fee as money"),
                  simple: String(localized: "School costs little here, but it takes many years before the first full salary.", comment: "Health specialist note, point 4b: the same fact in a beginner's or child's words. Germany, France and Italy only"),
                  tutorial: String(localized: "Simplified mode has no school bills, so nobody has to borrow.", comment: "Health specialist note, point 4b: what the Simplified tutorial mode does instead"),
                  only: lowTuition),
        ])
    }

    private static func judge(_ job: Job) -> Note {
        Note(title: String(localized: "Becoming a judge", comment: "Title of an advisor real-world note about becoming a judge. Shown only in common-law countries (US, Canada, UK)"), points: [
            Point(real: String(localized: "Judges are appointed or elected, usually after ten to twenty years as lawyers or prosecutors. There are few openings, and they rarely come up.", comment: "Judge note, point 1 (how judges are chosen): the real-world claim, for adults. True of common-law countries only (US, Canada, UK)"),
                  game: String(localized: "Very few jobs open: the game's demand for judges is \(pct(job.hiringDemand)) of a normal job's.", comment: "Judge note, point 1: what the game does about it. The argument is a percentage"),
                  simple: String(localized: "Judges are chosen after ten to twenty years as lawyers. There are very few jobs, and they open up rarely.", comment: "Judge note, point 1: the same fact in a beginner's or child's words. Common-law countries only"),
                  tutorial: basics(job),
                  only: commonLaw),
            Point(real: String(localized: "Reputation in the legal community — and often politics — decides who is chosen.", comment: "Judge note, point 2 (reputation and politics): the real-world claim, for adults. Common-law countries only (US, Canada, UK)"),
                  game: String(localized: "You need a law doctorate, the bar and years practising.", comment: "Judge note, point 2: what the game does about it"),
                  only: commonLaw),
        ])
    }

    private static func scientist(_ job: Job) -> Note {
        Note(title: String(localized: "Becoming a research scientist", comment: "Title of an advisor real-world note about becoming a research scientist"), points: [
            Point(real: String(localized: "A scientist needs a PhD — three to seven years of research — often followed by one or more short postdoctoral posts. There are far fewer permanent research jobs than PhD graduates, so many move to industry.", comment: "Research scientist note, point 1 (PhD and few jobs): the real-world claim, for adults. General claim"),
                  game: String(localized: "A doctorate is required, and the ladder climbs one rung at a time.", comment: "Research scientist note, point 1: what the game does about it"),
                  simple: String(localized: "A scientist usually needs a PhD, which is three to seven years of research. There are fewer research jobs than people with PhDs, so many scientists work in companies instead.", comment: "Research scientist note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: basics(job)),
            Point(real: String(localized: "Careers are made by publications and by winning research funding: a record of results, and other scientists who cite your work.", comment: "Research scientist note, point 2 (publications and funding): the real-world claim, for adults. General claim"),
                  game: String(localized: "Your fame in \(JobCategory.science.displayName) and your network in it add to your chance.", comment: "Research scientist note, point 2: what the game does about it. The argument is the job field Science")),
        ])
    }

    private static func pilot(_ job: Job) -> Note {
        let years = AdvisorCoach.list((AdvisorCoach.family(job.baseTitle)?.rungs ?? []).map { String($0.requirements.minYearsExperience) })
        return Note(title: String(localized: "Becoming an airline pilot", comment: "Title of an advisor real-world note about becoming an airline pilot"), points: [
            Point(real: String(localized: "An airline pilot needs an airline transport licence, which takes years of building flying hours. Most pilots build hours as instructors or on small aircraft, then join a regional airline before a major one.", comment: "Airline pilot note, point 1 (licence and flying hours): the real-world claim, for adults. General claim"),
                  game: String(localized: "Flight school and its licence are the gate; years of experience open each rung.", comment: "Airline pilot note, point 1: what the game does about it"),
                  simple: String(localized: "Airline pilots need a special licence and lots of hours of flying. Most start by teaching flying or flying small planes, then join a bigger airline.", comment: "Airline pilot note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: String(localized: "Simplified mode skips the licence: years of work open each step up (\(years)).", comment: "Airline pilot note, point 1: what the Simplified tutorial mode does instead. The argument is a list of years of work, e.g. '0, 3 and 8'"),
                  tail: [.unitedStates: String(localized: "In the US that normally means 1,500 flight hours (fewer through some approved flight schools).", comment: "Airline pilot note, point 1: US-only statistic (FAA flight-hour rule), shown to US players only")],
                  simpleTail: [.unitedStates: String(localized: "In the US that is about 1,500 hours.", comment: "Airline pilot note, point 1: US-only statistic in a beginner's words, shown to US players only")]),
            Point(real: String(localized: "At airlines, seniority decides who flies the bigger aircraft and who becomes a captain — years of service count for more than talent.", comment: "Airline pilot note, point 2 (seniority): the real-world claim, for adults. General claim"),
                  game: String(localized: "Each rung asks for more years (\(years)) and pays far more.", comment: "Airline pilot note, point 2: what the game does about it. The argument is a list of years of work, e.g. '0, 3 and 8'"),
                  simple: String(localized: "The longer a pilot has worked for an airline, the bigger the plane they get to fly.", comment: "Airline pilot note, point 2: the same fact in a beginner's or child's words"),
                  tutorial: String(localized: "Each step up asks for more years of work (\(years)) and pays a lot more.", comment: "Airline pilot note, point 2: what the Simplified tutorial mode does instead. The argument is a list of years of work")),
        ])
    }

    private static func athlete(_ job: Job) -> Note {
        let title = job.displayBreakthroughFame ?? "Junior Champion" // i18n:ignore fallback that never shows
        let drafted = "1–\(usShare(0.05))"
        return Note(title: String(localized: "Becoming a professional athlete", comment: "Title of an advisor real-world note about becoming a professional athlete"), points: [
            Point(real: String(localized: "Very few young players turn professional, and most of those were noticed as teenagers.", comment: "Professional athlete note, point 1 (few turn professional): the real-world claim, for adults. General claim"),
                  game: String(localized: "The \(title) title opens the door, and even then only \(pct(GameConstants.proRosterChance)) of title-holders make a roster.", comment: "Professional athlete note, point 1: what the game does about it. Arguments: the name of a junior championship title, a percentage"),
                  simple: String(localized: "Very few young players become professionals, and most were noticed as teenagers.", comment: "Professional athlete note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: String(localized: "The \(title) title opens the door — and in Simplified mode, once you have it, a team spot is yours.", comment: "Professional athlete note, point 1: what the Simplified tutorial mode does instead. The argument is the name of a junior championship title"),
                  tail: [.unitedStates: String(localized: "In US college sport roughly \(drafted) are drafted.", comment: "Professional athlete note, point 1: US-only statistic (share of US college athletes drafted into a pro league), shown to US players only. The argument is a range of percentages such as '1–5%'")],
                  simpleTail: [.unitedStates: String(localized: "In US college sport only about 1 to 5 in every 100 get picked.", comment: "Professional athlete note, point 1: US-only statistic in a beginner's words, shown to US players only")]),
            Point(real: String(localized: "Careers are short and an injury can end one without warning, so most athletes need a second career.", comment: "Professional athlete note, point 2 (short careers): the real-world claim, for adults. General claim"),
                  game: String(localized: "Careers end early in the game too.", comment: "Professional athlete note, point 2: what the game does about it"),
                  simple: String(localized: "A sports career can end suddenly with an injury, so most athletes need a second job.", comment: "Professional athlete note, point 2: the same fact in a beginner's or child's words"),
                  tutorial: String(localized: "Sports careers end early in the game too.", comment: "Professional athlete note, point 2: what the Simplified tutorial mode does instead")),
        ])
    }

    private static func eliteFirm(_ job: Job) -> Note {
        Note(title: String(localized: "Getting into an elite firm", comment: "Title of an advisor real-world note about getting hired by an elite investment bank or consultancy"), points: [
            Point(real: String(localized: "These firms recruit mostly from a short list of universities, through campus events and internships. At the biggest banks, well under \(pct(0.01)) of applicants for analyst jobs are hired.", comment: "Elite firm note, point 1 (campus recruiting): the real-world claim, for adults. General claim (the sources are American, the claim is stated for everyone). The argument is a percentage"),
                  game: String(localized: "A top-tier university adds +\(pct(Job.prestigeBonus(forPrestige: 3))) to your chance, and demand for the job is only \(pct(job.hiringDemand)) of a normal one's.", comment: "Elite firm note, point 1: what the game does about it. Arguments: two percentages"),
                  simple: String(localized: "Big banks and consulting firms mostly hire from a short list of universities, and fewer than 1 in 100 people who apply for a first job there get it.", comment: "Elite firm note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: basics(job)),
            Point(real: String(localized: "Analysts are hired in yearly classes and expected to work very long hours. Many leave after a couple of years for other industries; the rest face “up or out” promotions.", comment: "Elite firm note, point 2 (long hours, up or out): the real-world claim, for adults. General claim"),
                  game: String(localized: "Each rung above the entry level is harder to be hired into from outside.", comment: "Elite firm note, point 2: what the game does about it"),
                  simple: String(localized: "New analysts work very long hours, and many leave after a couple of years.", comment: "Elite firm note, point 2: the same fact in a beginner's or child's words")),
        ])
    }

    private static func presenter(_ job: Job) -> Note {
        Note(title: String(localized: "Becoming a TV presenter", comment: "Title of an advisor real-world note about becoming a TV presenter"), points: [
            Point(real: String(localized: "Presenters are found through auditions, showreels and being seen — small stations first, then national. Reliability on live TV and a following of viewers count for more than looks.", comment: "TV presenter note, point 1 (auditions and a following): the real-world claim, for adults. General claim"),
                  game: String(localized: "\(FameCategory.entertainment.displayName) fame is what employers weigh (up to +\(pct(Player.fameHireCap(topPosition: false)))): projects and events build it.", comment: "TV presenter note, point 1: what the game does about it. Arguments: the fame field Entertainment, a percentage. 'Fame' is the game's own term"),
                  simple: String(localized: "TV presenters start with auditions and video clips of themselves, at small stations first. Staying calm on live TV and having viewers who like you matter more than looks.", comment: "TV presenter note, point 1: the same fact in a beginner's or child's words"),
                  tutorial: basics(job)),
        ])
    }

    private static func pct(_ share: Double) -> String { AdvisorPathway.percent(share) }

    /// A fixed American statistic, "73%", written the same whatever the device's region.
    private static func usShare(_ share: Double) -> String { "\(Int((share * 100).rounded()))%" }
}
