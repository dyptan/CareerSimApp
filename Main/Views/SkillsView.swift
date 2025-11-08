import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player

    @Binding var selectedLanguages: Set<Language>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedCertifications: Set<Certification>

    // Controls the Certifications & Licenses sheet in the parent
    @Binding var showCertsLicensesSheet: Bool

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(uniqueKeysWithValues: SoftSkills.skillNames.map { ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram) })
    }

    var body: some View {
        HStack {
            // Soft skills
            VStack(alignment: .leading) {
                Text("Soft skills:")
                    .font(.headline)
                ForEach(
                    Array(SoftSkills.skillNames.enumerated()),
                    id: \.offset
                ) { (_, skill) in
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
            }
            .padding()

            Divider()
            Spacer()

            // Hard skills
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
                    ) { skill in
                        Text("\(skill.pictogram)")
                    }
                }

                Spacer()

                // Certifications & Licenses summary + edit button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Certifications & Licenses:")
                        HStack(spacing: 6) {
                            if selectedCertifications.isEmpty && selectedLicences.isEmpty {
                                Text("None selected")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(Array(selectedCertifications.prefix(6))) { cert in
                                    Text(cert.pictogram)
                                }
                                ForEach(Array(selectedLicences.prefix(6))) { lic in
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
            }
            .padding()
        }
    }
}

#Preview {
    SkillsView(
        player: Player(),
        selectedLanguages: .constant([]),
        selectedSoftware: .constant([]),
        selectedLicences: .constant([]),
        selectedPortfolio: .constant([]),
        selectedCertifications: .constant([]),
        showCertsLicensesSheet: .constant(false)
    )
    .padding()
}
