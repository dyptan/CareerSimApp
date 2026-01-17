import SwiftUI

struct ActivitiesView: View {
    @ObservedObject var player: Player
    @Binding var selectedActivities: Set<String>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedPortfolio: Set<Project>
    var maxActivitiesPerYear = 3

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
                Text("Activities this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedActivities.count >= maxActivitiesPerYear
                            ? .red : .primary
                    )
            }
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(activities, id: \.label) { activity in
                        let pictos: String = {
                            activity.abilities.flatMap { ability -> [String] in
                                let kp = ability.keyPath as PartialKeyPath<SoftSkills>
                                guard let pic = skillPictogramByKeyPath[kp] else { return [] }
                                return Array(repeating: pic, count: max(ability.weight, 1))
                            }.joined()
                        }()

                        let isLocked = player.lockedActivities.contains(activity.label)
                        let atLimit = selectedActivities.count >= maxActivitiesPerYear
                        let isSelected = selectedActivities.contains(activity.label)

                        Toggle(
                            "\(activity.label) \(pictos)",
                            isOn: Binding(
                                get: { isSelected },
                                set: { isOn in
                                    if isOn && !atLimit {
                                        selectedActivities.insert(activity.label)
                                    } else {
                                        _ = selectedActivities.remove(activity.label)
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
                                    ? "You can take up to \(maxActivitiesPerYear) activities this year."
                                    : "")
                        )
                        #if os(macOS)
                            .toggleStyle(.checkbox)
                        #endif
                        #if os(iOS)
                            .toggleStyle(.switch)
                        #endif
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
        selectedActivities: .constant([]),
        selectedSoftware: .constant([]),
        selectedPortfolio: .constant([])
    )
    .padding()
}

