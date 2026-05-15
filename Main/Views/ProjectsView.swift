import SwiftUI

struct ProjectsView: View {
    @ObservedObject var player: Player

    @Binding var selectedPortfolio: Set<Project>
    @Binding var selectedActivities: Set<String>

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var sortedPortfolio: [Project] {
        Project.allCases
            .filter { $0.stages.contains(currentStage) }
            .sorted(by: { $0.rawValue < $1.rawValue })
    }

    private struct ProjectRow: View {
        @ObservedObject var player: Player
        let item: Project
        @Binding var selectedPortfolio: Set<Project>
        @Binding var selectedActivities: Set<String>

        var body: some View {
            let isLocked = player.lockedPortfolio.contains(item)
            let isSelected = selectedPortfolio.contains(item)
            let atLimit = selectedActivities.count >= GameConstants.trainingActivitySlotCost

            let reqs = item.requirements(for: player)
            let meetsAllRequirements =
                reqs.softSkills.allSatisfy { $0.current >= $0.required }
                && reqs.hardSkills.allSatisfy { $0.current >= $0.required }

            let isDisabled = isLocked || (!isSelected && (atLimit || !meetsAllRequirements))

            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    // InfoHint sits outside the Toggle so it stays tappable
                    // even when the toggle is disabled by missing requirements.
                    InfoHint(title: "\(item.pictogram) \(item.rawValue)", message: item.description)
                    Toggle(
                        "\(Text(item.rawValue).font(.title3)) \(item.pictogram)",
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
                    .platformToggleStyle()
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.5 : 1.0)
                    .help(
                        isLocked
                            ? "Locked after year end"
                            : ((!isSelected && atLimit)
                                ? "You can take up to \(GameConstants.trainingActivitySlotCost) activities this year."
                                : (!isSelected && !meetsAllRequirements)
                                    ? "Requirements not met yet."
                                    : "")
                    )
                }

                let requirements =
                    reqs.softSkills.map { s in
                        Requirement(
                            label: s.label,
                            emoji: s.emoji,
                            style: .meter(
                                current: s.current,
                                required: s.required
                            )
                        )
                    }
                    + reqs.hardSkills.map { h in
                        Requirement(
                            label: h.label,
                            emoji: h.emoji,
                            style: .badge(isMet: h.current >= h.required)
                        )
                    }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(requirements) { req in
                        RequirementRow(
                            label: req.label,
                            emoji: req.emoji,
                            style: req.style
                        )
                    }

                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if sortedPortfolio.isEmpty {
                    Text("No portfolio projects available yet — come back when you're older.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(sortedPortfolio, id: \.self) { item in
                        ProjectRow(
                            player: player,
                            item: item,
                            selectedPortfolio: $selectedPortfolio,
                            selectedActivities: $selectedActivities
                        )
                        .padding(8)
                    }
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
                    player: player,
                    selectedPortfolio: $selected,
                    selectedActivities: $acts
                )
            }
        }
    }
    return Container()
}
