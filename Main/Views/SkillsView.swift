import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    @State private var financesExpanded: Bool = false
    @State private var softSkillsExpanded: Bool = false
    @State private var fameExpanded: Bool = false
    @State private var credentialsExpanded: Bool = false
    @State private var economyExpanded: Bool = false
    @State private var experienceExpanded: Bool = false

    private var trainings: [Training] {
        Array(appUIState.selectedTrainings.union(player.hardSkills.trainings))
    }

    private var experienceEntries: [(role: String, years: Int)] {
        player.experienceByRole
            .filter { $0.value > 0 }
            .map { ($0.key, $0.value) }
            .sorted { $0.years > $1.years }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                financesSection
                Divider()
                softSkillsSection
                Divider()
                fameSection
                Divider()
                credentialsSection
                Divider()
                experienceSection
                // The economy is a realistic-mode mechanic; Simplified has none,
                // so the section would be a list of "Steady" with nothing behind it.
                if !player.isSimplified {
                    Divider()
                    economySection
                }
            }
        }
    }

    // MARK: - Finances

    /// The money pillar, gathered in one place instead of scattered across the
    /// header: what's in the bank, what comes in each year and how much of it is
    /// actually banked, what's going out (tuition, loan interest), and the net
    /// worth the leaderboard score is built on.
    private var financesSection: some View {
        DisclosureGroup(isExpanded: $financesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                moneyRow(
                    "💰", "Savings", player.savings,
                    hint: player.isSimplified
                        ? "Everything you've earned so far. In Simplified mode you bank your whole paycheck."
                        : "Everything you've banked so far. It compounds at \(pct(GameConstants.investmentReturn)) a year while it's in the black."
                )

                if let job = player.currentOccupation {
                    moneyRow(
                        "🧾", "Gross income", job.annualIncome, suffix: " / yr",
                        hint: "What \(job.displayTitle) pays before tax and living costs."
                    )
                    if !player.isSimplified {
                        moneyRow(
                            "🏦", "Banked from pay", bankedFromPay(job), suffix: " / yr",
                            hint: "You keep \(pct(player.difficulty.savingsRate)) of gross pay — the rest goes to tax and living costs. Lower-income households have to spend a bigger share just to get by."
                        )
                    }
                } else {
                    labelledRow("🧾", "Gross income", "Not working", hint: "No job, no pay. Open Careers to start applying.")
                }

                if !player.isSimplified,
                   let edu = player.currentEducation,
                   edu.profile != nil,
                   (appUIState.yearsLeftToGraduation ?? 0) > 0 {
                    moneyRow(
                        "🎓", "Tuition", -edu.annualTuition, suffix: " / yr",
                        hint: "\(edu.degreeName) costs \(edu.annualTuition.formatted(.number)) $ a year while you're enrolled."
                    )
                }

                if player.outstandingLoan > 0 {
                    moneyRow(
                        "📉", "Venture loan owed", -player.outstandingLoan,
                        hint: "Borrowed to fund a venture. It accrues \(pct(GameConstants.ventureLoanAnnualInterest)) interest a year and is repaid automatically from savings until it's cleared."
                    )
                }

                if player.studentLoan > 0 {
                    moneyRow(
                        "🎓", "Student loan owed", -player.studentLoan,
                        hint: "Borrowed to pay tuition. It accrues \(pct(GameConstants.studentLoanAnnualInterest)) interest a year and is repaid from savings once you're earning."
                    )
                }

                Divider()
                moneyRow(
                    "🏅", "Net worth", player.netWorth,
                    hint: "Savings minus any outstanding venture or student loan. Divided by your age, this is your leaderboard score."
                )
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Finances").font(.headline)
                Spacer()
                // Net worth stays visible while collapsed — the number that matters.
                Text("\(player.netWorth.formatted(.number)) $")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(player.netWorth < 0 ? .red : .secondary)
            }
        }
    }

    /// The share of this job's gross pay that actually reaches savings.
    private func bankedFromPay(_ job: Job) -> Int {
        Int((Double(job.annualIncome) * player.difficulty.savingsRate).rounded())
    }

    private func pct(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    /// One money line: icon, label, info hint, and a right-aligned signed amount.
    @ViewBuilder
    private func moneyRow(_ icon: String, _ label: String, _ amount: Int, suffix: String = "", hint: String) -> some View {
        labelledRow(
            icon, label,
            "\(amount.formatted(.number)) $\(suffix)",
            tint: amount < 0 ? .red : nil,
            hint: hint
        )
    }

    @ViewBuilder
    private func labelledRow(_ icon: String, _ label: String, _ value: String, tint: Color? = nil, hint: String) -> some View {
        HStack {
            Text(icon)
            Text(label)
            InfoHint(title: "\(icon) \(label)", message: hint)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(tint ?? .secondary)
        }
    }

    // MARK: - Skills

    private var softSkillsSection: some View {
        DisclosureGroup(isExpanded: $softSkillsExpanded) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(
                    Array(SoftSkills.skillNames.enumerated()),
                    id: \.offset
                ) { (index, skill) in
                    HStack {
                        Text(skill.label)
                        InfoHint(title: "\(skill.pictogram) \(skill.label)", message: skill.description)
                        Spacer()
                        skillStars(level: player.softSkills[keyPath: skill.keyPath])
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 4)
                    // Zebra striping, so the eye can follow a row from the
                    // skill's name to its stars across the panel's width.
                    .background(
                        index.isMultiple(of: 2)
                            ? Color.clear
                            : Color.secondary.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Skills").font(.headline)
        }
    }

    // MARK: - Fame

    /// The third pillar of career capital: *what you're known for*. Fame is
    /// bucket-scoped — only same-bucket reputation lifts hiring and promotion
    /// odds there — so the section shows the fame score per `FameCategory`. The
    /// individual accolades are surfaced once in the status log as they're earned.
    private var fameSection: some View {
        DisclosureGroup(isExpanded: $fameExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if player.fameAwards.isEmpty {
                    Text("No fame yet — win a competition or ship a standout project.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(player.fameByCategory, id: \.category) { group in
                        HStack {
                            Text(fameCategoryLabel(group.category))
                            Spacer()
                            Text("🌟 \(String(format: "%.1f", group.score))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Fame").font(.headline)
        }
    }

    /// Icon + name for a fame group's bucket (`nil` = general renown).
    private func fameCategoryLabel(_ category: FameCategory?) -> String {
        category.map { "\($0.icon) \($0.rawValue)" } ?? "🌐 General"
    }

    // MARK: - Credentials

    /// Everything the player formally *holds*: degrees, plus the trainings
    /// (certificates and licences) that used to sit in their own "Skills"
    /// section. They're the same kind of thing — a qualification you've earned
    /// and keep — so they share one list, grouped by kind.
    private var credentialsSection: some View {
        DisclosureGroup(isExpanded: $credentialsExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                if !hasAnyCredential {
                    Text("No credentials yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    if !player.degrees.isEmpty {
                        credentialGroup(title: "Degrees") {
                            ForEach(player.degrees, id: \.id) { degree in
                                HStack {
                                    Text(degree.pictogram)
                                    Text(degree.degreeName)
                                    Spacer()
                                }
                            }
                        }
                    }
                    // Trainings don't apply in simplified mode, which is why the
                    // group is conditional rather than just empty there.
                    if showsTrainings {
                        credentialGroup(title: "Certificates & licences") {
                            ForEach(trainings) { training in
                                Text("\(training.friendlyName) \(training.pictogram)")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        } label: {
            Text("Credentials").font(.headline)
        }
    }

    /// Trainings are a realistic-mode mechanic, so simplified runs never show
    /// the group even if the set somehow isn't empty.
    private var showsTrainings: Bool {
        !player.isSimplified && !trainings.isEmpty
    }

    private var hasAnyCredential: Bool {
        !player.degrees.isEmpty || showsTrainings
    }

    @ViewBuilder
    private func credentialGroup<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                content()
            }
        }
    }

    // MARK: - Macroeconomics

    /// What each industry is doing this year. Every row here is load-bearing:
    /// the climate multiplies hire odds, moves promotion odds (and freezes them
    /// outright in a slump), and scales the odds a spare-time project in that
    /// field lands. It is the one place a player can see *when* to apply, not
    /// just where.
    private var economySection: some View {
        DisclosureGroup(isExpanded: $economyExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if player.economyInRecession {
                    Text(player.turmoilYearsRemaining > 0
                         ? "📉 National downturn — roughly \(player.turmoilYearsRemaining) more yr to run."
                         : "📉 National downturn this year.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.bottom, 2)
                }

                ForEach(player.industriesByClimate, id: \.category) { row in
                    HStack {
                        Text(row.climate.icon)
                        Text(row.category.rawValue)
                        InfoHint(
                            title: "\(row.climate.icon) \(row.category.rawValue) — \(row.climate.rawValue)",
                            message: industrySummary(row.category, row.climate)
                        )
                        Spacer()
                        Text(row.climate.rawValue)
                            .foregroundStyle(climateTint(row.climate))
                    }
                    // The player's own field is the row that actually decides
                    // their year, so it reads as the heading it is.
                    .fontWeight(row.category == player.currentOccupation?.category ? .bold : .regular)
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Economy").font(.headline)
                Spacer()
                // The player's own industry stays visible while collapsed — the
                // one climate that is affecting them right now.
                if let category = player.currentOccupation?.category {
                    let climate = player.climate(for: category)
                    Text("\(climate.icon) \(climate.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(climateTint(climate))
                }
            }
        }
    }

    private func climateTint(_ climate: IndustryClimate) -> Color {
        switch climate {
        case .boom, .growth: return .green
        case .steady:        return .secondary
        case .slowdown:      return .orange
        case .slump:         return .red
        }
    }

    /// What this climate is doing to the player's odds in this industry, in the
    /// terms the other hints use — multipliers on hiring, points on promotion.
    private func industrySummary(_ category: JobCategory, _ climate: IndustryClimate) -> String {
        func signed(_ v: Double) -> String {
            let p = Int((v * 100).rounded())
            return p >= 0 ? "+\(p)%" : "\(p)%"
        }
        func times(_ v: Double) -> String { "×\(String(format: "%.2f", v))" }

        var lines = [climate.blurb, ""]
        lines.append("🎯 Hire odds here: \(times(climate.hireFactor))")
        lines.append(climate.freezesRaises
                     ? "⬆️ Raises: frozen while the field is contracting"
                     : "⬆️ Promotion odds here: \(signed(climate.promotionDelta))")
        lines.append("🎲 Projects in this field: \(times(climate.projectFactor))")

        if category.cyclicality > 1.0 {
            lines.append("\nThis is a discretionary field — it swings harder than most, both ways.")
        } else if category.cyclicality < 1.0 {
            lines.append("\nThis is a defensive field — it rides out downturns better than most.")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Experience

    private var experienceSection: some View {
        DisclosureGroup(isExpanded: $experienceExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if experienceEntries.isEmpty {
                    Text("No experience yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(experienceEntries, id: \.role) { entry in
                        HStack {
                            Text(roleIcon(entry.role))
                            Text(entry.role)
                            Spacer()
                            Text("\(entry.years) yr\(entry.years == 1 ? "" : "s")")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Experience").font(.headline)
        }
    }

    /// The pictogram for an experience role — its own industry icon, falling back
    /// to the generic briefcase for a title the catalogue doesn't recognise.
    private func roleIcon(_ role: String) -> String {
        JobCatalog.iconByBaseTitle[role] ?? "💼"
    }

    // MARK: - Helpers

    /// A soft-skill level as a row of stars — one per point, up to the 10 cap.
    private func skillStars(level: Int) -> some View {
        Text(String(repeating: "★", count: max(0, min(level, 10))))
            .foregroundColor(.yellow)
            .font(.caption)
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
