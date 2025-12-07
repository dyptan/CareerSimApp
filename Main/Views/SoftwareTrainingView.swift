import SwiftUI

struct SoftwareTrainingView: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear = 1

    private var sortedSoftware: [Software] {
        Software.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    private var counterRow: some View {
        HStack(spacing: 6) {
            Text("Activities this year:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(
                    selectedActivities.count >= maxActivitiesPerYear
                        ? .red : .primary
                )
            Spacer()
            Text("Savings: $\(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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

    var body: some View {
        ScrollView {

            Text("Software")
            ForEach(sortedSoftware, id: \.self) { sw in
                let isLocked = player.lockedSoftware.contains(sw)
                let isSelected = selectedSoftware.contains(sw)
                let atLimit = selectedActivities.count >= maxActivitiesPerYear

                let requirement = sw.softwareRequirements(player)
                let blockedReason: String? = {
                    switch requirement {
                    case .blocked(let reason): return reason
                    case .ok: return nil
                    }
                }()

                VStack(alignment: .leading, spacing: 6) {
                    Toggle(
                        "\(sw.rawValue) \(sw.pictogram)",
                        isOn: Binding(
                            get: { isSelected },
                            set: { isOn in
                                guard !isLocked else { return }
                                if isOn {
                                    guard !atLimit else { return }
                                    switch sw.softwareRequirements(player) {
                                    case .ok(let cost):
                                        selectedSoftware.insert(sw)
                                        selectedActivities.insert(
                                            "soft:\(sw.rawValue)"
                                        )
                                        player.savings -= cost
                                    case .blocked:
                                        break
                                    }
                                } else {
                                    if selectedSoftware.remove(sw) != nil {
                                        selectedActivities.remove(
                                            "soft:\(sw.rawValue)"
                                        )
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

                    requirementRow(
                        label: SoftSkills.label(
                            forKeyPath: \.analyticalReasoningAndProblemSolving
                        ) ?? "Problem Solving",
                        emoji: SoftSkills.pictogram(
                            forKeyPath: \.analyticalReasoningAndProblemSolving
                        ) ?? "🧩",
                        level: 1,
                        playerLevel: player.softSkills
                            .analyticalReasoningAndProblemSolving
                    )
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal)

    }
}

#Preview {
    struct Container: View {
        @State var selected: Set<Software> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()
        var body: some View {
            NavigationView {
                SoftwareTrainingView(
                    selectedSoftware: $selected,
                    selectedActivities: $acts
                )
                .environmentObject(player)
            }
        }
    }
    return Container()
}
