import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear = 1

    private var sortedPortfolio: [PortfolioItem] {
        PortfolioItem.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }


    var body: some View {
        ScrollView {

            Text("Portfolio Items")
            ForEach(sortedPortfolio, id: \.self) { item in
                let isLocked = player.lockedPortfolio.contains(item)
                let isSelected = selectedPortfolio.contains(item)
                let atLimit = selectedActivities.count >= maxActivitiesPerYear

                let requirement = item.portfolioRequirements(player)
                let blockedReason: String? = {
                    switch requirement {
                    case .blocked(let reason): return reason
                    case .ok: return nil
                    }
                }()

                    Toggle(
                        "\(item.rawValue) \(item.pictogram) \(blockedReason ?? "")",
                        isOn: Binding(
                            get: { isSelected },
                            set: { isOn in
                                guard !isLocked else { return }
                                if isOn {
                                    guard !atLimit else { return }
                                    switch item.portfolioRequirements(player) {
                                    case .ok:
                                        selectedPortfolio.insert(item)
                                        selectedActivities.insert(
                                            "port:\(item.rawValue)"
                                        )
                                    case .blocked:
                                        break
                                    }
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
                                : "")
                    )
                    RequirementRow(
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
                    .padding(.vertical, 4)
                    
                }
            
        }
        .padding(.horizontal)
    }
}

#Preview {
    struct Container: View {
        @State var selected: Set<PortfolioItem> = []
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

