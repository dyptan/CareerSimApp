import SwiftUI


struct FooterView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState
        
    var body: some View {
        HStack {
            
            Button("Projects") { appUIState.showProjectsSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
            Button("Courses") { appUIState.showCoursesSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
            Button("Activities") { appUIState.showActivitiesSheet = true }
                .buttonStyle(.bordered).font(.headline)
        }
        
        HStack {
            
            Button("Certifications") { appUIState.showCertificationsSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
            Button("Licenses") { appUIState.showLicensesSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
        }
        
        HStack {
            Button("Jobs") {
                appUIState.showCareersSheet.toggle()
            }.buttonStyle(.bordered).font(.headline).frame(
                alignment: .trailing
            )
            
            
            Button("Education") {
                appUIState.showTertiarySheet.toggle()
            }.buttonStyle(.bordered).font(.headline).frame(
                alignment: .trailing
            )
            
            Button("Next year") {
                player.age += 1
                player.hardSkills.certifications.formUnion(appUIState.selectedCertifications)
                player.hardSkills.licenses.formUnion(appUIState.selectedLicenses)
                player.hardSkills.portfolioItems.formUnion(appUIState.selectedPortfolio)
                player.hardSkills.software.formUnion(appUIState.selectedSoftware)
                player.lockedCertifications.formUnion(appUIState.selectedCertifications)
                player.lockedPortfolio.formUnion(appUIState.selectedPortfolio)
                player.lockedSoftware.formUnion(appUIState.selectedSoftware)
                player.lockedLicenses.formUnion(appUIState.selectedLicenses)
                
                appUIState.selectedActivities.removeAll()
                
                appUIState.yearsLeftToGraduation? -= 1
                if appUIState.yearsLeftToGraduation == 0 {
                    appUIState.decisionText =
                    "You're done with your degree! What's your next step?"
                    appUIState.showDecisionSheet.toggle()
                    if let currentEducation = player.currentEducation {
                        player.degrees.append(currentEducation)
                    }
                    appUIState.yearsLeftToGraduation = nil
                    player.currentEducation = nil
                }
                
                if let income = player.currentOccupation?.income {
                    player.savings += income
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
    }
}
