import SwiftUI

/// Lets the player attend professional events this year — summits, conferences,
/// expos, and networking mixers. Events are free but build a per-industry
/// professional network that improves hiring odds on that field's postings and
/// the chance of promotion within it. Industry events list two distinct rows —
/// **attend** (participant) and **present** (unlocked once the player is a
/// veteran of the field); presenting banks extra network plus a fame award, and
/// the two are mutually exclusive (you attend an event in one capacity). Effects
/// (soft skills, network) apply the moment a row is toggled on and reverse if
/// toggled off before the year advances; presenter fame is banked when the year
/// advances.
struct EventsView: View {
    @ObservedObject var player: Player
    @Binding var selectedEvents: [String: EventRole]

    /// One selectable row: an event attended in a specific capacity. Presentable
    /// events contribute both a participant and a presenter row; everything else
    /// contributes a single participant row.
    private struct EventOption: Identifiable {
        let event: CareerEvent
        let role: EventRole
        var id: String { "\(event.id)#\(role.rawValue)" }
    }

    private var eventOptions: [EventOption] {
        EventCatalog.all.flatMap { event -> [EventOption] in
            var options = [EventOption(event: event, role: .participant)]
            if event.supportsPresenter {
                options.append(EventOption(event: event, role: .presenter))
            }
            return options
        }
    }

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
                    ForEach(eventOptions) { option in
                        row(for: option)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func row(for option: EventOption) -> some View {
        let event = option.event
        let rowRole = option.role
        let isPresenterRow = rowRole == .presenter

        let currentRole = selectedEvents[event.id]
        let isSelected = currentRole == rowRole
        // The same event is already claimed in the other capacity — toggling this
        // row on switches to it rather than consuming a fresh event slot.
        let selectedElsewhere = currentRole != nil && currentRole != rowRole
        let atLimit = selectedEvents.count >= GameConstants.maxEventsPerYear

        // Industry events open only once you have ≥1 year in that field.
        let meetsExp = event.meetsExperienceRequirement(for: player.experience)
        // Presenter rows stay locked until the full veteran gate is cleared.
        let presenterLocked = isPresenterRow && !event.canPresent(with: player.experience)
        // No free slot, and this isn't a switch of an already-attended event.
        let noSlot = !isSelected && !selectedElsewhere && atLimit
        let isDisabled = !meetsExp || presenterLocked || noSlot

        let roleIcon = isPresenterRow ? "🎤" : "🙋"
        let roleLabel = isPresenterRow ? event.presenterActionLabel : "Attend"

        // Network points reflect this row's role.
        let netPoints = event.networkPoints(for: rowRole)
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
                            if selectedElsewhere {
                                // Switch capacity on the same event — reapply so
                                // the network delta between roles lands cleanly.
                                player.dropEvent(event, from: &selectedEvents)
                                player.attendEvent(event, role: rowRole, into: &selectedEvents)
                            } else {
                                guard !atLimit else { return }
                                player.attendEvent(event, role: rowRole, into: &selectedEvents)
                            }
                        } else {
                            player.dropEvent(event, from: &selectedEvents)
                        }
                    }
                )
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(event.icon)  \(event.name)")
                        .font(.headline)
                    Text("\(roleIcon) \(roleLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isPresenterRow, let category = event.category {
                        if presenterLocked {
                            Text("🔒 \(event.presenterActionLabel) with \(GameConstants.presenterExperienceYears) yrs in \(category.rawValue)")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        } else {
                            Text("🎤 Earns reputation in \(category.rawValue)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
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
                    : (presenterLocked
                        ? "Spend \(GameConstants.presenterExperienceYears) years in \(event.category?.rawValue ?? "this field") to \(event.presenterActionLabel.lowercased()) here."
                        : (noSlot
                            ? "You can attend up to \(GameConstants.maxEventsPerYear) events this year."
                            : ""))
            )

            InfoHint(
                title: "\(roleIcon) \(event.name) — \(roleLabel)",
                message: "\(event.blurb)\n\n🤝 \(networkLabel)\n\nBuilds soft skills:\n\n\(hintMessage)\n\nA strong network in a field raises your hiring odds there and your chance of promotion." + (isPresenterRow ? "\n\nTaking the stage banks extra network plus a fame award in \(event.category?.rawValue ?? "the field")." : "")
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
