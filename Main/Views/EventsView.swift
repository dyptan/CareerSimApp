import SwiftUI

/// Lets the player attend professional events this year — summits, conferences,
/// expos, and networking mixers. Events are free but build a per-industry
/// professional network that improves hiring odds on that field's postings and
/// the chance of promotion within it. Industry events can be attended as a
/// **presenter** once the player is a veteran of the field — presenting banks
/// extra network plus a fame award. Effects (soft skills, network) apply
/// the moment an event is toggled on and reverse if toggled off before the year
/// advances; presenter fame is banked when the year advances.
struct EventsView: View {
    @ObservedObject var player: Player
    @Binding var selectedEvents: [String: EventRole]

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
            Text("Grow your professional network — present once you're a veteran of the field")
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
        let role = selectedEvents[event.id]
        let isSelected = role != nil
        let atLimit = selectedEvents.count >= GameConstants.maxEventsPerYear
        // Industry events open only once you have ≥1 year in that field.
        let meetsExp = event.meetsExperienceRequirement(for: player.experience)
        let isDisabled = (!isSelected && atLimit) || !meetsExp
        // Presenting needs the full veteran gate on top of the attend gate.
        let canPresent = event.canPresent(with: player.experience)

        // Network points reflect the chosen role (participant baseline until on).
        let netPoints = event.networkPoints(for: role ?? .participant)
        let networkLabel: String = {
            if let category = event.category {
                return "\(JobCategory.icon(for: category)) \(category.rawValue) network +\(netPoints)"
            }
            return "🌐 All-industry network +\(netPoints)"
        }()

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

                    // Role picker for industry events once selected: participants
                    // always, presenters once the veteran gate is cleared.
                    if isSelected, event.supportsPresenter {
                        if canPresent {
                            Picker(
                                "Role",
                                selection: Binding(
                                    get: { role ?? .participant },
                                    set: { newRole in
                                        // Re-attend so the network delta between
                                        // roles is applied cleanly.
                                        player.dropEvent(event, from: &selectedEvents)
                                        player.attendEvent(event, role: newRole, into: &selectedEvents)
                                    }
                                )
                            ) {
                                Text("🙋 Participant").tag(EventRole.participant)
                                Text("🎤 Presenter").tag(EventRole.presenter)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            if role == .presenter, let category = event.category {
                                Text("🎤 Earns reputation in \(category.rawValue)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("🔒 Present with \(GameConstants.presenterExperienceYears) yrs in \(event.category?.rawValue ?? "this field")")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }

                    if !meetsExp, let category = event.category {
                        Text("🔒 Requires 1 yr in \(category.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .platformToggleStyle()
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            .help(
                !meetsExp
                    ? "Work at least 1 year in \(event.category?.rawValue ?? "this field") to attend."
                    : (atLimit && !isSelected
                        ? "You can attend up to \(GameConstants.maxEventsPerYear) events this year."
                        : "")
            )

            InfoHint(
                title: "\(event.icon) \(event.name)",
                message: "\(event.blurb)\n\n🤝 \(networkLabel)\n\nBuilds soft skills:\n\n\(hintMessage)\n\nA strong network in a field raises your hiring odds there and your chance of promotion. Present at an industry event (after \(GameConstants.presenterExperienceYears) years in the field) for extra network and fame."
            )
        }
        .padding(5)
    }
}

#Preview {
    EventsView(
        player: Player(),
        selectedEvents: .constant([:])
    )
    .padding()
}
