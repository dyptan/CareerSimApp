import SwiftUI

struct SoftwareRow: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedActivities: Set<String>
        
    let maxActivitiesPerYear: Int
    let item: Software

    private var isSelected: Bool {
        selectedSoftware.contains(item)
    }

    private var isLocked: Bool {
        player.lockedSoftware.contains(item)
    }

    private var atLimit: Bool {
        selectedActivities.count >= maxActivitiesPerYear
    }

    private var requirement: TrainingRequirementResult {
        item.softwareRequirements(player)
    }
        
    private var prerequisitesFulfilled: Bool {
        let thresholds = softwareThresholds(item)
        for (kp, lvl) in thresholds {
            if player.softSkills[keyPath: kp] < lvl {
                return false
            }
        }
        return true
    }

    private var blockedReason: String? {
        switch requirement {
        case .blocked(let reason):
            return reason
        case .ok:
            return nil
        }
    }

    private func softwareThresholds(_ sw: Software) -> [(
        WritableKeyPath<
        SoftSkills,
        Int
        >,
        Int
    )] {
        switch sw {
        case .officeSuite:
            return [
                (\.selfDisciplineAndPerseverance, 2),
                (\.timeManagementAndPlanning, 1),
            ]
        case .programming:
            return [
                (\.analyticalReasoningAndProblemSolving, 3),
                (\.patienceAndPerseverance, 2),
            ]
        case .mediaEditing:
            return [
                (\.creativityAndInsightfulThinking, 3),
                (\.carefulnessAndAttentionToDetail, 2),
            ]
        case .gameEngine:
            return [
                (\.analyticalReasoningAndProblemSolving, 2),
                (\.creativityAndInsightfulThinking, 3),
            ]
        @unknown default:
            return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding<Bool>(
                get: { isSelected },
                set: { isOn in
                    guard !isLocked else { return }
                    if isOn {
                        guard !atLimit else { return }
                        switch item.softwareRequirements(player) {
                        case .ok(let cost):
                            selectedSoftware.insert(item)
                            selectedActivities.insert("soft:\(item.rawValue)")
                            player.savings -= cost
                        case .blocked:
                            break
                        }
                    } else {
                        if selectedSoftware.remove(item) != nil {
                            selectedActivities.remove("soft:\(item.rawValue)")
                        }
                    }
                }
            )) {
                Text(item.rawValue)
                    .font(.title3)
            }
#if os(macOS)
            .toggleStyle(.checkbox)
#endif
#if os(iOS)
            .toggleStyle(.switch)
#endif
            .disabled(
                isLocked || (
                    !isSelected && (
                        atLimit || blockedReason != nil || !prerequisitesFulfilled
                    )
                )
            )
            .opacity(
                isLocked || (
                    !isSelected && (
                        atLimit || blockedReason != nil || !prerequisitesFulfilled
                    )
                ) ? 0.5 : 1.0
            )
            .help(
                !prerequisitesFulfilled ? "You do not meet the prerequisites." :
                    isLocked ? "Locked after year end" :
                    (!isSelected && atLimit)
                ? "You can take up to \(maxActivitiesPerYear) activities this year."
                : (blockedReason ?? "")
            )

            let thresholds = softwareThresholds(item)
            if !thresholds.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(
                        Array(thresholds.enumerated()),
                        id: \.offset
                    ) { pair in
                        let (kp, lvl) = pair.element
                        RequirementRow(
                            label: SoftSkills.label(forKeyPath: kp) ?? "",
                            emoji: SoftSkills.pictogram(forKeyPath: kp) ?? "",
                            style: .meter(
                                current: player.softSkills[keyPath: kp],
                                required: lvl
                            )
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

