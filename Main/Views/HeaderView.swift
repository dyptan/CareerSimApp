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

                if let currentOccupation = player.currentOccupation {
                    HStack(spacing: 6) {
                        Text("\(currentOccupation.displayTitle) \(currentOccupation.icon)")
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
                }
                if let currentEducation = player.currentEducation {
                    Text("\(currentEducation.degreeName)")
                }

                // The running score, spelled out as the sum it is — net worth ÷
                // age — so the player watches the arithmetic move, not just the
                // result. The money lives only inside the formula; there is no
                // separate savings counter.
                HStack(spacing: 6) {
                    if player.isSimplified {
                        Text("Savings: \(player.savings.formatted(.number)) $")
                    } else {
                        Text("🏅 Score: \(scoreNetWorth.formatted(.number)) $ / \(player.age) y.o. = \(player.leaderboardScore.formatted(.number))")
                        InfoHint(
                            title: "Your score",
                            message: "Your score is your net worth — savings minus any venture or student loan — ÷ your age. It updates every year — building wealth younger scores higher. There's no finish line: play as long as you like, then tap “Stop” to bank this score to the leaderboard."
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if player.outstandingLoan > 0 {
                    Text("🏦 Venture loan owed: \(player.outstandingLoan.formatted(.number)) $")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if player.studentLoan > 0 {
                    Text("🎓 Student loan owed: \(player.studentLoan.formatted(.number)) $")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

            }

            Spacer()

            // The two controls that move the run itself, stacked together: end
            // it, or let a year pass. **Skip** lives here rather than in the
            // footer so the row below stays what the year can be *spent* on —
            // every button there opens a choice, and this one is the choice to
            // make none.
            VStack(alignment: .trailing, spacing: 8) {
                // Opens the Game Over sheet directly — no confirmation pop-up;
                // the sheet's own "Keep playing" button is the way back.
                Button("Stop") { appUIState.showRetirementSheet = true }
                    .buttonStyle(.bordered)
                    .font(.headline)

                Button("Skip") { player.advanceYear(appUIState: appUIState) }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
            }
        }
    }

    /// The score's numerator: net worth (savings minus any venture or student
    /// loan), floored at 0 — the same figure `Player.leaderboardScore` divides
    /// by age, so the displayed formula always reproduces the displayed score.
    private var scoreNetWorth: Int {
        max(0, player.savings - player.outstandingLoan - player.studentLoan)
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
        • Education vs. what the role expects: \(signed(odds.education))
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
