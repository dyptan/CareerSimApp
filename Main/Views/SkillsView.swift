import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState


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

            HStack {
                Text("Portfolio:")

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

            HStack{
                Text("Software:")

                VStack(alignment: .leading){
                    ForEach(
                        Array(
                            player.hardSkills.software.union(
                                appUIState.selectedSoftware
                            )
                        )
                    ) { skill in
                        Text("\(skill.pictogram)")
                    }
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
