import XCTest
@testable import CareersApp

/// The career advisor reads the game's own odds, so these tests pin its
/// *judgement* — what it will and won't recommend — rather than exact numbers,
/// which move with the random economy and starting skills.
final class CareerAdvisorTests: XCTestCase {

    /// A realistic-mode adult who has just finished high school and is free to
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
        let odds = tip.job.hireProbability(for: player, requestedSalary: Double(tip.job.income))
        XCTAssertGreaterThanOrEqual(odds, CareerAdvisor.minimumApplyOdds)
        XCTAssertGreaterThan(tip.job.income, CareerAdvisor.currentPay(player))
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

    func testYearsOfStudyCountTheWholeClimb() {
        let bachelor = Education(.Bachelor, profile: .health)
        XCTAssertEqual(CareerAdvisor.yearsOfStudy(from: bachelor, to: 5), 3)
        XCTAssertEqual(CareerAdvisor.yearsOfStudy(from: bachelor, to: 7), 3 + 2 + 3)
    }
}
