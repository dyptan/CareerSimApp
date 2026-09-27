import SwiftUI

struct JobDetail: View {
    /// The posting as listed. `job` is what the player is applying to: the same
    /// posting, at the employer industry they picked (see `industryChoice`).
    private let posting: Job
    @ObservedObject var player: Player
    @Binding var showCareersSheet: Bool
    /// Applying spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    init(job: Job, player: Player, showCareersSheet: Binding<Bool>, onCommit: @escaping () -> Void = {}) {
        self.posting = job
        self.player = player
        self._showCareersSheet = showCareersSheet
        self.onCommit = onCommit
    }

    /// The employer industry chosen for a role that offers the choice.
    @State private var industryChoice: Industry?

    private var job: Job {
        industryChoice.map { posting.inIndustry($0) } ?? posting
    }

    /// The industries the player can apply to this role in: every one where
    /// their hire odds at the posted rate are above zero.
    private var industryOptions: [Industry] {
        posting.possibleIndustries.filter {
            posting.inIndustry($0).hireProbability(for: player, requestedSalary: Double(posting.annualIncome)) > 0
        }
    }

    @State private var requestedSalary: Double = 0
    /// The outcome of the attempt just made. Kept only long enough to build the
    /// pop-up's text — the sheet closes, so nothing renders it inline.
    @State private var applicationResult: ApplicationResult? = nil

    enum ApplicationResult { case hired, rejected }

    private var sliderMin: Double { Double(job.income) * 0.5 }
    private var sliderMax: Double { Double(job.income) * 2.0 }

    private var isSimplified: Bool { player.isSimplified }
    private var requiredSoft: SoftSkills { job.requirements.softSkills }
    private var requiredHard: HardSkills { job.requirements.hardSkills }
    private var allRequirementsMet: Bool { job.allRequirementsMet(for: player) }
    private var hireProbability: Double {
        job.hireProbability(for: player, requestedSalary: requestedSalary)
    }

    private var applyButtonLabel: String {
        if !allRequirementsMet { return isSimplified ? "Requirements not met" : "Hard requirements not met" }
        return "Apply"
    }

    /// The soft skills that feed the hire-probability skill match, each with the
    /// level the employer looks for. Surfaced in the InfoHint so the list isn't
    /// cluttering the requirements page.
    private var softSkillsClause: String {
        let considered = SoftSkills.skillNames.filter { requiredSoft[keyPath: $0.keyPath] > 0 }
        guard !considered.isEmpty else { return "" }
        let list = considered
            .map { axis -> String in
                let target = requiredSoft[keyPath: axis.keyPath]
                let held = player.softSkills[keyPath: axis.keyPath]
                return "\(axis.pictogram) \(axis.label): \(min(held, target))/\(target)"
            }
            .joined(separator: "\n")
        return "\n\nThe skills this role asks for — each counts in proportion, and "
            + "nothing else is scored:\n\n\(list)"
    }

    /// Plain-language breakdown of the hire-probability formula with the
    /// player's *current* numbers plugged in. Shown in the InfoHint popover.
    /// Every figure is read off `Job.hireBreakdown` — the same terms the roll
    /// uses — so the explanation can't drift from the odds.
    private var hireProbabilityFormulaText: String {
        func pct(_ v: Double) -> String {
            "\(Int((v * 100).rounded()))%"
        }
        func signed(_ v: Double) -> String {
            let s = Int((v * 100).rounded())
            return s >= 0 ? "+\(s)%" : "\(s)%"
        }
        func times(_ v: Double) -> String { "×\(String(format: "%.2f", v))" }

        guard allRequirementsMet else {
            let gaps = CareerGraph.missingHardRequirements(for: job, player: player)
            let needs = gaps.isEmpty
                ? "the required degree, licences and experience"
                : gaps.joined(separator: "; ")
            return "Hire chance is 0% until you have: \(needs).\(softSkillsClause)"
        }

        let b = job.hireBreakdown(for: player, requestedSalary: requestedSalary)

        // Breakthrough gate: without the signature title, odds sit at the floor.
        if b.breakthroughMissing, let key = job.breakthroughFame {
            return "This career is gated on a breakthrough achievement. Hire chance stays at the \(pct(b.floor)) floor until you earn the “\(key)” title. \(breakthroughHowTo(key)) Earn it and it becomes the single biggest factor in getting signed — worth +\(Int((Job.breakthroughBonus * 100).rounded()))% on top of the usual skill, experience, and fame terms.\(softSkillsClause)"
        }
        let hasBreakthrough = job.breakthroughFame != nil

        let asked = job.askedSoftSkills.count
        let matched = job.softSkillsHelpfulScore(for: player)
        let fit = b.requirements
        let shortfall = job.educationShortfall(for: player)
        let madeUp = shortfall - job.creditedEducationShortfall(for: player)
        let educationFitLabel: String = {
            guard shortfall > 0 else {
                return job.hasAcceptedDegree(for: player) ? "degree in an accepted field" : "degree, but an unrelated field"
            }
            let short = "\(shortfall) level\(shortfall == 1 ? "" : "s") below what this role expects"
            return madeUp > 0 ? short + ", \(madeUp) made up by equivalent experience" : short
        }()
        let topPosition = job.isTopLeadership
        let fameLabel = job.category.fameCategory?.rawValue ?? "general"
        let climate = player.climate(for: job.industry)

        let topPrestige = (player.degrees.map { $0.tier.prestige }.max() ?? 0)
        let prestigeLabel: String = {
            switch topPrestige {
            case 3: return "Elite"
            case 2: return "State"
            case 1: return "Community"
            default: return "no degree"
            }
        }()

        let expYears = job.expectedYearsExperience
        let playerYears = job.relevantYears(for: player)

        var bring = [
            "• Base (the role expects \(job.requirements.education.educationLabel())): \(pct(b.base))",
            "• Skill match: \(matched)/\(asked) skills met, \(pct(b.skillFit)) fit → \(pct(b.skill))",
            "• Degree prestige (\(prestigeLabel)): \(signed(b.prestige))",
            "• Network (\(job.category.rawValue)): \(signed(b.network))",
        ]
        if b.fame > 0 {
            bring.append("• Fame (\(fameLabel))\(topPosition ? " — top role, weighted heavily" : ""): \(signed(b.fame))")
        }
        if hasBreakthrough {
            bring.append("• Breakthrough (\(job.breakthroughFame ?? "") title): \(signed(b.breakthrough))")
        }
        if b.credential > 0 {
            bring.append("• Relevant credential: \(signed(b.credential))")
        }

        var market: [String] = []
        if b.demand != 1 {
            market.append(b.demand < 1
                ? "• \(job.baseTitle) roles are oversubscribed: \(times(b.demand))"
                : "• Employers are short of \(job.baseTitle)s: \(times(b.demand))")
        }
        if job.rung > 0 {
            market.append("• Hiring in from outside, \(job.rung) rung\(job.rung == 1 ? "" : "s") above entry: \(times(b.rungDecay))")
        }
        market.append("• \(climate.icon) \(job.industry.rawValue) is \(climate.rawValue.lowercased()): \(times(b.climate))")
        if b.opportunity != 1 {
            market.append("• \(player.difficulty.title) difficulty: \(times(b.opportunity))")
        }

        var product = "\(pct(b.merit)) × \(String(format: "%.2f", fit.factor)) × \(pct(b.salaryFit))"
        for factor in [b.demand, b.rungDecay, b.climate, b.opportunity] where factor != 1 {
            product += " × \(String(format: "%.2f", factor))"
        }
        product += " = \(pct(b.scaled))"

        let seatLine: String = b.seat < 1
            ? "\nThen the seat: only a few qualified candidates land a seat like this each year — \(times(b.seat))\(job.isExecutive ? ", eased by a founder track record (years running ventures, rounds, exits)" : "")."
            : ""
        let finalLine = b.seat < 1
            ? "Final (clamped \(pct(b.floor))–\(pct(b.ceiling)), then × the seat): \(pct(b.final))"
            : "Final (clamped \(pct(b.floor))–\(pct(b.ceiling))): \(pct(b.final))"

        return """
        Formula: what you bring × how well you meet the requirements × salary fit × the market.

        What you bring:
        \(bring.joined(separator: "\n"))
        Subtotal: \(pct(b.merit))

        How well you meet the requirements (these multiply — a requirement you
        can't meet at all is ×0, which closes the role):
        • Education (\(educationFitLabel)): \(times(fit.education))
        • Licences and certificates: \(times(fit.credentials))
        • Experience (\(playerYears)/\(expYears) yr expected): \(times(fit.experience))
        • Salary fit: \(pct(b.salaryFit))

        The market:
        \(market.joined(separator: "\n"))

        \(product)\(seatLine)
        \(finalLine)
        \(softSkillsClause)
        """
    }

    var body: some View {
        ScrollView {
            Text(job.icon)

                .font(.system(size: 96))
                .padding(.top, 16)

            HStack(spacing: 8) {
                Text(job.id)
                    .font(.largeTitle.bold())
                InfoHint(title: "\(job.icon) \(job.id)", message: job.summary)
            }
            .padding()

            HStack(spacing: 12) {
                Text("Market median")
                Text("\(job.income) $")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            if posting.offersIndustryChoice, industryOptions.count > 1 {
                industryPicker
            }
            
            Divider()
            Text("Requirements")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()



            HStack(spacing: 6) {
                Text(job.educationIsMandatory ? "Education:" : "Education (preferred):")
                    .font(.headline)
                if !job.educationIsMandatory && job.requirements.education.minEQF > 0 {
                    InfoHint(
                        title: "🎓 Preferred education",
                        message: "Not required — but it counts on every application and every promotion. A degree in an accepted field counts most, an unrelated one a little, and falling short of this level costs you."
                    )
                }
                Spacer()
            }
            .padding()

            let eduPlayerLevel = job.playerEducationLevel(for: player)
            let eduRequired = job.requirements.education.minEQF
            RequirementRow(
                label: job.requirements.education.educationLabel(),
                emoji: "🎓",
                style: .meter(current: eduPlayerLevel, required: eduRequired)
            )
            .foregroundStyle(eduPlayerLevel >= eduRequired ? .primary : .secondary)
            .padding(.horizontal)

            if let acceptedProfiles = job.requirements.education.acceptedProfiles, !acceptedProfiles.isEmpty {
                let playerProfiles = Set(player.degrees.compactMap { $0.profile })
                let fieldMet = playerProfiles.contains { acceptedProfiles.contains($0) }
                RequirementRow(
                    label: "Field: " + acceptedProfiles.map { $0.rawValue.capitalized }.joined(separator: " / "),
                    emoji: "📚",
                    style: .badge(isMet: fieldMet)
                )
                .foregroundStyle(fieldMet ? .primary : .secondary)
                .padding(.horizontal)
            }

            // Experience is a hard gate at the role's baseline; above that, the
            // employer's tier-scaled preference shapes the hire probability.
            let baseYears = job.requirements.minYearsExperience
            if baseYears > 0 {
                HStack(spacing: 6) {
                    Text("Experience:")
                        .font(.headline)
                    if !isSimplified {
                        InfoHint(title: "📅 Experience", message: experienceHint(baseYears: baseYears))
                    }
                    Spacer()
                }
                .padding()

                let playerYears = job.relevantYears(for: player)
                let expLabel = job.isLadderVariant
                    ? "\(baseYears) yr as \(job.baseTitle)"
                    : "\(baseYears) yr in \(job.category.rawValue)"
                RequirementRow(
                    label: expLabel,
                    emoji: "📅",
                    style: .meter(current: playerYears, required: baseYears)
                )
                .foregroundStyle(playerYears >= baseYears ? .primary : .secondary)
                .padding(.horizontal)

            }

            if !isSimplified && !requiredHard.trainings.isEmpty {
                credentialSection(
                    title: "Trainings:",
                    trainings: Array(requiredHard.trainings).sorted(by: { $0.rawValue < $1.rawValue })
                )
            }

            // Preferred (helpful) credentials — non-gating skill-building programs
            // whose careerBoost covers this field. Never required; holding one
            // lifts the hire odds (see Player.trainingCareerBonus) and stands in
            // for one level of missing schooling (Job.equivalentExperienceCredit).
            // One the role already lists above isn't repeated here.
            let helpfulTrainings = (Training.helpfulByCategory[job.category] ?? [])
                .filter { !requiredHard.trainings.contains($0) }
            if !isSimplified && !helpfulTrainings.isEmpty {
                credentialSection(
                    title: "Preferred (helpful):",
                    trainings: helpfulTrainings,
                    footnote: "Not required — a relevant credential raises your hire odds in this field, and counts as one level of the schooling a role here expects."
                )
            }

            // Breakthrough fame award: the gateway achievement for gated careers
            // (e.g. a junior-competition win for Professional Player). Applies in
            // every mode, so it's shown regardless of simplified/realistic.
            if let key = job.breakthroughFame {
                let held = player.fameAwards.contains { $0.title == key }
                Text("Breakthrough:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                RequirementRow(label: "\(key) title", emoji: "🏅", style: .badge(isMet: held))
                    .foregroundStyle(held ? .primary : .secondary)
                    .padding(.horizontal)

                Text(held
                     ? "This is the single biggest factor in getting signed."
                     : "\(breakthroughHowTo(key)) Without it, you won't be signed (odds stay at \(Int((GameConstants.hireFloor * 100).rounded()))%).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            Divider()

            if canNegotiate {
                salaryNegotiationSection
            } else {
                postedSalarySection
            }

            applyButton
        }
        .onAppear {
            requestedSalary = Double(job.income)
        }
    }

    /// A titled list of credential rows, marked met/unmet against what the
    /// player holds — used for both the required and the preferred credentials.
    @ViewBuilder
    private func credentialSection(title: String, trainings: [Training], footnote: String? = nil) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

        ForEach(trainings, id: \.self) { training in
            let owned = player.hardSkills.trainings.contains(training)
            RequirementRow(label: training.friendlyName, emoji: training.pictogram, style: .badge(isMet: owned))
                .foregroundStyle(owned ? .primary : .secondary)
                .padding(.horizontal)
        }

        if let footnote {
            Text(footnote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
    }

    // MARK: - Employee application (pay)

    /// Whether this application offers a salary slider. Simplified mode never
    /// negotiates — it keeps the money simple — and neither do roles that pay a
    /// posted rate (see `Job.salaryIsNegotiable`).
    private var canNegotiate: Bool { !isSimplified && job.salaryIsNegotiable }

    /// Pay for a role you take at the advertised rate. Still shows the hire
    /// odds in the realistic modes — what you can't argue about, you can still
    /// weigh.
    /// The experience ⓘ: the qualifying bar (the same arithmetic as
    /// `Job.experienceFactor`, via `minimumQualifyingYears`), that more years
    /// help, and which other experience is credited here.
    private func experienceHint(baseYears: Int) -> String {
        let floorYears = job.minimumQualifyingYears(simplified: false)
        var text = floorYears < baseYears
            ? "\(baseYears) yr expected. With under \(floorYears) yr the role is closed; in between, every missing year costs you a lot — the odds scale with the square of the share you have. Every year beyond \(baseYears) raises your hire chance a little."
            : "\(baseYears) yr required to qualify — every extra year raises your hire chance a little."
        if job.isLadderVariant {
            text += "\n\nYears as \(job.baseTitle) count in full; your other \(JobCategory.icon(for: job.category)) \(job.category.rawValue) years count half."
        }
        // Related industries are credited too — notably, entrepreneurship
        // experience counts toward Business roles.
        let credited = job.category.creditedExperienceCategories
        if !credited.isEmpty {
            let names = credited
                .map { "\(JobCategory.icon(for: $0)) \($0.rawValue)" }
                .joined(separator: ", ")
            text += job.isLadderVariant
                ? "\n\nYour \(names) experience counts at half value too."
                : "\n\nYour \(names) experience counts toward this too."
        }
        return text
    }

    private var postedSalarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Salary:")
                    .font(.title2.bold())
                if !isSimplified {
                    InfoHint(title: "💵 Salary", message: "This role pays the going rate — there's no offer to argue over.")
                }
                Spacer()
                Text("\(job.income.formatted(.number)) $/yr")
                    .font(.headline)
            }
            .padding(.horizontal)


            HStack(spacing: 6) {
                Text(allRequirementsMet ? "✓ You qualify for this role." : lockedMessage)
                    .font(.subheadline)
                    .foregroundStyle(allRequirementsMet ? Color.green : Color.secondary)
                Spacer()
            }
            .padding(.horizontal)

            if !isSimplified {
                hireProbabilityRow
            }
        }
        .padding(.vertical)
    }

    /// The odds readout, shared by both pay sections so it reads the same either
    /// way.
    /// Which kind of organisation to apply to, each with this year's hire odds
    /// there — the industry's climate is what moves them.
    private var industryPicker: some View {
        HStack(spacing: 6) {
            Text("🏢 Employer")
                .font(.subheadline)
            InfoHint(
                title: "🏢 Employer's industry",
                message: "\(posting.id) roles exist in every kind of organisation. Pick which to apply to — each industry's climate this year moves your hire odds there, and decides how your pay and promotions fare while you work in it."
            )
            Spacer()
            Picker("Employer", selection: Binding(
                get: { industryChoice ?? posting.industry },
                set: { industryChoice = $0 }
            )) {
                ForEach(industryOptions) { industry in
                    // The same salary and rounding as the hire-probability row,
                    // so the menu and the page agree.
                    let salary = requestedSalary > 0 ? requestedSalary : Double(posting.income)
                    let odds = posting.inIndustry(industry).hireProbability(for: player, requestedSalary: salary)
                    Text("\(industry.icon) \(industry.rawValue) · \(Int(odds * 100))%")
                        .tag(industry)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
    }

    private var hireProbabilityRow: some View {
        HStack(spacing: 6) {
            Text("Hire probability:")
            InfoHint(
                title: "How hire probability is calculated",
                message: hireProbabilityFormulaText
            )
            Spacer()
            Text("\(Int(hireProbability * 100)) %")
                .font(.headline)
                .foregroundStyle(Color.forOdds(hireProbability))
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var salaryNegotiationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Salary negotiation")
                .font(.title2.bold())
                .padding(.horizontal)

            HStack {
                Text("Your ask:")
                Spacer()
                Text("\(Int(requestedSalary).formatted(.number)) $")
                    .font(.headline)
            }
            .padding(.horizontal)

            Slider(value: $requestedSalary, in: sliderMin...sliderMax, step: 500)
                .padding(.horizontal)

            HStack {
                Text("\(Int(sliderMin).formatted(.number)) $")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(sliderMax).formatted(.number)) $")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            hireProbabilityRow
        }
        .padding(.vertical)
    }

    // MARK: - Shared apply button

    /// How the player earns a gated career's breakthrough award — the rare
    /// achievement that unlocks it. Keyed by the award title so the copy stays
    /// accurate as new star tracks are added.
    private func breakthroughHowTo(_ key: String) -> String {
        switch key {
        case "Junior Champion": return "Win a Junior Championship as a teen — train a sport for years to raise your odds."
        default:                return "Earn the “\(key)” title first."
        }
    }

    /// What to say on a win. The header already shows the new job, so this says
    /// what it means rather than repeating the title.
    private var successMessage: String {
        "You start as \(job.displayTitle) on \(Int(requestedSalary).formatted(.number)) $ a year."
    }

    private func resultMessage(_ result: ApplicationResult) -> String {
        result == .hired ? "🎉 Offer accepted!" : "❌ No offer this time."
    }

    /// Explains *why* an application was turned down and what the player can do
    /// about it — a rejection is otherwise a silent dead end. Requirements are
    /// already met (the button gates on that), so a "no" is either the
    /// breakthrough gate, a too-high salary ask, or simply losing the odds roll;
    /// this names the dominant lever and points at the ⓘ breakdown. Simplified
    /// mode never rejects a qualified applicant, so this only fires in the
    /// realistic settings.
    private var rejectionAdvice: String? {
        guard applicationResult == .rejected else { return nil }
        func pct(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }

        // The breakthrough gate (e.g. a pro-player role needing a junior title)
        // pins odds at the hiring floor — by far the likeliest reason for a
        // "no", so call it out first.
        if let key = job.breakthroughFame,
           !player.fameAwards.contains(where: { $0.title == key }) {
            return "Employers here look for the “\(key)” title — earn it first to unlock this career."
        }

        return "Your odds were \(pct(hireProbability)) and the roll didn't land. Try again next year."
    }

    private var applyDisabled: Bool { !allRequirementsMet }

    /// What still stands between the player and this role, for the posted-pay
    /// section: the first hard gap (`CareerGraph.missingHardRequirements`, the
    /// same gates the Apply button checks) — an age, a degree, a licence or
    /// years of experience.
    private var lockedMessage: String {
        guard let gap = CareerGraph.missingHardRequirements(for: job, player: player).first else {
            return "🔒 Not open to you yet."
        }
        return "🔒 First: \(gap)."
    }

    private var applyButton: some View {
        Button {
            // Convert defensively: a degenerate slider state could leave the
            // bound value non-finite, and Int(_:) traps on NaN/infinity.
            let salary = requestedSalary.isFinite ? Int(requestedSalary) : job.income
            let success = player.applyForJob(job, requestedSalary: salary)
            // Applying is how the year was spent, offer or no offer, so the
            // answer is a pop-up on the game view rather than a banner in a
            // sheet the player is about to leave. A "no" still explains itself
            // and what to change before next year.
            applicationResult = success ? .hired : .rejected
            player.reportApplicationOutcome(
                title: resultMessage(success ? .hired : .rejected),
                message: rejectionAdvice ?? successMessage
            )
            onCommit()
        } label: {
            Text(applyButtonLabel)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(applyDisabled)
        .opacity(applyDisabled ? 0.5 : 1.0)
        .padding()
    }
}

#Preview {
    NavigationStack {
        JobDetail(
            job: jobExample,
            player: Player(),
            showCareersSheet: .constant(true)
        )
    }
}

