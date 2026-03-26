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
            case 10: player.degrees.append(Education(Level.Stage.PrimarySchool))
            case 14: player.degrees.append(Education(Level.Stage.MiddleSchool))
            case 18:
                appUIState.decisionText = "You're 18! What's your next step?"
                player.degrees.append(Education(Level.Stage.HighSchool))
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
            .environmentObject(player)
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { appUIState.showActivitiesSheet = false }
                }
            }
    }

    private var certificationsContent: some View {
        CertificationsView(
            selectedCertifications: $appUIState.selectedCertifications,
            selectedActivities: $appUIState.selectedActivities
        )
        .environmentObject(player)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showCertificationsSheet = false }
            }
        }
    }

    private var licensesContent: some View {
        LicensesView(
            selectedLicenses: $appUIState.selectedLicenses,
            selectedActivities: $appUIState.selectedActivities
        )
        .environmentObject(player)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showLicensesSheet = false }
            }
        }
    }

    private var coursesContent: some View {
        CoursesView(
            selectedSoftware: $appUIState.selectedSoftware,
            selectedActivities: $appUIState.selectedActivities
        )
        .environmentObject(player)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showCoursesSheet = false }
            }
        }
    }

    private var projectsContent: some View {
        ProjectsView(
            selectedPortfolio: $appUIState.selectedPortfolio,
            selectedActivities: $appUIState.selectedActivities
        )
        .environmentObject(player)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showProjectsSheet = false }
            }
        }
    }
}

// MARK: - Decision sheet

private struct DecisionView: View {
    @ObservedObject var appUIState: AppUIState

    var body: some View {
        VStack(spacing: 18) {
            Text(appUIState.decisionText)
                .font(.title2)
                .padding()

            Button {
                appUIState.showDecisionSheet = false
                appUIState.showTertiarySheet = true
            } label: {
                Text("Enter College / University")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                appUIState.showDecisionSheet = false
                appUIState.showCareersSheet = true
            } label: {
                Text("Find a Job")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Retirement sheet

private struct RetirementView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    var body: some View {
        VStack(spacing: 16) {
            Text("Retirement")
                .font(.title2.bold())
                .padding(.top)

            Text("You've retired at age \(player.age).")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Money earned: \(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                player.reset()
                appUIState.showRetirementSheet = false
                appUIState.selectedActivities = []
                appUIState.selectedSoftware = []
                appUIState.selectedLicenses = []
                appUIState.selectedPortfolio = []
                appUIState.selectedCertifications = []
                appUIState.yearsLeftToGraduation = nil
                appUIState.decisionText = ""
                appUIState.showDecisionSheet = false
                appUIState.showTertiarySheet = false
                appUIState.showCareersSheet = true
            } label: {
                Text("Restart")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 400)
        #endif
    }
}

#Preview {
    MainView()
}
