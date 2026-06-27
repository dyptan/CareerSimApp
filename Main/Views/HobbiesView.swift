import SwiftUI

struct HobbiesView: View {
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

    private var stageHobbies: [Hobby] {
        hobbies.filter { $0.stages.contains(currentStage) }
    }

    var body: some View {
        VStack {

            HStack(spacing: 6) {
                Text("Hobbies this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedActivities.count)/\(GameConstants.maxHobbiesPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedActivities.count >= GameConstants.maxHobbiesPerYear
                            ? .red : .primary
                    )
            }
            Text("\(currentStage.displayName) — age \(player.age)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageHobbies, id: \.label) { hobby in
                        // Each ability rendered once, prefixed with a Nx multiplier
                        // when the boost is greater than 1 (e.g. "2x🧠 🪡 🎤").
                        let pictos: String = hobby.abilities
                            .compactMap { ability -> String? in
                                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                                guard let pic = skillPictogramByKeyPath[kp] else { return nil }
                                return ability.weight > 1 ? "\(ability.weight)x\(pic)" : pic
                            }
                            .joined(separator: " ")

                        // One line per soft skill the hobby boosts, with the
                        // exact +N gain so the player knows what they're getting.
                        let hintMessage: String = hobby.abilities
                            .map { ability -> String in
                                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                                let pic = skillPictogramByKeyPath[kp] ?? ""
                                return "\(pic) \(label) (+\(ability.weight))"
                            }
                            .joined(separator: "\n")

                        let isLocked = player.lockedHobbies.contains(hobby.label)
                        let atLimit = selectedActivities.count >= GameConstants.maxHobbiesPerYear
                        let isSelected = selectedActivities.contains(hobby.label)

                        HStack(spacing: 8) {
                            Toggle(
                                "\(hobby.label) \n \(pictos)",
                                isOn: Binding(
                                    get: { isSelected },
                                    set: { isOn in
                                        if isOn && !atLimit {
                                            player.selectHobby(hobby, into: &selectedActivities)
                                        } else if !isOn {
                                            player.deselectHobby(hobby, from: &selectedActivities)
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
                                        ? "You can take up to \(GameConstants.maxHobbiesPerYear) hobbies this year."
                                        : "")
                            )
                            .platformToggleStyle()

                            InfoHint(
                                title: hobby.label,
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
    HobbiesView(
        player: Player(),
        selectedActivities: .constant([])
    )
    .padding()
}

