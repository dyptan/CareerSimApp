import XCTest
@testable import CareersApp

/// End-to-end coverage of the **launch a venture** flow — the founder path a
/// player walks from the Ventures sheet: stake capital through `foundVenture`,
/// the venture becomes their occupation, and they keep playing year over year
/// (see `Player.foundVenture` and `Player.advanceYear`).
///
/// Ventures are concrete, industry-specific one-off plays (no auto-climbing
/// ladder). A business always opens; how well it survives turns on the
/// founder's preparation — experience in that industry and soft-skill fit, with
/// capital a supporting factor (`Job.founderSuccessProbability`). These tests also drive the code path
/// behind the old crash report ("the app crashes when I launch a venture"):
/// they found a venture and advance many years, asserting state stays
/// well-formed the whole way. A crash in that path surfaces here as a failure.
final class VentureLaunchTests: XCTestCase {

    // MARK: - Fixtures

    /// The most accessible venture — a Coffee Roastery needs only a little retail
    /// experience, so it's the simplest reproduction of "launch a venture".
    private func coffeeRoasteryJob() throws -> Job {
        try XCTUnwrap(
            JobCatalog.allJobs().first { $0.isEntrepreneurial && $0.baseTitle == "Specialty Coffee Roastery" },
            "The catalogue is missing the Specialty Coffee Roastery venture."
        )
    }

    /// A player in a realistic (non-Simplified) mode set up the way the app does
    /// on launch — starting age 18 with the matching K-12 record — plus a war
    /// chest to stake, retail experience to clear the gate, and strong founder
    /// soft skills so a funded launch has real odds.
    private func realisticFounder(savings: Int, retailYears: Int = 6) -> Player {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.regenerateAvailableJobs()
        player.savings = savings
        player.experience[.retail] = retailYears
        // Pin the economy to neutral: these tests are about preparation, and a
        // seeded business cycle would otherwise move every founder's odds.
        player.pinNeutralEconomy()
        for kp in [
            \SoftSkills.creativityAndInsightfulThinking, \SoftSkills.communicationAndNetworking, \SoftSkills.persuasionAndNegotiation, \SoftSkills.visionaryThinkingAndAmbition, \SoftSkills.carefulnessAndAttentionToDetail, \SoftSkills.tinkeringAndFingerPrecision, \SoftSkills.timeManagementAndPlanning, \SoftSkills.selfDisciplineAndPerseverance,
        ] {
            player.softSkills[keyPath: kp] = 8
        }
        return player
    }

    // MARK: - Founding

    /// A funded, experienced founder has real (non-zero, capped) launch odds —
    /// the value the "Launch your venture" screen shows before they commit.
    func testFundedExperiencedVentureHasStrongOdds() throws {
        let player = realisticFounder(savings: 100_000)
        let job = try coffeeRoasteryJob()
        let p = job.founderSuccessProbability(for: player, investedCapital: job.targetCapital ?? 0)
        XCTAssertGreaterThan(p, 0.5, "A funded, experienced, skilled founder should have strong odds.")
        XCTAssertLessThanOrEqual(p, GameConstants.founderMaxSuccess,
                                 "Founding is a gamble — odds top out at the founder ceiling, not near certainty.")
    }

    /// Capital is the only hard requirement. With no industry experience at all a
    /// launch is still *allowed* — it is simply much less likely to work than the
    /// same attempt by a seasoned founder.
    func testNoIndustryExperienceIsALongShotNotABlocker() throws {
        let job = try coffeeRoasteryJob()
        let green = realisticFounder(savings: 200_000, retailYears: 0)
        let seasoned = realisticFounder(savings: 200_000, retailYears: 10)
        let stake = job.targetCapital ?? 0

        let greenOdds = job.founderSuccessProbability(for: green, investedCapital: stake)
        XCTAssertGreaterThan(greenOdds, 0,
                             "Experience must not gate a launch — capital is the only hard requirement.")
        XCTAssertLessThan(greenOdds,
                          job.founderSuccessProbability(for: seasoned, investedCapital: stake),
                          "Turning up with no experience should cost real odds.")
        XCTAssertTrue(job.allRequirementsMet(for: green) || job.isEntrepreneurial,
                      "A venture is never closed by a requirement gate.")
    }

    /// With nothing to stake there is no launch — the one thing that does block.
    func testNoCapitalIsTheOnlyHardBlocker() throws {
        let job = try coffeeRoasteryJob()
        let broke = realisticFounder(savings: 0, retailYears: 10)
        broke.currentOccupation = nil   // no income, so no borrowing headroom either
        XCTAssertEqual(broke.maxVentureStake, 0,
                       "This test needs a founder with nothing to stake.")
        XCTAssertFalse(broke.foundVenture(job, investedCapital: 0),
                       "A venture with no capital behind it cannot be founded.")
    }

    /// Experience meaningfully moves the odds: a seasoned founder beats a
    /// barely-qualified one, all else equal.
    func testMoreExperienceRaisesOdds() throws {
        let job = try coffeeRoasteryJob()
        let rookie = realisticFounder(savings: 100_000, retailYears: 1)
        let veteran = realisticFounder(savings: 100_000, retailYears: 12)
        let stake = job.targetCapital ?? 0
        XCTAssertGreaterThan(
            job.founderSuccessProbability(for: veteran, investedCapital: stake),
            job.founderSuccessProbability(for: rookie, investedCapital: stake),
            "Deeper industry experience should raise launch odds."
        )
    }

    /// A stake smaller than the founder screen's investment step (500) is still a
    /// valid founding — the case that crashed the launch slider (range
    /// `0...savings` narrower than a 500 step) for an early player with only a
    /// few hundred saved. The model must accept it so the UI has something valid.
    func testTinyStakeBelowStepIsAValidFounding() throws {
        let job = try coffeeRoasteryJob()
        var launched = false
        for _ in 0..<500 {
            let player = realisticFounder(savings: 400)   // < 500 UI step, < target
            let p = job.founderSuccessProbability(for: player, investedCapital: 400)
            XCTAssertGreaterThan(p, 0.0, "A small but positive stake should still give positive odds.")
            XCTAssertTrue(p.isFinite, "Founding odds must be finite for any stake.")
            if player.foundVenture(job, investedCapital: 400) {
                XCTAssertEqual(player.currentOccupation?.baseTitle, "Specialty Coffee Roastery",
                               "A small-stake launch still makes the player the founder.")
                launched = true
                break
            }
        }
        XCTAssertTrue(launched, "A small-stake Coffee Roastery should be launchable.")
    }

    /// Launching a venture (the success branch of `foundVenture`) makes the
    /// player the founder — it becomes their occupation with the stake committed
    /// — and unlocks the Boardroom.
    func testFoundingMakesPlayerFounder() throws {
        let job = try coffeeRoasteryJob()
        var launched = false
        for _ in 0..<500 {
            let player = realisticFounder(savings: 100_000)
            if player.foundVenture(job, investedCapital: 100_000) {
                XCTAssertEqual(player.currentOccupation?.baseTitle, "Specialty Coffee Roastery",
                               "Founding makes the player the founder.")
                XCTAssertLessThan(player.savings, 100_000, "The stake should be committed from savings.")
                XCTAssertTrue(player.canMakeExecutiveDecisions,
                              "Owning a venture unlocks the Boardroom.")
                launched = true
                break
            }
        }
        XCTAssertTrue(launched, "A funded Coffee Roastery should launch within many attempts.")
    }

    /// A business always opens: the stake is committed, the player becomes its
    /// founder, and year one pays only the first step of the income ramp.
    func testFoundingAlwaysOpensAndRampsIncome() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 10_000, retailYears: 0)
        XCTAssertTrue(player.foundVenture(job, investedCapital: 4_000),
                      "Even an unprepared founder opens the doors.")
        XCTAssertEqual(player.savings, 6_000, "The stake is committed from savings.")
        XCTAssertEqual(player.currentOccupation?.baseTitle, job.baseTitle)
        XCTAssertEqual(player.ventureMatureIncome, job.annualIncome)
        XCTAssertEqual(player.currentOccupation?.annualIncome,
                       Int((Double(job.annualIncome) * GameConstants.ventureIncomeRamp[0]).rounded()),
                       "Year one pays a fraction of the full income.")
    }

    /// The fold risk falls as a business establishes itself and with better
    /// preparation, and an average business lasts five years about half the
    /// time — the shape of real US business survival.
    func testSurvivalCurveMatchesRealBusinesses() {
        XCTAssertGreaterThan(Player.ventureFoldRisk(year: 1, preparation: 0.5),
                             Player.ventureFoldRisk(year: 4, preparation: 0.5))
        XCTAssertGreaterThan(Player.ventureFoldRisk(year: 1, preparation: 0),
                             Player.ventureFoldRisk(year: 1, preparation: 1))
        let fiveYear = (1...5).reduce(1.0) { $0 * (1 - Player.ventureFoldRisk(year: $1, preparation: 0.5)) }
        XCTAssertGreaterThan(fiveYear, 0.4)
        XCTAssertLessThan(fiveYear, 0.65)
    }

    /// Founders' pay moves with the business, not a promotion ladder.
    func testFoundersAreNotPromoted() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 60_000)
        player.foundVenture(job, investedCapital: 60_000)
        let venture = try XCTUnwrap(player.currentOccupation)
        XCTAssertFalse(player.promotionOdds(for: venture).promotes)
        XCTAssertEqual(player.promotionChance(for: venture), 0)
    }

    /// Only a scalable venture can raise a round, and a closed round grows the
    /// company rather than paying the founder cash.
    func testInvestmentRoundsAreForScalableVenturesAndPayNoCash() throws {
        let roastery = try coffeeRoasteryJob()
        let small = realisticFounder(savings: 60_000)
        small.foundVenture(roastery, investedCapital: 60_000)
        XCTAssertFalse(small.canRaiseInvestmentRound, "A roastery doesn't raise venture capital.")

        let saas = try XCTUnwrap(JobCatalog.allJobs().first { $0.baseTitle == "SaaS App Startup" })
        let decision = try XCTUnwrap(ExecutiveDecisionCatalog.byId["investmentRound"])
        for _ in 0..<60 {
            let founder = realisticFounder(savings: 80_000)
            founder.foundVenture(saas, investedCapital: 80_000)
            XCTAssertFalse(founder.canRaiseInvestmentRound, "Investors want a year of traction first.")
            founder.ventureFoundedAge = founder.age - 1
            XCTAssertTrue(founder.canRaiseInvestmentRound)
            let savings = founder.savings
            let valueBefore = founder.shareStakeValue()
            let outcome = founder.resolveExecutiveDecision(decision)
            XCTAssertEqual(founder.savings, savings, "A round's money goes into the company.")
            XCTAssertEqual(outcome.cash, 0)
            if outcome.success {
                XCTAssertGreaterThan(founder.shareStakeValue(), valueBefore,
                                     "A closed round makes the stake worth more.")
                return
            }
        }
        XCTFail("A round should close at least once in 60 tries.")
    }

    /// Leaving the venture — here, taking a job — ends the founder's bookkeeping.
    func testLeavingAVentureClearsItsState() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 60_000)
        player.foundVenture(job, investedCapital: 60_000)
        XCTAssertNotNil(player.ventureFoundedAge)
        player.currentOccupation = try dayJob(income: 40_000)
        XCTAssertNil(player.ventureFoundedAge)
        XCTAssertEqual(player.ventureStake, 0)
    }

    // MARK: - Venture loans

    /// A salaried non-founder day job with a known income, for loan-headroom math.
    private func dayJob(income: Int) throws -> Job {
        var job = try XCTUnwrap(JobCatalog.allJobs().first { !$0.isEntrepreneurial },
                                "The catalogue has no salaried role.")
        job.annualIncome = income
        return job
    }

    /// Staking beyond savings borrows the shortfall: savings fund the stake
    /// first, the rest — up to 2× income — is booked as an outstanding loan,
    /// whatever the launch roll says.
    func testStakeBeyondSavingsBooksALoan() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 10_000)
        player.currentOccupation = try dayJob(income: 50_000)

        XCTAssertEqual(player.maxVentureLoan, 100_000, "A bank lends 2× annual income.")
        XCTAssertEqual(player.maxVentureStake, 110_000, "Savings plus loan headroom.")
        XCTAssertEqual(player.borrowedPortion(ofStake: 110_000), 100_000)

        player.foundVenture(job, investedCapital: 110_000)
        XCTAssertEqual(player.savings, 0, "Savings fund the stake first.")
        XCTAssertEqual(player.outstandingLoan, 100_000, "The shortfall becomes debt.")
    }

    /// The debt — and its interest — outlives the venture that borrowed it:
    /// once the business is gone, with nothing coming in, the balance compounds
    /// at the venture-loan rate.
    func testLoanOutlivesTheVentureAndAccruesInterest() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 10_000, retailYears: 0)
        player.currentOccupation = try dayJob(income: 50_000)
        player.foundVenture(job, investedCapital: 110_000)
        XCTAssertEqual(player.outstandingLoan, 100_000)

        // The business is gone (sold, folded — it doesn't matter) and so is the
        // money: a year adds exactly one year's interest.
        player.currentOccupation = nil
        player.savings = 0
        player.advanceYear(appUIState: AppUIState())
        let expected = Int((100_000.0 * (1 + GameConstants.ventureLoanAnnualInterest)).rounded())
        XCTAssertEqual(player.outstandingLoan, expected,
                       "An unserviced loan compounds at the venture-loan rate.")
    }

    /// Founding builds a business name: business fame raises the preparation —
    /// and so the survival — of the next venture.
    func testFounderReputationHelpsTheNextVenture() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 60_000, retailYears: 2)
        let firstTimer = player.firstYearSurvival(for: job, stake: 60_000)
        player.award("Successful Exit", icon: "💸", category: .business, weight: GameConstants.founderExitFame)
        XCTAssertGreaterThan(player.firstYearSurvival(for: job, stake: 60_000), firstTimer,
                             "A founder with an exit behind them should be better placed.")
    }

    /// A founder's track record counts at the top of other companies too — a
    /// failed founder included: business fame eases the seat hurdle on a
    /// commercial executive seat, within its cap.
    func testFounderTrackRecordHelpsLandAnExecutiveSeat() throws {
        let ceo = try XCTUnwrap(JobCatalog.allJobs().first { $0.isExecutive && !$0.isEntrepreneurial })
        let player = realisticFounder(savings: 0)
        let before = ceo.hireProbability(for: player, requestedSalary: Double(ceo.annualIncome))
        let seatBefore = ceo.seatChance(for: player)
        XCTAssertLessThan(seatBefore, 1, "Premise: \(ceo.id) is a scarce seat.")
        player.award("Founder's Lessons", icon: "📚", category: .business, weight: GameConstants.founderFoldFame)
        player.award("Founder of Specialty Coffee Roastery", icon: "☕", category: .business, weight: 1.5)
        XCTAssertGreaterThan(ceo.seatChance(for: player), seatBefore)
        XCTAssertGreaterThanOrEqual(ceo.hireProbability(for: player, requestedSalary: Double(ceo.annualIncome)), before)
        // However long the record, it only eases the hurdle.
        for _ in 0..<20 { player.award("Successful Exit", icon: "💸", category: .business, weight: GameConstants.founderExitFame) }
        XCTAssertLessThanOrEqual(ceo.seatChance(for: player),
                                 (ceo.seatScarcity ?? 1) + GameConstants.executiveTrackRecordCap + 1e-9)
    }

    /// A loan is a fixed bill, paid partly from what would have been saved and
    /// partly by spending less: a salaried borrower clears a venture loan within
    /// its term — debt doesn't outgrow a healthy income — and still saves a
    /// little alongside.
    func testLoanIsRepaidFromIncomeWithinItsTerm() throws {
        let player = Player()
        player.difficulty = .comfortable              // no downturns, so no layoffs
        player.configureStart(age: 30)
        player.pinNeutralEconomy()
        player.savings = 0
        player.currentOccupation = try dayJob(income: 60_000)
        player.outstandingLoan = 60_000
        player.ventureLoanPayment = Player.annualLoanPayment(
            balance: 60_000, rate: GameConstants.ventureLoanAnnualInterest)
        let ui = AppUIState()
        for _ in 0..<GameConstants.loanTermYears { player.advanceYear(appUIState: ui) }
        XCTAssertEqual(player.outstandingLoan, 0, "The loan should be repaid within its term.")
        XCTAssertGreaterThan(player.savings, 0, "The borrower still saves alongside the instalments.")
    }

    /// Under-18 players can never pay money or go into debt, so a founding
    /// attempt before adulthood is refused outright — no stake spent, no loan.
    func testUnderageFoundingIsRefused() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 50_000)
        player.configureStart(age: 16)
        XCTAssertFalse(player.foundVenture(job, investedCapital: 20_000))
        XCTAssertEqual(player.savings, 50_000, "A minor's savings must be untouched.")
        XCTAssertEqual(player.outstandingLoan, 0, "A minor can never be put in debt.")
    }

    /// Restarting clears every debt: a fresh game begins owing nothing (a new
    /// 7-year-old in debt would also break the under-18 money rule).
    func testResetClearsDebts() {
        let player = Player()
        player.studentLoan = 12_000
        player.outstandingLoan = 8_000
        player.reset()
        XCTAssertEqual(player.studentLoan, 0, "Student debt must not survive a restart.")
        XCTAssertEqual(player.outstandingLoan, 0, "Venture debt must not survive a restart.")
    }

    // MARK: - Life after launch

    /// Launch a venture, then keep playing: advance a full run of years. The
    /// founder earns their income and the run stays well-formed every year — the
    /// direct reproduction of "launch a venture, then crash".
    func testLaunchedVentureSurvivesManyYears() throws {
        let job = try coffeeRoasteryJob()
        let ui = AppUIState()

        var player: Player?
        for _ in 0..<500 {
            let candidate = realisticFounder(savings: 250_000)
            if candidate.foundVenture(job, investedCapital: 250_000) {
                player = candidate
                break
            }
        }
        let founder = try XCTUnwrap(player, "Could not launch the venture to start the lifecycle test.")

        for _ in 0..<40 {
            founder.advanceYear(appUIState: ui)
            XCTAssertTrue(founder.savings.magnitude < Int.max / 2,
                          "Savings should not run away toward overflow.")
            XCTAssertGreaterThanOrEqual(founder.savings, 0, "Savings should never go negative.")
        }
    }
}
