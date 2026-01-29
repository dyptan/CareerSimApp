import SwiftUI

struct HeaderView: View {
    @ObservedObject var player: Player

    @Binding var showDecisionSheet: Bool
    @Binding var showTertiarySheet: Bool
    @Binding var showCareersSheet: Bool

    @Binding var selectedActivities: Set<String>

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedPortfolio: Set<Project>
    @Binding var selectedCertifications: Set<Certification>

    @Binding var yearsLeftToGraduation: Int?
    @Binding var descisionText: String

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
                Text("Degree: \(lastlog.degreeName)")
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
        showDecisionSheet: .constant(false),
        showTertiarySheet: .constant(false),
        showCareersSheet: .constant(false),
        selectedActivities: .constant(Set<String>()),
        selectedSoftware: .constant(Set<Software>()),
        selectedLicences: .constant(Set<License>()),
        selectedPortfolio: .constant(Set<Project>()),
        selectedCertifications: .constant(Set<Certification>()),
        yearsLeftToGraduation: .constant(nil),
        descisionText: .constant("sdf")
    )

}
