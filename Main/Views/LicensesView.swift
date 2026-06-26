import SwiftUI

struct LicensesView: View {
    @ObservedObject var player: Player

    @Binding var selectedLicenses: Set<License>
    @Binding var selectedActivities: Set<String>

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var sortedLicenses: [License] {
        License.allCases
            .filter { $0.stages.contains(currentStage) }
            .sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if sortedLicenses.isEmpty {
                    Text("Licences unlock once you're a teen — the earliest is a driver's licence at 16.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(sortedLicenses, id: \.self) { lic in
                        row(for: lic).padding(8)
                    }
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func row(for lic: License) -> some View {
        let isLocked = player.lockedLicenses.contains(lic)
        let isSelected = selectedLicenses.contains(lic)
        let atLimit = selectedActivities.count >= GameConstants.trainingActivitySlotCost

        let blockedReason: String? = {
            if case .blocked(let reason) = lic.licenseRequirements(player) { return reason }
            return nil
        }()
        let state = trainingRowState(isLocked: isLocked, isSelected: isSelected, atLimit: atLimit, blockedReason: blockedReason)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                // InfoHint sits outside the Toggle so it stays tappable
                // even when the toggle is disabled by missing requirements.
                InfoHint(title: "\(lic.pictogram) \(lic.friendlyName)", message: lic.description)
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
                .platformToggleStyle()
                .disabled(state.disabled)
                .opacity(state.disabled ? 0.5 : 1.0)
                .help(state.helpText)
            }

            let affordable = player.savings >= lic.costForLicense
            Text(affordable
                 ? "Costs $\(lic.costForLicense.formatted(.number))"
                 : "Costs $\(lic.costForLicense.formatted(.number)) — paid on credit")
                .font(.caption)
                .foregroundStyle(affordable ? Color.secondary : Color.orange)
                .padding(.leading, 8)

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
