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
                            Text(L("\(yearsLeft) yrs left"))
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
                            hint: [
                                L("Your average school grade so far, over \(player.highSchoolGrades.count) years."),
                                L("School skills set each year's grade, and choosing a Study activity pushes it up."),
                                L("Universities look at it when you apply — the top ones care about it a lot."),
                            ].joined(separator: " ")
                        )
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Occupation").font(.headline)
                InfoHint(title: L("Occupation"), message: SectionHints.occupation(simplified: player.isSimplified))
                Spacer()
                // What you are, visible while collapsed: the job if you have
                // one, otherwise what you're studying.
                Text(occupationHeadline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.8)
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
        return "\(player.currentEducation?.pictogram ?? "") " + String(localized: "Student", comment: "Headline of the Occupation panel when the player is in school and has no job") // i18n:ignore translator comment
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
                Text(job.industry.displayName)
                InfoHint(
                    title: L("\(job.industry.icon) \(job.industry.displayName) — \(climate.displayName)"),
                    message: industrySummary(job.industry, climate)
                )
                Spacer()
                Text(verbatim: "\(climate.icon) \(climate.displayName)")
                    .foregroundStyle(climateTint(climate))
            }
        }

        let tenure = player.experienceByRole[job.baseTitle, default: 0]
        labelledRow(
            "🧭", L("In this role"), L("\(tenure) yrs"),
            hint: [
                L("How many years you've worked as \(job.displayBaseTitle)."),
                L("More years help you get promoted, and some jobs only hire people with enough years in this kind of work."),
            ].joined(separator: " ")
        )

        // Promotions are a realistic-mode mechanic only.
        if !player.isSimplified {
            let odds = player.promotionOdds(for: job)
            labelledRow(
                "⬆️", L("Promotion odds"),
                odds.promotes ? pct(odds.total) : "—",
                hint: promotionOddsSummary(for: job)
            )
            // The role above, and how ready the player is for it — the row that
            // says which skill to build next.
            if odds.promotes, let next = odds.nextRole {
                labelledRow(
                    "🎯", L("Ready for \(next.displayTitle)"), pct(odds.readiness),
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
                let label = SoftSkills.label(forKeyPath: kp) ?? String(localized: "Skill", comment: "Fallback name of a soft skill") // i18n:ignore translator comment
                let pic = SoftSkills.pictogram(forKeyPath: kp) ?? ""
                return L("\(pic) \(label): you have \(player.softSkills[keyPath: kp]), it needs \(required[keyPath: kp])")
            }
        guard !gaps.isEmpty else {
            return L("You already have every skill \(next.displayTitle) needs. 🎉 That helps your promotion chances as much as it can.")
        }
        return [
            L("How ready your skills are for \(next.displayTitle). Bosses like to promote people who can already do the next job — so growing these skills makes a promotion more likely:"),
            gaps.joined(separator: "\n"),
        ].joined(separator: "\n\n")
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
                    "💰", L("Savings"), player.savings,
                    hint: player.isSimplified
                        ? [
                            L("All the money you've earned so far."),
                            L("In Simplified mode you keep your whole paycheck."),
                        ].joined(separator: " ")
                        : L("The money you've saved. It grows by about \(pct(GameConstants.investmentReturn)) a year while it's above zero — but it can drop in a year when the economy turns bad.")
                )

                if let job = player.currentOccupation {
                    moneyRow(
                        "🧾", L("Gross income"), job.annualIncome, perYear: true,
                        hint: L("What \(job.displayTitle) pays in a year, before taxes and living costs.")
                    )
                    if !player.isSimplified {
                        moneyRow(
                            "🏦", L("Banked from pay"), bankedFromPay(job), perYear: true,
                            hint: [
                                L("The first \(player.money(player.livingCostFloor)) of your pay goes on living costs like rent and food."),
                                L("You save \(pct(player.difficulty.savingsRate)) of the rest (\(pct(GameConstants.highEarnerSavingsRate)) of anything over \(player.money(player.country.highEarnerThreshold)))."),
                                L("If you have no job, living costs come out of your savings."),
                            ].joined(separator: " ")
                        )
                    }
                } else if player.endorsementIncome == 0 {
                    labelledRow("🧾", L("Gross income"), L("Not working"), hint: L("No job means no pay. Open Jobs to apply for one."))
                }

                // Fame can pay too: brand deals, on top of any salary.
                if player.endorsementIncome > 0 {
                    let entertainment = FameCategory.entertainment
                    moneyRow(
                        "🤝", L("Endorsements"), player.endorsementIncome, perYear: true,
                        hint: [
                            L("Brands pay famous people — athletes, stars and creators — to show off their products."),
                            L("The more \(entertainment.icon) \(entertainment.displayName) fame you have, the more they pay, every year."),
                        ].joined(separator: " ")
                    )
                }

                if showsTuition, let edu = player.currentEducation {
                    // What the student pays: the family covers its share.
                    let share = player.difficulty.familyTuitionShare
                    let yours = Int((Double(edu.annualTuition(in: player.country)) * (1 - share)).rounded())
                    let degree = edu.degreeName(in: player.country)
                    let fullTuition = player.money(edu.annualTuition(in: player.country))
                    moneyRow(
                        "🎓", L("Tuition"), -yours, perYear: true,
                        hint: share > 0
                            ? L("\(degree) costs \(fullTuition) a year. Your family pays \(pct(share)) of it, so you pay \(player.money(yours)) — from savings first, then as a student loan.")
                            : L("\(degree) costs \(fullTuition) a year while you study — from savings first, then as a student loan.")
                    )
                }

                if player.outstandingLoan > 0 {
                    moneyRow(
                        "📉", L("Venture loan owed"), -player.outstandingLoan,
                        hint: [
                            L("Money you borrowed to start a business. It grows by \(pct(GameConstants.ventureLoanAnnualInterest)) a year until it's paid back."),
                            L("Payments come out of your savings and pay each year."),
                        ].joined(separator: " ")
                    )
                }

                if player.studentLoan > 0 {
                    moneyRow(
                        "🎓", L("Student loan owed"), -player.studentLoan,
                        hint: [
                            L("Money you borrowed for school. It grows by \(pct(player.country.studentLoanInterest)) a year."),
                            L("You don't pay it back while you're studying — after that, payments come out of your savings and pay each year."),
                        ].joined(separator: " ")
                    )
                }

                // The score is built on net worth; the tutorial keeps none.
                if player.difficulty.keepsScore {
                    Divider()
                    moneyRow(
                        "🏅", L("Net worth"), player.netWorth,
                        hint: [
                            L("What you own minus what you owe: your savings (and any business you own) minus your loans."),
                            L("Divide it by your age and you get your score."),
                        ].joined(separator: " ")
                    )
                }
            }
            .padding(.top, 4)
        } label: {
            HStack {
                Text("Finances").font(.headline)
                InfoHint(title: L("Finances"), message: SectionHints.finances(simplified: player.isSimplified))
                Spacer()
                // Net worth stays visible while collapsed — the number that matters.
                Text(player.money(player.netWorth))
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
        HintFmt.pct(value)
    }

    private func signed(_ value: Double) -> String {
        HintFmt.signed(value)
    }

    /// One money line: icon, label, info hint, and a right-aligned signed amount.
    @ViewBuilder
    private func moneyRow(_ icon: String, _ label: String, _ amount: Int, perYear: Bool = false, hint: String) -> some View {
        labelledRow(
            icon, label,
            perYear ? L("\(player.money(amount)) / yr") : player.money(amount),
            tint: amount < 0 ? .red : nil,
            hint: hint
        )
    }

    @ViewBuilder
    private func labelledRow(_ icon: String, _ label: String, _ value: String, tint: Color? = nil, hint: String) -> some View {
        HStack {
            Text(icon)
            Text(label)
                .fixedSize(horizontal: false, vertical: true)
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
                    title: L("Skills"),
                    message: [
                        L("Skills are the things you're good at, besides school and work experience. They help with:"),
                        [
                            L("💼 Getting hired — every job lists the skills it needs"),
                            L("⬆️ Promotions — doing your job well and being ready for the next one"),
                            L("🎓 Getting into college — each subject looks for its own skills"),
                            L("📝 School grades, 🏅 contests and 🚀 starting a business"),
                        ].joined(separator: "\n"),
                        L("Grow them with Activities, and later with events, courses and projects. Tap a skill's ⓘ to see where it helps most."),
                    ].joined(separator: "\n\n")
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
                        Text(verbatim: "🌟 \(Fmt.decimal(group.score))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack(spacing: 6) {
                Text("Fame").font(.headline)
                InfoHint(title: L("Fame"), message: SectionHints.fame)
            }
        }
    }

    /// Icon + name for a fame group's bucket (`nil` = general renown).
    private func fameCategoryLabel(_ category: FameCategory?) -> String {
        category.map { "\($0.icon) \($0.displayName)" }
            ?? String(localized: "🌐 General", comment: "Fame shelf row: renown that is not tied to one field") // i18n:ignore translator comment
    }

    // MARK: - Trophies

    /// The fame-shelf entries that came from winning a competition.
    private var trophies: [FameAward] {
        player.fameAwards.filter { CompetitionCatalog.achievementTitles.contains($0.key) }
    }

    /// Every competition title won, repeat wins shown as a count. The same
    /// trophies also bank fame in their field, which the Fame section totals.
    private var trophiesSection: some View {
        DisclosureGroup(isExpanded: $trophiesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(trophies) { trophy in
                    HStack {
                        Text(trophy.icon)
                        Text(trophy.displayTitle)
                        Spacer()
                        if trophy.count > 1 {
                            Text(verbatim: "×\(Fmt.number(trophy.count))")
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
                InfoHint(title: L("Trophies"), message: SectionHints.trophies)
                Spacer()
                Text(verbatim: "🏆 \(Fmt.number(trophies.reduce(0) { $0 + $1.count }))")
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
                    credentialGroup(title: L("Degrees")) {
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
                    credentialGroup(title: L("Certificates & licences")) {
                        ForEach(trainings) { training in
                            Text(verbatim: "\(training.friendlyName) \(training.pictogram)")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        } label: {
            HStack(spacing: 6) {
                Text("Credentials").font(.headline)
                InfoHint(title: L("Credentials"), message: SectionHints.credentials(simplified: player.isSimplified))
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
                    InfoHint(title: L("The economy"), message: macroSummary)
                    Spacer()
                    Text(player.macroClimate.displayName)
                        .foregroundStyle(climateTint(player.macroClimate))
                }
                .fontWeight(.semibold)

                if player.economyInRecession {
                    Text(player.turmoilYearsRemaining > 0
                         ? L("📉 Declared downturn — roughly \(player.turmoilYearsRemaining) more yrs to run.")
                         : L("📉 Declared downturn this year."))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Divider().padding(.vertical, 2)

                ForEach(player.industriesByClimate, id: \.industry) { row in
                    HStack {
                        Text(row.industry.icon)
                        Text(row.industry.displayName)
                        InfoHint(
                            title: L("\(row.industry.icon) \(row.industry.displayName) — \(row.climate.displayName)"),
                            message: industrySummary(row.industry, row.climate)
                        )
                        Spacer()
                        Text(row.climate.displayName)
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
                InfoHint(title: L("Economy"), message: SectionHints.economy)
                Spacer()
                // The player's own industry stays visible while collapsed — the
                // one climate that is affecting them right now.
                if let sector = player.currentOccupation?.industry {
                    let climate = player.climate(for: sector)
                    Text(verbatim: "\(climate.icon) \(climate.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(climateTint(climate))
                }
            }
        }
    }

    /// How the national cycle reaches each sector — the model in two sentences,
    /// since every row below is derived from it.
    private var macroSummary: String {
        [
            player.macroClimate.blurb,
            L("Every industry below feels the economy in its own way. Some, like hotels and building, feel every up and down. Others, like schools and hospitals, barely notice."),
            L("Each industry also has good and bad years of its own — so one can be struggling in a good year, or doing great in a bad one."),
        ].joined(separator: "\n\n")
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
        lines.append(L("🎯 Getting hired here: \(Self.easierOrHarder(climate.hireFactor))"))
        lines.append(L("⬆️ Getting promoted here: \(Self.easierOrHarder(climate.promotionFactor))"))
        lines.append(L("✂️ Chance of losing your job: \(Self.higherOrLower(climate.layoffFactor))"))
        lines.append(L("🎲 Projects in this field: \(Self.easierOrHarder(climate.projectFactor))"))

        lines.append("")
        if industry.beta > 1.0 {
            lines.append(L("📊 Feels the economy more than most — when money is tight, people cut back on this first."))
        } else if industry.beta < 1.0 {
            lines.append(L("📊 Feels the economy less than most — people still need it in hard times."))
        } else {
            lines.append(L("📊 Goes up and down with the economy."))
        }
        if industry.volatility > 1.0 {
            lines.append(L("🎲 It also has big ups and downs of its own."))
        } else if industry.volatility < 1.0 {
            lines.append(L("🎲 It mostly just follows the economy."))
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
                        Text(JobCatalog.displayBaseTitle(for: entry.role))
                        Spacer()
                        Text(L("\(entry.years) yrs"))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack(spacing: 6) {
                Text("Experience").font(.headline)
                InfoHint(title: L("Experience"), message: SectionHints.experience)
            }
        }
    }

    /// Plain-text breakdown of this year's promotion odds for the current job,
    /// mirroring the hire-probability InfoHint: the industry-weighted merit terms
    /// first, then the modifiers.
    private func promotionOddsSummary(for job: Job) -> String {
        let odds = player.promotionOdds(for: job)
        guard odds.promotes, let next = odds.nextRole else {
            return L("There's no higher job to be promoted to from here. Your pay still goes up a little each year, up to a limit. To earn more, apply for a bigger job.")
        }
        let title = next.displayTitle
        let category = job.category.displayName

        let counts = [
            L("What counts:"),
            L("• How well you do your job: \(pct(odds.performance))"),
            L("• How ready you are for \(title): \(pct(odds.readiness))"),
            L("• Years in this job: \(odds.tenureYears) (full credit at \(GameConstants.promotionSeniorityYears))"),
            L("• People you know in \(category): \(signed(odds.network))"),
            L("• Your fame in \(category): \(signed(odds.fame))"),
            L("• Your schooling for this job: \(signed(odds.education))"),
        ]

        var thisYear = [
            L("This year:"),
            HintFmt.climateNow(job.industry, odds.climate, Self.easierOrHarder(odds.climate.promotionFactor)),
        ]
        if odds.passedOver < 1 || odds.ageFade < 1 {
            thisYear.append(L("• Promotions get harder after many years in the same job, and later in your career."))
        }

        var paragraphs = [
            L("Each year you have a chance to be promoted to \(title).") + " " + job.industry.promotionCultureBlurb,
            counts.joined(separator: "\n"),
            thisYear.joined(separator: "\n"),
            L("Your chance this year: \(pct(odds.total))"),
        ]
        if !odds.eligible {
            paragraphs.append(L("You can't be promoted to \(title) yet — you need what it asks for and enough years in this job first."))
        } else if odds.seat < 1 {
            paragraphs.append(L("There aren't many \(title) jobs — only \(pct(odds.seat)) of the people who are ready get one."))
        }
        return paragraphs.joined(separator: "\n\n")
    }

    /// A multiplier as plain words: "30% easier than usual", "normal".
    static func easierOrHarder(_ factor: Double) -> String { HintFmt.easierOrHarder(factor) }

    /// A risk multiplier as plain words: "60% higher than usual", "normal".
    static func higherOrLower(_ factor: Double) -> String { HintFmt.higherOrLower(factor) }

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
        [
            L("What you're doing right now: your job, or the school you're at."),
            simplified
                ? L("For a job, you'll see how many years you've been there.")
                : L("For a job, you'll see how many years you've been there and your chance of being promoted. Tap each ⓘ to learn more."),
        ].joined(separator: "\n\n")
    }

    static func finances(simplified: Bool) -> String {
        if simplified {
            return L("Your money. In Simplified mode you keep everything you earn.")
        }
        return [
            L("Your money: what you earn, what you save and what you owe."),
            L("The number on the right is what you own minus what you owe. Divide it by your age and you get your score — tap Score at the top to see it."),
        ].joined(separator: "\n\n")
    }

    static var fame: String {
        [
            L("How well known you are in each field."),
            L("You get famous by winning contests, speaking at events, projects that work out and running your own company. Fame makes it easier to get hired and promoted in that field — and brands pay very famous entertainers."),
        ].joined(separator: "\n\n")
    }

    static var trophies: String {
        [
            L("Titles you've won in contests."),
            L("Every year you practise an activity, you're entered in its biggest contest. Trophies make you more famous, and top colleges like them."),
        ].joined(separator: "\n\n")
    }

    static func credentials(simplified: Bool) -> String {
        [
            simplified
                ? L("Everything you've earned and keep: school diplomas and degrees.")
                : L("Everything you've earned and keep: school diplomas and degrees, plus certificates and licences."),
            simplified
                ? L("Many jobs need a certain degree before you can apply.")
                : L("Many jobs need a certain degree or licence before you can apply."),
        ].joined(separator: "\n\n")
    }

    static var economy: String {
        [
            L("How the economy is doing this year — overall, and in each industry."),
            L("In a good year it's easier to get hired and promoted. In a bad year it's harder, and more people lose their jobs. Your own industry is shown in bold."),
        ].joined(separator: "\n\n")
    }

    static var experience: String {
        [
            L("How many years you've worked in each job."),
            L("Many jobs need years of experience before they'll hire you, and years in the same kind of work help you move up."),
        ].joined(separator: "\n\n")
    }
}