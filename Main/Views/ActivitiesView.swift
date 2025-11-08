import SwiftUI

struct ActivitiesView: View {
    @ObservedObject var player: Player
    @Binding var selectedActivities: Set<String>
    @Binding var selectedLanguages: Set<Language>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedPortfolio: Set<PortfolioItem>

    // Local mapping from soft-skill key paths to pictograms
    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    var body: some View {
        ScrollView {
            // Activities
            VStack(spacing: 10) {
                ForEach(schoolActivities, id: \.label) { activity in
                    let pictos = activity.abilityKeyPaths.compactMap { kp in
                        skillPictogramByKeyPath[kp as PartialKeyPath<SoftSkills>]
                    }.joined()

                    let atLimit = selectedActivities.count >= 3
                    let isSelected = selectedActivities.contains(activity.label)

                    Toggle(
                        "\(activity.label) \(pictos)",
                        isOn: Binding(
                            get: { isSelected },
                            set: { isOn in
                                if isOn && !atLimit {
                                    selectedActivities.insert(activity.label)
                                    for keyPath in activity.abilityKeyPaths {
                                        player.softSkills[keyPath: keyPath] += 1
                                    }
                                } else {
                                    if selectedActivities.remove(activity.label) != nil {
                                        for keyPath in activity.abilityKeyPaths {
                                            player.softSkills[keyPath: keyPath] -= 1
                                        }
                                    }
                                }
                            }
                        )
                    )
                    .toggleStyle(.automatic)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(!isSelected && atLimit)
                    .opacity(!isSelected && atLimit ? 0.5 : 1.0)
                    .help(atLimit && !isSelected ? "You can take up to 3 activities this year." : "")
                }
            }

            // Hard skills
            VStack(spacing: 10) {
                Text("Languages:")
                ForEach(
                    Array(
                        HardSkills().languages.sorted { $0.rawValue > $1.rawValue }
                    )
                ) { skill in
                    let t = Toggle(
                        skill.rawValue,
                        isOn: Binding(
                            get: { selectedLanguages.contains(skill) },
                            set: { isSelected in
                                if isSelected {
                                    selectedLanguages.insert(skill)
                                } else {
                                    selectedLanguages.remove(skill)
                                }
                            }
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    #if os(macOS)
                    t.toggleStyle(.checkbox)
                    #endif
                    #if os(iOS)
                    t.toggleStyle(.switch)
                    #endif
                }

                Text("Software:")
                ForEach(
                    Array(
                        HardSkills().software.sorted { $0.rawValue > $1.rawValue }
                    )
                ) { skill in
                    let t = Toggle(
                        skill.rawValue,
                        isOn: Binding(
                            get: { selectedSoftware.contains(skill) },
                            set: { isSelected in
                                if isSelected {
                                    selectedSoftware.insert(skill)
                                } else {
                                    selectedSoftware.remove(skill)
                                }
                            }
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    #if os(macOS)
                    t.toggleStyle(.checkbox)
                    #endif
                    #if os(iOS)
                    t.toggleStyle(.switch)
                    #endif
                }

                Text("Portfolio Items:")
                ForEach(
                    Array(
                        HardSkills().portfolioItems.sorted { $0.rawValue > $1.rawValue }
                    )
                ) { skill in
                    let t = Toggle(
                        skill.rawValue,
                        isOn: Binding(
                            get: { selectedPortfolio.contains(skill) },
                            set: { isSelected in
                                if isSelected {
                                    selectedPortfolio.insert(skill)
                                } else {
                                    selectedPortfolio.remove(skill)
                                }
                            }
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    #if os(macOS)
                    t.toggleStyle(.checkbox)
                    #endif
                    #if os(iOS)
                    t.toggleStyle(.switch)
                    #endif
                }
            }
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    ActivitiesView(
        player: Player(),
        selectedActivities: .constant([]),
        selectedLanguages: .constant([]),
        selectedSoftware: .constant([]),
        selectedPortfolio: .constant([])
    )
    .padding()
}
