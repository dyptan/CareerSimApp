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
                    // The label and the number sit close, as one phrase; the HStack's own gap would
                    // open a hole after the colon (wide in Japanese, whose colon is full-width).
                    HStack(spacing: 4) {
                        Text("Age:", comment: "Header label before the player's age number")  // i18n:ignore translator comment
                        Text(verbatim: "\(player.age)")
                            .scaleEffect(didBumpAgeScale ? 2 : 1)
                            .animation(.spring(), value: didBumpAgeScale)
                            .onChange(of: player.age) { _ in
                                didBumpAgeScale = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    didBumpAgeScale = false
                                }
                            }
                    }
                    InfoHint(title: L("Game mode"), message: gameModeSummary)
                }

                // Free to open at any age: reading advice never spends the year.
                // A dot means the advisor has something waiting — its opening
                // question, or a review of the year just lived.
                Button { appUIState.showAdvisorSheet = true } label: {
                    Label(String(localized: "Advice", comment: "Header button that opens the career advisor (a noun: advice to read)"),  // i18n:ignore translator comment
                          systemImage: "lightbulb")
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
                // longer shows the score. Simplified keeps no score, so there
                // it is a progress check.
                Button(player.difficulty.keepsScore
                       ? String(localized: "Score", comment: "Header button: opens the score sheet (Real Life mode)")  // i18n:ignore translator comment
                       : String(localized: "Progress", comment: "Header button: opens the progress check (Simplified mode, which keeps no score)")) {  // i18n:ignore translator comment
                    appUIState.showRetirementSheet = true
                }
                    .buttonStyle(.bordered)
                    .font(.headline)

                // No years left to spend once the horizon is reached — the
                // score is final, so the control that would change it goes away.
                Button(String(localized: "Skip", comment: "Header button: let this year pass without choosing anything (a verb)")) {  // i18n:ignore translator comment
                    player.advanceYear(appUIState: appUIState)
                }
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
        lines.append("\(player.country.flag) \(player.country.title)")
        if !player.isSimplified {
            lines.append(L("💵 Saving \(Fmt.percent(player.difficulty.savingsRate)) of pay above \(player.money(player.livingCostFloor)) of living costs each year"))
        }
        lines.append(L("\(player.difficulty.goalIcon) Goal: \(player.difficulty.goalHeadline)"))
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
