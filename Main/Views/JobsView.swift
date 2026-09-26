import SwiftUI

struct JobsView: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool
    /// The list's filters. Held by `AppUIState` rather than as view state, so a
    /// choice survives the sheet closing — which it now does every year.
    @Binding var settingFilter: WorkSetting?
    @Binding var qualifiedOnly: Bool
    /// Applying spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    /// Whether a posting survives the current filters. Both are catalogue facts,
    /// so filtering never changes what a role *is* — only what's listed.
    private func matchesFilters(_ job: Job) -> Bool {
        if let settingFilter, job.workSetting != settingFilter { return false }
        if qualifiedOnly, !job.allRequirementsMet(for: player) { return false }
        return true
    }

    private var filteredJobs: [Job] {
        availableJobs.filter { !$0.isEntrepreneurial && matchesFilters($0) }
    }

    /// Roles left after filtering — the count shown under the filter controls, so
    /// an empty list reads as "the filter is strict", not "the game is broken".
    private var matchingRoleCount: Int {
        Set(filteredJobs.map(\.baseTitle)).count
    }

    func categories() -> [JobCategory] {
        // Ventures live on their own surface (see `EntrepreneurshipView`) — a
        // founder play is a capital-staked bet, not salaried employment. Ventures
        // now keep their true industry category, so they're filtered out by
        // `isEntrepreneurial` rather than by category (a category still lists its
        // ordinary jobs).
        Array(Set(filteredJobs.map(\.category)))
            .sorted { $0.rawValue < $1.rawValue }
    }

    /// Groups the jobs in `category` by `baseTitle`, returning one entry per
    /// role family. Each entry's `variants` are sorted from least to most
    /// senior using `minYearsExperience` (with `income` as a tiebreaker).
    private func roleGroups(in category: JobCategory) -> [RoleGroup] {
        let inCategory = filteredJobs.filter { $0.category == category }
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
        NavigationStack {
            content
        }
    }

    private var content: some View {
        List {
            filterSection

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
                                        showCareersSheet: $showCareersSheet,
                                        onCommit: onCommit
                                    )
                                } else {
                                    JobDetail(
                                        job: group.variants[0].atBaseSalary(),
                                        player: player,
                                        showCareersSheet: $showCareersSheet,
                                        onCommit: onCommit
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
            if categories().isEmpty {
                Text("No roles match these filters. Widen the setting, or turn off \"Only roles I qualify for\".")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
        .gameSheetClose($showCareersSheet, title: "Jobs")
    }

    /// Filters sit above the list rather than behind a toolbar button: on a small
    /// screen a hidden filter is a filter nobody finds.
    @ViewBuilder
    private var filterSection: some View {
        Section {
            HStack(spacing: 6) {
                Text("Kind of work")
                InfoHint(
                    title: "Kind of work",
                    message: WorkSetting.allCases
                        .map { "\($0.pictogram) \($0.rawValue) — \($0.blurb)" }
                        .joined(separator: "\n\n")
                )
                Spacer()
                Picker("Kind of work", selection: $settingFilter) {
                    Text("Any").tag(WorkSetting?.none)
                    ForEach(WorkSetting.allCases) { setting in
                        Text("\(setting.pictogram) \(setting.rawValue)").tag(WorkSetting?.some(setting))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Toggle("Only roles I qualify for", isOn: $qualifiedOnly)
                .platformToggleStyle()
        } footer: {
            Text(matchingRoleCount == 1 ? "1 role" : "\(matchingRoleCount) roles")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
    /// Every rung of a ladder shares an employer sector, so the first is the row's.
    private var industry: Industry? { variants.first?.industry }

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
                // The sector the employer trades in. Deliberately *not* its
                // climate: that already shows up where it matters, inside the
                // posting's hire probability, and repeating it on every row
                // turned the list into a wall of weather rather than of jobs.
                if let industry {
                    Text("\(industry.icon) \(industry.rawValue)")
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
/// `Job.founderSuccessProbability` and `Player.foundVenture`).
///
/// There is no invest submenu: tapping **Launch** on a row founds the venture on
/// the spot, staking its target capital as far as savings-plus-loan reach — the
/// same stake the old invest slider opened at. The spare-time plays (course,
/// app, game, and the creative fame gambles) live in the **Projects** sheet
/// instead (see `PrivateProjectsView`).
struct EntrepreneurshipView: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showSheet: Bool
    /// Launching a venture spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

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
        NavigationStack { content }
    }

    private var content: some View {
        List {
            ForEach(ventures) { venture in
                VentureRow(job: venture.atBaseSalary(), player: player) { launch($0) }
            }
        }
        .gameSheetClose($showSheet, title: "Ventures")
    }

    /// Founds the venture with its one-tap stake and reports back through the
    /// same pop-up an application uses — launching spends the year either way.
    private func launch(_ venture: Job) {
        let capital = VentureRow.stake(for: venture, player: player)
        let odds = venture.founderSuccessProbability(for: player, investedCapital: capital)
        if player.foundVenture(venture, investedCapital: capital) {
            player.reportApplicationOutcome(
                title: "🎉 Venture launched!",
                message: "You put \(capital.formatted(.number)) $ in and the venture is running — it's your occupation now."
            )
        } else {
            player.reportApplicationOutcome(
                title: "❌ The venture flopped",
                message: "The launch had \(Int((odds * 100).rounded()))% odds and didn't pan out. You lost your stake."
            )
        }
        onCommit()
    }
}

private struct VentureRow: View {
    let job: Job
    @ObservedObject var player: Player
    /// Tapping **Launch** founds this venture immediately (the year is spent).
    let onLaunch: (Job) -> Void

    /// The stake a one-tap launch commits: the venture's target capital, funded
    /// as far as savings-plus-loan reach — the same value the old invest
    /// slider opened at. Savings go in first; any shortfall up to the loan cap
    /// is borrowed (see `Player.foundVenture`).
    static func stake(for job: Job, player: Player) -> Int {
        min(job.targetCapital ?? 0, player.maxVentureStake)
    }

    /// One-line facts strip for the hint: the industry the venture draws
    /// experience from, the years of it expected, and the capital it wants.
    private var ventureFacts: String {
        var parts = ["\(job.industry.icon) \(job.industry.rawValue)", "🏭 \(job.category.rawValue)"]
        let years = job.requirements.minYearsExperience
        if years > 0 {
            parts.append("🧭 \(years) yr exp expected")
        }
        parts.append("💰 Target \((job.targetCapital ?? 0).formatted(.number)) $")
        return parts.joined(separator: "  ·  ")
    }

    var body: some View {
        let stake = Self.stake(for: job, player: player)
        let borrowed = player.borrowedPortion(ofStake: stake)
        let odds = job.founderSuccessProbability(for: player, investedCapital: stake)
        // Capital is the only hard requirement: with a stake you may attempt any
        // venture, however unprepared — the odds carry the whole decision.
        let locked = player.maxVentureStake <= 0

        HStack(alignment: .top, spacing: 12) {
            Text(job.icon)
                .font(.system(size: 28))
                .frame(width: 40, height: 40)
                .background(Color(.systemGray))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // The row carries only what the choice turns on — odds and stake,
            // or the reason Launch is disabled. The pitch, the industry facts
            // and the loan's terms all live in the hint, one tap away, so a
            // list of ventures stays scannable.
            VStack(alignment: .leading, spacing: 2) {
                Text(job.baseTitle)
                    .font(.headline)

                if locked {
                    Text("🔒 Nothing to stake yet — earn and save first")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("🎲 \(Int((odds * 100).rounded()))% · stake \(stake.formatted(.number)) $")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.forOdds(odds))
                    // Borrowing is the part a player can regret, so it stays on
                    // the row — as a flag, with the terms in the hint.
                    if borrowed > 0 {
                        Text("🏦 \(borrowed.formatted(.number)) $ of it borrowed")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                }
            }
            .opacity(locked ? 0.5 : 1.0)

            Spacer(minLength: 8)

            TakeButton(label: "Launch") { onLaunch(job) }
                .disabled(locked)
                .opacity(locked ? 0.5 : 1.0)

            InfoHint(
                title: "\(job.icon) \(job.baseTitle)",
                message: infoMessage(stake: stake, borrowed: borrowed, odds: odds)
            )
        }
        .padding(.vertical, 4)
    }

    /// Everything the row used to spell out — the pitch, the industry facts, the
    /// loan's terms — plus what the odds turn on and what each outcome costs.
    /// Kept to short lines: this is a reference the player opens, not prose.
    private func infoMessage(stake: Int, borrowed: Int, odds: Double) -> String {
        let header = [job.summary, ventureFacts]

        guard player.maxVentureStake > 0 else {
            return (header + [
                "🔒 You need something to stake. Earn and save first — capital is the only thing that can stop you launching."
            ]).joined(separator: "\n\n")
        }

        let target = (job.targetCapital ?? 0).formatted(.number)
        var funding = "Stake: \(stake.formatted(.number)) $, savings first."
        if borrowed > 0 {
            funding += " \(borrowed.formatted(.number)) $ of that is borrowed against your income, repaid with \(Int(GameConstants.ventureLoanAnnualInterest * 100))% interest win or lose."
        }

        return (header + [
            funding,
            "Odds: \(Int((odds * 100).rounded()))% — mostly your \(player.industryExperience(for: job.category)) yr in \(job.category.rawValue) against the \(job.requirements.minYearsExperience) expected, plus 🎲 Risk-Taker, 🔭 Visionary, 💬 Persuader and your stake against the \(target) $ this really needs. Nothing here blocks you — thin preparation just makes it a long shot.",
            "Win: it becomes your occupation, earning its income until you sell or it folds.\nLose: the stake is gone — the loan isn't.",
        ]).joined(separator: "\n\n")
    }
}

private struct CareersSheetPreviewContainer: View {
    @State private var show = true
    @State private var settingFilter: WorkSetting?
    @State private var qualifiedOnly = false
    let sampleJobs: [Job]
    let player = Player()

    var body: some View {
        JobsView(
            availableJobs: sampleJobs,
            player: player,
            showCareersSheet: $show,
            settingFilter: $settingFilter,
            qualifiedOnly: $qualifiedOnly
        )
    }
}

#Preview {
    let sampleJobs: [Job] = [
        jobExample
    ]
    CareersSheetPreviewContainer(sampleJobs: sampleJobs)
}
