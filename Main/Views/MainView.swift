import SwiftUI

struct MainView: View {
    @StateObject var player = Player()
    @State var showDecisionSheet = false
    @State var showTertiarySheet = false
    @State var showCareersSheet = false
    @State var selectedActivities: Set<String> = []
    @State var selectedLanguages: Set<Language> = []
    @State var selectedSoftware: Set<Software> = []
    @State var selectedLicences: Set<License> = []
    @State var selectedPortfolio: Set<PortfolioItem> = []
    @State var selectedCertifications: Set<Certification> = []
    @State var yearsLeftToGraduation: Int? = nil
    @State var descisionText = "You're 18! What's your next step?"
    @State var showRetirementSheet = false
    @State private var showCertsLicensesSheet = false
    
    func availableJobs() -> [Job] {
        detailsAll
    }
    
    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(uniqueKeysWithValues: SoftSkills.skillNames.map { ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram) })
    }
    
    private var aggregatedJobYears: [(job: Job, years: Int)] {
        var dict: [Job: Int] = [:]
        for (job, years) in player.jobExperiance {
            dict[job, default: 0] += years
        }
        return
        dict
            .map { ($0.key, $0.value) }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.id < rhs.0.id
            }
    }
    
    var body: some View {
        VStack(spacing: 16) {
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
            )
            
            // Extracted Skills view
            SkillsView(
                player: player,
                selectedLanguages: $selectedLanguages,
                selectedSoftware: $selectedSoftware,
                selectedLicences: $selectedLicences,
                selectedPortfolio: $selectedPortfolio,
                selectedCertifications: $selectedCertifications,
                showCertsLicensesSheet: $showCertsLicensesSheet
            )
            
            Divider()
            
            Text("Choose an activity to boost a skill:")
            
            // Combined Activities + Hard-skill selection view
            ActivitiesView(
                player: player,
                selectedActivities: $selectedActivities,
                selectedLanguages: $selectedLanguages,
                selectedSoftware: $selectedSoftware,
                selectedPortfolio: $selectedPortfolio
            )
            
            // Right side remains as in your layout; if you intended only one column,
            // you can remove this Spacer and keep the single ActivitiesView.
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
            CareersSheet(availableJobs: availableJobs(), player: player, showCareersSheet: $showCareersSheet)
                .frame(idealHeight: 500, alignment: .leading)
            
            Button("Close") {
                showCareersSheet = false
            }.padding()
        }
        // New: certifications & licenses sheet
        .sheet(isPresented: $showCertsLicensesSheet) {
            NavigationStack {
                ScrollView {
                    HardStillsView(
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
                .navigationTitle("Certifications & Licenses")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showCertsLicensesSheet = false }
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
                
                // Work history summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Work history")
                        .font(.headline)
                    
                    ForEach(
                        Array(aggregatedJobYears.enumerated()),
                        id: \.offset
                    ) { _, item in
                        Text("• \(item.job.id) — \(item.years) years")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let lastDegree = player.degrees.last {
                    Text("Highest education: \(lastDegree.1.degree)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let job = player.currentOccupation {
                    Text("Last occupation: \(job.id)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
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
        
    }
}
