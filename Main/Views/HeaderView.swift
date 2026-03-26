import SwiftUI

struct HeaderView: View {
    @ObservedObject var player: Player

    @ObservedObject var appUIState: AppUIState

    private let maxActivitiesPerYear = 1

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
                
            if let lastlog = player.degrees.last {
                Text("Education: \(lastlog.degreeName)")
            }
            
            
            
            if player.savings > 0 {
                Text("Savings: \(player.savings) $")
                Text(String(repeating: "💶", count: player.savings / 100000)).lineLimit(10)
            }

            if let currentOccupation = player.currentOccupation {
                Text(
                    "Working: \(currentOccupation.id) \(currentOccupation.icon)"
                )
            }
            if let currentEducation = player.currentEducation {
                if currentEducation.profile != nil {
                    Text("Studying: \(currentEducation.degreeName)")
                }
            }

            

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
            selectedSoftware: [],
            selectedLicenses: [],
            selectedPortfolio: [],
            selectedCertifications: [],
            yearsLeftToGraduation: nil,
            decisionText: "sdf"
        )
    )
}
