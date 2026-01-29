import SwiftUI

struct CoursesView: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear = 1

    private var sortedSoftware: [Software] {
        Software.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }
    
    private func softwareThresholds(_ sw: Software) -> [(WritableKeyPath<SoftSkills, Int>, Int)] {
        switch sw {
        case .officeSuite:
            return [(\.selfDisciplineAndStudyHabits, 2), (\.timeManagementAndPlanning, 1)]
        case .programming:
            return [(\.analyticalReasoningAndProblemSolving, 3), (\.patienceAndPerseverance, 2)]
        case .mediaEditing:
            return [(\.creativityAndInsightfulThinking, 3), (\.carefulnessAndAttentionToDetail, 2)]
        case .gameEngine:
            return [(\.analyticalReasoningAndProblemSolving, 2), (\.creativityAndInsightfulThinking, 3)]
        default:
            return []
        }
    }

    var body: some View {
        ScrollView {

            ForEach(sortedSoftware, id: \.self) { (sw: Software) in
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
//
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(
                        "\(sw.rawValue) \(sw.pictogram)",
                        isOn: Binding<Bool>(
                            get: { selectedSoftware.contains(sw) },
                            set: { isOn in
                                guard !isLocked else { return }
                                if isOn {
                                    guard !atLimit else { return }
                                    switch sw.softwareRequirements(player) {
                                    case .ok(let cost):
                                        selectedSoftware.insert(sw)
                                        selectedActivities.insert("soft:\(sw.rawValue)")
                                        player.savings -= cost
                                    case .blocked:
                                        break
                                    }
                                } else {
                                    if selectedSoftware.remove(sw) != nil {
                                        selectedActivities.remove("soft:\(sw.rawValue)")
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
                }
                
                let thresholds = softwareThresholds(sw)
                if !thresholds.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(thresholds.enumerated()), id: \.offset) { pair in
                            let (kp, lvl) = pair.element
                            RequirementRow(
                                label: SoftSkills.label(forKeyPath: kp) ?? "",
                                emoji: SoftSkills.pictogram(forKeyPath: kp) ?? "",
                                style: .meter(current: player.softSkills[keyPath: kp], required: lvl)
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
    }
}

#Preview {
    struct Container: View {
        @State var selected: Set<Software> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()
        var body: some View {
            NavigationView {
                CoursesView(
                    selectedSoftware: $selected,
                    selectedActivities: $acts
                )
                .environmentObject(player)
            }
        }
    }
    return Container()
}

