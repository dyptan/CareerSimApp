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

    /// Deterministic, so it's built once rather than per render.
    private static let skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] =
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )

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
        let isSelected = selectedEvents.contains(event.id)
        let atLimit = selectedEvents.count >= GameConstants.maxEventsPerYear

        // Taking the stage stays locked until the veteran gate is cleared.
        let locked = !event.canPresent(with: player.experience)
        // No free slot left for a fresh selection.
        let noSlot = !isSelected && atLimit
        let isDisabled = locked || noSlot

        let roleLabel = event.presenterActionLabel

        let category = event.category
        let networkLabel = "\(JobCategory.icon(for: category)) \(category.rawValue) network +\(event.networkPoints)"

        let hintMessage: String = event.abilities
            .map { ability -> String in
                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = Self.skillPictogramByKeyPath[kp] ?? ""
                return "\(pic) \(label) (+\(ability.weight))"
            }
            .joined(separator: "\n")

        HStack(alignment: .top, spacing: 8) {
            Toggle(
                isOn: Binding(
                    get: { isSelected },
                    set: { isOn in
                        if isOn {
                            guard !atLimit else { return }
                            player.attendEvent(event, into: &selectedEvents)
                        } else {
                            player.dropEvent(event, from: &selectedEvents)
                        }
                    }
                )
            ) {
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
            }
            .platformToggleStyle()
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            .help(
                locked
                    ? "Spend \(GameConstants.presenterExperienceYears) years in \(category.rawValue) to \(roleLabel.lowercased()) here."
                    : (noSlot
                        ? "You can take the stage at up to \(GameConstants.maxEventsPerYear) events this year."
                        : "")
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
