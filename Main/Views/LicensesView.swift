import SwiftUI

struct LicensesView: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedLicences: Set<License>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear = 1

    private var sortedLicenses: [License] {
        License.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    private func requirementRow(
        label: String,
        emoji: String,
        level: Int,
        playerLevel: Int
    ) -> some View {
        let required = max(level, 0)
        let meets = playerLevel >= required

        return HStack {
            Text(label)
            Spacer()
            HStack(spacing: 0) {
                ForEach(0..<required, id: \.self) { idx in
                    Text(emoji)
                        .opacity(idx < playerLevel ? 1.0 : 0.35)
                }
            }
            .font(.body)
        }
        .font(.body)
        .foregroundStyle(meets ? .primary : .secondary)
        .padding(.horizontal, 6)
    }

    private func licenseThresholds(_ lic: License) -> [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch lic {
        case .drivers:
            return [
                (\.spacialNavigationAndOrientation, 1),
                (\.coordinationAndBalance, 1),
                (\.physicalStrengthAndEndurance, 1),
            ]
        case .cdl:
            return [
                (\.spacialNavigationAndOrientation, 2),
                (\.coordinationAndBalance, 2),
                (\.physicalStrengthAndEndurance, 2),
                (\.patienceAndPerseverance, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .pilot:
            return [
                (\.spacialNavigationAndOrientation, 2),
                (\.coordinationAndBalance, 2),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .commercialPilot:
            return [
                (\.spacialNavigationAndOrientation, 3),
                (\.coordinationAndBalance, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.patienceAndPerseverance, 3),
                (\.analyticalReasoningAndProblemSolving, 3),
            ]
        case .nurse:
            return [
                (\.communicationAndNetworking, 2),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.physicalStrengthAndEndurance, 2),
            ]
        case .electrician:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.patienceAndPerseverance, 2),
            ]
        case .plumber:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 2),
                (\.patienceAndPerseverance, 2),
                (\.physicalStrengthAndEndurance, 2),
            ]
        case .realEstateAgent:
            return [
                (\.communicationAndNetworking, 3),
                (\.presentationAndStorytelling, 2),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .insuranceAgent:
            return [
                (\.communicationAndNetworking, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        }
    }

    var body: some View {
        ScrollView {

                ForEach(sortedLicenses, id: \.self) { lic in
                    let isLocked = player.lockedLicenses.contains(lic)
                    let isSelected = selectedLicences.contains(lic)
                    let atLimit = selectedActivities.count >= maxActivitiesPerYear

                    let requirement = lic.licenseRequirements(player)
                    let blockedReason: String? = {
                        switch requirement {
                        case .blocked(let reason): return reason
                        case .ok: return nil
                        }
                    }()
                    let priceText: String = {
                        switch requirement {
                        case .ok(let cost): return "$\(cost)"
                        case .blocked: return "$\(lic.costForLicense)"
                        }
                    }()

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(
                            "\(lic.friendlyName)",
                            isOn: Binding(
                                get: { isSelected },
                                set: { isOn in
                                    guard !isLocked else { return }
                                    if isOn {
                                        guard !atLimit else { return }
                                        switch lic.licenseRequirements(player) {
                                        case .ok(let cost):
                                            selectedLicences.insert(lic)
                                            selectedActivities.insert("lic:\(lic.rawValue)")
                                            player.savings -= cost
                                        case .blocked:
                                            break
                                        }
                                    } else {
                                        if selectedLicences.remove(lic) != nil {
                                            selectedActivities.remove("lic:\(lic.rawValue)")
                                            player.savings += lic.costForLicense
                                        }
                                    }
                                }
                            )
                        )
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                        #if os(iOS)
                        .toggleStyle(.switch)
                        #endif
                        .disabled(isLocked || (!isSelected && (atLimit || blockedReason != nil)))
                        .opacity((isLocked || (!isSelected && (atLimit || blockedReason != nil))) ? 0.5 : 1.0)
                        .help(isLocked
                              ? "Locked after year end"
                              : ((!isSelected && atLimit)
                                 ? "You can take up to \(maxActivitiesPerYear) activities this year."
                                 : (blockedReason ?? "")))

                        let thresholds = licenseThresholds(lic)
                        if !thresholds.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(0..<thresholds.count, id: \.self) { idx in
                                    let (kp, lvl) = thresholds[idx]
                                    requirementRow(
                                        label: SoftSkills.label(forKeyPath: kp) ?? "",
                                        emoji: SoftSkills.pictogram(forKeyPath: kp) ?? "",
                                        level: lvl,
                                        playerLevel: player.softSkills[keyPath: kp]
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        .padding(.horizontal)
        
    }
}

#Preview {
    struct Container: View {
        @State var selected: Set<License> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()
        var body: some View {
            NavigationView {
                LicensesView(
                    selectedLicences: $selected,
                    selectedActivities: $acts
                )
                .environmentObject(player)
            }
        }
    }
    return Container()
}

