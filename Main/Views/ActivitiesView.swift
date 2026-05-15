import SwiftUI

struct ActivitiesView: View {
    @ObservedObject var player: Player
    @Binding var selectedActivities: Set<String>

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var stageActivities: [Activity] {
        activities.filter { $0.stages.contains(currentStage) }
    }

    var body: some View {
        VStack {

            HStack(spacing: 6) {
                Text("Activities this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedActivities.count)/\(GameConstants.maxSoftActivitiesPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedActivities.count >= GameConstants.maxSoftActivitiesPerYear
                            ? .red : .primary
                    )
            }
            Text("\(currentStage.displayName) — age \(player.age)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageActivities, id: \.label) { activity in
                        // Each ability rendered once, prefixed with a Nx multiplier
                        // when the boost is greater than 1 (e.g. "2x🧠 🪡 🎤").
                        let pictos: String = activity.abilities
                            .compactMap { ability -> String? in
                                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                                guard let pic = skillPictogramByKeyPath[kp] else { return nil }
                                return ability.weight > 1 ? "\(ability.weight)x\(pic)" : pic
                            }
                            .joined(separator: " ")

                        // One line per soft skill the activity boosts, with the
                        // exact +N gain so the player knows what they're getting.
                        let hintMessage: String = activity.abilities
                            .map { ability -> String in
                                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                                let pic = skillPictogramByKeyPath[kp] ?? ""
                                return "\(pic) \(label) (+\(ability.weight))"
                            }
                            .joined(separator: "\n")

                        let isLocked = player.lockedActivities.contains(activity.label)
                        let atLimit = selectedActivities.count >= GameConstants.maxSoftActivitiesPerYear
                        let isSelected = selectedActivities.contains(activity.label)

                        HStack(spacing: 8) {
                            Toggle(
                                "\(activity.label) \n \(pictos)",
                                isOn: Binding(
                                    get: { isSelected },
                                    set: { isOn in
                                        if isOn && !atLimit {
                                            player.selectActivity(activity, into: &selectedActivities)
                                        } else if !isOn {
                                            player.deselectActivity(activity, from: &selectedActivities)
                                        }
                                    }
                                )
                            )
                            .toggleStyle(.automatic)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .disabled(isLocked || (!isSelected && atLimit))
                            .opacity((isLocked || (!isSelected && atLimit)) ? 0.5 : 1.0)
                            .help(
                                isLocked
                                    ? "Locked after year end"
                                    : ((!isSelected && atLimit)
                                        ? "You can take up to \(GameConstants.maxSoftActivitiesPerYear) activities this year."
                                        : "")
                            )
                            .platformToggleStyle()

                            InfoHint(
                                title: activity.label,
                                message: "Builds:\n\n\(hintMessage)"
                            )
                        }
                        .padding(5)
                    }

                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    ActivitiesView(
        player: Player(),
        selectedActivities: .constant([])
    )
    .padding()
}

