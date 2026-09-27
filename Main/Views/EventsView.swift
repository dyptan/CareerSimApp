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

    /// The sheet's title ⓘ.
    static let hint = """
    At an event you ask to go on stage — to give a talk, perform or pitch. 🎲 is your chance they say yes.

    If they pick you, you get known in that field and meet lots of people there — both help you get hired and promoted. If not, you still go and meet a few people.

    Taking part uses up your year.
    """

    /// Events the player can join first, best odds first — so the stages the
    /// player has built toward lead, as on the Projects sheet — then by name.
    /// Closed events show no odds, so they just go by name.
    private var events: [CareerEvent] {
        EventCatalog.all.sorted {
            let a = player.canJoinEvent($0), b = player.canJoinEvent($1)
            guard a == b else { return a }
            let oddsA = a ? player.presentOdds($0) : 0, oddsB = b ? player.presentOdds($1) : 0
            return oddsA == oddsB ? $0.name < $1.name : oddsA > oddsB
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
                    Text("\(event.icon)  \(event.name)")
                        .font(.headline)
                    if !locked {
                        // Event names run long; the name wraps, the odds don't.
                        Text("🎲 \(Int((odds * 100).rounded()))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Color.forOdds(odds))
                            .fixedSize()
                    }
                }
                if locked {
                    Text("🔒 Work or study in \(event.category.rawValue) to take part")
                        .font(.caption2)
                        .foregroundStyle(.orange)
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
        let field = "\(JobCategory.icon(for: event.category)) \(event.category.rawValue)"
        let voiceKeyPath: WritableKeyPath<SoftSkills, Int> = \.communicationAndNetworking
        let voice = "\(SoftSkills.pictogram(forKeyPath: voiceKeyPath) ?? "") \(SoftSkills.label(forKeyPath: voiceKeyPath) ?? "talking")"
        let grows = event.abilities
            .map { ability -> String in
                let label = SoftSkills.label(forKeyPath: ability.keyPath) ?? "Skill"
                let pic = SoftSkills.pictogram(forKeyPath: ability.keyPath) ?? ""
                return "\(pic) \(label) +\(ability.weight)"
            }
            .joined(separator: "\n")

        let chance = locked
            ? "🔒 Work or study in \(field) to take part. Then your chance goes up with years of work there, your \(voice) skill and your fame in the field."
            : "🎲 \(Int((odds * 100).rounded()))% chance they pick you. It goes up with years of work in \(field), your \(voice) skill and your fame there."
        return [
            event.blurb,
            chance,
            event.isOpenCall ? "📣 Anyone can apply." : nil,
            "If they pick you: you win the “\(event.presenterFameTitle)” title (🌟 fame) and meet lots of people in \(field), who can help you get hired and promoted there.",
            "If not: you still go and meet a few people.",
            "Grows either way:\n\(grows)",
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
