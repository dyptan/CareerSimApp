import XCTest
@testable import CareersApp

/// The pathway explains what decides a hard-to-reach role. These pin its
/// *judgement* — that the seat is what binds a CEO hire, that fame stops
/// mattering once the application is at the ceiling, that no link leads to a
/// sheet the player can't open — against the game's own formulas.
final class AdvisorPathwayTests: XCTestCase {

    private let ceoTitle = "Chief Executive Officer"

    /// A 38-year-old with a business bachelor's and `years` in Business, in a
    /// calm economy so the odds don't move under the assertions.
    private func executive(years: Int = 15, skilled: Bool = true, fame: Double = 0,
                           network: Int = 0, founder: Double = 0) -> Player {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.age = 38
        player.industryTrend = [:]
        player.degrees.append(Education(.Bachelor, profile: .business, tier: .state))
        player.experience[.business] = years
        player.softSkills = skilled
            ? (AdvisorCoach.family(ceoTitle)?.entry.requirements.softSkills ?? SoftSkills())
            : SoftSkills()
        player.savings = 200_000
        if fame > 0 { player.award("Course Creator", icon: "🎓", category: .business, weight: fame) }
        if founder > 0 { player.award("Successful Exit", icon: "💸", category: .business, weight: founder) }
        player.networkByCategory[.business] = network
        return player
    }

    private func teen() -> Player {
        let player = Player()
        player.difficulty = .middleClass
        player.configureStart(age: 18)
        player.age = 16
        player.industryTrend = [:]
        player.softSkills = SoftSkills()
        return player
    }

    private func pathway(_ title: String, _ player: Player) throws -> AdvisorPathway.Pathway {
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: title, player: player))
        return try XCTUnwrap(AdvisorPathway.pathway(for: guide, player: player), "No pathway for \(title).")
    }

    private func lever(_ kind: AdvisorPathway.Lever.Kind, in path: AdvisorPathway.Pathway) throws -> AdvisorPathway.Lever {
        try XCTUnwrap(path.levers.first { $0.kind == kind }, "No \(kind) lever: \(path.levers.map(\.title)).")
    }

    // MARK: How narrow it is

    func testEvenAFlawlessCEOCandidateIsHiredOnlyAboutOneYearInTen() throws {
        let path = try pathway(ceoTitle, executive(fame: 5, network: 8))
        XCTAssertTrue(path.isNarrow)
        XCTAssertEqual(path.odds.seat, GameConstants.cSuiteSeatChance, accuracy: 1e-9)
        XCTAssertLessThanOrEqual(path.odds.maxed, GameConstants.cSuiteSeatChance * GameConstants.hireCeiling + 1e-9,
                                 "The seat caps a non-founder however strong the application.")
        XCTAssertEqual(path.odds.bestSeat, GameConstants.cSuiteSeatChance + GameConstants.executiveTrackRecordCap,
                       accuracy: 1e-9)
        XCTAssertGreaterThan(path.odds.best, path.odds.maxed, "A founder record raises the ceiling.")
        XCTAssertTrue(path.headline.contains("narrow"), path.headline)
    }

    func testAnOrdinaryRoleIsNotCalledNarrow() throws {
        let path = try pathway("Cashier", executive())
        XCTAssertFalse(path.isNarrow)
        XCTAssertGreaterThan(path.odds.best, 0.5)
    }

    func testTheOddsPictureIsOrderedNowQualifiedMaxedBest() throws {
        for title in [ceoTitle, "Investment Banker", "Marketing Director"] {
            let path = try pathway(title, teen())
            XCTAssertLessThanOrEqual(path.odds.now, path.odds.qualified + 1e-9, title)
            XCTAssertLessThanOrEqual(path.odds.qualified, path.odds.maxed + 1e-9, title)
            XCTAssertLessThanOrEqual(path.odds.maxed, path.odds.best + 1e-9, title)
            XCTAssertEqual(path.odds.now, 0, "A teenager can't be hired as \(title).")
        }
    }

    // MARK: What decides it

    /// Once an application is at the ceiling, more fame, network and polish
    /// change nothing — only the seat is left. The advisor has to say so.
    func testFameStopsMattering_OnceTheApplicationIsAtTheCeiling() throws {
        let path = try pathway(ceoTitle, executive(fame: 3, network: 5))
        XCTAssertEqual(path.odds.strength, 1, accuracy: 1e-9)
        XCTAssertEqual(try lever(.fame, in: path).state, .capped, "Fame beyond what's needed is wasted.")
        XCTAssertEqual(try lever(.network, in: path).state, .capped)
        XCTAssertEqual(try lever(.skills, in: path).state, .maxed)
        XCTAssertEqual(path.levers.first?.kind, .seat, "What's left to move is the seat.")
        XCTAssertTrue(path.gates.contains { $0.detail.contains("already as strong as the game counts") })
    }

    func testFameStillMattersWhileTheApplicationIsBelowTheCeiling() throws {
        let path = try pathway(ceoTitle, executive(skilled: false))
        XCTAssertLessThan(path.odds.strength, 1)
        let fame = try lever(.fame, in: path)
        XCTAssertEqual(fame.state, .open)
        XCTAssertGreaterThan(fame.potential, 0)
        XCTAssertGreaterThan(try lever(.skills, in: path).potential, fame.potential,
                             "Skills are the biggest single term.")
    }

    func testTheSeatIsWhatBindsAProvenCandidateAndAFounderRecordIsItsOnlyLever() throws {
        let seat = try lever(.seat, in: try pathway(ceoTitle, executive(fame: 5, network: 8)))
        XCTAssertEqual(seat.state, .open)
        XCTAssertGreaterThan(seat.potential, 0.05, "It's worth more than every polish lever combined.")
        XCTAssertTrue(seat.sources.contains { $0.title.contains("Found a company") })

        let capPoints = GameConstants.executiveTrackRecordCap / GameConstants.executiveTrackRecordPerPoint
        let proven = try pathway(ceoTitle, executive(fame: 5, network: 8, founder: capPoints))
        XCTAssertEqual(try lever(.seat, in: proven).state, .maxed)
        XCTAssertEqual(proven.odds.seat, proven.odds.bestSeat, accuracy: 1e-9)
    }

    func testANonExecutiveSeatOffersNoFounderShortcut() throws {
        let path = try pathway("Managing Partner", executive())
        let seat = try lever(.seat, in: path)
        XCTAssertEqual(seat.state, .maxed, "A partner seat can't be eased by founding a company.")
        XCTAssertTrue(seat.sources.isEmpty)
        XCTAssertEqual(path.odds.bestSeat, path.odds.seat, accuracy: 1e-9)
    }

    func testLeversAreRankedByWhatTheyAreWorth() throws {
        let path = try pathway(ceoTitle, teen())
        XCTAssertEqual(path.levers.map(\.potential), path.levers.map(\.potential).sorted(by: >))
        XCTAssertEqual(Set(path.levers.map(\.kind)).count, path.levers.count, "One lever per kind.")
    }

    func testTheFunnelHasThreeGatesForAScarceSeatAndTwoPlusCrowdForAnOversubscribedRole() throws {
        let ceo = try pathway(ceoTitle, teen())
        XCTAssertEqual(ceo.gates.map(\.title), ["Get through the door", "Stand out", "Win the seat"])
        let banker = try pathway("Investment Banker", teen())
        XCTAssertEqual(banker.gates.last?.title, "Beat the crowd")
    }

    func testApplyingAtALongShotIsCalledOneBecauseItSpendsTheYear() throws {
        let player = executive(fame: 5, network: 8)
        let guide = try XCTUnwrap(AdvisorCoach.guide(for: ceoTitle, player: player))
        let apply = try XCTUnwrap(guide.steps.first { $0.kind == .apply })
        XCTAssertTrue(apply.card.detail.contains("long shot"), apply.card.detail)
        XCTAssertTrue(apply.card.detail.contains("spends the year"), apply.card.detail)
        let path = try pathway(ceoTitle, player)
        XCTAssertTrue(path.gates.last?.detail.contains("spends a whole year") == true)
    }

    // MARK: The way there

    func testTheTimelineCountsSchoolThenTheYears() throws {
        let path = try pathway(ceoTitle, teen())
        let door = path.gates.first?.detail ?? ""
        // 16 → school from 18, four years of a bachelor's, then 11 years to open the door, 15 for full strength.
        XCTAssertTrue(door.contains("around age 33"), door)
        XCTAssertTrue(door.contains("around 37"), door)
    }

    func testEventsQuoteTheGamesOwnAcceptanceOdds() throws {
        let player = executive(years: 12, skilled: false)
        let path = try pathway(ceoTitle, player)
        let card = try XCTUnwrap(try lever(.fame, in: path).sources.first { $0.actions.first?.effect == .go(.events) })
        let event = try XCTUnwrap(EventCatalog.all.first { card.title.contains($0.name) })
        XCTAssertTrue(card.detail.contains(AdvisorPathway.percent(player.presentOdds(event))), card.detail)
        XCTAssertTrue(card.detail.contains("+\(AdvisorPathway.decimal(event.presenterFameWeight))"), card.detail)
    }

    func testBusinessYearsCanComeFromFeederJobsVenturesAndCampaigns() throws {
        let path = try pathway(ceoTitle, executive(years: 5))
        let sources = try lever(.experience, in: path).sources
        XCTAssertTrue(sources.contains { $0.actions.first?.effect == .go(.ventures) }, "Venture years count as Business years.")
        XCTAssertTrue(sources.contains { $0.actions.first?.effect == .go(.projects) }, "So do crowdfunding years.")
        let feeders = sources.compactMap { source -> String? in
            if case .go(.listing(let title))? = source.actions.first?.effect { return title }
            return nil
        }
        XCTAssertFalse(feeders.isEmpty)
        XCTAssertEqual(Set(feeders).count, feeders.count, "One line per role, not one per rung.")
        XCTAssertFalse(feeders.contains(ceoTitle))
    }

    func testSkillAdviceIsAPlanNotAGenericActivity() throws {
        let path = try pathway(ceoTitle, teen())
        let skills = try lever(.skills, in: path)
        XCTAssertTrue(skills.sources.first?.title == "A plan for your skills", "\(skills.sources.map(\.title))")
        XCTAssertTrue(skills.mechanics.contains("Furthest behind"))
        let moves = skills.sources.dropFirst()
        XCTAssertFalse(moves.isEmpty)
        XCTAssertTrue(moves.allSatisfy { $0.detail.contains("to your chance a year") }, "\(moves.map(\.detail))")
    }

    // MARK: Links

    /// A link mustn't lead where the footer wouldn't: a teenager has no Events,
    /// Projects, Ventures, Boardroom or Education sheet.
    func testNoLinkLeadsToASheetThePlayerCannotOpen() throws {
        let player = teen()
        let path = try pathway(ceoTitle, player)
        let destinations = (path.levers.flatMap(\.sources) + path.leverCards).flatMap(\.actions).compactMap { action -> CareerAdvisor.Destination? in
            if case .go(let destination) = action.effect { return destination }
            return nil
        }
        for destination in destinations {
            switch destination {
            case .events, .projects, .ventures, .boardroom, .education:
                XCTFail("A 16-year-old was sent to \(destination), which the footer hides.")
            default: break
            }
        }
    }

    func testAdultLinksAreOfferedWhereTheSheetsOpen() throws {
        let player = executive(years: 12)
        let path = try pathway(ceoTitle, player)
        let destinations = Set(path.levers.flatMap(\.sources).flatMap(\.actions).compactMap { action -> String? in
            if case .go(let destination) = action.effect { return destination.buttonLabel }
            return nil
        })
        XCTAssertTrue(destinations.isSuperset(of: ["Open Events", "Open Projects", "Open Ventures", "See job listings"]),
                      "\(destinations)")
    }

    func testTheBoardroomIsOfferedOnlyToWhoHoldsAnExecutiveSeat() throws {
        let founder = executive(fame: 5, network: 8)
        let seatSources = { (player: Player) throws -> [AdvisorCard] in
            try self.lever(.seat, in: try self.pathway(self.ceoTitle, player)).sources
        }
        XCTAssertFalse(try seatSources(founder).contains { $0.actions.first?.effect == .go(.boardroom) })
        founder.currentOccupation = JobCatalog.allJobs().first { $0.isEntrepreneurial }
        XCTAssertTrue(founder.canMakeExecutiveDecisions)
        XCTAssertTrue(try seatSources(founder).contains { $0.actions.first?.effect == .go(.boardroom) })
    }

    // MARK: Other careers

    func testAScoutedCareerPointsAtItsBreakthroughTitle() throws {
        let path = try pathway("Player", teen())
        let door = try lever(.breakthrough, in: path)
        XCTAssertTrue(door.title.contains("Junior Champion"))
        XCTAssertEqual(path.levers.count, 1)
        XCTAssertTrue(path.isNarrow)
        if case .go(.activities)? = door.sources.first?.actions.first?.effect {} else {
            XCTFail("The title is won by training a sport: \(door.sources)")
        }
    }

    func testSimplifiedAndPromotionsHaveNoPathway() throws {
        let simple = Player()
        simple.difficulty = .simplified
        simple.configureStart(age: 18)
        simple.age = 30
        let simpleGuide = try XCTUnwrap(AdvisorCoach.guide(for: ceoTitle, player: simple))
        XCTAssertNil(AdvisorPathway.pathway(for: simpleGuide, player: simple), "Simplified has no odds, fame or network.")

        let climber = executive()
        climber.currentOccupation = AdvisorCoach.family("Software Engineer")?.rungs.first
        let climbGuide = try XCTUnwrap(AdvisorCoach.guide(for: "Software Engineer", player: climber))
        XCTAssertTrue(climbGuide.isPromotion)
        XCTAssertNil(AdvisorPathway.pathway(for: climbGuide, player: climber))
    }

    func testCardsShowTheTopLeversAndSummariseTheRest() throws {
        let path = try pathway(ceoTitle, executive(fame: 3, network: 5))
        let cards = path.leverCards
        XCTAssertLessThanOrEqual(cards.count, 5, "Four levers and a summary at most.")
        XCTAssertEqual(cards.last?.title, "The rest")
        XCTAssertTrue(cards.last?.detail.contains("enough for now") == true, cards.last?.detail ?? "")
        XCTAssertTrue(cards.first?.title.hasPrefix("The seat") == true, cards.first?.title ?? "")
    }

    func testReadingThePathwayChangesNothing() throws {
        let player = executive(fame: 2, network: 3)
        player.advisorPlan = AdvisorCoach.begin(.target(ceoTitle), for: player)
        let before = (player.age, player.savings, player.softSkills, player.fameAwards, player.networkByCategory, player.advisorPlan)
        _ = try pathway(ceoTitle, player)
        _ = AdvisorCoach.playerFacts(player)
        XCTAssertEqual(player.age, before.0)
        XCTAssertEqual(player.savings, before.1)
        XCTAssertEqual(player.softSkills, before.2)
        XCTAssertEqual(player.fameAwards, before.3)
        XCTAssertEqual(player.networkByCategory, before.4)
        XCTAssertEqual(player.advisorPlan, before.5)
    }

    // MARK: Real world

    func testHardCareersCarryARealWorldNoteThatPairsEachPointWithTheGame() throws {
        let ceo = try XCTUnwrap(AdvisorRealWorld.note(for: try XCTUnwrap(AdvisorCoach.family(ceoTitle)).entry, difficulty: .middleClass, voice: .standard))
        XCTAssertGreaterThanOrEqual(ceo.points.count, 5)
        XCTAssertTrue(ceo.points.allSatisfy { $0.game != nil }, "Each real-world point has its in-game counterpart.")
        let text = ceo.points.compactMap(\.game).joined(separator: " ")
        XCTAssertTrue(text.contains(AdvisorPathway.percent(GameConstants.cSuiteSeatChance)), "Built from the game's own seat chance.")
        XCTAssertTrue(text.contains("15 years"), "…and its own experience bar.")
        XCTAssertEqual(ceo.cards.count, ceo.points.count)
        XCTAssertTrue(ceo.cards.allSatisfy { $0.detail.contains("🎮 In the game:") })
        XCTAssertEqual(ceo.facts.count, ceo.points.count * 2)
    }

    func testEveryHardCareerNoteIsReachableAndEasyCareersHaveNone() throws {
        let hard = [ceoTitle, "Chief Technology Officer", "Chief Medical Officer", "Marketing Director", "Sales Director",
                    "Managing Partner", "Physician", "Surgeon", "Judge", "Research Scientist", "Airline Pilot", "Player",
                    "Investment Banker", "Management Consultant", "TV Presenter"]
        for title in hard {
            let family = try XCTUnwrap(AdvisorCoach.family(title), title)
            let note = try XCTUnwrap(AdvisorRealWorld.note(for: family.entry, difficulty: .middleClass, voice: .standard), "No real-world note for \(title).")
            XCTAssertFalse(note.points.isEmpty, title)
            XCTAssertTrue(note.points.allSatisfy { !$0.real.isEmpty }, title)
        }
        for title in ["Cashier", "Software Engineer", "Registered Nurse", "Chef"] {
            XCTAssertNil(AdvisorRealWorld.note(for: try XCTUnwrap(AdvisorCoach.family(title)).entry, difficulty: .middleClass, voice: .standard), title)
        }
    }

    func testQuestionsAreAnsweredFromThePathwayAndTheRealWorldNote() throws {
        let player = executive(fame: 2)
        player.advisorPlan = AdvisorCoach.begin(.target(ceoTitle), for: player)
        let facts = AdvisorCoach.playerFacts(player).joined(separator: "\n")
        XCTAssertTrue(facts.contains("narrow path"), "The pathway is in what a question is answered from.")
        XCTAssertTrue(facts.contains("In the real world:"))
        XCTAssertTrue(facts.contains("In the game:"))
    }

    // MARK: Check-ins

    func testAStalledYearIsPointedAtTheBiggestLeverNotAGenericActivity() throws {
        let player = executive(fame: 3, network: 5)
        player.advisorPlan = AdvisorCoach.begin(.target(ceoTitle), for: player)
        player.age += 1
        player.lastYearSports = []
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: player)).checkIn
        XCTAssertEqual(review.verdict, .needsCorrection)
        let lever = try XCTUnwrap(review.corrections.first { $0.title == "Your biggest lever" })
        XCTAssertTrue(lever.detail.contains("The seat"), lever.detail)
        XCTAssertFalse(lever.actions.isEmpty)
        let enough = try XCTUnwrap(review.corrections.first { $0.title == "Enough polish" })
        XCTAssertTrue(enough.detail.contains("changes nothing"), enough.detail)
        XCTAssertFalse(review.corrections.contains { $0.title == "Practise what the job needs" })
    }

    func testTheReviewNotesFameNetworkAndFounderProgress() throws {
        let player = executive(skilled: false)
        player.advisorPlan = AdvisorCoach.begin(.target(ceoTitle), for: player)
        player.age += 1
        player.award("Finance & Markets Forum — Speaker", icon: "💰", category: .business, weight: 4)
        player.networkByCategory[.business, default: 0] += 4
        player.award("Successful Exit", icon: "💸", category: .business, weight: 2)
        let review = try XCTUnwrap(AdvisorCoach.checkIn(for: player)).checkIn
        XCTAssertEqual(review.verdict, .onTrack)
        XCTAssertTrue(review.progress.contains { $0.hasPrefix("🌟") }, "\(review.progress)")
        XCTAssertTrue(review.progress.contains { $0.hasPrefix("🤝") }, "\(review.progress)")
        let founder = try XCTUnwrap(review.progress.first { $0.hasPrefix("🏗️") }, "\(review.progress)")
        XCTAssertTrue(founder.contains("seat chance is now"), founder)
    }

    // MARK: In the chat

    @MainActor
    func testChoosingAHardRoleShowsTheGuideThenTheNarrowPathThenTheRealWorld() async throws {
        let player = teen()
        let chat = AdvisorConversation(player: player, language: AdvisorPlainLanguage())
        await chat.start()
        await chat.choose(try XCTUnwrap(chat.replies.first { $0.kind == .haveRole }))
        await chat.send(ceoTitle)

        let advisor = chat.messages.filter { $0.speaker == .advisor }
        XCTAssertEqual(advisor.suffix(3).map(\.heading), [nil, "🧭 The narrow path", "🌍 Becoming a CEO"])
        XCTAssertEqual(chat.focusMessageID, advisor.suffix(3).first?.id, "A reply is read from its top.")
        let path = try XCTUnwrap(advisor.first { $0.heading == "🧭 The narrow path" })
        XCTAssertEqual(path.cards.prefix(3).map(\.title), ["Get through the door", "Stand out", "Win the seat"])
        XCTAssertTrue(chat.replies.contains { $0.kind == .showPath })
        XCTAssertTrue(chat.replies.contains { $0.kind == .realWorld })
    }

    @MainActor
    func testAnOrdinaryRoleOffersThePathOnRequestOnly() async throws {
        let player = teen()
        let chat = AdvisorConversation(player: player, language: AdvisorPlainLanguage())
        await chat.start()
        await chat.choose(try XCTUnwrap(chat.replies.first { $0.kind == .haveRole }))
        await chat.send("Registered Nurse")
        XCTAssertFalse(chat.messages.contains { $0.heading == "🧭 The narrow path" }, "Nothing narrow about it.")
        let chip = try XCTUnwrap(chat.replies.first { $0.kind == .showPath })
        XCTAssertEqual(chip.label, "🧭 What decides it")
        XCTAssertFalse(chat.replies.contains { $0.kind == .realWorld }, "No note for nursing.")

        await chat.choose(chip)
        XCTAssertTrue(chat.messages.contains { $0.heading == "🧭 The narrow path" })
    }

    @MainActor
    func testTheRealWorldViewCanBeCalledUpAgain() async throws {
        let player = teen()
        player.advisorPlan = AdvisorCoach.begin(.target(ceoTitle), for: player)
        let chat = AdvisorConversation(player: player, language: AdvisorPlainLanguage())
        await chat.start()
        XCTAssertFalse(chat.messages.contains { $0.heading == "🌍 Becoming a CEO" }, "Coming back shows the guide only.")
        await chat.choose(try XCTUnwrap(chat.replies.first { $0.kind == .realWorld }))
        XCTAssertTrue(chat.messages.contains { $0.heading == "🌍 Becoming a CEO" })
    }

    // MARK: Voice and mode

    private let hardCareers = ["Chief Executive Officer", "Chief Technology Officer", "Chief Medical Officer", "Marketing Director",
                               "Sales Director", "Managing Partner", "Physician", "Surgeon", "Judge", "Research Scientist",
                               "Airline Pilot", "Player", "Investment Banker", "Management Consultant", "TV Presenter"]

    private func note(_ title: String, _ difficulty: Difficulty, _ voice: AdvisorVoice) throws -> AdvisorRealWorld.Note {
        let family = try XCTUnwrap(AdvisorCoach.family(title), title)
        return try XCTUnwrap(AdvisorRealWorld.note(for: family.entry, difficulty: difficulty, voice: voice), title)
    }

    /// The advisor speaks to who is playing: the tutorial always simply, Real
    /// Life simply until the player leaves middle school.
    func testTheVoiceFollowsTheModeAndTheAge() {
        XCTAssertEqual(AdvisorVoice(difficulty: .simplified, age: 7), .simple)
        XCTAssertEqual(AdvisorVoice(difficulty: .simplified, age: 40), .simple, "Simplified is the tutorial at any age.")
        XCTAssertEqual(AdvisorVoice(difficulty: .middleClass, age: 7), .simple)
        XCTAssertEqual(AdvisorVoice(difficulty: .middleClass, age: AdvisorVoice.simpleBelowAge - 1), .simple)
        XCTAssertEqual(AdvisorVoice(difficulty: .middleClass, age: AdvisorVoice.simpleBelowAge), .standard)
        XCTAssertEqual(AdvisorVoice(executive()), .standard)
        XCTAssertEqual(AdvisorVoice(teen()), .standard, "A 16-year-old in Real Life reads the full version.")
    }

    /// What the on-device model is told is the one place the voice changes its
    /// words, so it has to say something for the simple voice — and nothing extra
    /// for everyone else.
    func testTheModelIsToldToWriteSimplyOnlyForTheSimpleVoice() {
        let simple = AdvisorVoice.simple.styleGuide
        XCTAssertTrue(simple.contains("very short sentences"), simple)
        XCTAssertTrue(simple.contains("Avoid jargon"), simple)
        XCTAssertTrue(simple.contains("Say only what the facts say"), "A small model invents when it isn't held to the facts.")
        XCTAssertTrue(simple.contains("never turn a percentage into a fraction"),
                      "A rewritten number would fail the number guard and waste the reply.")
        XCTAssertEqual(AdvisorVoice.standard.styleGuide, "")
        XCTAssertNotEqual(AdvisorVoice.simple.answerLength, AdvisorVoice.standard.answerLength)
    }

    /// Simplified hires with certainty, so its notes may not describe seats,
    /// fame, prestige, demand or odds — none of which it has.
    func testSimplifiedNeverHearsOfSeatsFameOrLuckItDoesNotHave() throws {
        let notInSimplified = ["seat", "fame", "network", "prestige", "founder", "demand", "odds", "%", "applicant", "climate", "market"]
        for title in hardCareers {
            for text in try note(title, .simplified, .simple).points.compactMap(\.game) {
                for word in notInSimplified {
                    XCTAssertFalse(text.lowercased().contains(word), "\(title): “\(text)” talks of \(word), which Simplified doesn't have.")
                }
            }
        }
    }

    /// …and what it does say is what the game does: the right school and the
    /// years, then the job is certain; one year short and it is closed.
    func testWhatTheSimplifiedNoteSaysIsWhatSimplifiedDoes() throws {
        let ceo = try XCTUnwrap(AdvisorCoach.family(ceoTitle)).entry
        let text = try note(ceoTitle, .simplified, .simple).points.compactMap(\.game).joined(separator: " ")
        XCTAssertTrue(text.contains(AdvisorCoach.educationPhrase(for: ceo)), "It names the degree, not just “school”: \(text)")
        XCTAssertTrue(text.contains("\(ceo.requirements.minYearsExperience) years of work in"), text)
        XCTAssertTrue(text.contains("no companies to start"), "Simplified has no Ventures sheet.")

        let player = executive()
        player.difficulty = .simplified
        let ask = Double(ceo.annualIncome)
        XCTAssertEqual(ceo.hireProbability(for: player, requestedSalary: ask), 1.0, accuracy: 1e-9,
                       "Qualified: “the job is yours”, with no seat to win.")
        player.experience[.business] = ceo.requirements.minYearsExperience - 1
        XCTAssertEqual(ceo.hireProbability(for: player, requestedSalary: ask), 0, "A year short: closed, not a long shot.")
    }

    func testThePilotAndDoctorTutorialLinesDescribeTheTutorial() throws {
        let pilot = try note("Airline Pilot", .simplified, .simple).points.compactMap(\.game).joined(separator: " ")
        XCTAssertTrue(pilot.contains("skips the licence"), pilot)
        let doctor = try note("Physician", .simplified, .simple).points.compactMap(\.game).joined(separator: " ")
        XCTAssertTrue(doctor.contains("no school bill") || doctor.contains("no licence to earn"), doctor)
        XCTAssertTrue(doctor.contains("in Simplified mode too"), "School admission is still a roll there.")
    }

    /// The Junior Champion door is shut in every mode; Simplified only drops the
    /// roster lottery behind it.
    func testTheAthleteTutorialLineKeepsTheDoorAndDropsTheLottery() throws {
        let text = try note("Player", .simplified, .simple).points.compactMap(\.game).joined(separator: " ")
        XCTAssertTrue(text.contains("Junior Champion"), text)
        XCTAssertFalse(text.contains("%"))

        let family = try XCTUnwrap(AdvisorCoach.family("Player"))
        let pro = try XCTUnwrap(family.rungs.first { $0.rung >= 1 })
        let player = executive()
        player.difficulty = .simplified
        XCTAssertTrue(pro.hireBreakdown(for: player, requestedSalary: Double(pro.annualIncome)).breakthroughMissing,
                      "No title, no door — in Simplified too.")
        player.award("Junior Champion", icon: "🏆", category: nil, weight: 1)
        let held = pro.hireBreakdown(for: player, requestedSalary: Double(pro.annualIncome))
        XCTAssertFalse(held.breakthroughMissing)
        XCTAssertEqual(held.odds(requirementFactor: 1), 1.0, accuracy: 1e-9, "With the title the spot is certain — no roster lottery.")
    }

    /// The beginner's telling is short, in short sentences, and drops the
    /// statistics — while Real Life keeps its own game lines, which are true there.
    func testTheSimpleTellingIsShortAndKeepsRealLifesGameLines() throws {
        for title in hardCareers {
            let full = try note(title, .middleClass, .standard)
            let simple = try note(title, .middleClass, .simple)
            XCTAssertFalse(simple.points.isEmpty, "\(title) has nothing for a young reader.")
            XCTAssertLessThanOrEqual(simple.points.count, full.points.count, title)
            for point in simple.points {
                XCTAssertLessThanOrEqual(point.real.count, 220, "\(title): too long for a young reader: \(point.real)")
                for sentence in point.real.split(separator: ".") {
                    XCTAssertLessThanOrEqual(sentence.split(separator: " ").count, 30, "\(title): “\(sentence)” is a mouthful.")
                }
                for word in ["C-suite", "P&L", "applicants", "residency", "postdoctoral", "up or out"] {
                    XCTAssertFalse(point.real.contains(word), "\(title): “\(word)” is jargon for a beginner.")
                }
            }
            XCTAssertTrue(Set(simple.points.compactMap(\.game)).isSubset(of: Set(full.points.compactMap(\.game))),
                          "\(title): Real Life's game lines are the same at any age.")
        }
        // Where the full telling has figures the simple one drops, the facts follow the telling.
        let ceoFull = try note(ceoTitle, .middleClass, .standard).facts.joined()
        let ceoSimple = try note(ceoTitle, .middleClass, .simple).facts.joined()
        XCTAssertTrue(ceoFull.contains("170") && !ceoSimple.contains("170"))
    }

    /// A Simplified or young player is not handed the adult analysis of odds,
    /// levers and seats; a Real Life player of 14 is.
    func testTheAdultPathwayIsLeftOutForTheSimpleVoice() throws {
        let player = teen()
        player.age = AdvisorVoice.simpleBelowAge
        XCTAssertNotNil(AdvisorPathway.pathway(for: try XCTUnwrap(AdvisorCoach.guide(for: ceoTitle, player: player)), player: player))
        player.age = AdvisorVoice.simpleBelowAge - 1
        XCTAssertNil(AdvisorPathway.pathway(for: try XCTUnwrap(AdvisorCoach.guide(for: ceoTitle, player: player)), player: player))

        let simplified = executive()
        simplified.difficulty = .simplified
        XCTAssertNil(AdvisorPathway.pathway(for: try XCTUnwrap(AdvisorCoach.guide(for: ceoTitle, player: simplified)), player: simplified))
    }

    /// What a question is answered from says how hiring works in the player's
    /// mode — otherwise a model reasons from Real Life's odds in the tutorial.
    func testASimplifiedPlayersFactsSayHowHiringWorksThere() {
        let simplified = executive()
        simplified.difficulty = .simplified
        XCTAssertTrue(AdvisorCoach.playerFacts(simplified).joined(separator: "\n")
            .contains("no odds, luck, fame or seats"))
        XCTAssertFalse(AdvisorCoach.playerFacts(executive()).joined(separator: "\n").contains("Simplified mode"))
    }
}
