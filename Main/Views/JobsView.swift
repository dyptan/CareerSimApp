import SwiftUI

struct JobsView: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool
    func categories() -> [JobCategory] {
        Array(Set(availableJobs.map(\.category))).sorted {
            $0.rawValue < $1.rawValue
        }
    }

    var body: some View {
        if #available(iOS 16, macOS 13, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
            #if os(iOS)
                .navigationViewStyle(.stack)
            #endif
        }
    }

    private var content: some View {
        List {
            ForEach(categories()) { category in
                NavigationLink {
                    List {
                        ForEach(availableJobs.filter { $0.category == category }) { job in
                            NavigationLink {
                                JobDetail(
                                    job: job,
                                    player: player,
                                    showCareersSheet: $showCareersSheet
                                )
                            } label: {
                                JobRow(detail: job)
                            }
                        }
                    }
                    .navigationTitle(category.rawValue.capitalized)
                } label: {
                    CategoryRow(category: category)
                        .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Jobs")
    }

}

private struct CareersSheetPreviewContainer: View {
    @State private var show = true
    let sampleJobs: [Job]
    let player = Player()

    var body: some View {
        JobsView(
            availableJobs: sampleJobs,
            player: player,
            showCareersSheet: $show
        )
    }
}

#Preview {
    let sampleJobs: [Job] = [
        jobExample
    ]
    CareersSheetPreviewContainer(sampleJobs: sampleJobs)
}
