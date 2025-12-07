import SwiftUI

struct MainView: View {
    @StateObject var player = Player()
    @State var showDecisionSheet = false
    @State var showTertiarySheet = false
    @State var showCareersSheet = false
    @State var selectedActivities: Set<String> = []
    @State var selectedSoftware: Set<Software> = []
    @State var selectedLicences: Set<License> = []
    @State var selectedPortfolio: Set<PortfolioItem> = []
    @State var selectedCertifications: Set<Certification> = []
    @State var yearsLeftToGraduation: Int? = nil
    @State var descisionText = ""
    @State var showRetirementSheet = false

    // NEW: separate sheets for each hard-skill group
    @State private var showCertificationsSheet = false
    @State private var showLicensesSheet = false
    @State private var showSoftwareSheet = false
    @State private var showPortfolioSheet = false

    @State var showSoftSkillsSheet = false

    // Use hard-coded jobs for now
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
                selectedPortfolio: $selectedPortfolio,
                selectedCertifications: $selectedCertifications,
                yearsLeftToGraduation: $yearsLeftToGraduation,
                descisionText: $descisionText
            ).padding(.bottom)

            SkillsView(
                player: player,
                selectedSoftware: $selectedSoftware,
                selectedLicences: $selectedLicences,
                selectedPortfolio: $selectedPortfolio,
                selectedCertifications: $selectedCertifications,
                showHardSkillsSheet: .constant(false),
                showSoftSkillsSheet: $showSoftSkillsSheet,
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
        }
        .sheet(isPresented: $showCareersSheet) {
            CareersSheet(
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
        // Certifications sheet
        .sheet(isPresented: $showCertificationsSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        CertificationsTrainingView(
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
                        CertificationsTrainingView(
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
        // Licenses sheet
        .sheet(isPresented: $showLicensesSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        LicensesTrainingView(
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
                        LicensesTrainingView(
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
        // Software sheet
        .sheet(isPresented: $showSoftwareSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        SoftwareTrainingView(
                            selectedSoftware: $selectedSoftware,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showSoftwareSheet = false }
                            }
                        }
                    }
                } else {
                    NavigationView {
                        SoftwareTrainingView(
                            selectedSoftware: $selectedSoftware,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showSoftwareSheet = false }
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
        // Portfolio sheet
        .sheet(isPresented: $showPortfolioSheet) {
            Group {
                if #available(iOS 16, macOS 13, *) {
                    NavigationStack {
                        PortfolioTrainingView(
                            selectedPortfolio: $selectedPortfolio,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showPortfolioSheet = false }
                            }
                        }
                    }
                } else {
                    NavigationView {
                        PortfolioTrainingView(
                            selectedPortfolio: $selectedPortfolio,
                            selectedActivities: $selectedActivities
                        )
                        .environmentObject(player)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showPortfolioSheet = false }
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
                        softSkillsContent
                            .navigationTitle("Participate in activities: ")
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
                        softSkillsContent
                            .navigationTitle("Participate in activities: ")
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

                // Degrees summary
                let degreeCount = player.degrees.count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Degrees earned: \(degreeCount)")
                        .font(.headline)

                    ForEach(
                        Array(player.degrees.enumerated()),
                        id: \.offset
                    ) { _, entry in
                        Text("• \(entry.degreeName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Work history")
                        .font(.headline)

                    ForEach(
                        Array(player.jobExperiance.enumerated()),
                        id: \.offset
                    ) { _, item in
                        Text("• \(item.1) years as \(item.0.id)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("Money earned: \(player.savings)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showRetirementSheet = false
                    let newPlayer = Player()
                    selectedActivities = []
                    selectedSoftware = []
                    selectedLicences = []
                    selectedPortfolio = []
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
            Button("Activities") {
                showSoftSkillsSheet = true
            }
            .buttonStyle(.bordered).font(.headline)
        }

        // Distinct hard-skill buttons
        HStack {
            Button("Portfolio") { showPortfolioSheet = true }
                .buttonStyle(.bordered).font(.headline)

            Button("Software") { showSoftwareSheet = true }
                .buttonStyle(.bordered).font(.headline)

            Button("Certifications") { showCertificationsSheet = true }
                .buttonStyle(.bordered).font(.headline)

            Button("Licenses") { showLicensesSheet = true }
                .buttonStyle(.bordered).font(.headline)
        }

        HStack {
            Button("Jobs") {
                showCareersSheet.toggle()
            }.buttonStyle(.bordered).font(.headline).frame(
                alignment: .trailing
            )

            Button("Degrees") {
                showTertiarySheet.toggle()
            }.buttonStyle(.bordered).font(.headline).frame(
                alignment: .trailing
            )

        }
        
        Button("+1 Year") {
            // Advance year
            player.age += 1

            // Persist this year's learning into the player's permanent hard skills
            player.hardSkills.certifications.formUnion(selectedCertifications)
            player.hardSkills.licenses.formUnion(selectedLicences)
            player.hardSkills.portfolioItems.formUnion(selectedPortfolio)
            player.hardSkills.software.formUnion(selectedSoftware)

            // Lock learned items so they won't be available next years
            player.lockedCertifications.formUnion(selectedCertifications)
            player.lockedPortfolio.formUnion(selectedPortfolio)
            player.lockedSoftware.formUnion(selectedSoftware)

            // Clear all in-progress selections for the new year
            selectedActivities.removeAll()
            selectedSoftware.removeAll()
            selectedLicences.removeAll()
            selectedPortfolio.removeAll()
            selectedCertifications.removeAll()

            // Education progress
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
                // income is full dollars now
                player.savings += income
            }
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom, 8)
        .font(.headline)

    }

    private var softSkillsContent: some View {
        ScrollView {
            ActivitiesView(
                player: player,
                selectedActivities: $selectedActivities,
                selectedSoftware: $selectedSoftware,
                selectedPortfolio: $selectedPortfolio
            )
            .environmentObject(player)
            .padding()
        }
    }
}

#Preview {
    MainView()
}
