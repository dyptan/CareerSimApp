import XCTest
@testable import CareersApp

/// End-to-end coverage of the **launch a venture** flow — the founder path a
/// player walks from the Ventures sheet: stake capital through `foundVenture`,
/// then run the multi-year startup loop inside `advanceYear` with its buyout,
/// hold-and-grow, and recession-liquidation branches (see `Player.foundVenture`,
/// `Player.advanceYear`, `Player.holdStartup`, `Player.acceptStartupOffer`).
///
/// These drive the exact code paths behind the crash report ("the app crashes
/// when I launch a venture"): they found a real founder rung, advance many
/// years, and assert the venture's state stays well-formed the whole way. A
/// crash (out-of-range rung, NaN/overflow metric, a trapped force-unwrap) in
/// that path surfaces here as a test failure instead of a runtime abort.
final class VentureLaunchTests: XCTestCase {

    // MARK: - Fixtures

    /// The first founder rung on the ladder. Side Hustler needs no prior
    /// entrepreneurship experience, so a fresh player can launch it — the
    /// simplest reproduction of "launch a venture".
    private func sideHustlerJob() throws -> Job {
        try XCTUnwrap(
            JobCatalog.allJobs().first { $0.isEntrepreneurial && $0.baseTitle == "Side Hustler" },
            "The catalogue is missing the Side Hustler founder rung."
        )
    }

    /// A player in a realistic (non-Simplified) mode set up the way the app does
    /// on launch — starting age 18 with the matching K-12 record — plus a war
    /// chest to stake. The startup loop only runs outside Simplified mode.
    private func realisticFounder(savings: Int) -> Player {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.regenerateAvailableJobs()
        player.savings = savings
        return player
    }

    /// Asserts a running venture's metrics are all within their documented
    /// bounds — the invariants the UI (HeaderView, StartupOfferView) relies on.
    private func assertWellFormed(_ startup: ActiveStartup, line: UInt = #line) {
        XCTAssertTrue(FounderLadder.rungTitles.indices.contains(startup.rungIndex),
                      "rungIndex \(startup.rungIndex) is off the founder ladder.", line: line)
        XCTAssertGreaterThanOrEqual(startup.marketSharePct, 0, "Market share went negative.", line: line)
        XCTAssertLessThanOrEqual(startup.marketSharePct, 100, "Market share exceeded 100%.", line: line)
        XCTAssertTrue(startup.marketSharePct.isFinite, "Market share is not finite.", line: line)
        XCTAssertGreaterThanOrEqual(startup.headcount, 1, "A venture always has at least one head.", line: line)
        XCTAssertGreaterThanOrEqual(startup.revenue, 0, "Revenue went negative.", line: line)
    }

    // MARK: - Founding

    /// A fully-funded first rung has real (non-zero, capped) launch odds — the
    /// value the "Launch your venture" screen shows before the player commits.
    func testFullyFundedSideHustleHasStrongOdds() throws {
        let player = realisticFounder(savings: 100_000)
        let job = try sideHustlerJob()
        let p = job.founderSuccessProbability(for: player, investedCapital: job.targetCapital ?? 0)
        XCTAssertGreaterThan(p, 0.0, "A fully-funded, experience-met venture should have positive odds.")
        XCTAssertLessThanOrEqual(p, 0.92, "Odds are capped at 0.92.")
    }

    /// Launching a venture (the success branch of `foundVenture`) makes the
    /// player a founder and boots the multi-year startup loop: an `activeStartup`
    /// at the rung matching the job, with the stake committed from savings.
    func testFoundingAVentureStartsTheStartupLoop() throws {
        let job = try sideHustlerJob()
        let expectedRung = try XCTUnwrap(FounderLadder.rungIndex(forTitle: job.id),
                                         "Side Hustler should map to a founder rung.")

        // `foundVenture` rolls the dice, so retry with a fresh, fully-funded
        // player until it lands the (high-probability) success branch. This never
        // loops long in practice — odds sit near the 0.92 cap.
        var launched = false
        for _ in 0..<500 {
            let player = realisticFounder(savings: 100_000)
            if player.foundVenture(job, investedCapital: 100_000) {
                XCTAssertNotNil(player.activeStartup, "A launched venture must set activeStartup.")
                XCTAssertEqual(player.activeStartup?.rungIndex, expectedRung,
                               "The startup should seed at the job's founder rung.")
                XCTAssertEqual(player.currentOccupation?.baseTitle, "Side Hustler",
                               "Founding makes the player the founder.")
                XCTAssertLessThan(player.savings, 100_000, "The stake should be committed from savings.")
                if let startup = player.activeStartup { assertWellFormed(startup) }
                launched = true
                break
            }
        }
        XCTAssertTrue(launched, "A fully-funded Side Hustler should launch within many attempts.")
    }

    /// A failed founding salvages half the stake and never starts a venture.
    func testFailedFoundingSalvagesHalfAndStartsNoVenture() throws {
        let job = try sideHustlerJob()
        // Zero capital drives the odds to the floor, so failures dominate.
        var sawFailure = false
        for _ in 0..<500 {
            let player = realisticFounder(savings: 10_000)
            let before = player.savings
            if !player.foundVenture(job, investedCapital: 0) {
                XCTAssertNil(player.activeStartup, "A flop must not start a venture.")
                XCTAssertNil(player.currentOccupation, "A flop must not make the player a founder.")
                XCTAssertEqual(player.savings, before, "No stake was committed, so savings are unchanged.")
                sawFailure = true
                break
            }
        }
        XCTAssertTrue(sawFailure, "A zero-capital founding should fail within many attempts.")
    }

    // MARK: - The multi-year startup loop

    /// Launch a venture, then keep playing: advance a full run of years so the
    /// startup loop rolls buyouts, hold-and-grows, and recession liquidations.
    /// The venture's metrics must stay well-formed every single year — this is
    /// the direct reproduction of "launch a venture, then the app crashes".
    func testLaunchedVentureSurvivesManyYears() throws {
        let job = try sideHustlerJob()
        let ui = AppUIState()

        // Found the venture for real (retry through the launch roll).
        let player = realisticFounder(savings: 250_000)
        var launched = false
        for _ in 0..<500 where !launched {
            let candidate = realisticFounder(savings: 250_000)
            if candidate.foundVenture(job, investedCapital: 250_000) {
                launched = true
                player.difficulty = candidate.difficulty
                player.savings = candidate.savings
                player.age = candidate.age
                player.degrees = candidate.degrees
                player.currentOccupation = candidate.currentOccupation
                player.activeStartup = candidate.activeStartup
            }
        }
        XCTAssertTrue(launched, "Could not launch the venture to start the lifecycle test.")

        for _ in 0..<40 {
            player.advanceYear(appUIState: ui)
            // Resolve any buyout the way the Hold button does — climb the ladder.
            if player.pendingStartupOffer != nil {
                player.holdStartup()
                XCTAssertNil(player.pendingStartupOffer, "Holding must clear the pending offer.")
            }
            if let startup = player.activeStartup { assertWellFormed(startup) }
            XCTAssertTrue(player.savings.magnitude < Int.max / 2, "Savings should not run away toward overflow.")
        }
    }

    // MARK: - Resolving a buyout offer

    /// Holding a buyout offer climbs the player to the next founder rung, updates
    /// the occupation to that rung's job, and clears the offer.
    func testHoldStartupClimbsFounderLadder() throws {
        let job = try sideHustlerJob()          // rung 0
        let player = realisticFounder(savings: 0)
        player.currentOccupation = job
        player.activeStartup = ActiveStartup.founded(rungIndex: 0, targetCapital: job.targetCapital ?? 0)
        player.pendingStartupOffer = 5_000

        player.holdStartup()

        XCTAssertEqual(player.activeStartup?.rungIndex, 1, "Holding advances to the next rung.")
        XCTAssertNil(player.pendingStartupOffer, "Holding clears the pending offer.")
        XCTAssertEqual(player.currentOccupation?.baseTitle, "Small Business Owner",
                       "The occupation steps up to the next rung's job.")
        if let startup = player.activeStartup { assertWellFormed(startup) }
    }

    /// Accepting a buyout banks the cash, ends the venture, and leaves the player
    /// between jobs (free to found again or take a salaried role).
    func testAcceptStartupOfferBanksCashAndEndsVenture() throws {
        let job = try sideHustlerJob()
        let player = realisticFounder(savings: 1_000)
        player.currentOccupation = job
        player.activeStartup = ActiveStartup.founded(rungIndex: 0, targetCapital: job.targetCapital ?? 0)
        player.pendingStartupOffer = 50_000

        player.acceptStartupOffer()

        XCTAssertEqual(player.savings, 51_000, "The offer should be banked on top of savings.")
        XCTAssertNil(player.activeStartup, "Selling ends the venture.")
        XCTAssertNil(player.pendingStartupOffer, "Selling clears the pending offer.")
        XCTAssertNil(player.currentOccupation, "Selling leaves the player between jobs.")
    }
}
