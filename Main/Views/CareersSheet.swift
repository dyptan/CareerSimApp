//
//  CareersSheet.swift
//
//  Created by Ivan Dyptan on 28.10.25.
//

import SwiftUI

struct CareersSheet: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool
    func categories() -> [Category] {
        Array(Set(availableJobs.map(\.category))).sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        NavigationStack {
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
                .navigationTitle("Jobs for you")

            }
        }
    }
}

#Preview {
    @Previewable @State var show = true
    var sampleJobs: [Job] = [
        jobExample
    ]
    // Simple preview scaffolding
    let player = Player()
    CareersSheet(
        availableJobs: sampleJobs,
        player: player,
        showCareersSheet: $show
    )
}
