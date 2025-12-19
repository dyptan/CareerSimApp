import SwiftUI

struct SkillsSection: View {
    @ObservedObject var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedCertifications: Set<Certification>
    @Binding var showCareersSheet: Bool
    @Binding var showTertiarySheet: Bool

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    var body: some View {

        ScrollView {

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

            Divider()

            if !player.hardSkills.portfolioItems.isEmpty {
                Text("Portfolio")
            }

            ForEach(
                Array(
                    player.hardSkills.portfolioItems.union(
                        selectedPortfolio
                    )
                )
            ) { skill in
                Text("\(skill.id) \(skill.pictogram)")
            }

            if !player.hardSkills.certifications.isEmpty {
                Text("Certifications")
            }

            ForEach(
                Array(
                    selectedCertifications.union(
                        player.hardSkills.certifications
                    )
                )
            ) { cert in
                Text(cert.pictogram)
            }

            if !player.hardSkills.licenses.isEmpty {
                Text("Licenses")
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

            if !player.hardSkills.software.isEmpty {
                Text("Computer Skills")
            }
            

            VStack(alignment: .leading){
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

        }
    }

}

#Preview {
    SkillsSection(
        player: Player(),
        selectedSoftware: .constant([]),
        selectedLicences: .constant([]),
        selectedPortfolio: .constant([.app]),
        selectedCertifications: .constant([]),
//        showHardSkillsSheet: .constant(false),
//        showSoftSkillsSheet: .constant(false),
        showCareersSheet: .constant(false),
        showTertiarySheet: .constant(false)
    )
    .padding()
}
