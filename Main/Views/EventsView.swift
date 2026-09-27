import SwiftUI

/// Professional events this year — summits, conferences, expos, festivals and
/// pitch competitions. Each is tied to an industry. **Attend** to bank its
/// network there (open to anyone working in or studying toward the field, or
/// to anyone for an open call), or **apply to take the stage** — acceptance
/// odds from experience, communication and fame (see `Player.presentOdds`);
/// accepted, it banks more network plus a fame award, and a rejection still
/// counts as attending. Either way the year is spent.
struct EventsView: View {
    @ObservedObject var player: Player
    @Binding var selectedEvents: Set<String>
    /// Taking part spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    /// The sheet's title ⓘ.
    static let hint = """
    Events help you meet people and get known in a field — both make it easier to get hired and promoted there. Going to one uses up your year.

    🎟️ Go and listen: open to anyone who works or studies in that field.
    🎤 Give a talk: apply to speak — your chance goes up with years in the field, being good at talking, and fame there. If they say yes, you meet more people and win a title. If not, you still get to attend.
    📣 Open calls (auditions, festivals, pitch and talk contests) are open to everyone.
    """

    /// Events the player can join first, then the rest, each group by name.
    private var events: [CareerEvent] {
        EventCatalog.all.sorted {
            let a = player.canJoinEvent($0), b = player.canJoinEvent($1)
            return a == b ? $0.name < $1.name : a
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
        let category = event.category
        let field = "\(JobCategory.icon(for: category)) \(category.rawValue)"

        let skills: String = event.abilities
            .map { ability -> String in
                let label = SoftSkills.label(forKeyPath: ability.keyPath) ?? "Skill"
                let pic = SoftSkills.pictogram(forKeyPath: ability.keyPath) ?? ""
                return "\(pic) \(label) +\(ability.weight)"
            }
            .joined(separator: ", ")

        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(event.icon)  \(event.name)")
                    .font(.headline)
                if locked {
                    Text("🔒 Work or study in \(category.rawValue) to take part")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("🎤 \(Int((odds * 100).rounded()))% to \(event.presenterActionLabel.lowercased())\(event.isOpenCall ? " · 📣 open call" : "")")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.forOdds(odds))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(locked ? 0.5 : 1.0)

            VStack(spacing: 6) {
                TakeButton(label: event.presenterActionLabel) {
                    player.applyToPresent(event, into: &selectedEvents)
                    onCommit()
                }
                TakeButton(label: "Attend") {
                    player.attendEvent(event)
                    onCommit()
                }
            }
            .disabled(locked)
            .opacity(locked ? 0.5 : 1.0)

            InfoHint(
                title: "\(event.icon) \(event.name)",
                message: """
                \(event.blurb)

                🎟️ Attend: \(field) network +\(event.networkWeight).
                🎤 \(event.presenterActionLabel): \(Int((odds * 100).rounded()))% to be accepted — network +\(event.networkPoints) and the “\(event.presenterFameTitle)” fame award. Turned down, you attended.

                Builds: \(skills).
                """
            )
        }
        .padding(5)
    }
}

#Preview {
    EventsView(
        player: Player(),
        selectedEvents: .constant([])
    )
    .padding()
}
