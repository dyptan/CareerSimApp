import SwiftUI


struct FooterView: View {
    @ObservedObject var player: Player
    
    @Binding var showDecisionSheet: Bool
    @Binding var showTertiarySheet: Bool
    @Binding var showCareersSheet: Bool
    @Binding var showProjectsSheet: Bool
    @Binding var showCourcesSheet: Bool
    @Binding var showSoftSkillsSheet: Bool
    @Binding var showCertificationsSheet: Bool
    @Binding var showLicencesSheet: Bool
    @Binding var selectedActivities: Set<String>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedPortfolio: Set<Project>
    @Binding var selectedCertifications: Set<Certification>
    @Binding var yearsLeftToGraduation: Int?
    @Binding var descisionText: String
    
        
    var body: some View {
        HStack {
            
            Button("Projects") { showProjectsSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
            Button("Courses") { showCourcesSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
            Button("Activities") { showSoftSkillsSheet = true }
                .buttonStyle(.bordered).font(.headline)
        }
        
        HStack {
            
            Button("Certifications") { showCertificationsSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
            Button("Licenses") { showLicencesSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
        }
        
        HStack {
            Button("Jobs") {
                showCareersSheet.toggle()
            }.buttonStyle(.bordered).font(.headline).frame(
                alignment: .trailing
            )
            
            
            Button("Education") {
                showTertiarySheet.toggle()
            }.buttonStyle(.bordered).font(.headline).frame(
                alignment: .trailing
            )
            
            Button("Next year") {
                player.age += 1
                player.hardSkills.certifications.formUnion(selectedCertifications)
                player.hardSkills.licenses.formUnion(selectedLicences)
                player.hardSkills.portfolioItems.formUnion(selectedPortfolio)
                player.hardSkills.software.formUnion(selectedSoftware)
                player.lockedCertifications.formUnion(selectedCertifications)
                player.lockedPortfolio.formUnion(selectedPortfolio)
                player.lockedSoftware.formUnion(selectedSoftware)
                player.lockedLicenses.formUnion(selectedLicences)
                
                selectedActivities.removeAll()
                
                yearsLeftToGraduation? -= 1
                if yearsLeftToGraduation == 0 {
                    descisionText =
                    "You're done with your degree! What's your next step?"
                    showDecisionSheet.toggle()
                    if let currentEducation = player.currentEducation {
                        player.degrees.append(currentEducation)
                    }
                    yearsLeftToGraduation = nil
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

