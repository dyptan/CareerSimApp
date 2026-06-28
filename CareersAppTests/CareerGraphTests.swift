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

    /// The licence prerequisite chain must terminate (no cycles) and bottom out
    /// in a licence with no prerequisites.
    func testLicencePrerequisiteChainsTerminate() {
        for start in License.allCases {
            var seen: Set<License> = []
            var frontier = start.prerequisiteLicenses
            var depth = 0
            while let next = frontier.popLast() {
                XCTAssertFalse(
                    seen.contains(next),
                    "Licence prerequisite cycle reached '\(next.rawValue)' from '\(start.rawValue)'."
                )
                seen.insert(next)
                frontier.append(contentsOf: next.prerequisiteLicenses)
                depth += 1
                XCTAssertLessThan(depth, License.allCases.count + 1,
                                  "Licence chain from '\(start.rawValue)' did not terminate.")
            }
        }
    }

    /// `missingHardRequirements` should report the gaps for a fresh player and go
    /// empty once those exact gaps are filled — a sanity check on the queryable
    /// guidance helper. Uses a job that gates on a portfolio piece.
    func testMissingHardRequirementsClearsWhenSatisfied() {
        // Find a non-regulated job that requires a portfolio piece (so the gap is
        // a buildable project, easy to satisfy in-test).
        guard let job = JobCatalog.allJobs().first(where: {
            !$0.category.requiresCredentials
                && !$0.requirements.hardSkills.portfolioItems.isEmpty
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

        // Grant exactly the hard skills the job gates on (portfolio always; a
        // licence is checked in every field even when non-regulated).
        for piece in job.requirements.hardSkills.portfolioItems {
            player.hardSkills.portfolioItems.insert(piece)
        }
        for licence in job.requirements.hardSkills.licenses {
            player.hardSkills.licenses.insert(licence)
        }
        let after = CareerGraph.missingHardRequirements(for: job, player: player)
        XCTAssertEqual(
            after, [],
            "Granting the required portfolio pieces should clear the gaps for '\(job.id)', got: \(after)"
        )
    }
}
