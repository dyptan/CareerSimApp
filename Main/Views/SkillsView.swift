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
                        Text(studying.degreeName(in: player.country))
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
                            "📝", player.country.schooling.gradeName, gpaLabel,
                            hint: "Your average school grade so far, over \(player.highSchoolGrades.count) year\(player.highSchoolGrades.count == 1 ? "" : "s"). School skills set each year's grade, and choosing a Study activity pushes it up. Universities look at it when you apply — the top ones care about it a lot."
                        )
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Occupation").font(.headline)
                InfoHint(title: "Occupation", message: SectionHints.occupation(simplified: player.isSimplified))
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

    /// The school-leaving grade as the player's country writes it: "3.4 (B+)",
    /// "1.6 (good)", "AAB".
    private var gpaLabel: String {
        player.country.gradeLabel(player.highSchoolGPA)
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
            hint: "How many years you've worked as \(job.baseTitle). More years help you get promoted, and some jobs only hire people with enough years in this kind of work."
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
                return "\(pic) \(label): you have \(player.softSkills[keyPath: kp]), it needs \(required[keyPath: kp])"
            }
        guard !gaps.isEmpty else {
            return "You already have every skill \(next.displayTitle) needs. 🎉 That helps your promotion chances as much as it can."
        }
        return """
        How ready your skills are for \(next.displayTitle). Bosses like to promote people who can already do the next job — so growing these skills makes a promotion more likely:

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
                        ? "All the money you've earned so far. In Simplified mode you keep your whole paycheck."
                        : "The money you've saved. It grows by about \(pct(GameConstants.investmentReturn)) a year while it's above zero — but it can drop in a year when the economy turns bad."
                )

                if let job = player.currentOccupation {
                    moneyRow(
                        "🧾", "Gross income", job.annualIncome, suffix: " / yr",
                        hint: "What \(job.displayTitle) pays in a year, before taxes and living costs."
                    )
                    if !player.isSimplified {
                        moneyRow(
                            "🏦", "Banked from pay", bankedFromPay(job), suffix: " / yr",
                            hint: "The first \(player.money(player.livingCostFloor)) of your pay goes on living costs like rent and food. You save \(pct(player.difficulty.savingsRate)) of the rest (\(pct(GameConstants.highEarnerSavingsRate)) of anything over \(player.money(player.country.highEarnerThreshold))). If you have no job, living costs come out of your savings."
                        )
                    }
                } else if player.endorsementIncome == 0 {
                    labelledRow("🧾", "Gross income", "Not working", hint: "No job means no pay. Open Jobs to apply for one.")
                }

                // Fame can pay too: brand deals, on top of any salary.
                if player.endorsementIncome > 0 {
                    moneyRow(
                        "🤝", "Endorsements", player.endorsementIncome, suffix: " / yr",
                        hint: "Brands pay famous people — athletes, stars and creators — to show off their products. The more 🎬 Entertainment fame you have, the more they pay, every year."
                    )
                }

                if showsTuition, let edu = player.currentEducation {
                    // What the student pays: the family covers its share.
                    let share = player.difficulty.familyTuitionShare
                    let yours = Int((Double(edu.annualTuition(in: player.country)) * (1 - share)).rounded())
                    moneyRow(
                        "🎓", "Tuition", -yours, suffix: " / yr",
                        hint: share > 0
                            ? "\(edu.degreeName(in: player.country)) costs \(player.money(edu.annualTuition(in: player.country))) a year. Your family pays \(pct(share)) of it, so you pay \(player.money(yours)) — from savings first, then as a student loan."
                            : "\(edu.degreeName(in: player.country)) costs \(player.money(edu.annualTuition(in: player.country))) a year while you study — from savings first, then as a student loan."
                    )
                }

                if player.outstandingLoan > 0 {
                    moneyRow(
                        "📉", "Venture loan owed", -player.outstandingLoan,
                        hint: "Money you borrowed to start a business. It grows by \(pct(GameConstants.ventureLoanAnnualInterest)) a year until it's paid back. Payments come out of your savings and pay each year."
                    )
                }

                if player.studentLoan > 0 {
                    moneyRow(
                        "🎓", "Student loan owed", -player.studentLoan,
                        hint: "Money you borrowed for school. It grows by \(pct(player.country.studentLoanInterest)) a year. You don't pay it back while you're studying — after that, payments come out of your savings and pay each year."
                    )
                }

                // The score is built on net worth; the tutorial keeps none.
                if player.difficulty.keepsScore {
                    Divider()
                    moneyRow(
                        "🏅", "Net worth", player.netWorth,
                        hint: "What you own minus what you owe: your savings (and any business you own) minus your loans. Divide it by your age and you get your score."
                    )
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Finances").font(.headline)
                InfoHint(title: "Finances", message: SectionHints.finances(simplified: player.isSimplified))
                Spacer()
                // Net worth stays visible while collapsed — the number that matters.
                Text("\(player.money(player.netWorth))")
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
        player.annualSaving(gross: job.annualIncome, atAge: player.age)
    }

    private func pct(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    /// One money line: icon, label, info hint, and a right-aligned signed amount.
    @ViewBuilder
    private func moneyRow(_ icon: String, _ label: String, _ amount: Int, suffix: String = "", hint: String) -> some View {
        labelledRow(
            icon, label,
            "\(player.money(amount))\(suffix)",
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
                    message: "Skills are the things you're good at, besides school and work experience. They help with:\n\n💼 Getting hired — every job lists the skills it needs\n⬆️ Promotions — doing your job well and being ready for the next one\n🎓 Getting into college — each subject looks for its own skills\n📝 School grades, 🏅 contests and 🚀 starting a business\n\nGrow them with Activities, and later with events, courses and projects. Tap a skill's ⓘ to see where it helps most."
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
            HStack(spacing: 6) {
                Text("Fame").font(.headline)
                InfoHint(title: "Fame", message: SectionHints.fame)
            }
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
                InfoHint(title: "Trophies", message: SectionHints.trophies)
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
                                Text(degree.degreeName(in: player.country))
                                Spacer()
                                // The diploma carries the grade universities read.
                                if degree.level == .HighSchool {
                                    Text(gpaLabel)
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
            HStack(spacing: 6) {
                Text("Credentials").font(.headline)
                InfoHint(title: "Credentials", message: SectionHints.credentials(simplified: player.isSimplified))
            }
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
                InfoHint(title: "Economy", message: SectionHints.economy)
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

        Every industry below feels the economy in its own way. Some, like \
        hotels and building, feel every up and down. Others, like schools and \
        hospitals, barely notice.

        Each industry also has good and bad years of its own — so one can be \
        struggling in a good year, or doing great in a bad one.
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
        var lines = [climate.blurb, ""]
        lines.append("🎯 Getting hired here: \(Self.easierOrHarder(climate.hireFactor))")
        lines.append("⬆️ Getting promoted here: \(Self.easierOrHarder(climate.promotionFactor))")
        lines.append("✂️ Chance of losing your job: \(Self.higherOrLower(climate.layoffFactor))")
        lines.append("🎲 Projects in this field: \(Self.easierOrHarder(climate.projectFactor))")

        lines.append("")
        if industry.beta > 1.0 {
            lines.append("📊 Feels the economy more than most — when money is tight, people cut back on this first.")
        } else if industry.beta < 1.0 {
            lines.append("📊 Feels the economy less than most — people still need it in hard times.")
        } else {
            lines.append("📊 Goes up and down with the economy.")
        }
        if industry.volatility > 1.0 {
            lines.append("🎲 It also has big ups and downs of its own.")
        } else if industry.volatility < 1.0 {
            lines.append("🎲 It mostly just follows the economy.")
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
            HStack(spacing: 6) {
                Text("Experience").font(.headline)
                InfoHint(title: "Experience", message: SectionHints.experience)
            }
        }
    }

    /// Plain-text breakdown of this year's promotion odds for the current job,
    /// mirroring the hire-probability InfoHint: the industry-weighted merit terms
    /// first, then the modifiers.
    private func promotionOddsSummary(for job: Job) -> String {
        let odds = player.promotionOdds(for: job)
        guard odds.promotes, let next = odds.nextRole else {
            return "There's no higher job to be promoted to from here. Your pay still goes up a little each year, up to a limit. To earn more, apply for a bigger job."
        }
        func signed(_ v: Double) -> String {
            let s = Int((v * 100).rounded())
            return s >= 0 ? "+\(s)%" : "\(s)%"
        }
        let gate = odds.eligible
            ? (odds.seat < 1 ? "\n\nThere aren't many \(next.displayTitle) jobs — only \(pct(odds.seat)) of the people who are ready get one." : "")
            : "\n\nYou can't be promoted to \(next.displayTitle) yet — you need what it asks for and enough years in this job first."
        let slowing = (odds.passedOver < 1 || odds.ageFade < 1)
            ? "\n• Promotions get harder after many years in the same job, and later in your career."
            : ""
        return """
        Each year you have a chance to be promoted to \(next.displayTitle). \(job.industry.promotionCultureBlurb)

        What counts:
        • How well you do your job: \(pct(odds.performance))
        • How ready you are for \(next.displayTitle): \(pct(odds.readiness))
        • Years in this job: \(odds.tenureYears) (full credit at \(GameConstants.promotionSeniorityYears))
        • People you know in \(job.category.rawValue): \(signed(odds.network))
        • Your fame in \(job.category.rawValue): \(signed(odds.fame))
        • Your schooling for this job: \(signed(odds.education))

        This year:
        • \(odds.climate.icon) \(job.industry.rawValue) is \(odds.climate.rawValue.lowercased()): \(Self.easierOrHarder(odds.climate.promotionFactor))\(slowing)

        Your chance this year: \(pct(odds.total))\(gate)
        """
    }

    /// A multiplier as plain words: "30% easier than usual", "normal".
    static func easierOrHarder(_ factor: Double) -> String {
        let p = Int(((factor - 1) * 100).rounded())
        if p == 0 { return "normal" }
        return p > 0 ? "\(p)% easier than usual" : "\(-p)% harder than usual"
    }

    /// A risk multiplier as plain words: "60% higher than usual", "normal".
    static func higherOrLower(_ factor: Double) -> String {
        let p = Int(((factor - 1) * 100).rounded())
        if p == 0 { return "normal" }
        return p > 0 ? "\(p)% higher than usual" : "\(-p)% lower than usual"
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

/// What each expandable section of the main screen is for — the ⓘ beside its
/// title. Kept together so the sections explain themselves in one voice.
private enum SectionHints {
    static func occupation(simplified: Bool) -> String {
        "What you're doing right now: your job, or the school you're at.\n\n"
            + (simplified
               ? "For a job, you'll see how many years you've been there."
               : "For a job, you'll see how many years you've been there and your chance of being promoted. Tap each ⓘ to learn more.")
    }

    static func finances(simplified: Bool) -> String {
        simplified
            ? "Your money. In Simplified mode you keep everything you earn."
            : "Your money: what you earn, what you save and what you owe.\n\nThe number on the right is what you own minus what you owe. Divide it by your age and you get your score — tap Score at the top to see it."
    }

    static let fame = "How well known you are in each field.\n\nYou get famous by winning contests, speaking at events, projects that work out and running your own company. Fame makes it easier to get hired and promoted in that field — and brands pay very famous entertainers."

    static let trophies = "Titles you've won in contests.\n\nEvery year you practise an activity, you're entered in its biggest contest. Trophies make you more famous, and top colleges like them."

    static func credentials(simplified: Bool) -> String {
        "Everything you've earned and keep: school diplomas and degrees"
            + (simplified ? "" : ", plus certificates and licences")
            + ".\n\nMany jobs need a certain degree"
            + (simplified ? "" : " or licence")
            + " before you can apply."
    }

    static let economy = "How the economy is doing this year — overall, and in each industry.\n\nIn a good year it's easier to get hired and promoted. In a bad year it's harder, and more people lose their jobs. Your own industry is shown in bold."

    static let experience = "How many years you've worked in each job.\n\nMany jobs need years of experience before they'll hire you, and years in the same kind of work help you move up."
}
