import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState


    var body: some View {

        ScrollView {

            Text("Skills")
            ForEach(
                Array(SoftSkills.skillNames.enumerated()),
                id: \.offset
            ) { (_, skill) in
                HStack {
                    Text(skill.label)
                    InfoHint(title: "\(skill.pictogram) \(skill.label)", message: skill.description)
                    Spacer()
                    let count = player.softSkills[keyPath: skill.keyPath]
                    Text(count == 0 ? " " : count <= 5 ? String(repeating: skill.pictogram, count: count) : "\(count)x\(skill.pictogram)")
                        .monospacedDigit()
                }
            }

            Divider()

            
            HStack {
                Text("Projects:")
                
                ForEach(
                    Array(
                        player.hardSkills.portfolioItems.union(
                            appUIState.selectedPortfolio
                        )
                    )
                ) { skill in
                    Text("\(skill.id) \(skill.pictogram)")
                }
                
                Spacer()

            }
            HStack {
                Text("Education:")
                ForEach(player.degrees, id: \.degreeName) { degree in
                    Text(degree.pictogram)
                }
                Spacer()
            }

            HStack{
                Text("Certifications:")

                ForEach(
                    Array(
                        appUIState.selectedCertifications.union(
                            player.hardSkills.certifications
                        )
                    )
                ) { cert in
                    Text(cert.pictogram)
                }
                Spacer()
            }

            HStack{
                Text("Licenses:")
                
                ForEach(
                    Array(
                        appUIState.selectedLicenses.union(
                            player.hardSkills.licenses
                        )
                    )
                ) { lic in
                    Text(lic.pictogram)
                }
                Spacer()
            }

        }
    }
}

#Preview {
    let player = Player()
    let appUIState = AppUIState()
    return SkillsView(
        player: player,
        appUIState: appUIState
    )
    .padding()
}
