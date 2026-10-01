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
            posting.inIndustry($0).hireProbability(for: player, requestedSalary: Double(posting.offeredSalary(for: player))) > 0
        }
    }

    @State private var requestedSalary: Double = 0
    /// The outcome of the attempt just made. Kept only long enough to build the
    /// pop-up's text — the sheet closes, so nothing renders it inline.
    @State private var applicationResult: ApplicationResult? = nil

    enum ApplicationResult { case hired, rejected }

    private var sliderMin: Double { max(Double(player.country.minimumAnnualPay), Double(job.income) * 0.5) }
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
        return "\n\nSkills this job looks for (each one helps, even if you're only part of the way there):\n\n\(list)"
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
        guard allRequirementsMet else {
            let gaps = CareerGraph.missingHardRequirements(for: job, player: player)
            let needs = gaps.isEmpty
                ? "the right schooling, licences and experience"
                : gaps.joined(separator: "; ")
            return "You can't get this job yet. First you need: \(needs).\(softSkillsClause)"
        }

        let b = job.hireBreakdown(for: player, requestedSalary: requestedSalary)

        // Breakthrough gate: without the signature title, odds sit at the floor.
        if b.breakthroughMissing, let key = job.breakthroughFame {
            return "This career has a special door: you need the “\(key)” title first. Until then your chance stays at \(pct(b.floor)). \(breakthroughHowTo(key)) Once you have it, it's the biggest help there is — +\(Int((Job.breakthroughBonus * 100).rounded()))%.\(softSkillsClause)"
        }

        let asked = job.askedSoftSkills.count
        let matched = job.softSkillsHelpfulScore(for: player)
        let fit = b.requirements
        let shortfall = job.educationShortfall(for: player)
        let madeUp = shortfall - job.creditedEducationShortfall(for: player)
        let schoolLabel: String = {
            if shortfall > 0 {
                let short = "\(shortfall) school level\(shortfall == 1 ? "" : "s") below what this job wants"
                return madeUp > 0 ? short + " (your work experience makes up \(madeUp))" : short
            }
            if job.degreePreferenceFactor(for: player) < 1 { return "employers here prefer a university degree" }
            if job.requirements.education.minEQF < 5 { return "you have the schooling it needs" }
            return job.hasAcceptedDegree(for: player) ? "you have the right degree" : "you have a degree, but in a different subject"
        }()
        let fameLabel = job.category.fameCategory?.rawValue ?? "general"
        let climate = player.climate(for: job.industry)
        let topPrestige = (player.degrees.filter { $0.profile != nil }.map { $0.tier.prestige }.max() ?? 0)
        let schoolName: String = {
            switch topPrestige {
            case 3: return player.country.tierName(.elite)
            case 2: return player.country.tierName(.state)
            default: return "your school"
            }
        }()
        let expYears = job.expectedYearsExperience
        let playerYears = job.relevantYears(for: player)

        /// A multiplier in plain words.
        func effect(_ f: Double) -> String {
            if f == 0 { return "closes this job for now" }
            let p = Int(((f - 1) * 100).rounded())
            if p == 0 { return "no change" }
            return p > 0 ? "+\(p)% boost" : "cuts your chance to \(Int((f * 100).rounded()))% of normal"
        }

        var helps = [
            "• Your skills: \(matched) of \(asked) are strong enough (\(pct(b.skillFit)) match)",
            "• Starting chance for this kind of job: \(pct(b.base)) (jobs that need more school start lower)",
        ]
        if b.prestige != 0 { helps.append("• A degree from \(schoolName): \(signed(b.prestige))") }
        if b.network != 0 { helps.append("• People you know in \(job.category.rawValue): \(signed(b.network))") }
        if b.fame > 0 { helps.append("• Your fame (\(fameLabel)): \(signed(b.fame))") }
        if job.breakthroughFame != nil { helps.append("• Your “\(job.breakthroughFame ?? "")” title: \(signed(b.breakthrough))") }
        if b.credential > 0 { helps.append("• A course for this field: \(signed(b.credential))") }

        let salaryLine: String = {
            if b.salaryFit > 1 { return "asking for less helps a little (\(effect(b.salaryFit)))" }
            if b.salaryFit < 1 { return "asking for a lot more \(effect(b.salaryFit))" }
            return "fair ✓"
        }()

        var market: [String] = []
        if b.demand < 1 { market.append("• Lots of people want this job: \(effect(b.demand))") }
        if b.demand > 1 { market.append("• Employers need more \(job.baseTitle)s: \(effect(b.demand))") }
        if job.rung > 0 { market.append("• Joining above the starting level: \(effect(b.rungDecay))") }
        market.append("• \(climate.icon) \(job.industry.rawValue) is \(climate.rawValue.lowercased()) this year: \(effect(b.climate))")
        if b.seat < 1 {
            market.append("• Only a few people get a job like this each year: \(pct(b.seat)) of the people who qualify\(job.isExecutive ? " (having run your own company helps)" : "")")
        }

        return """
        Your chance: \(pct(b.final))

        What helps:
        \(helps.joined(separator: "\n"))

        Your school and experience:
        • School: \(schoolLabel) — \(effect(fit.education))
        • Licences: \(fit.credentials > 0 ? "all set ✓" : "missing")
        • Experience: \(expYears == 0 ? "none needed ✓" : "\(playerYears) of \(expYears) years — \(effect(fit.experience))")
        • Your salary ask: \(salaryLine)

        This year's job market:
        \(market.joined(separator: "\n"))\(softSkillsClause)
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
                Text(player.money(job.income))
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
                        message: "You don't strictly need it — but it helps every time you apply and every time you could be promoted. A degree in the right subject helps most, a degree in another subject helps less, and having less schooling than this makes it harder."
                    )
                }
                Spacer()
            }
            .padding()

            let eduPlayerLevel = job.playerEducationLevel(for: player)
            let eduRequired = job.requirements.education.minEQF
            RequirementRow(
                label: job.requirements.education.educationLabel(in: player.country),
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
                    footnote: "Not needed — but one of these makes it easier to get hired in this field, and counts as one level of the schooling a job here wants."
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
                     ? "You have it! This is the biggest help there is for getting signed."
                     : "\(breakthroughHowTo(key)) Without it, teams won't sign you (your chance stays at \(Int((GameConstants.hireFloor * 100).rounded()))%).")
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
            // The offer for this applicant: the median adjusted for their
            // experience — what a posted-rate role pays and where the slider
            // starts (`Job.offeredSalary`).
            requestedSalary = Double(job.offeredSalary(for: player))
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
            ? "This job wants \(baseYears) years of experience. With less than \(floorYears), you can't apply yet. In between you can, but each missing year makes it much harder. Every year over \(baseYears) helps a little more."
            : "You need \(baseYears) years of experience to apply. Every extra year helps a little more."
        if job.isLadderVariant {
            text += "\n\nYears as \(job.baseTitle) count fully. Other years in \(JobCategory.icon(for: job.category)) \(job.category.rawValue) count half."
        }
        // Related industries are credited too — notably, entrepreneurship
        // experience counts toward Business roles.
        let credited = job.category.creditedExperienceCategories
        if !credited.isEmpty {
            let names = credited
                .map { "\(JobCategory.icon(for: $0)) \($0.rawValue)" }
                .joined(separator: ", ")
            text += job.isLadderVariant
                ? "\n\nYears in \(names) count half too."
                : "\n\nYears in \(names) count too."
        }
        return text
    }

    private var postedSalarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Salary:")
                    .font(.title2.bold())
                if !isSimplified {
                    InfoHint(title: "💵 Salary", message: "This job pays a set amount — you can't ask for more. It starts a bit lower for beginners and a bit higher if you have years of experience in this work.")
                }
                Spacer()
                Text("\(player.money(job.offeredSalary(for: player)))/yr")
                    .font(.headline)
            }
            .padding(.horizontal)


            HStack(spacing: 6) {
                Text(allRequirementsMet ? "✓ You can apply for this job." : lockedMessage)
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
                message: "Every kind of company needs a \(posting.id). Pick which one to apply to. Some industries are doing better than others this year — that changes your chance of getting hired, and how your pay and promotions go while you work there."
            )
            Spacer()
            Picker("Employer", selection: Binding(
                get: { industryChoice ?? posting.industry },
                set: { industryChoice = $0 }
            )) {
                ForEach(industryOptions) { industry in
                    // The same salary and rounding as the hire-probability row,
                    // so the menu and the page agree.
                    let salary = requestedSalary > 0 ? requestedSalary : Double(posting.offeredSalary(for: player))
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
            Text("Chance to get hired:")
            InfoHint(
                title: "What your chance depends on",
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
            Text("Ask for a salary")
                .font(.title2.bold())
                .padding(.horizontal)

            HStack {
                Text("Your ask:")
                Spacer()
                Text("\(player.money(Int(requestedSalary)))")
                    .font(.headline)
            }
            .padding(.horizontal)

            Slider(value: $requestedSalary, in: sliderMin...sliderMax, step: Double(player.country.moneyStep))
                .padding(.horizontal)

            HStack {
                Text("\(player.money(Int(sliderMin)))")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(player.money(Int(sliderMax)))")
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
        case "Junior Champion": return "Win a Junior Championship as a teen. Practise a sport for years to get better at it."
        default:                return "Earn the “\(key)” title first."
        }
    }

    /// What to say on a win. The header already shows the new job, so this says
    /// what it means rather than repeating the title.
    private var successMessage: String {
        "You start as \(job.displayTitle) on \(player.money(Int(requestedSalary))) a year."
    }

    private func resultMessage(_ result: ApplicationResult) -> String {
        result == .hired ? "🎉 Offer accepted!" : "❌ No offer this time."
    }

    /// Explains *why* an application was turned down and what the player can do
    /// about it — a rejection is otherwise a silent dead end. Requirements are
    /// already met (the button gates on that), so a "no" is either the
    /// breakthrough gate, a too-high salary ask, or simply losing the odds roll;
    /// this names the dominant lever and points at the ⓘ breakdown. Simplified
    /// mode never rejects a qualified applicant, so this only fires in Real
    /// Life.
    private var rejectionAdvice: String? {
        guard applicationResult == .rejected else { return nil }
        func pct(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }

        // The breakthrough gate (e.g. a pro-player role needing a junior title)
        // pins odds at the hiring floor — by far the likeliest reason for a
        // "no", so call it out first.
        if let key = job.breakthroughFame,
           !player.fameAwards.contains(where: { $0.title == key }) {
            return "Teams here want the “\(key)” title — win it first to open this career."
        }

        return "You had a \(pct(hireProbability)) chance, and this time it didn't work out. Don't give up — try again next year!"
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
            let salary = requestedSalary.isFinite ? Int(requestedSalary) : job.offeredSalary(for: player)
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

