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
        if player.isSimplified {
            return [Education(level, profile: profile, tier: .community)]
        }
        // Elite-tier institutions exist only for white-collar profiles —
        // their prestige is the currency of knowledge-economy careers. Blue-
        // collar / service / athletic tracks top out at the State tier.
        let availableTiers = EducationTier.allCases.filter {
            $0 != .elite || profile.isWhiteCollar
        }
        return availableTiers.map { Education(level, profile: profile, tier: $0) }
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
        .navigationTitle(player.isSimplified ? "Apply" : "Compare schools")
    }

    @ViewBuilder
    private func tierCard(for education: Education) -> some View {
        let r = education.requirements
        let highestEQF = player.highestEQF
        let canAfford = player.savings >= education.totalTuition
        // The qualification level is the only hard gate; soft skills just move the
        // odds of the admission roll, in every mode.
        let eqfMet = education.meetsRequirements(player: player)
        let admission = education.admissionProbability(player: player)

        VStack(alignment: .leading, spacing: 10) {
            if player.isSimplified {
                HStack(spacing: 6) {
                    Text("\(education.pictogram) \(education.degreeName)")
                        .font(.headline)
                    Spacer()
                }
            } else {
                HStack(spacing: 6) {
                    Text("\(education.tier.pictogram) \(education.tier.friendlyName)")
                        .font(.headline)
                    InfoHint(
                        title: "\(education.tier.pictogram) \(education.tier.friendlyName)",
                        message: education.tier.description
                    )
                    Spacer()
                    prestigeBadge(education.tier.prestige)
                }
            }

            HStack(spacing: 10) {
                // Simplified mode is kid-friendly — education is free, so its
                // costs are hidden and only the duration is shown.
                if !player.isSimplified {
                    Label("\(education.annualTuition.formatted(.number)) $/yr", systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundStyle(canAfford ? Color.secondary : Color.red)
                    Label("Total \(education.totalTuition.formatted(.number)) $", systemImage: "sum")
                        .font(.caption)
                        .foregroundStyle(canAfford ? Color.secondary : Color.red)
                }
                Label("\(education.yearsToComplete) yrs", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Admission requirement:")
                        .font(.subheadline.bold())
                    InfoHint(
                        title: "Admission requirement",
                        message: "The education level below is the one thing you must already hold to apply here. Everything else only moves your odds."
                    )
                }
                .padding(.top, 4)

                RequirementRow(
                    label: r.educationLabel(),
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
                    Text("📝 Your grades: GPA \(Player.formatGPA(gpa)) (\(Player.letterGrade(gpa)))")
                        .font(.subheadline)
                    InfoHint(
                        title: "📝 High-school grades",
                        message: gradesHint(for: education, gpa: gpa)
                    )
                    Spacer()
                    Text("\(Int((education.gradeWeight * 100).rounded()))% of the decision")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Trophies and accolades, where the school counts them.
            if education.accoladeWeight > 0 {
                HStack(spacing: 6) {
                    Text("🏆 Your accolades: \(accoladeSummary)")
                        .font(.subheadline)
                    InfoHint(
                        title: "🏆 Trophies & accolades",
                        message: accoladesHint(for: education)
                    )
                    Spacer()
                    Text("\(Int((education.accoladeWeight * 100).rounded()))% of the decision")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                            title: "Soft-skill match",
                            message: admissionSoftSkillsHint(for: overlap)
                        )
                        Spacer()
                        Text("\(Int((education.softSkillFit(player: player) * 100).rounded())) % match")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
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
                    title: "How admission works",
                    message: "Your current education level is the only hard requirement — once you have it you can always apply. From there, your odds rise with how well your soft skills overlap with what this school looks for — and, for a first degree, with your high-school grades, and at selective schools with your trophies — and fall with how selective the school is. Matching every one makes you fully qualified, but selective schools still turn away strong applicants — and a school may still take a chance on you when your soft skills are thin. Build the skills listed above through activities and projects, and lift your grades with Study activities while at school, to improve your chances. Applying is how you spend the year, so it costs a year whether or not you get in."
                )
                Spacer()
                Text(eqfMet ? "\(Int((admission * 100).rounded())) %" : "—")
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

    /// Spells out the match rows in numbers: what the school looks for on each
    /// skill against what the player brings, and what a gap actually costs —
    /// odds, never entry.
    private func gradesHint(for education: Education, gpa: Double) -> String {
        let share = Int((education.gradeWeight * 100).rounded())
        let record = player.highSchoolGrades.isEmpty
            ? "You have no high-school years on record here, so your grades are estimated from the skills you arrived with."
            : "Your GPA is the average of your \(player.highSchoolGrades.count) high-school year\(player.highSchoolGrades.count == 1 ? "" : "s")."
        return """
        Grades make up \(share)% of what \(schoolName(education).lowercased()) weighs here, next to \(Int((education.softSkillWeight * 100).rounded()))% for soft skills\(education.accoladeWeight > 0 ? " and \(Int((education.accoladeWeight * 100).rounded()))% for trophies and accolades" : ""). A C average (2.0) adds nothing, a straight-A 4.0 counts in full.

        \(record) Each year's grade comes from your academic skills — and a year spent on a Study activity lifts it. Skills alone top out at a B+.
        """
    }

    /// "3 · 45% of full marks", or "None yet".
    private var accoladeSummary: String {
        let count = player.fameAwards.reduce(0) { $0 + $1.count }
        guard count > 0 else { return "None yet" }
        return "\(count) · \(Int((player.accoladeFit * 100).rounded()))% of full marks"
    }

    private func accoladesHint(for education: Education) -> String {
        let share = Int((education.accoladeWeight * 100).rounded())
        let top = player.fameAwards
            .sorted { $0.totalWeight > $1.totalWeight }
            .prefix(5)
            .map { "\($0.icon) \($0.title)\($0.count > 1 ? " ×\($0.count)" : "")" }
            .joined(separator: "\n")
        return """
        Trophies and accolades make up \(share)% of what \(schoolName(education).lowercased()) weighs here. Bigger titles count for more — an olympiad medal or national championship is worth many sports-day ribbons. Roughly a national title plus a few local wins counts in full.

        Win them through Activities: every year you practise, you enter that activity's top contest.\(top.isEmpty ? "" : "\n\nYour strongest:\n\(top)")
        """
    }

    private func admissionSoftSkillsHint(for overlap: [Education.SoftSkillOverlap]) -> String {
        let list = overlap
            .map { "\($0.pictogram) \($0.label): you have \($0.have), they look for \($0.target)" }
            .joined(separator: "\n")
        return """
        Every skill here counts toward your admission chance. Reaching the level a school looks for scores that skill in full, falling short scores it in part — and no gap can shut you out, it only lowers the odds.

        \(list)
        """
    }

    /// How the school reads in a message: the tier when tiers are shown, the
    /// degree itself in simplified mode, where there is only one school.
    private func schoolName(_ education: Education) -> String {
        player.isSimplified ? "The school" : education.tier.friendlyName
    }

    /// Sends the application, which is how this year gets spent — an admission
    /// starts the degree, a rejection costs the year anyway. Either way the
    /// sheet closes and the answer arrives as a pop-up on the game view, the
    /// same as a job application.
    private func apply(to education: Education, admission: Double) {
        if player.applyToSchool(education) {
            // Enrolling means studying full-time — say so when it costs a job,
            // rather than letting the salary silently vanish from the header.
            let leavingNote = player.currentOccupation.map {
                " You've left your job as \($0.baseTitle) to study full-time."
            } ?? ""
            player.reportApplicationOutcome(
                title: "🎓 You're in!",
                message: "\(schoolName(education)) accepted you onto \(education.degreeName)." + leavingNote
            )
            enroll(in: education)
        } else {
            player.reportApplicationOutcome(
                title: "🎓 Not this year",
                message: "\(schoolName(education)) turned you down — your odds were "
                    + "\(Int((admission * 100).rounded()))%. Try again next year."
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
        if !eqfMet { return "Need \(education.requirements.educationLabel()) first" }
        return "Apply"
    }

    @ViewBuilder
    private func prestigeBadge(_ prestige: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < prestige ? "star.fill" : "star")
                    .imageScale(.small)
                    .foregroundStyle(i < prestige ? Color.yellow : Color.secondary.opacity(0.4))
            }
        }
    }
}
