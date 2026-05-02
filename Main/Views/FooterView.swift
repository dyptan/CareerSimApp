import SwiftUI


struct FooterView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState
        
    var body: some View {
        HStack {
            
            Button("Projects") { appUIState.showProjectsSheet = true }
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
                player.advanceYear(appUIState: appUIState)
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
    }
}
