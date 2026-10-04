import XCTest
@testable import CareersApp

/// The career advisor reads the game's own odds, so these tests pin its
/// *judgement* — what it will and won't recommend — rather than exact numbers,
/// which move with the random economy and starting skills.
final class CareerAdvisorTests: XCTestCase {

    /// A Real Life adult who has just finished high school and is free to
    /// choose: no job, no study in progress.
    private func graduate(age: Int = 18) -> Player {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.age = age
        return player
    }

    func testTipsAreRankedCappedAndDistinct() {
        let tips = CareerAdvisor.tips(for: graduate(age: 25))
        XCTAssertLessThanOrEqual(tips.count, 3)
        XCTAssertEqual(tips.map(\.value), tips.map(\.value).sorted(by: >), "Best tip first.")
        XCTAssertEqual(Set(tips.map(\.kind)).count, tips.count, "One tip per kind of move.")
        XCTAssertTrue(tips.allSatisfy { $0.value > 0 }, "A tip must be worth something.")
    }

    /// Nothing a tip says leaks a format placeholder, and each sheet has a button label of its own.
    func testTipsAreFinishedSentencesAndEachSheetHasALabel() {
        for age in [13, 18, 25, 40] {
            for tip in CareerAdvisor.tips(for: graduate(age: age)) {
                for marker in ["%@", "%lld", "%1$"] {
                    XCTAssertFalse((tip.title + tip.detail).contains(marker), "\(tip.kind) at \(age): \(tip.detail)")
                }
                XCTAssertFalse(tip.title.isEmpty)
                XCTAssertFalse(tip.detail.contains("  "), "Two spaces from a sentence join: \(tip.detail)")
            }
        }
        let destinations: [CareerAdvisor.Destination] = [.jobs(.office), .listing("Chef"), .education, .events, .projects,
                                                         .ventures, .boardroom, .activities(.sports)]
        XCTAssertEqual(Set(destinations.map(\.buttonLabel)).count, destinations.count, "A label per sheet.")
    }

    func testReadingAdviceChangesNothing() {
        let player = graduate(age: 30)
        let before = (player.age, player.savings, player.softSkills, player.degrees, player.currentOccupation)
        _ = CareerAdvisor.tips(for: player)
        XCTAssertEqual(player.age, before.0)
        XCTAssertEqual(player.savings, before.1)
        XCTAssertEqual(player.softSkills, before.2)
        XCTAssertEqual(player.degrees, before.3)
        XCTAssertEqual(player.currentOccupation, before.4)
    }

    /// A child can't work, study for a degree or earn a licence yet — the only
    /// useful advice is which skills to grow.
    func testChildIsOnlyAdvisedOnSkills() {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 10)
        let kinds = Set(CareerAdvisor.tips(for: player).map(\.kind))
        XCTAssertTrue(kinds.isSubset(of: [.buildSkill]), "Got \(kinds) for a 10-year-old.")
    }

    func testNeverSuggestsALongShotApplication() {
        let player = graduate(age: 22)
        guard let tip = CareerAdvisor.applyNowTip(player, CareerAdvisor.catalogue(player)) else { return }
        // Read at the ask the advisor quotes and the Jobs sheet defaults to —
        // the experience-adjusted offer. Asking a newcomer's full posted pay
        // is asking ~18% over the offer, which reads lower than the tip did.
        let offer = tip.job.offeredSalary(for: player)
        let odds = tip.job.hireProbability(for: player, requestedSalary: Double(offer))
        XCTAssertGreaterThanOrEqual(odds, CareerAdvisor.minimumApplyOdds)
        XCTAssertGreaterThan(offer, CareerAdvisor.currentPay(player))
        XCTAssertTrue(player.availableJobs.contains { $0.id == tip.job.id },
                      "\(tip.job.id) isn't posted this year — the Jobs sheet wouldn't list it.")
    }

    /// Same state, same advice: the postings are shuffled, but the ranking
    /// mustn't depend on their order.
    func testAdviceIsStableForTheSameState() {
        let player = graduate(age: 26)
        let first = CareerAdvisor.tips(for: player)
        player.availableJobs.shuffle()
        let second = CareerAdvisor.tips(for: player)
        XCTAssertEqual(first.map(\.title), second.map(\.title))
        XCTAssertEqual(first.map(\.value), second.map(\.value))
    }

    /// A role closed only by a licence the player can enrol in today should
    /// produce a "Take <course>" tip.
    func testALicenceStandingBetweenPlayerAndARoleIsSuggested() {
        let player = graduate(age: 25)
        let jobs = CareerAdvisor.catalogue(player)
        let pay = CareerAdvisor.currentPay(player)
        let gated = jobs.filter { job in
            let fit = job.requirementFit(for: player)
            guard job.income > pay, fit.credentials == 0,
                  fit.age * fit.education * fit.experience > 0 else { return false }
            let missing = job.requirements.hardSkills.trainings
                .filter { $0.isStatutory || job.category.requiresCredentials }
                .subtracting(player.hardSkills.trainings)
            return !missing.isEmpty && missing.count <= CareerAdvisor.maxTrainingSteps
                && missing.allSatisfy { if case .ok = $0.requirements(player) { return true }; return false }
        }
        XCTAssertFalse(gated.isEmpty, "Precondition: some role should be one licence away for a 25-year-old.")

        let tip = CareerAdvisor.trainTip(player, jobs)
        XCTAssertNotNil(tip)
        XCTAssertEqual(tip?.kind, .train)
        XCTAssertEqual(tip?.destination, .education)
        XCTAssertGreaterThan(tip?.value ?? 0, 0)
    }

    /// Simplified mode never rolls promotions, so it must never be told to
    /// wait for one.
    func testSimplifiedPlayerIsNeverToldToWaitForAPromotion() throws {
        let player = Player()
        player.difficulty = .simplified
        player.configureStart(age: 18)
        player.age = 30
        let job = try XCTUnwrap(player.availableJobs.first {
            !$0.isEntrepreneurial && !$0.isLowSkilled && player.nextRung(after: $0) != nil
        })
        player.currentOccupation = job
        XCTAssertTrue(player.promotionOdds(for: job).promotes,
                      "Precondition: the formula alone would offer odds for \(job.id).")
        XCTAssertNil(CareerAdvisor.climbTip(player))
    }

    /// A fresh graduate with a whole career ahead should be pointed at a degree:
    /// plenty of well-paid roles are closed to them without one.
    func testSchoolLeaverIsOfferedADegree() {
        let player = graduate()
        let tip = CareerAdvisor.studyTip(player, CareerAdvisor.catalogue(player))
        XCTAssertNotNil(tip)
        XCTAssertEqual(tip?.destination, .education)
    }

    /// Three years of study with two years left to work can't pay for itself.
    func testNoDegreeIsSuggestedOnTheEveOfRetirement() {
        let player = graduate(age: GameConstants.retirementAge - 2)
        XCTAssertNil(CareerAdvisor.studyTip(player, CareerAdvisor.catalogue(player)))
    }

    /// The advisor's estimate is the game's own breakdown: with nothing
    /// changed, it quotes exactly the odds the roll would use.
    func testEstimateIsTheRollWhenNothingChanges() {
        let player = graduate(age: 30)
        player.experience[.business] = 6
        for job in CareerAdvisor.catalogue(player) {
            let fit = job.requirementFit(for: player)
            XCTAssertEqual(CareerAdvisor.estimatedOdds(for: job, player: player, requirementFactor: fit.factor),
                           job.hireProbability(for: player, requestedSalary: Double(job.offeredSalary(for: player))),
                           accuracy: 1e-12, "\(job.id)")
        }
    }

    /// A licence that only the finished degree makes enrollable — the RN
    /// licence after nursing school, the medical licence after the MD — still
    /// counts toward a degree tip, a year later; one that also needs years of
    /// practice doesn't.
    func testLicencesTheDegreeUnlocksCountTowardAStudyTip() throws {
        let player = graduate()
        XCTAssertTrue(CareerAdvisor.enrollableAfterDegree(.medicalLicense, eqf: 7, alongside: [.medicalLicense],
                                                          player: player, inYears: 8))
        XCTAssertFalse(CareerAdvisor.enrollableAfterDegree(.boardCertified, eqf: 7, alongside: [.boardCertified],
                                                           player: player, inYears: 8),
                       "Board certification needs residency years the degree doesn't give.")

        let nurse = try XCTUnwrap(CareerAdvisor.catalogue(player).first { $0.id == "Registered Nurse" })
        XCTAssertEqual(nurse.requirementFit(for: player).credentials, 0, "Premise: the RN licence is missing.")
        let tip = try XCTUnwrap(CareerAdvisor.studyTip(player, [nurse]),
                                "A school-leaver should be pointed at the degree that leads to nursing.")
        XCTAssertEqual(tip.job.id, "Registered Nurse")
        XCTAssertTrue(tip.detail.contains(Training.nurse.friendlyName), tip.detail)
    }

    /// In Simplified the finish line is a top-leadership seat, not a salary:
    /// the advisor points a qualified player at the seat whatever it pays, and
    /// never points someone already in it back down for more money.
    func testSimplifiedAdviceAimsAtTheGoalAndStaysThere() throws {
        let player = Player()
        player.difficulty = .simplified
        player.configureStart(age: 18)
        player.age = 40
        player.degrees.append(Education(.Doctorate, profile: .health))
        player.experience[.health] = 15
        let jobs = CareerAdvisor.catalogue(player)
        player.currentOccupation = try XCTUnwrap(jobs.first { $0.id == "Surgeon" })
        XCTAssertFalse(player.goalMet)
        let tip = try XCTUnwrap(CareerAdvisor.applyNowTip(player, jobs))
        XCTAssertTrue(tip.job.isTopLeadership, "Advised \(tip.job.id) instead of a seat that meets the goal.")

        player.currentOccupation = tip.job
        XCTAssertTrue(player.goalMet)
        if let next = CareerAdvisor.applyNowTip(player, jobs) {
            XCTAssertTrue(next.job.isTopLeadership, "Advised stepping off the finish line to \(next.job.id).")
        }
    }

    func testYearsOfStudyCountTheWholeClimb() {
        let bachelor = Education(.Bachelor, profile: .health)
        XCTAssertEqual(CareerAdvisor.yearsOfStudy(from: bachelor, to: 5), 4)
        XCTAssertEqual(CareerAdvisor.yearsOfStudy(from: bachelor, to: 6), 4 + 2)
        // A US doctorate follows a bachelor's directly.
        XCTAssertEqual(CareerAdvisor.yearsOfStudy(from: bachelor, to: 7), 4 + 4)
    }
}
