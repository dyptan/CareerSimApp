//import SwiftUI
//
//// Minimal harness to reproduce the Portfolio ForEach logic in isolation.
//struct PortfolioSectionPreviewView: View {
//    @State var selectedPortfolio: Set<PortfolioItem> = []
//    @State var selectedActivities: Set<String> = []
//    @StateObject var player = Player()
//
//    let maxActivitiesPerYear = 1
//
//    // Use a value array for ForEach (not a binding)
//    var sortedPortfolio: [PortfolioItem] {
//        PortfolioItem.allCases.sorted(by: { $0.rawValue < $1.rawValue })
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack(spacing: 6) {
//                Text("Activities this year:")
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//                Text("\(selectedActivities.count)/\(maxActivitiesPerYear)")
//                    .font(.headline.monospacedDigit())
//                    .foregroundStyle(
//                        selectedActivities.count >= maxActivitiesPerYear ? .red : .primary
//                    )
//                Spacer()
//                Text("Savings: $\(player.savings)")
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//            }
//
//            Text("Portfolio Items:")
//                .font(.headline)
//
//            ForEach(sortedPortfolio, id: \.self) { item in
//                let isLocked = player.lockedPortfolio.contains(item)
//                let isSelected = selectedPortfolio.contains(item)
//                let atLimit = selectedActivities.count >= maxActivitiesPerYear
//
//                Toggle(
//                    "\(item.rawValue) \(item.pictogram)",
//                    isOn: Binding(
//                        get: { isSelected },
//                        set: { isOn in
//                            guard !isLocked else { return }
//                            if isOn {
//                                guard !atLimit else { return }
//                                selectedPortfolio.insert(item)
//                                selectedActivities.insert("port:\(item.rawValue)")
//                            } else {
//                                if selectedPortfolio.remove(item) != nil {
//                                    selectedActivities.remove("port:\(item.rawValue)")
//                                }
//                            }
//                        }
//                    )
//                )
//                #if os(macOS)
//                .toggleStyle(.checkbox)
//                #endif
//                #if os(iOS)
//                .toggleStyle(.switch)
//                #endif
//                .disabled(isLocked || (!isSelected && atLimit))
//                .opacity((isLocked || (!isSelected && atLimit)) ? 0.5 : 1.0)
//            }
//
//            Divider()
//
//            VStack(alignment: .leading, spacing: 6) {
//                Text("Debug")
//                    .font(.subheadline.bold())
//                Text("Selected: \(selectedPortfolio.map(\.rawValue).sorted().joined(separator: ", "))")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//                Text("Activities: \(selectedActivities.sorted().joined(separator: ", "))")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//        }
//        .padding()
//        .environmentObject(player)
//    }
//}
//
//#Preview("Portfolio Section") {
//    PortfolioSectionPreviewView()
//}
