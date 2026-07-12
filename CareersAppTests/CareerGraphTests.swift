import XCTest
@testable import CareersApp

/// Structural validation of the career dependency graph. These are *catalogue*
/// invariants — reachability over the prerequisite DAG — so they run in
/// O(catalogue size), not as a combinatorial sweep of player states.
final class CareerGraphTests: XCTestCase {

    /// The headline guarantee: the catalogue is internally consistent. No orphan
    /// projects, no licence-prerequisite cycles, every credential gate and every
    /// job's required portfolio pieces are reachable. A failure prints the exact
    /// offending node(s).
    func testCatalogueHasNoUnreachablePaths() {
        let issues = CareerGraph.validateCatalogue()
        XCTAssertEqual(
            issues, [],
            "Career graph validation found \(issues.count) issue(s):\n" + issues.joined(separator: "\n")
        )
    }

    /// Every project must be unlocked by at least one hobby — otherwise it can
    /// never be built and any job requiring it is unwinnable. (This is the class
    /// of bug that previously left `presentation` and `lessonPlan` orphaned.)
    func testEveryProjectIsUnlockedByAHobby() {
        let buildable = CareerGraph.unlockableProjects
        for project in Project.allCases {
            XCTAssertTrue(
                buildable.contains(project),
                "Project '\(project.rawValue)' is unlocked by no hobby."
            )
        }
    }

    /// Every portfolio piece any job asks for must be producible by some project
    /// (which in turn must be hobby-unlockable).
    func testEveryRequiredPortfolioPieceIsBuildable() {
        let buildable = CareerGraph.unlockableProjects
        for job in JobCatalog.allJobs() {
            for piece in job.requirements.hardSkills.portfolioItems {
                XCTAssertTrue(
                    buildable.contains(piece),
                    "Job '\(job.id)' requires portfolio '\(piece.rawValue)', which no hobby unlocks."
                )
            }
        }
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

        // Grant exactly the hard skills the job gates on.
        for piece in job.requirements.hardSkills.portfolioItems {
            player.hardSkills.portfolioItems.insert(piece)
        }
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
}
