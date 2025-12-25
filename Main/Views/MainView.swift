import SwiftUI

struct MainView: View {
    @StateObject var player = Player()
    @State var showDecisionSheet = false
    @State var showTertiarySheet = false
    @State var showCareersSheet = false
    @State var selectedActivities: Set<String> = []
    @State var selectedSoftware: Set<Software> = []
    @State var selectedLicences: Set<License> = []
    @State var selectedProjects: Set<Project> = []
    @State var selectedCertifications: Set<Certification> = []
    @State var yearsLeftToGraduation: Int? = nil
    @State var descisionText = ""
    @State var showRetirementSheet = false
    @State private var showCertificationsSheet = false
    @State private var showLicensesSheet = false
    @State private var showCourcesSheet = false
    @State private var showProjectsSheet = false

    @State var showSoftSkillsSheet = false

    private var availableJobs: [Job] {
        HardcodedJobs.sampleJobs()
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
                showDecisionSheet: $showDecisionSheet,
                showTertiarySheet: $showTertiarySheet,
                showCareersSheet: $showCareersSheet,
                selectedActivities: $selectedActivities,
                selectedSoftware: $selectedSoftware,
                selectedLicences: $selectedLicences,
                selectedPortfolio: $selectedProjects,
                selectedCertifications: $selectedCertifications,
                yearsLeftToGraduation: $yearsLeftToGraduation,
                descisionText: $descisionText
            ).padding(.bottom)

            SkillsSection(
                player: player,
                selectedSoftware: $selectedSoftware,
                selectedLicences: $selectedLicences,
                selectedPortfolio: $selectedProjects,
                selectedCertifications: $selectedCertifications,
                showCareersSheet: $showCareersSheet,
                showTertiarySheet: $showTertiarySheet
            )

        }
        .sheet(isPresented: $showDecisionSheet) {
            VStack(spacing: 18) {
                Text(descisionText)
                    .font(.title2)
                    .padding()
                Button {
                    showDecisionSheet = false
                    showTertiarySheet = true
                } label: {
                    Text("Enter College / University")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showDecisionSheet = false
                    showCareersSheet = true
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
        .sheet(isPresented: $showTertiarySheet) {
            EducationView(
                player: player,
                yearsLeftToGraduation: $yearsLeftToGraduation,
                showTertiarySheet: $showTertiarySheet,
                showCareersSheet: $showCareersSheet
            )
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif

            Button("Close") {
                showTertiarySheet = false
            }
            .padding()
        }
        .sheet(isPresented: $showCareersSheet) {
            JobsView(
                availableJobs: availableJobs,
                player: player,
                showCareersSheet: $showCareersSheet
            )
            .frame(idealHeight: 500, alignment: .leading)
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 500)
            #endif

            Button("Close") {
                showCareersSheet = false
            }.padding()
        }
        .sheet(isPresented: $showCertificationsSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        CertificationsView(
                            selectedCertifications: $selectedCertifications,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showCertificationsSheet = false }
                            }
                        }
                    }
                } else {
                    NavigationView {
                        CertificationsView(
                            selectedCertifications: $selectedCertifications,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showCertificationsSheet = false }
                            }
                        }
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
        .sheet(isPresented: $showLicensesSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        LicensesView(
                            selectedLicences: $selectedLicences,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showLicensesSheet = false }
                            }
                        }
                    }
                } else {
                    NavigationView {
                        LicensesView(
                            selectedLicences: $selectedLicences,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showLicensesSheet = false }
                            }
                        }
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
        .sheet(isPresented: $showCourcesSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        CoursesView(
                            selectedSoftware: $selectedSoftware,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showCourcesSheet = false }
                            }
                        }
                    }
                } else {
                    NavigationView {
                        CoursesView(
                            selectedSoftware: $selectedSoftware,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showCourcesSheet = false }
                            }
                        }
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
        .sheet(isPresented: $showProjectsSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        ProjectsView(
                            selectedPortfolio: $selectedProjects,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showProjectsSheet = false }
                            }
                        }
                    }
                } else {
                    NavigationView {
                        ProjectsView(
                            selectedPortfolio: $selectedProjects,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showProjectsSheet = false }
                            }
                        }
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
        .sheet(isPresented: $showSoftSkillsSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        activitiesView
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") {
                                        showSoftSkillsSheet = false
                                    }
                                }
                            }
                    }
                } else {
                    NavigationView {
                        activitiesView
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Done") {
                                        showSoftSkillsSheet = false
                                    }
                                }
                            }
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
        .sheet(isPresented: $showRetirementSheet) {
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
                    showRetirementSheet = false
                    let newPlayer = Player()
                    selectedActivities = []
                    selectedSoftware = []
                    selectedLicences = []
                    selectedProjects = []
                    selectedCertifications = []
                    yearsLeftToGraduation = nil
                    descisionText = "You're 18! What's your next step?"
                    showDecisionSheet = false
                    showTertiarySheet = false
                    showCareersSheet = true
                    // Assign the new player last to trigger UI refresh
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
                descisionText = "You're 18! What's your next step?"
                player.degrees.append(Education(Level.Stage.HighSchool))
                showDecisionSheet.toggle()
            case 68: showRetirementSheet.toggle()
            default: break
            }
        }
        .padding()

        Divider()
        HStack {
        
            Button("Projects") { showProjectsSheet = true }
                .buttonStyle(.bordered).font(.headline)

            Button("Courses") { showCourcesSheet = true }
                .buttonStyle(.bordered).font(.headline)

            Button("Certifications") { showCertificationsSheet = true }
                .buttonStyle(.bordered).font(.headline)

            Button("Licenses") { showLicensesSheet = true }
                .buttonStyle(.bordered).font(.headline)
        }

        HStack {
            Button("Activities") { showSoftSkillsSheet = true }
                .buttonStyle(.bordered).font(.headline)
            
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

        }
        
        Button("To next year") {
            player.age += 1
            player.hardSkills.certifications.formUnion(selectedCertifications)
            player.hardSkills.licenses.formUnion(selectedLicences)
            player.hardSkills.portfolioItems.formUnion(selectedProjects)
            player.hardSkills.software.formUnion(selectedSoftware)

            player.lockedCertifications.formUnion(selectedCertifications)
            player.lockedPortfolio.formUnion(selectedProjects)
            player.lockedSoftware.formUnion(selectedSoftware)

            selectedActivities.removeAll()
            selectedSoftware.removeAll()
            selectedLicences.removeAll()
            selectedProjects.removeAll()
            selectedCertifications.removeAll()

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
        .padding(.bottom, 8)
        .font(.headline)

    }

    private var activitiesView: some View {
            ActivitiesView(
                player: player,
                selectedActivities: $selectedActivities,
                selectedSoftware: $selectedSoftware,
                selectedPortfolio: $selectedProjects
            )
            .environmentObject(player)
            .padding()
    }
}

#Preview {
    MainView()
}

