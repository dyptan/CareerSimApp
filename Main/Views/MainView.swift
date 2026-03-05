import SwiftUI

struct MainView: View {
    @StateObject var player = Player()
    @StateObject var appUIState = AppUIState()
    
    private var availableJobs: [Job] {
        JobExamples.sampleJobs()
    }

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            HeaderView(
                player: player,
                appUIState: appUIState
            ).padding(.bottom)

            Divider()
            Spacer()
            SkillsView(
                player: player,
                appUIState: appUIState
            )
            
            Spacer()
            Divider()

            FooterView(
                player: player,
                appUIState: appUIState
            ).padding(.bottom)

        }
        .sheet(isPresented: $appUIState.showDecisionSheet) {
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

            Button("Close") {
                appUIState.showTertiarySheet = false
            }
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

            Button("Close") {
                appUIState.showCareersSheet = false
            }.padding()
        }
        .sheet(isPresented: $appUIState.showCertificationsSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        certificationsContent
                    }
                } else {
                    NavigationView {
                        certificationsContent
                    }
                    #if os(iOS)
                    .navigationViewStyle(.stack)
                    #endif
                }
            }
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        }
        .sheet(isPresented: $appUIState.showLicencesSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        licensesContent
                    }
                } else {
                    NavigationView {
                        licensesContent
                    }
                    #if os(iOS)
                    .navigationViewStyle(.stack)
                    #endif
                }
            }
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        }
        .sheet(isPresented: $appUIState.showCourcesSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        coursesContent
                    }
                } else {
                    NavigationView {
                        coursesContent
                    }
                    #if os(iOS)
                    .navigationViewStyle(.stack)
                    #endif
                }
            }
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        }
        .sheet(isPresented: $appUIState.showProjectsSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        projectsContent
                    }
                } else {
                    NavigationView {
                        projectsContent
                    }
                    #if os(iOS)
                    .navigationViewStyle(.stack)
                    #endif
                }
            }
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        }
        .sheet(isPresented: $appUIState.showSoftSkillsSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        softSkillsContent
                    }
                } else {
                    NavigationView {
                        softSkillsContent
                    }
                    #if os(iOS)
                        .navigationViewStyle(.stack)
                    #endif
                }
            }
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif
        }
        .sheet(isPresented: $appUIState.showRetirementSheet) {
            VStack(spacing: 16) {
                Text("Retirement")
                    .font(.title2.bold())
                    .padding(.top)

                Text("You’ve retired at age \(player.age).")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Money earned: \(player.savings)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    let newPlayer = Player()
                    appUIState.showRetirementSheet = false
                    appUIState.selectedActivities = []
                    appUIState.selectedSoftware = []
                    appUIState.selectedLicences = []
                    appUIState.selectedPortfolio = []
                    appUIState.selectedCertifications = []
                    appUIState.yearsLeftToGraduation = nil
                    appUIState.decisionText = "You're 18! What's your next step?"
                    appUIState.showDecisionSheet = false
                    appUIState.showTertiarySheet = false
                    appUIState.showCareersSheet = true
                    player.age = newPlayer.age
                    player.softSkills = newPlayer.softSkills
                    player.hardSkills = newPlayer.hardSkills
                    player.degrees = newPlayer.degrees
                    player.jobExperiance = newPlayer.jobExperiance
                    player.currentOccupation = newPlayer.currentOccupation
                    player.currentEducation = newPlayer.currentEducation
                    player.savings = newPlayer.savings
                    player.lockedCertifications = newPlayer.lockedCertifications
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


    private var softSkillsContent: some View {
        ActivitiesView(
            player: player,
            selectedActivities: $appUIState.selectedActivities
        )
        .environmentObject(player)
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    appUIState.showSoftSkillsSheet = false
                }
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
            selectedLicences: $appUIState.selectedLicences,
            selectedActivities: $appUIState.selectedActivities
        )
        .environmentObject(player)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { appUIState.showLicencesSheet = false }
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
                Button("Close") { appUIState.showCourcesSheet = false }
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

#Preview {
    MainView()
}
