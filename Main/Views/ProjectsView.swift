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
                ProjectRequirementsView(
                    requirements:
                        reqs.softSkills.map { s in
                            .init(label: s.label, emoji: s.emoji, style: .meter(current: s.current, required: s.required))
                        }
                        +
                        reqs.hardSkills.map { h in
                            .init(label: h.label, emoji: h.emoji, style: .badge(isMet: h.current >= h.required))
                        }
                )
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

