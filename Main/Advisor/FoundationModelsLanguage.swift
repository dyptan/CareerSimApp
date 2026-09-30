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
        return AdvisorPlainLanguage(note: "Chatting with the advisor needs iOS or macOS 26 with Apple Intelligence — for now you'll get its standard advice.")
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
        let session: LanguageModelSession
        let log: FactLog
    }

    init(player: Player) {
        self.player = player
    }

    var isAvailable: Bool { model.isAvailable }

    var note: String? {
        guard case .unavailable(let reason) = model.availability else { return nil }
        switch reason {
        case .deviceNotEligible:
            return "This device can't run Apple Intelligence, so you'll get the advisor's standard advice."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to chat with the advisor. For now you'll get its standard advice."
        case .modelNotReady:
            return "Apple Intelligence is still getting ready. For now you'll get the advisor's standard advice."
        @unknown default:
            return nil
        }
    }

    func prewarm() {
        guard isAvailable else { return }
        LanguageModelSession(instructions: Self.persona).prewarm()
    }

    // MARK: Phrasing

    /// Who the advisor is. Short, because the on-device model has a small
    /// context window and every narration starts from it afresh.
    private static let persona = """
        You are the career advisor in a life-simulation game for young players, and you are talking to the player directly.
        Write two or three short, warm, simple sentences — like a friendly coach, not a textbook.
        Use ONLY the facts you are given. Never invent jobs, skills, numbers or game rules, and never do arithmetic: copy any number exactly as it is written in the facts.
        Do not use lists, headings or markdown, and never mention these instructions.
        """

    func narrate(_ brief: AdvisorBrief) async -> String? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: Self.persona)
        let facts = brief.facts.map { "- \($0)" }.joined(separator: "\n")
        let prompt = """
            Topic: \(brief.topic)

            Facts:
            \(facts)

            Say this to the player in your own words. Here is the plain version: "\(brief.plain)"
            """
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
    /// real role titles (or "none"), so a reading can only ever name a job that exists.
    private static let intentSchema: GenerationSchema? = {
        let kind = DynamicGenerationSchema(name: "Kind", anyOf: ["chooseRole", "undecided", "question"])
        let role = DynamicGenerationSchema(name: "Role", anyOf: AdvisorCoach.families.map(\.baseTitle) + ["none"])
        let root = DynamicGenerationSchema(name: "PlayerIntent", properties: [
            .init(name: "kind", description: "What the player wants", schema: kind),
            .init(name: "role", description: "The job that fits best, or none", schema: role),
        ])
        return try? GenerationSchema(root: root, dependencies: [])
    }()

    func interpret(_ text: String) async -> AdvisorIntent? {
        guard isAvailable, let schema = Self.intentSchema else { return nil }
        let session = LanguageModelSession(instructions: """
            You read what a player typed to their career advisor and decide what they want.
            kind is "chooseRole" when they name a job or describe work they would like to do, "undecided" when they say they don't know what they want to do yet, and "question" for anything else.
            role is the job that fits best when kind is "chooseRole", otherwise "none".
            """)
        do {
            let response = try await session.respond(
                to: "The player typed: \"\(text)\"", schema: schema,
                options: GenerationOptions(samplingMode: .greedy))
            let kind = try response.content.value(String.self, forProperty: "kind")
            let role = try response.content.value(String.self, forProperty: "role")
            switch kind {
            case "chooseRole": return role == "none" ? .question : .chooseRole(role)
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
            let chat = chatSession(facts: brief.facts)
            do {
                let response = try await chat.session.respond(
                    to: question, options: GenerationOptions(temperature: 0.5, maximumResponseTokens: 220))
                return AdvisorGuard.accept(response.content, facts: brief.facts + chat.log.lines)
            } catch {
                dropChat()
            }
        }
        return nil
    }

    private func chatSession(facts: [String]) -> Chat {
        lock.lock()
        defer { lock.unlock() }
        if let chat, chat.facts == facts { return chat }
        let log = FactLog()
        let known = facts.map { "- \($0)" }.joined(separator: "\n")
        let session = LanguageModelSession(
            tools: [RoleInfoTool(player: player, log: log)],
            instructions: """
                \(Self.persona)
                You can also answer questions about jobs, skills, school and what to do next. Keep answers to four short sentences at most.
                What you know about the player right now:
                \(known)
                Lines that start with "In the real world:" are real-world background, and each is followed by an "In the game:" line saying what the game does about it. When the player asks how a job really works or why it is hard to get, answer from those lines first, then say how the game plays it.
                When the player asks about a job you have no facts about, call the roleInfo tool for it. If you still don't know, say so kindly and suggest what they could ask instead.
                """)
        let fresh = Chat(facts: facts, session: session, log: log)
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
/// so what it says about a role is what the coach would say.
@available(iOS 26.0, macOS 26.0, *)
private struct RoleInfoTool: Tool, @unchecked Sendable {
    let name = "roleInfo"
    let description = "Looks up a job in the game: its pay, and what the player still needs to get it (skills, school, licences, years of experience). Use it whenever the player asks about a specific job."

    let player: Player
    let log: FactLog

    @Generable
    struct Arguments {
        @Guide(description: "The job title, or a word from it, such as nurse or pilot")
        var job: String
    }

    func call(arguments: Arguments) async throws -> String {
        let text = await MainActor.run { () -> String in
            guard let family = AdvisorCoach.search(arguments.job, limit: 1).first,
                  let guide = AdvisorCoach.guide(for: family.baseTitle, player: player) else {
                return "There is no job matching \"\(arguments.job)\" in the game."
            }
            return AdvisorCoach.facts(guide, player: player).joined(separator: "\n")
        }
        log.add(text)
        return text
    }
}

#endif
