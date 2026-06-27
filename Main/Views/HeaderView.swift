import SwiftUI

struct HeaderView: View {
    @ObservedObject var player: Player

    @ObservedObject var appUIState: AppUIState

    @State var didBumpAgeScale = false

    var body: some View {
        VStack(alignment: .leading) {
            
            HStack{
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

            if !player.isSimplified {
                Text("\(player.difficulty.icon) \(player.difficulty.title) — saving \(Int(player.difficulty.savingsRate * 100))% of gross income each year")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if player.economyInRecession {
                    Text(player.turmoilYearsRemaining > 0
                         ? "📉 Recession ongoing (~\(player.turmoilYearsRemaining) yr left) — hiring & raises frozen"
                         : "📉 Recession this year — hiring & raises frozen")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                if player.lostJobThisYear {
                    Text("💼 You were laid off last year — find a new job")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                if player.lastSideHustleEarnings != 0 {
                    Text("🛠️ Side hustles \(player.lastSideHustleEarnings >= 0 ? "earned" : "cost") \(abs(player.lastSideHustleEarnings).formatted(.number)) $ last year")
                        .font(.caption2)
                        .foregroundStyle(player.lastSideHustleEarnings >= 0 ? .green : .red)
                }

                if player.lastPromotionRaisePct > 0 {
                    Text("⬆️ Promoted last year — pay up \(player.lastPromotionRaisePct)%")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }

                if player.lastCompetitionWins > 0 {
                    Text("🏆 Won \(player.lastCompetitionWins) competition\(player.lastCompetitionWins == 1 ? "" : "s") last year")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Text("\(player.difficulty.goalIcon) Goal: \(player.difficulty.goalHeadline)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

        }
    }
}

#Preview {
    HeaderView(
        player: Player(
            degrees: [],
            currentOccupation: .none
        ),
        appUIState: AppUIState(
            showDecisionSheet: false,
            showTertiarySheet: false,
            showCareersSheet: false,
            selectedActivities: [],
            selectedLicenses: [],
            selectedPortfolio: [],
            selectedCertifications: [],
            yearsLeftToGraduation: nil,
            decisionText: "sdf"
        )
    )
}
