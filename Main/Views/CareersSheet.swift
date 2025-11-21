import SwiftUI

struct CareersSheet: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool
    func categories() -> [Category] {
        Array(Set(availableJobs.map(\.category))).sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        if #available(iOS 16, macOS 13, *) {
            NavigationStack {
                content
                    .navigationTitle("Jobs for you")
            }
        } else {
            NavigationView {
                content
                    .navigationTitle("Jobs for you")
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
                        ForEach(
                            availableJobs.filter { $0.category == category }
                        ) { job in
                            NavigationLink {
                                JobView(
                                    job: job,
                                    player: player,
                                    showCareersSheet: $showCareersSheet
                                )
                            } label: {
                                JobRow(detail: job)
                            }
                        }
                    }
                } label: {
                    CategoryRow(category: category)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct CareersSheetPreviewContainer: View {
    @State private var show = true
    let sampleJobs: [Job]
    let player = Player()

    var body: some View {
        CareersSheet(
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
