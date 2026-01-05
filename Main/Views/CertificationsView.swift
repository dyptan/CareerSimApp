import SwiftUI

struct CertificationsView: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedCertifications: Set<Certification>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear = 1

    private var sortedCertifications: [Certification] {
        Certification.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    private func certificationThresholds(_ cert: Certification) -> [(
        WritableKeyPath<SoftSkills, Int>, Int
    )] {
        switch cert {
        case .aws, .azure, .google:
            return [(\.analyticalReasoningAndProblemSolving, 3)]
        case .scrum:
            return [(\.communicationAndNetworking, 2)]
        case .security:
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .cna:
            return [
                (\.communicationAndNetworking, 2),
                (\.patienceAndPerseverance, 2),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .dentalAssistant:
            return [
                (\.carefulnessAndAttentionToDetail, 3),
                (\.communicationAndNetworking, 2),
            ]
        case .medicalAssistant:
            return [
                (\.communicationAndNetworking, 2),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.patienceAndPerseverance, 2),
            ]
        case .pharmacyTech:
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.carefulnessAndAttentionToDetail, 3),
            ]
        case .cwi:
            return [
                (\.patienceAndPerseverance, 3),
                (\.carefulnessAndAttentionToDetail, 3),
            ]
        case .epa608:
            return [
                (\.carefulnessAndAttentionToDetail, 3),
                (\.analyticalReasoningAndProblemSolving, 2),
            ]
        case .nate:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.patienceAndPerseverance, 2),
            ]
        case .faaAMP:
            return [
                (\.tinkeringAndFingerPrecision, 3),
                (\.carefulnessAndAttentionToDetail, 3),
                (\.patienceAndPerseverance, 3),
            ]
        case .cfp:
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.communicationAndNetworking, 2),
            ]
        case .series65:
            return [
                (\.analyticalReasoningAndProblemSolving, 3)
            ]
        case .flightAttendantCert:
            return [
                (\.communicationAndNetworking, 2),
                (\.physicalStrengthAndEndurance, 3),
            ]
        }
    }

    private func requiredHardLevel(for cert: Certification) -> Int {
        switch cert {
        case .aws, .azure, .google:
            return 3 // e.g., Associate (1), Professional (2), Specialty (3)
        case .security:
            return 2
        case .scrum:
            return 2
        default:
            return 1
        }
    }

    var body: some View {
        ScrollView {
                ForEach(Array(sortedCertifications), id: \.rawValue) { (cert: Certification) in
                    let isLocked = player.lockedCertifications.contains(cert)
                    let isSelected = selectedCertifications.contains(cert)
                    let atLimit =
                        selectedActivities.count >= maxActivitiesPerYear

                    let requirement = cert.certificationRequirements(player)
                    let blockedReason: String? = {
                        switch requirement {
                        case .blocked(let reason): return reason
                        case .ok: return nil
                        }
                    }()
                

                    VStack(alignment: .leading, spacing: 6) {
                    Toggle(
                        "\(cert.friendlyName)",
                        isOn: Binding(
                            get: { isSelected },
                            set: { isOn in
                                guard !isLocked else { return }
                                if isOn {
                                    guard !atLimit else { return }
                                    switch cert.certificationRequirements(
                                        player
                                    ) {
                                    case .ok(let cost):
                                        selectedCertifications.insert(cert)
                                        selectedActivities.insert(
                                            "cert:\(cert.rawValue)"
                                        )
                                        player.savings -= cost
                                    case .blocked:
                                        break
                                    }
                                } else {
                                    if selectedCertifications.remove(cert)
                                        != nil
                                    {
                                        selectedActivities.remove(
                                            "cert:\(cert.rawValue)"
                                        )
                                        player.savings +=
                                            cert.costForCertification
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
                    .disabled(
                        isLocked
                            || (!isSelected
                                && (atLimit || blockedReason != nil))
                    )
                    .opacity(
                        (isLocked
                            || (!isSelected
                                && (atLimit || blockedReason != nil)))
                            ? 0.5 : 1.0
                    )
                    .help(
                        isLocked
                            ? "Locked after year end"
                            : ((!isSelected && atLimit)
                                ? "You can take up to \(maxActivitiesPerYear) activities this year."
                                : (blockedReason ?? ""))
                    )

                    let thresholds = certificationThresholds(cert)
                    if !thresholds.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(thresholds.enumerated()), id: \.offset) { pair in
                                let (kp, lvl) = pair.element
                                RequirementRow(
                                    label: SoftSkills.label(forKeyPath: kp) ?? "",
                                    emoji: SoftSkills.pictogram(forKeyPath: kp) ?? "🧩",
                                    style: .meter(current: player.softSkills[keyPath: kp], required: lvl)
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)
        }.padding()
    }

}

#Preview {
    struct Container: View {
        @State var selected: Set<Certification> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()
        var body: some View {
            NavigationView {
                CertificationsView(
                    selectedCertifications: $selected,
                    selectedActivities: $acts
                )
                .environmentObject(player)
            }
        }
    }
    return Container()
}

