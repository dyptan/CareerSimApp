import SwiftUI


struct FooterView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    @State private var showFinishConfirm = false

    var body: some View {
        // Projects, Certifications, Licenses, Side Hustles, and Events are
        // realistic-mode features, so hide them in simplified mode. Hobbies
        // stay — they build the soft skills that gate school admission.
        if player.isSimplified {
            HStack {
                Button("Hobbies") { appUIState.showHobbiesSheet = true }
                    .buttonStyle(.bordered).font(.headline)
            }
        } else {
            HStack {

                Button("Hobbies") { appUIState.showHobbiesSheet = true }
                    .buttonStyle(.bordered).font(.headline)

                // Professional events only make sense once the player is old
                // enough to be networking into a career (college age onward).
                if player.age >= 18 {
                    Button("Events") { appUIState.showEventsSheet = true }
                        .buttonStyle(.bordered).font(.headline)
                }
            }

            HStack {

                Button("Certifications") { appUIState.showCertificationsSheet = true }
                    .buttonStyle(.bordered).font(.headline)

                Button("Licenses") { appUIState.showLicensesSheet = true }
                    .buttonStyle(.bordered).font(.headline)

                Button("Hustles & Projects") { appUIState.showSideHustlesSheet = true }
                    .buttonStyle(.bordered).font(.headline)

                // Competitions are a teen-onward pursuit (athletic / e-sports).
                if player.age >= 14 {
                    Button("Competitions") { appUIState.showCompetitionsSheet = true }
                        .buttonStyle(.bordered).font(.headline)
                }

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

            // End the run early and record the score, at any age.
            Button("Finish game") { showFinishConfirm = true }
                .buttonStyle(.bordered)
                .font(.headline)
        }
        .alert("Finish game?", isPresented: $showFinishConfirm) {
            Button("Finish & record score", role: .destructive) {
                appUIState.showRetirementSheet = true
            }
            Button("Keep playing", role: .cancel) { }
        } message: {
            Text("End your career now and record your score (savings ÷ age = \(player.leaderboardScore)). You can start over afterward.")
        }
    }
}
