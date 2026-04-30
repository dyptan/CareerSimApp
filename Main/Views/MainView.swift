import SwiftUI

struct MainView: View {
    @StateObject var player = Player()
    @StateObject var appUIState = AppUIState()

    private var availableJobs: [Job] {
        JobExamples.sampleJobs()
    }

    var body: some View {
        VStack(alignment: .leading) {
            HeaderView(player: player, appUIState: appUIState)
                .padding(.bottom)

            Divider()
            Spacer()

            SkillsView(player: player, appUIState: appUIState)

            Spacer()
            Divider()

            FooterView(player: player, appUIState: appUIState)
                .padding(.bottom)
        }
        .sheet(isPresented: $appUIState.showDecisionSheet) {
            DecisionView(appUIState: appUIState)
        }
        .sheet(isPresented: $appUIState.showTertiarySheet) {
            EducationView(
                player: player,
                yearsLeftToGraduation: $appUIState.yearsLeftToGraduation,
                showTertiarySheet: $appUIState.showTertiarySheet,
                showCareersSheet: $appUIState.showCareersSheet
            )
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif

            Button("Close") { appUIState.showTertiarySheet = false }
                .padding()
        }
        .sheet(isPresented: $appUIState.showCareersSheet) {
            JobsView(
                availableJobs: availableJobs,
                player: player,
                showCareersSheet: $appUIState.showCareersSheet
            )
            .frame(idealHeight: 500, alignment: .leading)
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif

            Button("Close") { appUIState.showCareersSheet = false }
                .padding()
        }
        .sheet(isPresented: $appUIState.showCertificationsSheet) {
            navigationSheet { certificationsContent }
        }
        .sheet(isPresented: $appUIState.showLicensesSheet) {
            navigationSheet { licensesContent }
        }
        .sheet(isPresented: $appUIState.showCoursesSheet) {
            navigationSheet { coursesContent }
        }
        .sheet(isPresented: $appUIState.showProjectsSheet) {
            navigationSheet { projectsContent }
        }
        .sheet(isPresented: $appUIState.showActivitiesSheet) {
            navigationSheet { activitiesContent }
        }
        .sheet(isPresented: $appUIState.showRetirementSheet) {
            RetirementView(player: player, appUIState: appUIState)
        }
        .onChange(of: player.age) { newValue in
            switch newValue {
            case 10:
                player.degrees.append(Education(Level.Stage.PrimarySchool))
                player.currentEducation = Education(Level.Stage.MiddleSchool)
            case 14:
                player.degrees.append(Education(Level.Stage.MiddleSchool))
                player.currentEducation = Education(Level.Stage.HighSchool)
            case 18:
                appUIState.decisionText = "You're 18! What's your next step?"
                player.degrees.append(Education(Level.Stage.HighSchool))
                player.currentEducation = nil
                appUIState.showDecisionSheet.toggle()
            case 68: appUIState.showRetirementSheet.toggle()
            default: break
            }
        }
        .padding()
    }

    // MARK: - Navigation sheet wrapper

    @ViewBuilder
    private func navigationSheet<C: View>(@ViewBuilder content: () -> C) -> some View {
        Group {
            if #available(iOS 16, macOS 13, *) {
                NavigationStack { content() }
            } else {
                NavigationView { content() }
                #if os(iOS)
                .navigationViewStyle(.stack)
                #endif
            }
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 500)
        #endif
    }

    // MARK: - Sheet content

    private var activitiesContent: some View {
        ActivitiesView(player: player, selectedActivities: $appUIState.selectedActivities)
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { appUIState.showActivitiesSheet = false }
                }
            }
    }

    private var certificationsContent: some View {
        CertificationsView(
            player: player,
            selectedCertifications: $appUIState.selectedCertifications,
            selectedActivities: $appUIState.selectedActivities
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showCertificationsSheet = false }
            }
        }
    }

    private var licensesContent: some View {
        LicensesView(
            player: player,
            selectedLicenses: $appUIState.selectedLicenses,
            selectedActivities: $appUIState.selectedActivities
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showLicensesSheet = false }
            }
        }
    }

    private var coursesContent: some View {
        CoursesView(
            player: player,
            selectedSoftware: $appUIState.selectedSoftware,
            selectedActivities: $appUIState.selectedActivities
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showCoursesSheet = false }
            }
        }
    }

    private var projectsContent: some View {
        ProjectsView(
            player: player,
            selectedPortfolio: $appUIState.selectedPortfolio,
            selectedActivities: $appUIState.selectedActivities
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showProjectsSheet = false }
            }
        }
    }
}

#Preview {
    MainView()
}
