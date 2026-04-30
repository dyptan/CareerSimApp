import SwiftUI

struct CoursesView: View {
    @ObservedObject var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedActivities: Set<String>

    private var sortedSoftware: [Software] {
        Software.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(sortedSoftware, id: \.self) { sw in
                    SoftwareRow(
                        player: player,
                        selectedSoftware: $selectedSoftware,
                        selectedActivities: $selectedActivities,
                        item: sw
                    )
                    .padding(8)
                }
            }
            .padding()
        }
    }
}


   


#Preview {
    struct Container: View {
        @State var selected: Set<Software> = []
        @State var acts: Set<String> = []
        @StateObject var player = Player()

        var body: some View {
            NavigationView {
                CoursesView(
                    player: player,
                    selectedSoftware: $selected,
                    selectedActivities: $acts
                )
            }
        }
    }
    return Container()
}
