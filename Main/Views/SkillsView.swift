import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player

    @Binding var selectedLanguages: Set<Language>
    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedCertifications: Set<Certification>

    // Controls the Certifications & Licenses sheet in the parent
    @Binding var showHardSkillsSheet: Bool
    @Binding var showSoftSkillsSheet: Bool

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }
    
    // Skill proficiency to emoji mapping
    private func emojiForLevel(_ value: Int) -> String {
        switch value {
        case ..<2: return "☹️"     // none
        case 2: return "🙁"    // weak
        case 3: return "😐"    // okay
        case 4: return "🙂"    // high
        case 5: return "😀"    // high
        case 6: return "😁"    // high
        case 7: return "😎"    // high
        default: return "👑"       // very high
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Hard skills

            Button("Hard skills") {
                showHardSkillsSheet = true
            }
            .buttonStyle(.bordered)

            HStack {
                Text("Languages: ")
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

            HStack {
                Text("Portfolio: ")
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

            // Certifications & Licenses summary + edit button
            HStack {
                Text("Certifications & Licenses:")

                ForEach(
                    Array(
                        selectedCertifications.union(
                            player.hardSkills.certifications
                        )
                    )
                ) { cert in
                    Text(cert.pictogram)
                }

                ForEach(
                    Array(
                        selectedLicences.union(
                            player.hardSkills.licenses
                        )
                    )
                ) { lic in
                    Text(lic.pictogram)
                }
            }

            HStack {
                Text("Software: ")
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

            Divider()

            // Soft skills
            VStack(alignment: .leading) {

                Button("Soft skills") {
                    showSoftSkillsSheet = true
                }
                .buttonStyle(.bordered).font(.headline)
                ForEach(
                    Array(SoftSkills.skillNames.enumerated()),
                    id: \.offset
                ) { (_, skill) in
                    HStack {
                        Text(skill.label)
                        Spacer()
                        // Use proficiency-mapped emoji here!
                        Text(emojiForLevel(player.softSkills[keyPath: skill.keyPath]))
                    }
                }
            }

            SkillEmojiCloudView(player: player)
                .frame(height: 180)
                .padding(.top, 8)
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
        showHardSkillsSheet: .constant(false),
        showSoftSkillsSheet: .constant(false)
    )
    .padding()
}
