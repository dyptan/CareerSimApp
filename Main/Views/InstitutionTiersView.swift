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
        let highestEQF = player.degrees.last?.eqf ?? 0
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
                    message: "Your current education level is the only hard requirement — once you have it you can always apply. From there, your odds rise with how well your soft skills overlap with what this school looks for and fall with how selective the school is. Matching every one makes you fully qualified, but selective schools still turn away strong applicants — and a school may still take a chance on you when your soft skills are thin. Build the skills listed above through hobbies, sports and projects to improve your chances. Applying is how you spend the year, so it costs a year whether or not you get in."
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
            player.reportApplicationOutcome(
                title: "🎓 You're in!",
                message: "\(schoolName(education)) accepted you onto \(education.degreeName). "
                    + "It takes \(education.yearsToComplete) year\(education.yearsToComplete == 1 ? "" : "s")."
            )
            enroll(in: education)
        } else {
            player.reportApplicationOutcome(
                title: "🎓 Not this year",
                message: "\(schoolName(education)) turned you down — your odds were "
                    + "\(Int((admission * 100).rounded()))%. Even a strong applicant gets turned away. "
                    + "Build the skills the school looks for, try a less selective one, or apply again next year."
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
