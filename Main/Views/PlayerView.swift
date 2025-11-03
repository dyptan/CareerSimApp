import SwiftUI

struct ExtraActivity {
    let label: String
    let abilityKeyPaths: [WritableKeyPath<SoftSkills, Int>]
}

let schoolActivities: [ExtraActivity] = [
    ExtraActivity(
        label: "Sports",
        abilityKeyPaths: [\.physicalAbility, \.riskTolerance, \.outdoorOrientation]
    ),
    ExtraActivity(
        label: "Music band",
        abilityKeyPaths: [\.creativeExpression, \.influenceAndNetworking]
    ),
    ExtraActivity(
        label: "Photography",
        abilityKeyPaths: [\.creativeExpression]
    ),
    ExtraActivity(
        label: "Chess",
        abilityKeyPaths: [\.attentionToDetail, \.analyticalReasoning, \.resilienceCognitive]
    ),
    ExtraActivity(
        label: "Literature",
        abilityKeyPaths: [\.attentionToDetail, \.analyticalReasoning, \.teamLeadership]
    ),
    ExtraActivity(
        label: "3D simulation gaming",
        abilityKeyPaths: [\.spatialThinking, \.mechanicalOperation]
    ),
    ExtraActivity(
        label: "Economic simulation gaming",
        abilityKeyPaths: [\.spatialThinking, \.mechanicalOperation]
    ),
    ExtraActivity(
        label: "Scouting",
        abilityKeyPaths: [\.resiliencePhysical, \.outdoorOrientation]
    ),
    ExtraActivity(
        label: "Hanging out with friends",
        abilityKeyPaths: [\.socialCommunication, \.influenceAndNetworking]
    ),
    ExtraActivity(
        label: "Modeling",
        abilityKeyPaths: [\.mechanicalOperation, \.creativeExpression, \.attentionToDetail]
    ),
    ExtraActivity(
        label: "Mini-job",
        abilityKeyPaths: [\.riskTolerance, \.teamLeadership]
    ),
    ExtraActivity(
        label: "Organizing events",
        abilityKeyPaths: [\.influenceAndNetworking, \.teamLeadership, \.socialCommunication]
    ),
    ExtraActivity(
        label: "Pop‑up Stand",
        abilityKeyPaths: [\.opportunityRecognition, \.socialCommunication, \.attentionToDetail]
    ),
    ExtraActivity(
        label: "Volunteering Fundraising",
        abilityKeyPaths: [\.opportunityRecognition, \.influenceAndNetworking, \.teamLeadership]
    ),
]

struct PlayerView: View {
    @StateObject var player = Player()
    @State var showDecisionSheet = false
    @State var showTertiarySheet = false
    @State var showCareersSheet = true
    @State var selectedActivities: Set<String> = []
    @State var selectedLanguages: Set<Language> = []
    @State var selectedSoftware: Set<Software> = []
    @State var selectedLicences: Set<License> = []
    @State var selectedPortfolio: Set<PortfolioItem> = []
    @State var selectedCertifications: Set<Certification> = []
    @State var yearsLeftToGraduation: Int? = nil
    @State var descisionText = "You're 18! What's your next step?"
    @State var showRetirementSheet = false
    // New: controls Certifications & Licenses sheet
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
            HStack {
                //Soft skills
                VStack(alignment: .leading) {
                    Text("Soft skills:")
                        .font(.headline)
                    ForEach(
                        Array(SoftSkills.skillNames.enumerated()),
                        id: \.offset
                    ) { (idx, skill) in
                        HStack {
                            Text(skill.label)
                            Spacer()
                            Text(
                                String(
                                    repeating: skill.pictogram,
                                    count: player.softSkills[
                                        keyPath: skill.keyPath
                                    ]
                                )
                            )
                        }
                    }
                }.padding()
                Divider()
                Spacer()
                //Hard skills
                VStack(alignment: .leading) {
                    Text("Hard skills:").font(.headline)
                    Text("Languages: ")
                    HStack {
                        ForEach(
                            Array(
                                player.hardSkills.languages.union(
                                    selectedLanguages
                                )
                            )
                        ) { skill in
                            Text("\(skill.pictogram)")
                        }
                    }

                    Spacer()
                    Text("Portfolio: ")
                    HStack {
                        ForEach(
                            Array(
                                player.hardSkills.portfolioItems.union(
                                    selectedPortfolio
                                )
                            )
                        ) {
                            skill in
                            Text("\(skill.pictogram)")
                        }
                    }
                    Spacer()

                    // Certifications & Licenses moved to separate sheet, show compact summary + edit button
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Certifications & Licenses:")
                            HStack(spacing: 6) {
                                // show a compact preview
                                if selectedCertifications.isEmpty && selectedLicences.isEmpty {
                                    Text("None selected")
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(Array(selectedCertifications.prefix(6))) { cert in
                                        Text(cert.pictogram)
                                    }
                                    ForEach(Array(selectedLicences.prefix(6))) { lic in
                                        // quick initial badge for license
                                        Text(String(lic.rawValue.prefix(1)).uppercased())
                                    }
                                }
                            }
                        }
                        Spacer()
                        Button("Edit") {
                            showCertsLicensesSheet = true
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()
                    Text("Software: ")
                    HStack {
                        ForEach(
                            Array(
                                player.hardSkills.software.union(
                                    selectedSoftware
                                )
                            )
                        ) { skill in
                            Text("\(skill.pictogram)")
                        }
                    }

                    Spacer()
                    Text("Licenses: ")
                    HStack {
                        ForEach(
                            Array(
                                player.hardSkills.licenses.union(
                                    selectedLicences
                                )
                            )
                        ) { skill in
                            Text("\(skill.rawValue)")
                        }
                    }
                }.padding()

            }

            Divider()

            Text("Choose an activity to boost a skill:")
            HStack {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(schoolActivities, id: \.label) { activity in
                            let pictos = activity.abilityKeyPaths.compactMap { kp in
                                skillPictogramByKeyPath[kp as PartialKeyPath<SoftSkills>]
                            }.joined()

                            let atLimit = selectedActivities.count >= 3
                            let isSelected = selectedActivities.contains(activity.label)
                            
                            Toggle(
                                "\(activity.label) \(pictos)",
                                isOn: Binding(
                                    get: {
                                        isSelected
                                    },
                                    set: { isOn in
                                        if isOn && !atLimit {
                                            selectedActivities.insert(activity.label)
                                            for keyPath in activity.abilityKeyPaths {
                                                player.softSkills[keyPath: keyPath] += 1
                                            }
                                        } else {
                                            if selectedActivities.remove(activity.label) != nil {
                                                for keyPath in activity.abilityKeyPaths {
                                                    player.softSkills[keyPath: keyPath] -= 1
                                                }
                                            }
                                        }
                                    }
                                )
                            )
                            .toggleStyle(.automatic)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .disabled(!isSelected && atLimit)
                            .opacity(!isSelected && atLimit ? 0.5 : 1.0)
                            .help(atLimit && !isSelected ? "You can take up to 3 activities this year." : "")
                        }
                    }
                    //Hard skills
                    VStack(spacing: 10) {
                        Text("Languages:")
                        ForEach(
                            Array(
                                HardSkills().languages.sorted {
                                    $0.rawValue > $1.rawValue
                                }
                            )
                        ) { skill in
                            let t = Toggle(
                                skill.rawValue,
                                isOn: Binding(
                                    get: {
                                        selectedLanguages.contains(
                                            skill
                                        )
                                    },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedLanguages.insert(
                                                skill
                                            )

                                        } else {
                                            selectedLanguages.remove(
                                                skill
                                            )
                                        }
                                    }
                                )
                            ).frame(maxWidth: .infinity, alignment: .leading)
                            #if os(macOS)
                                t.toggleStyle(.checkbox)
                            #endif
                            #if os(iOS)
                                t.toggleStyle(.switch)
                            #endif

                        }

                        // Certifications & Licenses UI moved into separate sheet

                        Text("Software:")
                        ForEach(
                            Array(
                                HardSkills().software.sorted {
                                    $0.rawValue > $1.rawValue
                                }
                            )
                        ) { skill in
                            let t = Toggle(
                                skill.rawValue,
                                isOn: Binding(
                                    get: {
                                        selectedSoftware.contains(
                                            skill
                                        )
                                    },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedSoftware.insert(
                                                skill
                                            )

                                        } else {
                                            selectedSoftware.remove(
                                                skill
                                            )
                                        }
                                    }
                                )
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            #if os(macOS)
                                t.toggleStyle(.checkbox)
                            #endif
                            #if os(iOS)
                                t.toggleStyle(.switch)
                            #endif
                        }

                        Text("Portfolio Items:")
                        ForEach(
                            Array(
                                HardSkills().portfolioItems.sorted {
                                    $0.rawValue > $1.rawValue
                                }
                            )
                        ) { skill in
                            let t = Toggle(
                                skill.rawValue,
                                isOn: Binding(
                                    get: {
                                        selectedPortfolio.contains(
                                            skill
                                        )
                                    },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedPortfolio.insert(
                                                skill
                                            )

                                        } else {
                                            selectedPortfolio.remove(
                                                skill
                                            )
                                        }
                                    }
                                )
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            #if os(macOS)
                                t.toggleStyle(.checkbox)
                            #endif
                            #if os(iOS)
                                t.toggleStyle(.switch)
                            #endif
                        }

                    }

                }
                .padding(.bottom, 8)

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
                        CertificationsAndLicensesView(
                            selectedCertifications: $selectedCertifications,
                            selectedLicences: $selectedLicences
                        )
                        // Pass lockedCertifications via environment to avoid changing signature?
                        // We’ll instead pass it down via environment object:
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
        }.padding()
    }
}

