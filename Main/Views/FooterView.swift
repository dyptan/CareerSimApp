import SwiftUI


struct FooterView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState
        
    var body: some View {
        // Projects, Certifications, and Licenses are hard-skill training that
        // only matters in realistic mode, so hide them in simplified mode.
        // Activities stay — they build the soft skills that gate school admission.
        if player.isSimplified {
            HStack {
                Button("Activities") { appUIState.showActivitiesSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }
        } else {
            HStack {

                Button("Side Projects") { appUIState.showProjectsSheet = true }
                    .buttonStyle(.bordered).font(.headline)

                Button("Activities") { appUIState.showActivitiesSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }

            HStack {

                Button("Certifications") { appUIState.showCertificationsSheet = true }
                    .buttonStyle(.bordered).font(.headline)

                Button("Licenses") { appUIState.showLicensesSheet = true }
                    .buttonStyle(.bordered).font(.headline)

                Button("Side Hustles") { appUIState.showSideHustlesSheet = true }
                    .buttonStyle(.bordered).font(.headline)

            }
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
