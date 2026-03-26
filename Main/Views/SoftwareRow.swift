import SwiftUI

struct SoftwareRow: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear: Int
    let item: Software

    private var isSelected: Bool { selectedSoftware.contains(item) }
    private var isLocked: Bool { player.lockedSoftware.contains(item) }
    private var atLimit: Bool { selectedActivities.count >= maxActivitiesPerYear }

    private var blockedReason: String? {
        if case .blocked(let reason) = item.softwareRequirements(player) { return reason }
        return nil
    }

    private var prerequisitesMet: Bool {
        item.softSkillThresholds.allSatisfy { player.softSkills[keyPath: $0.0] >= $0.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { isSelected },
                set: { isOn in
                    guard !isLocked else { return }
                    if isOn {
                        guard !atLimit else { return }
                        if case .ok(let cost) = item.softwareRequirements(player) {
                            selectedSoftware.insert(item)
                            selectedActivities.insert("soft:\(item.rawValue)")
                            player.savings -= cost
                        }
                    } else if selectedSoftware.remove(item) != nil {
                        selectedActivities.remove("soft:\(item.rawValue)")
                    }
                }
            )) {
                Text(item.rawValue).font(.title3)
            }
            #if os(macOS)
            .toggleStyle(.checkbox)
            #endif
            #if os(iOS)
            .toggleStyle(.switch)
            #endif
            .disabled(isLocked || (!isSelected && (atLimit || blockedReason != nil || !prerequisitesMet)))
            .opacity((isLocked || (!isSelected && (atLimit || blockedReason != nil || !prerequisitesMet))) ? 0.5 : 1.0)
            .help(
                !prerequisitesMet ? "You do not meet the prerequisites." :
                isLocked ? "Locked after year end" :
                (!isSelected && atLimit) ? "You can take up to \(maxActivitiesPerYear) activities this year." :
                (blockedReason ?? "")
            )

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
