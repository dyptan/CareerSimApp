import SwiftUI

struct SkillsView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    @State private var occupationExpanded: Bool = false
    @State private var financesExpanded: Bool = false
    @State private var softSkillsExpanded: Bool = false
    @State private var fameExpanded: Bool = false
    @State private var trophiesExpanded: Bool = false
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

    /// The stat panels, in display order.
    private enum Section: CaseIterable {
        case occupation, finances, skills, fame, trophies, credentials, experience, economy
    }

    /// A section appears only once it has something to show — an empty panel
    /// is chrome the player has to read past, and a section turning up (the
    /// first trophy, the first credential) doubles as news.
    private func hasContent(_ section: Section) -> Bool {
        switch section {
        case .occupation:
            return player.currentOccupation != nil || player.currentEducation != nil
        case .finances:
            return player.savings != 0
                || player.currentOccupation != nil
                || player.outstandingLoan > 0
                || player.studentLoan > 0
                || showsTuition
                || player.lastYearProjectPay > 0
                || player.endorsementIncome > 0
        case .skills:
            return SoftSkills.skillNames.contains { player.softSkills[keyPath: $0.keyPath] > 0 }
        case .fame:
            return !player.fameAwards.isEmpty
        case .trophies:
            return !trophies.isEmpty
        case .credentials:
            return hasAnyCredential
        case .experience:
            return !experienceEntries.isEmpty
        case .economy:
            // A realistic-mode mechanic; Simplified has no economy, so the
            // section would be a list of "Steady" with nothing behind it. It
            // also waits for the high-school diploma: before then the job market
            // is not yet the player's concern (a teen's part-time job still
            // shows its industry's climate in Occupation).
            return !player.isSimplified
                && player.degrees.contains { $0.level == .HighSchool }
        }
    }

    private var visibleSections: [Section] {
        Section.allCases.filter(hasContent)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(visibleSections.enumerated()), id: \.element) { index, section in
                    if index > 0 { Divider() }
                    view(for: section)
                }
            }
        }
    }

    @ViewBuilder
    private func view(for section: Section) -> some View {
        switch section {
        case .occupation:  occupationSection
        case .finances:    financesSection
        case .skills:      softSkillsSection
        case .fame:        fameSection
        case .trophies:    trophiesSection
        case .credentials: credentialsSection
        case .experience:  experienceSection
        case .economy:     economySection
        }
    }

    // MARK: - Occupation

    /// What the player is doing with their years right now — the job held and
    /// the course enrolled on — with the facts that decide how that goes: the
    /// employer's industry and its climate, tenure, and the odds of a promotion.
    /// Pay and tuition stay in Finances, so money has one home.
    private var occupationSection: some View {
        DisclosureGroup(isExpanded: $occupationExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                if let job = player.currentOccupation {
                    currentJobRows(job)
                }

                if let studying = player.currentEducation {
                    if player.currentOccupation != nil {
                        Divider().padding(.vertical, 2)
                    }
                    HStack {
                        Text(studying.pictogram)
                        Text(studying.degreeName)
                        Spacer()
                        if let yearsLeft = appUIState.yearsLeftToGraduation, yearsLeft > 0 {
                            Text("\(yearsLeft) yr\(yearsLeft == 1 ? "" : "s") left")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .fontWeight(.semibold)

                    // The transcript universities will read — shown once the
                    // first high-school year is on record.
                    if studying.level == .HighSchool, !player.highSchoolGrades.isEmpty {
                        labelledRow(
                            "📝", "Grade average", gpaLabel,
                            hint: "Your high-school GPA so far, averaged over \(player.highSchoolGrades.count) year\(player.highSchoolGrades.count == 1 ? "" : "s"). Academic skills set each year's grade; a year spent on a Study activity lifts it. Universities weigh it at admission — up to half the decision at an elite school."
                        )
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Occupation").font(.headline)
                Spacer()
                // What you are, visible while collapsed: the job if you have
                // one, otherwise what you're studying.
                Text(occupationHeadline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    /// "3.4 (B+)" — the high-school GPA with its letter.
    private var gpaLabel: String {
        let gpa = player.highSchoolGPA
        return "\(Player.formatGPA(gpa)) (\(Player.letterGrade(gpa)))"
    }

    private var occupationHeadline: String {
        if let job = player.currentOccupation {
            return "\(job.icon) \(job.displayTitle)"
        }
        return "\(player.currentEducation?.pictogram ?? "") Student"
    }

    @ViewBuilder
    private func currentJobRows(_ job: Job) -> some View {
        HStack {
            Text(job.icon)
            Text(job.displayTitle)
            Spacer()
        }
        .fontWeight(.semibold)

        // The economy is a realistic-mode mechanic, so Simplified has no
        // climate to show — and the sector alone decides nothing there.
        if !player.isSimplified {
            let climate = player.climate(for: job.industry)
            HStack {
                Text(job.industry.icon)
                Text(job.industry.rawValue)
                InfoHint(
                    title: "\(job.industry.icon) \(job.industry.rawValue) — \(climate.rawValue)",
                    message: industrySummary(job.industry, climate)
                )
                Spacer()
                Text("\(climate.icon) \(climate.rawValue)")
                    .foregroundStyle(climateTint(climate))
            }
        }

        let tenure = player.experienceByRole[job.baseTitle, default: 0]
        labelledRow(
            "🧭", "In this role", "\(tenure) yr\(tenure == 1 ? "" : "s")",
            hint: "Years spent as \(job.baseTitle). Seniority counts toward promotion — how much depends on the industry — and toward roles that ask for experience in this line of work."
        )

        // Promotions are a realistic-mode mechanic only.
        if !player.isSimplified {
            let odds = player.promotionOdds(for: job)
            labelledRow(
                "⬆️", "Promotion odds",
                odds.promotes ? pct(odds.total) : "—",
                hint: promotionOddsSummary(for: job)
            )
            // The role above, and how ready the player is for it — the row that
            // says which skill to build next.
            if odds.promotes, let next = odds.nextRole {
                labelledRow(
                    "🎯", "Ready for \(next.displayTitle)", pct(odds.readiness),
                    hint: readinessHint(for: next)
                )
            }
        }
    }

    /// What the next rung asks for that the player doesn't have yet.
    private func readinessHint(for next: Job) -> String {
        let required = next.requirements.softSkills
        let gaps = next.askedSoftSkills
            .filter { player.softSkills[keyPath: $0] < required[keyPath: $0] }
            .map { kp -> String in
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = SoftSkills.pictogram(forKeyPath: kp) ?? ""
                return "\(pic) \(label): you have \(player.softSkills[keyPath: kp]), it asks for \(required[keyPath: kp])"
            }
        guard !gaps.isEmpty else {
            return "You already have every skill \(next.displayTitle) asks for — readiness counts in full toward your promotion."
        }
        return """
        How well your skills match what \(next.displayTitle) asks for. Employers promote people who can already do the job above, so closing these gaps raises your promotion odds:

        \(gaps.joined(separator: "\n"))
        """
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
                } else if player.lastYearProjectPay == 0 && player.endorsementIncome == 0 {
                    labelledRow("🧾", "Gross income", "Not working", hint: "No job, no pay. Open Jobs to start applying — or earn from Projects.")
                }

                // Fame pays too: project earnings and brand deals, on top of any salary.
                if player.lastYearProjectPay > 0 {
                    moneyRow(
                        "🎬", "Project pay (last year)", player.lastYearProjectPay,
                        hint: "What your landed project paid last year, before tax and living costs. Project pay rises steeply with your fame in its field."
                    )
                }
                if player.endorsementIncome > 0 {
                    moneyRow(
                        "🤝", "Endorsements", player.endorsementIncome, suffix: " / yr",
                        hint: "Brands pay a famous entertainment name to carry their products — athletes, stars and creators alike. It rises steeply with your 🎬 Entertainment fame, and is paid every year on top of anything else you earn."
                    )
                }

                if showsTuition, let edu = player.currentEducation {
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

    /// Whether a tuition bill is running this year: a paid course (one with an
    /// institution profile) still in progress. Realistic mode only.
    private var showsTuition: Bool {
        !player.isSimplified
            && player.currentEducation?.profile != nil
            && (appUIState.yearsLeftToGraduation ?? 0) > 0
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
            HStack(spacing: 6) {
                Text("Skills").font(.headline)
                InfoHint(
                    title: "Skills",
                    message: "Skills are what you bring besides degrees and experience. They count toward:\n\n💼 Getting hired — each job lists the skills it asks for\n⬆️ Promotions — your fit for your role and for the next one up\n🎓 Admissions — each degree field looks for its own\n📝 School grades, 🏅 contests, and 🚀 ventures\n\nBuild them through Activities, and later events, courses and projects. Tap a skill's ⓘ to see where it matters most."
                )
            }
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
            .padding(.top, 4)
        } label: {
            Text("Fame").font(.headline)
        }
    }

    /// Icon + name for a fame group's bucket (`nil` = general renown).
    private func fameCategoryLabel(_ category: FameCategory?) -> String {
        category.map { "\($0.icon) \($0.rawValue)" } ?? "🌐 General"
    }

    // MARK: - Trophies

    /// The fame-shelf entries that came from winning a competition.
    private var trophies: [FameAward] {
        player.fameAwards.filter { CompetitionCatalog.achievementTitles.contains($0.title) }
    }

    /// Every competition title won, repeat wins shown as a count. The same
    /// trophies also bank fame in their field, which the Fame section totals.
    private var trophiesSection: some View {
        DisclosureGroup(isExpanded: $trophiesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(trophies) { trophy in
                    HStack {
                        Text(trophy.icon)
                        Text(trophy.title)
                        Spacer()
                        if trophy.count > 1 {
                            Text("×\(trophy.count)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Trophies").font(.headline)
                Spacer()
                Text("🏆 \(trophies.reduce(0) { $0 + $1.count })")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Credentials

    /// Everything the player formally *holds*: degrees, plus the trainings
    /// (certificates and licences) that used to sit in their own "Skills"
    /// section. They're the same kind of thing — a qualification you've earned
    /// and keep — so they share one list, grouped by kind.
    private var credentialsSection: some View {
        DisclosureGroup(isExpanded: $credentialsExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                if !player.degrees.isEmpty {
                    credentialGroup(title: "Degrees") {
                        ForEach(player.degrees, id: \.id) { degree in
                            HStack {
                                Text(degree.pictogram)
                                Text(degree.degreeName)
                                Spacer()
                                // The diploma carries the GPA universities read.
                                if degree.level == .HighSchool {
                                    Text("GPA \(gpaLabel)")
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
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
                // The national cycle first: every sector below is this number
                // times the sector's beta, plus whatever is happening to it alone.
                HStack {
                    Text(player.macroClimate.icon)
                    Text("The economy")
                    InfoHint(title: "The economy", message: macroSummary)
                    Spacer()
                    Text(player.macroClimate.rawValue)
                        .foregroundStyle(climateTint(player.macroClimate))
                }
                .fontWeight(.semibold)

                if player.economyInRecession {
                    Text(player.turmoilYearsRemaining > 0
                         ? "📉 Declared downturn — roughly \(player.turmoilYearsRemaining) more yr to run."
                         : "📉 Declared downturn this year.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Divider().padding(.vertical, 2)

                ForEach(player.industriesByClimate, id: \.industry) { row in
                    HStack {
                        Text(row.industry.icon)
                        Text(row.industry.rawValue)
                        InfoHint(
                            title: "\(row.industry.icon) \(row.industry.rawValue) — \(row.climate.rawValue)",
                            message: industrySummary(row.industry, row.climate)
                        )
                        Spacer()
                        Text(row.climate.rawValue)
                            .foregroundStyle(climateTint(row.climate))
                    }
                    // The player's own field is the row that actually decides
                    // their year, so it reads as the heading it is.
                    .fontWeight(row.industry == player.currentOccupation?.industry ? .bold : .regular)
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Economy").font(.headline)
                Spacer()
                // The player's own industry stays visible while collapsed — the
                // one climate that is affecting them right now.
                if let sector = player.currentOccupation?.industry {
                    let climate = player.climate(for: sector)
                    Text("\(climate.icon) \(climate.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(climateTint(climate))
                }
            }
        }
    }

    /// How the national cycle reaches each sector — the model in two sentences,
    /// since every row below is derived from it.
    private var macroSummary: String {
        """
        \(player.macroClimate.blurb)

        Every sector below is this cycle scaled by how much it transmits — a \
        hotel chain amplifies it, a school district barely feels it — plus \
        whatever is happening to that sector on its own account.

        So a sector can be slumping in a good year, or booming through a bad one.
        """
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
    private func industrySummary(_ industry: Industry, _ climate: IndustryClimate) -> String {
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

        lines.append("")
        if industry.beta > 1.0 {
            lines.append("📊 Amplifies the economy (×\(String(format: "%.1f", industry.beta))) — a discretionary field, so it swings harder than the cycle both ways.")
        } else if industry.beta < 1.0 {
            lines.append("📊 Damps the economy (×\(String(format: "%.1f", industry.beta))) — a defensive field that rides out downturns better than most.")
        } else {
            lines.append("📊 Moves with the economy (×1.0).")
        }
        if industry.volatility > 1.0 {
            lines.append("🎲 Also swings on its own account, cycle or no cycle.")
        } else if industry.volatility < 1.0 {
            lines.append("🎲 Little movement of its own — it mostly just follows the cycle.")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Experience

    private var experienceSection: some View {
        DisclosureGroup(isExpanded: $experienceExpanded) {
            VStack(alignment: .leading, spacing: 4) {
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
            .padding(.top, 4)
        } label: {
            Text("Experience").font(.headline)
        }
    }

    /// Plain-text breakdown of this year's promotion odds for the current job,
    /// mirroring the hire-probability InfoHint: the industry-weighted merit terms
    /// first, then the modifiers.
    private func promotionOddsSummary(for job: Job) -> String {
        let odds = player.promotionOdds(for: job)
        guard odds.promotes else {
            return "This role doesn't offer in-place promotions — unskilled work rarely comes with a raise-and-title bump. Climb by applying to a higher role instead."
        }
        func signed(_ v: Double) -> String {
            let s = Int((v * 100).rounded())
            return s >= 0 ? "+\(s)%" : "\(s)%"
        }
        let c = odds.culture
        let readinessLine = odds.nextRole.map {
            "Readiness for \($0.displayTitle): \(pct(odds.readiness)) — weighs \(pct(c.readiness))"
        } ?? "Readiness: top of the ladder, judged on the job you do — weighs \(pct(c.readiness))"
        return """
        Each year in a skilled role you get a shot at a raise and title bump. \(job.industry.promotionCultureBlurb)

        Merit — \(pct(odds.merit)):
        • Performance in the role: \(pct(odds.performance)) — weighs \(pct(c.performance))
        • \(readinessLine)
        • Seniority (\(odds.tenureYears) of \(GameConstants.promotionSeniorityYears) yr): \(pct(odds.seniority)) — weighs \(pct(c.seniority))

        Then:
        • Network (\(job.category.rawValue)): \(signed(odds.network))
        • Fame (\(job.category.rawValue)): \(signed(odds.fame))
        • Education vs. what the role expects: \(signed(odds.education))
        • \(odds.climate.icon) \(job.industry.rawValue) is \(odds.climate.rawValue.lowercased()): \(signed(odds.climate.promotionDelta))
        Total: \(pct(odds.total))

        \(odds.climate.freezesRaises
          ? "Raises are frozen while \(job.industry.rawValue) is contracting — see Economy."
          : "Your industry's climate moves these odds every year — see Economy.")
        """
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
