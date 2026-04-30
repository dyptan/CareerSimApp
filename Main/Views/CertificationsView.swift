import SwiftUI

struct CertificationsView: View {
    @ObservedObject var player: Player

    @Binding var selectedCertifications: Set<Certification>
    @Binding var selectedActivities: Set<String>

    private var sortedCertifications: [Certification] {
        Certification.allCases.sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView {
            ForEach(sortedCertifications, id: \.rawValue) { cert in
                let isLocked = player.lockedCertifications.contains(cert)
                let isSelected = selectedCertifications.contains(cert)
                let atLimit = selectedActivities.count >= GameConstants.trainingActivitySlotCost

                let requirement = cert.certificationRequirements(player)
                let blockedReason: String? = {
                    if case .blocked(let reason) = requirement { return reason }
                    return nil
                }()

                VStack(alignment: .leading, spacing: 6) {
                    Toggle(cert.friendlyName, isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                guard !atLimit else { return }
                                player.purchaseCertification(cert, into: &selectedCertifications, activities: &selectedActivities)
                            } else {
                                player.refundCertification(cert, from: &selectedCertifications, activities: &selectedActivities)
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

                    let thresholds = cert.softSkillThresholds
                    if !thresholds.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(thresholds.enumerated()), id: \.offset) { _, pair in
                                RequirementRow(
                                    label: SoftSkills.label(forKeyPath: pair.0) ?? "",
                                    emoji: SoftSkills.pictogram(forKeyPath: pair.0) ?? "🧩",
                                    style: .meter(current: player.softSkills[keyPath: pair.0], required: pair.1)
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    struct Container: View {
        @State var selected: Set<Certification> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()
        var body: some View {
            NavigationView {
                CertificationsView(player: player, selectedCertifications: $selected, selectedActivities: $acts)
            }
        }
    }
    return Container()
}
