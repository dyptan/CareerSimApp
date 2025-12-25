import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedPortfolio: Set<Project>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear = 1

    private var sortedPortfolio: [Project] {
        Project.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    private struct ProjectRow: View {
        @EnvironmentObject private var player: Player
        let item: Project
        @Binding var selectedPortfolio: Set<Project>
        @Binding var selectedActivities: Set<String>
        let maxActivitiesPerYear: Int

        private func requirementRow(label: String, emoji: String, level: Int, playerLevel: Int) -> some View {
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
            .padding(.horizontal)
        }

        private func softRequirement(_ label: String, _ emoji: String, requiredLevel: Int, current: Int) -> some View {
            requirementRow(label: label, emoji: emoji, level: requiredLevel, playerLevel: current)
        }

        private func hardRequirementRow(label: String, emoji: String, met: Bool) -> some View {
            HStack {
                Text(label)
                Spacer()
                Text(emoji)
                    .opacity(met ? 1.0 : 0.35)
            }
            .font(.body)
            .foregroundStyle(met ? .primary : .secondary)
            .padding(.horizontal)
        }

        var body: some View {
            let isLocked = player.lockedPortfolio.contains(item)
            let isSelected = selectedPortfolio.contains(item)
            let atLimit = selectedActivities.count >= maxActivitiesPerYear
            
            let reqs = item.requirements(for: player)
            let meetsAllRequirements =
                reqs.softSkills.allSatisfy { $0.current >= $0.required } &&
                reqs.hardSkills.allSatisfy { $0.current >= $0.required }

            VStack(alignment: .leading) {
                Toggle(
                    "\(item.rawValue) \(item.pictogram)",
                    isOn: Binding(
                        get: { isSelected },
                        set: { isOn in
                            guard !isLocked else { return }
                            if isOn {
                                guard !atLimit else { return }
                                selectedPortfolio.insert(item)
                                selectedActivities.insert(
                                    "port:\(item.rawValue)"
                                )
                            } else {
                                if selectedPortfolio.remove(item) != nil {
                                    selectedActivities.remove(
                                        "port:\(item.rawValue)"
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
                    || (!isSelected && (atLimit || !meetsAllRequirements))
                )
                .opacity(
                    (isLocked || (!isSelected && (atLimit || !meetsAllRequirements))) ? 0.5 : 1.0
                )
                .help(
                    isLocked
                    ? "Locked after year end"
                    : (
                        (!isSelected && atLimit)
                        ? "You can take up to \(maxActivitiesPerYear) activities this year."
                        : (!isSelected && !meetsAllRequirements)
                          ? "Requirements not met yet."
                          : ""
                      )
                )
                VStack(alignment: .leading, spacing: 8) {
                    if !reqs.softSkills.isEmpty {
                        ForEach(reqs.softSkills, id: \.label) { s in
                            softRequirement(s.label, s.emoji, requiredLevel: s.required, current: s.current)
                        }
                    }

                    if !reqs.hardSkills.isEmpty {
                        ForEach(reqs.hardSkills, id: \.label) { h in
                            let met = h.current >= h.required
                            hardRequirementRow(label: h.label, emoji: h.emoji, met: met)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(sortedPortfolio, id: \.self) { item in
                    ProjectRow(
                        item: item,
                        selectedPortfolio: $selectedPortfolio,
                        selectedActivities: $selectedActivities,
                        maxActivitiesPerYear: maxActivitiesPerYear
                    )
                    .environmentObject(player)
                }
            }
        }
        .padding()
    }
}

#Preview {
    struct Container: View {
        @State var selected: Set<Project> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()
        var body: some View {
            NavigationView {
                ProjectsView(
                    selectedPortfolio: $selected,
                    selectedActivities: $acts
                )
                .environmentObject(player)
            }
        }
    }
    return Container()
}

