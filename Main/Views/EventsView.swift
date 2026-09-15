import SwiftUI

/// Lets the player take the stage at professional events this year — summits,
/// conferences, expos, festivals, and pitch competitions. Each event is tied to
/// an industry: presenting there builds that field's **professional network**
/// (improving hiring odds on its postings and the chance of promotion within
/// it) and banks a fame award in the industry when the year advances.
/// Presenting unlocks once the player is a veteran of the field (see
/// `CareerEvent.canPresent`); its effects (soft skills, network) apply the
/// moment a row is toggled on and reverse if toggled off before the year
/// advances, while presenter fame is banked when the year advances.
struct EventsView: View {
    @ObservedObject var player: Player
    @Binding var selectedEvents: Set<String>
    /// Attending an event spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    var body: some View {
        VStack {
            // No slot counter — see `HobbiesView`; an event that can't be taken
            // this year dims in place.
            Text("Take the stage to grow your reputation — unlocks once you're a veteran of the field")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(EventCatalog.all) { event in
                        row(for: event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func row(for event: CareerEvent) -> some View {
        // Taking the stage stays locked until the veteran gate is cleared.
        let locked = !event.canPresent(with: player.experience)

        let roleLabel = event.presenterActionLabel

        let category = event.category
        let networkLabel = "\(JobCategory.icon(for: category)) \(category.rawValue) network +\(event.networkPoints)"

        let hintMessage: String = event.abilities
            .map { ability -> String in
                let label = SoftSkills.label(forKeyPath: ability.keyPath) ?? "Skill"
                let pic = SoftSkills.pictogram(forKeyPath: ability.keyPath) ?? ""
                return "\(pic) \(label) (+\(ability.weight))"
            }
            .joined(separator: "\n")

        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                // The role verb rides inline on the name row.
                HStack(spacing: 8) {
                    Text("\(event.icon)  \(event.name)")
                        .font(.headline)
                    Spacer(minLength: 8)
                    Text("🎤 \(roleLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if locked {
                    Text("🔒 \(roleLabel) with \(GameConstants.presenterExperienceYears) yrs in \(category.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("🎤 Earns reputation in \(category.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(locked ? 0.5 : 1.0)

            TakeButton {
                player.attendEvent(event, into: &selectedEvents)
                onCommit()
            }
            .disabled(locked)
            .opacity(locked ? 0.5 : 1.0)
            .help(
                locked
                    ? "Spend \(GameConstants.presenterExperienceYears) years in \(category.rawValue) to \(roleLabel.lowercased()) here."
                    : ""
            )

            InfoHint(
                title: "🎤 \(event.name) — \(roleLabel)",
                message: "\(event.blurb)\n\n🤝 \(networkLabel)\n\nBuilds soft skills:\n\n\(hintMessage)\n\nTaking the stage builds your network in \(category.rawValue) and banks a fame award there — raising your hiring odds and your chance of promotion."
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
