import Foundation
import Combine

// MARK: - The language layer's contract

/// What the language layer is asked to put into words: what the message is
/// about, the facts it may quote, and the plain text the game would show with
/// no model at all. The facts are the only source of numbers — see `AdvisorGuard`.
struct AdvisorBrief: Equatable {
    let topic: String
    let facts: [String]
    let plain: String
}

/// What a player's typed words ask for.
enum AdvisorIntent: Equatable {
    /// They named a role — always one that exists (a `Job.baseTitle`).
    case chooseRole(String)
    /// They haven't decided what they want to do.
    case undecided
    /// Anything else: a question to answer.
    case question
}

/// Something that can talk. The advisor's *judgement* is `AdvisorCoach`'s; this
/// only reads the player's words and phrases the coach's facts, so a model that
/// is unavailable, slow or wrong costs nothing but warmth — every method may
/// answer nil, and the conversation then falls back to the plain text.
protocol AdvisorLanguage: Sendable {
    /// Whether it can take free-form words right now.
    var isAvailable: Bool { get }
    /// A line for the player when it isn't (Apple Intelligence off, say).
    var note: String? { get }
    /// Gets ready ahead of the first request, to shorten the wait.
    func prewarm()
    /// The brief in the advisor's own voice.
    func narrate(_ brief: AdvisorBrief) async -> String?
    /// What the player's words ask for.
    func interpret(_ text: String) async -> AdvisorIntent?
    /// An answer to a free question, drawn from the brief's facts.
    func answer(_ question: String, brief: AdvisorBrief) async -> String?
}

extension AdvisorLanguage {
    var note: String? { nil }
    func prewarm() {}
}

/// No model: the conversation runs on the coach's plain text and tap-to-answer
/// buttons alone.
struct AdvisorPlainLanguage: AdvisorLanguage {
    var isAvailable: Bool { false }
    var note: String?
    func narrate(_ brief: AdvisorBrief) async -> String? { nil }
    func interpret(_ text: String) async -> AdvisorIntent? { nil }
    func answer(_ question: String, brief: AdvisorBrief) async -> String? { nil }
}

/// Keeps a model honest. A small on-device model is happy to round a chance
/// up, or to "work out" a number it was never given; the advisor quotes odds
/// the player will act on, so a reply is shown only if every number in it
/// appears in the facts it was written from.
enum AdvisorGuard {
    /// The numbers in `text`, as bare digits: "68,000 $" → "68000", "12%" → "12".
    static func numbers(in text: String) -> Set<String> {
        var found = Set<String>()
        var current = ""
        func flush() {
            let digits = current.filter(\.isNumber)
            if !digits.isEmpty { found.insert(digits) }
            current = ""
        }
        let characters = Array(text)
        for (index, character) in characters.enumerated() {
            if character.isNumber {
                current.append(character)
            } else if (character == "," || character == "."),
                      !current.isEmpty,
                      index + 1 < characters.count, characters[index + 1].isNumber {
                // A thousands separator or a decimal point inside a number.
                current.append(character)
            } else {
                flush()
            }
        }
        flush()
        return found
    }

    /// Whether every number in `text` is one of the facts' numbers.
    static func isGrounded(_ text: String, in facts: [String]) -> Bool {
        numbers(in: text).isSubset(of: numbers(in: facts.joined(separator: "\n")))
    }

    /// A model's reply ready to show, or nil when it isn't fit: empty, rambling,
    /// or quoting numbers the facts don't hold.
    static func accept(_ reply: String, facts: [String], maxLength: Int = 700) -> String? {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= maxLength, isGrounded(text, in: facts) else { return nil }
        return text
    }
}

// MARK: - The conversation

struct AdvisorMessage: Identifiable, Equatable {
    enum Speaker: Equatable { case advisor, player }

    let id = UUID()
    let speaker: Speaker
    /// A small line above the text — "📅 Check-in · age 21".
    var heading: String?
    var text: String
    var cards: [AdvisorCard] = []
}

/// A tap-to-answer chip under the conversation.
struct AdvisorReply: Identifiable, Equatable {
    enum Kind: Equatable {
        case haveRole, undecided, changeGoal
        case browse(JobCategory), pickRole(String), backToFields
        case bestMoves
        /// Shows the odds, gates and levers behind the goal.
        case showPath
        /// Shows how the goal works in the real world.
        case realWorld
    }

    let label: String
    let kind: Kind

    var id: String { label }
}

/// The advisor's side of the chat, and the state it needs: what it has said,
/// what the player can answer with, and the flow that connects them.
///
///     first time      →  "Do you have a role in mind, or not decided yet?"
///     a role in mind  →  where the listings are, what skills (and degree,
///                        licences, years) it takes, and which activity builds each
///     not decided     →  different things to try; after a few moves, roles that
///                        use the skills gained
///     every move      →  a review of progress, with corrections
///
/// Every answer works by tapping a chip, so the game is complete without a
/// model. With one (`AdvisorLanguage.isAvailable`) the player can also type —
/// name a role, say they're undecided, or ask anything — and the coach's
/// facts come back in the advisor's own words.
@MainActor
final class AdvisorConversation: ObservableObject {
    @Published private(set) var messages: [AdvisorMessage] = []
    @Published private(set) var replies: [AdvisorReply] = []
    @Published private(set) var isThinking = false
    /// Whether the advisor is waiting for the player to name a role.
    @Published private(set) var choosing = false
    /// The first advisor message of the latest reply — where the view scrolls
    /// to, so a reply of several messages is read from its top.
    @Published private(set) var focusMessageID: UUID?

    private let player: Player
    private let language: AdvisorLanguage
    private var started = false
    /// Set when a reply begins; the first advisor message after it takes the focus.
    private var replyBegins = false

    /// How long the model gets before the plain text is shown instead.
    static let narrationTimeout: Duration = .seconds(12)
    static let answerTimeout: Duration = .seconds(25)

    init(player: Player, language: AdvisorLanguage) {
        self.player = player
        self.language = language
    }

    /// Whether the text box has a use: to name a role, or — with a model — to ask.
    var acceptsText: Bool { choosing || language.isAvailable }
    var languageNote: String? { language.isAvailable ? nil : language.note }

    // MARK: Opening

    /// Opens the conversation: the opening question the first time, a review of
    /// the year when one is waiting, else where things stand.
    func start() async {
        guard !started else { return }
        started = true
        language.prewarm()
        isThinking = true
        replyBegins = true
        defer { isThinking = false }

        let plan = player.advisorPlan
        switch plan.path {
        case .unasked:
            askOpeningQuestion(changing: false)
        case .exploring, .target:
            if plan.unreadCount > 0, let latest = plan.checkIns.last {
                await present(checkIn: latest)
                player.advisorPlan.unreadCount = 0
            } else {
                await presentStatus()
            }
            offerFollowUps()
        }
    }

    // MARK: Taking answers

    /// The player tapped a chip.
    func choose(_ reply: AdvisorReply) async {
        guard !isThinking else { return }
        isThinking = true
        defer { isThinking = false }
        say(player: reply.label)
        replies = []
        replyBegins = true

        switch reply.kind {
        case .haveRole, .backToFields:
            askForRole()
        case .undecided:
            await beginExploring()
        case .changeGoal:
            choosing = false
            askOpeningQuestion(changing: true)
        case .browse(let category):
            browse(category)
        case .pickRole(let title):
            await aim(at: title, lead: "Great choice!")
        case .bestMoves:
            await presentBestMoves()
            offerFollowUps()
        case .showPath:
            if let guide = currentGuide() { await presentPathway(guide, forced: true) }
            offerFollowUps()
        case .realWorld:
            if let guide = currentGuide(), let note = AdvisorRealWorld.note(for: guide.focus) { presentRealWorld(note) }
            offerFollowUps()
        }
    }

    /// The player picked a role from a card — a suggestion, say.
    func aim(at title: String) async {
        guard !isThinking, let family = AdvisorCoach.family(title) else { return }
        isThinking = true
        defer { isThinking = false }
        say(player: "I'd like to be \(CareerAdvisor.article(for: family.baseTitle)) \(family.baseTitle)")
        replies = []
        replyBegins = true
        await aim(at: title, lead: "Great choice!")
    }

    /// The player typed something.
    func send(_ text: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        isThinking = true
        defer { isThinking = false }
        say(player: text)
        replies = []
        replyBegins = true

        if choosing {
            await resolveRole(from: text)
            return
        }
        guard language.isAvailable else {
            say(advisor: "I can only take your answers from the buttons right now — pick one below.")
            offerFollowUps()
            return
        }
        let intent = await withTimeout(Self.narrationTimeout) { await self.language.interpret(text) } ?? .question
        switch intent {
        case .chooseRole(let title) where AdvisorCoach.family(title) != nil:
            await settle(on: title, typed: text)
        case .undecided:
            await beginExploring()
        default:
            await answer(text)
            offerFollowUps()
        }
    }

    // MARK: Flow

    private func askOpeningQuestion(changing: Bool) {
        say(advisor: changing
            ? "Sure — let's pick a new direction. Do you have a job in mind now, or would you like to explore again?"
            : "Hi, I'm your career advisor! 👋 Do you already have a job in mind that you'd like to work toward — or haven't you decided yet? Either answer is fine.")
        replies = [
            AdvisorReply(label: "🎯 I have a role in mind", kind: .haveRole),
            AdvisorReply(label: "🤔 I haven't decided yet", kind: .undecided),
        ]
    }

    private func askForRole() {
        choosing = true
        say(advisor: "Which job are you thinking about? Type it below (like “nurse” or “game”), or pick a field to browse.")
        replies = AdvisorCoach.fields.map {
            AdvisorReply(label: "\(JobCategory.icon(for: $0)) \($0.rawValue)", kind: .browse($0))
        }
    }

    private func browse(_ category: JobCategory) {
        say(advisor: "Here are the \(category.rawValue) jobs. Which one sounds like you?")
        replies = AdvisorCoach.families(in: category).map(roleChip)
            + [AdvisorReply(label: "← Other fields", kind: .backToFields)]
    }

    private func roleChip(_ family: AdvisorCoach.RoleFamily) -> AdvisorReply {
        AdvisorReply(label: "\(family.icon) \(family.baseTitle)", kind: .pickRole(family.baseTitle))
    }

    /// Reads a typed role: the model first when there is one, the plain search
    /// otherwise — and always the plain search as its backstop.
    private func resolveRole(from text: String) async {
        if language.isAvailable,
           case .chooseRole(let title)? = await withTimeout(Self.narrationTimeout, { await self.language.interpret(text) }),
           AdvisorCoach.family(title) != nil {
            await settle(on: title, typed: text)
            return
        }
        let matches = AdvisorCoach.search(text).map(\.baseTitle)
        let typed = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if matches.count == 1 || matches.first?.lowercased() == typed, let title = matches.first {
            await aim(at: title, lead: "Great choice!")
        } else if matches.isEmpty {
            say(advisor: "I couldn't find a job like that. Try another word (like “nurse”, “engineer” or “game”), or pick a field.")
            replies = AdvisorCoach.fields.map {
                AdvisorReply(label: "\(JobCategory.icon(for: $0)) \($0.rawValue)", kind: .browse($0))
            }
        } else {
            say(advisor: "A few jobs fit that. Which one do you mean?")
            replies = matches.compactMap(AdvisorCoach.family).map(roleChip)
                + [AdvisorReply(label: "← Other fields", kind: .backToFields)]
        }
    }

    /// Acts on the model's reading of a typed role. It's trusted for anything
    /// descriptive ("I'd like to spend my days cooking in a restaurant"), but a
    /// word or two that fits several jobs — "nurse" fits four — is the
    /// player's to settle, not the model's to guess.
    private func settle(on title: String, typed text: String) async {
        let candidates = AdvisorCoach.search(text).map(\.baseTitle)
        let named = text.lowercased().contains(title.lowercased())
        if AdvisorCoach.contentWords(text).count <= 2, !named, candidates.count > 1, candidates.contains(title) {
            say(advisor: "A few jobs fit that. Which one do you mean?")
            replies = candidates.compactMap(AdvisorCoach.family).map(roleChip)
                + [AdvisorReply(label: "← Other fields", kind: .backToFields)]
            choosing = true
        } else {
            await aim(at: title, lead: "Great choice!")
        }
    }

    private func aim(at title: String, lead: String) async {
        choosing = false
        player.advisorPlan = AdvisorCoach.begin(.target(title), for: player)
        await presentGuide(title, lead: lead, full: true)
        offerFollowUps()
    }

    private func beginExploring() async {
        choosing = false
        player.advisorPlan = AdvisorCoach.begin(.exploring, for: player)
        await presentExploration(lead: "No problem!")
        offerFollowUps()
    }

    private func offerFollowUps() {
        switch player.advisorPlan.path {
        case .unasked:
            replies = [
                AdvisorReply(label: "🎯 I have a role in mind", kind: .haveRole),
                AdvisorReply(label: "🤔 I haven't decided yet", kind: .undecided),
            ]
        case .exploring:
            replies = [
                AdvisorReply(label: "🎯 I have a role in mind", kind: .haveRole),
                AdvisorReply(label: "💡 Best moves right now", kind: .bestMoves),
            ]
        case .target:
            var chips = [
                AdvisorReply(label: "🔄 Change my goal", kind: .changeGoal),
                AdvisorReply(label: "💡 Best moves right now", kind: .bestMoves),
            ]
            if let guide = currentGuide() {
                if let path = AdvisorPathway.pathway(for: guide, player: player) {
                    chips.append(AdvisorReply(label: path.isNarrow ? "🧭 The narrow path" : "🧭 What decides it", kind: .showPath))
                }
                if AdvisorRealWorld.note(for: guide.focus) != nil {
                    chips.append(AdvisorReply(label: "🌍 How it works in real life", kind: .realWorld))
                }
            }
            replies = chips
        }
    }

    /// The guide for the role the player is working toward, if they've picked one.
    private func currentGuide() -> AdvisorCoach.RoleGuide? {
        player.advisorPlan.target.flatMap { AdvisorCoach.guide(for: $0, player: player) }
    }

    // MARK: Saying things

    private func say(player text: String) {
        messages.append(AdvisorMessage(speaker: .player, text: text))
    }

    private func say(advisor text: String, heading: String? = nil, cards: [AdvisorCard] = []) {
        let message = AdvisorMessage(speaker: .advisor, heading: heading, text: text, cards: cards)
        messages.append(message)
        if replyBegins {
            focusMessageID = message.id
            replyBegins = false
        }
    }

    /// Says the brief in the model's words when it has any, else in the plain
    /// text. The cards under it are always the coach's own.
    private func say(_ brief: AdvisorBrief, heading: String? = nil, cards: [AdvisorCard] = []) async {
        var text = brief.plain
        if language.isAvailable,
           let reply = await withTimeout(Self.narrationTimeout, { await self.language.narrate(brief) }),
           let accepted = AdvisorGuard.accept(reply, facts: brief.facts + [brief.plain]) {
            text = accepted
        }
        say(advisor: text, heading: heading, cards: cards)
    }

    /// Runs `work` for at most `limit`; nil if it finishes empty-handed or runs out of time.
    private func withTimeout<T: Sendable>(_ limit: Duration, _ work: @escaping @Sendable () async -> T?) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await work() }
            group.addTask {
                try? await Task.sleep(for: limit)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    // MARK: Presenting

    /// Where the player stands on a role. `full` adds what a first look at a
    /// hard role needs — the narrow path and the real-world view — which the
    /// player can call up again with a chip.
    private func presentGuide(_ title: String, lead: String, full: Bool = false) async {
        guard let guide = AdvisorCoach.guide(for: title, player: player) else { return }
        var plain = "\(lead) \(AdvisorCoach.introduction(guide, player: player))"
        if guide.steps.contains(where: { ![.listing, .apply].contains($0.kind) }) {
            plain += " Here's what would help most:"
        }
        let brief = AdvisorBrief(
            topic: "The player chose \(title) as their goal. Tell them where they stand and point them to the steps listed below your message.",
            facts: AdvisorCoach.facts(guide, player: player), plain: plain)
        await say(brief, cards: guide.cards)
        if full {
            await presentPathway(guide, forced: false)
            if let note = AdvisorRealWorld.note(for: guide.focus) { presentRealWorld(note) }
        }
    }

    /// The odds behind the goal: how narrow it is, the gates, and the levers that
    /// move it. Shown unprompted for a narrow role; on request for any other.
    private func presentPathway(_ guide: AdvisorCoach.RoleGuide, forced: Bool) async {
        guard let path = AdvisorPathway.pathway(for: guide, player: player) else {
            if forced {
                say(advisor: "There's no odds to weigh here: a Simplified game hires with certainty once you meet the requirements, and a promotion follows its own rules.")
            }
            return
        }
        guard forced || path.isNarrow else { return }
        let brief = AdvisorBrief(
            topic: "The player's goal is \(path.title). Explain how narrow the path is and what decides it; the gates and the levers are listed below your message.",
            facts: path.facts, plain: path.headline)
        await say(brief, heading: "🧭 The narrow path", cards: path.gates + path.leverCards)
    }

    /// The curated real-world view of the role, beside what the game does with it.
    private func presentRealWorld(_ note: AdvisorRealWorld.Note) {
        say(advisor: "Here's how this works in real life — and how the game plays it.",
            heading: "🌍 \(note.title)", cards: note.cards)
    }

    private func presentExploration(lead: String) async {
        let plan = player.advisorPlan
        let moves = plan.moves(for: player)
        let left = max(0, AdvisorCoach.exploreMoves - moves)
        let ideas = AdvisorCoach.activityIdeas(for: player)
        var plain = "\(lead) The best way to find out what you like is to try different things."
        var facts = ["The player hasn't chosen a role yet and is exploring."]
        if ideas.isEmpty {
            plain += " Nothing new is open to you right now — look through the jobs list for something that catches your eye."
        } else {
            plain += " This year, try one of these:"
            facts += ideas.map { "\($0.sport.label) builds \(AdvisorCoach.list($0.builds))" }
        }
        if moves > 0 {
            plain += left > 0
                ? " You're \(moves) move\(moves == 1 ? "" : "s") in — \(left) more and I'll suggest jobs that fit you."
                : " Once you've tried a couple of different things, I'll suggest jobs that fit you."
            facts.append("Moves spent exploring so far: \(moves). Moves left before suggestions: \(left).")
        } else {
            plain += " After a few moves, I'll suggest jobs that fit the skills you've built."
            facts.append("After \(AdvisorCoach.exploreMoves) moves the advisor will suggest jobs that fit the skills gained.")
        }
        let cards = ideas.map { idea in
            AdvisorCard(icon: idea.sport.pictogram, title: idea.sport.label,
                        detail: "Builds \(AdvisorCoach.list(idea.builds)).",
                        actions: [AdvisorAction(label: "Open Activities", effect: .go(.activities(idea.sport.kind)))])
        }
        let brief = AdvisorBrief(
            topic: "The player hasn't decided on a role. Encourage them to try different activities; the ideas are listed below your message.",
            facts: facts, plain: plain)
        await say(brief, cards: cards)
    }

    /// Where things stand, when there's no new review to read.
    private func presentStatus() async {
        switch player.advisorPlan.path {
        case .target(let title):
            await presentGuide(title, lead: "Here's where you stand.")
        case .exploring:
            if let latest = player.advisorPlan.checkIns.last, !latest.suggestions.isEmpty {
                await present(checkIn: latest)
            } else {
                await presentExploration(lead: "Still exploring — good.")
            }
        case .unasked:
            break
        }
    }

    private func present(checkIn: AdvisorCheckIn) async {
        var cards = checkIn.progress.map(Self.progressCard)
        cards += checkIn.corrections
        for title in checkIn.suggestions {
            if let card = suggestionCard(title) { cards.append(card) }
        }
        let brief = AdvisorBrief(
            topic: checkIn.role.map { "The advisor's yearly review of the player's progress toward \($0)." }
                ?? "The advisor's yearly review of the player's exploring.",
            facts: AdvisorCoach.facts(checkIn), plain: checkIn.headline)
        await say(brief, heading: "📅 Check-in · age \(checkIn.age)", cards: cards)
    }

    private func suggestionCard(_ title: String) -> AdvisorCard? {
        guard let suggestion = AdvisorCoach.suggestion(title, player: player) else { return nil }
        var detail = "Uses your \(AdvisorCoach.list(suggestion.matches)). Pays \(suggestion.pay)."
        if !suggestion.needs.isEmpty { detail += " It takes \(AdvisorCoach.list(suggestion.needs))." }
        var actions = [AdvisorAction(label: "Aim for this", effect: .aim(title))]
        if player.availableJobs.contains(where: { $0.baseTitle == title }) {
            actions.append(AdvisorAction(label: "See job listings", effect: .go(.listing(title))))
        }
        return AdvisorCard(icon: suggestion.icon, title: title, detail: detail, actions: actions)
    }

    /// A review's "🎯 Your chance went from 10% to 20%" line as a card: the
    /// leading pictogram becomes the icon.
    private static func progressCard(_ line: String) -> AdvisorCard {
        guard let first = line.first, !first.isASCII else { return AdvisorCard(icon: "•", detail: line) }
        return AdvisorCard(icon: String(first), detail: line.dropFirst().trimmingCharacters(in: .whitespaces))
    }

    private func presentBestMoves() async {
        let tips = CareerAdvisor.tips(for: player)
        guard !tips.isEmpty else {
            say(advisor: "Right now, the best move is to keep going! Keep building your skills and check back next year. 👍")
            return
        }
        let cards = tips.map { tip in
            AdvisorCard(icon: tip.icon, title: tip.title, detail: tip.detail,
                        actions: tip.destination.map { [AdvisorAction(label: $0.buttonLabel, effect: .go($0))] } ?? [])
        }
        say(advisor: "Here are the moves that pay off most right now, best first:", cards: cards)
    }

    private func answer(_ question: String) async {
        let brief = AdvisorBrief(
            topic: "The player asked: \(question)",
            facts: AdvisorCoach.playerFacts(player), plain: "")
        if let reply = await withTimeout(Self.answerTimeout, { await self.language.answer(question, brief: brief) }) {
            say(advisor: reply)
        } else {
            say(advisor: "Hmm, I'm not sure about that one. I can tell you about a job, a skill, or what to do next — try asking it that way.")
        }
    }
}
