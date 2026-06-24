import SwiftUI

struct HeaderView: View {
    @ObservedObject var player: Player

    @ObservedObject var appUIState: AppUIState

    @State var didBumpAgeScale = false

    var body: some View {
        VStack(alignment: .leading) {
            
            HStack{
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
                Text("Topped up with \(Int(GameConstants.savingsRate * 100))% of gross income each year")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text("\(player.gameMode.goalIcon) Goal: \(player.gameMode.goalHeadline)")
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
