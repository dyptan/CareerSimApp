import SwiftUI

/// The career advisor's sheet: a chat. The advisor opens by asking whether the
/// player has a role in mind; every answer works by tapping a chip, and where
/// Apple Intelligence is available the player can also type. Its advice comes
/// as cards, each with a button that jumps to the sheet where the move is made.
/// Talking to it spends nothing — the year only moves once the player acts.
struct AdvisorView: View {
    @ObservedObject var player: Player
    /// Closes the advisor and opens the sheet a card points to.
    let onGo: (CareerAdvisor.Destination) -> Void

    @StateObject private var chat: AdvisorConversation
    @State private var draft = ""
    @FocusState private var typing: Bool

    init(player: Player,
         language: AdvisorLanguage? = nil,
         onGo: @escaping (CareerAdvisor.Destination) -> Void) {
        self.player = player
        self.onGo = onGo
        _chat = StateObject(wrappedValue: AdvisorConversation(
            player: player, language: language ?? AdvisorLanguages.make(player: player)))
    }

    /// The sheet's help text, one paragraph per catalog entry.
    static var hint: String {
        [
            L("Your career advisor helps you find a job you'll love."),
            L("🎯 Have a job in mind? It shows you where it's posted, and which skills, school and licences you need."),
            L("🤔 Not sure yet? It suggests things to try, and after a few moves it names jobs that fit the skills you've built."),
            L("🧭 For a hard-to-reach job, like CEO, it shows how narrow the path is and what really decides it — fame, network, school, years, and having built a company — with the real-world story behind it."),
            L("📅 After every year it checks how you're doing and suggests changes. A red dot on the Advice button means it has something for you."),
            L("✨ With Apple Intelligence you can type to it, too. The chances it shows are always the game's real chances. Talking is free — it doesn't use up your year."),
        ].joined(separator: "\n\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let note = chat.languageNote {
                            Text(verbatim: note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        ForEach(chat.messages) { message in
                            bubble(message).id(message.id)
                        }
                        if chat.isThinking {
                            thinking
                        }
                        Color.clear.frame(height: 1).id(Self.bottom)
                    }
                    .padding()
                    .frame(maxWidth: 560, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                // A reply of several long messages is read from its top: the
                // view jumps to the first of them, not the foot of the last.
                .onChange(of: chat.focusMessageID) { id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .top) }
                }
                // The player's own words, and the wait for the answer, stay in view.
                .onChange(of: chat.messages.count) { _ in
                    if chat.messages.last?.speaker == .player {
                        withAnimation { proxy.scrollTo(Self.bottom, anchor: .bottom) }
                    }
                }
                .onChange(of: chat.isThinking) { thinking in
                    if thinking { withAnimation { proxy.scrollTo(Self.bottom, anchor: .bottom) } }
                }
            }
            Divider()
            controls
        }
        .task { await chat.start() }
    }

    private static let bottom = "advisor-bottom"

    // MARK: Messages

    @ViewBuilder
    private func bubble(_ message: AdvisorMessage) -> some View {
        switch message.speaker {
        case .player:
            HStack {
                Spacer(minLength: 40)
                // What the player typed, or a chip's wording: data, shown as it is. Wraps to
                // as many lines as a long German or Ukrainian phrase needs.
                Text(verbatim: message.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .padding(10)
                    .background(Color.accentColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
            }
        case .advisor:
            HStack(alignment: .top, spacing: 8) {
                Text(verbatim: "💡").font(.title3)
                VStack(alignment: .leading, spacing: 8) {
                    if let heading = message.heading {
                        Text(verbatim: heading)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !message.text.isEmpty {
                        // The advisor's words — the coach's text or the model's reply — are data.
                        Text(verbatim: message.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(message.cards) { card in
                        cardView(card)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func cardView(_ card: AdvisorCard) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(verbatim: card.icon)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                if !card.title.isEmpty {
                    Text(verbatim: card.title)
                        .font(.subheadline.bold())
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(verbatim: card.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !card.actions.isEmpty {
                    // Buttons wrap onto a second line when the translations are long.
                    FlowLayout(spacing: 8) {
                        ForEach(card.actions) { action in
                            Button { perform(action) } label: {
                                Text(verbatim: action.label)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.quaternary.opacity(0.5)))
    }

    private var thinking: some View {
        HStack(spacing: 8) {
            Text(verbatim: "💡").font(.title3)
            ProgressView().controlSize(.small)
            Text("Thinking…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func perform(_ action: AdvisorAction) {
        switch action.effect {
        case .go(let destination):
            onGo(destination)
        case .aim(let title):
            Task { await chat.aim(at: title) }
        }
    }

    // MARK: Answering

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 8) {
            if !chat.replies.isEmpty {
                // A field's worth of role chips can run long: scroll rather than
                // push the conversation off the screen — and step aside while the
                // keyboard is up, when the conversation needs the room.
                if chat.replies.count > 8 {
                    if !typing { ScrollView { chips }.frame(maxHeight: 130) }
                } else {
                    chips
                }
            }
            if chat.acceptsText {
                HStack(spacing: 8) {
                    TextField(prompt, text: $draft)
                        .textFieldStyle(.roundedBorder)
                        .focused($typing)
                        .submitLabel(.send)
                        .onSubmit(sendDraft)
                    Button("Send", action: sendDraft)
                        .buttonStyle(.borderedProminent)
                        .fixedSize()
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || chat.isThinking)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    /// What the empty text box says: a job to type while the advisor is asking for one, else a question.
    private var prompt: String {
        chat.choosing ? L("Type a job, like “nurse”…") : L("Ask me anything…")
    }

    private var chips: some View {
        FlowLayout(spacing: 8) {
            ForEach(chat.replies) { reply in
                // A chip is a whole phrase; in German or Ukrainian a long one wraps inside its
                // button rather than running off the sheet (FlowLayout offers it the row's width).
                Button { Task { await chat.choose(reply) } } label: {
                    Text(verbatim: reply.label)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(chat.isThinking)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sendDraft() {
        let text = draft
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty, !chat.isThinking else { return }
        draft = ""
        // The answer is long and the sheet is short: lower the keyboard to read it.
        typing = false
        Task { await chat.send(text) }
    }
}

/// Lays chips out left to right, wrapping onto new lines — the standard
/// container has no such layout, and a row of a dozen fields needs one. A chip
/// wider than the row (a long German or Ukrainian phrase) is offered the row's
/// width and wraps its own text, rather than running off the sheet.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    private func size(of view: LayoutSubview, within width: CGFloat) -> CGSize {
        let ideal = view.sizeThatFits(.unspecified)
        guard width.isFinite, ideal.width > width else { return ideal }
        return view.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = size(of: view, within: width)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = size(of: view, within: bounds.width)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        AdvisorView(player: Player(), language: AdvisorPlainLanguage(), onGo: { _ in })
    }
}
