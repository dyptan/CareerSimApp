import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedLicences: Set<License>
    @Binding var selectedPortfolio: Set<PortfolioItem>
    @Binding var selectedCertifications: Set<Certification>
    @Binding var showHardSkillsSheet: Bool
    @Binding var showSoftSkillsSheet: Bool

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {

            VStack(alignment: .leading) {

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

            HStack{
                Button("Activities") {
                    showSoftSkillsSheet = true
                }
                .buttonStyle(.bordered).font(.headline)
                
                Button("Cources&Trainings") {
                    showHardSkillsSheet = true
                }
                .buttonStyle(.bordered).font(.headline).frame(alignment: .trailing)
            }

        }

        Divider()

        VStack(alignment: .leading) {

            HStack {
                if !player.hardSkills.portfolioItems.isEmpty {
                    Text("Portfolio: ")
                }
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

            HStack {
                if !player.hardSkills.certifications.isEmpty || !player.hardSkills.licenses.isEmpty {
                    
                    Text("Certifications & Licenses:")
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
                if !player.hardSkills.software.isEmpty {
                    
                    Text("Software: ")
                }
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
    SkillsView(
        player: Player(),
        selectedSoftware: .constant([]),
        selectedLicences: .constant([]),
        selectedPortfolio: .constant([]),
        selectedCertifications: .constant([]),
        showHardSkillsSheet: .constant(false),
        showSoftSkillsSheet: .constant(false)
    )
    .padding()
}
