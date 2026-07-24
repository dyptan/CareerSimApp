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
        XCTAssertLessThanOrEqual(p, 0.95, "Odds are capped at 0.95.")
    }

    /// Experience is a hard gate: with no industry experience the odds are zero,
    /// no matter how much capital or skill the player brings.
    func testNoIndustryExperienceGatesTheLaunch() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 200_000, retailYears: 0)
        let p = job.founderSuccessProbability(for: player, investedCapital: 200_000)
        XCTAssertEqual(p, 0.0, "Below the experience baseline, a launch can't get off the ground.")
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
    /// founder. Driving the odds to zero (no experience) guarantees the flop.
    func testFailedFoundingLosesFullStakeAndStartsNoVenture() throws {
        let job = try coffeeRoasteryJob()
        let player = realisticFounder(savings: 10_000, retailYears: 0)  // gated → certain failure
        XCTAssertFalse(player.foundVenture(job, investedCapital: 4_000))
        XCTAssertNil(player.currentOccupation, "A flop must not make the player a founder.")
        XCTAssertEqual(player.savings, 10_000 - 4_000,
                       "A failed founding loses the entire committed stake.")
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
