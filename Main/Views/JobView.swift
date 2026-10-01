import SwiftUI

/// Number and phrase helpers shared by the hint builders on the Jobs and Skills screens.
/// Every figure goes through `Fmt`, and every phrase is a whole localized sentence part.
enum HintFmt {
    /// 0.734 -> "73%".
    static func pct(_ v: Double) -> String { Fmt.percent(v) }

    /// +0.2 -> "+20%", -0.05 -> "-5%"; a change that rounds to nothing reads "+0%".
    static func signed(_ v: Double) -> String {
        Int((v * 100).rounded()) == 0 ? "+" + Fmt.percent(0) : Fmt.signedPercent(v)
    }

    /// A hire/odds readout. Truncates rather than rounds, so 99.6% never reads "100%".
    static func oddsPercent(_ p: Double) -> String {
        Fmt.percent(Double(Int(p * 100)) / 100)
    }

    /// A multiplier in plain words.
    static func effect(_ f: Double) -> String {
        if f == 0 { return L("closes this job for now") }
        let p = Int(((f - 1) * 100).rounded())
        if p == 0 {
            return String(localized: "no change", comment: "Plain-words effect of a modifier on the chance to be hired: it changes nothing") // i18n:ignore translator comment
        }
        return p > 0 ? L("\(Fmt.signedPercent(f - 1)) boost") : L("cuts your chance to \(Fmt.percent(f)) of normal")
    }

    /// A multiplier as plain words: "30% easier than usual", "normal".
    static func easierOrHarder(_ factor: Double) -> String {
        let p = Int(((factor - 1) * 100).rounded())
        if p == 0 { return normal }
        return p > 0 ? L("\(Fmt.percent(Double(p) / 100)) easier than usual") : L("\(Fmt.percent(Double(-p) / 100)) harder than usual")
    }

    /// A risk multiplier as plain words: "60% higher than usual", "normal".
    static func higherOrLower(_ factor: Double) -> String {
        let p = Int(((factor - 1) * 100).rounded())
        if p == 0 { return normal }
        return p > 0 ? L("\(Fmt.percent(Double(p) / 100)) higher than usual") : L("\(Fmt.percent(Double(-p) / 100)) lower than usual")
    }

    private static var normal: String {
        String(localized: "normal", comment: "Plain-words description of a modifier that changes nothing: neither easier nor harder than usual") // i18n:ignore translator comment
    }

    /// "<pictogram> <label>" of a soft skill, as the skills list shows it.
    static func skill(_ keyPath: WritableKeyPath<SoftSkills, Int>) -> String {
        let pic = SoftSkills.pictogram(forKeyPath: keyPath) ?? ""
        let label = SoftSkills.label(forKeyPath: keyPath) ?? ""
        return "\(pic) \(label)"
    }

    /// "Hotels is booming this year: <effect>" -- one whole sentence per climate.
    static func climateThisYear(_ industry: Industry, _ climate: IndustryClimate, _ effect: String) -> String {
        let name = industry.displayName
        let icon = climate.icon
        switch climate {
        case .boom:     return L("• \(icon) \(name) is booming this year: \(effect)")
        case .growth:   return L("• \(icon) \(name) is growing this year: \(effect)")
        case .steady:   return L("• \(icon) \(name) is steady this year: \(effect)")
        case .slowdown: return L("• \(icon) \(name) is slowing this year: \(effect)")
        case .slump:    return L("• \(icon) \(name) is in a slump this year: \(effect)")
        }
    }

    /// "Hotels is booming: <effect>" -- the promotion hint's version.
    static func climateNow(_ industry: Industry, _ climate: IndustryClimate, _ effect: String) -> String {
        let name = industry.displayName
        let icon = climate.icon
        switch climate {
        case .boom:     return L("• \(icon) \(name) is booming: \(effect)")
        case .growth:   return L("• \(icon) \(name) is growing: \(effect)")
        case .steady:   return L("• \(icon) \(name) is steady: \(effect)")
        case .slowdown: return L("• \(icon) \(name) is slowing: \(effect)")
        case .slump:    return L("• \(icon) \(name) is in a slump: \(effect)")
        }
    }
}

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
        if !allRequirementsMet {
            return isSimplified ? L("Requirements not met") : L("Hard requirements not met")
        }
        return String(localized: "Apply", comment: "Button: apply for the job shown on this page") // i18n:ignore translator comment
    }

    /// The soft skills that feed the hire-probability skill match, each with the
    /// level the employer looks for, as hint paragraphs (none when the job asks for
    /// no skills). Surfaced in the InfoHint so the list isn't cluttering the
    /// requirements page.
    private var softSkillsParagraphs: [String] {
        let considered = SoftSkills.skillNames.filter { requiredSoft[keyPath: $0.keyPath] > 0 }
        guard !considered.isEmpty else { return [] }
        let list = considered
            .map { axis -> String in
                let target = requiredSoft[keyPath: axis.keyPath]
                let held = min(player.softSkills[keyPath: axis.keyPath], target)
                return L("\(axis.pictogram) \(axis.label): \(held)/\(target)")
            }
            .joined(separator: "\n")
        return [L("Skills this job looks for (each one helps, even if you're only part of the way there):"), list]
    }

    /// Plain-language breakdown of the hire-probability formula with the
    /// player's *current* numbers plugged in. Shown in the InfoHint popover.
    /// Every figure is read off `Job.hireBreakdown` — the same terms the roll
    /// uses — so the explanation can't drift from the odds.
    private var hireProbabilityFormulaText: String {
        let pct = HintFmt.pct
        let signed = HintFmt.signed
        let effect = HintFmt.effect

        guard allRequirementsMet else {
            let gaps = CareerGraph.missingHardRequirements(for: job, player: player)
            let needs = gaps.isEmpty
                ? L("the right schooling, licences and experience")
                : gaps.joined(separator: "; ")
            return ([L("You can't get this job yet. First you need: \(needs).")] + softSkillsParagraphs)
                .joined(separator: "\n\n")
        }

        let b = job.hireBreakdown(for: player, requestedSalary: requestedSalary)

        // Breakthrough gate: without the signature title, odds sit at the floor.
        if b.breakthroughMissing, let key = job.breakthroughFame {
            let title = FameAward.displayTitle(forId: key)
            let opening = [
                L("This career has a special door: you need the “\(title)” title first."),
                L("Until then your chance stays at \(pct(b.floor))."),
                breakthroughHowTo(key),
                L("Once you have it, it's the biggest help there is — \(signed(Job.breakthroughBonus))."),
            ].joined(separator: " ")
            return ([opening] + softSkillsParagraphs).joined(separator: "\n\n")
        }

        let asked = job.askedSoftSkills.count
        let matched = job.softSkillsHelpfulScore(for: player)
        let fit = b.requirements
        let shortfall = job.educationShortfall(for: player)
        let madeUp = shortfall - job.creditedEducationShortfall(for: player)
        let schoolLine: String = {
            let schoolEffect = effect(fit.education)
            if shortfall > 0 {
                return madeUp > 0
                    ? L("• School: \(shortfall) school levels below what this job wants (your work experience makes up \(Fmt.number(madeUp))) — \(schoolEffect)")
                    : L("• School: \(shortfall) school levels below what this job wants — \(schoolEffect)")
            }
            if job.degreePreferenceFactor(for: player) < 1 { return L("• School: employers here prefer a university degree — \(schoolEffect)") }
            if job.requirements.education.minEQF < 5 { return L("• School: you have the schooling it needs — \(schoolEffect)") }
            return job.hasAcceptedDegree(for: player)
                ? L("• School: you have the right degree — \(schoolEffect)")
                : L("• School: you have a degree, but in a different subject — \(schoolEffect)")
        }()
        let climate = player.climate(for: job.industry)
        let topPrestige = (player.degrees.filter { $0.profile != nil }.map { $0.tier.prestige }.max() ?? 0)
        let expYears = job.expectedYearsExperience
        let playerYears = job.relevantYears(for: player)

        var helps = [
            L("• Your skills: \(matched) of \(asked) are strong enough (\(pct(b.skillFit)) match)"),
            L("• Starting chance for this kind of job: \(pct(b.base)) (jobs that need more school start lower)"),
        ]
        if b.prestige != 0 {
            switch topPrestige {
            case 3: helps.append(L("• A degree from \(player.country.tierName(.elite)): \(signed(b.prestige))"))
            case 2: helps.append(L("• A degree from \(player.country.tierName(.state)): \(signed(b.prestige))"))
            default: helps.append(L("• A degree from your school: \(signed(b.prestige))"))
            }
        }
        if b.network != 0 { helps.append(L("• People you know in \(job.category.displayName): \(signed(b.network))")) }
        if b.fame > 0 {
            if let fameCategory = job.category.fameCategory {
                helps.append(L("• Your fame (\(fameCategory.displayName)): \(signed(b.fame))"))
            } else {
                helps.append(L("• Your fame (general): \(signed(b.fame))"))
            }
        }
        if let key = job.breakthroughFame {
            helps.append(L("• Your “\(FameAward.displayTitle(forId: key))” title: \(signed(b.breakthrough))"))
        }
        if b.credential > 0 { helps.append(L("• A course for this field: \(signed(b.credential))")) }

        let salaryLine: String = {
            if b.salaryFit > 1 { return L("• Your salary ask: asking for less helps a little (\(effect(b.salaryFit)))") }
            if b.salaryFit < 1 { return L("• Your salary ask: asking for a lot more \(effect(b.salaryFit))") }
            return L("• Your salary ask: fair ✓")
        }()

        var market: [String] = []
        if b.demand < 1 { market.append(L("• Lots of people want this job: \(effect(b.demand))")) }
        if b.demand > 1 { market.append(L("• Employers need more people in this job: \(effect(b.demand))")) }
        if job.rung > 0 { market.append(L("• Joining above the starting level: \(effect(b.rungDecay))")) }
        market.append(HintFmt.climateThisYear(job.industry, climate, effect(b.climate)))
        if b.seat < 1 {
            market.append(job.isExecutive
                ? L("• Only a few people get a job like this each year: \(pct(b.seat)) of the people who qualify (having run your own company helps)")
                : L("• Only a few people get a job like this each year: \(pct(b.seat)) of the people who qualify"))
        }

        let experienceLine = expYears == 0
            ? L("• Experience: none needed ✓")
            : L("• Experience: \(Fmt.number(playerYears)) of \(expYears) years — \(effect(fit.experience))")

        let schoolAndExperience = [
            L("Your school and experience:"),
            schoolLine,
            b.requirements.credentials > 0 ? L("• Licences: all set ✓") : L("• Licences: missing"),
            experienceLine,
            salaryLine,
        ]

        return ([
            L("Your chance: \(pct(b.final))"),
            ([L("What helps:")] + helps).joined(separator: "\n"),
            schoolAndExperience.joined(separator: "\n"),
            ([L("This year's job market:")] + market).joined(separator: "\n"),
        ] + softSkillsParagraphs).joined(separator: "\n\n")
    }

    var body: some View {
        ScrollView {
            Text(job.icon)

                .font(.system(size: 96))
                .padding(.top, 16)

            HStack(spacing: 8) {
                Text(job.catalogueTitle)
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                InfoHint(title: "\(job.icon) \(job.catalogueTitle)", message: job.displaySummary)
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
                if job.educationIsMandatory {
                    Text("Education:")
                        .font(.headline)
                } else {
                    Text("Education (preferred):")
                        .font(.headline)
                }
                if !job.educationIsMandatory && job.requirements.education.minEQF > 0 {
                    InfoHint(
                        title: L("🎓 Preferred education"),
                        message: [
                            L("You don't strictly need it — but it helps every time you apply and every time you could be promoted."),
                            L("A degree in the right subject helps most, a degree in another subject helps less, and having less schooling than this makes it harder."),
                        ].joined(separator: " ")
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
                    label: L("Field: \(acceptedProfiles.map { $0.displayName }.joined(separator: " / "))"),
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
                        InfoHint(title: L("📅 Experience"), message: experienceHint(baseYears: baseYears))
                    }
                    Spacer()
                }
                .padding()

                let playerYears = job.relevantYears(for: player)
                let expLabel = job.isLadderVariant
                    ? L("\(baseYears) yr as \(job.displayBaseTitle)")
                    : L("\(baseYears) yr in \(job.category.displayName)")
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
                    title: L("Trainings:"),
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
                    title: L("Preferred (helpful):"),
                    trainings: helpfulTrainings,
                    footnote: L("Not needed — but one of these makes it easier to get hired in this field, and counts as one level of the schooling a job here wants.")
                )
            }

            // Breakthrough fame award: the gateway achievement for gated careers
            // (e.g. a junior-competition win for Professional Player). Applies in
            // every mode, so it's shown regardless of simplified/realistic.
            if let key = job.breakthroughFame {
                let held = player.fameAwards.contains { $0.key == key }
                Text("Breakthrough:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                RequirementRow(label: L("\(FameAward.displayTitle(forId: key)) title"), emoji: "🏅", style: .badge(isMet: held))
                    .foregroundStyle(held ? .primary : .secondary)
                    .padding(.horizontal)

                Text(held
                     ? L("You have it! This is the biggest help there is for getting signed.")
                     : [breakthroughHowTo(key),
                        L("Without it, teams won't sign you (your chance stays at \(Fmt.percent(GameConstants.hireFloor))).")]
                        .joined(separator: " "))
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
        var paragraphs: [String]
        if floorYears < baseYears {
            paragraphs = [[
                L("This job wants \(baseYears) years of experience."),
                L("With less than \(floorYears) years, you can't apply yet."),
                L("In between you can, but each missing year makes it much harder."),
                L("Every year over \(Fmt.number(baseYears)) helps a little more."),
            ].joined(separator: " ")]
        } else {
            paragraphs = [[
                L("You need \(baseYears) years of experience to apply."),
                L("Every extra year helps a little more."),
            ].joined(separator: " ")]
        }
        if job.isLadderVariant {
            paragraphs.append(L("Years as \(job.displayBaseTitle) count fully. Other years in \(JobCategory.icon(for: job.category)) \(job.category.displayName) count half."))
        }
        // Related industries are credited too — notably, entrepreneurship
        // experience counts toward Business roles.
        let credited = job.category.creditedExperienceCategories
        if !credited.isEmpty {
            let names = Fmt.list(credited.map { "\(JobCategory.icon(for: $0)) \($0.displayName)" })
            paragraphs.append(job.isLadderVariant
                ? L("Years in \(names) count half too.")
                : L("Years in \(names) count too."))
        }
        return paragraphs.joined(separator: "\n\n")
    }

    private var postedSalarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Salary:")
                    .font(.title2.bold())
                if !isSimplified {
                    InfoHint(
                        title: L("💵 Salary"),
                        message: [
                            L("This job pays a set amount — you can't ask for more."),
                            L("It starts a bit lower for beginners and a bit higher if you have years of experience in this work."),
                        ].joined(separator: " ")
                    )
                }
                Spacer()
                Text(L("\(player.money(job.offeredSalary(for: player)))/yr"))
                    .font(.headline)
            }
            .padding(.horizontal)


            HStack(spacing: 6) {
                Text(allRequirementsMet ? L("✓ You can apply for this job.") : lockedMessage)
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
                title: L("🏢 Employer's industry"),
                message: [
                    L("Every kind of company hires for this job. Pick which one to apply to."),
                    L("Some industries are doing better than others this year — that changes your chance of getting hired, and how your pay and promotions go while you work there."),
                ].joined(separator: " ")
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
                    Text(verbatim: "\(industry.icon) \(industry.displayName) · \(HintFmt.oddsPercent(odds))")
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
                .fixedSize(horizontal: false, vertical: true)
            InfoHint(
                title: L("What your chance depends on"),
                message: hireProbabilityFormulaText
            )
            Spacer()
            Text(HintFmt.oddsPercent(hireProbability))
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
                Text(player.money(Int(requestedSalary)))
                    .font(.headline)
            }
            .padding(.horizontal)

            Slider(value: $requestedSalary, in: sliderMin...sliderMax, step: Double(player.country.moneyStep))
                .padding(.horizontal)

            HStack {
                Text(player.money(Int(sliderMin)))
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(player.money(Int(sliderMax)))
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
        case "Junior Champion": // i18n:ignore award id
            return L("Win a Junior Championship as a teen. Practise a sport for years to get better at it.")
        default:
            return L("Earn the “\(FameAward.displayTitle(forId: key))” title first.")
        }
    }

    /// What to say on a win. The header already shows the new job, so this says
    /// what it means rather than repeating the title.
    private var successMessage: String {
        L("You start as \(job.displayTitle) on \(player.money(Int(requestedSalary))) a year.")
    }

    private func resultMessage(_ result: ApplicationResult) -> String {
        result == .hired ? L("🎉 Offer accepted!") : L("❌ No offer this time.")
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
        // The breakthrough gate (e.g. a pro-player role needing a junior title)
        // pins odds at the hiring floor — by far the likeliest reason for a
        // "no", so call it out first.
        if let key = job.breakthroughFame,
           !player.fameAwards.contains(where: { $0.key == key }) {
            return L("Teams here want the “\(FameAward.displayTitle(forId: key))” title — win it first to open this career.")
        }

        return L("You had a \(Fmt.percent(hireProbability)) chance, and this time it didn't work out. Don't give up — try again next year!")
    }

    private var applyDisabled: Bool { !allRequirementsMet }

    /// What still stands between the player and this role, for the posted-pay
    /// section: the first hard gap (`CareerGraph.missingHardRequirements`, the
    /// same gates the Apply button checks) — an age, a degree, a licence or
    /// years of experience.
    private var lockedMessage: String {
        guard let gap = CareerGraph.missingHardRequirements(for: job, player: player).first else {
            return L("🔒 Not open to you yet.")
        }
        return L("🔒 First: \(gap).")
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

