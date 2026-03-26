import SwiftUI

struct LicensesView: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedLicenses: Set<License>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear = 1

    private var sortedLicenses: [License] {
        License.allCases.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView {
            ForEach(sortedLicenses, id: \.self) { lic in
                let isLocked = player.lockedLicenses.contains(lic)
                let isSelected = selectedLicenses.contains(lic)
                let atLimit = selectedActivities.count >= maxActivitiesPerYear

                let requirement = lic.licenseRequirements(player)
                let blockedReason: String? = {
                    if case .blocked(let reason) = requirement { return reason }
                    return nil
                }()

                VStack(alignment: .leading, spacing: 6) {
                    Toggle(lic.friendlyName, isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                guard !atLimit else { return }
                                if case .ok(let cost) = lic.licenseRequirements(player) {
                                    selectedLicenses.insert(lic)
                                    selectedActivities.insert("lic:\(lic.rawValue)")
                                    player.savings -= cost
                                }
                            } else if selectedLicenses.remove(lic) != nil {
                                selectedActivities.remove("lic:\(lic.rawValue)")
                                player.savings += lic.costForLicense
                            }
                        }
                    ))
                    #if os(macOS)
                    .toggleStyle(.checkbox)
                    #endif
                    #if os(iOS)
                    .toggleStyle(.switch)
                    #endif
                    .disabled(isLocked || (!isSelected && (atLimit || blockedReason != nil)))
                    .opacity((isLocked || (!isSelected && (atLimit || blockedReason != nil))) ? 0.5 : 1.0)
                    .help(
                        isLocked ? "Locked after year end" :
                        (!isSelected && atLimit) ? "You can take up to \(maxActivitiesPerYear) activities this year." :
                        (blockedReason ?? "")
                    )

                    let thresholds = lic.softSkillThresholds
                    if !thresholds.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(thresholds.enumerated()), id: \.offset) { _, pair in
                                RequirementRow(
                                    label: SoftSkills.label(forKeyPath: pair.0) ?? "",
                                    emoji: SoftSkills.pictogram(forKeyPath: pair.0) ?? "",
                                    style: .meter(current: player.softSkills[keyPath: pair.0], required: pair.1)
                                )
                            }
                        }
                        .padding(4)
                    }
                }
                .padding(8)
            }
        }
        .padding()
    }
}

#Preview {
    struct Container: View {
        @State var selected: Set<License> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()
        var body: some View {
            NavigationView {
                LicensesView(selectedLicenses: $selected, selectedActivities: $acts)
                    .environmentObject(player)
            }
        }
    }
    return Container()
}
