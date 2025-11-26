import SwiftUI

struct HeaderView: View {
    //     Inject the model and all state this header needs to read/mutate
    @ObservedObject var player: Player

    @Binding var showDecisionSheet: Bool
    @Binding var showTertiarySheet: Bool
    @Binding var showCareersSheet: Bool

    @Binding var selectedActivities: Set<String>

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedCertifications: Set<Certification>

    @Binding var yearsLeftToGraduation: Int?
    @Binding var descisionText: String

    private let maxActivitiesPerYear = 3

    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Age: \(player.age)")
                .font(.title2)
            
            if let lastlog = player.degrees.last {
                Text("Last degree: \(lastlog.degreeName)")
            }
            
            Text("Bank balance: \(player.savings)$")
            
            if player.savings > 0 {
                Text(String(repeating: "💶", count: player.savings / 10))
            }

            if let currentOccupation = player.currentOccupation {
                Text(
                    "Occupation: \(currentOccupation.id) \(currentOccupation.icon)"
                )
            }
            if let currentEducation = player.currentEducation {
                if currentEducation.profile != nil {
                    Text("Studying: \(currentEducation.degreeName)")
                }
            }

            HStack {

                if player.age > 18 {
                    Button("Find a Job") {
                        showCareersSheet.toggle()
                        player.currentOccupation = nil
                    }.buttonStyle(.borderedProminent)
                }

                if let eqf = player.degrees.last?.eqf, eqf >= 4 {
                    Button("Get a degree") {
                        showTertiarySheet.toggle()
                    }.buttonStyle(.borderedProminent)
                }
            }

        }
    }
}

#Preview {
    HeaderView(
        player: Player(
            degrees: [],
            currentOccupation: .some(
                jobExample
            )
        ),
        showDecisionSheet: .constant(false),
        showTertiarySheet: .constant(false),
        showCareersSheet: .constant(false),
        selectedActivities: .constant(Set<String>()),
        selectedSoftware: .constant(Set<Software>()),
        selectedLicences: .constant(Set<License>()),
        selectedPortfolio: .constant(Set<PortfolioItem>()),
        selectedCertifications: .constant(Set<Certification>()),
        yearsLeftToGraduation: .constant(nil),
        descisionText: .constant("sdf")
    )

}

