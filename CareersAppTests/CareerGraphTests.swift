import XCTest
@testable import CareersApp

/// Structural validation of the career dependency graph. These are *catalogue*
/// invariants — reachability over the prerequisite DAG — so they run in
/// O(catalogue size), not as a combinatorial sweep of player states.

final class CatalogIntegrityTests: XCTestCase {

    private var fullTitles: Set<String> { Set(JobCatalog.allTitles) }
    private var baseTitles: Set<String> { Set(JobCatalog.allBaseTitles) }

    /// Pay is argued over in professional office work and posted everywhere else.
    /// Pinning both directions keeps the rule from drifting as roles are added.
    func testOnlyProfessionalOfficeRolesNegotiateSalary() {
        let jobs = JobCatalog.allJobs().filter { !$0.isEntrepreneurial }
        for job in jobs where job.salaryIsNegotiable {
            XCTAssertEqual(job.workSetting, .office,
                           "\(job.id) negotiates pay but isn't office work.")
            XCTAssertGreaterThanOrEqual(job.requirements.education.minEQF,
                                        GameConstants.negotiableSalaryMinEQF,
                                        "\(job.id) negotiates pay below the professional bar.")
        }
        // Hand-on and people-facing work is always a posted rate, however senior.
        for job in jobs where job.workSetting != .office {
            XCTAssertFalse(job.salaryIsNegotiable,
                           "\(job.id) is \(job.workSetting.rawValue) work — pay should be posted.")
        }
        // A founder sets their own terms; there is no offer to negotiate.
        for job in JobCatalog.allJobs() where job.isEntrepreneurial {
            XCTAssertFalse(job.salaryIsNegotiable, "\(job.id) is a venture, not an offer.")
        }
        // A public pay scale is a scale whatever the seniority: no rung of such a
        // ladder negotiates, however senior or well-schooled.
        for job in jobs where Job.publicPayScaleTitles.contains(job.baseTitle) {
            XCTAssertFalse(job.salaryIsNegotiable,
                           "\(job.id) is on a public pay scale — no rung of it negotiates.")
        }
        // The rule has to actually split the catalogue, not collapse to one side.
        let negotiable = jobs.filter(\.salaryIsNegotiable).count
        XCTAssertGreaterThan(negotiable, 0, "No role negotiates — the bar is too high.")
        XCTAssertLessThan(negotiable, jobs.count, "Every role negotiates — the bar does nothing.")
    }

    /// The Education sheet files each course under its field of study and lists
    /// the licences on their own. Every credential must land in exactly one of
    /// those two places, or a course the game still gates jobs on would be
    /// unreachable.
    func testEveryTrainingIsReachableInEducation() {
        let filed = Set(Training.allCases.filter { $0.profile != nil })
        let general = Set(Training.allCases.filter { $0.profile == nil })
        XCTAssertEqual(filed.union(general), Set(Training.allCases),
                       "Every training is either filed under a profile or general.")
        XCTAssertTrue(filed.isDisjoint(with: general),
                      "No training may be in both places.")
    }

    /// A licence qualifies you to practise rather than teaching you a field, so
    /// the Education sheet never files it under a faculty — even though it may
    /// still belong to one, which is what tells a graduate it has opened up.
    func testStatutoryLicencesAreNeverFiledUnderAProfile() {
        for training in Training.allCases where training.isStatutory {
            XCTAssertNil(training.profile,
                         "\(training.rawValue) is a licence and must stay general.")
        }
        XCTAssertNotNil(Training.bar.studyField,
                        "A licence still belongs to a faculty — the bar exam is law.")
    }

    /// The converse: every course *is* filed. An unfiled one would silently fall
    /// into the licence list, where a player looking for it in their field would
    /// never find it.
    func testEveryCourseIsFiledUnderAProfile() {
        for training in Training.allCases where !training.isStatutory {
            XCTAssertNotNil(training.profile,
                            "\(training.rawValue) is a course with no field of study. "
                            + "Add a Training.studyFieldByTraining row.")
        }
    }

    /// A credential's field has to be one the Education sheet can actually reach.
    func testFiledTrainingsUseRealProfiles() {
        for (training, profile) in Training.studyFieldByTraining {
            XCTAssertTrue(TertiaryProfile.allCases.contains(profile),
                          "\(training.rawValue) is filed under an unknown profile.")
        }
    }

    /// Tables keyed by *base* title, so one entry covers every rung of a ladder.
    func testBaseTitleOverridesNameRealJobs() {
        let tables: [(String, [String])] = [
            ("softSkillsByBaseTitle", Array(JobCatalog.softSkillsByBaseTitle.keys)),
            ("credentialsByBaseTitle", Array(JobCatalog.credentialsByBaseTitle.keys)),
            ("acceptedProfilesByBaseTitle", Array(JobCatalog.acceptedProfilesByBaseTitle.keys)),
            ("workSettingByBaseTitle", Array(JobCatalog.workSettingByBaseTitle.keys)),
            ("Job.publicPayScaleTitles", Array(Job.publicPayScaleTitles)),
        ]
        let known = baseTitles
        for (name, keys) in tables {
            let orphans = Set(keys).subtracting(known).sorted()
            XCTAssertTrue(orphans.isEmpty,
                          "\(name) has keys that are not the base title of any job: \(orphans). "
                          + "Either the job was renamed or the key carries a seniority prefix "
                          + "(this table is looked up through Job.baseTitle, so a prefixed key can never match).")
        }
    }

    /// Tables keyed by *full* title, so they attach to one rung only.
    func testFullTitleOverridesNameRealJobs() {
        let tables: [(String, [String])] = [
            ("credentialsByFullTitle", Array(JobCatalog.credentialsByFullTitle.keys)),
            ("minYearsByTitle", Array(JobCatalog.minYearsByTitle.keys)),
        ]
        let known = fullTitles
        for (name, keys) in tables {
            let orphans = Set(keys).subtracting(known).sorted()
            XCTAssertTrue(orphans.isEmpty,
                          "\(name) has keys matching no job title: \(orphans). The job was probably renamed.")
        }
    }

    func testJobTitlesAreUnique() {
        let titles = JobCatalog.allTitles
        let dupes = Set(titles.filter { t in titles.filter { $0 == t }.count > 1 }).sorted()
        XCTAssertTrue(dupes.isEmpty, "Duplicate job titles would produce two jobs with one id: \(dupes).")
    }

    /// `job(from:)` raises a role's education floor to whatever its mandated
    /// credentials require, so a job can never demand a credential the player
    /// couldn't have earned at its stated level.
    func testStatedEducationCoversMandatedCredentials() {
        for job in JobCatalog.allJobs() {
            let needed = job.requirements.hardSkills.trainings.map(\.minEQF).max() ?? 0
            XCTAssertGreaterThanOrEqual(
                job.requirements.education.minEQF, needed,
                "\(job.id) states EQF \(job.requirements.education.minEQF) but mandates a credential needing \(needed).")
        }
    }

    /// Carrying `targetCapital` is what makes a role a venture — not its category.
    func testVentureFlagAndCapitalAgree() {
        for job in JobCatalog.allJobs() {
            XCTAssertEqual(job.targetCapital != nil, job.isEntrepreneurial,
                           "\(job.id): targetCapital and isEntrepreneurial disagree.")
        }
        for venture in JobCatalog.ventures {
            XCTAssertGreaterThan(venture.targetCapital ?? 0, 0,
                                 "Venture \(venture.title) must stake capital.")
        }
    }

    /// A ladder's rungs are its promotion chain: every rung must be reachable by
    /// stepping one index at a time from the entry rung, and no two rungs may
    /// share a position. Parsed seniority prefixes could tie — staff and
    /// principal both ranked 5, so the promotion pick was shuffle-dependent and
    /// staff was a dead end. Declared order cannot.
    func testLaddersFormAnUnambiguousChain() {
        for ladder in JobCatalog.ladders {
            XCTAssertGreaterThan(ladder.rungs.count, 1,
                                 "\(ladder.name) has one rung — it belongs in standaloneRoles.")
            let rungs = JobCatalog.jobs(for: ladder)
            XCTAssertEqual(rungs.map(\.rung), Array(0..<ladder.rungs.count),
                           "\(ladder.name) rungs must be numbered 0..<n in declared order.")
            XCTAssertEqual(Set(rungs.map(\.baseTitle)), [ladder.name],
                           "Every rung of \(ladder.name) should share its base title.")
            for (lower, upper) in zip(rungs, rungs.dropFirst()) {
                // Pay climbs with the rung — a promotion is never a demotion.
                XCTAssertLessThan(lower.income, upper.income,
                                  "\(ladder.name): \(upper.id) should out-earn \(lower.id).")
                // Requirements never ease off going up. This is what makes
                // stepping exactly one rung correct: a rung you don't yet
                // qualify for can't be hiding an easier one above it.
                XCTAssertGreaterThanOrEqual(
                    upper.requirements.minYearsExperience, lower.requirements.minYearsExperience,
                    "\(ladder.name): \(upper.id) should not expect less experience than \(lower.id).")
                XCTAssertGreaterThanOrEqual(
                    upper.requirements.education.minEQF, lower.requirements.education.minEQF,
                    "\(ladder.name): \(upper.id) should not require less education than \(lower.id).")
            }
        }
    }

    /// Ladder names and standalone titles share one namespace — `Job.baseTitle`
    /// keys tenure and the jobs list, so a collision would merge two roles.
    func testBaseTitlesAreUnique() {
        let bases = JobCatalog.allBaseTitles
        let dupes = Set(bases.filter { b in bases.filter { $0 == b }.count > 1 }).sorted()
        XCTAssertTrue(dupes.isEmpty, "Base titles collide: \(dupes).")
    }

    /// Every work setting must be represented, or the jobs filter would offer a
    /// chip that matches nothing.
    func testEveryWorkSettingHasRoles() {
        let jobs = JobCatalog.allJobs().filter { !$0.isEntrepreneurial }
        for setting in WorkSetting.allCases {
            let roles = Set(jobs.filter { $0.workSetting == setting }.map(\.baseTitle))
            XCTAssertFalse(roles.isEmpty, "No role is \(setting.rawValue) — the filter would show an empty list.")
        }
    }

    /// A ladder is one role, so its rungs must share a setting — otherwise the
    /// same job would appear under two different filters as the player climbs.
    func testLadderRungsShareAWorkSetting() {
        for ladder in JobCatalog.ladders {
            let settings = Set(JobCatalog.jobs(for: ladder).map(\.workSetting))
            XCTAssertEqual(settings.count, 1,
                           "\(ladder.name) rungs disagree on work setting: \(settings.map(\.rawValue).sorted()).")
        }
    }

    /// Outside the regulated professions a degree must never *block* an
    /// application — that is the whole point of the split — but it must move the
    /// odds a lot. Shape assertions rather than magic numbers, so retuning the
    /// constants doesn't break the suite; only reversing the design would.
    func testDegreeIsASignificantHiringFactorWhereItIsNotAGate() {
        // A role that declares accepted degree fields — some categories list
        // none, and there any degree at the right level counts as relevant.
        let jobs = JobCatalog.allJobs().filter {
            !$0.isEntrepreneurial && !$0.educationIsMandatory
                && $0.requirements.education.minEQF >= 5
                && !($0.requirements.education.acceptedProfiles ?? []).isEmpty
        }
        guard let job = jobs.first else { return XCTFail("No non-regulated degree-level role.") }
        let accepted = job.requirements.education.acceptedProfiles ?? []

        let none = Self.candidate(eqf: nil, profile: nil)
        let short = Self.candidate(eqf: .HighSchool, profile: nil)
        let unrelated = Self.candidate(eqf: .Bachelor,
                                       profile: TertiaryProfile.allCases.first { !accepted.contains($0) })
        let relevant = Self.candidate(eqf: .Bachelor, profile: accepted.first)

        // Never a gate: no degree still leaves the application open.
        XCTAssertTrue(job.educationGateMet(for: none),
                      "A degree must not hard-gate \(job.id) — it isn't a regulated profession.")

        let terms = [none, short, unrelated, relevant].map { job.educationFactor(for: $0) }
        XCTAssertEqual(terms, terms.sorted(),
                       "Education multiplier should improve monotonically: none <= short <= unrelated <= relevant, got \(terms).")
        XCTAssertLessThan(terms[0], 1, "No degree should scale the odds down for a degree-level role.")
        XCTAssertGreaterThan(terms[3], 1, "The expected degree in an accepted field should pay.")
        XCTAssertGreaterThan(terms[3] - terms[0], 0.25,
                             "A degree should swing the odds substantially, not marginally.")
        XCTAssertGreaterThan(terms[3], terms[2],
                             "A degree in an accepted field should beat an unrelated one.")
    }

    /// The same factor has to reach promotions, not just hiring — being
    /// under-credentialled for the role you hold should cap how far you climb.
    func testDegreeMovesPromotionOdds() {
        guard let job = JobCatalog.allJobs().first(where: {
            !$0.isEntrepreneurial && !$0.educationIsMandatory
                && $0.requirements.education.minEQF >= 5 && !$0.isLowSkilled
        }) else { return XCTFail("No non-regulated degree-level skilled role.") }

        let none = Self.candidate(eqf: nil, profile: nil)
        let relevant = Self.candidate(eqf: .Bachelor,
                                      profile: job.requirements.education.acceptedProfiles?.first)
        let withoutDegree = none.promotionOdds(for: job)
        let withDegree = relevant.promotionOdds(for: job)

        XCTAssertLessThan(withoutDegree.education, 0,
                          "Holding a degree-level role without the degree should hold promotions back.")
        XCTAssertGreaterThan(withDegree.total, withoutDegree.total,
                             "The degree should raise the annual promotion odds.")
        XCTAssertGreaterThanOrEqual(withoutDegree.total, 0, "Odds must never go negative.")
    }

    /// A candidate identical but for their education, for the tests above.
    private static func candidate(eqf: Level.Stage?, profile: TertiaryProfile?) -> Player {
        let player = Player()
        player.age = 40
        for keyPath in SoftSkills.skillNames.map(\.keyPath) { player.softSkills[keyPath: keyPath] = 5 }
        for category in JobCategory.allCases { player.experience[category] = 20 }
        if let eqf {
            player.degrees = profile.map { [Education(eqf, profile: $0)] } ?? [Education(eqf)]
        }
        return player
    }

    /// Every credential must have a row in `rulesByTraining`. Without this, a new
    /// `Training` case silently takes the struct defaults — a statutory licence
    /// that quietly stops gating hiring, for instance.
    func testEveryTrainingHasRules() {
        let missing = Training.allCases.filter { Training.rulesByTraining[$0] == nil }
        XCTAssertTrue(missing.isEmpty,
                      "Trainings with no rules row: \(missing.map(\.rawValue)). Add them to Training.rulesByTraining.")
    }

    /// A prerequisite chain must terminate, or a credential could never be earned.
    func testTrainingPrerequisitesTerminate() {
        /// The chain that revisits a credential, or nil when it terminates.
        func cycle(from training: Training, seen: [Training] = []) -> [Training]? {
            if let loop = seen.firstIndex(of: training) { return Array(seen[loop...]) + [training] }
            for prerequisite in training.prerequisites {
                if let found = cycle(from: prerequisite, seen: seen + [training]) { return found }
            }
            return nil
        }
        for training in Training.allCases {
            let found = cycle(from: training)
            XCTAssertNil(found, "\(training.rawValue) has a cyclic prerequisite chain: "
                         + (found?.map(\.rawValue).joined(separator: " -> ") ?? ""))
        }
    }
}

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
                && !$0.isLadderVariant
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

    /// Work experience should lift any project's odds — not only the ones that
    /// build experience of their own — and years in the project's own field
    /// should count twice over.
    func testExperienceRaisesProjectOdds() {
        guard let venture = SideHustleCatalog.byId["crowdfundingCampaign"],
              let plain = SideHustleCatalog.byId["projectApp"] else {
            XCTFail("Expected projects missing from catalogue."); return
        }
        let soft = SoftSkills()
        for project in [venture, plain] {
            let cold = project.successProbability(for: soft, totalExperienceYears: 0)
            let seasoned = project.successProbability(for: soft, totalExperienceYears: 10)
            XCTAssertGreaterThan(seasoned, cold,
                                 "A working career should raise '\(project.id)' odds.")
        }
        XCTAssertEqual(plain.experienceFit(totalYears: 4, fieldYears: 4),
                       plain.experienceFit(totalYears: 8, fieldYears: 0),
                       accuracy: 0.0001,
                       "Years in the project's own field should count twice.")
        XCTAssertEqual(plain.experienceFit(totalYears: 500, fieldYears: 500), 1.0,
                       "The experience term should cap out at a full fit.")
    }

    /// Nothing gates a project any more, so the odds have to carry the meaning:
    /// a player with no talent and no career rolls against nothing, and no
    /// player ever exceeds the project's own ceiling.
    func testProjectOddsSpanZeroToCeiling() {
        let green = SoftSkills()
        for project in SideHustleCatalog.all {
            XCTAssertEqual(project.successProbability(for: green), 0, accuracy: 0.0001,
                           "'\(project.id)' should be a hopeless shot with no skills and no career.")
        }
        var maxed = SoftSkills()
        for skill in SoftSkills.skillNames { maxed[keyPath: skill.keyPath] = 10 }
        for project in SideHustleCatalog.all {
            let best = project.successProbability(
                for: maxed, famePoints: 1_000,
                totalExperienceYears: 100, fieldExperienceYears: 100
            )
            XCTAssertLessThanOrEqual(best, project.successCeiling + 0.0001,
                                     "'\(project.id)' must never beat its own ceiling.")
            XCTAssertGreaterThan(best, 0,
                                 "'\(project.id)' should be winnable once fully built up.")
        }
    }

    /// A committed project year pays its soft-skill growth whether or not the
    /// project lands; only the fame award turns on the roll. Driven with a
    /// guaranteed flop — a player with no skills and no career rolls 0% (see
    /// `testProjectOddsSpanZeroToCeiling`) — so the growth observed here cannot
    /// have come from a success.
    func testFlopStillGrowsSkillsButBanksNoFame() {
        guard let project = SideHustleCatalog.byId["projectApp"] else {
            XCTFail("Missing project 'projectApp'."); return
        }
        XCTAssertFalse(project.growth.isEmpty,
                       "This test is only meaningful for a project that grants growth.")

        // `Player()` randomises starting skills 0...1, which is enough to roll a
        // few percent — so the flop has to be forced with genuinely empty ones.
        let player = Player(softSkills: SoftSkills())
        let appUIState = AppUIState()
        XCTAssertEqual(player.projectOdds(for: project), 0, accuracy: 0.0001,
                       "A green player should be a guaranteed flop — the premise of this test.")

        let before = project.growth.map { player.softSkills[keyPath: $0.keyPath] }
        appUIState.selectedSideHustles = [project.id]
        player.advanceYear(appUIState: appUIState)

        for (ability, was) in zip(project.growth, before) {
            XCTAssertEqual(player.softSkills[keyPath: ability.keyPath], was + ability.weight,
                           "A flopped project should still bank its \(ability.weight)-point gain.")
        }
        XCTAssertTrue(player.fameAwards.isEmpty,
                      "A flopped project must bank no fame.")
    }

    /// Reputation feeds the next attempt, but only inside its own bucket: fame
    /// banked in the project's own `FameCategory` lifts its odds, and fame from
    /// an unrelated field does nothing — the same rule hiring uses.
    func testProjectOddsRiseWithSameBucketFameOnly() {
        guard let project = SideHustleCatalog.byId["projectApp"] else {
            XCTFail("Missing project 'projectApp'."); return
        }
        let bucket = project.fameCategory
        guard let otherBucket = FameCategory.allCases.first(where: { $0 != bucket }) else {
            XCTFail("Expected more than one fame bucket."); return
        }

        // Some talent, so the baseline isn't pinned at the 0 floor where a lift
        // would be invisible.
        var soft = SoftSkills()
        for ability in project.talents { soft[keyPath: ability] = 5 }

        let cold = Player(softSkills: soft)
        let baseline = cold.projectOdds(for: project)

        let sameField = Player(softSkills: soft)
        sameField.award("Same-field renown", icon: "🌟", category: bucket, weight: 5)
        XCTAssertGreaterThan(sameField.projectOdds(for: project), baseline,
                             "Fame in the project's own field should lift its odds.")

        let otherField = Player(softSkills: soft)
        otherField.award("Unrelated renown", icon: "🌟", category: otherBucket, weight: 5)
        XCTAssertEqual(otherField.projectOdds(for: project), baseline, accuracy: 0.0001,
                       "Fame from an unrelated field should not lift this project's odds.")
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
            "pitch-competition":(.business,         .business,     "Pitch Winner"),
        ]
        for (id, (category, fame, title)) in expected {
            guard let event = EventCatalog.byId[id] else {
                XCTFail("Missing spotlight event '\(id)'."); continue
            }
            XCTAssertEqual(event.category, category, "'\(id)' should serve \(category.rawValue).")
            XCTAssertEqual(event.presenterFameTitle, title, "'\(id)' should bank a bespoke accolade.")
            XCTAssertEqual(event.category.fameCategory, fame, "'\(id)' fame should land in \(fame).")
        }
    }

    // MARK: - Skill-building trainings (career-boost credentials)

    /// The new creative/digital programs are non-statutory, non-gating credentials
    /// whose value is the career edge they confer in the right fields.
    func testSkillBuildingTrainingsAreNonGatingBoosts() {
        let expected: [Training: Set<JobCategory>] = [
            .codingBootcamp:     [.technology, .engineering],
            .gameDevProgram:     [.design, .technology],
            .productDesign:      [.design],
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
            $0.category == .business && !$0.isLadderVariant && !$0.isTopLeadership
        }) {
            XCTAssertFalse(analyst.isExecutive, "A rank-and-file role shouldn't unlock the Boardroom.")
        }
        // A top-leadership role outside the commercial fields (e.g. a Head Chef)
        // tops out its ladder but doesn't run a cap table.
        if let nonCommercial = jobs.first(where: {
            $0.isTopLeadership && !$0.isEntrepreneurial
                && ![.business, .entrepreneurship, .technology].contains($0.category)
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

    // MARK: - Run horizon

    /// The run ends at `GameConstants.retirementAge`, and the score is final
    /// there. This is what bounds the score at all: savings compound every year
    /// whether or not the player works, so net worth grows geometrically while
    /// age grows linearly — past age ~1/investmentReturn the ratio rises on its
    /// own and idling would raise the score forever.
    func testRunEndsAtRetirementAndScoreStopsMoving() {
        let player = Player()
        let appUIState = AppUIState()
        player.difficulty = .middleClass
        player.age = GameConstants.retirementAge - 1
        player.savings = 1_000_000
        XCTAssertFalse(player.hasRetired, "Premise: one year still to live.")

        player.advanceYear(appUIState: appUIState)
        XCTAssertTrue(player.hasRetired, "Reaching the retirement age ends the run.")
        XCTAssertTrue(appUIState.showRetirementSheet,
                      "The final year should raise the Game Over sheet by itself.")

        // Past the horizon nothing may move: not the age, not the score.
        let finalAge = player.age
        let finalScore = player.leaderboardScore
        for _ in 0..<25 { player.advanceYear(appUIState: appUIState) }
        XCTAssertEqual(player.age, finalAge, "No years pass after retirement.")
        XCTAssertEqual(player.leaderboardScore, finalScore,
                       "The score is final — idling past the horizon cannot raise it.")
    }

    /// The exploit this horizon closes, stated as arithmetic: with compounding
    /// alone the score climbs every year once the player is past ~17, so without
    /// a horizon the best strategy is to stop playing and let the clock run.
    func testIdlingWouldOtherwiseRaiseTheScoreForever() {
        let r = GameConstants.investmentReturn
        let breakEven = 1.0 / r
        XCTAssertLessThan(breakEven, Double(GameConstants.retirementAge),
                          "The horizon has to sit above the age where idling starts paying.")
        var netWorth = 500_000.0
        var age = Double(GameConstants.retirementAge)
        let scoreAtHorizon = netWorth / age
        netWorth *= (1 + r); age += 1
        XCTAssertGreaterThan(netWorth / age, scoreAtHorizon,
                             "Compounding outruns ageing — which is exactly why the run has to stop.")
    }

    // MARK: - Breakthrough-gated star careers

    /// The three star tracks (pro athlete, movie star, pop star) exist in the
    /// catalogue and are effectively closed without their signature achievement:
    /// a fully-qualified applicant who lacks the award sits at the 5% floor, and
    /// holding it lifts the odds well above the floor.
    func testStarCareersAreBreakthroughGated() {
        let jobs = JobCatalog.allJobs()
        let gates: [(base: String, award: String)] = [
            ("Player", "Junior Champion"),
            ("Movie Star", "Breakout Role"),
            ("Pop Star", "Hit Record"),
        ]
        for gate in gates {
            // Use the easiest-to-qualify rung of the ladder (lowest seniority).
            guard let job = jobs
                .filter({ $0.baseTitle == gate.base })
                .min(by: { $0.rung < $1.rung }) else {
                XCTFail("Missing star career '\(gate.base)' in the catalogue.")
                continue
            }
            XCTAssertEqual(job.breakthroughFame, gate.award,
                           "\(gate.base) should gate on the '\(gate.award)' award.")

            let player = Player()
            player.difficulty = .middleClass
            player.configureStart(age: 40)          // clears the entry rungs' light gates
            XCTAssertTrue(job.allRequirementsMet(for: player),
                          "A 40-year-old should meet the entry rung's requirements for '\(job.id)'.")

            let salary = Double(job.annualIncome)
            let gated = job.hireProbability(for: player, requestedSalary: salary)
            XCTAssertEqual(gated, 0.05, accuracy: 0.0001,
                           "Without the breakthrough, '\(job.id)' odds sit at the 5% floor.")

            player.award(gate.award, icon: "🏅", category: .entertainment, weight: 2.0)
            let opened = job.hireProbability(for: player, requestedSalary: salary)
            XCTAssertGreaterThan(opened, gated,
                                 "Holding the '\(gate.award)' award should open '\(job.id)' up.")
        }
    }

    // MARK: - Early-choice balance (Phase 3)

    /// An elite school turns away even a flawless applicant a good share of the
    /// time — a maxed candidate tops out around 65%, not the old 82%.
    func testEliteAdmissionTurnsAwayEvenTopApplicants() {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)            // high-school record clears the EQF gate
        for axis in SoftSkills.allAxes { player.softSkills[keyPath: axis.keyPath] = 10 }

        let elite = Education(.Bachelor, profile: .business, tier: .elite)
        let odds = elite.admissionProbability(player: player)
        XCTAssertGreaterThan(odds, 0.5, "A perfect applicant should still have a real shot.")
        XCTAssertLessThanOrEqual(odds, 0.66, "An elite school shouldn't be a near-lock even when maxed.")
    }

    /// Applying costs the year whether or not you get in, so a school-leaver with
    /// nothing built yet has to have somewhere they can count on. The tiers must
    /// also stay ordered at every strength — otherwise the choice between them is
    /// not a trade, it is just a worse option.
    func testAdmissionTiersStayOrderedAndTheOpenDoorStaysOpen() {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)

        func odds(_ tier: EducationTier) -> Double {
            Education(.Bachelor, profile: .business, tier: tier).admissionProbability(player: player)
        }

        for level in [0, 2, 5, 10] {
            for axis in SoftSkills.allAxes { player.softSkills[keyPath: axis.keyPath] = level }
            XCTAssertGreaterThan(odds(.community), odds(.state),
                                 "At skill \(level) the community college should be the safer bet.")
            XCTAssertGreaterThan(odds(.state), odds(.elite),
                                 "At skill \(level) a state place should beat an elite one.")
        }

        // The floor is what makes a first application affordable: a fresh
        // school-leaver should expect to get into the open-admission tier, not
        // burn years being turned away with nothing to show for them.
        for axis in SoftSkills.allAxes { player.softSkills[keyPath: axis.keyPath] = 0 }
        XCTAssertGreaterThan(odds(.community), 0.6,
                             "An open-admission college should take a thin applicant most of the time.")
    }

    /// Soft skills are never a gate: an applicant who holds the prior
    /// qualification can always apply, whatever their soft skills look like.
    func testSoftSkillsNeverBlockAdmission() {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)            // high-school record clears the EQF gate
        for axis in SoftSkills.allAxes { player.softSkills[keyPath: axis.keyPath] = 0 }

        for profile in TertiaryProfile.allCases {
            for tier in EducationTier.allCases {
                let school = Education(.Bachelor, profile: profile, tier: tier)
                XCTAssertTrue(school.meetsRequirements(player: player),
                              "Zero soft skills shouldn't bar an application to \(profile.rawValue) (\(tier.rawValue)).")
                XCTAssertGreaterThan(school.admissionProbability(player: player), 0,
                                     "A blank-slate applicant should still have a shot at \(profile.rawValue) (\(tier.rawValue)).")
            }
        }
    }

    /// The prior-qualification level is the one hard gate — no Master's without a
    /// Bachelor's, no matter how good the soft skills are.
    func testEducationLevelIsTheOnlyHardGate() {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        for axis in SoftSkills.allAxes { player.softSkills[keyPath: axis.keyPath] = 10 }

        let master = Education(.Master, profile: .business, tier: .state)
        XCTAssertFalse(master.meetsRequirements(player: player),
                       "A high-school leaver can't enter a Master's, however strong their soft skills.")
        XCTAssertEqual(master.admissionProbability(player: player), 0,
                       "Missing the prerequisite degree leaves no admission chance at all.")
    }

    /// Soft skills earn their keep on the odds instead: better skills, better
    /// chances, all the way up to fully qualified.
    func testSoftSkillsRaiseAdmissionOdds() {
        let school = Education(.Bachelor, profile: .business, tier: .state)

        func odds(softSkillLevel: Int) -> Double {
            let player = Player()
            player.difficulty = .middleClass
            player.configureStart(age: 18)
            for axis in SoftSkills.allAxes { player.softSkills[keyPath: axis.keyPath] = softSkillLevel }
            return school.admissionProbability(player: player)
        }

        let none = odds(softSkillLevel: 0)
        let some = odds(softSkillLevel: 2)
        let strong = odds(softSkillLevel: 5)

        XCTAssertGreaterThan(some, none, "Building soft skills should improve the odds.")
        XCTAssertGreaterThan(strong, some, "More soft skills, better odds — up to fully qualified.")
    }

    /// Admission is a roll in every mode, Simplified included — no school is a
    /// formality, and none is a closed door.
    func testAdmissionIsProbabilisticInEveryMode() {
        for difficulty in Difficulty.allCases {
            let player = Player()
            player.difficulty = difficulty
            player.configureStart(age: 18)

            // The community tier is the one school Simplified offers, and the
            // most forgiving elsewhere — if even this is a roll, all of them are.
            let school = Education(.Bachelor, profile: .business, tier: .community)

            let blankSlate = school.admissionProbability(player: player)
            XCTAssertGreaterThan(blankSlate, 0,
                                 "A thin applicant should still have a chance in \(difficulty.title).")

            for axis in SoftSkills.allAxes { player.softSkills[keyPath: axis.keyPath] = 10 }
            let maxedOut = school.admissionProbability(player: player)
            XCTAssertGreaterThan(maxedOut, blankSlate,
                                 "Soft skills should pay off in \(difficulty.title).")
            XCTAssertLessThan(maxedOut, 1.0,
                              "Admission is never a certainty in \(difficulty.title).")
        }
    }

    /// The overlap the admissions screen shows is the same overlap the odds are
    /// computed from — every listed skill is one the school weighs, and their
    /// average is the fit that feeds `admissionProbability`.
    func testSoftSkillOverlapExplainsTheOdds() {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.softSkills.communicationAndNetworking = 2
        player.softSkills.presentationAndStorytelling = 9   // well past the target

        let school = Education(.Bachelor, profile: .business, tier: .state)
        let overlap = school.softSkillOverlap(player: player)

        XCTAssertFalse(overlap.isEmpty, "A business degree weighs some soft skills.")
        for axis in overlap {
            XCTAssertGreaterThan(axis.target, 0, "Only skills the school looks for are listed.")
            XCTAssertLessThanOrEqual(axis.fit, 1.0, "A surplus on one axis can't exceed a full match.")
        }

        let average = overlap.reduce(0.0) { $0 + $1.fit } / Double(overlap.count)
        XCTAssertEqual(school.softSkillFit(player: player), average, accuracy: 0.0001,
                       "The rows shown and the fit used must be the same number.")
    }

    /// Tuition the player can't cover in cash becomes an interest-bearing student
    /// loan that drags net worth — an expensive early degree is a lasting cost.
    func testUnaffordableTuitionBecomesAStudentLoan() {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.savings = 0
        let ui = AppUIState()
        player.currentEducation = Education(.Bachelor, profile: .business, tier: .elite)
        ui.yearsLeftToGraduation = 3

        XCTAssertEqual(player.studentLoan, 0, "No debt before the first tuition bill.")
        player.advanceYear(appUIState: ui)
        XCTAssertGreaterThan(player.studentLoan, 0,
                             "Unaffordable tuition should be borrowed as a student loan.")
        XCTAssertEqual(player.leaderboardScore, 0,
                       "A net-negative balance from the loan floors the score at 0.")
    }
}
