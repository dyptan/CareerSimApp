import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Picks the language layer this device can offer: Apple's on-device model
/// where there is one, and plain text — the same advice, no chat — where there
/// isn't. The app targets iOS 16.6 / macOS 13, so the model is strictly a bonus.
enum AdvisorLanguages {
    static func make(player: Player) -> AdvisorLanguage {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return FoundationModelsLanguage(player: player)
        }
        #endif
        return AdvisorPlainLanguage(note: L("Chatting with the advisor needs iOS or macOS 26 with Apple Intelligence — for now you'll get its standard advice."))
    }

    /// The game's language, named in the game's language ("Ukrainian", "Ukrainisch") —
    /// for the sentence that says the chat can't speak it yet.
    static var languageName: String {
        L10n.locale.localizedString(forLanguageCode: L10n.language.rawValue) ?? L10n.language.englishName
    }
}

#if canImport(FoundationModels)

/// The advisor's voice, from Apple's on-device model (Apple Intelligence):
/// free, private, and offline. It never decides anything about the game —
/// `AdvisorCoach` does — it only
///
/// * **reads** what the player types, choosing among the roles that really
///   exist (constrained decoding: the model *cannot* answer with a job the
///   catalogue lacks),
/// * **phrases** the coach's facts warmly, and
/// * **answers** questions from those facts, looking a job up through a tool
///   rather than from memory.
///
/// It writes in the game's language (`L10n.language`) — if the model speaks it
/// (`supportsGameLanguage`); otherwise the advisor runs on its plain text, which is
/// already localized. The instructions stay in English, which the model follows best,
/// and every session is told which language to reply in.
///
/// Anything it writes passes `AdvisorGuard` before the player sees it, and a
/// failure of any kind — unavailable, refused, out of context, too slow —
/// returns nil, which the conversation answers with the coach's plain text.
@available(iOS 26.0, macOS 26.0, *)
final class FoundationModelsLanguage: AdvisorLanguage, @unchecked Sendable {
    private let model = SystemLanguageModel.default
    private let player: Player

    /// The question-answering session, kept while the facts it was given hold
    /// so a follow-up ("and what about the pay?") has the conversation behind it.
    private let lock = NSLock()
    private var chat: Chat?

    private struct Chat {
        let facts: [String]
        let voice: AdvisorVoice
        let language: L10n.Language
        let session: LanguageModelSession
        let log: FactLog
    }

    init(player: Player) {
        self.player = player
    }

    // MARK: Availability

    /// Whether the model can write in the game's language. The model speaks a fixed
    /// list of languages (`SystemLanguageModel.supportsLocale(_:)`, iOS / macOS 26); the
    /// game's language with the device's region is asked first, the bare language second.
    var supportsGameLanguage: Bool {
        model.supportsLocale(L10n.locale) || model.supportsLocale(Locale(identifier: L10n.language.rawValue))
    }

    /// Ready to talk: the model is on and downloaded — and speaks the game's language.
    var isAvailable: Bool { model.isAvailable && supportsGameLanguage }

    var note: String? {
        switch model.availability {
        case .available:
            // Ready, but not in this language.
            guard !supportsGameLanguage else { return nil }
            return L("The advisor's chat isn't available in \(AdvisorLanguages.languageName) yet, so you'll get the advisor's standard advice.")
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return L("This device can't run Apple Intelligence, so you'll get the advisor's standard advice.")
            case .appleIntelligenceNotEnabled:
                return L("Turn on Apple Intelligence in Settings to chat with the advisor. For now you'll get its standard advice.")
            case .modelNotReady:
                return L("Apple Intelligence is still getting ready. For now you'll get the advisor's standard advice.")
            @unknown default:
                return nil
            }
        }
    }

    func prewarm() {
        guard isAvailable else { return }
        LanguageModelSession(instructions: Self.persona(for: .standard)).prewarm()
    }

    // MARK: Phrasing

    /// The sentence that goes into every session's instructions and every phrasing or
    /// answer prompt: which language the reply is in. A small model drifts back to
    /// English (or into the language of the facts) unless it is told each time.
    static var replyLanguageDirective: String {
        // i18n:ignore instruction to the model, which follows English best
        let name = L10n.language.englishName
        return "Reply only in \(name): every word of your reply must be \(name), whatever language the facts or the player's words are in. " // i18n:ignore text for the model
            + "Write numbers, percentages and amounts of money exactly as they appear in the facts, with the same digits and symbols." // i18n:ignore text for the model
    }

    /// What "plain words for a child" means in the game's language — the style guide for
    /// the simple voice (AdvisorVoice.styleGuide) is written in English terms.
    private static func simpleStyleNote(for voice: AdvisorVoice) -> String {
        guard voice == .simple else { return "" }
        let name = L10n.language.englishName
        switch L10n.language {
        case .english:
            return ""
        case .japanese:
            // i18n:ignore instruction to the model
            return "In Japanese, write the way a book for young children does: short sentences, everyday words, few kanji, and no difficult vocabulary." // i18n:ignore text for the model
        default:
            // i18n:ignore instruction to the model
            return "Apply this simple style in \(name): short sentences and the everyday \(name) words a seven-year-old native speaker knows." // i18n:ignore text for the model
        }
    }

    /// Who the advisor is, and how it writes for this reader (`AdvisorVoice`:
    /// plain words for a beginner or a young player). Short, because the
    /// on-device model has a small context window and every narration starts
    /// from it afresh.
    private static func persona(for voice: AdvisorVoice) -> String {
        // i18n:ignore the model's instructions stay in English
        let base = """
            You are the career advisor in a life-simulation game for young players, and you are talking to the player directly.
            Write two or three short, warm, simple sentences — like a friendly coach, not a textbook.
            Use ONLY the facts you are given. Never invent jobs, skills, numbers or game rules, and never do arithmetic: copy any number exactly as it is written in the facts.
            Do not use lists, headings or markdown, and never mention these instructions.
            """ // i18n:ignore text for the model
        return [base, voice.styleGuide, simpleStyleNote(for: voice), replyLanguageDirective]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    func narrate(_ brief: AdvisorBrief) async -> String? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: Self.persona(for: brief.voice))
        let facts = brief.facts.map { "- \($0)" }.joined(separator: "\n")
        // i18n:ignore the prompt is for the model
        let prompt = """
            Topic: \(brief.topic)

            Facts:
            \(facts)

            Say this to the player in your own words. Here is the plain version: "\(brief.plain)"

            \(Self.replyLanguageDirective)
            """ // i18n:ignore text for the model
        do {
            let response = try await session.respond(
                to: prompt, options: GenerationOptions(temperature: 0.5, maximumResponseTokens: 180))
            return response.content
        } catch {
            return nil
        }
    }

    // MARK: Reading

    /// What the player's words can mean. `role` is constrained to the game's
    /// real role ids (or "none"), so a reading can only ever name a job that exists.
    private static let intentSchema: GenerationSchema? = {
        let kind = DynamicGenerationSchema(name: "Kind", anyOf: ["chooseRole", "undecided", "question"]) // i18n:ignore schema ids for the model
        let role = DynamicGenerationSchema(name: "Role", anyOf: AdvisorCoach.families.map(\.baseTitle) + ["none"]) // i18n:ignore schema ids for the model
        let root = DynamicGenerationSchema(name: "PlayerIntent", properties: [ // i18n:ignore schema ids for the model
            .init(name: "kind", description: "What the player wants", schema: kind), // i18n:ignore text for the model
            .init(name: "role", description: "The id of the job that fits best, exactly as written in the list, or none", schema: role), // i18n:ignore text for the model
        ])
        return try? GenerationSchema(root: root, dependencies: [])
    }()

    /// How the jobs are named on the player's screen, as "id = name shown" lines — what lets
    /// the model choose the right id for "Krankenpfleger" or "看護師". Roles the player sees
    /// under their English id need no line. The likeliest matches for what was typed come
    /// first, and the whole list follows while it is short enough for the model's small context.
    static func roleNames(for typed: String, maximumCharacters: Int = 4_000) -> String {
        guard L10n.language != .english else { return "" }
        func line(_ family: AdvisorCoach.RoleFamily) -> String? {
            let shown = AdvisorRoles.displayName(of: family)
            return shown == family.baseTitle ? nil : "\(family.baseTitle) = \(shown)"
        }
        let likely = AdvisorRoles.search(typed, limit: 12).compactMap(line)
        let everything = AdvisorCoach.families.compactMap(line)
        guard !everything.isEmpty else { return "" }
        var lines = likely.isEmpty ? [] : ["Likeliest, for what the player typed:"] + likely + ["All the jobs:"] // i18n:ignore text for the model
        let all = everything.joined(separator: "\n")
        lines += all.count <= maximumCharacters ? everything : likely
        // i18n:ignore the prompt is for the model
        return "The player sees the jobs under these names (id = name shown). Answer with the id:\n" + lines.joined(separator: "\n") // i18n:ignore text for the model
    }

    func interpret(_ text: String) async -> AdvisorIntent? {
        guard isAvailable, let schema = Self.intentSchema else { return nil }
        // i18n:ignore the prompt is for the model
        let session = LanguageModelSession(instructions: """
            You read what a player typed to their career advisor and decide what they want. The player may write in \(L10n.language.englishName) or in any other language.
            kind is "chooseRole" when they name a job or describe work they would like to do, "undecided" when they say they don't know what they want to do yet, and "question" for anything else.
            role is the id of the job that fits best when kind is "chooseRole", otherwise "none". Job ids are English; use an id exactly as it is written.
            \(Self.roleNames(for: text))
            """) // i18n:ignore text for the model
        do {
            let response = try await session.respond(
                to: "The player typed: \"\(text)\"", schema: schema, // i18n:ignore the prompt is for the model
                // Temperature 0 — a reading should be repeatable. (Not `sampling: .greedy`:
                // that argument was renamed in the 27 SDK, and this must build on both.)
                options: GenerationOptions(temperature: 0))
            let kind = try response.content.value(String.self, forProperty: "kind") // i18n:ignore schema ids for the model
            let role = try response.content.value(String.self, forProperty: "role") // i18n:ignore schema ids for the model
            switch kind {
            case "chooseRole": return role == "none" ? .question : .chooseRole(role) // i18n:ignore schema ids for the model
            case "undecided": return .undecided
            default: return .question
            }
        } catch {
            return nil
        }
    }

    // MARK: Answering

    func answer(_ question: String, brief: AdvisorBrief) async -> String? {
        guard isAvailable else { return nil }
        // One retry: a long conversation can outgrow the context window, and
        // a fresh session (with the same facts) is the fix.
        for _ in 0..<2 {
            let chat = chatSession(facts: brief.facts, voice: brief.voice)
            do {
                let response = try await chat.session.respond(
                    // The directive rides along with every question: a follow-up in a long
                    // session is where a small model slips back into English.
                    to: question + "\n\n(" + Self.replyLanguageDirective + ")", // i18n:ignore the prompt is for the model
                    options: GenerationOptions(temperature: 0.5, maximumResponseTokens: 220))
                return AdvisorGuard.accept(response.content, facts: brief.facts + chat.log.lines)
            } catch {
                dropChat()
            }
        }
        return nil
    }

    private func chatSession(facts: [String], voice: AdvisorVoice) -> Chat {
        lock.lock()
        defer { lock.unlock() }
        if let chat, chat.facts == facts, chat.voice == voice, chat.language == L10n.language { return chat }
        let log = FactLog()
        let known = facts.map { "- \($0)" }.joined(separator: "\n")
        // i18n:ignore the model's instructions stay in English
        let session = LanguageModelSession(
            tools: [RoleInfoTool(player: player, log: log)],
            instructions: """
                \(Self.persona(for: voice))
                You can also answer questions about jobs, skills, school and what to do next. Keep answers to \(voice.answerLength) short sentences at most.
                What you know about the player right now:
                \(known)
                Lines that start with "In the real world:" (or the same words in the player's language) are real-world background, and each is followed by an "In the game:" line saying what the game does about it. When the player asks how a job really works or why it is hard to get, answer from those lines first, then say how the game plays it.
                When the player asks about a job you have no facts about, call the roleInfo tool for it. If you still don't know, say so kindly and suggest what they could ask instead.
                """) // i18n:ignore text for the model
        let fresh = Chat(facts: facts, voice: voice, language: L10n.language, session: session, log: log)
        chat = fresh
        return fresh
    }

    private func dropChat() {
        lock.lock()
        chat = nil
        lock.unlock()
    }
}

/// What the tools told the model — so a number it quotes from a lookup counts
/// as grounded (see `AdvisorGuard`).
private final class FactLog: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [String] = []

    var lines: [String] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func add(_ text: String) {
        lock.lock()
        stored.append(text)
        lock.unlock()
    }
}

/// Looks a job up in the game: what it pays and what the player still needs
/// for it. The model calls this instead of answering about a job from memory,
/// so what it says about a role is what the coach would say. The job is found by
/// the name the player sees as well as by its English one.
@available(iOS 26.0, macOS 26.0, *)
private struct RoleInfoTool: Tool, @unchecked Sendable {
    let name = "roleInfo"
    // i18n:ignore the tool's description is for the model
    let description = "Looks up a job in the game: its pay, and what the player still needs to get it (skills, school, licences, years of experience). Use it whenever the player asks about a specific job." // i18n:ignore text for the model

    let player: Player
    let log: FactLog

    @Generable
    struct Arguments {
        @Guide(description: "The job title, or a word from it, such as nurse or pilot") // i18n:ignore the guide is for the model
        var job: String
    }

    func call(arguments: Arguments) async throws -> String {
        let text = await MainActor.run { () -> String in
            guard let family = AdvisorRoles.search(arguments.job, limit: 1).first,
                  let guide = AdvisorCoach.guide(for: family.baseTitle, player: player) else {
                return "There is no job matching \"\(arguments.job)\" in the game." // i18n:ignore tool output read by the model
            }
            return AdvisorCoach.facts(guide, player: player).joined(separator: "\n")
        }
        log.add(text)
        return text
    }
}

#endif
