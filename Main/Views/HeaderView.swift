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
                Text(
                    "Working: \(currentOccupation.id) \(currentOccupation.icon)"
                )
            }
            if let currentEducation = player.currentEducation {
                Text("Studying: \(currentEducation.degreeName)")
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
