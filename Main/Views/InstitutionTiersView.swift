import SwiftUI

/// Third level of the education nav stack — picks the tier of the institution
/// (Community / State / Elite) for a chosen (level, profile) degree.
struct InstitutionTiersView: View {
    @ObservedObject var player: Player
    let level: Level.Stage
    let profile: TertiaryProfile

    @Binding var yearsLeftToGraduation: Int?
    @Binding var showTertiarySheet: Bool
    /// Enrolling spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    private var tiers: [Education] {
        // Simplified mode has no institution tiers — a single neutral school
        // (community tier: no prestige bonus, lowest tuition, base admission bar).
        // Elite-tier institutions exist only for white-collar profiles —
        // their prestige is the currency of knowledge-economy careers. Blue-
        // collar / service / athletic tracks top out at the State tier, and
        // community colleges award no graduate degrees.
        EducationTier.offered(level: level, profile: profile, simplified: player.isSimplified)
            .map { Education(level, profile: profile, tier: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(tiers.enumerated()), id: \.element.id) { _, education in
                    tierCard(for: education)
                }
            }
            .padding()
        }
        .navigationTitle(player.isSimplified ? Self.applyTitle : L("Compare schools"))
    }

    /// “Apply” — the verb, for a school application: the screen title in Simplified mode and the
    /// button on each school's card.
    private static var applyTitle: String {
        String(localized: "school.apply", defaultValue: "Apply", comment: "Verb. Screen title and button for applying to a school or university (not to a job); applying uses up the year.")  // i18n:ignore translator comment
    }

    /// Tuition per year, tuition in total (red when savings fall short) and the length of the degree.
    @ViewBuilder
    private func costLabels(for education: Education, canAfford: Bool) -> some View {
        if !player.isSimplified {
            Label("\(player.money(education.annualTuition(in: player.country)))/yr", systemImage: "banknote")
                .font(.caption)
                .foregroundStyle(canAfford ? Color.secondary : Color.red)
                .lineLimit(1)
            Label("Total \(player.money(education.totalTuition(in: player.country)))", systemImage: "sum")
                .font(.caption)
                .foregroundStyle(canAfford ? Color.secondary : Color.red)
                .lineLimit(1)
        }
        Label("\(education.yearsToComplete) yrs", systemImage: "clock")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    @ViewBuilder
    private func tierCard(for education: Education) -> some View {
        let r = education.requirements
        let highestEQF = player.highestEQF
        let canAfford = player.savings >= education.totalTuition(in: player.country)
        // The qualification level is the only hard gate; soft skills just move the
        // odds of the admission roll, in every mode.
        let eqfMet = education.meetsRequirements(player: player)
        let admission = education.admissionProbability(player: player)

        VStack(alignment: .leading, spacing: 10) {
            if player.isSimplified {
                HStack(spacing: 6) {
                    Text(verbatim: "\(education.pictogram) \(education.degreeName(in: player.country))")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            } else {
                HStack(spacing: 6) {
                    Text(verbatim: "\(education.tier.pictogram) \(player.country.tierName(education.tier))")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    InfoHint(
                        title: "\(education.tier.pictogram) \(player.country.tierName(education.tier))",
                        message: education.tier.description
                    )
                    Spacer()
                    prestigeBadge(education.tier.prestige)
                }
            }

            // Simplified mode is kid-friendly — education is free, so its
            // costs are hidden and only the duration is shown. The three facts
            // stack when a longer translation or a narrow screen leaves no room
            // for them side by side.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { costLabels(for: education, canAfford: canAfford) }
                VStack(alignment: .leading, spacing: 4) { costLabels(for: education, canAfford: canAfford) }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Admission requirement:")
                        .font(.subheadline.bold())
                    InfoHint(
                        title: L("Admission requirement"),
                        message: L("You need to have finished this school level before you can apply. Everything else just changes your chance of getting in.")
                    )
                }
                .padding(.top, 4)

                RequirementRow(
                    label: r.educationLabel(in: player.country),
                    emoji: "🎓",
                    style: .meter(current: highestEQF, required: r.minEQF)
                )
                .foregroundStyle(eqfMet ? .primary : .secondary)
            }

            // Grades, for a first degree: how the transcript reads and how much of
            // the decision it carries at this school.
            if education.gradeWeight > 0 {
                let gpa = player.highSchoolGPA
                HStack(spacing: 6) {
                    Text(verbatim: "📝 \(player.country.schooling.gradeName): \(player.country.gradeLabel(gpa))")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    InfoHint(
                        title: "📝 \(player.country.schooling.gradeName)",
                        message: gradesHint(for: education, gpa: gpa)
                    )
                    Spacer(minLength: 4)
                    Text(L("\(Fmt.percent(education.gradeWeight)) of the decision"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Trophies and accolades, where the school counts them.
            if education.accoladeWeight > 0 {
                HStack(spacing: 6) {
                    Text(L("🏆 Your accolades: \(accoladeSummary)"))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    InfoHint(
                        title: L("🏆 Trophies & accolades"),
                        message: accoladesHint(for: education)
                    )
                    Spacer(minLength: 4)
                    Text(L("\(Fmt.percent(education.accoladeWeight)) of the decision"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // The overlap the odds are made of: what this school looks for, next
            // to what the player brings. Shown in full rather than tucked behind
            // a hint — it's the one thing the player can act on.
            let overlap = education.softSkillOverlap(player: player)
            if !overlap.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("What this school looks for:")
                            .font(.subheadline.bold())
                        InfoHint(
                            title: L("Soft-skill match"),
                            message: admissionSoftSkillsHint(for: overlap)
                        )
                        Spacer(minLength: 4)
                        Text(L("\(Fmt.percent(education.softSkillFit(player: player))) match"))
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(overlap) { axis in
                        RequirementRow(
                            label: axis.label,
                            emoji: axis.pictogram,
                            style: .meter(current: axis.have, required: axis.target)
                        )
                        .font(.caption)
                        .foregroundStyle(axis.isMet ? .primary : .secondary)
                    }
                }
                .padding(.top, 4)
            }

            // Admission is a roll in every mode: strong soft skills raise the
            // odds, a thin profile lowers them, and matching everything still
            // isn't a guarantee at a selective school.
            HStack(spacing: 6) {
                Text("Admission chance:")
                InfoHint(
                    title: L("How admission works"),
                    message: admissionHint
                )
                Spacer()
                Text(verbatim: eqfMet ? Fmt.percent(admission) : "—")
                    .font(.headline)
                    .foregroundStyle(Color.forOdds(admission))
            }
            .font(.subheadline)
            .padding(.top, 4)

            Button {
                apply(to: education, admission: admission)
            } label: {
                Text(applyLabel(eqfMet: eqfMet, education: education))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!eqfMet)
            .opacity(eqfMet ? 1.0 : 0.5)
            .padding(.top, 4)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func gradesHint(for education: Education, gpa: Double) -> String {
        let grades = Fmt.percent(education.gradeWeight)
        let skills = Fmt.percent(education.softSkillWeight)
        let prizes = Fmt.percent(education.accoladeWeight)
        // One whole sentence per case: who is judging, and on what.
        let weights: String
        if player.isSimplified {
            weights = L("The school cares about: grades \(grades), skills \(skills).")
        } else if education.accoladeWeight > 0 {
            weights = L("\(player.country.tierName(education.tier)) cares about: grades \(grades), skills \(skills), prizes and titles \(prizes).")
        } else {
            weights = L("\(player.country.tierName(education.tier)) cares about: grades \(grades), skills \(skills).")
        }
        let range = L("\(player.country.gradeLabel(GameConstants.gradeFloor)) doesn't help; \(player.country.gradeLabel(4.0)) helps the most.")
        let count = player.highSchoolGrades.count
        let record = count == 0
            ? L("You don't have school grades yet, so the game guesses them from your skills.")
            : L("Your grade comes from your \(count) school years.")
        let ceiling = L("Your school skills set each year's grade, and choosing a Study activity pushes it up. With skills alone, the best you can get is \(player.country.gradeLabel(GameConstants.gradeFloor + GameConstants.gradeSkillSpan)).")
        return [[weights, range].joinedAsSentences(), [record, ceiling].joinedAsSentences()]
            .joined(separator: "\n\n")
    }

    /// "3 · 45% of full marks", or "None yet".
    private var accoladeSummary: String {
        let count = player.fameAwards.reduce(0) { $0 + $1.count }
        guard count > 0 else { return L("None yet") }
        return L("\(count) · \(Fmt.percent(player.accoladeFit)) of full marks")
    }

    private func accoladesHint(for education: Education) -> String {
        let share = Fmt.percent(education.accoladeWeight)
        // `\(title)` is the award's English id until the awards have display names.
        let top = player.fameAwards
            .sorted { $0.totalWeight > $1.totalWeight }
            .prefix(5)
            .map { $0.count > 1 ? "\($0.icon) \($0.title) ×\($0.count)" : "\($0.icon) \($0.title)" }
            .joined(separator: "\n")
        var paragraphs = [
            // Only shown where a school weighs accolades, which is never the single Simplified school.
            L("Prizes and titles are \(share) of what \(player.country.tierName(education.tier)) looks at. Bigger prizes count more — winning a national championship is worth lots of school ribbons. About one national title plus a few local wins gets you full marks."),
            L("Win them with Activities: every year you practise, you enter that activity's biggest contest."),
        ]
        if !top.isEmpty {
            paragraphs.append([L("Your best ones:"), top].joined(separator: "\n"))
        }
        return paragraphs.joined(separator: "\n\n")
    }

    /// Spells out the match rows in numbers: what the school looks for on each
    /// skill against what the player brings, and what a gap actually costs —
    /// odds, never entry.
    private func admissionSoftSkillsHint(for overlap: [Education.SoftSkillOverlap]) -> String {
        let list = overlap
            .map { L("\($0.pictogram) \($0.label): you have \($0.have), they'd like \($0.target)") }
            .joined(separator: "\n")
        return [
            L("Every skill here helps you get in. Reaching the level the school likes counts fully; being a bit short still counts some. A low skill never stops you from applying — it just lowers your chance."),
            list,
        ].joined(separator: "\n\n")
    }

    /// The "How admission works" hint: when you can apply, what moves the odds, what it costs.
    private var admissionHint: String {
        let bullets = [
            L("• the skills this school looks for"),
            L("• your \(player.country.schooling.gradeName) (for a first degree)"),
            L("• your prizes and titles (at top schools)"),
        ].joined(separator: "\n")
        return [
            L("You can apply as soon as you've finished the school level above. After that, your chance goes up with:"),
            bullets,
            L("Picky schools say no to many good students, and friendly ones may still say yes when your skills are low. Grow your skills with Activities and projects, and pick Study activities at school to raise your grades. Applying uses up your year, whether you get in or not."),
        ].joined(separator: "\n\n")
    }

    /// Sends the application, which is how this year gets spent — an admission
    /// starts the degree, a rejection costs the year anyway. Either way the
    /// sheet closes and the answer arrives as a pop-up on the game view, the
    /// same as a job application.
    private func apply(to education: Education, admission: Double) {
        if player.applyToSchool(education) {
            // Enrolling means studying full-time — say so when it costs a job,
            // rather than letting the salary silently vanish.
            let degree = education.degreeName(in: player.country)
            var message = player.isSimplified
                ? L("The school accepted you onto \(degree).")
                : L("\(player.country.tierName(education.tier)) accepted you onto \(degree).")
            if let job = player.currentOccupation {
                message += AdvisorCoach.sentenceGap + L("You've left your job as \(job.displayBaseTitle) to study full-time.")
            }
            player.reportApplicationOutcome(title: L("🎓 You're in!"), message: message)
            enroll(in: education)
        } else {
            let chance = Fmt.percent(admission)
            player.reportApplicationOutcome(
                title: L("🎓 Not this year"),
                message: player.isSimplified
                    ? L("The school said no this time — you had a \(chance) chance. You can try again next year!")
                    : L("\(player.country.tierName(education.tier)) said no this time — you had a \(chance) chance. You can try again next year!")
            )
            onCommit()
        }
    }

    /// Locks in the chosen school: drops any job and starts the degree. The
    /// caller spends the year.
    private func enroll(in education: Education) {
        player.currentOccupation = nil
        player.currentEducation = education
        yearsLeftToGraduation = education.yearsToComplete
        onCommit()
    }

    private func applyLabel(eqfMet: Bool, education: Education) -> String {
        if !eqfMet { return L("Need \(education.requirements.educationLabel(in: player.country)) first") }
        return Self.applyTitle
    }

    @ViewBuilder
    private func prestigeBadge(_ prestige: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < prestige ? "star.fill" : "star")  // i18n:ignore SF Symbol
                    .imageScale(.small)
                    .foregroundStyle(i < prestige ? Color.yellow : Color.secondary.opacity(0.4))
            }
        }
    }
}
