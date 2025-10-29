import SwiftUI

struct ExtraActivity {
    let label: String
    let prerequisite: [SoftSkills]
    let abilityKeyPath: WritableKeyPath<SoftSkills, Int>
}

let schoolActivities: [ExtraActivity] = [
    ExtraActivity(
        label: "Sports",
        prerequisite: [],
        abilityKeyPath: \.physicalAbility
    ),
    ExtraActivity(
        label: "Music",
        prerequisite: [],
        abilityKeyPath: \.creativeExpression
    ),
    ExtraActivity(
        label: "Painting",
        prerequisite: [],
        abilityKeyPath: \.creativeExpression
    ),
    ExtraActivity(
        label: "Chess",
        prerequisite: [],
        abilityKeyPath: \.attentionToDetail
    ),
    ExtraActivity(
        label: "Reading",
        prerequisite: [],
        abilityKeyPath: \.creativeExpression
    ),
    ExtraActivity(
        label: "Gaming",
        prerequisite: [],
        abilityKeyPath: \.spatialThinking
    ),
    ExtraActivity(
        label: "Hanging out with friends",
        prerequisite: [],
        abilityKeyPath: \.socialCommunication
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

    func availableJobs() -> [Job] {
        detailsAll
    }
    

    // Aggregated job experience: total years per Job
    private var aggregatedJobYears: [(job: Job, years: Int)] {
        var dict: [Job: Int] = [:]
        for (job, years) in player.jobExperiance {
            dict[job, default: 0] += years
        }
        // Sort by years desc, then by id for stable order
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
                    Text("Certifications: ")

                    HStack {
                        ForEach(
                            Array(
                                player.hardSkills.certifications.union(
                                    selectedCertifications
                                )
                            )
                        ) {
                            skill in
                            Text("\(skill.pictogram)")
                        }
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
                            Toggle(
                                activity.label,
                                isOn: Binding(
                                    get: {
                                        selectedActivities.contains(
                                            activity.label
                                        )
                                    },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedActivities.insert(
                                                activity.label
                                            )
                                            player.softSkills[
                                                keyPath: activity.abilityKeyPath
                                            ] += 1

                                        } else {
                                            selectedActivities.remove(
                                                activity.label
                                            )
                                            player.softSkills[
                                                keyPath: activity.abilityKeyPath
                                            ] -= 1

                                        }
                                    }
                                )
                            )
                            .toggleStyle(.automatic)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                        Text("Certifications:")
                        ForEach(
                            Array(
                                HardSkills().certifications.sorted {
                                    $0.rawValue > $1.rawValue
                                }
                            )
                        ) { skill in
                            let t = Toggle(
                                skill.rawValue,
                                isOn: Binding(
                                    get: {
                                        selectedCertifications.contains(
                                            skill
                                        )
                                    },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedCertifications.insert(
                                                skill
                                            )

                                        } else {
                                            selectedCertifications.remove(
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

                        Text("Licenses:")
                        ForEach(
                            Array(
                                HardSkills().licenses.sorted {
                                    $0.rawValue > $1.rawValue
                                }
                            )
                        ) { skill in
                            let t = Toggle(
                                skill.rawValue,
                                isOn: Binding(
                                    get: {
                                        selectedLicences.contains(
                                            skill
                                        )
                                    },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedLicences.insert(
                                                skill
                                            )

                                        } else {
                                            selectedLicences.remove(
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
                    } label: {
                        Text("Close")
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
                case 80: showRetirementSheet.toggle()
                default: break
                }
            }
            .padding()
        }.padding()
    }
}


