import Foundation

/// A thin, **derived** dependency graph over the game's discrete unlockables —
/// hobbies, projects, certifications, licences, and the jobs that consume them.
/// It is built entirely from the existing catalogue declarations (`hobbies`,
/// `Project`, `Certification`, `License`, `JobCatalog`); it introduces no new
/// source of truth and is never consulted by the hiring/odds maths.
///
/// It models *only* the **hard-prerequisite** layer — the part that is genuinely
/// a DAG ("you either hold the licence / portfolio piece or you don't"). The
/// continuous fitness factors (soft-skill fit, prestige, network, the experience
/// curve) are deliberately out of scope: those are weights in
/// `Job.hireProbability`, not dependencies, and trying to model them as graph
/// edges only adds ceremony.
///
/// Its two jobs are both read-only:
/// 1. `validateCatalogue()` — assert the catalogue is internally consistent
///    (no orphan/unreachable nodes, no prerequisite cycles, every job's hard
///    requirements producible). This is *reachability*, linear in catalogue
///    size — NOT a combinatorial sweep of player states.
/// 2. `missingHardRequirements(for:player:)` — answer "what does this player
///    still need for this job?" for the UI, which the scattered subset-checks
///    couldn't surface directly.
enum CareerGraph {

    /// Highest EQF a player can in principle attain (doctorate). Used to check
    /// that every credential's education gate is reachable at all.
    static let maxAttainableEQF = 7

    /// Every project that at least one hobby unlocks. A project outside this set
    /// can never be built, so any job requiring it would be unwinnable.
    static var unlockableProjects: Set<Project> {
        var result: Set<Project> = []
        for hobby in hobbies { result.formUnion(hobby.unlocks) }
        return result
    }

    // MARK: - Player guidance

    /// The *hard* gates the player has yet to clear for `job`, as short,
    /// player-facing strings. Mirrors `Job.allRequirementsMet` exactly but
    /// returns the gaps instead of a bool. Soft/odds factors are intentionally
    /// excluded — these are blockers, not nice-to-haves. An empty array means
    /// every hard gate is met (the player is hireable, subject to the odds roll).
    static func missingHardRequirements(for job: Job, player: Player) -> [String] {
        var gaps: [String] = []

        if !job.ageGateMet(for: player) {
            gaps.append("Reach working age (\(GameConstants.minimumWorkingAge))")
        }
        if job.educationIsMandatory, !job.educationMet(for: player) {
            gaps.append("Earn \(job.requirements.education.educationLabel())")
        }

        // Simplified mode hires on degree + experience alone (no hard-skill gate),
        // matching `Job.allRequirementsMet`.
        if !player.isSimplified {
            let req = job.requirements.hardSkills
            let held = player.hardSkills.trainings
            // Statutory trainings are required everywhere; non-statutory ones
            // (former certifications) only in regulated fields.
            let needed = req.trainings.filter { $0.isStatutory || job.category.requiresCredentials }
            for training in needed.subtracting(held)
                .sorted(by: { $0.rawValue < $1.rawValue }) {
                gaps.append("Training: \(training.friendlyName)")
            }
            // Everywhere else, employers hire on demonstrated portfolio work.
            if !job.category.requiresCredentials {
                for piece in req.portfolioItems.subtracting(player.hardSkills.portfolioItems)
                    .sorted(by: { $0.rawValue < $1.rawValue }) {
                    gaps.append("Portfolio: \(piece.rawValue)")
                }
            }
        }

        if !job.experienceMet(for: player) {
            gaps.append("\(job.requirements.minYearsExperience) yr(s) in \(job.category.rawValue)")
        }
        return gaps
    }

    // MARK: - Catalogue validation

    /// Structural invariants over the prerequisite graph. Linear in catalogue
    /// size (reachability, not a combinatorial player-state sweep). An empty
    /// result means every unlockable is reachable and every job's hard
    /// requirements are in principle satisfiable.
    ///
    /// Run as a DEBUG launch assertion (see `Main.init`); also trivially liftable
    /// into an XCTest if a test target is ever added: `XCTAssertEqual(
    /// CareerGraph.validateCatalogue(), [])`.
    ///
    /// Not yet covered (honest scope): that a job's `acceptedProfiles` are
    /// actually offered by the education system, and that the soft-skill
    /// *thresholds* on credentials are reachable within the per-year slot/age
    /// economy. The former needs the tertiary-profile catalogue; the latter is a
    /// feasibility question better answered by a scenario/Monte-Carlo test than
    /// by static reachability.
    static func validateCatalogue() -> [String] {
        var issues: [String] = []
        let buildable = unlockableProjects

        // 1. No orphan projects — every project must be unlocked by some hobby,
        //    or it can never enter the portfolio.
        for project in Project.allCases where !buildable.contains(project) {
            issues.append("Project ‘\(project.rawValue)’ is unlocked by no hobby — unreachable.")
        }

        // 2. The training prerequisite chain must stay acyclic (it is a DAG).
        issues.append(contentsOf: trainingCycleIssues())

        // 3. Credential education gates must be attainable at all.
        for training in Training.allCases where training.minEQF > maxAttainableEQF {
            issues.append("Training ‘\(training.rawValue)’ needs EQF \(training.minEQF) > max attainable \(maxAttainableEQF).")
        }

        // 4. Every job's hard requirements must be producible.
        for job in JobCatalog.allJobs() {
            let req = job.requirements.hardSkills
            for piece in req.portfolioItems where !buildable.contains(piece) {
                issues.append("Job ‘\(job.id)’ requires portfolio ‘\(piece.rawValue)’, which no hobby unlocks.")
            }
            if job.requirements.education.minEQF > maxAttainableEQF {
                issues.append("Job ‘\(job.id)’ needs EQF \(job.requirements.education.minEQF) > max attainable \(maxAttainableEQF).")
            }
        }

        return issues
    }

    /// Depth-first cycle detection over `Training.prerequisites`. Reports the
    /// offending chain so a future bad edge is easy to spot.
    private static func trainingCycleIssues() -> [String] {
        var issues: [String] = []
        // 0 = unvisited, 1 = on the current DFS stack, 2 = fully explored.
        var state: [Training: Int] = [:]

        func visit(_ training: Training, _ trail: [Training]) {
            switch state[training] {
            case 2: return
            case 1:
                let cycle = (trail + [training]).map(\.rawValue).joined(separator: " → ")
                issues.append("Training prerequisite cycle: \(cycle)")
                return
            default: break
            }
            state[training] = 1
            for prereq in training.prerequisites {
                visit(prereq, trail + [training])
            }
            state[training] = 2
        }

        for training in Training.allCases { visit(training, []) }
        return issues
    }
}
