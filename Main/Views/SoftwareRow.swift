import SwiftUI

struct SoftwareRow: View {
    @ObservedObject var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedActivities: Set<String>

    let item: Software

    private var isSelected: Bool { selectedSoftware.contains(item) }
    private var isLocked: Bool { player.lockedSoftware.contains(item) }
    private var atLimit: Bool { selectedActivities.count >= GameConstants.trainingActivitySlotCost }

    private var blockedReason: String? {
        if case .blocked(let reason) = item.softwareRequirements(player) { return reason }
        return nil
    }

    private var prerequisitesMet: Bool {
        item.softSkillThresholds.allSatisfy { player.softSkills[keyPath: $0.0] >= $0.1 }
    }

    private var isDisabled: Bool {
        isLocked || (!isSelected && (atLimit || blockedReason != nil || !prerequisitesMet))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                // InfoHint sits outside the Toggle so it stays tappable
                // even when the toggle is disabled by missing requirements.
                InfoHint(title: "\(item.pictogram) \(item.friendlyName)", message: item.description)
                Toggle(isOn: Binding(
                    get: { isSelected },
                    set: { isOn in
                        guard !isLocked else { return }
                        if isOn {
                            guard !atLimit else { return }
                            player.purchaseSoftware(item, into: &selectedSoftware, activities: &selectedActivities)
                        } else {
                            player.deselectSoftware(item, from: &selectedSoftware, activities: &selectedActivities)
                        }
                    }
                )) {
                    Text(item.friendlyName).font(.title3)
                }
                .platformToggleStyle()
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.5 : 1.0)
                .help(
                    !prerequisitesMet ? "You do not meet the prerequisites." :
                    isLocked ? "Locked after year end" :
                    (!isSelected && atLimit) ? "You can take up to \(GameConstants.trainingActivitySlotCost) activities this year." :
                    (blockedReason ?? "")
                )
            }

            let thresholds = item.softSkillThresholds
            if !thresholds.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(thresholds.enumerated()), id: \.offset) { _, pair in
                        RequirementRow(
                            label: SoftSkills.label(forKeyPath: pair.0) ?? "",
                            emoji: SoftSkills.pictogram(forKeyPath: pair.0) ?? "",
                            style: .meter(current: player.softSkills[keyPath: pair.0], required: pair.1)
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
