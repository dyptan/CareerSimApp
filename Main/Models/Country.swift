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
    case canada
    case france
    case germany
    case italy
    case japan
    case ukraine
    case unitedKingdom

    var id: String { rawValue }

    /// The country a new game starts in unless the player picks another.
    static let `default`: Country = .unitedStates

    var title: String { profile.title }
    var flag: String { profile.flag }
    var currencySymbol: String { profile.currencySymbol }

    /// An amount the way the game writes money: "68,000 $", "45.000 €",
    /// "4,380,000 ¥". The grouping follows the device's locale, as it always has.
    func money(_ amount: Int) -> String {
        "\(amount.formatted(.number)) \(currencySymbol)"
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

    /// What the country changes, for the picker's ⓘ.
    var details: String {
        let tuition = { (tier: EducationTier) in self.annualTuition(tier: tier, level: .Bachelor, profile: nil) }
        guard profile.pay != nil else {
            return """
                Pay, prices and school costs from the United States, in dollars.

                • Pay is the national median for each job.
                • Universities charge tuition — from about \(money(tuition(.community))) a year at a community college to \(money(tuition(.elite))) or more at an elite one — so many students borrow.
                """
        }
        var lines = ["Pay, prices and school costs from \(profile.titleInSentenceOrTitle), in \(profile.currencyName)."]
        lines.append("")
        lines += profile.highlights.map { "• \($0)" }
        lines.append("• \(profile.minimumWageNote): no job pays under \(money(minimumAnnualPay)) a year.")
        lines.append("• A university year costs about \(money(tuition(.state))), or \(money(tuition(.elite))) at an elite school.")
        lines.append("• Living costs take the first \(money(livingCostFloor)) of pay.")
        lines.append("• Scores go to their own \(profile.adjective) leaderboard.")
        lines.append("")
        lines.append("Still American for now: school ages and tracks, licence names and most of the advisor's real-world facts.")
        return lines.joined(separator: "\n")
    }

    // MARK: - Profiles

    /// Everything that makes a country's money its own.
    struct Profile {
        let title: String
        /// "the United Kingdom", "Germany".
        var titleInSentence: String? = nil
        let adjective: String
        let flag: String
        let currencySymbol: String
        let currencyName: String
        let leaderboardSuffix: String
        /// nil for the US: the catalogue already is its pay.
        let pay: PayModel?
        let step: Int
        let minimumAnnualPay: Int
        let minimumWageNote: String
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
        /// What sets the country apart, for the picker's ⓘ.
        let highlights: [String]

        var titleInSentenceOrTitle: String { titleInSentence ?? title }
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
        case .canada:        return Self.canadaProfile
        case .france:        return Self.franceProfile
        case .germany:       return Self.germanyProfile
        case .italy:         return Self.italyProfile
        case .japan:         return Self.japanProfile
        case .ukraine:       return Self.ukraineProfile
        case .unitedKingdom: return Self.unitedKingdomProfile
        }
    }

    private static let unitedStatesProfile = Profile(
        title: "United States", titleInSentence: "the United States", adjective: "American",
        flag: "🇺🇸", currencySymbol: "$", currencyName: "dollars", leaderboardSuffix: "",
        pay: nil, step: 500,
        // The federal $7.25 an hour — under every catalogue offer, so it never binds.
        minimumAnnualPay: 15_080, minimumWageNote: "The federal minimum wage",
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
        title: "Germany", adjective: "German", flag: "🇩🇪", currencySymbol: "€", currencyName: "euros",
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
        minimumAnnualPay: 28_900, minimumWageNote: "The minimum wage (€13.90 an hour)",
        tuition: TuitionTable(vocational: TuitionTable.flat(0), bachelor: TuitionTable.flat(600),
                              master: TuitionTable.flat(600), doctorate: TuitionTable.flat(600)),
        studentLoanInterest: 0,
        // Rent and food take about €20,000 net — about €28,000 gross.
        livingCostFloor: 28_000, highEarnerThreshold: 150_000,
        generalPayScale: 0.6, capitalScale: 0.9,
        schooling: .german,
        highlights: [
            "Everyday jobs pay about the same number of euros as dollars in the US; professional jobs pay roughly half. Doctors, nurses, teachers and pilots follow their German pay scales.",
            "Public universities, the famous ones included, charge only a semester fee, and student loans are interest-free.",
        ])

    /// Statistics Canada earnings for the curve (C$36k at $30k, C$63k at $60k,
    /// C$118k at $130k, C$200k at $250k); provincial fee schedules for
    /// physicians (gross billings), collective agreements for nurses and
    /// teachers. Tuition is Statistics Canada's domestic average (about C$7,400
    /// for an undergraduate year), with medicine and law priced on their own.
    /// The federal share of a student loan has been interest-free since 2023.
    private static let canadaProfile = Profile(
        title: "Canada", adjective: "Canadian", flag: "🇨🇦", currencySymbol: "C$", currencyName: "Canadian dollars",
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
        minimumAnnualPay: 37_750, minimumWageNote: "The federal minimum wage (C$18.15 an hour)",
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
        highlights: [
            "Pay is close to the US in Canadian dollars for everyday jobs, and lower for professionals. Doctors bill provincial health plans and earn among the most.",
            "Tuition is moderate, and the federal part of a student loan is interest-free.",
        ])

    /// ONS Annual Survey of Hours and Earnings for the curve (£25k at $30k,
    /// £39k at $60k, £63k at $130k, £95k at $250k); NHS Agenda for Change and the
    /// 2025–26 medical pay awards (resident doctors, consultants), the teachers'
    /// pay award. English universities may charge up to £9,790 a year (2026/27) — the
    /// same at Oxford as anywhere — and most PhDs are funded. A Plan 5 student
    /// loan carries inflation-only interest.
    private static let unitedKingdomProfile = Profile(
        title: "United Kingdom", titleInSentence: "the United Kingdom", adjective: "British",
        flag: "🇬🇧", currencySymbol: "£", currencyName: "pounds", leaderboardSuffix: "uk",
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
        minimumAnnualPay: 24_800, minimumWageNote: "The National Living Wage (£12.71 an hour)",
        tuition: TuitionTable(
            vocational: TuitionTable.flat(0), bachelor: TuitionTable.flat(9_790),
            master: [.community: 10_000, .state: 12_000, .elite: 18_000],
            doctorate: TuitionTable.flat(0),
            professional: [.health: TuitionTable.flat(9_790), .law: [.community: 12_000, .state: 15_000, .elite: 18_000]]),
        studentLoanInterest: 0,
        livingCostFloor: 26_000, highEarnerThreshold: 125_000,
        generalPayScale: 0.65, capitalScale: 0.75, drivingAge: 17,
        schooling: .british,
        highlights: [
            "Professional pay is well under the US; NHS doctors, nurses and teachers follow national pay scales.",
            "Every English university charges up to £9,790 a year — the famous ones too — and most PhDs are funded.",
        ])

    /// INSEE salary data for the curve (€22k at $30k, €34k at $60k, €56k at
    /// $130k, €85k at $250k); hospital pay grids for doctors and nurses, the
    /// national teaching grid. Public universities charge the national fees
    /// (€178 a year for a licence, €254 for a master's, €397 for a doctorate,
    /// plus the €105 student-life levy); the grandes écoles of business charge
    /// far more.
    private static let franceProfile = Profile(
        title: "France", adjective: "French", flag: "🇫🇷", currencySymbol: "€", currencyName: "euros",
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
        minimumAnnualPay: 22_400, minimumWageNote: "The minimum wage (SMIC, on a 35-hour week)",
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
        highlights: [
            "Pay is compressed: the minimum wage is high and professional pay far under the US. Hospital doctors, nurses and teachers follow national grids.",
            "Public universities cost a few hundred euros a year; the elite business schools are the exception.",
        ])

    /// ISTAT earnings for the curve (€20k at $30k, €30k at $60k, €48k at $130k,
    /// €70k at $250k); the national health-service contract for doctors and
    /// nurses, the school contract for teachers. Italy has no statutory minimum
    /// wage: collective agreements set the floor. Public universities charge by
    /// family income (about €1,700 a year on average); Bocconi and the private
    /// medical schools charge far more.
    private static let italyProfile = Profile(
        title: "Italy", adjective: "Italian", flag: "🇮🇹", currencySymbol: "€", currencyName: "euros",
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
        minimumAnnualPay: 18_000, minimumWageNote: "Collective agreements set the floor (Italy has no legal minimum wage)",
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
        highlights: [
            "Pay is among the lowest in western Europe, and professional pay is much less than in the US. Doctors, nurses and teachers are paid on national contracts.",
            "Public universities charge by family income; the private elite schools charge much more.",
        ])

    /// MHLW wage census for the curve (¥2.8M at $30k, ¥4.4M at $60k, ¥7.2M at
    /// $130k, ¥11M at $250k); pay is seniority-based and compressed. National
    /// universities charge the standard ¥535,800 a year, less than most private
    /// universities (the University of Tokyo raised its undergraduate fee to
    /// ¥642,960 for 2025 entrants — the top national tier is priced at the
    /// standard rate); private medical schools cost millions of yen a year.
    /// JASSO loans are interest-free or nearly so.
    private static let japanProfile = Profile(
        title: "Japan", adjective: "Japanese", flag: "🇯🇵", currencySymbol: "¥", currencyName: "yen",
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
        minimumAnnualPay: 2_330_000, minimumWageNote: "The minimum wage (¥1,121 an hour on average)",
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
        highlights: [
            "Pay rises with seniority and is compressed: professionals earn far less than in the US.",
            "The top national universities cost less than most private ones; private medical schools cost millions of yen a year.",
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
        title: "Ukraine", adjective: "Ukrainian", flag: "🇺🇦", currencySymbol: "₴", currencyName: "hryvnias",
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
        minimumAnnualPay: 103_800, minimumWageNote: "The minimum wage (₴8,647 a month)",
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
        highlights: [
            "Most pay is far below western Europe, but IT pays well above the national average — the best-paid path in the country.",
            "University is free on a state-funded place; these are the fees for a paid (contract) place.",
            "Priced as in peacetime: the war's effects on work and flights aren't in the game.",
        ])
}

// MARK: - School names and grades

extension Country {
    /// What school is called and how it is graded here — names only. The
    /// grade itself is kept on the US 4.0 scale inside the game (it's what
    /// admission reads); `gradeLabel` shows it the way this country writes a
    /// school-leaving grade.
    struct Schooling {
        let primarySchool: String
        let middleSchool: String
        /// The school-leaving qualification — Abitur, A-levels, Baccalauréat.
        let schoolLeaving: String
        /// A vocational qualification, before its field: "Vocational Diploma", "Ausbildung".
        let vocational: String
        /// The three kinds of school a degree is taken at, open-access first.
        let tiers: [EducationTier: String]
        /// What the school-leaving grade is called: "GPA", "Abitur grade".
        let gradeName: String
        let scale: GradeScale
        /// Requirement labels that read differently from the stage names
        /// ("College / Vocational" for a level-4 job); by EQF level.
        var requirementNames: [Int: String] = [:]
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
        case 5:    return "University — Bachelor's"
        case 6:    return "University — Master's"
        case 7:    return "Doctorate"
        default:   return "Doctorate+"
        }
    }

    /// What a `tier` school is called here.
    func tierName(_ tier: EducationTier) -> String {
        schooling.tiers[tier] ?? tier.friendlyName
    }

    /// The school-leaving grade the game keeps on the US 4.0 scale, written the
    /// way this country writes it. Monotonic: a better grade always reads better.
    func gradeLabel(_ gpa: Double) -> String {
        let g = max(0, min(4, gpa))
        switch schooling.scale {
        case .gpa:
            return "\(String(format: "%.1f", g)) (\(Player.letterGrade(g)))"
        case .percent:
            return "\(Int((50 + 11.25 * g).rounded()))%"
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
            case ..<1.55: word = "very good"
            case ..<2.55: word = "good"
            case ..<3.55: word = "satisfactory"
            default:      word = "sufficient"
            }
            return "\(String(format: "%.1f", note)) (\(word))"
        case .baccalaureat:
            let note = ((8 + 2.75 * g) * 10).rounded() / 10   // the mention follows the number shown
            let mention: String
            switch note {
            case 16...: mention = "très bien"
            case 14...: mention = "bien"
            case 12...: mention = "assez bien"
            default:    mention = "passable"
            }
            return "\(String(format: "%.1f", note))/20 (\(mention))"
        case .maturita:
            return "\(max(60, Int((40 + 15 * g).rounded())))/100"
        case .hyotei:
            return "\(String(format: "%.1f", 1 + g)) of 5"
        case .nmt:
            return "\(Int((100 + 25 * g).rounded()))/200"
        }
    }
}

extension Country.Schooling {
    static let american = Self(
        primarySchool: "Primary School", middleSchool: "Middle School", schoolLeaving: "High School",
        vocational: "Vocational Diploma",
        tiers: [.community: "Community College", .state: "State University", .elite: "Elite / Ivy League"],
        gradeName: "GPA", scale: .gpa,
        requirementNames: [1: "Primary school", 2: "Middle school", 3: "High school", 4: "College / Vocational"])

    static let canadian = Self(
        primarySchool: "Elementary School", middleSchool: "Middle School", schoolLeaving: "High School Diploma",
        vocational: "College Diploma",
        tiers: [.community: "College", .state: "University", .elite: "Top research university (U15)"],
        gradeName: "Grade average", scale: .percent)

    static let british = Self(
        primarySchool: "Primary School", middleSchool: "Secondary School", schoolLeaving: "A-levels",
        vocational: "BTEC Diploma",
        tiers: [.community: "Further Education College", .state: "University", .elite: "Oxbridge / Russell Group"],
        gradeName: "A-level grades", scale: .aLevels)

    static let german = Self(
        primarySchool: "Grundschule", middleSchool: "Gymnasium (lower school)", schoolLeaving: "Abitur",
        vocational: "Ausbildung",
        tiers: [.community: "Fachhochschule", .state: "Universität", .elite: "Exzellenzuniversität"],
        gradeName: "Abitur grade", scale: .abitur)

    static let french = Self(
        primarySchool: "École primaire", middleSchool: "Collège", schoolLeaving: "Baccalauréat",
        vocational: "BTS",
        tiers: [.community: "IUT", .state: "Université", .elite: "Grande école"],
        gradeName: "Bac average", scale: .baccalaureat)

    static let italian = Self(
        primarySchool: "Scuola primaria", middleSchool: "Scuola media", schoolLeaving: "Diploma di maturità",
        vocational: "ITS Diploma",
        tiers: [.community: "ITS Academy", .state: "Università", .elite: "Top private university"],
        gradeName: "Maturità score", scale: .maturita)

    static let japanese = Self(
        primarySchool: "Elementary School (shōgakkō)", middleSchool: "Junior High School (chūgakkō)",
        schoolLeaving: "High School (kōkō)", vocational: "Senmon Diploma",
        tiers: [.community: "Junior College", .state: "Private University", .elite: "National University"],
        gradeName: "Grade average (hyōtei)", scale: .hyotei)

    static let ukrainian = Self(
        primarySchool: "Primary School", middleSchool: "Basic Secondary School", schoolLeaving: "Atestat",
        vocational: "Professional Junior Bachelor",
        tiers: [.community: "College", .state: "University", .elite: "Top university"],
        gradeName: "NMT score", scale: .nmt)
}

/// Game Center leaderboard identifiers. The US board is the original one; each
/// other country's adds a suffix (see `Country.leaderboardID`).
enum GameCenterLeaderboards {
    static let wealthVelocity = "dev.dyptan.carrersim.wealth_velocity"
}
