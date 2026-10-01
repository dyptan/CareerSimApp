import XCTest
@testable import CareersApp

/// Countries price the same career game in their own money. These pin that
/// the US game is exactly the reference catalogue, that Germany's prices follow
/// the rules `Country` states, and that nothing about *which* jobs exist or what
/// they require moves with the country.
final class CountryTests: XCTestCase {

    private func player(in country: Country, age: Int = 30) -> Player {
        let player = Player()
        player.difficulty = .middleClass
        player.country = country
        player.configureStart(age: 18)
        player.age = age
        player.regenerateAvailableJobs()
        return player
    }

    private func catalogue(_ country: Country) -> [String: Job] {
        Dictionary(uniqueKeysWithValues: JobCatalog.allJobs(in: country).map { ($0.id, $0) })
    }

    // MARK: The US is the reference

    func testTheUSGameIsTheReferenceCatalogueUnchanged() {
        for job in JobCatalog.allJobs(in: .unitedStates) {
            XCTAssertEqual(job.income, job.referenceIncome, job.id)
        }
        XCTAssertEqual(Country.unitedStates.money(68_000), "\(68_000.formatted(.number)) $")
        for tier in EducationTier.allCases {
            for level in [Level.Stage.Vocational, .Bachelor, .Master, .Doctorate] {
                XCTAssertEqual(Country.unitedStates.annualTuition(tier: tier, level: level, profile: .health),
                               tier.annualTuition(for: level, profile: .health))
            }
        }
        XCTAssertEqual(Country.unitedStates.studentLoanInterest, GameConstants.studentLoanAnnualInterest)
        XCTAssertEqual(Country.unitedStates.leaderboardID, GameCenterLeaderboards.wealthVelocity, "The original board stays the US one.")
    }

    // MARK: Same jobs, other money

    func testEveryCountryHasTheSameJobsAndRequirements() {
        let us = catalogue(.unitedStates), de = catalogue(.germany)
        XCTAssertEqual(Set(us.keys), Set(de.keys))
        for (id, job) in us {
            let german = de[id]!
            XCTAssertEqual(german.requirements, job.requirements, id)
            XCTAssertEqual(german.baseTitle, job.baseTitle, id)
            XCTAssertEqual(german.rung, job.rung, id)
            XCTAssertEqual(german.referenceIncome, job.income, "\(id) keeps its US reference.")
            XCTAssertEqual(german.prefersDegree, job.prefersDegree, "\(id): a rule about the role, not the money.")
        }
    }

    func testEveryGermanPayScaleNamesARealJob() {
        let ids = Set(JobCatalog.allJobs().map(\.id))
        for title in Country.germany.statedPay.keys {
            XCTAssertTrue(ids.contains(title), "“\(title)” isn't a job, so its German pay would never apply.")
        }
    }

    // MARK: German pay

    func testGermanPayIsCompressedAndNeverBelowTheMinimumWage() {
        let de = catalogue(.germany)
        for job in de.values where !job.isEntrepreneurial {
            XCTAssertGreaterThanOrEqual(job.income, Country.germany.minimumAnnualPay, job.id)
            if job.income > Country.germany.minimumAnnualPay {
                XCTAssertEqual(job.income % 500, 0, "\(job.id) should read like a pay scale.")
            }
        }
        // Low-wage work pays about as many euros as dollars; professional pay about half.
        XCTAssertEqual(de["Fast Food Worker"]!.income, Country.germany.minimumAnnualPay, "The lowest-paid US job lands on the minimum wage.")
        let engineer = de["Software Engineer"]!
        XCTAssertEqual(Double(engineer.income) / Double(engineer.referenceIncome), 0.55, accuracy: 0.08)
        XCTAssertGreaterThan(Double(de["Cashier"]!.income) / Double(de["Cashier"]!.referenceIncome),
                             Double(engineer.income) / Double(engineer.referenceIncome))
    }

    func testGermanPayScalesSetDoctorsNursesTeachersAndPilots() {
        let de = catalogue(.germany)
        for (title, pay) in Country.germany.statedPay {
            XCTAssertEqual(de[title]?.income, pay, title)
        }
        // A German residency pays a lot next to the attending job it leads to.
        let resident = de["Resident Physician"]!.income, physician = de["Physician"]!.income
        XCTAssertGreaterThan(Double(resident) / Double(physician), 0.6)
        // Teachers are civil servants in Germany: paid more, next to engineers, than in the US.
        let us = catalogue(.unitedStates)
        XCTAssertGreaterThan(Double(de["Teacher"]!.income) / Double(de["Mechanical Engineer"]!.income),
                             Double(us["Teacher"]!.income) / Double(us["Mechanical Engineer"]!.income))
    }

    /// A newcomer is offered less than the median, but never under the legal
    /// minimum — which binds in Germany, where low-paid work sits near it.
    func testNoOfferOrHireIsUnderTheMinimumWage() throws {
        let player = player(in: .germany, age: 18)
        for job in player.availableJobs where !job.isEntrepreneurial {
            XCTAssertGreaterThanOrEqual(job.offeredSalary(for: player), Country.germany.minimumAnnualPay, job.id)
        }
        let low = try XCTUnwrap(player.availableJobs.first { $0.id == "Fast Food Worker" })
        XCTAssertEqual(low.offeredSalary(for: player), Country.germany.minimumAnnualPay, "85% of the median would be under the floor.")

        // The US floor sits under every offer, so US offers are unchanged.
        let american = self.player(in: .unitedStates, age: 18)
        for job in american.availableJobs where !job.isEntrepreneurial {
            XCTAssertGreaterThan(Int((Double(job.income) * GameConstants.offerExperienceBase).rounded()), Country.unitedStates.minimumAnnualPay, job.id)
        }
    }

    func testEveryLadderStillPaysMoreAsItClimbsInGermany() {
        for (ladder, rungs) in JobCatalog.rungsByLadder[.germany]! {
            for (lower, upper) in zip(rungs, rungs.dropFirst()) {
                XCTAssertGreaterThanOrEqual(upper.income, lower.income, "\(ladder): \(upper.id) pays less than \(lower.id).")
            }
        }
    }

    // MARK: A German game

    func testAGermanGameIsPricedInEurosThroughout() throws {
        let player = player(in: .germany)
        XCTAssertTrue(player.money(45_000).hasSuffix(" €"))
        XCTAssertTrue(player.availableJobs.allSatisfy { $0.income == Country.germany.localPay(title: $0.id, category: $0.category, reference: $0.referenceIncome) })

        // A promotion moves to the German rung, not the American one.
        let junior = try XCTUnwrap(player.availableJobs.first { $0.id == "Junior Software Engineer" })
        let next = try XCTUnwrap(player.nextRung(after: junior))
        XCTAssertEqual(next.income, catalogue(.germany)[next.id]!.income)
        XCTAssertLessThan(next.income, next.referenceIncome)

        // The advisor quotes euros.
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: "Software Engineer", player: player))
        XCTAssertTrue(guide.pay.contains("€"), guide.pay)
        XCTAssertFalse(guide.pay.contains("$"), guide.pay)
        XCTAssertEqual(AdvisorCoach.family("Software Engineer", in: .germany)?.entry.income,
                       catalogue(.germany)["Junior Software Engineer"]!.income)
    }

    func testGermanUniversityIsFreeApartFromTheSemesterFeeAndLoansCarryNoInterest() {
        for tier in EducationTier.allCases {
            XCTAssertEqual(Country.germany.annualTuition(tier: tier, level: .Vocational, profile: nil), 0)
            for level in [Level.Stage.Bachelor, .Master, .Doctorate] {
                XCTAssertEqual(Country.germany.annualTuition(tier: tier, level: level, profile: .health), 600, "\(tier) \(level)")
            }
        }
        XCTAssertEqual(Country.germany.studentLoanInterest, 0)

        // Medical school: tens of thousands a year in the US, the semester fee in Germany.
        let medicine = Education(.Doctorate, profile: .health, tier: .elite)
        XCTAssertGreaterThan(medicine.annualTuition(in: .unitedStates), 50 * medicine.annualTuition(in: .germany))
    }

    /// Found by the balance simulator: the amortising formula is 0 ÷ 0 at a
    /// zero rate, which trapped the first time a German student borrowed.
    func testAnInterestFreeLoanIsRepaidInEqualPartsWithinItsTerm() {
        let payment = Player.annualLoanPayment(balance: 12_000, rate: 0)
        XCTAssertEqual(payment, 12_000 / GameConstants.loanTermYears)

        let student = player(in: .germany, age: 19)
        student.currentEducation = Education(.Bachelor, profile: .business, tier: .state)
        student.savings = 0
        let ui = AppUIState()
        ui.yearsLeftToGraduation = 3
        student.advanceYear(appUIState: ui)
        XCTAssertGreaterThan(student.studentLoan, 0, "The semester fee was borrowed.")
        XCTAssertLessThan(student.studentLoan, 1_000)
        XCTAssertEqual(student.studentLoanPayment, Player.annualLoanPayment(balance: student.studentLoan, rate: 0))
    }

    func testLivingCostsAndTheHighEarnerBandAreGerman() {
        let player = player(in: .germany)
        XCTAssertEqual(player.livingCostFloor, Country.germany.livingCostFloor)
        XCTAssertEqual(player.annualSaving(gross: Country.germany.livingCostFloor, atAge: 30), 0,
                       "Nothing is saved below the living costs.")
        let saved = player.annualSaving(gross: 200_000, atAge: 30)
        let expected = Double(Country.germany.highEarnerThreshold - Country.germany.livingCostFloor) * player.difficulty.savingsRate
            + Double(200_000 - Country.germany.highEarnerThreshold) * GameConstants.highEarnerSavingsRate
        XCTAssertEqual(Double(saved), expected, accuracy: 1)
        XCTAssertEqual(Difficulty.simplified.livingCostFloor(in: .germany), 0)
    }

    func testEndorsementsScaleWithTheCountrysPay() {
        let us = player(in: .unitedStates), de = player(in: .germany)
        for p in [us, de] { p.award("Box Office Hit", icon: "🎬", category: .entertainment, weight: 8) }
        XCTAssertGreaterThan(us.endorsementIncome, 0)
        XCTAssertEqual(Double(de.endorsementIncome), Double(us.endorsementIncome) * Country.germany.generalPayScale, accuracy: 1)
    }

    func testEachCountryHasItsOwnLeaderboard() {
        XCTAssertEqual(Set(Country.allCases.map(\.leaderboardID)).count, Country.allCases.count)
    }

    func testRestartingKeepsNothingOfTheLastCountry() {
        let player = player(in: .germany)
        player.reset()
        XCTAssertEqual(player.country, .default)
    }

    // MARK: Every country

    private var abroad: [Country] { Country.allCases.filter { $0 != .unitedStates } }

    func testEveryCountryIsOnOffer() {
        let expected = ["United States", "Australia", "Brazil", "Canada", "China", "France", "Germany", "India", "Italy", "Japan",
                        "Mexico", "Poland", "South Korea", "Spain", "Sweden", "Turkey", "Ukraine", "United Kingdom"]
        XCTAssertEqual(Set(Country.allCases.map(\.title)), Set(expected))
        XCTAssertEqual(Country.allCases.map(\.title), expected, "The US leads the picker, then A to Z.")
        XCTAssertEqual(Country.allCases.first, .default)
    }

    func testEveryCountryPricesEveryJobAtLeastAtItsMinimumWage() {
        for country in Country.allCases {
            for job in JobCatalog.allJobs(in: country) where !job.isEntrepreneurial {
                XCTAssertGreaterThanOrEqual(job.income, country.minimumAnnualPay, "\(country.title): \(job.id)")
                if country != .unitedStates, job.income > country.minimumAnnualPay, country.statedPay[job.id] == nil {
                    XCTAssertEqual(job.income % country.moneyStep, 0, "\(country.title): \(job.id) should read like a pay scale.")
                }
            }
            let player = player(in: country, age: 18)
            for job in player.availableJobs where !job.isEntrepreneurial {
                XCTAssertGreaterThanOrEqual(job.offeredSalary(for: player), country.minimumAnnualPay, "\(country.title): offer for \(job.id)")
            }
        }
    }

    func testEveryStatedPayNamesARealJobInEveryCountry() {
        let ids = Set(JobCatalog.allJobs().map(\.id))
        for country in abroad {
            for title in country.statedPay.keys {
                XCTAssertTrue(ids.contains(title), "\(country.title): “\(title)” isn't a job.")
            }
        }
    }

    func testEveryLadderPaysMoreAsItClimbsInEveryCountry() {
        for country in Country.allCases {
            for (ladder, rungs) in JobCatalog.rungsByLadder[country]! {
                for (lower, upper) in zip(rungs, rungs.dropFirst()) {
                    XCTAssertGreaterThanOrEqual(upper.income, lower.income, "\(country.title) · \(ladder): \(upper.id) pays less than \(lower.id).")
                }
            }
        }
    }

    /// The same jobs everywhere, and the rules about them don't move.
    func testEveryCountryHasTheSameJobsAndRules() {
        let us = catalogue(.unitedStates)
        for country in abroad {
            let local = catalogue(country)
            XCTAssertEqual(Set(local.keys), Set(us.keys), country.title)
            for (id, job) in us {
                XCTAssertEqual(local[id]!.requirements, job.requirements, "\(country.title): \(id)")
                XCTAssertEqual(local[id]!.prefersDegree, job.prefersDegree, "\(country.title): \(id)")
            }
        }
    }

    /// Pay is compressed in most countries: a professional earns fewer times a
    /// cashier's pay than in America. Brazil is the exception the data shows —
    /// its pay is more unequal than the US's — and Ukraine's IT is paid far
    /// above the country's other work.
    func testProfessionalPayIsCompressedOutsideTheUS() {
        func ratio(_ country: Country, _ high: String, _ low: String) -> Double {
            let jobs = catalogue(country)
            return Double(jobs[high]!.income) / Double(jobs[low]!.income)
        }
        let usLawyer = ratio(.unitedStates, "Lawyer", "Cashier")
        let moreUnequal: Set<Country> = [.brazil]
        for country in abroad where !moreUnequal.contains(country) {
            XCTAssertLessThan(ratio(country, "Lawyer", "Cashier"), usLawyer, country.title)
        }
        for country in moreUnequal {
            XCTAssertGreaterThan(ratio(country, "Lawyer", "Cashier"), usLawyer, "\(country.title) is more unequal than the US.")
        }
        XCTAssertGreaterThan(ratio(.ukraine, "Software Engineer", "Cashier"), ratio(.unitedStates, "Software Engineer", "Cashier"),
                             "Ukrainian IT pays several times what other work does — more so than IT in the US.")
    }

    func testEveryCountryHasItsOwnCurrencyTuitionAndBoard() {
        XCTAssertEqual(Set(Country.allCases.map(\.leaderboardID)).count, Country.allCases.count)
        for country in Country.allCases {
            XCTAssertTrue(country.money(1_000).hasSuffix(" \(country.currencySymbol)"))
            XCTAssertTrue(country.details.contains(country.currencySymbol), "\(country.title)'s ⓘ quotes its money.")
            XCTAssertGreaterThan(country.livingCostFloor, country.minimumAnnualPay / 2, country.title)
            for tier in EducationTier.allCases {
                for level in [Level.Stage.Vocational, .Bachelor, .Master, .Doctorate] {
                    for subject in [TertiaryProfile.health, .law, .business] {
                        XCTAssertGreaterThanOrEqual(country.annualTuition(tier: tier, level: level, profile: subject), 0)
                    }
                }
            }
        }
        // A few that set countries apart.
        XCTAssertEqual(Country.unitedKingdom.annualTuition(tier: .elite, level: .Bachelor, profile: nil),
                       Country.unitedKingdom.annualTuition(tier: .community, level: .Bachelor, profile: nil),
                       "Oxford charges the same capped fee as any English university.")
        XCTAssertLessThan(Country.japan.annualTuition(tier: .elite, level: .Bachelor, profile: nil),
                          Country.japan.annualTuition(tier: .state, level: .Bachelor, profile: nil),
                          "Japan's top national universities cost less than a private one.")
        XCTAssertLessThan(Country.france.annualTuition(tier: .state, level: .Bachelor, profile: nil), 500)
    }

    /// A whole life runs to the end in every country without trapping: amounts
    /// in yen are large, and several countries' student loans are interest-free.
    func testALifeRunsToTheEndInEveryCountry() {
        for country in Country.allCases {
            let player = player(in: country, age: 18)
            player.currentEducation = Education(.Bachelor, profile: .health, tier: .state)
            let ui = AppUIState()
            ui.yearsLeftToGraduation = 3
            while !player.hasRetired {
                player.advanceYear(appUIState: ui)
                if player.currentOccupation == nil, player.currentEducation == nil,
                   let job = player.availableJobs.filter({ !$0.isEntrepreneurial && $0.allRequirementsMet(for: player) }).max(by: { $0.income < $1.income }) {
                    _ = player.applyForJob(job, requestedSalary: job.offeredSalary(for: player))
                }
            }
            // Hiring and layoffs are rolls, so how much is left is luck; what must
            // hold is that the run got to the end with sane money.
            XCTAssertTrue(player.hasRetired, country.title)
            XCTAssertGreaterThanOrEqual(player.savings, 0, country.title)
            XCTAssertLessThan(player.savings, Int.max / 4, country.title)
        }
    }

    // MARK: School names and grades

    /// The US reads exactly as before: "3.4 (B+)" as a GPA, a High School diploma.
    func testTheUSKeepsItsGPAAndSchoolNames() {
        XCTAssertEqual(Country.unitedStates.gradeLabel(3.4), "\(Fmt.decimal(3.4)) (\(Player.letterGrade(3.4)))")
        XCTAssertEqual(Country.unitedStates.schooling.gradeName, "GPA")
        XCTAssertEqual(Education(.HighSchool).degreeName(in: .unitedStates), "High School")
        XCTAssertEqual(Country.unitedStates.tierName(.elite), EducationTier.elite.friendlyName)
    }

    func testEachCountryWritesTheGradeItsOwnWay() {
        // Numbers are written in the game's locale (a decimal comma in many), so expectations go through `Fmt`.
        XCTAssertEqual(Country.germany.gradeLabel(4.0), "\(Fmt.decimal(1.0)) (very good)", "The Abitur runs 1.0 (best) to 4.0.")
        XCTAssertEqual(Country.germany.gradeLabel(3.0), "\(Fmt.decimal(2.0)) (good)")
        XCTAssertEqual(Country.unitedKingdom.gradeLabel(4.0), "A*A*A")
        XCTAssertEqual(Country.unitedKingdom.gradeLabel(3.2), "AAB")
        XCTAssertTrue(Country.france.gradeLabel(3.0).hasSuffix("/20 (très bien)"), Country.france.gradeLabel(3.0))
        XCTAssertEqual(Country.italy.gradeLabel(4.0), "100/100")
        XCTAssertEqual(Country.italy.gradeLabel(0), "60/100", "A pass is 60.")
        XCTAssertEqual(Country.japan.gradeLabel(4.0), "\(Fmt.decimal(5.0)) of 5")
        XCTAssertEqual(Country.ukraine.gradeLabel(4.0), "200/200")
        XCTAssertEqual(Country.canada.gradeLabel(4.0), Fmt.percent(0.95))
    }

    /// A better grade always reads better — whichever way the scale runs.
    func testEveryGradeScaleOrdersGradesTheSameWay() {
        func rank(_ country: Country, _ label: String) -> Double {
            let digits = label.prefix { $0.isNumber || $0 == "." }
            if case .aLevels = country.schooling.scale {
                return label.reduce(0) { $0 + ($1 == "*" ? 1 : $1 == "A" ? 0.5 : $1 == "B" ? 0 : $1 == "C" ? -0.5 : -1) }
            }
            // Higher is better, except where the scale runs the other way (Abitur, a rank out of 9).
            return (country.schooling.scale.isInverted ? -1 : 1) * Double(digits)!
        }
        for country in Country.allCases {
            var last = -Double.infinity
            for step in 0...40 {
                let value = rank(country, country.gradeLabel(Double(step) / 10))
                XCTAssertGreaterThanOrEqual(value, last, "\(country.title) at \(Double(step) / 10)")
                last = value
            }
            XCTAssertNotEqual(country.gradeLabel(2.0), country.gradeLabel(4.0), country.title)
        }
    }

    func testSchoolsAndTiersAreCalledWhatTheCountryCallsThem() {
        XCTAssertEqual(Education(.HighSchool).degreeName(in: .germany), "Abitur")
        XCTAssertEqual(Education(.HighSchool).degreeName(in: .france), "Baccalauréat")
        XCTAssertEqual(Education(.HighSchool).degreeName(in: .unitedKingdom), "A-levels")
        XCTAssertEqual(Education(.PrimarySchool).degreeName(in: .germany), "Grundschule")
        XCTAssertEqual(Education(.Vocational, profile: .health, tier: .community).degreeName(in: .germany), "Ausbildung in Health")
        XCTAssertEqual(Country.germany.tierName(.community), "Fachhochschule")
        XCTAssertEqual(Country.japan.tierName(.elite), "National University", "Japan's cheapest tier is its most prestigious.")
        // Degrees keep their international names.
        let bachelor = Education(.Bachelor, profile: .law, tier: .state)
        XCTAssertEqual(bachelor.degreeName(in: .italy), bachelor.degreeName(in: .unitedStates))
        for country in Country.allCases {
            XCTAssertEqual(Set(EducationTier.allCases.map(country.tierName)).count, 3, "\(country.title) names each tier.")
        }
    }

    func testTheGraduationMessageUsesTheCountrysCertificateAndGrade() {
        let player = player(in: .germany, age: 18)
        player.highSchoolGrades = [3.0, 3.0]
        let message = player.graduationMessage(for: Education(.HighSchool))
        XCTAssertTrue(message.contains("Abitur"), message)
        XCTAssertTrue(message.contains("\(Fmt.decimal(2.0)) (good)"), message)
        XCTAssertFalse(message.contains("GPA"), message)
    }

    /// The grade is reported once, when school ends — not after every year.
    func testTheGradeIsLoggedOnlyAtGraduation() {
        let player = player(in: .germany, age: 15)
        player.currentEducation = Education(.HighSchool)
        let ui = AppUIState()
        player.advanceYear(appUIState: ui)
        XCTAssertEqual(player.highSchoolGrades.count, 1, "The year's grade is still recorded…")
        XCTAssertFalse(player.statusEvents.contains { $0.icon == "📝" || $0.message.contains("school year") || $0.message.contains("grade") },
                       "…but not reported: the old per-year line was “Finished the school year …”.")

        let line = player.graduationStatus(for: Education(.HighSchool))
        XCTAssertTrue(line.hasPrefix("Graduated — Abitur · Abitur grade "), line)
        XCTAssertEqual(player.graduationStatus(for: Education(.MiddleSchool)), "Graduated — Gymnasium (lower school)")
    }

    // MARK: International readers

    /// A device set to French, Ukrainian or Swiss German groups thousands with a
    /// space or apostrophe. The advisor's guard must read "45 000" as one number,
    /// or it rejects model replies that quote the pay correctly.
    func testTheAdvisorGuardReadsAmountsInEveryLocale() {
        for id in ["en_US", "en_GB", "de_DE", "fr_FR", "it_IT", "uk_UA", "ja_JP", "de_CH", "en_CA", "fr_CA", "es_ES", "pl_PL"] {
            let text = 45_000.formatted(.number.locale(Locale(identifier: id)))
            XCTAssertEqual(AdvisorGuard.numbers(in: "It pays \(text) a year to start"), ["45000"], "\(id): '\(text)'")
            let big = 1_234_567.formatted(.number.locale(Locale(identifier: id)))
            XCTAssertEqual(AdvisorGuard.numbers(in: "Net worth \(big) today"), ["1234567"], "\(id): '\(big)'")
        }
    }

    /// …without gluing neighbouring numbers in ordinary sentences together.
    func testTheAdvisorGuardStillSeparatesNeighbouringNumbers() {
        XCTAssertEqual(AdvisorGuard.numbers(in: "Skills 7 of 10, age 16, in 2026"), ["7", "10", "16", "2026"])
        XCTAssertEqual(AdvisorGuard.numbers(in: "You have 3 chances and 12% odds"), ["3", "12"])
        XCTAssertEqual(AdvisorGuard.numbers(in: "Level 4 1000 points"), ["4", "1000"], "A year-sized group is not a thousands group.")
        XCTAssertEqual(AdvisorGuard.numbers(in: "68,000 $ and 12%"), ["68000", "12"])
    }

    func testTheDrivingLicenceOpensAtTheCountrysDrivingAge() {
        let ages: [Country: Int] = [.unitedStates: 16, .canada: 16, .unitedKingdom: 17, .france: 17, .australia: 17,
                                    .germany: 18, .italy: 18, .japan: 18, .ukraine: 18, .brazil: 18, .china: 18, .india: 18,
                                    .mexico: 18, .poland: 18, .southKorea: 18, .spain: 18, .sweden: 18, .turkey: 18]
        for country in Country.allCases { XCTAssertEqual(country.drivingAge, ages[country], country.title) }

        func blockedReason(_ country: Country) -> String? {
            if case .blocked(let reason) = Training.drivers.requirements(player(in: country, age: 16)) { return reason }
            return nil
        }
        XCTAssertNil(blockedReason(.unitedStates), "A 16-year-old American may take the licence.")
        XCTAssertNil(blockedReason(.canada))
        XCTAssertEqual(blockedReason(.unitedKingdom), "Requires age 17+")
        XCTAssertEqual(blockedReason(.germany), "Requires age 18+")
        XCTAssertEqual(Training.drivers.minAge(in: .germany), 18)
        XCTAssertEqual(Training.pilot.minAge(in: .germany), Training.pilot.minAge, "Only the driving age differs.")
    }

    // MARK: Advisor notes for other countries

    private func note(_ title: String, in country: Country, voice: AdvisorVoice = .standard) -> AdvisorRealWorld.Note? {
        let family = AdvisorCoach.family(title, in: country)!
        return AdvisorRealWorld.note(for: family.entry, difficulty: .middleClass, voice: voice, country: country)
    }

    private func text(_ note: AdvisorRealWorld.Note?) -> String {
        (note?.points ?? []).flatMap { [$0.real, $0.game ?? ""] }.joined(separator: " ")
    }

    /// The figures behind the notes are American; only an American reads them.
    func testUSStatisticsAreQuotedToAmericansOnly() {
        let american = text(note("Chief Executive Officer", in: .unitedStates)) + text(note("Player", in: .unitedStates)) + text(note("Airline Pilot", in: .unitedStates))
        for figure in ["170 new CEOs", "about 73%", "about 84%", "roughly 1–5%", "1,500 flight hours"] {
            XCTAssertTrue(american.contains(figure), "The US keeps “\(figure)”.")
        }
        for country in Country.allCases where country != .unitedStates {
            let all = ["Chief Executive Officer", "Player", "Airline Pilot"].map { text(note($0, in: country)) }.joined()
            for figure in ["170", "73%", "84%", "1–5%", "1,500", " US ", "NCAA"] {
                XCTAssertFalse(all.contains(figure), "\(country.title) shouldn't hear “\(figure)”.")
            }
        }
    }

    func testTheCostOfMedicalSchoolMatchesWhatTheGameCharges() {
        // Free or nearly free: the note doesn't call it costly or talk of loans, and quotes the local fee.
        for country in [Country.germany, .france, .italy] {
            let doctor = text(note("Physician", in: country))
            XCTAssertFalse(doctor.contains("often on loans"), country.title)
            XCTAssertFalse(doctor.contains("may owe a student loan"), country.title)
            XCTAssertTrue(doctor.contains(country.currencySymbol), "\(country.title) quotes its own money.")
            XCTAssertFalse(doctor.contains("$"), country.title)
        }
        // Everywhere else, and for Americans, it still is the costly road.
        for country in [Country.unitedStates, .canada, .unitedKingdom, .japan, .ukraine] {
            XCTAssertTrue(text(note("Physician", in: country)).contains("often on loans"), country.title)
        }
        // Each country's note has exactly one cost point, never both.
        for country in Country.allCases {
            let costPoints = note("Physician", in: country)!.points.filter { $0.real.contains("cost") || $0.real.contains("Study itself") }
            XCTAssertEqual(costPoints.count, 1, country.title)
        }
    }

    func testTheJudgeNoteIsToldWhereJudgesComeFromTheBar() {
        for country in [Country.unitedStates, .canada, .unitedKingdom] {
            XCTAssertNotNil(note("Judge", in: country), country.title)
        }
        for country in [Country.germany, .france, .italy, .japan, .ukraine] {
            XCTAssertNil(note("Judge", in: country), "\(country.title): judges are a career entered after the state exam, not from the bar.")
        }
    }

    func testEveryCountryStillGetsNotesWorthReading() {
        for country in Country.allCases {
            for title in ["Chief Executive Officer", "Chief Technology Officer", "Physician", "Airline Pilot", "Player", "Investment Banker", "Research Scientist"] {
                let told = note(title, in: country)
                XCTAssertNotNil(told, "\(country.title): \(title)")
                XCTAssertFalse(told?.points.isEmpty ?? true, "\(country.title): \(title)")
            }
        }
    }

    func testTierNamesInNotesAreTheCountrysOwn() {
        let german = text(note("Chief Executive Officer", in: .germany))
        XCTAssertTrue(german.contains("Exzellenzuniversität"), german)
        XCTAssertFalse(german.contains("Ivy"), german)
        XCTAssertTrue(text(note("Chief Executive Officer", in: .unitedStates)).contains("Elite / Ivy League"))
    }

    // MARK: Fixes from the independent double-check

    /// The Bac mention is read off the number shown: 15.975 prints as 16.0, so it is "très bien".
    func testTheFrenchMentionAlwaysMatchesTheNumberShown() {
        for step in 0...4000 {
            let gpa = Double(step) / 1000
            let label = Country.france.gradeLabel(gpa)
            let shown = Double(label.prefix { $0.isNumber || $0 == "." || $0 == "," }.replacingOccurrences(of: ",", with: "."))!
            let expected = shown >= 16 ? "très bien" : shown >= 14 ? "bien" : shown >= 12 ? "assez bien" : "passable"
            XCTAssertTrue(label.hasSuffix("(\(expected))"), "\(label) at \(gpa)")
        }
        XCTAssertEqual(Country.france.gradeLabel(2.9), "\(Fmt.decimal(16.0))/20 (très bien)")
    }

    /// An American sees the requirement labels the game always used.
    func testTheUSKeepsItsRequirementLabelsExactly() {
        for eqf in 0...8 {
            let requirement = Education.Requirements(minEQF: eqf)
            XCTAssertEqual(requirement.educationLabel(in: .unitedStates), requirement.educationLabel(), "EQF \(eqf)")
        }
        XCTAssertEqual(Education.Requirements(minEQF: 4).educationLabel(in: .germany), "Ausbildung")
        XCTAssertEqual(Education.Requirements(minEQF: 3).educationLabel(in: .unitedKingdom), "A-levels")
    }

    /// The hire-gap banner named the requirement in the US's words in every country.
    func testTheHireGapNamesTheRequirementInTheCountrysWords() throws {
        let german = player(in: .germany, age: 18)
        let job = try XCTUnwrap(german.availableJobs.first { $0.educationIsMandatory && $0.requirements.education.minEQF == 4 })
        let gaps = CareerGraph.missingHardRequirements(for: job, player: german).joined(separator: " ")
        XCTAssertTrue(gaps.contains("Ausbildung"), gaps)
        XCTAssertFalse(gaps.contains("College / Vocational"), gaps)
    }

    func testTheSimpleTellingKeepsTheUSFiguresForAmericansOnly() {
        let american = text(note("Airline Pilot", in: .unitedStates, voice: .simple)) + text(note("Player", in: .unitedStates, voice: .simple))
        XCTAssertTrue(american.contains("about 1,500 hours"), american)
        XCTAssertTrue(american.contains("1 to 5 in every 100"), american)
        for country in Country.allCases where country != .unitedStates {
            let other = text(note("Airline Pilot", in: country, voice: .simple)) + text(note("Player", in: country, voice: .simple))
            XCTAssertFalse(other.contains("1,500") || other.contains("1 to 5"), country.title)
        }
    }

    /// The asked-for salary is floored at the minimum wage, and the log says what was paid.
    func testAHireIsNeverPaidUnderTheMinimumWage() throws {
        let player = player(in: .germany, age: 30)
        let job = try XCTUnwrap(player.availableJobs.first { $0.id == "Fast Food Worker" })
        var hired = false
        for _ in 0..<300 where !hired { hired = player.applyForJob(job, requestedSalary: 10_000) }
        XCTAssertTrue(hired, "A fast-food job at a modest ask is hired within a few tries.")
        XCTAssertEqual(player.currentOccupation?.annualIncome, Country.germany.minimumAnnualPay)
        XCTAssertTrue(player.statusEvents.last?.message.contains(Country.germany.money(Country.germany.minimumAnnualPay)) ?? false,
                      "The log names the pay, not the ask.")
    }

    func testVentureCapitalIsPricedInTheCountrysMoney() {
        let american = JobCatalog.allJobs(in: .unitedStates).filter { $0.targetCapital != nil }
        XCTAssertFalse(american.isEmpty)
        for country in abroad {
            var local: [String: Int] = [:]
            for job in JobCatalog.allJobs(in: country) { if let capital = job.targetCapital { local[job.id] = capital } }
            for job in american {
                XCTAssertEqual(local[job.id], country.localCapital(job.targetCapital!), "\(country.title): \(job.id)")
            }
        }
        XCTAssertEqual(Country.germany.localCapital(100_000), 90_000)
        XCTAssertEqual(Country.japan.localCapital(100_000), 12_000_000)
        XCTAssertEqual(Country.unitedStates.localCapital(100_000), 100_000)
    }

    /// Interest-free (BAföG): paid down in equal parts, never grown, gone within the term.
    func testAnInterestFreeStudentLoanIsPaidDownAndNeverGrows() throws {
        let player = player(in: .germany, age: 25)
        player.currentOccupation = try XCTUnwrap(player.availableJobs.first { $0.id == "Machinist" }).atBaseSalary()
        player.currentEducation = nil
        player.savings = 1_000_000      // so a layoff can't leave an instalment unpaid
        player.studentLoan = 10_000
        player.studentLoanPayment = Player.annualLoanPayment(balance: 10_000, rate: 0)
        XCTAssertEqual(player.studentLoanPayment, 10_000 / GameConstants.loanTermYears)
        let ui = AppUIState()
        var last = player.studentLoan
        for _ in 0..<(GameConstants.loanTermYears + 2) {
            player.advanceYear(appUIState: ui)
            XCTAssertLessThanOrEqual(player.studentLoan, last, "Interest-free: the balance never grows.")
            last = player.studentLoan
        }
        XCTAssertEqual(player.studentLoan, 0, "…and is repaid within the loan term.")
    }

    // MARK: More countries

    /// Each new country writes the school-leaving grade the way its own system does, from its pass mark to its top.
    func testTheNewCountriesWriteTheirGradeScalesFromPassToTop() {
        let d = { (value: Double, digits: Int) in Fmt.decimal(value, digits: digits) }   // locale-aware, like the labels
        let ends: [Country: (String, String)] = [
            .australia: (d(30, 1), d(99.9, 1)), .mexico: (d(6, 1), d(10, 1)),
            .india: (Fmt.percent(0.40), Fmt.percent(0.98)), .china: ("300/750", "720/750"),
            .brazil: ("400", "900"), .spain: ("\(d(5, 2))/14", "\(d(14, 2))/14"), .sweden: ("\(d(10, 1))/20", "\(d(20, 1))/20"),
            .poland: (Fmt.percent(0.30), Fmt.percent(0.98)), .turkey: ("50/100", "100/100"),
            .southKorea: ("\(d(9, 1)) (1 = best)", "\(d(1, 1)) (1 = best)"),
        ]
        for (country, (bottom, top)) in ends {
            XCTAssertEqual(country.gradeLabel(0), bottom, country.title)
            XCTAssertEqual(country.gradeLabel(4), top, country.title)
        }
    }

    /// Money-sized steps suit the currency: a salary slider in yen or won can't move in 500s.
    func testTheMoneyStepSuitsTheCurrency() {
        for country in Country.allCases {
            XCTAssertGreaterThanOrEqual(country.minimumAnnualPay / country.moneyStep, 20,
                                        "\(country.title): a step this big would make the minimum wage a handful of notches.")
        }
        XCTAssertGreaterThan(Country.japan.moneyStep, Country.germany.moneyStep)
    }

    /// The executives follow each country's pay curve rather than top-company total pay (found by the
    /// research: 3x–36x the curve), so a CEO is paid like a senior professional there, not like a founder.
    func testExecutivesAreNotPricedOnTotalRemuneration() {
        for country in abroad where country.statedPay["Chief Executive Officer"] == nil {
            let jobs = catalogue(country)
            let ceo = Double(jobs["Chief Executive Officer"]!.income)
            let median = Double(jobs["Cashier"]!.income)
            // The US is 12x; unequal Brazil 26x. Top-company total pay would be in the hundreds.
            XCTAssertLessThan(ceo / median, 40, "\(country.title): a CEO at \(Int(ceo / median)) cashiers' pay.")
        }
    }
}

