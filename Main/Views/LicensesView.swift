import SwiftUI

struct LicensesView: View {
    @ObservedObject var player: Player

    @Binding var selectedLicenses: Set<License>
    @Binding var selectedActivities: Set<String>

    private var sortedLicenses: [License] {
        License.allCases.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView {
            ForEach(sortedLicenses, id: \.self) { lic in
                let isLocked = player.lockedLicenses.contains(lic)
                let isSelected = selectedLicenses.contains(lic)
                let atLimit = selectedActivities.count >= GameConstants.trainingActivitySlotCost

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
                                player.purchaseLicense(lic, into: &selectedLicenses, activities: &selectedActivities)
                            } else {
                                player.refundLicense(lic, from: &selectedLicenses, activities: &selectedActivities)
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
                        (!isSelected && atLimit) ? "You can take up to \(GameConstants.trainingActivitySlotCost) activities this year." :
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
                LicensesView(player: player, selectedLicenses: $selected, selectedActivities: $acts)
            }
        }
    }
    return Container()
}
