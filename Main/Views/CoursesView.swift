import SwiftUI

struct CoursesView: View {
    @EnvironmentObject private var player: Player

    @Binding var selectedSoftware: Set<Software>
    @Binding var selectedActivities: Set<String>

    let maxActivitiesPerYear = 1

    private var sortedSoftware: [Software] {
        Software.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(sortedSoftware, id: \.self) { sw in
                    SoftwareRow(
                        selectedSoftware: $selectedSoftware,
                        selectedActivities: $selectedActivities,
                        maxActivitiesPerYear: maxActivitiesPerYear,
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
                    selectedSoftware: $selected,
                    selectedActivities: $acts
                )
                .environmentObject(player)
            }
        }
    }
    return Container()
}
