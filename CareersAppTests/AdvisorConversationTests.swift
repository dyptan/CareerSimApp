import XCTest
@testable import CareersApp

/// A language layer the tests control: what it "understands", what it says.
private struct StubLanguage: AdvisorLanguage {
    var isAvailable = true
    var intent: AdvisorIntent?
    var narration: String?
    var reply: String?

    func narrate(_ brief: AdvisorBrief) async -> String? { narration }
    func interpret(_ text: String) async -> AdvisorIntent? { intent }
    func answer(_ question: String, brief: AdvisorBrief) async -> String? { reply }
}

/// The advisor's chat: the flow the player walks through, with and without a
/// language model. Every path must work from buttons alone.
@MainActor
final class AdvisorConversationTests: XCTestCase {

    private func adult(age: Int = 25) -> Player {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.age = age
        player.softSkills = SoftSkills()
        return player
    }

    private func chat(_ player: Player, _ language: AdvisorLanguage = AdvisorPlainLanguage()) -> AdvisorConversation {
        AdvisorConversation(player: player, language: language)
    }

    private func lastAdvisorMessage(_ chat: AdvisorConversation) throws -> AdvisorMessage {
        try XCTUnwrap(chat.messages.last { $0.speaker == .advisor })
    }

    private func reply(_ kind: AdvisorReply.Kind, in chat: AdvisorConversation) throws -> AdvisorReply {
        try XCTUnwrap(chat.replies.first { $0.kind == kind }, "No \(kind) chip in \(chat.replies.map(\.label)).")
    }

    // MARK: The first visit

    func testTheFirstVisitAsksWhetherThePlayerHasARoleInMind() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        XCTAssertEqual(chat.messages.count, 1)
        XCTAssertEqual(chat.messages.first?.speaker, .advisor)
        XCTAssertEqual(chat.replies.map(\.kind), [.haveRole, .undecided])
        XCTAssertEqual(player.advisorPlan.path, .unasked, "Asking commits nothing.")
    }

    func testOpeningTwiceDoesNotRepeatTheGreeting() async {
        let chat = chat(adult())
        await chat.start()
        await chat.start()
        XCTAssertEqual(chat.messages.count, 1)
    }

    // MARK: A role in mind

    func testNamingARoleSetsTheGoalAndShowsTheGuideWithAListingsLink() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        await chat.choose(try reply(.haveRole, in: chat))
        XCTAssertTrue(chat.choosing)
        XCTAssertTrue(chat.acceptsText)
        XCTAssertEqual(chat.replies.count, AdvisorCoach.fields.count, "A chip per field to browse.")

        await chat.send("Registered Nurse")
        XCTAssertEqual(player.advisorPlan.path, .target("Registered Nurse"))
        XCTAssertFalse(chat.choosing)
        let guide = try lastAdvisorMessage(chat)
        let actions = guide.cards.flatMap(\.actions).map(\.effect)
        XCTAssertTrue(actions.contains(.go(.listing("Registered Nurse"))), "\(actions)")
        XCTAssertTrue(actions.contains(.go(.education)))
        XCTAssertEqual(chat.replies.map(\.kind), [.changeGoal, .bestMoves, .showPath],
                       "Nursing has no real-world note, but what decides it can be asked for.")
    }

    func testAVagueWordOffersTheRolesItCouldMean() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        await chat.choose(try reply(.haveRole, in: chat))
        await chat.send("nurse")
        XCTAssertEqual(player.advisorPlan.path, .unasked, "More than one job fits; ask which.")
        XCTAssertTrue(chat.replies.contains { $0.kind == .pickRole("Registered Nurse") })
        XCTAssertTrue(chat.replies.contains { $0.kind == .backToFields })

        await chat.choose(try reply(.pickRole("Registered Nurse"), in: chat))
        XCTAssertEqual(player.advisorPlan.target, "Registered Nurse")
    }

    func testBrowsingAFieldOffersItsRoles() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        await chat.choose(try reply(.haveRole, in: chat))
        await chat.choose(try reply(.browse(.health), in: chat))
        let picks = chat.replies.compactMap { reply -> String? in
            if case .pickRole(let title) = reply.kind { return title }
            return nil
        }
        XCTAssertEqual(Set(picks), Set(AdvisorCoach.families(in: .health).map(\.baseTitle)))
        await chat.choose(try reply(.backToFields, in: chat))
        XCTAssertEqual(chat.replies.count, AdvisorCoach.fields.count)
    }

    func testAWordThatNamesNoRoleKeepsAskingRatherThanGuessing() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        await chat.choose(try reply(.haveRole, in: chat))
        await chat.send("xyzzy")
        XCTAssertEqual(player.advisorPlan.path, .unasked)
        XCTAssertTrue(chat.choosing)
        XCTAssertEqual(chat.replies.count, AdvisorCoach.fields.count)
    }

    // MARK: Not decided

    func testNotDecidedStartsExploringWithThingsToTry() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        await chat.choose(try reply(.undecided, in: chat))
        XCTAssertEqual(player.advisorPlan.path, .exploring)
        let ideas = try lastAdvisorMessage(chat)
        XCTAssertFalse(ideas.cards.isEmpty)
        XCTAssertTrue(ideas.cards.allSatisfy { card in
            if case .go(.activities)? = card.actions.first?.effect { return true }
            return false
        })
        XCTAssertEqual(chat.replies.map(\.kind), [.haveRole, .bestMoves])
    }

    func testAnExplorerWhoHasFoundARoleCanSwitch() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        await chat.choose(try reply(.undecided, in: chat))
        await chat.choose(try reply(.haveRole, in: chat))
        await chat.send("Chef")
        XCTAssertEqual(player.advisorPlan.target, "Chef")
    }

    func testAskingForTheBestMovesShowsTheRankedTips() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        await chat.choose(try reply(.undecided, in: chat))
        await chat.choose(try reply(.bestMoves, in: chat))
        let message = try lastAdvisorMessage(chat)
        XCTAssertEqual(message.cards.map(\.title), CareerAdvisor.tips(for: player).map(\.title))
    }

    // MARK: Coming back after a move

    func testAWaitingReviewIsShownFirstAndMarkedRead() async throws {
        let player = adult()
        player.advisorPlan = AdvisorCoach.begin(.target("Registered Nurse"), for: player)
        player.age += 1
        player.advisorPlan.record(try XCTUnwrap(AdvisorCoach.checkIn(for: player)))
        XCTAssertEqual(player.advisorPlan.unreadCount, 1)

        let chat = chat(player)
        await chat.start()
        let message = try lastAdvisorMessage(chat)
        XCTAssertEqual(message.heading, "📅 Check-in · age \(player.age)")
        XCTAssertEqual(message.text, player.advisorPlan.checkIns.last?.headline)
        XCTAssertFalse(message.cards.isEmpty, "A review carries its corrections.")
        XCTAssertEqual(player.advisorPlan.unreadCount, 0)
        XCTAssertFalse(player.advisorPlan.needsAttention)
    }

    func testWithNoReviewWaitingTheGuideIsShownAgain() async throws {
        let player = adult()
        player.advisorPlan = AdvisorCoach.begin(.target("Chef"), for: player)
        let chat = chat(player)
        await chat.start()
        XCTAssertNil(try lastAdvisorMessage(chat).heading)
        XCTAssertTrue(try lastAdvisorMessage(chat).text.contains("Chef"))
    }

    func testARoleSuggestionCanBeTakenUpFromItsCard() async throws {
        let player = adult(age: 14)
        player.advisorPlan = AdvisorCoach.begin(.exploring, for: player)
        for keyPath: WritableKeyPath<SoftSkills, Int> in [\.analyticalReasoningAndProblemSolving, \.carefulnessAndAttentionToDetail] {
            player.softSkills[keyPath: keyPath] += 4
        }
        player.age += AdvisorCoach.exploreMoves
        player.lastYearSports = [.coding]
        player.sportYears[.coding] = 2
        player.sportYears[.math] = 1
        player.advisorPlan.record(try XCTUnwrap(AdvisorCoach.checkIn(for: player)))

        let chat = chat(player)
        await chat.start()
        let message = try lastAdvisorMessage(chat)
        let aims = message.cards.flatMap(\.actions).compactMap { action -> String? in
            if case .aim(let title) = action.effect { return title }
            return nil
        }
        XCTAssertFalse(aims.isEmpty, "Suggested roles should be offered as goals.")
        await chat.aim(at: aims[0])
        XCTAssertEqual(player.advisorPlan.target, aims[0])
    }

    // MARK: With a language model

    func testTypingIsTurnedAwayWithoutAModelUnlessNamingARole() async throws {
        let player = adult()
        let chat = chat(player)
        await chat.start()
        await chat.choose(try reply(.undecided, in: chat))
        XCTAssertFalse(chat.acceptsText)
        let before = chat.messages.count
        await chat.send("what should I do?")
        XCTAssertEqual(player.advisorPlan.path, .exploring)
        XCTAssertEqual(chat.messages.count, before + 2, "The words and a pointer back to the buttons.")
    }

    func testAModelReadsARoleOutOfFreeText() async throws {
        let player = adult()
        let chat = chat(player, StubLanguage(intent: .chooseRole("Chef")))
        await chat.start()
        XCTAssertTrue(chat.acceptsText)
        await chat.send("I'd really like to spend my days cooking in a busy restaurant kitchen")
        XCTAssertEqual(player.advisorPlan.target, "Chef")
    }

    func testAShortWordThatFitsSeveralJobsIsLeftToThePlayerEvenWithAModel() async throws {
        let player = adult()
        let chat = chat(player, StubLanguage(intent: .chooseRole("Licensed Practical Nurse")))
        await chat.start()
        await chat.send("nurse")
        XCTAssertEqual(player.advisorPlan.path, .unasked, "Four jobs fit \"nurse\"; the model mustn't pick one for them.")
        XCTAssertTrue(chat.replies.contains { $0.kind == .pickRole("Registered Nurse") })
        XCTAssertTrue(chat.replies.contains { $0.kind == .pickRole("Licensed Practical Nurse") })
        XCTAssertTrue(chat.choosing)

        // Naming the job outright is not ambiguous.
        let exact = AdvisorConversation(player: adult(), language: StubLanguage(intent: .chooseRole("Licensed Practical Nurse")))
        await exact.start()
        await exact.send("licensed practical nurse")
        XCTAssertFalse(exact.choosing)
    }

    func testAModelCannotInventARole() async throws {
        let player = adult()
        let chat = chat(player, StubLanguage(intent: .chooseRole("Astronaut Wizard")))
        await chat.start()
        await chat.send("I want to be an astronaut wizard")
        XCTAssertEqual(player.advisorPlan.path, .unasked)
    }

    func testAModelHearsAPlayerWhoHasNotDecided() async throws {
        let player = adult()
        let chat = chat(player, StubLanguage(intent: .undecided))
        await chat.start()
        await chat.send("no idea honestly")
        XCTAssertEqual(player.advisorPlan.path, .exploring)
    }

    func testAModelAnswersQuestionsAndTheGameFallsBackWhenItCannot() async throws {
        let player = adult()
        let talking = chat(player, StubLanguage(intent: .question, reply: "Practise Chess to grow your Inventor skill."))
        await talking.start()
        await talking.send("how do I get smarter?")
        XCTAssertEqual(try lastAdvisorMessage(talking).text, "Practise Chess to grow your Inventor skill.")

        let stumped = chat(player, StubLanguage(intent: .question, reply: nil))
        await stumped.start()
        await stumped.send("how do I get smarter?")
        XCTAssertTrue(try lastAdvisorMessage(stumped).text.contains("not sure"))
        XCTAssertEqual(stumped.replies.count, 2, "Buttons are offered again.")
    }

    func testANarrationIsShownOnlyWhenEveryNumberInItIsGrounded() async throws {
        let player = adult()
        player.advisorPlan = AdvisorCoach.begin(.target("Registered Nurse"), for: player)

        let invented = chat(player, StubLanguage(narration: "You have a 99% chance and it pays 500000 $!"))
        await invented.start()
        let plain = try lastAdvisorMessage(invented).text
        XCTAssertTrue(plain.contains("Registered Nurse"), "Fell back to the coach's plain text: \(plain)")
        XCTAssertFalse(plain.contains("99%"))

        let warm = "Nursing is a wonderful choice, and there's a clear path to get there."
        let friendly = chat(player, StubLanguage(narration: warm))
        await friendly.start()
        XCTAssertEqual(try lastAdvisorMessage(friendly).text, warm)
        XCTAssertFalse(try lastAdvisorMessage(friendly).cards.isEmpty, "The steps stay the coach's own.")
    }

    // MARK: The number guard

    func testTheGuardReadsNumbersTheWayThePlayerWouldWriteThem() {
        XCTAssertEqual(AdvisorGuard.numbers(in: "It pays 68,000 $ — a 12% chance in 3 years."), ["68000", "12", "3"])
        XCTAssertEqual(AdvisorGuard.numbers(in: "Chance 12.5%. Then, 7, 8."), ["125", "7", "8"])
        XCTAssertEqual(AdvisorGuard.numbers(in: "no numbers here"), [])
    }

    func testTheGuardRejectsWhatItCannotTraceToTheFacts() {
        let facts = ["Your chance to be hired today is 12%.", "It pays 68,000 $ a year."]
        XCTAssertEqual(AdvisorGuard.accept("A 12% chance, and 68,000 $ a year.", facts: facts), "A 12% chance, and 68,000 $ a year.")
        XCTAssertNil(AdvisorGuard.accept("A 13% chance.", facts: facts))
        XCTAssertNil(AdvisorGuard.accept("   ", facts: facts))
        XCTAssertNil(AdvisorGuard.accept(String(repeating: "word ", count: 400), facts: facts), "Rambling is rejected.")
        XCTAssertEqual(AdvisorGuard.accept("  No numbers at all.  ", facts: facts), "No numbers at all.")
    }
}
