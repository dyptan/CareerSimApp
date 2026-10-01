import SwiftUI

struct JobsView: View {
    var availableJobs: [Job]
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool
    /// The list's filters. Held by `AppUIState` rather than as view state, so a
    /// choice survives the sheet closing — which it now does every year.
    @Binding var settingFilter: WorkSetting?
    @Binding var qualifiedOnly: Bool
    /// A role (a `Job.baseTitle`) to open straight onto — set when the advisor's
    /// "See job listings" sent the player here. Taken on opening and cleared.
    @Binding var focusRole: String?
    /// Applying spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    /// The roles pushed on top of the category list (see `focusRole`).
    @State private var path: [String] = []

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
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    /// Groups the jobs in `category` by `baseTitle`, returning one entry per
    /// role family. Each entry's `variants` are sorted from least to most
    /// senior using `minYearsExperience` (with `income` as a tiebreaker).
    private func roleGroups(in category: JobCategory) -> [RoleGroup] {
        let inCategory = filteredJobs.filter { $0.category == category }
        let grouped = Dictionary(grouping: inCategory) { $0.baseTitle }
        return grouped
            .map { (key, value) in RoleGroup(baseTitle: key, variants: Self.leastToMostSenior(value)) }
            .sorted { $0.displayBaseTitle.localizedStandardCompare($1.displayBaseTitle) == .orderedAscending }
    }

    /// A role's postings from least to most senior, by the experience they ask
    /// for (with pay as the tiebreaker).
    private static func leastToMostSenior(_ jobs: [Job]) -> [Job] {
        jobs.sorted {
            if $0.requirements.minYearsExperience != $1.requirements.minYearsExperience {
                return $0.requirements.minYearsExperience < $1.requirements.minYearsExperience
            }
            return $0.income < $1.income
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationDestination(for: String.self) { roleDestination($0) }
        }
        .onAppear {
            if let role = focusRole {
                path = [role]
                focusRole = nil
            }
        }
    }

    /// One role's postings — however the list is filtered, since the player
    /// asked for this role by name. Seniority rungs first when there are
    /// several, straight to the posting when there's one.
    @ViewBuilder
    private func roleDestination(_ baseTitle: String) -> some View {
        let variants = Self.leastToMostSenior(
            availableJobs.filter { $0.baseTitle == baseTitle && !$0.isEntrepreneurial })
        if variants.count > 1 {
            SeniorityOffersView(variants: variants, player: player,
                                showCareersSheet: $showCareersSheet, onCommit: onCommit)
        } else if let only = variants.first {
            JobDetail(job: only.atBaseSalary(), player: player,
                      showCareersSheet: $showCareersSheet, onCommit: onCommit)
        } else {
            let title = JobCatalog.displayBaseTitle(for: baseTitle)
            Text(L("Nobody is posting \(title) jobs this year. The job market changes every year — check again next year."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .navigationTitle(title)
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
                                    baseTitle: group.displayBaseTitle,
                                    variants: group.variants
                                )
                            }
                        }
                    }
                    .navigationTitle(category.displayName)
                } label: {
                    CategoryRow(category: category)
                        .padding(.vertical, 6)
                }
            }
            if categories().isEmpty {
                Text("No jobs match these filters. Try another kind of work, or turn off \"Only roles I qualify for\".")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
        .gameSheetClose($showCareersSheet, title: String(localized: "Jobs", comment: "Title of the sheet listing job categories and postings")) // i18n:ignore translator comment
    }

    /// Filters sit above the list rather than behind a toolbar button: on a small
    /// screen a hidden filter is a filter nobody finds.
    @ViewBuilder
    private var filterSection: some View {
        Section {
            HStack(spacing: 6) {
                Text("Kind of work")
                    .fixedSize(horizontal: false, vertical: true)
                InfoHint(
                    title: L("Kind of work"),
                    message: WorkSetting.allCases
                        .map { L("\($0.pictogram) \($0.displayName) — \($0.blurb)") }
                        .joined(separator: "\n\n")
                )
                Spacer()
                Picker("Kind of work", selection: $settingFilter) {
                    Text("Any", comment: "Filter choice: show roles of any kind of work").tag(WorkSetting?.none) // i18n:ignore translator comment
                    ForEach(WorkSetting.allCases) { setting in
                        Text(verbatim: "\(setting.pictogram) \(setting.displayName)").tag(WorkSetting?.some(setting))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Toggle("Only roles I qualify for", isOn: $qualifiedOnly)
                .platformToggleStyle()
        } footer: {
            Text(L("\(matchingRoleCount) roles"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

}

private struct RoleGroup: Identifiable {
    let baseTitle: String
    let variants: [Job]
    var id: String { baseTitle }
    /// The role's name in the player's language (every rung shares it).
    var displayBaseTitle: String { variants.first?.displayBaseTitle ?? JobCatalog.displayBaseTitle(for: baseTitle) }
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
                if let first = variants.first, first.offersIndustryChoice {
                    Text(L("🏢 Any of \(first.possibleIndustries.count) industries — your choice"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let industry {
                    Text(verbatim: "\(industry.icon) \(industry.displayName)")
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
/// out or it folds). A business always opens; how well it survives turns on the
/// player's experience in that industry and their soft-skill fit, not mainly
/// capital (see `Player.foundVenture` and `Player.ventureFoldRisk`).
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
        .gameSheetClose($showSheet, title: String(localized: "Ventures", comment: "Title of the sheet listing businesses the player can found")) // i18n:ignore translator comment
    }

    /// Founds the venture with its one-tap stake and reports back through the
    /// same pop-up an application uses. Launching spends the year.
    private func launch(_ venture: Job) {
        let capital = VentureRow.stake(for: venture, player: player)
        guard player.foundVenture(venture, investedCapital: capital) else { return }
        let firstYear = Fmt.percent(Player.ventureRamp(year: 1))
        player.reportApplicationOutcome(
            title: L("🎉 Venture launched!"),
            message: [
                L("You put in \(player.money(capital)) and opened your business!"),
                L("In the first year it pays about \(firstYear) of the full amount while you find customers."),
            ].joined(separator: " ")
        )
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
        var parts = ["\(job.industry.icon) \(job.industry.displayName)", "🏭 \(job.category.displayName)"]
        let years = job.requirements.minYearsExperience
        if years > 0 {
            parts.append(L("🧭 \(years) yr exp expected"))
        }
        parts.append(L("💰 Target \(player.money((job.targetCapital ?? 0)))"))
        return parts.joined(separator: "  ·  ")
    }

    var body: some View {
        let stake = Self.stake(for: job, player: player)
        let borrowed = player.borrowedPortion(ofStake: stake)
        // The business always opens; preparation sets how well it survives.
        let survival = player.firstYearSurvival(for: job, stake: stake)
        // Capital is the only hard requirement: with a stake you may launch any
        // venture, however unprepared.
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
                Text(job.displayBaseTitle)
                    .font(.headline)

                if locked {
                    Text("🔒 Nothing to stake yet — earn and save first")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text(L("🛡️ \(Fmt.percent(survival)) survive year 1 · stake \(player.money(stake))"))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.forOdds(survival))
                    // Borrowing is the part a player can regret, so it stays on
                    // the row — as a flag, with the terms in the hint.
                    if borrowed > 0 {
                        Text(L("🏦 \(player.money(borrowed)) of it borrowed"))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                }
            }
            .opacity(locked ? 0.5 : 1.0)

            Spacer(minLength: 8)

            TakeButton(label: String(localized: "Launch", comment: "Button: found this business now")) { onLaunch(job) } // i18n:ignore translator comment
                .disabled(locked)
                .opacity(locked ? 0.5 : 1.0)

            InfoHint(
                title: "\(job.icon) \(job.displayBaseTitle)",
                message: infoMessage(stake: stake, borrowed: borrowed, survival: survival)
            )
        }
        .padding(.vertical, 4)
    }

    /// The pitch, the industry facts, the loan's terms, and how a business's
    /// life plays out. Kept to short lines: a reference the player opens.
    private func infoMessage(stake: Int, borrowed: Int, survival: Double) -> String {
        let header = [job.displaySummary, ventureFacts]

        guard player.maxVentureStake > 0 else {
            return (header + [
                L("🔒 You need some money to start a business. Work and save first — then you can start any business you like.")
            ]).joined(separator: "\n\n")
        }

        let target = player.money(job.targetCapital ?? 0)
        var funding = L("💰 You'd put in \(player.money(stake)) of the \(target) it needs, from your savings first.")
        if borrowed > 0 {
            funding += " " + L("\(player.money(borrowed)) would be a loan that grows \(Fmt.percent(GameConstants.ventureLoanAnnualInterest)) a year — you pay it back even if the business closes.")
        }
        let full = player.money(job.annualIncome)
        let ramp = GameConstants.ventureIncomeRamp
        let firstYear = Fmt.percent(ramp.first ?? 1)
        let secondYear = Fmt.percent(ramp.last ?? 1)
        let fame = FameCategory.business
        let years = player.industryExperience(for: job.category)

        var lines = header + [
            funding,
            [
                L("🚀 It always opens. It has a \(Fmt.percent(survival)) chance to make it through the first year."),
                L("What helps: your \(years) years in \(job.category.displayName) (\(Fmt.number(job.requirements.minYearsExperience)) is good), the skills it needs, \(HintFmt.skill(\.visionaryThinkingAndAmbition)), \(HintFmt.skill(\.persuasionAndNegotiation)), and the money you put in."),
                L("Each year it lasts, it gets safer — but a bad economy makes it riskier."),
            ].joined(separator: " "),
            L("💵 It pays \(firstYear), then \(secondYear) of its \(full) in the first two years, then the full amount — more in good years, less in bad ones."),
            L("📉 If it closes, you get back \(Fmt.percent(GameConstants.ventureFoldRecovery)) of the money you put in."),
            L("🌟 Every year in business, every investment you win and every sale makes you better known in \(fame.icon) \(fame.displayName) — so your next business is more likely to last."),
        ]
        if job.isScalableVenture {
            lines.append(L("🦄 This kind of business can grow big: you can ask investors for money in the Boardroom, and — very rarely — it takes off and becomes worth a fortune."))
        }
        return lines.joined(separator: "\n\n")
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
            qualifiedOnly: $qualifiedOnly,
            focusRole: .constant(nil)
        )
    }
}

#Preview {
    let sampleJobs: [Job] = [
        jobExample
    ]
    CareersSheetPreviewContainer(sampleJobs: sampleJobs)
}
