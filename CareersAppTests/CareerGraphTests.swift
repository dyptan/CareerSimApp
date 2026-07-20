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
        let ventureIds = ["crowdfundingCampaign"]
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
        guard let venture = SideHustleCatalog.byId["crowdfundingCampaign"],
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

    // MARK: - Projects vs. Events taxonomy

    /// The four participate-in-an-organized-thing plays moved out of Projects and
    /// into Events: they must exist as `CareerEvent`s and be gone from the
    /// spare-time project catalogue (which is now self-initiated works only).
    func testSpotlightPlaysAreEventsNotProjects() {
        let movedEventIds = ["music-festival", "tv-casting", "conference-talk", "pitch-competition"]
        for id in movedEventIds {
            XCTAssertNotNil(EventCatalog.byId[id], "Spotlight play '\(id)' should be a career event.")
        }
        let removedProjectIds = ["projectMusicFestival", "tvShow", "projectPresentation", "pitchCompetition"]
        for id in removedProjectIds {
            XCTAssertNil(SideHustleCatalog.byId[id],
                         "Moved play '\(id)' should no longer be a spare-time project.")
        }
    }

    /// A moved spotlight event supports the stage/presenter role and banks its
    /// bespoke fame accolade (not the generic "— Speaker" title) in the right
    /// fame bucket.
    func testMovedEventsBankBespokeStageFame() {
        let expected: [String: (JobCategory, FameCategory, String)] = [
            "music-festival":   (.showBusiness,    .entertainment, "Festival Performer"),
            "tv-casting":       (.showBusiness,    .entertainment, "TV Personality"),
            "conference-talk":  (.business,        .business,      "Noted Speaker"),
            "pitch-competition":(.entrepreneurship, .business,     "Pitch Winner"),
        ]
        for (id, (category, fame, title)) in expected {
            guard let event = EventCatalog.byId[id] else {
                XCTFail("Missing spotlight event '\(id)'."); continue
            }
            XCTAssertEqual(event.category, category, "'\(id)' should serve \(category.rawValue).")
            XCTAssertTrue(event.supportsPresenter, "'\(id)' should offer a stage role.")
            XCTAssertEqual(event.presenterFameTitle, title, "'\(id)' should bank a bespoke accolade.")
            XCTAssertEqual(event.category?.fameCategory, fame, "'\(id)' fame should land in \(fame).")
        }
    }

    // MARK: - Skill-building trainings (career-boost credentials)

    /// The new creative/digital programs are non-statutory, non-gating credentials
    /// whose value is the career edge they confer in the right fields.
    func testSkillBuildingTrainingsAreNonGatingBoosts() {
        let expected: [Training: Set<JobCategory>] = [
            .codingBootcamp:     [.technology, .engineering],
            .gameDevProgram:     [.gaming, .technology],
            .productDesign:      [.design, .fashion],
            .actingConservatory: [.showBusiness],
            .musicProduction:    [.showBusiness],
        ]
        for (training, categories) in expected {
            XCTAssertFalse(training.isStatutory, "\(training.rawValue) is a program, not a licence.")
            guard let boost = training.careerBoost else {
                XCTFail("\(training.rawValue) should carry a career boost."); continue
            }
            XCTAssertEqual(boost.categories, categories, "\(training.rawValue) boosts the wrong fields.")
            XCTAssertGreaterThan(boost.weight, 0, "\(training.rawValue) boost should be positive.")
        }
    }

    /// The bonus is field-scoped and non-stacking: it applies to a relevant field,
    /// is zero for unrelated fields, and the strongest single credential wins.
    func testTrainingCareerBonusIsFieldScopedAndNonStacking() {
        let player = Player()
        XCTAssertEqual(player.trainingCareerBonus(for: .technology), 0, "No credential, no bonus.")

        player.hardSkills.trainings.insert(.codingBootcamp)
        XCTAssertEqual(player.trainingCareerBonus(for: .technology), 0.15, accuracy: 1e-9,
                       "A Coding Bootcamp should lift technology odds.")
        XCTAssertEqual(player.trainingCareerBonus(for: .health), 0,
                       "It should do nothing for an unrelated field.")

        // A second tech-relevant credential doesn't stack — the strongest applies.
        player.hardSkills.trainings.insert(.gameDevProgram)
        XCTAssertEqual(player.trainingCareerBonus(for: .technology), 0.15, accuracy: 1e-9,
                       "Bonuses take the strongest relevant credential, not the sum.")
    }

    /// A relevant credential meaningfully raises a founder's launch odds — the
    /// "significant for launching a venture" guarantee.
    func testRelevantTrainingLiftsFounderOdds() throws {
        let saas = try XCTUnwrap(
            JobCatalog.allJobs().first { $0.isEntrepreneurial && $0.baseTitle == "SaaS App Startup" },
            "The catalogue is missing the SaaS App Startup venture."
        )
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.experience[.technology] = 4   // clears the launch experience gate
        let stake = saas.targetCapital ?? 0

        let without = saas.founderSuccessProbability(for: player, investedCapital: stake)
        player.hardSkills.trainings.insert(.codingBootcamp)
        let with = saas.founderSuccessProbability(for: player, investedCapital: stake)
        XCTAssertGreaterThan(with, without,
                             "A Coding Bootcamp should raise the odds of launching a SaaS startup.")
    }

    /// A relevant credential raises hire odds for a role in its field — the
    /// "significant for landing a relevant job" guarantee. Never lowers them.
    func testRelevantTrainingLiftsHireOdds() {
        let techJobs = JobCatalog.allJobs().filter { $0.category == .technology && !$0.isEntrepreneurial }
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 40)
        player.experience[.technology] = 12   // seasoned enough to clear tech gates

        var sawStrictIncrease = false
        for job in techJobs where job.allRequirementsMet(for: player) && !player.isSimplified {
            let salary = Double(job.annualIncome)
            let before = job.hireProbability(for: player, requestedSalary: salary)
            player.hardSkills.trainings.insert(.codingBootcamp)
            let after = job.hireProbability(for: player, requestedSalary: salary)
            player.hardSkills.trainings.remove(.codingBootcamp)
            XCTAssertGreaterThanOrEqual(after, before, "A credential must never hurt hire odds.")
            if after > before { sawStrictIncrease = true }
        }
        XCTAssertTrue(sawStrictIncrease,
                      "The credential should strictly raise hire odds for at least one tech role.")
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

    /// Selling a stake is a priced, probabilistic sale: the valuation grows with
    /// tenure, the odds a buyer bites fall as the asking price climbs above fair
    /// value, and whatever the roll, savings move by exactly the cash booked.
    func testSellStakeValuationAndOdds() {
        guard let ceo = JobCatalog.allJobs().first(where: { $0.id == "Chief Executive Officer" }) else {
            return
        }
        let player = Player()
        player.currentOccupation = ceo
        XCTAssertTrue(player.canMakeExecutiveDecisions)

        let rookie = player.shareStakeValue()
        player.experienceByRole[ceo.baseTitle] = 8
        let veteran = player.shareStakeValue()
        XCTAssertGreaterThan(veteran, rookie, "Longer tenure should vest more equity.")

        // Asking above fair value should find fewer buyers; odds stay in bounds.
        let fair = player.shareStakeValue()
        let cheapOdds = player.shareSaleOdds(askPrice: fair / 2)
        let dearOdds = player.shareSaleOdds(askPrice: fair * 2)
        XCTAssertGreaterThan(cheapOdds, dearOdds, "A higher asking price should find fewer buyers.")
        for odds in [cheapOdds, dearOdds] {
            XCTAssertGreaterThanOrEqual(odds, 0.02)
            XCTAssertLessThanOrEqual(odds, 0.98)
        }

        guard let decision = ExecutiveDecisionCatalog.byId["sellShares"] else { return }
        let before = player.savings
        let outcome = player.resolveExecutiveDecision(decision, askPrice: fair)
        // Whether or not a buyer appears, savings move by exactly the cash booked.
        XCTAssertEqual(player.savings, before + outcome.cash)
        XCTAssertEqual(outcome.cash, outcome.success ? fair : 0)
        XCTAssertTrue(player.hasUsedExecutiveDecision(decision),
                      "A decision should be marked used for the year.")
    }

    /// A recession thins the buyer pool: for the same asking price, the odds a
    /// buyer bites are strictly lower during a downturn.
    func testRecessionLowersSaleOdds() {
        guard let ceo = JobCatalog.allJobs().first(where: { $0.id == "Chief Executive Officer" }) else {
            return
        }
        let player = Player()
        player.currentOccupation = ceo
        let fair = player.shareStakeValue()
        let normalOdds = player.shareSaleOdds(askPrice: fair)
        player.economyInRecession = true
        let recessionOdds = player.shareSaleOdds(askPrice: fair)
        XCTAssertLessThan(recessionOdds, normalOdds, "A recession should cut the odds a buyer bites.")
    }

    /// When a founder lands a sale of their venture, they exit it: the occupation
    /// (and any startup state) clears, so they're no longer an executive and the
    /// Ventures button returns — the owner can't re-sell the same stake next
    /// year. A rock-bottom asking price makes a buyer near-certain; a bounded
    /// retry absorbs the tail.
    func testVentureSaleExitsVenture() {
        guard let venture = JobCatalog.allJobs().first(where: { $0.isEntrepreneurial }) else { return }
        guard let decision = ExecutiveDecisionCatalog.byId["sellShares"] else { return }

        for _ in 0..<40 {
            let player = Player()
            player.currentOccupation = venture
            let floor = player.shareAskingBounds().min
            let outcome = player.resolveExecutiveDecision(decision, askPrice: floor)
            if outcome.success {
                XCTAssertNil(player.currentOccupation,
                             "Selling a venture should free the occupation slot, not keep the owner in the seat.")
                XCTAssertFalse(player.canMakeExecutiveDecisions,
                               "After exiting, the player is no longer an executive and can't re-sell.")
                return
            }
        }
        XCTFail("Expected at least one floor-priced sale to succeed across 40 attempts.")
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

    /// Business fame is a heavy lever on investment-round odds: a well-known
    /// founder's reputation should move the odds substantially (up to the +0.55
    /// cap) and outweigh a small skill edge. Fame in another bucket does nothing.
    func testBusinessFameSignificantlyLiftsInvestmentRoundOdds() {
        guard let ceo = JobCatalog.allJobs().first(where: { $0.id == "Chief Executive Officer" }) else {
            return
        }
        let player = Player()
        player.currentOccupation = ceo
        let plain = player.investmentRoundOdds()

        // Fame in an unrelated bucket must not help a capital raise.
        player.award("Chart-Topping Single", icon: "🎬", category: .entertainment, weight: 5)
        XCTAssertEqual(player.investmentRoundOdds(), plain, accuracy: 0.0001,
                       "Only business fame should move investment-round odds.")

        // A big business reputation should be a large, capped swing.
        player.award("Serial Founder", icon: "💼", category: .business, weight: 10)
        XCTAssertEqual(player.investmentRoundFameBonus(), 0.55, accuracy: 0.0001,
                       "Ample business fame should saturate the fame bonus at its cap.")
        XCTAssertGreaterThan(player.investmentRoundOdds() - plain, 0.30,
                             "Business fame should be a significant lift, not a rounding error.")
        XCTAssertLessThanOrEqual(player.investmentRoundOdds(), 0.95)
    }

    // MARK: - Investment round outcome

    /// A closed investment round banks cash and additional business (💼) fame —
    /// the reputation that compounds into the next round's odds. Maxing the
    /// driving skills and fame pins the odds at the cap, so a bounded retry lands
    /// the success branch.
    func testInvestmentRoundSuccessBanksCashAndFame() {
        guard let founder = JobCatalog.allJobs().first(where: { $0.isEntrepreneurial }),
              let decision = ExecutiveDecisionCatalog.byId["investmentRound"] else { return }
        for _ in 0..<40 {
            let player = Player()
            player.currentOccupation = founder
            player.softSkills.visionaryThinkingAndAmbition = 10
            player.softSkills.persuasionAndNegotiation = 10
            player.softSkills.leadershipAndInfluence = 10
            player.softSkills.communicationAndNetworking = 10
            player.award("Serial Founder", icon: "💼", category: .business, weight: 10)
            let before = player.savings
            let fameBefore = player.famePoints(for: .business)
            let outcome = player.resolveExecutiveDecision(decision)
            if outcome.success {
                XCTAssertGreaterThan(outcome.cash, 0, "A closed round realises cash.")
                XCTAssertEqual(player.savings, before + outcome.cash)
                XCTAssertGreaterThan(player.famePoints(for: .business), fameBefore,
                                     "Closing a round banks additional business fame.")
                return
            }
        }
        XCTFail("Expected the round to close within many attempts at capped odds.")
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
