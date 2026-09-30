import SwiftUI

struct HeaderView: View {
    @ObservedObject var player: Player

    @ObservedObject var appUIState: AppUIState

    @State var didBumpAgeScale = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {

                HStack {
                    Text(player.avatar)
                        .font(.title2)
                    Text("Age:")
                    Text("\(player.age)")
                        .scaleEffect(didBumpAgeScale ? 2 : 1)
                        .animation(.spring(), value: didBumpAgeScale)
                        .onChange(of: player.age) { _ in
                            didBumpAgeScale = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                didBumpAgeScale = false
                            }
                        }
                    InfoHint(title: "Game mode", message: gameModeSummary)
                }

                // Free to open at any age: reading advice never spends the year.
                // A dot means the advisor has something waiting — its opening
                // question, or a review of the year just lived.
                Button { appUIState.showAdvisorSheet = true } label: {
                    Label("Advice", systemImage: "lightbulb")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(player.hasRetired)
                .overlay(alignment: .topTrailing) {
                    if player.advisorPlan.needsAttention, !player.hasRetired {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 9, height: 9)
                            .offset(x: 3, y: -3)
                            .accessibilityLabel("The advisor has something for you")
                    }
                }
            }

            Spacer()

            // The two controls that concern the run itself, stacked together:
            // check (or end) it, or let a year pass. **Skip** lives here rather
            // than in the footer so the row below stays what the year can be
            // *spent* on — every button there opens a choice, and this one is
            // the choice to make none.
            VStack(alignment: .trailing, spacing: 8) {
                // Opens the score sheet: the running score, with Keep playing
                // and Start over (see `RetirementView`). The header itself no
                // longer shows the score.
                Button("Score") { appUIState.showRetirementSheet = true }
                    .buttonStyle(.bordered)
                    .font(.headline)

                // No years left to spend once the horizon is reached — the
                // score is final, so the control that would change it goes away.
                Button("Skip") { player.advanceYear(appUIState: appUIState) }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    .disabled(player.hasRetired)
            }
        }
    }

    /// Plain-text summary of the current run's rules: mode, savings rate, goal.
    /// Fed into the `InfoHint` next to the age. Year-by-year news (layoffs,
    /// promotions, wins) is the status log's job, and the recession is shown in
    /// the Economy section, so neither is repeated here.
    private var gameModeSummary: String {
        var lines: [String] = []
        lines.append("\(player.difficulty.icon) \(player.difficulty.title)")
        if !player.isSimplified {
            lines.append("💵 Saving \(Int(player.difficulty.savingsRate * 100))% of pay above \(player.difficulty.livingCostFloor.formatted(.number)) $ of living costs each year")
        }
        lines.append("\(player.difficulty.goalIcon) Goal: \(player.difficulty.goalHeadline)")
        return lines.joined(separator: "\n")
    }
}

#Preview {
    HeaderView(
        player: Player(
            degrees: [],
            currentOccupation: .none
        ),
        appUIState: AppUIState(
            showTertiarySheet: false,
            showCareersSheet: false,
            selectedActivities: [],
            selectedTrainings: [],
            yearsLeftToGraduation: nil
        )
    )
}
