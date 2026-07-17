import XCTest
@testable import CareersApp

/// Structural validation of the career dependency graph. These are *catalogue*
/// invariants — reachability over the prerequisite DAG — so they run in
/// O(catalogue size), not as a combinatorial sweep of player states.
final class CareerGraphTests: XCTestCase {

    /// The headline guarantee: the catalogue is internally consistent. No
    /// licence-prerequisite cycles and every credential/education gate is
    /// reachable. A failure prints the exact offending node(s).
    func testCatalogueHasNoUnreachablePaths() {
        let issues = CareerGraph.validateCatalogue()
        XCTAssertEqual(
            issues, [],
            "Career graph validation found \(issues.count) issue(s):\n" + issues.joined(separator: "\n")
        )
    }

    /// The training prerequisite chain must terminate (no cycles) and bottom out
    /// in a training with no prerequisites.
    func testTrainingPrerequisiteChainsTerminate() {
        for start in Training.allCases {
            var seen: Set<Training> = []
            var frontier = start.prerequisites
            var depth = 0
            while let next = frontier.popLast() {
                XCTAssertFalse(
                    seen.contains(next),
                    "Training prerequisite cycle reached '\(next.rawValue)' from '\(start.rawValue)'."
                )
                seen.insert(next)
                frontier.append(contentsOf: next.prerequisites)
                depth += 1
                XCTAssertLessThan(depth, Training.allCases.count + 1,
                                  "Training chain from '\(start.rawValue)' did not terminate.")
            }
        }
    }

    /// `missingHardRequirements` should report the gaps for a fresh player and go
    /// empty once those exact gaps are filled — a sanity check on the queryable
    /// guidance helper. Uses a job that gates on a statutory training.
    func testMissingHardRequirementsClearsWhenSatisfied() {
        // Find a non-regulated job that requires a statutory training (checked in
        // every field), with no education/experience gate so it's easy to satisfy.
        guard let job = JobCatalog.allJobs().first(where: {
            !$0.category.requiresCredentials
                && $0.requirements.hardSkills.trainings.contains(where: \.isStatutory)
                && $0.requirements.minYearsExperience == 0
                && !$0.educationIsMandatory
        }) else {
            // No such job in the catalogue — nothing to assert, but don't fail.
            return
        }

        let player = Player()
        player.difficulty = .middleClass // a non-simplified mode, so hard skills are gated
        player.age = 30 // clear the working-age gate

        let before = CareerGraph.missingHardRequirements(for: job, player: player)
        XCTAssertFalse(before.isEmpty, "Expected unmet requirements for a fresh player on '\(job.id)'.")

        // Grant exactly the hard skills (trainings) the job gates on.
        for training in job.requirements.hardSkills.trainings {
            player.hardSkills.trainings.insert(training)
        }
        let after = CareerGraph.missingHardRequirements(for: job, player: player)
        XCTAssertEqual(
            after, [],
            "Granting the required trainings should clear the gaps for '\(job.id)', got: \(after)"
        )
    }

    // MARK: - Entrepreneurship experience counts toward Business

    /// Entrepreneurship and Business credit each other's years, so a founder's
    /// experience counts toward Business roles (and vice versa).
    func testEntrepreneurshipExperienceCreditsBusiness() {
        let player = Player(experience: [.entrepreneurship: 4])
        XCTAssertEqual(player.industryExperience(for: .business), 4,
                       "Entrepreneurship years should count toward Business experience.")
        XCTAssertEqual(player.industryExperience(for: .entrepreneurship), 4)

        let player2 = Player(experience: [.business: 3])
        XCTAssertEqual(player2.industryExperience(for: .entrepreneurship), 3,
                       "Business years should count toward Entrepreneurship experience.")
    }

    /// A standalone Business role's relevant years should reflect entrepreneurship
    /// experience, so a founder can qualify on venture years alone.
    func testBusinessRoleCountsEntrepreneurshipYears() {
        guard let job = JobCatalog.allJobs().first(where: {
            $0.category == .business
                && $0.seniorityPrefix == nil
                && $0.requirements.minYearsExperience > 0
        }) else {
            return // no such role in the catalogue — nothing to assert
        }
        let need = job.requirements.minYearsExperience
        let player = Player(experience: [.entrepreneurship: need])
        XCTAssertEqual(job.relevantYears(for: player), need)
        XCTAssertTrue(job.experienceMet(for: player),
                      "Entrepreneurship years should satisfy '\(job.id)'s experience gate.")
    }

    /// Every entrepreneurship spare-time venture builds `.entrepreneurship` work
    /// experience — the mechanism that feeds Business roles.
    func testEntrepreneurshipVenturesBuildExperience() {
        let ventureIds = ["startupLaunch", "pitchCompetition", "crowdfundingCampaign"]
        for id in ventureIds {
            guard let venture = SideHustleCatalog.byId[id] else {
                XCTFail("Missing entrepreneurship venture '\(id)'."); continue
            }
            XCTAssertEqual(venture.experienceCategory, .entrepreneurship,
                           "Venture '\(id)' should build entrepreneurship experience.")
        }
    }

    /// Relevant work experience should lift an experience-building venture's odds,
    /// but never beyond the cap; ventures with no experience category are unmoved.
    func testExperienceLiftRaisesVentureOdds() {
        guard let venture = SideHustleCatalog.byId["startupLaunch"],
              let plain = SideHustleCatalog.byId["projectApp"] else {
            XCTFail("Expected ventures missing from catalogue."); return
        }
        let soft = SoftSkills()
        let cold = venture.successProbability(for: soft, experienceYears: 0)
        let seasoned = venture.successProbability(for: soft, experienceYears: 20)
        XCTAssertGreaterThan(seasoned, cold,
                             "Experience should raise an entrepreneurship venture's odds.")
        XCTAssertEqual(venture.experienceLift(years: 100), SideHustle.maxExperienceLift,
                       "Experience lift should cap out.")
        XCTAssertEqual(plain.experienceLift(years: 20), 0,
                       "A venture with no experience category gets no lift.")
    }

    // MARK: - Executive decisions (Boardroom)

    /// The Boardroom unlocks for founders and business-style top leadership, but
    /// not for ordinary roles or non-commercial capstones.
    func testExecutiveSeatGating() {
        let jobs = JobCatalog.allJobs()

        if let ceo = jobs.first(where: { $0.id == "Chief Executive Officer" }) {
            XCTAssertTrue(ceo.isExecutive, "The CEO should unlock the Boardroom.")
        }
        if let founder = jobs.first(where: { $0.isEntrepreneurial }) {
            XCTAssertTrue(founder.isExecutive, "Founder ventures should unlock the Boardroom.")
        }
        if let analyst = jobs.first(where: {
            $0.category == .business && $0.seniorityPrefix == nil && !$0.isTopLeadership
        }) {
            XCTAssertFalse(analyst.isExecutive, "A rank-and-file role shouldn't unlock the Boardroom.")
        }
        // A top-leadership role outside the commercial fields (e.g. a Head Chef)
        // tops out its ladder but doesn't run a cap table.
        if let nonCommercial = jobs.first(where: {
            $0.isTopLeadership && !$0.isEntrepreneurial
                && ![.business, .entrepreneurship, .finance, .technology].contains($0.category)
        }) {
            XCTAssertFalse(nonCommercial.isExecutive,
                           "'\(nonCommercial.id)' is top leadership but shouldn't unlock the Boardroom.")
        }
    }

    /// Selling vested shares is a guaranteed payout that grows with tenure and
    /// is one-per-year.
    func testSellSharesPaysAndScalesWithTenure() {
        guard let ceo = JobCatalog.allJobs().first(where: { $0.id == "Chief Executive Officer" }) else {
            return
        }
        let player = Player()
        player.currentOccupation = ceo
        XCTAssertTrue(player.canMakeExecutiveDecisions)

        let rookie = player.sellSharesPayout()
        player.experienceByRole[ceo.baseTitle] = 8
        let veteran = player.sellSharesPayout()
        XCTAssertGreaterThan(veteran, rookie, "Longer tenure should vest more equity.")

        guard let decision = ExecutiveDecisionCatalog.byId["sellShares"] else { return }
        let before = player.savings
        let outcome = player.resolveExecutiveDecision(decision)
        XCTAssertTrue(outcome.success)
        XCTAssertEqual(player.savings, before + outcome.cash)
        XCTAssertTrue(player.hasUsedExecutiveDecision(decision),
                      "A decision should be marked used for the year.")
    }

    /// Investment-round odds stay in bounds, and the per-year lock clears when the
    /// year advances.
    func testInvestmentRoundOddsBoundedAndResetYearly() {
        guard let ceo = JobCatalog.allJobs().first(where: { $0.id == "Chief Executive Officer" }) else {
            return
        }
        let player = Player()
        player.currentOccupation = ceo
        let odds = player.investmentRoundOdds()
        XCTAssertGreaterThanOrEqual(odds, 0.05)
        XCTAssertLessThanOrEqual(odds, 0.95)

        player.executiveActionsThisYear.insert("investmentRound")
        player.advanceYear(appUIState: AppUIState())
        XCTAssertTrue(player.executiveActionsThisYear.isEmpty,
                      "Executive actions should reset each year.")
    }

    // MARK: - Venture metrics (market share, revenue, headcount)

    /// A founded venture seeds positive metrics scaled off its capital.
    func testFoundedVentureSeedsMetrics() {
        let s = ActiveStartup.founded(rungIndex: 2, targetCapital: 60_000)
        XCTAssertGreaterThan(s.marketSharePct, 0)
        XCTAssertGreaterThanOrEqual(s.revenue, 60_000)
        XCTAssertGreaterThanOrEqual(s.headcount, 1)
    }

    /// Holding the venture another year always grows revenue and lifts the exit
    /// premium (the growth factor is strictly > 1).
    func testGrowthRaisesRevenueAndExitPremium() {
        var s = ActiveStartup.founded(rungIndex: 1, targetCapital: 25_000)
        let premiumBefore = s.exitPremium(targetCapital: 25_000)
        let revenueBefore = s.revenue
        s.grow(founderSkillFit: 0.8)
        XCTAssertGreaterThan(s.revenue, revenueBefore, "A held year should grow revenue.")
        XCTAssertGreaterThanOrEqual(s.exitPremium(targetCapital: 25_000), premiumBefore,
                                    "Growth should not lower the exit premium.")
        XCTAssertLessThanOrEqual(s.marketSharePct, 100.0, "Market share is capped at 100%.")
    }

    /// A bigger, higher-share company commands a larger exit premium.
    func testExitPremiumScalesWithTraction() {
        let target = 60_000
        let small = ActiveStartup.founded(rungIndex: 2, targetCapital: target)
        var big = small
        big.revenue = target * 4
        big.marketSharePct = 40
        XCTAssertGreaterThan(big.exitPremium(targetCapital: target),
                             small.exitPremium(targetCapital: target))
        XCTAssertGreaterThanOrEqual(small.exitPremium(targetCapital: target), 0.5,
                                    "Exit premium never falls below the floor.")
    }

    /// Stepping up a rung scales the company and never shrinks it.
    func testScaleUpGrowsAndFloorsMetrics() {
        var s = ActiveStartup.founded(rungIndex: 0, targetCapital: 2_000)
        let revenueBefore = s.revenue
        s.scaleUp(toRungIndex: 1, targetCapital: 25_000)
        XCTAssertEqual(s.rungIndex, 1)
        XCTAssertEqual(s.yearsHeld, 0)
        XCTAssertGreaterThanOrEqual(s.revenue, revenueBefore)
        XCTAssertGreaterThanOrEqual(s.revenue, 25_000, "Floored at the new rung's seed.")
    }

    /// An investment round injected into a founder's venture grows its metrics.
    func testInvestmentRoundFuelsVentureMetrics() {
        guard let founder = JobCatalog.allJobs().first(where: { $0.isEntrepreneurial }),
              let decision = ExecutiveDecisionCatalog.byId["investmentRound"] else { return }
        let player = Player()
        player.currentOccupation = founder
        player.activeStartup = ActiveStartup.founded(
            rungIndex: FounderLadder.rungIndex(forTitle: founder.id) ?? 0,
            targetCapital: founder.targetCapital ?? 0
        )
        // Guarantee the round closes so we can assert the metric injection.
        player.softSkills.visionaryThinkingAndAmbition = 10
        player.softSkills.persuasionAndNegotiation = 10
        player.softSkills.leadershipAndInfluence = 10
        player.softSkills.communicationAndNetworking = 10
        let revenueBefore = player.activeStartup?.revenue ?? 0
        let outcome = player.resolveExecutiveDecision(decision)
        if outcome.success {
            XCTAssertGreaterThan(player.activeStartup?.revenue ?? 0, revenueBefore,
                                 "A closed round should grow the venture's revenue.")
        }
    }

    // MARK: - Open-ended realistic goal + running score

    /// Realistic modes are open-ended: no savings target ever counts as a goal,
    /// however wealthy the player gets.
    func testRealisticModeHasNoFixedGoal() {
        let player = Player()
        player.difficulty = .middleClass
        player.savings = 5_000_000
        XCTAssertFalse(player.goalMet, "Realistic mode should have no fixed savings goal.")

        player.difficulty = .comfortable
        XCTAssertFalse(player.goalMet)
    }

    /// Simplified keeps its finish line: reaching a top-leadership role.
    func testSimplifiedGoalIsTopLeadership() {
        let player = Player()
        player.difficulty = .simplified
        XCTAssertFalse(player.goalMet, "No occupation yet — goal not met.")
        if let ceo = JobCatalog.allJobs().first(where: { $0.isTopLeadership }) {
            player.currentOccupation = ceo
            XCTAssertTrue(player.goalMet, "Reaching a top-leadership role wins Simplified.")
        }
    }

    /// The running score is savings ÷ age and recomputes from current state.
    func testRunningScoreTracksSavingsPerYear() {
        let player = Player()
        player.age = 25
        player.savings = 100_000
        XCTAssertEqual(player.leaderboardScore, 4_000)
        player.savings = 250_000
        XCTAssertEqual(player.leaderboardScore, 10_000, "Score should update as savings grow.")
        player.savings = -50_000
        XCTAssertEqual(player.leaderboardScore, 0, "Score is floored at 0.")
    }
}
