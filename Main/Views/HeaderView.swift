import SwiftUI

struct HeaderView: View {
    @ObservedObject var player: Player

    @ObservedObject var appUIState: AppUIState

    @State var didBumpAgeScale = false
    @State private var showFinishConfirm = false

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

                if let currentOccupation = player.currentOccupation {
                    Text("Working: \(currentOccupation.id) \(currentOccupation.icon)")
                    Text("\(currentOccupation.annualIncome.formatted(.number)) $ / year")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let currentEducation = player.currentEducation {
                    Text("Studying: \(currentEducation.degreeName)")
                }

                Text("Savings: \(player.savings.formatted(.number)) $")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !player.recognitions.isEmpty {
                    accoladesRow
                }
            }

            Spacer()

            // End the run early and record the score, at any age.
            Button("Finish game") { showFinishConfirm = true }
                .buttonStyle(.bordered)
                .font(.headline)
        }
        .alert("Finish game?", isPresented: $showFinishConfirm) {
            Button("Finish & record score", role: .destructive) {
                appUIState.showRetirementSheet = true
            }
            Button("Keep playing", role: .cancel) { }
        } message: {
            Text("End your career now and record your score (savings ÷ age = \(player.leaderboardScore)). You can start over afterward.")
        }
    }

    /// A single-line fame counter. The individual accolade titles live in the
    /// SkillsView "Personal Brand & Recognition" section, not here.
    private var accoladesRow: some View {
        Text("🌟 Fame \(String(format: "%.1f", player.fameScore))")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
    }

    /// Plain-text summary of the current run's mode, savings, goal, and any
    /// active flags (recession, layoff, last year's side-hustle / promotion /
    /// competition results). Fed into the `InfoHint` next to the age so the
    /// header itself can stay focused on age + current activity.
    private var gameModeSummary: String {
        var lines: [String] = []
        lines.append("\(player.difficulty.icon) \(player.difficulty.title)")
        if !player.isSimplified {
            lines.append("💵 Saving \(Int(player.difficulty.savingsRate * 100))% of gross income each year")
        }
        lines.append("\(player.difficulty.goalIcon) Goal: \(player.difficulty.goalHeadline)")

        if !player.isSimplified {
            if player.economyInRecession {
                lines.append(player.turmoilYearsRemaining > 0
                             ? "📉 Recession ongoing (~\(player.turmoilYearsRemaining) yr left) — hiring & raises frozen"
                             : "📉 Recession this year — hiring & raises frozen")
            }
            if player.lostJobThisYear {
                lines.append("💼 You were laid off last year — find a new job")
            }
            if player.lastSideHustleEarnings != 0 {
                lines.append("🛠️ Side hustles \(player.lastSideHustleEarnings >= 0 ? "earned" : "cost") \(abs(player.lastSideHustleEarnings).formatted(.number)) $ last year")
            }
            if player.lastPromotionRaisePct > 0 {
                lines.append("⬆️ Promoted last year — pay up \(player.lastPromotionRaisePct)%")
            }
            if player.lastCompetitionWins > 0 {
                lines.append("🏆 Won \(player.lastCompetitionWins) competition\(player.lastCompetitionWins == 1 ? "" : "s") last year")
            }
        }
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
