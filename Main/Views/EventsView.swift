import SwiftUI

/// Lets the player attend professional events this year — summits, conferences,
/// expos, and networking mixers. Unlike hobbies, events cost money and build a
/// per-industry professional network that improves hiring odds on that field's
/// postings and the chance of promotion within it. Effects (cost, soft skills,
/// network) apply the moment an event is toggled on, and reverse if toggled off
/// before the year advances.
struct EventsView: View {
    @ObservedObject var player: Player
    @Binding var selectedEvents: Set<String>

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text("Events this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedEvents.count)/\(GameConstants.maxEventsPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedEvents.count >= GameConstants.maxEventsPerYear
                            ? .red : .primary
                    )
            }
            Text("Grow your professional network · savings: \(player.savings.formatted(.number)) $")
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
        let isDisabled = !isSelected && atLimit
        // A flag, not a gate — an unaffordable ticket is still bought on credit.
        let canAfford = isSelected || player.savings >= event.cost

        // Where this event builds your network: a specific field, or everywhere.
        let networkLabel: String = {
            if let category = event.category {
                return "\(JobCategory.icon(for: category)) \(category.rawValue) network +\(event.networkWeight)"
            }
            return "🌐 All-industry network +\(event.networkWeight)"
        }()

        let pictos: String = event.abilities
            .compactMap { ability -> String? in
                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                guard let pic = skillPictogramByKeyPath[kp] else { return nil }
                return ability.weight > 1 ? "\(ability.weight)x\(pic)" : pic
            }
            .joined(separator: " ")

        let hintMessage: String = event.abilities
            .map { ability -> String in
                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp] ?? ""
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
                    Text("\(event.icon)  \(event.name)")
                        .font(.headline)
                    Text(event.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !pictos.isEmpty {
                        Text("Builds: \(pictos)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 10) {
                        Text(canAfford
                             ? "💵 \(event.cost.formatted(.number)) $"
                             : "💵 \(event.cost.formatted(.number)) $ (on credit)")
                            .foregroundStyle(canAfford ? Color.secondary : Color.orange)
                        Text("🤝 \(networkLabel)")
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .platformToggleStyle()
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            .help(
                atLimit && !isSelected
                    ? "You can attend up to \(GameConstants.maxEventsPerYear) events this year."
                    : ""
            )

            InfoHint(
                title: "\(event.icon) \(event.name)",
                message: "\(networkLabel)\n\nBuilds soft skills:\n\n\(hintMessage)\n\nA strong network in a field raises your hiring odds there and your chance of promotion."
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
