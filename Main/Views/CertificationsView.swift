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
        // Owned if already earned (locked / in hard skills) or passed this year.
        let isOwned = player.lockedCertifications.contains(cert)
            || player.hardSkills.certifications.contains(cert)
            || selectedCertifications.contains(cert)
        let attemptedThisYear = player.attemptedCertificationIds.contains(cert.rawValue)
        let atLimit = selectedActivities.count >= GameConstants.trainingActivitySlotCost
        let cost = cert.costForCertification
        let canAfford = player.savings >= cost

        let blockedReason: String? = {
            if case .blocked(let reason) = cert.certificationRequirements(player) { return reason }
            return nil
        }()
        let eqfMet = blockedReason == nil
        let passChance = cert.passProbability(for: player)
        // Can sit the exam: eligible, not already owned/attempted, slot free.
        // Affordability is NOT a gate — an unaffordable fee just goes into debt.
        let canAttempt = eqfMet && !isOwned && !attemptedThisYear && !atLimit

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                InfoHint(title: "\(cert.pictogram) \(cert.friendlyName)", message: cert.description)
                Text(cert.friendlyName)
                    .font(.body)
                Spacer()
                if isOwned {
                    Text("✓ Certified")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
            }

            Text(canAfford
                 ? "Exam fee $\(cost.formatted(.number))"
                 : "Exam fee $\(cost.formatted(.number)) — paid on credit")
                .font(.caption)
                .foregroundStyle(canAfford ? Color.secondary : Color.orange)
                .padding(.leading, 8)

            // Pass odds (realistic mode only — simplified is a guaranteed pass).
            if !player.isSimplified && !isOwned {
                HStack(spacing: 6) {
                    Text("Pass chance:")
                    Spacer()
                    Text(eqfMet ? "\(Int((passChance * 100).rounded())) %" : "—")
                        .font(.subheadline.bold())
                        .foregroundStyle(passChance >= 0.6 ? .green : passChance >= 0.3 ? .orange : .red)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            }

            if !isOwned {
                Button {
                    let passed = player.attemptCertification(cert, into: &selectedCertifications, activities: &selectedActivities)
                    // Passing against long odds is worth a celebration.
                    if passed, passChance <= GameConstants.luckyAdmissionThreshold {
                        player.celebrationTrigger += 1
                    }
                } label: {
                    Text(attemptButtonLabel(attempted: attemptedThisYear, atLimit: atLimit, blockedReason: blockedReason))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAttempt)
                .opacity(canAttempt ? 1.0 : 0.5)
                .padding(.top, 2)

                if attemptedThisYear {
                    Text("❌ Didn't pass this year — build the skills below and retry next year.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.leading, 8)
                }
            }

            let thresholds = cert.softSkillThresholds
            if !thresholds.isEmpty && !isOwned {
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

    private func attemptButtonLabel(attempted: Bool, atLimit: Bool, blockedReason: String?) -> String {
        if let reason = blockedReason { return reason }
        if attempted { return "Attempted this year" }
        if atLimit { return "Only \(GameConstants.trainingActivitySlotCost) activity per year" }
        return player.isSimplified ? "Take Certification" : "Sit Exam"
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
