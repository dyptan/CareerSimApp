import SwiftUI

struct MainView: View {
    @StateObject var player = Player()
    @State var showDecisionSheet = false
    @State var showTertiarySheet = false
    @State var showCareersSheet = false
    @State var selectedActivities: Set<String> = []
    @State var selectedLanguages: Set<ProgrammingLanguage> = []
    @State var selectedSoftware: Set<Software> = []
    @State var selectedLicences: Set<License> = []
    @State var selectedPortfolio: Set<PortfolioItem> = []
    @State var selectedCertifications: Set<Certification> = []
    @State var yearsLeftToGraduation: Int? = nil
    @State var descisionText = "You're 18! What's your next step?"
    @State var showRetirementSheet = false
    @State var showHardSkillsSheet = false
    @State var showSoftSkillsSheet = false

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
                selectedLanguages: $selectedLanguages,
                selectedSoftware: $selectedSoftware,
                selectedLicences: $selectedLicences,
                selectedPortfolio: $selectedPortfolio,
                selectedCertifications: $selectedCertifications,
                yearsLeftToGraduation: $yearsLeftToGraduation,
                descisionText: $descisionText
            ).padding(.bottom)

            SkillsView(
                player: player,
                selectedLanguages: $selectedLanguages,
                selectedSoftware: $selectedSoftware,
                selectedLicences: $selectedLicences,
                selectedPortfolio: $selectedPortfolio,
                selectedCertifications: $selectedCertifications,
                showHardSkillsSheet: $showHardSkillsSheet,
                showSoftSkillsSheet: $showSoftSkillsSheet,
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
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTertiarySheet) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Pick your education direction")
                        .font(.title2)
                        .padding(.vertical)
                    ForEach(TertiaryProfile.allCases) { profile in
                        if let next = player.degrees.last?.1.next {
                            HStack {
                                ForEach(next) { level in
                                    Button {
                                        player.currentEducation = (
                                            profile, level
                                        )
                                        player.currentOccupation = nil
                                        yearsLeftToGraduation =
                                            level.yearsToComplete()
                                        showTertiarySheet.toggle()
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(profile.rawValue)
                                                .font(.headline)
                                            Text(profile.description)
                                                .font(.caption)
                                            Text(level.rawValue)
                                        }
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                    Button("Find a job") {
                        showTertiarySheet = false
                        showCareersSheet = true
                    }
                    .foregroundStyle(.secondary)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCareersSheet) {
            CareersSheet(
                availableJobs: jobs,
                player: player,
                showCareersSheet: $showCareersSheet
            )
            .frame(idealHeight: 500, alignment: .leading)

            Button("Close") {
                showCareersSheet = false
            }.padding()
        }
        .sheet(isPresented: $showHardSkillsSheet) {
            NavigationStack {
                ScrollView {
                    HardSkillsView(
                        selectedCertifications: $selectedCertifications,
                        selectedLicences: $selectedLicences,
                        selectedLanguages: $selectedLanguages,
                        selectedSoftware: $selectedSoftware,
                        selectedPortfolio: $selectedPortfolio,
                        selectedActivities: $selectedActivities
                    )
                    .environmentObject(player)
                    .padding()
                }
                .navigationTitle("Sign up for training")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showHardSkillsSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSoftSkillsSheet) {
            NavigationStack {
                ScrollView {
                    ActivitiesView(
                        player: player,
                        selectedActivities: $selectedActivities,
                        selectedLanguages: $selectedLanguages,
                        selectedSoftware: $selectedSoftware,
                        selectedPortfolio: $selectedPortfolio
                    )
                    .environmentObject(player)
                    .padding()
                }
                .navigationTitle("Participate in activities: ")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showSoftSkillsSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
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
                        Text("• \(entry.1.degree)")
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
                    selectedLanguages = []
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
                    player.degrees = newPlayer.degrees
                    player.jobExperiance = newPlayer.jobExperiance
                    player.softSkills = newPlayer.softSkills
                    player.hardSkills = newPlayer.hardSkills
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
            .presentationDetents([.medium])
        }
        .onChange(of: player.age) { oldValue, newValue in
            switch newValue {
            case 10: player.degrees.append((nil, .PrimarySchool))
            case 14: player.degrees.append((nil, .MiddleSchool))
            case 18:
                player.degrees.append((nil, .HighSchool))
                showDecisionSheet.toggle()
            case 68: showRetirementSheet.toggle()
            default: break
            }
        }
        .padding()

        Spacer()
        
        Button("+1 Year") {
            // Advance year
            player.age += 1

            // Persist this year's learning into the player's permanent hard skills
            player.hardSkills.certifications.formUnion(selectedCertifications)
            player.hardSkills.languages.formUnion(selectedLanguages)
            player.hardSkills.licenses.formUnion(selectedLicences)
            player.hardSkills.portfolioItems.formUnion(selectedPortfolio)
            player.hardSkills.software.formUnion(selectedSoftware)

            // Lock learned items so they won't be available next years
            player.lockedCertifications.formUnion(selectedCertifications)
            player.lockedLanguages.formUnion(selectedLanguages)
            player.lockedLicenses.formUnion(selectedLicences)
            player.lockedPortfolio.formUnion(selectedPortfolio)
            player.lockedSoftware.formUnion(selectedSoftware)

            // Clear all in-progress selections for the new year
            selectedActivities.removeAll()
            selectedLanguages.removeAll()
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

            // Income
            if let income = player.currentOccupation?.income {
                player.savings += income
            }
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .font(.headline)
    }
}
