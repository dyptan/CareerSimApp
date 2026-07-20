import SwiftUI

struct JobsView: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool

    func categories() -> [JobCategory] {
        // Ventures live on their own surface (see `EntrepreneurshipView`) — a
        // founder play is a capital-staked bet, not salaried employment. Ventures
        // now keep their true industry category, so they're filtered out by
        // `isEntrepreneurial` rather than by category (a category still lists its
        // ordinary jobs).
        Array(Set(availableJobs.filter { !$0.isEntrepreneurial }.map(\.category)))
            .sorted { $0.rawValue < $1.rawValue }
    }

    /// Groups the jobs in `category` by `baseTitle`, returning one entry per
    /// role family. Each entry's `variants` are sorted from least to most
    /// senior using `minYearsExperience` (with `income` as a tiebreaker).
    private func roleGroups(in category: JobCategory) -> [RoleGroup] {
        let inCategory = availableJobs.filter { $0.category == category && !$0.isEntrepreneurial }
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
/// Jobs list. Each entry is a concrete, industry-specific business idea (a coffee
/// roastery, an indie game studio, a SaaS startup…), staked with the player's own
/// capital. Ventures are one-off founder bets — no auto-climbing ladder — run one
/// at a time (a launched venture becomes the player's occupation until they sell
/// out or go bankrupt). Launch success turns on the player's experience in that
/// industry and their soft-skill fit, not mainly capital (see
/// `Job.founderSuccessProbability` and `Player.foundVenture`). Every venture
/// routes into the same `JobDetail` invest flow. The spare-time plays (course,
/// app, game, and the creative fame gambles) live in the **Projects** sheet
/// instead (see `PrivateProjectsView`).
struct EntrepreneurshipView: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showSheet: Bool

    /// All ventures on offer — every capital-staked founder play — sorted by
    /// experience gate then stake size (least to most), so the most accessible
    /// ideas lead.
    private var ventures: [Job] {
        availableJobs
            .filter { $0.isEntrepreneurial }
            .sorted {
                if $0.requirements.minYearsExperience != $1.requirements.minYearsExperience {
                    return $0.requirements.minYearsExperience < $1.requirements.minYearsExperience
                }
                return $0.income < $1.income
            }
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
                    ventureLink(venture)
                }
            } header: {
                Text("Real business ideas across different industries. Stake your capital on one at a time — your experience in that field and your personal strengths decide whether the launch flies. Grow it, then sell out or move on.")
                    .textCase(nil)
            }
        }
        .navigationTitle("Ventures")
    }

    private func ventureLink(_ venture: Job) -> some View {
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
}

private struct VentureRow: View {
    let job: Job

    /// One-line facts strip: the industry the venture draws experience from, the
    /// years of that experience it expects, and the capital stake.
    private var ventureFacts: String {
        var parts = ["🏭 \(job.category.rawValue)"]
        let years = job.requirements.minYearsExperience
        if years > 0 {
            parts.append("🧭 \(years)+ yr exp")
        }
        parts.append("💰 Stake \((job.targetCapital ?? 0).formatted(.number)) $")
        return parts.joined(separator: "  ·  ")
    }

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
                Text(ventureFacts)
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
