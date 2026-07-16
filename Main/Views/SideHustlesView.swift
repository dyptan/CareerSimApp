import SwiftUI

/// The **Projects** page — the home for the pure fame/creative spare-time plays
/// (writing, talks, festivals, open source, and personal-brand performances).
/// Every row is a talent-fit gamble that stakes no money and banks industry-
/// scoped **fame** (growing the soft skills it drew on). Mirrors `HobbiesView`:
/// the catalogue is filtered by life stage and capped per year.
///
/// Anything with prospects of turning profitable — the commercial ventures
/// (course, online store, shop, flip), the buildable products (app, game), and
/// the entrepreneurship plays — banks Business fame and lives in the
/// **Ventures** sheet instead (see `EntrepreneurshipView` and
/// `SideHustleCatalog.businessVentures`).
struct PrivateProjectsView: View {
    @ObservedObject var player: Player
    @Binding var selectedSideHustles: Set<String>

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    /// Spare-time projects offered this stage (business ventures excluded — they
    /// live in the Ventures sheet). All are always available once the player is
    /// old enough — no hobby prerequisite.
    private var stageProjects: [SideHustle] {
        SideHustleCatalog.spareTimeProjects.filter { $0.stages.contains(currentStage) }
    }

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text("Projects this year:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(selectedSideHustles.count)/\(GameConstants.maxSideHustlesPerYear)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        selectedSideHustles.count >= GameConstants.maxSideHustlesPerYear
                            ? .red : .primary
                    )
            }
            Text("Spend a year building your name — a standout project banks fame in its field.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageProjects) { hustle in
                        SideHustleRow(
                            hustle: hustle,
                            player: player,
                            selectedSideHustles: $selectedSideHustles
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/// A single selectable spare-time venture row: a talent-fit toggle with its
/// blurb, lock label (unmet soft-skill / capital gate), and an info popover.
/// Shared by the **Projects** sheet and the business-ventures section of the
/// **Ventures** sheet, so both surfaces present a venture identically.
struct SideHustleRow: View {
    let hustle: SideHustle
    @ObservedObject var player: Player
    @Binding var selectedSideHustles: Set<String>

    private var skillPictogramByKeyPath: [PartialKeyPath<SoftSkills>: String] {
        Dictionary(
            uniqueKeysWithValues: SoftSkills.skillNames.map {
                ($0.keyPath as PartialKeyPath<SoftSkills>, $0.pictogram)
            }
        )
    }

    var body: some View {
        let isSelected = selectedSideHustles.contains(hustle.id)
        let atLimit = selectedSideHustles.count >= GameConstants.maxSideHustlesPerYear
        // A venture is locked until its soft-skill prerequisite and any capital
        // requirement are both met.
        let meetsPrereq = hustle.meetsPrerequisite(for: player.softSkills)
        let meetsCapital = hustle.meetsCapital(savings: player.savings)
        let meetsAll = meetsPrereq && meetsCapital
        let isDisabled = (!isSelected && atLimit) || !meetsAll

        let lockLabel: String? = {
            var parts: [String] = []
            if let req = hustle.prerequisite, !meetsPrereq {
                let kp = req.keyPath as PartialKeyPath<SoftSkills>
                let pic = skillPictogramByKeyPath[kp] ?? ""
                let label = SoftSkills.label(forKeyPath: kp) ?? "skill"
                parts.append("\(pic) \(label) \(req.minLevel)")
            }
            if let cap = hustle.minCapital, !meetsCapital {
                parts.append("💰 \(cap.formatted(.number)) $")
            }
            guard !parts.isEmpty else { return nil }
            return "🔒 Requires " + parts.joined(separator: " · ")
        }()

        let talentHint: String = hustle.talents
            .map { kp -> String in
                let label = SoftSkills.label(forKeyPath: kp as PartialKeyPath<SoftSkills>) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp as PartialKeyPath<SoftSkills>] ?? ""
                return "\(pic) \(label)"
            }
            .joined(separator: "\n")

        let growthHint: String = hustle.growth
            .map { boost -> String in
                let kp = boost.keyPath as PartialKeyPath<SoftSkills>
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = skillPictogramByKeyPath[kp] ?? ""
                return "\(pic) \(label) +\(boost.weight)"
            }
            .joined(separator: "\n")

        HStack(alignment: .top, spacing: 8) {
            Toggle(
                isOn: Binding(
                    get: { isSelected },
                    set: { isOn in
                        if isOn {
                            guard !atLimit else { return }
                            selectedSideHustles.insert(hustle.id)
                        } else {
                            selectedSideHustles.remove(hustle.id)
                        }
                    }
                )
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(hustle.icon)  \(hustle.label)")
                        .font(.headline)
                    Text(hustle.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let lockLabel {
                        Text(lockLabel)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .platformToggleStyle()
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)
            .help(
                !meetsAll
                    ? "Meet this project's requirements first — the required soft skill and any capital on hand — then take it on."
                    : (atLimit && !isSelected
                        ? "You can take on up to \(GameConstants.maxSideHustlesPerYear) project(s) this year."
                        : "")
            )

            InfoHint(
                title: "\(hustle.icon) \(hustle.label)",
                message: infoMessage(for: hustle, talentHint: talentHint, growthHint: growthHint)
            )
        }
        .padding(5)
    }

    private func infoMessage(for hustle: SideHustle, talentHint: String, growthHint: String) -> String {
        let gate: String = {
            var lines: [String] = []
            if let req = hustle.prerequisite {
                let kp = req.keyPath as PartialKeyPath<SoftSkills>
                let pic = skillPictogramByKeyPath[kp] ?? ""
                let label = SoftSkills.label(forKeyPath: kp) ?? "a skill"
                lines.append("🔒 Unlocks at \(pic) \(label) \(req.minLevel) — build it through hobbies first.")
            }
            if let cap = hustle.minCapital {
                lines.append("💰 Requires \(cap.formatted(.number)) $ in savings on hand to take on.")
            }
            guard !lines.isEmpty else { return "" }
            return lines.joined(separator: "\n") + "\n\n"
        }()
        let expYears = hustle.experienceCategory.map { player.industryExperience(for: $0) } ?? 0
        let odds = Int((hustle.successProbability(for: player.softSkills, fameScore: player.fameScore, experienceYears: expYears) * 100).rounded())
        // Ventures that build work experience (the entrepreneurship plays) note
        // the industry the year credits — and that Business roles count it too.
        let experienceNote: String = {
            guard let cat = hustle.experienceCategory else { return "" }
            let icon = JobCategory.icon(for: cat)
            let credited = cat.creditedExperienceCategories
                .map { "\(JobCategory.icon(for: $0)) \($0.rawValue)" }
                .joined(separator: ", ")
            let creditLine = credited.isEmpty
                ? ""
                : " Those years also count toward \(credited) roles."
            let liftPct = Int((hustle.experienceLift(years: expYears) * 100).rounded())
            let liftLine = expYears > 0
                ? " Your \(expYears) yr so far add +\(liftPct)% to the odds."
                : " Years in the field raise the odds over time."
            return "\n\n📅 A committed year — win or lose — banks a year of \(icon) \(cat.rawValue) work experience.\(creditLine)\(liftLine)"
        }()
        switch hustle.payoff {
        case .money:
            let upside = hustle.projectedPayout(for: player.softSkills)
            let stats = "🎲 ~\(odds)% success · 📈 up to \(upside.formatted(.number)) $\n\n"
            return gate + stats + "Monetizes:\n\n\(talentHint)\n\nA money venture risks no cash — build these talents through activities and hobbies to raise your odds and payout. A flop simply earns nothing." + experienceNote
        case .fame(let industry, _):
            let stats = "🎲 ~\(odds)% success · 🌟 \(JobCategory.icon(for: industry)) \(industry.rawValue) fame\n\n"
            return gate + stats + "Draws on:\n\n\(talentHint)\n\nA fame venture spends the soft skills you've built for a shot at being noticed. A successful year banks fame in \(JobCategory.icon(for: industry)) \(industry.rawValue) (industry-specific — it only helps you land \(industry.rawValue) roles) and grows you the way a hobby can't:\n\n\(growthHint)\n\nThe odds also climb with your existing reputation. A dud year yields nothing." + experienceNote
        }
    }
}

#Preview {
    PrivateProjectsView(
        player: Player(),
        selectedSideHustles: .constant([])
    )
    .padding()
}
