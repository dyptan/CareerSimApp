import SwiftUI

extension View {
    /// Toggle style appropriate for the current platform (.checkbox on macOS, .switch on iOS).
    @ViewBuilder
    func platformToggleStyle() -> some View {
        #if os(macOS)
        self.toggleStyle(.checkbox)
        #elseif os(iOS)
        self.toggleStyle(.switch)
        #else
        self
        #endif
    }
}

/// Disabled/help-text state for a training-toggle row.
/// Shared by CertificationsView, LicensesView, and any other "buy a thing this year" toggle.
func trainingRowState(
    isLocked: Bool,
    isSelected: Bool,
    atLimit: Bool,
    blockedReason: String?
) -> (disabled: Bool, helpText: String) {
    let disabled = isLocked || (!isSelected && (atLimit || blockedReason != nil))
    let helpText: String
    if isLocked {
        helpText = "Locked after year end"
    } else if !isSelected && atLimit {
        helpText = "You can take up to \(GameConstants.trainingActivitySlotCost) activities this year."
    } else {
        helpText = blockedReason ?? ""
    }
    return (disabled, helpText)
}

struct CertificationsView: View {
    @ObservedObject var player: Player

    @Binding var selectedCertifications: Set<Certification>
    @Binding var selectedActivities: Set<String>

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var sortedCertifications: [Certification] {
        Certification.allCases
            .filter { $0.stages.contains(currentStage) }
            .sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if sortedCertifications.isEmpty {
                    Text("Career certifications unlock after high school.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(sortedCertifications, id: \.rawValue) { cert in
                        row(for: cert)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    @ViewBuilder
    private func row(for cert: Certification) -> some View {
        let isLocked = player.lockedCertifications.contains(cert)
        let isSelected = selectedCertifications.contains(cert)
        let atLimit = selectedActivities.count >= GameConstants.trainingActivitySlotCost

        let blockedReason: String? = {
            if case .blocked(let reason) = cert.certificationRequirements(player) { return reason }
            return nil
        }()
        let state = trainingRowState(isLocked: isLocked, isSelected: isSelected, atLimit: atLimit, blockedReason: blockedReason)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                // InfoHint sits outside the Toggle so it stays tappable
                // even when the toggle is disabled by missing requirements.
                InfoHint(title: "\(cert.pictogram) \(cert.friendlyName)", message: cert.description)
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
                .platformToggleStyle()
                .disabled(state.disabled)
                .opacity(state.disabled ? 0.5 : 1.0)
                .help(state.helpText)
            }

            Text("Costs $\(cert.costForCertification.formatted(.number))")
                .font(.caption)
                .foregroundStyle(player.savings >= cert.costForCertification ? Color.secondary : Color.red)
                .padding(.leading, 8)

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
