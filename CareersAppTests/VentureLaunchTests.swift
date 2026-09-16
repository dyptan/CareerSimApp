import XCTest
@testable import CareersApp

/// End-to-end coverage of the **launch a venture** flow — the founder path a
/// player walks from the Ventures sheet: stake capital through `foundVenture`,
/// the venture becomes their occupation, and they keep playing year over year
/// (see `Player.foundVenture` and `Player.advanceYear`).
///
/// Ventures are concrete, industry-specific one-off plays (no auto-climbing
/// ladder): launch success turns on the founder's experience in that industry
/// and their soft-skill fit, with capital a supporting factor
/// (`Job.founderSuccessProbability`). These tests also drive the code path
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
            \SoftSkills.creativityAndInsightfulThinking, \SoftSkills.communicationAndNetworking,
            \SoftSkills.persuasionAndNegotiation, \SoftSkills.visionaryThinkingAndAmbition,
            \SoftSkills.riskTakingAndInitiative, \SoftSkills.carefulnessAndAttentionToDetail,
            \SoftSkills.tinkeringAndFingerPrecision, \SoftSkills.timeManagementAndPlanning,
            \SoftSkills.selfDisciplineAndPerseverance,
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

    /// A failed founding loses the entire stake and never makes the player a
    /// founder. Experience no longer gates a launch, so a flop can no longer be
    /// forced by zeroing the odds — attempt a long shot until one flops instead.
    func testFailedFoundingLosesFullStakeAndStartsNoVenture() throws {
        let job = try coffeeRoasteryJob()
        for _ in 0..<200 {
            let player = realisticFounder(savings: 10_000, retailYears: 0)
            guard !player.foundVenture(job, investedCapital: 4_000) else { continue }
            XCTAssertNil(player.currentOccupation, "A flop must not make the player a founder.")
            XCTAssertEqual(player.savings, 10_000 - 4_000,
                           "A failed founding loses the entire committed stake.")
            return
        }
        XCTFail("An underfunded, inexperienced founding should flop at least once in 200 tries.")
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

    /// The debt — and its interest — outlives the venture that borrowed it: a
    /// flopped launch still owes, and with nothing coming in the balance
    /// compounds at the venture-loan rate.
    func testLoanOutlivesAFailedLaunchAndAccruesInterest() throws {
        let job = try coffeeRoasteryJob()
        // Experience no longer gates a launch, so retry until one actually flops.
        var player = realisticFounder(savings: 10_000, retailYears: 0)
        player.currentOccupation = try dayJob(income: 50_000)
        var flopped = player.foundVenture(job, investedCapital: 110_000) == false
        for _ in 0..<200 where !flopped {
            player = realisticFounder(savings: 10_000, retailYears: 0)
            player.currentOccupation = try dayJob(income: 50_000)
            flopped = player.foundVenture(job, investedCapital: 110_000) == false
        }
        XCTAssertTrue(flopped, "A long-shot founding should flop within 200 tries.")
        XCTAssertEqual(player.outstandingLoan, 100_000, "A flop doesn't erase the debt.")

        // Strip income and savings so the servicing is deterministic: with no
        // repayment funds, a year adds exactly one year's interest.
        player.currentOccupation = nil
        player.savings = 0
        player.advanceYear(appUIState: AppUIState())
        let expected = Int((100_000.0 * (1 + GameConstants.ventureLoanAnnualInterest)).rounded())
        XCTAssertEqual(player.outstandingLoan, expected,
                       "An unserviced loan compounds at the venture-loan rate.")
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
