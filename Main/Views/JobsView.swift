import SwiftUI

struct JobsView: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    func categories() -> [JobCategory] {
        // Entrepreneurship is its own surface (see `EntrepreneurshipView`) — the
        // founder path is a capital-staked venture, not salaried employment, so
        // it's kept out of the Jobs list.
        Array(Set(availableJobs.map(\.category)))
            .filter { $0 != .entrepreneurship }
            .sorted { $0.rawValue < $1.rawValue }
    }

    /// Groups the jobs in `category` by `baseTitle`, returning one entry per
    /// role family. Each entry's `variants` are sorted from least to most
    /// senior using `minYearsExperience` (with `income` as a tiebreaker).
    private func roleGroups(in category: JobCategory) -> [RoleGroup] {
        let inCategory = availableJobs.filter { $0.category == category }
        let grouped = Dictionary(grouping: inCategory) { $0.baseTitle }
        return grouped
            .map { (key, value) -> RoleGroup in
                let sorted = value.sorted {
                    if $0.requirements.minYearsExperience != $1.requirements.minYearsExperience {
                        return $0.requirements.minYearsExperience < $1.requirements.minYearsExperience
                    }
                    return $0.income < $1.income
                }
                return RoleGroup(baseTitle: key, variants: sorted)
            }
            .sorted { $0.baseTitle < $1.baseTitle }
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
                        ForEach(roleGroups(in: category)) { group in
                            NavigationLink {
                                // Pick a role, then a seniority rung (or go straight
                                // to the single role) — no company-tier step.
                                if group.variants.count > 1 {
                                    SeniorityOffersView(
                                        variants: group.variants,
                                        player: player,
                                        showCareersSheet: $showCareersSheet
                                    )
                                } else {
                                    JobDetail(
                                        job: group.variants[0].atBaseSalary(),
                                        player: player,
                                        showCareersSheet: $showCareersSheet
                                    )
                                }
                            } label: {
                                RoleGroupRow(
                                    baseTitle: group.baseTitle,
                                    variants: group.variants
                                )
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

private struct RoleGroup: Identifiable {
    let baseTitle: String
    let variants: [Job]
    var id: String { baseTitle }
}

private struct RoleGroupRow: View {
    let baseTitle: String
    let variants: [Job]

    private var icon: String { variants.first?.icon ?? "" }

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 40, height: 40)
                .background(Color(.systemGray))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(baseTitle)
                    .font(.headline)
                if variants.count > 1 {
                    Text("\(variants.count) seniority levels")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
    }
}

/// The **Ventures** surface — the founder path, split out from the salaried
/// Jobs list. Two kinds of play live here. The founder rungs (Side Hustler →
/// Serial Entrepreneur) are capital-staked: you invest your own savings for a
/// shot at running a venture, then chase buyout offers year over year (see
/// `FounderLadder` and `Player.foundVenture`), routing into the same `JobDetail`
/// invest flow. The spare-time business ventures (startup, pitch competition,
/// crowdfunding) are lighter entrepreneurial projects with prospects of becoming
/// a business — they stake no cash, credit `.entrepreneurship` work experience,
/// and are committed when the year advances (see `SideHustleCatalog`).
struct EntrepreneurshipView: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showSheet: Bool
    @Binding var selectedSideHustles: Set<String>

    /// Founder rungs on offer, in climb order (least to most experience).
    private var ventures: [Job] {
        availableJobs
            .filter { $0.category == .entrepreneurship }
            .sorted {
                if $0.requirements.minYearsExperience != $1.requirements.minYearsExperience {
                    return $0.requirements.minYearsExperience < $1.requirements.minYearsExperience
                }
                return $0.income < $1.income
            }
    }

    /// Spare-time business ventures offered at the player's life stage — the
    /// entrepreneurship projects moved here out of the Projects sheet.
    private var businessVentures: [SideHustle] {
        let stage = LifeStage.forAge(player.age)
        return SideHustleCatalog.businessVentures.filter { $0.stages.contains(stage) }
    }

    var body: some View {
        if #available(iOS 16, macOS 13, *) {
            NavigationStack { content }
        } else {
            NavigationView { content }
            #if os(iOS)
                .navigationViewStyle(.stack)
            #endif
        }
    }

    private var content: some View {
        List {
            Section {
                ForEach(ventures) { venture in
                    NavigationLink {
                        JobDetail(
                            job: venture.atBaseSalary(),
                            player: player,
                            showCareersSheet: $showSheet
                        )
                    } label: {
                        VentureRow(job: venture)
                    }
                }
            } header: {
                Text("Stake your own capital to run a venture. Grow it and sell for a multiple — or ride out the downturns.")
                    .textCase(nil)
            }

            if !businessVentures.isEmpty {
                Section {
                    ForEach(businessVentures) { hustle in
                        SideHustleRow(
                            hustle: hustle,
                            player: player,
                            selectedSideHustles: $selectedSideHustles
                        )
                    }
                } header: {
                    Text("Spare-time business plays — no cash down. Each committed year builds entrepreneurship experience and is resolved when you advance the year.")
                        .textCase(nil)
                }
            }
        }
        .navigationTitle("Ventures")
    }
}

private struct VentureRow: View {
    let job: Job

    var body: some View {
        HStack(spacing: 12) {
            Text(job.icon)
                .font(.system(size: 28))
                .frame(width: 40, height: 40)
                .background(Color(.systemGray))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(job.baseTitle)
                    .font(.headline)
                Text(job.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("💰 Stake \((job.targetCapital ?? 0).formatted(.number)) $")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
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
