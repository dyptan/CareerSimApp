import XCTest
@testable import CareersApp

/// The advisor's coaching is judged on what it *says* about the game — which
/// gaps it names, when it starts suggesting roles, what it flags at a review —
/// not on wording, so these pin the coach's structure and leave the phrasing free.
final class AdvisorCoachTests: XCTestCase {

    /// A realistic-mode player of `age` with no skills and no plan yet.
    private func player(age: Int, simplified: Bool = false) -> Player {
        let player = Player()
        player.difficulty = simplified ? .simplified : .middleClass
        player.configureStart(age: 18)
        player.age = age
        player.softSkills = SoftSkills()
        return player
    }

    /// Advances the player's age the way a year does, without rolling anything.
    private func passYear(_ player: Player, practising sports: Set<Sport> = []) {
        player.age += 1
        player.lastYearSports = sports
        for sport in sports { player.sportYears[sport, default: 0] += 1 }
    }

    // MARK: - Finding a role

    func testSearchFindsARoleByItsTitleOrAWordOfIt() {
        XCTAssertEqual(AdvisorCoach.search("Registered Nurse").first?.baseTitle, "Registered Nurse")
        XCTAssertTrue(AdvisorCoach.search("I want to be a nurse").map(\.baseTitle).contains("Registered Nurse"))
        XCTAssertTrue(AdvisorCoach.search("software").prefix(3).map(\.baseTitle).contains("Software Engineer"))
        XCTAssertTrue(AdvisorCoach.search("game").map(\.baseTitle).contains("Game Designer"))
    }

    func testSearchSaysNothingForWordsThatNameNoRole() {
        XCTAssertTrue(AdvisorCoach.search("xyzzy").isEmpty)
        XCTAssertTrue(AdvisorCoach.search("I want to be a").isEmpty, "Filler words alone name nothing.")
        XCTAssertTrue(AdvisorCoach.search("").isEmpty)
    }

    func testListsReadLikeSentences() {
        XCTAssertEqual(AdvisorCoach.list([]), "")
        XCTAssertEqual(AdvisorCoach.list(["a"]), "a")
        XCTAssertEqual(AdvisorCoach.list(["a", "b"]), "a and b")
        XCTAssertEqual(AdvisorCoach.list(["Technology", "Engineering", "Science"], conjunction: "or"),
                       "Technology, Engineering or Science")
    }

    // MARK: - Finding a role in every language

    /// What the player types is read in the game's language. The headless tests have no catalog, so
    /// the roles' display names are their English ids: these exercise the tokenizer, the folding and
    /// the matching directly, with hand-written tokens, and the search with the language pinned.
    private func withLanguage(_ language: L10n.Language, _ body: () throws -> Void) rethrows {
        let before = L10n.languageOverride
        L10n.languageOverride = language
        defer { L10n.languageOverride = before }
        try body()
    }

    func testEnglishQueriesReadAsTheyAlwaysDid() {
        XCTAssertEqual(AdvisorCoach.contentWords("I want to be a nurse", language: .english), ["nurse"])
        XCTAssertEqual(AdvisorCoach.contentWords("I'm a Junior Developer!", language: .english), ["junior", "developer"])
        XCTAssertEqual(AdvisorCoach.contentWords("I want to be a", language: .english), [])
        XCTAssertEqual(AdvisorCoach.tokens("Software-Engineer, e-mail", language: .english), ["software", "engineer", "e", "mail"])
    }

    func testJapaneseIsSegmentedIntoWordsAndTheParticlesDropped() {
        // No spaces in Japanese: the system tokenizer finds the words.
        XCTAssertGreaterThan(AdvisorCoach.tokens("看護師になりたい", language: .japanese).count, 1)
        // "I want to be a nurse" → the nurse. (Split as 看護 + 師 or whole, depending on the system.)
        XCTAssertEqual(AdvisorCoach.contentWords("看護師になりたい", language: .japanese).joined(), "看護師")
        // "I like animals" → animals; が、好き and です are filler.
        XCTAssertEqual(AdvisorCoach.contentWords("動物が好きです", language: .japanese).joined(), "動物")
        // A single kanji is a word; a single kana is a particle.
        XCTAssertFalse(AdvisorCoach.isFiller("医", language: .japanese))
        XCTAssertTrue(AdvisorCoach.isFiller("を", language: .japanese))
    }

    func testDiacriticsCaseAndWidthDoNotMatter() {
        XCTAssertEqual(AdvisorCoach.fold("Ärztin", language: .german), AdvisorCoach.fold("ARZTIN", language: .german))
        XCTAssertEqual(AdvisorCoach.fold("Straße", language: .german), "strasse")
        XCTAssertEqual(AdvisorCoach.fold("Infirmière", language: .french), "infirmiere")
        XCTAssertEqual(AdvisorCoach.fold("Élève", language: .french), AdvisorCoach.fold("eleve", language: .french))
        XCTAssertEqual(AdvisorCoach.fold("Farmacista Più", language: .italian), "farmacista piu")
        XCTAssertEqual(AdvisorCoach.fold("ＡＢＣ ｿﾌﾄ", language: .japanese), "abc ソフト")
        // Ukrainian keeps й and ї: they are letters of their own, not accents.
        XCTAssertEqual(AdvisorCoach.fold("Їжак Київ", language: .ukrainian), "їжак київ")
    }

    func testFillerWordsAreDroppedInEachLanguage() {
        XCTAssertEqual(AdvisorCoach.contentWords("Ich möchte Krankenpfleger werden", language: .german), ["krankenpfleger"])
        XCTAssertEqual(AdvisorCoach.contentWords("Je voudrais devenir infirmière", language: .french), ["infirmiere"])
        XCTAssertEqual(AdvisorCoach.contentWords("Voglio fare l'infermiere", language: .italian), ["infermiere"])
        XCTAssertEqual(AdvisorCoach.contentWords("Я хочу бути лікарем", language: .ukrainian), ["лікарем"])
        // English words typed into a German game are filler too.
        XCTAssertEqual(AdvisorCoach.contentWords("I want to be Pilot", language: .german), ["pilot"])
    }

    func testWordsMatchOnTheirStemsAndTheirHeads() {
        XCTAssertTrue(AdvisorCoach.matches("nurs", "nurse", language: .english))
        XCTAssertFalse(AdvisorCoach.matches("cat", "category", language: .english), "Under four letters is exact only.")
        // A German compound is found by its head, which English never does.
        XCTAssertTrue(AdvisorCoach.matches("pfleger", "krankenpfleger", language: .german))
        XCTAssertFalse(AdvisorCoach.matches("pfleger", "krankenpfleger", language: .english))
        // A Japanese word is found inside a longer one.
        XCTAssertTrue(AdvisorCoach.matches("看護師", "看護師長", language: .japanese))
        XCTAssertFalse(AdvisorCoach.matches("看護師", "薬剤師", language: .japanese))
    }

    func testTokensThatFillTheCatalogueAreFillerToo() {
        let documents = (0..<30).map { Set(["arbeit", "rolle\($0)"]) }
        XCTAssertEqual(AdvisorCoach.frequentTokens(in: documents), ["arbeit"])
        XCTAssertTrue(AdvisorCoach.isFiller("arbeit", language: .german, frequent: ["arbeit"]))
        XCTAssertFalse(AdvisorCoach.isFiller("rolle1", language: .german, frequent: ["arbeit"]))
        XCTAssertTrue(AdvisorCoach.frequentTokens(in: Array(documents.prefix(5))).isEmpty, "Nothing to learn from a handful of roles.")
    }

    func testTheSearchFindsEnglishTitlesInEveryLanguage() {
        for language in L10n.Language.allCases {
            withLanguage(language) {
                XCTAssertTrue(AdvisorCoach.search("nurse").map(\.baseTitle).contains("Registered Nurse"), language.rawValue)
                XCTAssertEqual(AdvisorCoach.search("Registered Nurse").first?.baseTitle, "Registered Nurse", language.rawValue)
                XCTAssertTrue(AdvisorCoach.search("xyzzy").isEmpty, language.rawValue)
                XCTAssertTrue(AdvisorCoach.contentWords("nurse").contains("nurse"), language.rawValue)
            }
        }
    }

    func testSentencesAreSetApartBySpacesExceptInJapanese() {
        XCTAssertEqual(AdvisorCoach.sentences(["One.", "", "Two."]), "One. Two.")
        withLanguage(.japanese) { XCTAssertEqual(AdvisorCoach.sentences(["一。", "二。"]), "一。二。") }
    }

    func testNumbersAreWrittenThroughFmt() {
        XCTAssertEqual(AdvisorPathway.percent(0.304), Fmt.percent(0.304))
        XCTAssertEqual(CareerAdvisor.percent(0.5), Fmt.percent(0.5))
        XCTAssertEqual(AdvisorPathway.decimal(2.0), "2", "A whole number drops its decimal.")
        XCTAssertEqual(AdvisorPathway.decimal(0.34), Fmt.decimal(0.3, digits: 1))
        XCTAssertEqual(AdvisorPathway.chance(0.001), "under \(Fmt.percent(0.01))")
        XCTAssertEqual(AdvisorPathway.decimalPercent(0.04), Fmt.percent(0.04))
        XCTAssertTrue(AdvisorPathway.decimalPercent(0.005).contains("5"), "A half percent keeps its decimal.")
        XCTAssertNotEqual(AdvisorPathway.decimalPercent(0.005), AdvisorPathway.decimalPercent(0.01))
    }

    func testEveryRoleIsPickableAndLaddersRunEntryRungFirst() {
        XCTAssertFalse(AdvisorCoach.families.isEmpty)
        for family in AdvisorCoach.families {
            XCTAssertFalse(family.entry.isEntrepreneurial, "\(family.baseTitle) is a venture.")
            XCTAssertEqual(family.rungs.map(\.rung), Array(0..<family.rungs.count), family.baseTitle)
            XCTAssertTrue(AdvisorCoach.fields.contains(family.category), family.baseTitle)
        }
    }

    // MARK: - A role in mind

    func testGuideNamesWhatStandsBetweenAGraduateAndANurse() throws {
        let graduate = player(age: 18)
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: "Registered Nurse", player: graduate))
        let kinds = guide.steps.map(\.kind)
        XCTAssertEqual(kinds.first, .listing, "The listings link comes first.")
        XCTAssertTrue(kinds.contains(.education), "A nurse needs a diploma a school-leaver lacks.")
        XCTAssertTrue(kinds.contains(.licence), "…and the nursing licence.")
        XCTAssertFalse(kinds.contains(.apply), "There is nothing to apply for yet.")
        XCTAssertTrue(guide.closed)
        XCTAssertFalse(guide.canApply)
        XCTAssertTrue(guide.needs.contains("a college or vocational diploma"), "\(guide.needs)")
        let education = try XCTUnwrap(guide.steps.first { $0.kind == .education })
        XCTAssertEqual(education.card.actions.first?.effect, .go(.education))
    }

    func testGuideLinksToTheListingsOnlyWhileTheRoleIsPosted() throws {
        let graduate = player(age: 18)
        graduate.availableJobs = []
        let closed = try XCTUnwrap(AdvisorCoach.guide(for: "Chef", player: graduate))
        XCTAssertFalse(closed.posted)
        XCTAssertTrue(try XCTUnwrap(closed.steps.first).card.actions.isEmpty, "No postings, no link.")

        graduate.availableJobs = JobCatalog.allJobs()
        let open = try XCTUnwrap(AdvisorCoach.guide(for: "Chef", player: graduate))
        XCTAssertTrue(open.posted)
        XCTAssertEqual(open.steps.first?.card.actions.first?.effect, .go(.listing("Chef")))
    }

    func testGuideListsSkillGapsBiggestFirstWithTheActivityThatBuildsEach() throws {
        let teen = player(age: 16)
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: "Registered Nurse", player: teen))
        XCTAssertFalse(guide.skills.isEmpty)
        let gaps = guide.skills.map { Double($0.need - $0.have) / Double($0.need) }
        XCTAssertEqual(gaps, gaps.sorted(by: >), "Biggest relative gap first.")
        XCTAssertTrue(guide.skills.allSatisfy { $0.have < $0.need })
        // A teen has activities open, so every skill has one to build it.
        for need in guide.skills {
            let activity = try XCTUnwrap(need.activity, "\(need.label) has no activity.")
            XCTAssertGreaterThan(need.perYear ?? 0, 0)
            XCTAssertTrue(activity.abilities.contains { SoftSkills.label(forKeyPath: $0.keyPath) == need.label })
        }
        let skillSteps = guide.steps.filter { $0.kind == .skill }
        XCTAssertLessThanOrEqual(skillSteps.count, 3)
        XCTAssertTrue(skillSteps.allSatisfy { step in
            if case .go(.activities)? = step.card.actions.first?.effect { return true }
            return false
        })
    }

    func testGuideOffersAnApplicationWhenNothingIsMissing() throws {
        let adult = player(age: 25)
        for axis in SoftSkills.allAxes { adult.softSkills[keyPath: axis.keyPath] = 10 }
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: "Cashier", player: adult))
        XCTAssertFalse(guide.closed)
        XCTAssertTrue(guide.skills.isEmpty)
        XCTAssertTrue(guide.steps.contains { $0.kind == .apply })
        XCTAssertTrue(guide.canApply, "\(String(describing: guide.odds))")
        XCTAssertTrue(AdvisorCoach.introduction(guide, player: adult).contains("chance"))
    }

    func testSimplifiedGuideQuotesNoOddsAndAsksNoSkillsOfAnAdult() throws {
        let adult = player(age: 25, simplified: true)
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: "Registered Nurse", player: adult))
        XCTAssertNil(guide.odds, "Simplified hires with certainty once requirements are met.")
        XCTAssertTrue(guide.skills.isEmpty, "Simplified hiring ignores soft skills for adults.")
        XCTAssertFalse(AdvisorCoach.introduction(guide, player: adult).contains("%"))

        let child = player(age: 12, simplified: true)
        let forChild = try XCTUnwrap(AdvisorCoach.guide(for: "Registered Nurse", player: child))
        XCTAssertFalse(forChild.skills.isEmpty, "For the young, skills shape admissions.")
    }

    func testAPlayerOnTheLadderIsPointedAtTheNextRung() throws {
        let adult = player(age: 30)
        let family = try XCTUnwrap(AdvisorCoach.family("Software Engineer"))
        adult.currentOccupation = family.rungs[0]
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: "Software Engineer", player: adult))
        XCTAssertTrue(guide.onLadder)
        XCTAssertTrue(guide.isPromotion)
        XCTAssertEqual(guide.focus.rung, 1)
        XCTAssertTrue(guide.steps.contains { $0.kind == .climb })
        XCTAssertFalse(guide.steps.contains { $0.kind == .listing }, "They're already in; no listings to browse.")

        adult.currentOccupation = family.rungs.last
        let top = try XCTUnwrap(AdvisorCoach.guide(for: "Software Engineer", player: adult))
        XCTAssertTrue(top.atTop)
        XCTAssertTrue(AdvisorCoach.introduction(top, player: adult).contains("top of the"))
    }

    // MARK: - Not decided

    func testActivityIdeasSpreadOverDifferentSkillsAndFavourWhatIsUntried() throws {
        let teen = player(age: 14)
        let ideas = AdvisorCoach.activityIdeas(for: teen)
        XCTAssertEqual(ideas.count, AdvisorCoach.activityIdeaCount)
        XCTAssertEqual(Set(ideas.map(\.sport)).count, ideas.count, "Distinct activities.")
        let offered = Set(CareerAdvisor.offeredActivities(teen))
        XCTAssertTrue(ideas.allSatisfy { offered.contains($0.sport) })
        XCTAssertTrue(ideas.allSatisfy { !$0.builds.isEmpty })

        let first = try XCTUnwrap(ideas.first).sport
        teen.sportYears[first] = 3
        let next = AdvisorCoach.activityIdeas(for: teen)
        XCTAssertFalse(next.map(\.sport).contains(first), "\(first) is already a habit; suggest something new.")
    }

    func testSuggestionsUseTheSkillsGained() throws {
        let teen = player(age: 15)
        teen.advisorPlan = AdvisorCoach.begin(.exploring, for: teen)
        XCTAssertTrue(AdvisorCoach.suggestions(for: teen).isEmpty, "Nothing gained yet, nothing to read.")

        let grown: [WritableKeyPath<SoftSkills, Int>] = [
            \.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail, \.selfDisciplineAndPerseverance,
        ]
        for keyPath in grown { teen.softSkills[keyPath: keyPath] += 3 }
        let picks = AdvisorCoach.suggestions(for: teen)
        XCTAssertFalse(picks.isEmpty)
        XCTAssertLessThanOrEqual(picks.count, AdvisorCoach.suggestionCount)
        XCTAssertEqual(picks.map(\.score), picks.map(\.score).sorted(by: >), "Best first.")
        XCTAssertEqual(Set(picks.map(\.category)).count, picks.count, "One per field while fields last.")
        for pick in picks {
            let family = try XCTUnwrap(AdvisorCoach.family(pick.baseTitle))
            XCTAssertTrue(grown.contains { family.entry.askedSoftSkills.contains($0) },
                          "\(pick.baseTitle) uses none of the skills gained.")
            XCTAssertFalse(pick.matches.isEmpty)
        }
    }

    func testSuggestionsSkipCareersGatedOnAnAwardThePlayerLacks() {
        let teen = player(age: 15)
        teen.advisorPlan = AdvisorCoach.begin(.exploring, for: teen)
        for axis in SoftSkills.allAxes { teen.softSkills[keyPath: axis.keyPath] += 4 }
        let all = AdvisorCoach.suggestions(for: teen, limit: 500).map(\.baseTitle)
        XCTAssertFalse(all.isEmpty)
        XCTAssertFalse(all.contains("Player"), "Professional sport is closed without its breakthrough win.")
    }

    func testRolesAreNamedOnlyAfterAFewMovesOfTryingThings() throws {
        let teen = player(age: 12)
        teen.advisorPlan = AdvisorCoach.begin(.exploring, for: teen)
        let ideas = AdvisorCoach.activityIdeas(for: teen).map(\.sport)
        let (first, second) = (ideas[0], ideas[1])
        var verdicts: [AdvisorCheckIn.Verdict] = []
        for move in 1...AdvisorCoach.exploreMoves {
            passYear(teen, practising: [move.isMultiple(of: 2) ? second : first])
            for ability in (move.isMultiple(of: 2) ? second : first).abilities {
                teen.softSkills[keyPath: ability.keyPath] = min(10, teen.softSkills[keyPath: ability.keyPath] + ability.weight)
            }
            verdicts.append(try XCTUnwrap(AdvisorCoach.checkIn(for: teen)).checkIn.verdict)
        }
        XCTAssertEqual(verdicts.dropLast(), [.exploring, .exploring])
        XCTAssertEqual(verdicts.last, .readyToSuggest)
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: teen)).checkIn
        XCTAssertFalse(review.suggestions.isEmpty)
        XCTAssertTrue(review.suggestions.allSatisfy { AdvisorCoach.family($0) != nil })
    }

    func testExploringWithNothingTriedStaysExploringHoweverLongItTakes() throws {
        let teen = player(age: 12)
        teen.advisorPlan = AdvisorCoach.begin(.exploring, for: teen)
        for _ in 0..<(AdvisorCoach.exploreMoves + 2) { passYear(teen) }
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: teen)).checkIn
        XCTAssertEqual(review.verdict, .exploring, "No practice, no skills, no taste to read.")
        XCTAssertTrue(review.suggestions.isEmpty)
    }

    func testAnIdleExploringYearIsNudgedTowardSomethingNew() throws {
        let teen = player(age: 12)
        teen.advisorPlan = AdvisorCoach.begin(.exploring, for: teen)
        passYear(teen)
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: teen)).checkIn
        let card = try XCTUnwrap(review.corrections.first)
        if case .go(.activities)? = card.actions.first?.effect {} else {
            XCTFail("The nudge should open Activities, got \(card.actions).")
        }
    }

    // MARK: - Every move

    /// With the odds in play, a stalled year is pointed at the lever worth the
    /// most — for a teenager aiming at nursing that is still a skill, built by
    /// an activity.
    func testAStalledYearIsPointedAtTheBiggestLever() throws {
        let teen = player(age: 16)
        teen.advisorPlan = AdvisorCoach.begin(.target("Registered Nurse"), for: teen)
        passYear(teen, practising: [])
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: teen)).checkIn
        XCTAssertEqual(review.verdict, .needsCorrection)
        XCTAssertEqual(review.role, "Registered Nurse")
        XCTAssertTrue(review.progress.isEmpty)
        let lever = try XCTUnwrap(review.corrections.first { $0.title == "Your biggest lever" })
        XCTAssertTrue(lever.detail.contains("Skills the job asks for"), lever.detail)
        if case .go(.activities)? = lever.actions.first?.effect {} else {
            XCTFail("Should send the player to Activities: \(lever.actions)")
        }
    }

    /// Simplified has no odds, fame or network to weigh, so the plain nudge to
    /// practise the skills a child's goal asks for remains.
    func testAStalledSimplifiedYearIsCorrectedWithThePracticeTheJobNeeds() throws {
        let child = player(age: 12, simplified: true)
        child.advisorPlan = AdvisorCoach.begin(.target("Registered Nurse"), for: child)
        passYear(child, practising: [])
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: child)).checkIn
        XCTAssertEqual(review.verdict, .needsCorrection)
        let practice = try XCTUnwrap(review.corrections.first { $0.title == "Practise what the job needs" })
        if case .go(.activities)? = practice.actions.first?.effect {} else {
            XCTFail("Should send the player to Activities: \(practice.actions)")
        }
    }

    func testPracticingTheRightSkillIsNotedAndNotCorrected() throws {
        let teen = player(age: 16)
        teen.advisorPlan = AdvisorCoach.begin(.target("Registered Nurse"), for: teen)
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: "Registered Nurse", player: teen))
        let need = try XCTUnwrap(guide.skills.first)
        let activity = try XCTUnwrap(need.activity)
        passYear(teen, practising: [activity])
        for ability in activity.abilities {
            teen.softSkills[keyPath: ability.keyPath] = min(10, teen.softSkills[keyPath: ability.keyPath] + ability.weight)
        }
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: teen)).checkIn
        XCTAssertEqual(review.verdict, .onTrack)
        XCTAssertTrue(review.progress.contains { $0.contains(need.label) }, "\(review.progress)")
        XCTAssertFalse(review.corrections.contains { $0.title == "Practise what the job needs" })
    }

    func testAFallInTheOddsIsFlagged() throws {
        let adult = player(age: 25)
        adult.advisorPlan = AdvisorCoach.begin(.target("Cashier"), for: adult)
        let odds = try XCTUnwrap(AdvisorCoach.guide(for: "Cashier", player: adult)?.odds)
        let before = try XCTUnwrap(adult.advisorPlan.lastMark)
        adult.advisorPlan.lastMark = AdvisorPlan.Mark(
            age: before.age, skills: before.skills, licences: before.licences, educationLevel: before.educationLevel,
            years: before.years, odds: min(1, odds + 0.3), onLadder: before.onLadder)
        passYear(adult)
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: adult)).checkIn
        XCTAssertTrue(review.corrections.contains { $0.title == "Your chances fell" }, "\(review.corrections)")
    }

    func testReachingTheTopOfTheLadderIsCelebratedOnce() throws {
        let adult = player(age: 45)
        adult.advisorPlan = AdvisorCoach.begin(.target("Software Engineer"), for: adult)
        adult.currentOccupation = AdvisorCoach.family("Software Engineer")?.rungs.last
        passYear(adult)
        let first = try XCTUnwrap(AdvisorCoach.checkIn(for: adult))
        XCTAssertEqual(first.checkIn.verdict, .goalReached)
        adult.advisorPlan.record(first)
        passYear(adult)
        XCTAssertNil(AdvisorCoach.checkIn(for: adult), "Celebrated already; don't repeat it every year.")
    }

    func testGettingHiredOntoTheLadderIsNoted() throws {
        let adult = player(age: 30)
        adult.advisorPlan = AdvisorCoach.begin(.target("Cashier"), for: adult)
        adult.currentOccupation = AdvisorCoach.family("Cashier")?.entry
        passYear(adult)
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: adult)).checkIn
        XCTAssertTrue(review.progress.contains { $0.contains("You got a job") }, "\(review.progress)")
    }

    func testTheAdvisorReviewsEveryYearOnceThePlayerHasAnswered() {
        let adult = player(age: 25)
        let state = AppUIState()
        adult.advanceYear(appUIState: state)
        XCTAssertTrue(adult.advisorPlan.checkIns.isEmpty, "Nothing to review before it has asked.")
        XCTAssertTrue(adult.advisorPlan.needsAttention, "Its opening question is waiting.")

        adult.advisorPlan = AdvisorCoach.begin(.exploring, for: adult)
        XCTAssertFalse(adult.advisorPlan.needsAttention)
        adult.advanceYear(appUIState: state)
        XCTAssertEqual(adult.advisorPlan.checkIns.count, 1)
        XCTAssertEqual(adult.advisorPlan.unreadCount, 1)
        XCTAssertTrue(adult.advisorPlan.needsAttention)

        for _ in 0..<(AdvisorCoach.maxCheckIns + 3) { adult.advanceYear(appUIState: state) }
        XCTAssertLessThanOrEqual(adult.advisorPlan.checkIns.count, AdvisorCoach.maxCheckIns)
    }

    func testStartingOverForgetsThePlan() {
        let adult = player(age: 25)
        adult.advisorPlan = AdvisorCoach.begin(.target("Chef"), for: adult)
        adult.reset()
        XCTAssertEqual(adult.advisorPlan, AdvisorPlan())
    }

    func testChangingTheGoalRestartsTheReviews() {
        let adult = player(age: 25)
        adult.advisorPlan = AdvisorCoach.begin(.exploring, for: adult)
        passYear(adult)
        if let review = AdvisorCoach.checkIn(for: adult) { adult.advisorPlan.record(review) }
        XCTAssertEqual(adult.advisorPlan.unreadCount, 1)
        adult.advisorPlan = AdvisorCoach.begin(.target("Chef"), for: adult)
        XCTAssertTrue(adult.advisorPlan.checkIns.isEmpty)
        XCTAssertEqual(adult.advisorPlan.unreadCount, 0)
        XCTAssertEqual(adult.advisorPlan.target, "Chef")
        XCTAssertEqual(adult.advisorPlan.startedAge, adult.age)
    }

    func testCoachingNeverChangesThePlayer() {
        let adult = player(age: 30)
        adult.advisorPlan = AdvisorCoach.begin(.target("Registered Nurse"), for: adult)
        let before = (adult.age, adult.savings, adult.softSkills, adult.degrees, adult.advisorPlan)
        _ = AdvisorCoach.guide(for: "Registered Nurse", player: adult)
        _ = AdvisorCoach.suggestions(for: adult)
        _ = AdvisorCoach.activityIdeas(for: adult)
        _ = AdvisorCoach.checkIn(for: adult)
        _ = AdvisorCoach.playerFacts(adult)
        XCTAssertEqual(adult.age, before.0)
        XCTAssertEqual(adult.savings, before.1)
        XCTAssertEqual(adult.softSkills, before.2)
        XCTAssertEqual(adult.degrees, before.3)
        XCTAssertEqual(adult.advisorPlan, before.4)
    }
}
