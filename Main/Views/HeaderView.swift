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
                    HStack(spacing: 6) {
                        Text("Working: \(currentOccupation.id) \(currentOccupation.icon)")
                        // Promotions are a realistic-mode mechanic only.
                        if !player.isSimplified {
                            InfoHint(
                                title: "Promotion odds this year",
                                message: promotionOddsSummary(for: currentOccupation)
                            )
                        }
                    }
                    Text("\(currentOccupation.annualIncome.formatted(.number)) $ / year")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // While running a founder venture, show its live business
                    // metrics — the traction that drives the next buyout offer.
                    if let startup = player.activeStartup {
                        Text("📊 \(Int(startup.marketSharePct.rounded()))% market · 💰 \(startup.revenue.formatted(.number)) $ · 👥 \(startup.headcount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let currentEducation = player.currentEducation {
                    Text("Studying: \(currentEducation.degreeName)")
                }

                Text("Savings: \(player.savings.formatted(.number)) $")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Realistic mode is open-ended: show the running score (updated
                // every year) that the player banks when they finish the game.
                if !player.isSimplified {
                    HStack(spacing: 6) {
                        Text("🏅 Score: \(player.leaderboardScore.formatted(.number))")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        InfoHint(
                            title: "Your score",
                            message: "Your score is your savings ÷ your age (\(player.savings.formatted(.number)) ÷ \(player.age) = \(player.leaderboardScore)). It updates every year — building wealth younger scores higher. There's no finish line: play as long as you like, then tap “Finish game” to bank this score to the leaderboard."
                        )
                    }
                }
            }

            Spacer()

            // End the run early and record the score, at any age.
            Button("Finish game") { showFinishConfirm = true }
                .buttonStyle(.bordered)
                .font(.headline)
        }
        .alert("Finish game?", isPresented: $showFinishConfirm) {
            Button("Finish & save record", role: .destructive) {
                appUIState.showRetirementSheet = true
            }
            Button("Keep playing", role: .cancel) { }
        } message: {
            Text("End your career now and save your score of \(player.leaderboardScore) (savings ÷ age) to the leaderboard. You can start over afterward.")
        }
    }

    /// Plain-text breakdown of this year's promotion odds for the current job,
    /// mirroring the hire-probability InfoHint. Explains each term (readiness,
    /// network, fame, tenure) so the fame contribution is visible.
    private func promotionOddsSummary(for job: Job) -> String {
        let odds = player.promotionOdds(for: job)
        guard odds.promotes else {
            return "This role doesn't offer in-place promotions — unskilled work rarely comes with a raise-and-title bump. Climb by applying to a higher role instead."
        }
        func pct(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }
        func signed(_ v: Double) -> String {
            let s = Int((v * 100).rounded())
            return s >= 0 ? "+\(s)%" : "\(s)%"
        }
        return """
        Each year in a skilled role you get a shot at a raise and title bump. This year's odds:

        • Base × soft-skill readiness: \(pct(odds.readinessBase))
        • Network (\(job.category.rawValue)): \(signed(odds.network))
        • Fame (\(job.category.rawValue)): \(signed(odds.fame))
        • Tenure (\(odds.tenureYears) yr in role): \(signed(odds.tenure))
        Total: \(pct(odds.total))

        Raises are paused during a recession.
        """
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
