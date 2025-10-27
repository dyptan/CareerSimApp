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
    @StateObject private var player = Player()
    @State private var showDecisionSheet = false
    @State private var showTertiarySheet = false
    @State private var showCareersSheet = false
    @State private var selectedActivities: Set<String> = []
    @State private var selectedLanguages: Set<Language> = []
    @State private var selectedSoftware: Set<Software> = []
    @State private var selectedLicences: Set<License> = []
    @State private var selectedPortfolio: Set<PortfolioItem> = []
    @State private var selectedCertifications: Set<Certification> = []
    @State private var yearsLeftToGraduation: Int? = nil

    var availableCareers: [Job] {
        detailsAll.filter {
            $0.requirements.education <= player.degrees.last!.1.eqf
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Age: \(player.age)")
                        .font(.title2)
                    Spacer()
                    VStack {
                        Button("+1 Year") {
                            player.age += 1
                            player.hardSkills.certifications.formUnion(
                                selectedCertifications
                            )
                            player.hardSkills.languages.formUnion(
                                selectedLanguages
                            )
                            player.hardSkills.licenses.formUnion(
                                selectedLicences
                            )
                            player.hardSkills.portfolioItems.formUnion(
                                selectedPortfolio
                            )
                            player.hardSkills.software.formUnion(
                                selectedSoftware
                            )
                            selectedActivities = []
                            selectedLicences = []
                            selectedLanguages = []
                            selectedPortfolio = []
                            selectedSoftware = []
                            selectedCertifications = []
                            yearsLeftToGraduation? -= 1
                            if yearsLeftToGraduation == 0 {
                                showDecisionSheet.toggle()
                                if let currentEducation = player
                                    .currentEducation
                                {
                                    player.degrees.append(currentEducation)
                                }
                                yearsLeftToGraduation = nil
                                player.currentEducation = nil
                            }
                        }

                        if player.currentOccupation != nil {
                            Button("Quit Job") {
                                showDecisionSheet.toggle()
                                player.currentOccupation = nil
                            }
                        }
                    }
                }
                Text(
                    "Education Level: EQF \(player.degrees.last!.1.eqf) (\(player.degrees.last!.1.description))"
                )
                VStack {
                    if let currentOccupation = player.currentOccupation {
                        Text("Current occupation: \(currentOccupation.id)")
                    }
                    if let currentEducation = player.currentEducation {
                        VStack {
                            Text(
                                "Current Education: \(currentEducation.0.rawValue)"
                            )
                            Text(
                                "Pursuing degree: \(currentEducation.1.rawValue)"
                            )
                        }
                    }
                }

            }
            .padding(.top, 10)

            HStack {
                VStack(alignment: .leading) {
                    Text("Soft skills:")
                        .font(.headline)
                    ForEach(
                        Array(SoftSkills.skillNames.enumerated()),
                        id: \.offset
                    ) { (idx, skill) in
                        HStack {
                            Text(skill.pictogram)
                            Text(skill.label)
                            Spacer()
                            Text("\(player.softSkills[keyPath: skill.keyPath])")
                        }
                    }
                }.padding()

                VStack(alignment: .leading) {
                    Text("Hard skills:").font(.headline)
                    HStack {
                        Text("🗣️ Languages: ")
                        Spacer()
                        ForEach(
                            Array(
                                player.hardSkills.languages.union(
                                    selectedLanguages
                                )
                            )
                        ) { skill in
                            Text("\(skill.rawValue)")
                        }
                    }

                    HStack {
                        Text("🧩 Portfolio: ")
                        Spacer()
                        ForEach(
                            Array(
                                player.hardSkills.portfolioItems.union(
                                    selectedPortfolio
                                )
                            )
                        ) {
                            skill in
                            Text("\(skill.rawValue)")
                        }
                    }

                    HStack {
                        Text("📜 Certification: ")
                        Spacer()
                        ForEach(
                            Array(
                                player.hardSkills.certifications.union(
                                    selectedCertifications
                                )
                            )
                        ) {
                            skill in
                            Text("\(skill.rawValue)")
                        }
                    }

                    HStack {
                        Text("💻 Software: ")
                        Spacer()
                        ForEach(
                            Array(
                                player.hardSkills.software.union(
                                    selectedSoftware
                                )
                            )
                        ) { skill in
                            Text("\(skill.rawValue)")
                        }
                    }

                    HStack {
                        Text("🪪 Licenses:  ")
                        Spacer()
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
                }.padding([.bottom, .trailing], 20)

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

                    }
                    VStack(spacing: 10) {
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

                    }
                    VStack(spacing: 10) {
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

                    }
                    VStack(spacing: 10) {
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

                    }
                    VStack(spacing: 10) {
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
                    Text("You're 18! What's your next step?")
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

                    Button("Cancel") {
                        showDecisionSheet.toggle()
                    }
                    .foregroundStyle(.secondary)
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
                NavigationStack {

                    ScrollView {
                        VStack {
                            Text("Jobs for you")
                                .font(.title2)
                                .padding(.vertical)

                            ForEach(availableCareers) { detail in
                                NavigationLink {
                                    VStack {
                                        DetailView(detail: detail)

                                        Button("Choose this job") {
                                            player.currentOccupation = detail
                                            showCareersSheet.toggle()
                                        }.padding()
                                    }
                                } label: {
                                    DetailRow(detail: detail)
                                }
                            }
                            .listStyle(.plain)

                            Button("Close") {
                                showCareersSheet.toggle()
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .onChange(of: player.age) { oldValue, newValue in
                switch newValue {
                case 10: player.degrees.append((nil, .MiddleSchool))
                case 14: player.degrees.append((nil, .HighSchool))
                case 18: showDecisionSheet = true
                default: break
                }
            }
            .padding()
        }.padding()
    }
}
