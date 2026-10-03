import Foundation

/// Where the player grows up — the second choice made at launch, beside the
/// difficulty. A country sets the money side of a life: the currency, what
/// each job pays, what school costs, the living costs a paycheck has to clear
/// and the price of starting a business. It doesn't change the jobs, their
/// requirements or the rules: every country runs the same career game, priced
/// in its own money.
///
/// **How the money is converted.** The job catalogue is written in US dollars
/// (BLS OEWS medians). `localPay` turns each role's reference pay into local
/// pay when the catalogue builds its jobs (`JobCatalog.allJobs(in:)`), so every
/// amount downstream — offers, raises, promotions, savings, the advisor's
/// quotes — is already local and nothing converts twice. Rules that are about
/// the *job* rather than the money (which roles prefer a degree, say) read
/// `Job.referenceIncome` instead, so they are the same everywhere.
///
/// Every country but the US is one `Profile`: a pay curve, the pay scales
/// that sit off it, a tuition table, and a handful of amounts. Adding a
/// country is adding a profile.
///
/// Figures are 2025–26, full-time and gross, and deliberately round: they
/// describe a country's pay *shape* — how much less a doctor earns next to a
/// cleaner, what a degree costs — not any one employer. Not yet country-
/// specific: the school system (ages, tracks, apprenticeships), licence names,
/// labour law, the retirement age, and the advisor's real-world notes, which
/// cite US sources.
enum Country: String, Codable, CaseIterable, Identifiable {
    case unitedStates
    case australia
    case brazil
    case canada
    case china
    case france
    case germany
    case india
    case italy
    case japan
    case mexico
    case poland
    case southKorea
    case spain
    case sweden
    case turkey
    case ukraine
    case unitedKingdom

    var id: String { rawValue }

    /// The country a new game starts in unless the player picks another.
    static let `default`: Country = .unitedStates

    /// The country's name in the player's language ("Germany" / "Deutschland").
    /// `rawValue` stays the English id.
    var title: String { String(localized: profile.title) }

    /// Every country, in the order of the game's language (the names are translated, so the
    /// order of the English names would look shuffled in German or Japanese).
    static var sortedForPicker: [Country] {
        allCases.sorted { $0.title.compare($1.title, locale: L10n.locale) == .orderedAscending }
    }
    var flag: String { profile.flag }
    var currencySymbol: String { profile.currencySymbol }

    /// An amount the way the game writes money: "68,000 $", "45.000 €",
    /// "4,380,000 ¥". The grouping follows the game's language and locale, and Japanese
    /// writes "4,380,000円" and "$68,000".
    func money(_ amount: Int) -> String {
        let number = Fmt.number(amount)
        switch L10n.language {
        case .english:
            return "\(number) \(currencySymbol)"
        case .japanese:
            // Yen are written in 万 (ten thousands) and 億: "9,500円", "54万3,210円", "270万円", "1億2,345万円".
            // Up to a million it is exact; above, it is rounded to the 万 — a salary of 2,700,864 reads 270万円.
            // Every other currency leads with its sign: "$68,000".
            guard self == .japan else { return "\(currencySymbol)\(Fmt.number(amount))" }
            return Self.yen(amount)
        default:
            // A no-break space, so the sign never wraps onto the next line alone.
            return "\(number)\u{00A0}\(currencySymbol)"
        }
    }

    /// Yen the way Japanese writes them (see `money`).
    private static func yen(_ amount: Int) -> String {
        let sign = amount < 0 ? "−" : ""
        let value = abs(amount)
        let body: String
        switch value {
        case ..<10_000:
            body = "\(Fmt.number(value))円"
        case ..<1_000_000:
            let man = value / 10_000, rest = value % 10_000
            body = rest == 0 ? "\(man)万円" : "\(man)万\(Fmt.number(rest))円"
        default:
            let man = (value + 5_000) / 10_000          // rounded to the nearest 万
            let oku = man / 10_000, rest = man % 10_000
            if oku == 0 { body = "\(Fmt.number(man))万円" }
            else { body = rest == 0 ? "\(Fmt.number(oku))億円" : "\(Fmt.number(oku))億\(Fmt.number(rest))万円" }
        }
        return sign + body
    }

    /// The smallest step money moves in on a slider — 500 in most currencies,
    /// more where the unit is small (yen, hryvnia).
    var moneyStep: Int { profile.step }

    // MARK: - Pay

    /// Local pay for a catalogue role whose US reference pay is `reference`.
    ///
    /// A power law through the country's own reference points: `anchor` is what
    /// a $30,000 US job pays locally, and an exponent under 1 compresses the top
    /// — most rich countries pay their professionals far less, next to their
    /// low-wage workers, than the US does. Fields that sit off the curve take a
    /// factor, and roles on a national pay scale (hospital doctors, nurses,
    /// teachers, airline pilots) are stated outright. No job pays under the
    /// minimum wage.
    func localPay(title: String, category: JobCategory, reference: Int) -> Int {
        guard let pay = profile.pay else { return reference }
        if let stated = pay.stated[title] { return stated }
        let curve = pay.anchor * pow(Double(reference) / Self.curveReference, pay.exponent)
        let local = curve * (pay.categoryFactor[category] ?? 1)
        return max(minimumAnnualPay, rounded(local))
    }

    /// The US pay the curve's anchor stands for.
    private static let curveReference = 30_000.0

    /// The roles whose pay a country states rather than reads off its curve.
    var statedPay: [String: Int] { profile.pay?.stated ?? [:] }

    /// Local cost of what a venture needs to launch, from its US reference:
    /// premises, equipment and stock, in local money.
    func localCapital(_ reference: Int) -> Int {
        profile.pay == nil ? reference : rounded(Double(reference) * profile.capitalScale)
    }

    /// Local money per US dollar of general pay — what money that tracks the
    /// overall level of pay rather than one job is scaled by (what brands pay a
    /// famous person).
    var generalPayScale: Double { profile.generalPayScale }

    /// The age a driving licence can be taken: 16 in the US and Canada (by state
    /// and province), 17 in the UK and France, 18 elsewhere.
    var drivingAge: Int { profile.drivingAge }

    /// Full-time pay at the minimum wage: the least any job may pay — its
    /// median, an offer to a newcomer, or an ask.
    var minimumAnnualPay: Int { profile.minimumAnnualPay }

    /// Pay rounded the way a pay scale reads.
    private func rounded(_ amount: Double) -> Int {
        let step = Double(profile.step)
        return Int((amount / step).rounded()) * profile.step
    }

    // MARK: - School

    /// A year of `level` at a `tier` school, in local money.
    func annualTuition(tier: EducationTier, level: Level.Stage, profile subject: TertiaryProfile?) -> Int {
        guard let table = profile.tuition else { return tier.annualTuition(for: level, profile: subject) }
        return table.annual(tier: tier, level: level, profile: subject)
    }

    /// The interest charged on a student loan, after inflation.
    var studentLoanInterest: Double { profile.studentLoanInterest }

    // MARK: - Living costs and saving

    /// A year's basic living costs in Real Life, gross — nothing is saved below
    /// it (see `Difficulty.livingCostFloor(in:)`).
    var livingCostFloor: Int { profile.livingCostFloor }

    /// Pay above this is saved at the higher high-earner rate (see
    /// `Player.annualSaving`): the top few percent of earners in each country.
    var highEarnerThreshold: Int { profile.highEarnerThreshold }

    // MARK: - Score

    /// The Game Center leaderboard a run in this country is scored on. Net
    /// worth ÷ age in one currency isn't comparable with another, and even two
    /// euro countries have different pay levels, so each country has its own
    /// board. (Each non-US board must be created in App Store Connect.)
    var leaderboardID: String {
        profile.leaderboardSuffix.isEmpty
            ? GameCenterLeaderboards.wealthVelocity
            : GameCenterLeaderboards.wealthVelocity + "_" + profile.leaderboardSuffix
    }

    // MARK: - Picker

    /// What the country changes, for the picker's ⓘ. Every line is a whole
    /// sentence (bullets included) so each language can phrase it its own way.
    var details: String {
        let tuition = { (tier: EducationTier) in self.annualTuition(tier: tier, level: .Bachelor, profile: nil) }
        guard profile.pay != nil else {
            return [
                String(localized: profile.introduction),
                "",
                L("• Pay is the national median for each job."),
                L("• Universities charge tuition — from about \(money(tuition(.community))) a year at a community college to \(money(tuition(.elite))) or more at an elite one — so many students borrow."),
            ].joined(separator: "\n")
        }
        var lines = [String(localized: profile.introduction), ""]
        lines += profile.highlights.map { "• " + String(localized: $0) }   // i18n:ignore bullet glyph; the text is a catalog string
        lines.append(L("• \(String(localized: profile.minimumWageNote)): no job pays under \(money(minimumAnnualPay)) a year."))
        lines.append(L("• A university year costs about \(money(tuition(.state))), or \(money(tuition(.elite))) at an elite school."))
        lines.append(L("• Living costs take the first \(money(livingCostFloor)) of pay."))
        if let note = profile.leaderboardNote { lines.append(String(localized: note)) }
        lines.append("")
        lines.append(L("Still American for now: school ages and tracks, licence names and most of the advisor's real-world facts."))
        return lines.joined(separator: "\n")
    }

    // MARK: - Profiles

    /// Everything that makes a country's money its own.
    struct Profile {
        /// The country's name (display text; the id is `Country.rawValue`).
        let title: LocalizedStringResource
        /// The picker's opening sentence, naming the country and its currency in
        /// full ("Pay, prices and school costs from the United Kingdom, in pounds.").
        /// A whole sentence per country, because "from Germany" / "from the
        /// United Kingdom" take different articles and cases in other languages.
        let introduction: LocalizedStringResource
        let flag: String
        let currencySymbol: String
        let leaderboardSuffix: String
        /// nil for the US: the catalogue already is its pay.
        let pay: PayModel?
        let step: Int
        let minimumAnnualPay: Int
        /// A noun phrase ("The minimum wage (€13.90 an hour)") that leads the picker line "…: no job pays under N a year."
        let minimumWageNote: LocalizedStringResource
        /// nil for the US: `EducationTier.annualTuition` is its table.
        let tuition: TuitionTable?
        let studentLoanInterest: Double
        let livingCostFloor: Int
        let highEarnerThreshold: Int
        let generalPayScale: Double
        let capitalScale: Double
        /// The age the driving licence opens at.
        var drivingAge: Int = 18
        /// What school is called and how it is graded.
        var schooling: Schooling = .american
        /// "• Scores go to their own German leaderboard." — a whole bullet, because the
        /// adjective is a grammar trap. nil for the US, whose ⓘ has no such line.
        var leaderboardNote: LocalizedStringResource? = nil
        /// What sets the country apart, for the picker's ⓘ.
        let highlights: [LocalizedStringResource]
    }

    struct PayModel {
        /// What a $30,000 US job pays locally.
        let anchor: Double
        let exponent: Double
        var categoryFactor: [JobCategory: Double] = [:]
        /// Exact titles on a national pay scale.
        var stated: [String: Int] = [:]
    }

    /// A year's tuition by level and school tier, with professional doctorates
    /// (medicine, law) priced on their own.
    struct TuitionTable {
        let vocational: [EducationTier: Int]
        let bachelor: [EducationTier: Int]
        let master: [EducationTier: Int]
        let doctorate: [EducationTier: Int]
        var professional: [TertiaryProfile: [EducationTier: Int]] = [:]

        func annual(tier: EducationTier, level: Level.Stage, profile: TertiaryProfile?) -> Int {
            switch level {
            case .Vocational: return vocational[tier] ?? 0
            case .Bachelor:   return bachelor[tier] ?? 0
            case .Master:     return master[tier] ?? 0
            case .Doctorate:
                if let profile, let fees = professional[profile] { return fees[tier] ?? 0 }
                return doctorate[tier] ?? 0
            default:          return 0
            }
        }

        /// The same fee at every tier.
        static func flat(_ fee: Int) -> [EducationTier: Int] {
            Dictionary(uniqueKeysWithValues: EducationTier.allCases.map { ($0, fee) })
        }
    }

    var profile: Profile {
        switch self {
        case .unitedStates:  return Self.unitedStatesProfile
        case .australia:     return Self.australiaProfile
        case .brazil:        return Self.brazilProfile
        case .canada:        return Self.canadaProfile
        case .china:         return Self.chinaProfile
        case .france:        return Self.franceProfile
        case .germany:       return Self.germanyProfile
        case .india:         return Self.indiaProfile
        case .italy:         return Self.italyProfile
        case .japan:         return Self.japanProfile
        case .mexico:        return Self.mexicoProfile
        case .poland:        return Self.polandProfile
        case .southKorea:    return Self.southKoreaProfile
        case .spain:         return Self.spainProfile
        case .sweden:        return Self.swedenProfile
        case .turkey:        return Self.turkeyProfile
        case .ukraine:       return Self.ukraineProfile
        case .unitedKingdom: return Self.unitedKingdomProfile
        }
    }

    private static let unitedStatesProfile = Profile(
        title: LocalizedStringResource("United States", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from the United States, in dollars.", comment: "First line of the country picker's info text, about United States: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."),
        flag: "🇺🇸", currencySymbol: "$", leaderboardSuffix: "",
        pay: nil, step: 500,
        // The federal $7.25 an hour — under every catalogue offer, so it never binds.
        minimumAnnualPay: 15_080, minimumWageNote: LocalizedStringResource("The federal minimum wage", comment: "Noun phrase naming the minimum-wage rule in United States. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: nil, studentLoanInterest: GameConstants.studentLoanAnnualInterest,
        livingCostFloor: 32_000, highEarnerThreshold: GameConstants.highEarnerThreshold,
        generalPayScale: 1.0, capitalScale: 1.0, drivingAge: 16, highlights: [])

    /// Destatis earnings survey for the curve (€28k at $30k, €45k at $60k, €77k
    /// at $130k, €120k at $250k); TV-Ärzte VKA for hospital doctors, TVöD P8 for
    /// nurses, S8a for early-years educators, civil-service A13–A15 for teachers.
    /// Industry-wide agreements (IG Metall) lift factory pay a little. Public
    /// universities charge only the semester fee (about €300, including a
    /// transit ticket), the Excellence universities included; vocational school
    /// in the dual system is free; BAföG is half grant, half interest-free loan.
    private static let germanyProfile = Profile(
        title: LocalizedStringResource("Germany", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Germany, in euros.", comment: "First line of the country picker's info text, about Germany: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇩🇪", currencySymbol: "€",
        leaderboardSuffix: "de",
        pay: PayModel(anchor: 28_000, exponent: 0.689,
                      categoryFactor: [.manufacturing: 1.05, .education: 1.3, .transportation: 0.9],
                      stated: [
                        "Resident Physician": 68_000, "Physician": 100_000, "Senior Physician": 125_000,
                        "Surgeon": 140_000, "Anesthesiologist": 130_000, "Chief Medical Officer": 200_000,
                        "Dentist": 110_000, "Pharmacist": 58_000,
                        "Registered Nurse": 47_000, "Senior Registered Nurse": 55_000,
                        "Licensed Practical Nurse": 36_000, "Nurse Practitioner": 60_000,
                        "Teacher": 58_000, "Senior Teacher": 68_000, "Lead Teacher": 80_000,
                        "Childcare Worker": 42_000,
                        "First Officer": 85_000, "Pilot": 130_000, "Airline Captain": 200_000,
                        "Chief Executive Officer": 220_000, "Chief Technology Officer": 180_000,
                        "Managing Partner": 300_000,
                      ]),
        step: 500,
        // €13.90 an hour in 2026, 40 hours for 52 weeks.
        minimumAnnualPay: 28_900, minimumWageNote: LocalizedStringResource("The minimum wage (€13.90 an hour)", comment: "Noun phrase naming the minimum-wage rule in Germany. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(vocational: TuitionTable.flat(0), bachelor: TuitionTable.flat(600),
                              master: TuitionTable.flat(600), doctorate: TuitionTable.flat(600)),
        studentLoanInterest: 0,
        // Rent and food take about €20,000 net — about €28,000 gross.
        livingCostFloor: 28_000, highEarnerThreshold: 150_000,
        generalPayScale: 0.6, capitalScale: 0.9,
        schooling: .german,
        leaderboardNote: LocalizedStringResource("• Scores go to their own German leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Germany."),
        highlights: [
            LocalizedStringResource("Everyday jobs pay about the same number of euros as dollars in the US; professional jobs pay roughly half. Doctors, nurses, teachers and pilots follow their German pay scales.", comment: "Info bullet in the country picker describing Germany's pay and school costs."),
            LocalizedStringResource("Public universities, the famous ones included, charge only a semester fee, and student loans are interest-free.", comment: "Info bullet in the country picker describing Germany's pay and school costs."),
        ])

    /// Statistics Canada earnings for the curve (C$36k at $30k, C$63k at $60k,
    /// C$118k at $130k, C$200k at $250k); provincial fee schedules for
    /// physicians (gross billings), collective agreements for nurses and
    /// teachers. Tuition is Statistics Canada's domestic average (about C$7,400
    /// for an undergraduate year), with medicine and law priced on their own.
    /// The federal share of a student loan has been interest-free since 2023.
    private static let canadaProfile = Profile(
        title: LocalizedStringResource("Canada", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Canada, in Canadian dollars.", comment: "First line of the country picker's info text, about Canada: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇨🇦", currencySymbol: "C$",
        leaderboardSuffix: "ca",
        pay: PayModel(anchor: 36_000, exponent: 0.809,
                      categoryFactor: [.education: 1.2],
                      stated: [
                        "Resident Physician": 62_000, "Physician": 280_000, "Senior Physician": 330_000,
                        "Surgeon": 420_000, "Anesthesiologist": 400_000, "Chief Medical Officer": 380_000,
                        "Registered Nurse": 88_000, "Senior Registered Nurse": 100_000,
                        "Teacher": 70_000, "Senior Teacher": 95_000, "Lead Teacher": 125_000,
                        "First Officer": 110_000, "Pilot": 200_000, "Airline Captain": 300_000,
                      ]),
        step: 500,
        // The federal minimum wage, C$18.15 an hour from 1 April 2026, 40 hours for 52 weeks.
        minimumAnnualPay: 37_750, minimumWageNote: LocalizedStringResource("The federal minimum wage (C$18.15 an hour)", comment: "Noun phrase naming the minimum-wage rule in Canada. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 4_000, .state: 5_000, .elite: 7_000],
            bachelor: [.community: 5_000, .state: 7_400, .elite: 10_000],
            master: [.community: 7_000, .state: 8_500, .elite: 12_000],
            doctorate: [.community: 3_000, .state: 3_000, .elite: 4_000],
            professional: [.health: [.community: 22_000, .state: 22_000, .elite: 28_000],
                           .law: [.community: 15_000, .state: 18_000, .elite: 34_000]]),
        studentLoanInterest: 0.01,
        livingCostFloor: 35_000, highEarnerThreshold: 250_000,
        generalPayScale: 1.05, capitalScale: 1.25, drivingAge: 16,
        schooling: .canadian,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Canadian leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Canada."),
        highlights: [
            LocalizedStringResource("Pay is close to the US in Canadian dollars for everyday jobs, and lower for professionals. Doctors bill provincial health plans and earn among the most.", comment: "Info bullet in the country picker describing Canada's pay and school costs."),
            LocalizedStringResource("Tuition is moderate, and the federal part of a student loan is interest-free.", comment: "Info bullet in the country picker describing Canada's pay and school costs."),
        ])

    /// ONS Annual Survey of Hours and Earnings for the curve (£25k at $30k,
    /// £39k at $60k, £63k at $130k, £95k at $250k); NHS Agenda for Change and the
    /// 2025–26 medical pay awards (resident doctors, consultants), the teachers'
    /// pay award. English universities may charge up to £9,790 a year (2026/27) — the
    /// same at Oxford as anywhere — and most PhDs are funded. A Plan 5 student
    /// loan carries inflation-only interest.
    private static let unitedKingdomProfile = Profile(
        title: LocalizedStringResource("United Kingdom", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from the United Kingdom, in pounds.", comment: "First line of the country picker's info text, about United Kingdom: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."),
        flag: "🇬🇧", currencySymbol: "£", leaderboardSuffix: "uk",
        pay: PayModel(anchor: 25_000, exponent: 0.63,
                      stated: [
                        "Resident Physician": 44_000, "Physician": 110_000, "Senior Physician": 135_000,
                        "Surgeon": 145_000, "Anesthesiologist": 140_000, "Chief Medical Officer": 200_000,
                        "Registered Nurse": 31_000, "Senior Registered Nurse": 38_500,
                        "Licensed Practical Nurse": 26_000, "Nurse Practitioner": 52_000,
                        "Teacher": 38_000, "Senior Teacher": 49_000, "Lead Teacher": 70_000,
                        "First Officer": 70_000, "Pilot": 110_000, "Airline Captain": 160_000,
                      ]),
        step: 500,
        // The National Living Wage, £12.71 an hour from April 2026, 37.5 hours for 52 weeks.
        minimumAnnualPay: 24_800, minimumWageNote: LocalizedStringResource("The National Living Wage (£12.71 an hour)", comment: "Noun phrase naming the minimum-wage rule in United Kingdom. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: TuitionTable.flat(0), bachelor: TuitionTable.flat(9_790),
            master: [.community: 10_000, .state: 12_000, .elite: 18_000],
            doctorate: TuitionTable.flat(0),
            professional: [.health: TuitionTable.flat(9_790), .law: [.community: 12_000, .state: 15_000, .elite: 18_000]]),
        studentLoanInterest: 0,
        livingCostFloor: 26_000, highEarnerThreshold: 125_000,
        generalPayScale: 0.65, capitalScale: 0.75, drivingAge: 17,
        schooling: .british,
        leaderboardNote: LocalizedStringResource("• Scores go to their own British leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: United Kingdom."),
        highlights: [
            LocalizedStringResource("Professional pay is well under the US; NHS doctors, nurses and teachers follow national pay scales.", comment: "Info bullet in the country picker describing United Kingdom's pay and school costs."),
            LocalizedStringResource("Every English university charges up to £9,790 a year — the famous ones too — and most PhDs are funded.", comment: "Info bullet in the country picker describing United Kingdom's pay and school costs."),
        ])

    /// INSEE salary data for the curve (€22k at $30k, €34k at $60k, €56k at
    /// $130k, €85k at $250k); hospital pay grids for doctors and nurses, the
    /// national teaching grid. Public universities charge the national fees
    /// (€178 a year for a licence, €254 for a master's, €397 for a doctorate,
    /// plus the €105 student-life levy); the grandes écoles of business charge
    /// far more.
    private static let franceProfile = Profile(
        title: LocalizedStringResource("France", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from France, in euros.", comment: "First line of the country picker's info text, about France: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇫🇷", currencySymbol: "€",
        leaderboardSuffix: "fr",
        pay: PayModel(anchor: 22_000, exponent: 0.638,
                      stated: [
                        "Resident Physician": 30_000, "Physician": 90_000, "Senior Physician": 110_000,
                        "Surgeon": 130_000, "Anesthesiologist": 120_000, "Chief Medical Officer": 150_000,
                        "Registered Nurse": 32_000, "Senior Registered Nurse": 38_000,
                        "Licensed Practical Nurse": 25_000, "Nurse Practitioner": 42_000,
                        "Teacher": 34_000, "Senior Teacher": 45_000, "Lead Teacher": 55_000,
                        "First Officer": 80_000, "Pilot": 150_000, "Airline Captain": 220_000,
                        "Chief Executive Officer": 200_000, "Chief Technology Officer": 150_000,
                        "Managing Partner": 250_000,
                      ]),
        step: 500,
        // The SMIC, €12.31 an hour from 1 June 2026, on the legal 35-hour week.
        minimumAnnualPay: 22_400, minimumWageNote: LocalizedStringResource("The minimum wage (SMIC, on a 35-hour week)", comment: "Noun phrase naming the minimum-wage rule in France. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: TuitionTable.flat(0),
            bachelor: [.community: 280, .state: 280, .elite: 12_000],
            master: [.community: 360, .state: 360, .elite: 16_000],
            doctorate: [.community: 500, .state: 500, .elite: 500],
            professional: [.health: TuitionTable.flat(500), .law: [.community: 500, .state: 500, .elite: 14_000]]),
        studentLoanInterest: 0.01,
        livingCostFloor: 24_000, highEarnerThreshold: 120_000,
        generalPayScale: 0.57, capitalScale: 0.85, drivingAge: 17,
        schooling: .french,
        leaderboardNote: LocalizedStringResource("• Scores go to their own French leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: France."),
        highlights: [
            LocalizedStringResource("Pay is compressed: the minimum wage is high and professional pay far under the US. Hospital doctors, nurses and teachers follow national grids.", comment: "Info bullet in the country picker describing France's pay and school costs."),
            LocalizedStringResource("Public universities cost a few hundred euros a year; the elite business schools are the exception.", comment: "Info bullet in the country picker describing France's pay and school costs."),
        ])

    /// ISTAT earnings for the curve (€20k at $30k, €30k at $60k, €48k at $130k,
    /// €70k at $250k); the national health-service contract for doctors and
    /// nurses, the school contract for teachers. Italy has no statutory minimum
    /// wage: collective agreements set the floor. Public universities charge by
    /// family income (about €1,700 a year on average); Bocconi and the private
    /// medical schools charge far more.
    private static let italyProfile = Profile(
        title: LocalizedStringResource("Italy", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Italy, in euros.", comment: "First line of the country picker's info text, about Italy: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇮🇹", currencySymbol: "€",
        leaderboardSuffix: "it",
        pay: PayModel(anchor: 20_000, exponent: 0.591,
                      stated: [
                        "Resident Physician": 26_000, "Physician": 80_000, "Senior Physician": 100_000,
                        "Surgeon": 110_000, "Anesthesiologist": 105_000, "Chief Medical Officer": 130_000,
                        "Registered Nurse": 30_000, "Senior Registered Nurse": 34_000,
                        "Licensed Practical Nurse": 22_000, "Nurse Practitioner": 36_000,
                        "Teacher": 30_000, "Senior Teacher": 38_000, "Lead Teacher": 60_000,
                        "First Officer": 70_000, "Pilot": 110_000, "Airline Captain": 160_000,
                        "Chief Executive Officer": 180_000, "Chief Technology Officer": 130_000,
                        "Managing Partner": 220_000,
                      ]),
        step: 500,
        // No statutory minimum: collective agreements pay about €8.70 an hour at the bottom.
        minimumAnnualPay: 18_000, minimumWageNote: LocalizedStringResource("Collective agreements set the floor (Italy has no legal minimum wage)", comment: "Noun phrase naming the minimum-wage rule in Italy. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: TuitionTable.flat(0),
            bachelor: [.community: 1_200, .state: 1_700, .elite: 14_000],
            master: [.community: 1_500, .state: 2_000, .elite: 16_000],
            doctorate: TuitionTable.flat(0),
            professional: [.health: [.community: 2_500, .state: 2_500, .elite: 20_000],
                           .law: [.community: 2_000, .state: 2_000, .elite: 15_000]]),
        studentLoanInterest: 0.02,
        livingCostFloor: 20_000, highEarnerThreshold: 100_000,
        generalPayScale: 0.5, capitalScale: 0.8,
        schooling: .italian,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Italian leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Italy."),
        highlights: [
            LocalizedStringResource("Pay is among the lowest in western Europe, and professional pay is much less than in the US. Doctors, nurses and teachers are paid on national contracts.", comment: "Info bullet in the country picker describing Italy's pay and school costs."),
            LocalizedStringResource("Public universities charge by family income; the private elite schools charge much more.", comment: "Info bullet in the country picker describing Italy's pay and school costs."),
        ])

    /// MHLW wage census for the curve (¥2.8M at $30k, ¥4.4M at $60k, ¥7.2M at
    /// $130k, ¥11M at $250k); pay is seniority-based and compressed. National
    /// universities charge the standard ¥535,800 a year, less than most private
    /// universities (the University of Tokyo raised its undergraduate fee to
    /// ¥642,960 for 2025 entrants — the top national tier is priced at the
    /// standard rate); private medical schools cost millions of yen a year.
    /// JASSO loans are interest-free or nearly so.
    private static let japanProfile = Profile(
        title: LocalizedStringResource("Japan", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Japan, in yen.", comment: "First line of the country picker's info text, about Japan: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇯🇵", currencySymbol: "¥",
        leaderboardSuffix: "jp",
        pay: PayModel(anchor: 2_800_000, exponent: 0.645,
                      stated: [
                        "Resident Physician": 4_500_000, "Physician": 12_000_000, "Senior Physician": 15_000_000,
                        "Surgeon": 16_000_000, "Anesthesiologist": 16_000_000, "Chief Medical Officer": 20_000_000,
                        "Registered Nurse": 5_000_000, "Senior Registered Nurse": 5_800_000,
                        "Licensed Practical Nurse": 4_000_000, "Nurse Practitioner": 6_000_000,
                        "Teacher": 5_000_000, "Senior Teacher": 7_000_000, "Lead Teacher": 9_500_000,
                        "First Officer": 12_000_000, "Pilot": 18_000_000, "Airline Captain": 25_000_000,
                        "Chief Executive Officer": 25_000_000, "Chief Technology Officer": 18_000_000,
                        "Managing Partner": 30_000_000,
                      ]),
        step: 10_000,
        // The national weighted-average minimum wage, ¥1,121 an hour (October 2025), 2,080 hours.
        minimumAnnualPay: 2_330_000, minimumWageNote: LocalizedStringResource("The minimum wage (¥1,121 an hour on average)", comment: "Noun phrase naming the minimum-wage rule in Japan. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 800_000, .state: 1_000_000, .elite: 1_200_000],
            bachelor: [.community: 700_000, .state: 950_000, .elite: 535_800],
            master: [.community: 535_800, .state: 800_000, .elite: 535_800],
            doctorate: TuitionTable.flat(535_800),
            professional: [.health: [.community: 535_800, .state: 4_000_000, .elite: 535_800],
                           .law: [.community: 804_000, .state: 1_000_000, .elite: 804_000]]),
        studentLoanInterest: 0,
        livingCostFloor: 2_700_000, highEarnerThreshold: 15_000_000,
        generalPayScale: 73, capitalScale: 120,
        schooling: .japanese,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Japanese leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Japan."),
        highlights: [
            LocalizedStringResource("Pay rises with seniority and is compressed: professionals earn far less than in the US.", comment: "Info bullet in the country picker describing Japan's pay and school costs."),
            LocalizedStringResource("The top national universities cost less than most private ones; private medical schools cost millions of yen a year.", comment: "Info bullet in the country picker describing Japan's pay and school costs."),
        ])

    /// State statistics for the curve (₴110k at $30k, ₴206k at $60k, ₴415k at
    /// $130k, ₴750k at $250k), with IT paid half again above the curve: the
    /// best-paid path, well over the national average, but under what outsourcing
    /// developers earn. (A factor of 2.5 put median wealth at ₴5.2M; 1.5 roughly
    /// halves it and keeps IT clearly ahead.) State pay programmes for doctors, nurses and teachers. Students on
    /// state-funded places pay nothing; those on contract places pay the fees
    /// here. Priced in peacetime terms: the war's effects on pay, work and
    /// flights aren't modelled.
    private static let ukraineProfile = Profile(
        title: LocalizedStringResource("Ukraine", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Ukraine, in hryvnias.", comment: "First line of the country picker's info text, about Ukraine: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇺🇦", currencySymbol: "₴",
        leaderboardSuffix: "ua",
        pay: PayModel(anchor: 110_000, exponent: 0.905,
                      categoryFactor: [.technology: 1.5],
                      stated: [
                        "Resident Physician": 150_000, "Physician": 360_000, "Senior Physician": 450_000,
                        "Surgeon": 540_000, "Anesthesiologist": 500_000, "Chief Medical Officer": 600_000,
                        "Registered Nurse": 180_000, "Senior Registered Nurse": 210_000,
                        "Licensed Practical Nurse": 150_000, "Nurse Practitioner": 220_000,
                        "Teacher": 170_000, "Senior Teacher": 220_000, "Lead Teacher": 300_000,
                        "First Officer": 1_200_000, "Pilot": 2_000_000, "Airline Captain": 3_000_000,
                        "Chief Executive Officer": 3_000_000, "Chief Technology Officer": 3_500_000,
                        "Managing Partner": 2_500_000,
                      ]),
        step: 1_000,
        // ₴8,647 a month under the 2026 state budget.
        minimumAnnualPay: 103_800, minimumWageNote: LocalizedStringResource("The minimum wage (₴8,647 a month)", comment: "Noun phrase naming the minimum-wage rule in Ukraine. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: TuitionTable.flat(0),
            bachelor: [.community: 25_000, .state: 35_000, .elite: 70_000],
            master: [.community: 30_000, .state: 40_000, .elite: 80_000],
            doctorate: TuitionTable.flat(0),
            professional: [.health: [.community: 60_000, .state: 70_000, .elite: 100_000],
                           .law: [.community: 40_000, .state: 50_000, .elite: 80_000]]),
        studentLoanInterest: 0,
        livingCostFloor: 120_000, highEarnerThreshold: 1_500_000,
        generalPayScale: 3.4, capitalScale: 20,
        schooling: .ukrainian,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Ukrainian leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Ukraine."),
        highlights: [
            LocalizedStringResource("Most pay is far below western Europe, but IT pays well above the national average — the best-paid path in the country.", comment: "Info bullet in the country picker describing Ukraine's pay and school costs."),
            LocalizedStringResource("University is free on a state-funded place; these are the fees for a paid (contract) place.", comment: "Info bullet in the country picker describing Ukraine's pay and school costs."),
            LocalizedStringResource("Priced as in peacetime: the war's effects on work and flights aren't in the game.", comment: "Info bullet in the country picker describing Ukraine's pay and school costs."),
        ])

    // MARK: - More countries (generated from sourced 2025-26 data; see Tools/i18n and the PR)

    /// Australia: the pay curve is fitted through the local pay of six reference jobs and the national median (98,124) and
    /// 90th-percentile (171,600) full-time wages; A$1,004.90 per week x 52 weeks = A$52,254.80 (A$26.44 x 38 h = A$1,004.72; FWC publishes A$1,004.90).
    /// Commonwealth-supported fees are set nationally by discipline band, not by university, so the community/state/elite tiers for bachelor, medicine and law are mapped to bands rather than institutions.
    /// HELP (HECS-HELP) is interest-free but indexed every 1 June to the lower of CPI and the Wage Price Index (2.8% in June 2026).
    private static let australiaProfile = Profile(
        title: LocalizedStringResource("Australia", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Australia, in Australian dollars.", comment: "First line of the country picker's info text, about Australia: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇦🇺", currencySymbol: "A$",
        leaderboardSuffix: "au",
        pay: PayModel(anchor: 59_300, exponent: 0.623,
                      categoryFactor: [.technology: 0.85],
                      stated: [
                        "Resident Physician": 97_000,
                        "Physician": 320_000,
                        "Senior Physician": 400_000,
                        "Surgeon": 448_000,
                        "Anesthesiologist": 416_000,
                        "Chief Medical Officer": 640_000,
                        "Dentist": 160_000,
                        "Pharmacist": 100_000,
                        "Registered Nurse": 98_000,
                        "Senior Registered Nurse": 114_500,
                        "Licensed Practical Nurse": 75_500,
                        "Nurse Practitioner": 125_500,
                        "Teacher": 105_000,
                        "Senior Teacher": 123_000,
                        "Lead Teacher": 145_000,
                        "First Officer": 135_000,
                        "Pilot": 187_500,
                        "Airline Captain": 260_000,
                      ]),
        step: 500,
        minimumAnnualPay: 52_255, minimumWageNote: LocalizedStringResource("The minimum wage (A$26.44 an hour)", comment: "Noun phrase naming the minimum-wage rule in Australia. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 1_500, .state: 3_500, .elite: 10_000],
            bachelor: TuitionTable.flat(9_537),
            master: [.community: 22_000, .state: 32_000, .elite: 46_000],
            doctorate: TuitionTable.flat(0),
            professional: [.health: TuitionTable.flat(13_558),
                           .law: TuitionTable.flat(17_399)]),
        studentLoanInterest: 0,
        livingCostFloor: 55_000, highEarnerThreshold: 350_000,
        generalPayScale: 1.52, capitalScale: 1.4, drivingAge: 17, schooling: .australian,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Australian leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Australia."),
        highlights: [
            LocalizedStringResource("Pay is high and compressed: the minimum wage is about half the typical full-time wage.", comment: "Info bullet in the country picker describing Australia's pay and school costs."),
            LocalizedStringResource("University fees are set by subject, not by university, and HECS-HELP loans are indexed to prices, so they carry no real interest.", comment: "Info bullet in the country picker describing Australia's pay and school costs."),
        ])

    /// Brazil: the pay curve is fitted through the local pay of six reference jobs and the national median (39,000) and
    /// 90th-percentile (97,500) full-time wages; R$1,621 x 13 = R$21,073.
    /// Public federal and state universities charge no tuition, and this includes the most selective ones (USP, Unicamp, UFRJ).
    /// Fies (Fundo de Financiamento Estudantil) is the federal loan for tuition at private colleges.
    private static let brazilProfile = Profile(
        title: LocalizedStringResource("Brazil", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Brazil, in reais.", comment: "First line of the country picker's info text, about Brazil: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇧🇷", currencySymbol: "R$",
        leaderboardSuffix: "br",
        pay: PayModel(anchor: 18_100, exponent: 1.3,
                      categoryFactor: [.technology: 0.85],
                      stated: [
                        "Resident Physician": 49_000,
                        "Physician": 208_000,
                        "Senior Physician": 260_000,
                        "Surgeon": 291_000,
                        "Anesthesiologist": 270_000,
                        "Chief Medical Officer": 416_000,
                        "Dentist": 71_000,
                        "Pharmacist": 60_000,
                        "Registered Nurse": 58_000,
                        "Senior Registered Nurse": 68_000,
                        "Licensed Practical Nurse": 45_000,
                        "Nurse Practitioner": 75_000,
                        "Teacher": 72_000,
                        "Senior Teacher": 84_000,
                        "Lead Teacher": 99_000,
                        "First Officer": 234_000,
                        "Pilot": 349_000,
                        "Airline Captain": 520_000,
                      ]),
        step: 1000,
        minimumAnnualPay: 21_073, minimumWageNote: LocalizedStringResource("The minimum wage (R$1,621 a month, paid 13 times)", comment: "Noun phrase naming the minimum-wage rule in Brazil. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 7_200, .state: 0, .elite: 18_000],
            bachelor: [.community: 9_600, .state: 0, .elite: 70_000],
            master: [.community: 24_000, .state: 0, .elite: 45_000],
            doctorate: [.community: 30_000, .state: 0, .elite: 42_000],
            professional: [.health: [.community: 96_000, .state: 0, .elite: 190_000],
                           .law: [.community: 10_800, .state: 0, .elite: 80_000]]),
        studentLoanInterest: 0,
        livingCostFloor: 42_900, highEarnerThreshold: 170_000,
        generalPayScale: 0.741, capitalScale: 2.5, schooling: .brazilian,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Brazilian leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Brazil."),
        highlights: [
            LocalizedStringResource("The minimum wage is paid in 13 instalments, and the average worker earns about 2.3 times the minimum.", comment: "Info bullet in the country picker describing Brazil's pay and school costs."),
            LocalizedStringResource("Public universities, the most selective included, charge no tuition, but entry is by the ENEM exam, and many students pay for a private college instead.", comment: "Info bullet in the country picker describing Brazil's pay and school costs."),
        ])

    /// China: the pay curve is fitted through the local pay of six reference jobs and the national median (64,000) and
    /// 90th-percentile (130,000) full-time wages; CN¥2,740 a month x 12 = CN¥32,880.
    /// Public tuition in China is state-regulated and low: about CN¥4,000-6,500 a year for most public bachelor's degrees.
    /// National Student Loan (国家助学贷款), state-backed and run through China Development Bank and the student's home county.
    private static let chinaProfile = Profile(
        title: LocalizedStringResource("China", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from China, in yuan.", comment: "First line of the country picker's info text, about China: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇨🇳", currencySymbol: "CN¥",
        leaderboardSuffix: "cn",
        pay: PayModel(anchor: 37_700, exponent: 0.855,
                      stated: [
                        "Resident Physician": 100_000,
                        "Physician": 200_000,
                        "Senior Physician": 250_000,
                        "Surgeon": 280_000,
                        "Anesthesiologist": 260_000,
                        "Chief Medical Officer": 400_000,
                        "Dentist": 150_000,
                        "Pharmacist": 85_000,
                        "Registered Nurse": 75_000,
                        "Senior Registered Nurse": 88_000,
                        "Licensed Practical Nurse": 58_000,
                        "Nurse Practitioner": 96_000,
                        "Teacher": 110_000,
                        "Senior Teacher": 129_000,
                        "Lead Teacher": 152_000,
                        "First Officer": 350_000,
                        "Pilot": 592_000,
                        "Airline Captain": 1_000_000,
                      ]),
        step: 1000,
        minimumAnnualPay: 32_880, minimumWageNote: LocalizedStringResource("The minimum wage (Shanghai, CN¥2,740 a month)", comment: "Noun phrase naming the minimum-wage rule in China. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 5_000, .state: 5_500, .elite: 6_500],
            bachelor: [.community: 5_000, .state: 5_500, .elite: 5_000],
            master: [.community: 8_000, .state: 10_000, .elite: 12_000],
            doctorate: [.community: 10_000, .state: 10_000, .elite: 12_000],
            professional: [.health: [.community: 6_000, .state: 7_000, .elite: 8_000],
                           .law: [.community: 5_000, .state: 5_500, .elite: 5_500]]),
        studentLoanInterest: 0.02,
        livingCostFloor: 50_000, highEarnerThreshold: 260_000,
        generalPayScale: 1.14, capitalScale: 3.4, schooling: .chinese,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Chinese leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: China."),
        highlights: [
            LocalizedStringResource("Minimum wages are set province by province, and pay in IT and finance is far above hotels and catering.", comment: "Info bullet in the country picker describing China's pay and school costs."),
            LocalizedStringResource("Public universities charge a few thousand yuan a year, and one exam, the gaokao, decides where you can go.", comment: "Info bullet in the country picker describing China's pay and school costs."),
        ])

    /// India: the pay curve is fitted through the local pay of six reference jobs and the national median (210,000) and
    /// 90th-percentile (600,000) full-time wages; Delhi unskilled minimum wage Rs 18,456 a month (Rs 710 a day on a 26-day month) x 12 = Rs 221,472 a year.
    /// All amounts are annual fees for a typical domestic student in rupees, tuition plus compulsory institute fees, excluding hostel and mess.
    /// There is no income-contingent scheme.
    private static let indiaProfile = Profile(
        title: LocalizedStringResource("India", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from India, in rupees.", comment: "First line of the country picker's info text, about India: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇮🇳", currencySymbol: "₹",
        leaderboardSuffix: "in",
        pay: PayModel(anchor: 109_000, exponent: 1.286,
                      stated: [
                        "Resident Physician": 1_000_000,
                        "Physician": 2_400_000,
                        "Senior Physician": 3_000_000,
                        "Surgeon": 3_360_000,
                        "Anesthesiologist": 3_120_000,
                        "Chief Medical Officer": 4_800_000,
                        "Dentist": 350_000,
                        "Pharmacist": 250_000,
                        "Registered Nurse": 250_000,
                        "Senior Registered Nurse": 290_000,
                        "Licensed Practical Nurse": 225_000,
                        "Nurse Practitioner": 320_000,
                        "Teacher": 370_000,
                        "Senior Teacher": 435_000,
                        "Lead Teacher": 510_000,
                        "First Officer": 3_600_000,
                        "Pilot": 5_055_000,
                        "Airline Captain": 7_100_000,
                      ]),
        step: 5000,
        minimumAnnualPay: 221_472, minimumWageNote: LocalizedStringResource("The Delhi minimum wage (₹18,456 a month)", comment: "Noun phrase naming the minimum-wage rule in India. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 3_000, .state: 15_000, .elite: 60_000],
            bachelor: [.community: 6_000, .state: 20_000, .elite: 210_000],
            master: [.community: 8_000, .state: 30_000, .elite: 1_300_000],
            doctorate: [.community: 15_000, .state: 15_000, .elite: 20_850],
            professional: [.health: [.community: 60_000, .state: 60_000, .elite: 2_717],
                           .law: [.community: 25_000, .state: 50_000, .elite: 147_000]]),
        studentLoanInterest: 0.045,
        livingCostFloor: 300_000, highEarnerThreshold: 1_000_000,
        generalPayScale: 4.43, capitalScale: 20, schooling: .indian,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Indian leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: India."),
        highlights: [
            LocalizedStringResource("There is no single minimum wage: each state sets its own, and most workers earn little.", comment: "Info bullet in the country picker describing India's pay and school costs."),
            LocalizedStringResource("Elite government institutions such as AIIMS cost very little, but places go by national entrance exams.", comment: "Info bullet in the country picker describing India's pay and school costs."),
        ])

    /// Mexico: the pay curve is fitted through the local pay of six reference jobs and the national median (135,000) and
    /// 90th-percentile (340,000) full-time wages; 315.04 x 365 days = 114,989.60 (equals 9,582.47 a month x 12).
    /// Fee pages of private universities are dynamic simulators, so the private and elite figures are estimates.
    /// Mexico has no major national public student-loan scheme in the sources checked; most students rely on family funds, scholarships or free or cheap public universities.
    private static let mexicoProfile = Profile(
        title: LocalizedStringResource("Mexico", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Mexico, in Mexican pesos.", comment: "First line of the country picker's info text, about Mexico: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇲🇽", currencySymbol: "MX$",
        leaderboardSuffix: "mx",
        pay: PayModel(anchor: 75_900, exponent: 1.04,
                      stated: [
                        "Resident Physician": 270_000,
                        "Physician": 480_000,
                        "Senior Physician": 600_000,
                        "Surgeon": 672_000,
                        "Anesthesiologist": 624_000,
                        "Chief Medical Officer": 960_000,
                        "Dentist": 200_000,
                        "Pharmacist": 175_000,
                        "Registered Nurse": 170_000,
                        "Senior Registered Nurse": 199_000,
                        "Licensed Practical Nurse": 131_000,
                        "Nurse Practitioner": 218_000,
                        "Teacher": 200_000,
                        "Senior Teacher": 234_000,
                        "Lead Teacher": 276_000,
                        "First Officer": 1_050_000,
                        "Pilot": 1_587_000,
                        "Airline Captain": 2_400_000,
                      ]),
        step: 1000,
        minimumAnnualPay: 119_715, minimumWageNote: LocalizedStringResource("The minimum wage (MX$315.04 a day)", comment: "Noun phrase naming the minimum-wage rule in Mexico. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 6_000, .state: 6_000, .elite: 90_000],
            bachelor: [.community: 6_000, .state: 5_500, .elite: 300_000],
            master: [.community: 10_000, .state: 12_000, .elite: 300_000],
            doctorate: [.community: 3_000, .state: 3_000, .elite: 200_000],
            professional: [.health: [.community: 5_500, .state: 5_500, .elite: 420_000],
                           .law: [.community: 5_500, .state: 5_500, .elite: 260_000]]),
        studentLoanInterest: 0.05,
        livingCostFloor: 155_000, highEarnerThreshold: 590_000,
        generalPayScale: 2.6, capitalScale: 10, schooling: .mexican,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Mexican leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Mexico."),
        highlights: [
            LocalizedStringResource("Pay is low and unequal: nearly half of workers earn no more than one minimum wage.", comment: "Info bullet in the country picker describing Mexico's pay and school costs."),
            LocalizedStringResource("Public universities such as UNAM are almost free, while the top private ones cost far more than most families earn.", comment: "Info bullet in the country picker describing Mexico's pay and school costs."),
        ])

    /// Poland: the pay curve is fitted through the local pay of six reference jobs and the national median (93,000) and
    /// 90th-percentile (185,000) full-time wages; 4,806 zł a month x 12 = 57,672 zł.
    /// Poland has no community colleges, and the most selective universities are public, so every cell is 0 for a full-time student at a public institution (Eurydice).
    /// Kredyt studencki: a bank loan guaranteed and subsidised by the state, paid out as 400-1,000 zł a month to full-time students for up to six years (Student360/Pekao).
    private static let polandProfile = Profile(
        title: LocalizedStringResource("Poland", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Poland, in zloty.", comment: "First line of the country picker's info text, about Poland: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇵🇱", currencySymbol: "zł",
        leaderboardSuffix: "pl",
        pay: PayModel(anchor: 53_900, exponent: 0.833,
                      stated: [
                        "Resident Physician": 140_000,
                        "Physician": 288_000,
                        "Senior Physician": 361_000,
                        "Surgeon": 404_000,
                        "Anesthesiologist": 375_000,
                        "Chief Medical Officer": 577_000,
                        "Dentist": 140_000,
                        "Pharmacist": 132_000,
                        "Registered Nurse": 138_000,
                        "Senior Registered Nurse": 161_000,
                        "Licensed Practical Nurse": 106_000,
                        "Nurse Practitioner": 177_000,
                        "Teacher": 121_000,
                        "Senior Teacher": 142_000,
                        "Lead Teacher": 167_000,
                        "First Officer": 174_000,
                        "Pilot": 258_000,
                        "Airline Captain": 384_000,
                      ]),
        step: 1000,
        minimumAnnualPay: 57_672, minimumWageNote: LocalizedStringResource("The minimum wage (4,806 zł a month)", comment: "Noun phrase naming the minimum-wage rule in Poland. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: TuitionTable.flat(0),
            bachelor: TuitionTable.flat(0),
            master: TuitionTable.flat(0),
            doctorate: TuitionTable.flat(0),
            professional: [.health: TuitionTable.flat(0),
                           .law: TuitionTable.flat(0)]),
        studentLoanInterest: 0,
        livingCostFloor: 68_000, highEarnerThreshold: 360_000,
        generalPayScale: 1.6, capitalScale: 2, schooling: .polish,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Polish leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Poland."),
        highlights: [
            LocalizedStringResource("Full-time study at public universities is free, medicine and law included.", comment: "Info bullet in the country picker describing Poland's pay and school costs."),
            LocalizedStringResource("The state student loan charges less than inflation, so its real cost is nothing.", comment: "Info bullet in the country picker describing Poland's pay and school costs."),
        ])

    /// Spain: the pay curve is fitted through the local pay of six reference jobs and the national median (28,500) and
    /// 90th-percentile (57,000) full-time wages; EUR 1,221 a month x 14 payments (12 months + 2 extra pay instalments) = EUR 17,094 a year.
    /// All figures are first-enrolment public-university prices for 60 ECTS credits a year, 2024-25 (latest published by the Ministry; 2025-26 not yet listed).
    /// Spain has no public student-loan system.
    private static let spainProfile = Profile(
        title: LocalizedStringResource("Spain", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Spain, in euros.", comment: "First line of the country picker's info text, about Spain: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇪🇸", currencySymbol: "€",
        leaderboardSuffix: "es",
        pay: PayModel(anchor: 16_200, exponent: 0.758,
                      categoryFactor: [.technology: 0.85],
                      stated: [
                        "Resident Physician": 31_000,
                        "Physician": 60_000,
                        "Senior Physician": 75_000,
                        "Surgeon": 84_000,
                        "Anesthesiologist": 78_000,
                        "Chief Medical Officer": 120_000,
                        "Dentist": 50_000,
                        "Pharmacist": 30_000,
                        "Registered Nurse": 31_000,
                        "Senior Registered Nurse": 36_500,
                        "Licensed Practical Nurse": 24_000,
                        "Nurse Practitioner": 39_500,
                        "Teacher": 40_000,
                        "Senior Teacher": 47_000,
                        "Lead Teacher": 55_000,
                        "First Officer": 60_000,
                        "Pilot": 88_500,
                        "Airline Captain": 130_000,
                      ]),
        step: 500,
        minimumAnnualPay: 17_094, minimumWageNote: LocalizedStringResource("The minimum wage (€1,221 a month, paid in 14 instalments)", comment: "Noun phrase naming the minimum-wage rule in Spain. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: TuitionTable.flat(0),
            bachelor: [.community: 717, .state: 922, .elite: 1_113],
            master: [.community: 693, .state: 1_802, .elite: 5_042],
            doctorate: [.community: 60, .state: 230, .elite: 401],
            professional: [.health: [.community: 836, .state: 997, .elite: 1_196],
                           .law: [.community: 591, .state: 839, .elite: 1_040]]),
        studentLoanInterest: 0.02,
        livingCostFloor: 18_000, highEarnerThreshold: 100_000,
        generalPayScale: 0.457, capitalScale: 0.57, schooling: .spanish,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Spanish leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Spain."),
        highlights: [
            LocalizedStringResource("Public university costs about €900 a year, and vocational training (FP) has no tuition.", comment: "Info bullet in the country picker describing Spain's pay and school costs."),
            LocalizedStringResource("The minimum wage is paid in 14 instalments, and pay is low next to the rest of western Europe.", comment: "Info bullet in the country picker describing Spain's pay and school costs."),
        ])

    /// Sweden: the pay curve is fitted through the local pay of six reference jobs and the national median (459,600) and
    /// 90th-percentile (740,400) full-time wages; 26,626 kr per month x 12 = 319,512 kr per year.
    /// Tuition is zero at every level for Swedish, EU/EEA and Swiss citizens and for people with permanent residence or a non-study residence permit (studera.nu); people who must pay face a 900 kr application fee.
    /// Both values are in percent.
    private static let swedenProfile = Profile(
        title: LocalizedStringResource("Sweden", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Sweden, in Swedish kronor.", comment: "First line of the country picker's info text, about Sweden: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇸🇪", currencySymbol: "kr",
        leaderboardSuffix: "se",
        pay: PayModel(anchor: 335_000, exponent: 0.493,
                      categoryFactor: [.technology: 0.95],
                      stated: [
                        "Resident Physician": 676_000,
                        "Physician": 1_162_000,
                        "Senior Physician": 1_452_000,
                        "Surgeon": 1_626_000,
                        "Anesthesiologist": 1_510_000,
                        "Chief Medical Officer": 2_323_000,
                        "Dentist": 643_000,
                        "Pharmacist": 576_000,
                        "Registered Nurse": 515_000,
                        "Senior Registered Nurse": 602_000,
                        "Licensed Practical Nurse": 396_000,
                        "Nurse Practitioner": 659_000,
                        "Teacher": 530_000,
                        "Senior Teacher": 621_000,
                        "Lead Teacher": 732_000,
                        "First Officer": 695_000,
                        "Pilot": 874_000,
                        "Airline Captain": 1_100_000,
                      ]),
        step: 1000,
        minimumAnnualPay: 319_512, minimumWageNote: LocalizedStringResource("The retail pay floor (26,626 kr a month, no legal minimum)", comment: "Noun phrase naming the minimum-wage rule in Sweden. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: TuitionTable.flat(0),
            bachelor: TuitionTable.flat(0),
            master: TuitionTable.flat(0),
            doctorate: TuitionTable.flat(0),
            professional: [.health: TuitionTable.flat(0),
                           .law: TuitionTable.flat(0)]),
        studentLoanInterest: 0,
        livingCostFloor: 242_400, highEarnerThreshold: 1_800_000,
        generalPayScale: 7.86, capitalScale: 8.5, schooling: .swedish,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Swedish leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Sweden."),
        highlights: [
            LocalizedStringResource("There is no legal minimum wage: union agreements set the floor, retail's among them.", comment: "Info bullet in the country picker describing Sweden's pay and school costs."),
            LocalizedStringResource("University is free, and student support is part grant, part loan.", comment: "Info bullet in the country picker describing Sweden's pay and school costs."),
        ])

    /// Turkey: the pay curve is fitted through the local pay of six reference jobs and the national median (660,000) and
    /// 90th-percentile (1,600,000) full-time wages; ₺33,030 gross per month x 12 months = ₺396,360 a year (net ₺28,075.50 a month).
    /// Day (formal) programmes at state universities charge no tuition, including the very selective Boğaziçi, ODTÜ and İTÜ; evening (ikinci öğretim), non-thesis master's and second-degree students pay fees each university sets (amounts…
    /// KYK state student loan: 0% interest on the amount borrowed (debt = amount given), repaid monthly starting two years after the standard study period ends.
    private static let turkeyProfile = Profile(
        title: LocalizedStringResource("Turkey", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from Turkey, in Turkish lira.", comment: "First line of the country picker's info text, about Turkey: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇹🇷", currencySymbol: "₺",
        leaderboardSuffix: "tr",
        pay: PayModel(anchor: 360_000, exponent: 0.886,
                      stated: [
                        "Resident Physician": 1_500_000,
                        "Physician": 3_000_000,
                        "Senior Physician": 3_750_000,
                        "Surgeon": 4_200_000,
                        "Anesthesiologist": 3_900_000,
                        "Chief Medical Officer": 6_000_000,
                        "Dentist": 1_700_000,
                        "Pharmacist": 1_200_000,
                        "Registered Nurse": 780_000,
                        "Senior Registered Nurse": 910_000,
                        "Licensed Practical Nurse": 600_000,
                        "Nurse Practitioner": 1_000_000,
                        "Teacher": 930_000,
                        "Senior Teacher": 1_090_000,
                        "Lead Teacher": 1_280_000,
                        "First Officer": 3_300_000,
                        "Pilot": 4_670_000,
                        "Airline Captain": 6_600_000,
                      ]),
        step: 10000,
        minimumAnnualPay: 396_360, minimumWageNote: LocalizedStringResource("The minimum wage (₺33,030 a month)", comment: "Noun phrase naming the minimum-wage rule in Turkey. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 0, .state: 0, .elite: 500_000],
            bachelor: [.community: 0, .state: 0, .elite: 1_295_000],
            master: [.community: 0, .state: 0, .elite: 1_295_000],
            doctorate: [.community: 0, .state: 0, .elite: 1_295_000],
            professional: [.health: [.community: 0, .state: 0, .elite: 2_000_000],
                           .law: [.community: 0, .state: 0, .elite: 1_295_000]]),
        studentLoanInterest: 0,
        livingCostFloor: 600_000, highEarnerThreshold: 2_500_000,
        generalPayScale: 11.1, capitalScale: 20, schooling: .turkish,
        leaderboardNote: LocalizedStringResource("• Scores go to their own Turkish leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: Turkey."),
        highlights: [
            LocalizedStringResource("Prices rise about 30% a year, so pay here is in 2026 lira and ages fast.", comment: "Info bullet in the country picker describing Turkey's pay and school costs."),   // i18n:ignore extracted as a catalog key; the audit reads "% a" as a format specifier
            LocalizedStringResource("State universities are free, while the top private ones cost over ₺1 million a year.", comment: "Info bullet in the country picker describing Turkey's pay and school costs."),
        ])

    /// South Korea: the pay curve is fitted through the local pay of six reference jobs and the national median (42,500,000) and
    /// 90th-percentile (94,000,000) full-time wages; 10,320 won an hour x 209 paid hours a month (40 working hours a week plus the paid weekly rest day, averaged over a month) = 2,156,880 won a month; x 12 = 25,882,560 won…
    /// All figures are annual (two semesters) tuition for a domestic student, in won, 2026 school year unless stated.
    /// Korea Student Aid Foundation (KOSAF, 한국장학재단) loans come in two forms: the income-contingent 취업 후 상환 학자금대출 (ICL) and an ordinary fixed-repayment loan, both at 1.7% a year (rates in this entry are deci…
    private static let southKoreaProfile = Profile(
        title: LocalizedStringResource("South Korea", comment: "Country name, shown in the country picker and on the score sheet."),
        introduction: LocalizedStringResource("Pay, prices and school costs from South Korea, in won.", comment: "First line of the country picker's info text, about South Korea: its pay, prices, school costs and currency. Written as a whole sentence so each language can name the country and currency naturally."), flag: "🇰🇷", currencySymbol: "₩",
        leaderboardSuffix: "kr",
        pay: PayModel(anchor: 21_000_000, exponent: 1.039,
                      categoryFactor: [.technology: 0.8],
                      stated: [
                        "Resident Physician": 80_000_000,
                        "Physician": 260_000_000,
                        "Senior Physician": 325_000_000,
                        "Surgeon": 364_000_000,
                        "Anesthesiologist": 338_000_000,
                        "Chief Medical Officer": 520_000_000,
                        "Dentist": 210_000_000,
                        "Pharmacist": 80_000_000,
                        "Registered Nurse": 55_000_000,
                        "Senior Registered Nurse": 64_300_000,
                        "Licensed Practical Nurse": 42_400_000,
                        "Nurse Practitioner": 70_400_000,
                        "Teacher": 60_000_000,
                        "Senior Teacher": 70_200_000,
                        "Lead Teacher": 82_800_000,
                        "First Officer": 100_000_000,
                        "Pilot": 141_400_000,
                        "Airline Captain": 200_000_000,
                      ]),
        step: 100000,
        minimumAnnualPay: 25_882_560, minimumWageNote: LocalizedStringResource("The minimum wage (₩10,320 an hour)", comment: "Noun phrase naming the minimum-wage rule in South Korea. It leads the picker line \"<this>: no job pays under <amount> a year.\""),
        tuition: TuitionTable(
            vocational: [.community: 6_653_100, .state: 6_653_100, .elite: 7_000_000],
            bachelor: [.community: 6_653_100, .state: 7_273_000, .elite: 8_380_000],
            master: [.community: 7_500_000, .state: 7_500_000, .elite: 10_800_000],
            doctorate: [.community: 7_500_000, .state: 7_500_000, .elite: 10_800_000],
            professional: [.health: [.community: 10_086_000, .state: 10_086_000, .elite: 11_000_000],
                           .law: [.community: 14_950_000, .state: 14_950_000, .elite: 17_700_000]]),
        studentLoanInterest: 0,
        livingCostFloor: 24_000_000, highEarnerThreshold: 160_000_000,
        generalPayScale: 719, capitalScale: 820, schooling: .korean,
        leaderboardNote: LocalizedStringResource("• Scores go to their own South Korean leaderboard.", comment: "Info bullet in the country picker: each country has its own Game Center leaderboard. Country: South Korea."),
        highlights: [
            LocalizedStringResource("The minimum wage is about 60% of the typical full-time wage.", comment: "Info bullet in the country picker describing South Korea's pay and school costs."),   // i18n:ignore extracted as a catalog key; the audit reads "% a" as a format specifier
            LocalizedStringResource("University entry rests on one November exam, the CSAT, graded 1 (best) to 9, and the state student loan charges less than inflation.", comment: "Info bullet in the country picker describing South Korea's pay and school costs."),
        ])

    // MARK: end of more countries
}

// MARK: - School names and grades

extension Country {
    /// What school is called and how it is graded here — names only. The
    /// grade itself is kept on the US 4.0 scale inside the game (it's what
    /// admission reads); `gradeLabel` shows it the way this country writes a
    /// school-leaving grade.
    struct Schooling {
        // The names are stored as catalog resources and read as plain strings, so
        // a school's name follows the player's language wherever it is shown.
        private let primarySchoolName: LocalizedStringResource
        private let middleSchoolName: LocalizedStringResource
        private let schoolLeavingName: LocalizedStringResource
        private let vocationalName: LocalizedStringResource
        private let tierNames: [EducationTier: LocalizedStringResource]
        private let gradeLabelName: LocalizedStringResource
        private let requirementResources: [Int: LocalizedStringResource]
        let scale: GradeScale

        /// The primary school's name.
        var primarySchool: String { String(localized: primarySchoolName) }
        /// The lower-secondary school's name.
        var middleSchool: String { String(localized: middleSchoolName) }
        /// The school-leaving qualification — Abitur, A-levels, Baccalauréat.
        var schoolLeaving: String { String(localized: schoolLeavingName) }
        /// A vocational qualification, before its field: "Vocational Diploma", "Ausbildung".
        var vocational: String { String(localized: vocationalName) }
        /// The three kinds of school a degree is taken at, open-access first.
        var tiers: [EducationTier: String] { tierNames.mapValues { String(localized: $0) } }
        /// What the school-leaving grade is called: "GPA", "Abitur grade".
        var gradeName: String { String(localized: gradeLabelName) }
        /// Requirement labels that read differently from the stage names
        /// ("College / Vocational" for a level-4 job); by EQF level.
        var requirementNames: [Int: String] { requirementResources.mapValues { String(localized: $0) } }

        init(primarySchool: LocalizedStringResource, middleSchool: LocalizedStringResource,
             schoolLeaving: LocalizedStringResource, vocational: LocalizedStringResource,
             tiers: [EducationTier: LocalizedStringResource], gradeName: LocalizedStringResource,
             scale: GradeScale, requirementNames: [Int: LocalizedStringResource] = [:]) {
            primarySchoolName = primarySchool
            middleSchoolName = middleSchool
            schoolLeavingName = schoolLeaving
            vocationalName = vocational
            tierNames = tiers
            gradeLabelName = gradeName
            self.scale = scale
            requirementResources = requirementNames
        }

        /// The tier's name, if this country names it.
        func tierName(_ tier: EducationTier) -> String? {
            tierNames[tier].map { String(localized: $0) }
        }
    }

    /// The ways countries write a school-leaving grade.
    enum GradeScale {
        /// 0–4 with a letter: "3.4 (B+)".
        case gpa
        /// A percentage average: "84%".
        case percent
        /// Three A-level grades: "AAB".
        case aLevels
        /// The Abitur grade, 1.0 (best) to 4.0 (pass): "1.6 (good)".
        case abitur
        /// The Bac average out of 20, with its mention: "15.8/20 (bien)".
        case baccalaureat
        /// The maturità score, 60 (pass) to 100: "85/100".
        case maturita
        /// The five-point school record average, 5.0 best: "4.4 of 5".
        case hyotei
        /// The national multi-subject test, 100–200: "185/200".
        case nmt
        /// A straight-line scale: the game's 0–4 grade mapped onto `low…high`
        /// and written in `style`. `low` may be above `high` where a smaller
        /// number is the better grade (a rank out of 9).
        case linear(low: Double, high: Double, style: LinearStyle)

        /// How a straight-line grade is written.
        enum LinearStyle {
            /// "84.5" — `digits` decimals.
            case number(digits: Int)
            /// "620/750" — over a stated maximum.
            case outOf(Int, digits: Int)
            /// "84%".
            case percent
            /// "3.0 (1 = best)", for a scale where 1 is the top grade.
            case bestIsOne
        }

        /// True where a smaller number is the better grade.
        var isInverted: Bool {
            switch self {
            case .abitur: return true
            case .linear(let low, let high, _): return low > high
            default: return false
            }
        }
    }

    var schooling: Schooling { profile.schooling }

    /// What school stage `stage` is called here. Degrees keep their
    /// international names (Bachelor, Master, Doctorate).
    func schoolName(_ stage: Level.Stage) -> String? {
        switch stage {
        case .PrimarySchool: return schooling.primarySchool
        case .MiddleSchool:  return schooling.middleSchool
        case .HighSchool:    return schooling.schoolLeaving
        case .Vocational:    return schooling.vocational
        default:             return nil
        }
    }

    /// What an education requirement at EQF `minEQF` reads as here: the
    /// country's school names below a degree, the international ones above.
    func educationLevelName(minEQF: Int) -> String {
        if let named = schooling.requirementNames[min(max(minEQF, 1), 4)], minEQF <= 4 { return named }
        switch minEQF {
        case ...1: return schooling.primarySchool
        case 2:    return schooling.middleSchool
        case 3:    return schooling.schoolLeaving
        case 4:    return schooling.vocational
        case 5:    return String(localized: "University — Bachelor's", comment: "Education requirement: a bachelor's degree.")
        case 6:    return String(localized: "University — Master's", comment: "Education requirement: a master's degree.")
        case 7:    return String(localized: "Doctorate", comment: "Education requirement: a doctorate (PhD level).")
        default:   return String(localized: "Doctorate+", comment: "Education requirement above a doctorate: post-doctoral work.")
        }
    }

    /// What a `tier` school is called here.
    func tierName(_ tier: EducationTier) -> String {
        schooling.tierName(tier) ?? tier.friendlyName
    }

    /// The school-leaving grade the game keeps on the US 4.0 scale, written the
    /// way this country writes it. Monotonic: a better grade always reads better.
    func gradeLabel(_ gpa: Double) -> String {
        let g = max(0, min(4, gpa))
        switch schooling.scale {
        case .gpa:
            return Self.gradeWithNote(Fmt.decimal(g), Player.letterGrade(g))
        case .percent:
            return Fmt.percent(Double(Int((50 + 11.25 * g).rounded())) / 100)
        case .aLevels:
            switch g {
            case 3.85...:     return "A*A*A"
            case 3.5..<3.85:  return "A*AA"
            case 3.15..<3.5:  return "AAB"
            case 2.85..<3.15: return "ABB"
            case 2.5..<2.85:  return "BBB"
            case 2.15..<2.5:  return "BBC"
            case 1.85..<2.15: return "CCC"
            default:          return "DDD"
            }
        case .abitur:
            let note = max(1.0, min(4.0, 5.0 - g))
            let word: String
            switch note {
            case ..<1.55: word = String(localized: "very good", comment: "Verbal rating of an Abitur grade of 1.0–1.5 (German sehr gut), shown in brackets after the number.")
            case ..<2.55: word = String(localized: "good", comment: "Verbal rating of an Abitur grade of 1.6–2.5 (German gut), shown in brackets after the number.")
            case ..<3.55: word = String(localized: "satisfactory", comment: "Verbal rating of an Abitur grade of 2.6–3.5 (German befriedigend), shown in brackets after the number.")
            default:      word = String(localized: "sufficient", comment: "Verbal rating of the lowest passing Abitur grades (German ausreichend), shown in brackets after the number.")
            }
            return Self.gradeWithNote(Fmt.decimal(note), word)
        case .baccalaureat:
            let note = ((8 + 2.75 * g) * 10).rounded() / 10   // the mention follows the number shown
            let mention: String
            switch note {
            case 16...: mention = String(localized: "très bien", comment: "French Baccalauréat mention for an average of 16 or more out of 20 (“with highest honours”). Shown in brackets after the number.")
            case 14...: mention = String(localized: "bien", comment: "French Baccalauréat mention for an average of 14–15.9 out of 20 (“with honours”). Shown in brackets after the number.")
            case 12...: mention = String(localized: "assez bien", comment: "French Baccalauréat mention for an average of 12–13.9 out of 20 (“with fair honours”). Shown in brackets after the number.")
            default:    mention = String(localized: "passable", comment: "French Baccalauréat: a pass without a mention (average under 12 out of 20). Shown in brackets after the number.")
            }
            return String(localized: "\(Fmt.decimal(note))/20 (\(mention))",
                          comment: "A French Baccalauréat average out of 20 with its mention in brackets, e.g. “15.8/20 (bien)”. First is the number, second the mention.")
        case .maturita:
            return String(localized: "\(max(60, Int((40 + 15 * g).rounded())))/100",
                          comment: "An Italian maturità score out of 100, e.g. “85/100”.")
        case .hyotei:
            return String(localized: "\(Fmt.decimal(1 + g)) of 5",
                          comment: "A Japanese school record average on the five-point scale, e.g. “4.4 of 5”.")
        case .nmt:
            return String(localized: "\(Int((100 + 25 * g).rounded()))/200",
                          comment: "A Ukrainian national multi-subject test (NMT) score out of 200, e.g. “185/200”.")
        case .linear(let low, let high, let style):
            let value = low + (high - low) * g / 4
            switch style {
            case .number(let digits):
                return Fmt.decimal(value, digits: digits)
            case .outOf(let maximum, let digits):
                return String(localized: "\(Fmt.decimal(value, digits: digits))/\(maximum)",
                              comment: "A grade over its maximum, e.g. “620/750” or “16.5/20”. First is the grade, second the maximum possible.")
            case .percent:
                return Fmt.percent(Double(Int(value.rounded())) / 100)
            case .bestIsOne:
                return String(localized: "\(Fmt.decimal(value)) (1 = best)",
                              comment: "A grade on a scale where 1 is the best, e.g. “3.0 (1 = best)”. The number is the grade.")
            }
        }
    }

    /// "3.4 (B+)" / "1.6 (good)": a grade with its letter or verbal rating in brackets.
    private static func gradeWithNote(_ grade: String, _ note: String) -> String {
        String(localized: "\(grade) (\(note))",
               comment: "A school grade followed by its letter or verbal rating in brackets, e.g. “3.4 (B+)” or “1.6 (good)”. First is the grade, second the rating.")
    }
}

extension Country.Schooling {
    static let american = Self(
        primarySchool: LocalizedStringResource("Primary School", comment: "School term: primary school (United States, United Kingdom, Ukraine, Australia, India)."),
        middleSchool: LocalizedStringResource("Middle School", comment: "School term: middle school / lower secondary school (United States, Canada)."),
        schoolLeaving: LocalizedStringResource("High School", comment: "School term: school-leaving qualification or high school (United States)."),
        vocational: LocalizedStringResource("Vocational Diploma", comment: "School term: vocational qualification (United States)."),
        tiers: [
            .community: LocalizedStringResource("Community College", comment: "School term: open-access college tier (United States)."),
            .state: LocalizedStringResource("State University", comment: "School term: mainstream university tier (United States, India)."),
            .elite: LocalizedStringResource("Elite / Ivy League", comment: "School term: top-tier university (United States)."),
            ],
        gradeName: LocalizedStringResource("GPA", comment: "School term: what the school-leaving grade is called (United States)."),
        scale: .gpa,
        requirementNames: [
            1: LocalizedStringResource("Primary school", comment: "School term: requirement label: primary school (United States)."),
            2: LocalizedStringResource("Middle school", comment: "School term: requirement label: middle school (United States)."),
            3: LocalizedStringResource("High school", comment: "School term: requirement label: high school (United States)."),
            4: LocalizedStringResource("College / Vocational", comment: "School term: requirement label: college / vocational (United States)."),
        ])

    static let canadian = Self(
        primarySchool: LocalizedStringResource("Elementary School", comment: "School term: primary school (Canada)."),
        middleSchool: LocalizedStringResource("Middle School", comment: "School term: middle school / lower secondary school (United States, Canada)."),
        schoolLeaving: LocalizedStringResource("High School Diploma", comment: "School term: school-leaving qualification or high school (Canada)."),
        vocational: LocalizedStringResource("College Diploma", comment: "School term: vocational qualification (Canada)."),
        tiers: [
            .community: LocalizedStringResource("College", comment: "School term: open-access college tier (Canada, Ukraine)."),
            .state: LocalizedStringResource("University", comment: "School term: mainstream university tier (Canada, United Kingdom, Ukraine, Australia)."),
            .elite: LocalizedStringResource("Top research university (U15)", comment: "School term: top-tier university (Canada)."),
            ],
        gradeName: LocalizedStringResource("Grade average", comment: "School term: what the school-leaving grade is called (Canada)."),
        scale: .percent)

    static let british = Self(
        primarySchool: LocalizedStringResource("Primary School", comment: "School term: primary school (United States, United Kingdom, Ukraine, Australia, India)."),
        middleSchool: LocalizedStringResource("Secondary School", comment: "School term: middle school / lower secondary school (United Kingdom)."),
        schoolLeaving: LocalizedStringResource("A-levels", comment: "School term: school-leaving qualification or high school (United Kingdom)."),
        vocational: LocalizedStringResource("BTEC Diploma", comment: "School term: vocational qualification (United Kingdom)."),
        tiers: [
            .community: LocalizedStringResource("Further Education College", comment: "School term: open-access college tier (United Kingdom)."),
            .state: LocalizedStringResource("University", comment: "School term: mainstream university tier (Canada, United Kingdom, Ukraine, Australia)."),
            .elite: LocalizedStringResource("Oxbridge / Russell Group", comment: "School term: top-tier university (United Kingdom)."),
            ],
        gradeName: LocalizedStringResource("A-level grades", comment: "School term: what the school-leaving grade is called (United Kingdom)."),
        scale: .aLevels)

    static let german = Self(
        primarySchool: LocalizedStringResource("Grundschule", comment: "School term: primary school (Germany)."),
        middleSchool: LocalizedStringResource("Gymnasium (lower school)", comment: "School term: middle school / lower secondary school (Germany)."),
        schoolLeaving: LocalizedStringResource("Abitur", comment: "School term: school-leaving qualification or high school (Germany)."),
        vocational: LocalizedStringResource("Ausbildung", comment: "School term: vocational qualification (Germany)."),
        tiers: [
            .community: LocalizedStringResource("Fachhochschule", comment: "School term: open-access college tier (Germany)."),
            .state: LocalizedStringResource("Universität", comment: "School term: mainstream university tier (Germany)."),
            .elite: LocalizedStringResource("Exzellenzuniversität", comment: "School term: top-tier university (Germany)."),
            ],
        gradeName: LocalizedStringResource("Abitur grade", comment: "School term: what the school-leaving grade is called (Germany)."),
        scale: .abitur)

    static let french = Self(
        primarySchool: LocalizedStringResource("École primaire", comment: "School term: primary school (France)."),
        middleSchool: LocalizedStringResource("Collège", comment: "School term: middle school / lower secondary school (France)."),
        schoolLeaving: LocalizedStringResource("Baccalauréat", comment: "School term: school-leaving qualification or high school (France)."),
        vocational: LocalizedStringResource("BTS", comment: "School term: vocational qualification (France)."),
        tiers: [
            .community: LocalizedStringResource("IUT", comment: "School term: open-access college tier (France)."),
            .state: LocalizedStringResource("Université", comment: "School term: mainstream university tier (France)."),
            .elite: LocalizedStringResource("Grande école", comment: "School term: top-tier university (France)."),
            ],
        gradeName: LocalizedStringResource("Bac average", comment: "School term: what the school-leaving grade is called (France)."),
        scale: .baccalaureat)

    static let italian = Self(
        primarySchool: LocalizedStringResource("Scuola primaria", comment: "School term: primary school (Italy)."),
        middleSchool: LocalizedStringResource("Scuola media", comment: "School term: middle school / lower secondary school (Italy)."),
        schoolLeaving: LocalizedStringResource("Diploma di maturità", comment: "School term: school-leaving qualification or high school (Italy)."),
        vocational: LocalizedStringResource("ITS Diploma", comment: "School term: vocational qualification (Italy)."),
        tiers: [
            .community: LocalizedStringResource("ITS Academy", comment: "School term: open-access college tier (Italy)."),
            .state: LocalizedStringResource("Università", comment: "School term: mainstream university tier (Italy)."),
            .elite: LocalizedStringResource("Top private university", comment: "School term: top-tier university (Italy)."),
            ],
        gradeName: LocalizedStringResource("Maturità score", comment: "School term: what the school-leaving grade is called (Italy)."),
        scale: .maturita)

    static let japanese = Self(
        primarySchool: LocalizedStringResource("Elementary School (shōgakkō)", comment: "School term: primary school (Japan)."),
        middleSchool: LocalizedStringResource("Junior High School (chūgakkō)", comment: "School term: middle school / lower secondary school (Japan)."),
        schoolLeaving: LocalizedStringResource("High School (kōkō)", comment: "School term: school-leaving qualification or high school (Japan)."), vocational: LocalizedStringResource("Senmon Diploma", comment: "School term: vocational qualification (Japan)."),
        tiers: [
            .community: LocalizedStringResource("Junior College", comment: "School term: open-access college tier (Japan, South Korea)."),
            .state: LocalizedStringResource("Private University", comment: "School term: mainstream university tier (Japan)."),
            .elite: LocalizedStringResource("National University", comment: "School term: top-tier university (Japan)."),
            ],
        gradeName: LocalizedStringResource("Grade average (hyōtei)", comment: "School term: what the school-leaving grade is called (Japan)."),
        scale: .hyotei)

    static let ukrainian = Self(
        primarySchool: LocalizedStringResource("Primary School", comment: "School term: primary school (United States, United Kingdom, Ukraine, Australia, India)."),
        middleSchool: LocalizedStringResource("Basic Secondary School", comment: "School term: middle school / lower secondary school (Ukraine)."),
        schoolLeaving: LocalizedStringResource("Atestat", comment: "School term: school-leaving qualification or high school (Ukraine)."),
        vocational: LocalizedStringResource("Professional Junior Bachelor", comment: "School term: vocational qualification (Ukraine)."),
        tiers: [
            .community: LocalizedStringResource("College", comment: "School term: open-access college tier (Canada, Ukraine)."),
            .state: LocalizedStringResource("University", comment: "School term: mainstream university tier (Canada, United Kingdom, Ukraine, Australia)."),
            .elite: LocalizedStringResource("Top university", comment: "School term: top-tier university (Ukraine)."),
            ],
        gradeName: LocalizedStringResource("NMT score", comment: "School term: what the school-leaving grade is called (Ukraine)."),
        scale: .nmt)

    // MARK: more countries (generated)

    static let australian = Self(
        primarySchool: LocalizedStringResource("Primary School", comment: "School term: primary school (United States, United Kingdom, Ukraine, Australia, India)."),
        middleSchool: LocalizedStringResource("Junior Secondary School", comment: "School term: middle school / lower secondary school (Australia)."),
        schoolLeaving: LocalizedStringResource("Senior Secondary Certificate", comment: "School term: school-leaving qualification or high school (Australia)."),
        vocational: LocalizedStringResource("TAFE Diploma", comment: "School term: vocational qualification (Australia)."),
        tiers: [
            .community: LocalizedStringResource("TAFE / Regional Institute", comment: "School term: open-access college tier (Australia)."),
            .state: LocalizedStringResource("University", comment: "School term: mainstream university tier (Canada, United Kingdom, Ukraine, Australia)."),
            .elite: LocalizedStringResource("Group of Eight", comment: "School term: top-tier university (Australia)."),
            ],
        gradeName: LocalizedStringResource("ATAR", comment: "School term: what the school-leaving grade is called (Australia)."),
        scale: .linear(low: 30, high: 99.9, style: .number(digits: 1)))

    static let brazilian = Self(
        primarySchool: LocalizedStringResource("Ensino Fundamental I", comment: "School term: primary school (Brazil)."),
        middleSchool: LocalizedStringResource("Ensino Fundamental II", comment: "School term: middle school / lower secondary school (Brazil)."),
        schoolLeaving: LocalizedStringResource("Ensino Médio", comment: "School term: school-leaving qualification or high school (Brazil)."),
        vocational: LocalizedStringResource("Curso Técnico", comment: "School term: vocational qualification (Brazil)."),
        tiers: [
            .community: LocalizedStringResource("Faculdade", comment: "School term: open-access college tier (Brazil)."),
            .state: LocalizedStringResource("Universidade pública", comment: "School term: mainstream university tier (Brazil)."),
            .elite: LocalizedStringResource("Insper / FGV / PUC", comment: "School term: top-tier university (Brazil)."),
            ],
        gradeName: LocalizedStringResource("ENEM score", comment: "School term: what the school-leaving grade is called (Brazil)."),
        scale: .linear(low: 400, high: 900, style: .number(digits: 0)))

    static let chinese = Self(
        primarySchool: LocalizedStringResource("Primary School (xiaoxue)", comment: "School term: primary school (China)."),
        middleSchool: LocalizedStringResource("Junior Middle School (chuzhong)", comment: "School term: middle school / lower secondary school (China)."),
        schoolLeaving: LocalizedStringResource("Senior High School (gaozhong)", comment: "School term: school-leaving qualification or high school (China)."),
        vocational: LocalizedStringResource("Vocational College (gaozhi)", comment: "School term: vocational qualification (China)."),
        tiers: [
            .community: LocalizedStringResource("Higher Vocational College", comment: "School term: open-access college tier (China)."),
            .state: LocalizedStringResource("Provincial University", comment: "School term: mainstream university tier (China)."),
            .elite: LocalizedStringResource("985 / Double First-Class University", comment: "School term: top-tier university (China)."),
            ],
        gradeName: LocalizedStringResource("Gaokao score", comment: "School term: what the school-leaving grade is called (China)."),
        scale: .linear(low: 300, high: 720, style: .outOf(750, digits: 0)))

    static let indian = Self(
        primarySchool: LocalizedStringResource("Primary School", comment: "School term: primary school (United States, United Kingdom, Ukraine, Australia, India)."),
        middleSchool: LocalizedStringResource("Secondary School (Class 10)", comment: "School term: middle school / lower secondary school (India)."),
        schoolLeaving: LocalizedStringResource("Class 12 (Senior Secondary)", comment: "School term: school-leaving qualification or high school (India)."),
        vocational: LocalizedStringResource("ITI / Polytechnic Diploma", comment: "School term: vocational qualification (India)."),
        tiers: [
            .community: LocalizedStringResource("Government Degree College", comment: "School term: open-access college tier (India)."),
            .state: LocalizedStringResource("State University", comment: "School term: mainstream university tier (United States, India)."),
            .elite: LocalizedStringResource("IIT / IIM / AIIMS", comment: "School term: top-tier university (India)."),
            ],
        gradeName: LocalizedStringResource("Class 12 percentage", comment: "School term: what the school-leaving grade is called (India)."),
        scale: .linear(low: 40, high: 98, style: .percent))

    static let mexican = Self(
        primarySchool: LocalizedStringResource("Primaria", comment: "School term: primary school (Mexico)."),
        middleSchool: LocalizedStringResource("Secundaria", comment: "School term: middle school / lower secondary school (Mexico)."),
        schoolLeaving: LocalizedStringResource("Bachillerato", comment: "School term: school-leaving qualification or high school (Mexico, Spain)."),
        vocational: LocalizedStringResource("Técnico Superior Universitario", comment: "School term: vocational qualification (Mexico)."),
        tiers: [
            .community: LocalizedStringResource("Universidad Tecnológica", comment: "School term: open-access college tier (Mexico)."),
            .state: LocalizedStringResource("Universidad pública", comment: "School term: mainstream university tier (Mexico, Spain)."),
            .elite: LocalizedStringResource("Tec de Monterrey / ITAM", comment: "School term: top-tier university (Mexico)."),
            ],
        gradeName: LocalizedStringResource("Promedio", comment: "School term: what the school-leaving grade is called (Mexico)."),
        scale: .linear(low: 6, high: 10, style: .number(digits: 1)))

    static let polish = Self(
        primarySchool: LocalizedStringResource("Szkoła podstawowa", comment: "School term: primary school (Poland)."),
        middleSchool: LocalizedStringResource("Szkoła podstawowa (klasy 4–8)", comment: "School term: middle school / lower secondary school (Poland)."),
        schoolLeaving: LocalizedStringResource("Matura", comment: "School term: school-leaving qualification or high school (Poland)."),
        vocational: LocalizedStringResource("Technikum", comment: "School term: vocational qualification (Poland)."),
        tiers: [
            .community: LocalizedStringResource("Uczelnia zawodowa", comment: "School term: open-access college tier (Poland)."),
            .state: LocalizedStringResource("Uniwersytet", comment: "School term: mainstream university tier (Poland)."),
            .elite: LocalizedStringResource("UW / UJ / SGH", comment: "School term: top-tier university (Poland)."),
            ],
        gradeName: LocalizedStringResource("Matura result", comment: "School term: what the school-leaving grade is called (Poland)."),
        scale: .linear(low: 30, high: 98, style: .percent))

    static let spanish = Self(
        primarySchool: LocalizedStringResource("Educación Primaria", comment: "School term: primary school (Spain)."),
        middleSchool: LocalizedStringResource("ESO", comment: "School term: middle school / lower secondary school (Spain)."),
        schoolLeaving: LocalizedStringResource("Bachillerato", comment: "School term: school-leaving qualification or high school (Mexico, Spain)."),
        vocational: LocalizedStringResource("Formación Profesional", comment: "School term: vocational qualification (Spain)."),
        tiers: [
            .community: LocalizedStringResource("FP Grado Superior", comment: "School term: open-access college tier (Spain)."),
            .state: LocalizedStringResource("Universidad pública", comment: "School term: mainstream university tier (Mexico, Spain)."),
            .elite: LocalizedStringResource("Carlos III / Pompeu Fabra / IE", comment: "School term: top-tier university (Spain)."),
            ],
        gradeName: LocalizedStringResource("Nota de admisión", comment: "School term: what the school-leaving grade is called (Spain)."),
        scale: .linear(low: 5, high: 14, style: .outOf(14, digits: 2)))

    static let swedish = Self(
        primarySchool: LocalizedStringResource("Grundskola", comment: "School term: primary school (Sweden)."),
        middleSchool: LocalizedStringResource("Högstadiet", comment: "School term: middle school / lower secondary school (Sweden)."),
        schoolLeaving: LocalizedStringResource("Gymnasieexamen", comment: "School term: school-leaving qualification or high school (Sweden)."),
        vocational: LocalizedStringResource("Yrkeshögskola", comment: "School term: vocational qualification (Sweden)."),
        tiers: [
            .community: LocalizedStringResource("Folkhögskola", comment: "School term: open-access college tier (Sweden)."),
            .state: LocalizedStringResource("Högskola / Universitet", comment: "School term: mainstream university tier (Sweden)."),
            .elite: LocalizedStringResource("KTH / Karolinska / Lund", comment: "School term: top-tier university (Sweden)."),
            ],
        gradeName: LocalizedStringResource("Meritvärde", comment: "School term: what the school-leaving grade is called (Sweden)."),
        scale: .linear(low: 10, high: 20, style: .outOf(20, digits: 1)))

    static let turkish = Self(
        primarySchool: LocalizedStringResource("İlkokul", comment: "School term: primary school (Turkey)."),
        middleSchool: LocalizedStringResource("Ortaokul", comment: "School term: middle school / lower secondary school (Turkey)."),
        schoolLeaving: LocalizedStringResource("Lise diploması", comment: "School term: school-leaving qualification or high school (Turkey)."),
        vocational: LocalizedStringResource("Önlisans (MYO)", comment: "School term: vocational qualification (Turkey)."),
        tiers: [
            .community: LocalizedStringResource("Meslek Yüksekokulu", comment: "School term: open-access college tier (Turkey)."),
            .state: LocalizedStringResource("Devlet üniversitesi", comment: "School term: mainstream university tier (Turkey)."),
            .elite: LocalizedStringResource("Bilkent / Koç / Sabancı", comment: "School term: top-tier university (Turkey)."),
            ],
        gradeName: LocalizedStringResource("Diploma notu", comment: "School term: what the school-leaving grade is called (Turkey)."),
        scale: .linear(low: 50, high: 100, style: .outOf(100, digits: 0)))

    static let korean = Self(
        primarySchool: LocalizedStringResource("Elementary School (chodeung)", comment: "School term: primary school (South Korea)."),
        middleSchool: LocalizedStringResource("Middle School (jung)", comment: "School term: middle school / lower secondary school (South Korea)."),
        schoolLeaving: LocalizedStringResource("High School (godeung)", comment: "School term: school-leaving qualification or high school (South Korea)."),
        vocational: LocalizedStringResource("Junior College (jeonmun)", comment: "School term: vocational qualification (South Korea)."),
        tiers: [
            .community: LocalizedStringResource("Junior College", comment: "School term: open-access college tier (Japan, South Korea)."),
            .state: LocalizedStringResource("Regional University", comment: "School term: mainstream university tier (South Korea)."),
            .elite: LocalizedStringResource("SKY (Seoul National, Korea, Yonsei)", comment: "School term: top-tier university (South Korea)."),
            ],
        gradeName: LocalizedStringResource("CSAT grade", comment: "School term: what the school-leaving grade is called (South Korea)."),
        scale: .linear(low: 9, high: 1, style: .bestIsOne))

    // MARK: end of more countries
}

/// Game Center leaderboard identifiers. The US board is the original one; each
/// other country's adds a suffix (see `Country.leaderboardID`).
enum GameCenterLeaderboards {
    static let wealthVelocity = "dev.dyptan.carrersim.wealth_velocity"   // i18n:ignore Game Center leaderboard id
}
