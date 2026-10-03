import SwiftUI

/// Professional events this year — summits, conferences, expos, festivals and
/// pitch competitions. Each is tied to an industry, and there is one way to
/// take part: **apply to take the stage** — speak, present, perform or pitch,
/// in the event's own words. The acceptance odds come from experience,
/// communication and fame (see `Player.presentOdds`); accepted, it banks the
/// field's network plus a fame title, and turned down, the player still goes
/// and banks a little network. Either way the year is spent. Rows follow the
/// Projects sheet (see `SideHustleRow`): the odds beside the name, one button,
/// an ⓘ.
struct EventsView: View {
    @ObservedObject var player: Player
    @Binding var selectedEvents: Set<String>
    /// Taking part spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    /// The sheet's title ⓘ. One paragraph per key.
    static var hint: String {
        [
            L("At an event you ask to go on stage — to give a talk, perform or pitch. 🎲 is your chance they say yes."),
            L("If they pick you, you get known in that field and meet lots of people there — both help you get hired and promoted. If not, you still go and meet a few people."),
            L("Taking part uses up your year."),
        ].joined(separator: "\n\n")
    }

    /// Events the player can join first, best odds first — so the stages the
    /// player has built toward lead, as on the Projects sheet — then by name.
    /// Closed events show no odds, so they just go by name.
    private var events: [CareerEvent] {
        EventCatalog.all.sorted {
            let a = player.canJoinEvent($0), b = player.canJoinEvent($1)
            guard a == b else { return a }
            let oddsA = a ? player.presentOdds($0) : 0, oddsB = b ? player.presentOdds($1) : 0
            return oddsA == oddsB ? NameOrder.before($0.name, $1.name) : oddsA > oddsB
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(events) { event in
                    row(for: event)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func row(for event: CareerEvent) -> some View {
        let locked = !player.canJoinEvent(event)
        let odds = player.presentOdds(event)

        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(verbatim: "\(event.icon)  \(event.name)")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    if !locked {
                        // Event names run long; the name wraps, the odds don't.
                        Text(verbatim: "🎲 \(Fmt.percent(odds))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Color.forOdds(odds))
                            .fixedSize()
                    }
                }
                if locked {
                    Text(L("🔒 Work or study in \(event.category.displayName) to take part"))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .opacity(locked ? 0.5 : 1.0)
            Spacer(minLength: 8)

            // Applying is committing the year to it — the sheet closes and the
            // year runs, so there is only ever one application to hold.
            TakeButton(label: event.presenterActionLabel) {
                player.applyToPresent(event, into: &selectedEvents)
                onCommit()
            }
            .disabled(locked)
            .opacity(locked ? 0.5 : 1.0)

            InfoHint(
                title: "\(event.icon) \(event.name)",
                message: infoMessage(for: event, odds: odds, locked: locked)
            )
        }
        .padding(5)
    }

    /// The event hint, in the Projects hint's shape: what it is, the odds and
    /// what moves them, what a yes and a no each bring, and the skills it
    /// grows either way.
    private func infoMessage(for event: CareerEvent, odds: Double, locked: Bool) -> String {
        let field = "\(JobCategory.icon(for: event.category)) \(event.category.displayName)"
        let voice = SkillLine.tag(\.communicationAndNetworking)
        let grows = event.abilities
            .map(SkillLine.plus)
            .joined(separator: "\n")

        let chance = locked
            ? L("🔒 Work or study in \(field) to take part. Then your chance goes up with years of work there, your \(voice) skill and your fame in the field.")
            : L("🎲 \(Fmt.percent(odds)) chance they pick you. It goes up with years of work in \(field), your \(voice) skill and your fame there.")
        return [
            event.blurb,
            chance,
            event.isOpenCall ? L("📣 Anyone can apply.") : nil,
            L("If they pick you: you win the “\(event.presenterFameTitle)” title (🌟 fame) and meet lots of people in \(field), who can help you get hired and promoted there."),
            L("If not: you still go and meet a few people."),
            L("Grows either way:\n\(grows)"),
        ].compactMap { $0 }.joined(separator: "\n\n")
    }
}

#Preview {
    EventsView(
        player: Player(),
        selectedEvents: .constant([])
    )
    .padding()
}
