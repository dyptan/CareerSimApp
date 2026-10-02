import SwiftUI

/// The **Projects** page — the home for every *self-initiated* spare-time work:
/// creative fame gambles you make on your own (writing, albums, open source,
/// podcasts, films, personal-brand plays), the course/MOOC play, and the
/// crowdfunding entrepreneurship play. Things you *participate in* rather than
/// create — a festival set, a TV casting, a conference talk, a pitch competition
/// — are Events instead (see `EventCatalog`).
///
/// Nothing here is locked. Every project can be attempted at any time, and the
/// odds on the row carry the whole decision: they rise with the soft skills the
/// work draws on and the working life behind you, and a project you have no
/// talent or career for shows the ~0% it really is. Each attempt costs the year
/// either way, and the year reports back with a hit-or-flop pop-up.
///
/// The **Ventures** sheet keeps only the capital-staked industry ventures (see
/// `EntrepreneurshipView`); every `SideHustle` lives here.
struct PrivateProjectsView: View {
    @ObservedObject var player: Player
    @Binding var selectedSideHustles: Set<String>
    /// Taking a project on spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    /// Every spare-time project offered this stage, best odds first — so the
    /// plays the player has actually built toward lead, and the long shots read
    /// as long shots.
    private var stageProjects: [SideHustle] {
        SideHustleCatalog.all
            .filter { $0.stages.contains(currentStage) }
            .sorted {
                let a = player.projectOdds(for: $0), b = player.projectOdds(for: $1)
                return a == b ? NameOrder.before($0.label, $1.label) : a > b
            }
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageProjects) { hustle in
                        SideHustleRow(
                            hustle: hustle,
                            player: player,
                            selectedSideHustles: $selectedSideHustles,
                            onCommit: onCommit
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/// A single selectable spare-time project row: its odds for this player, and an
/// info popover explaining what drives them. Every `SideHustle` is presented
/// through this row in the **Projects** sheet.
struct SideHustleRow: View {
    let hustle: SideHustle
    @ObservedObject var player: Player
    @Binding var selectedSideHustles: Set<String>
    var onCommit: () -> Void = {}

    var body: some View {
        let odds = player.projectOdds(for: hustle)

        let talentHint: String = hustle.talents
            .map(SkillLine.tag)
            .joined(separator: "\n")

        let growthHint: String = hustle.growth
            .map(SkillLine.plus)
            .joined(separator: "\n")

        let locked = !player.canTakeProject(hustle)

        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(verbatim: "\(hustle.icon)  \(hustle.label)")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    if !locked {
                        Text(verbatim: "🎲 \(Fmt.percent(odds))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Color.forOdds(odds))
                            .fixedSize()
                    }
                }
                if let award = hustle.requiredAwardTitle, locked {
                    Text(L("🔒 Needs the “\(award)” title"))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .opacity(locked ? 0.5 : 1.0)
            Spacer(minLength: 8)

            // Picking a project is committing the year to it — the sheet
            // closes and the year runs, so there is only ever one pick to hold.
            TakeButton {
                selectedSideHustles = [hustle.id]
                onCommit()
            }
            .disabled(locked)
            .opacity(locked ? 0.5 : 1.0)

            InfoHint(
                title: "\(hustle.icon) \(hustle.label)",
                message: infoMessage(for: hustle, odds: odds, talentHint: talentHint, growthHint: growthHint)
            )
        }
        .padding(5)
    }

    /// Why a star project is still closed, if it is.
    private func lockLine(for hustle: SideHustle) -> String? {
        guard let award = hustle.requiredAwardTitle, !player.canTakeProject(hustle) else { return nil }
        return L("🔒 Opens once you hold the “\(award)” title — chase it under Projects.")
    }

    /// The "your chance goes up with …" line. The note about double-counting years is a sentence of
    /// its own (with its own count), so each sentence carries one plural and none is glued from fragments.
    private func oddsLine(for hustle: SideHustle, fame: String) -> String {
        let years = player.totalExperienceYears
        let main = L("Your chance goes up with the skills below, your \(years) years of work, and the \(fame) fame you already have — being known in a field makes the next project there easier.")
        guard let cat = hustle.experienceCategory else { return main }
        let fieldYears = player.industryExperience(for: cat)
        let field = "\(JobCategory.icon(for: cat)) \(cat.displayName)"
        return main + AdvisorCoach.sentenceGap + L("Your \(fieldYears) years in \(field) count double.")
    }

    /// What a flop costs: only the fame — the skill gains and the banked experience land either way.
    private func lossLine(for hustle: SideHustle) -> String {
        guard let cat = hustle.experienceCategory else {
            return L("If it doesn't work out: you just miss the fame — you keep the skills.")
        }
        let field = "\(JobCategory.icon(for: cat)) \(cat.displayName)"
        let credited = Fmt.list(cat.creditedExperienceCategories
            .map { "\(JobCategory.icon(for: $0)) \($0.displayName)" })
        return credited.isEmpty
            ? L("If it doesn't work out: you just miss the fame — you keep the skills. 📅 The year still counts as \(field) work experience.")
            : L("If it doesn't work out: you just miss the fame — you keep the skills. 📅 The year still counts as \(field) work experience, which also helps for \(credited) jobs.")
    }

    /// What the field's climate does to the odds this year; nothing to say when it is steady.
    private func climateLine(for hustle: SideHustle) -> String? {
        let climate = player.projectClimate(for: hustle)
        let effect = SkillsView.easierOrHarder(climate.projectFactor)
        switch climate {
        case .steady:   return nil
        case .boom:     return L("\(climate.icon) This field is booming this year: \(effect).")
        case .growth:   return L("\(climate.icon) This field is growing this year: \(effect).")
        case .slowdown: return L("\(climate.icon) This field is slowing this year: \(effect).")
        case .slump:    return L("\(climate.icon) This field is in a slump this year: \(effect).")
        }
    }

    /// The project hint, kept to what the player can act on: the blurb, the
    /// odds and what moves them, the fame a win banks (projects pay no money —
    /// they build fame and skills), what the year costs either way. The
    /// mechanic used to be spelled out in full prose, which made every row a
    /// wall of text to read past.
    private func infoMessage(for hustle: SideHustle, odds: Double,
                             talentHint: String, growthHint: String) -> String {
        let category = hustle.fameCategory
        let fame = "\(category.icon) \(category.displayName)"

        return [
            hustle.blurb,
            L("🎲 \(Fmt.percent(odds)) chance it works · 🌟 \(fame) fame"),
            // Naming the drivers with where the player stands now makes a 0% row
            // read as "not yet" rather than "broken".
            oddsLine(for: hustle, fame: fame),
            climateLine(for: hustle),
            L("Needs:\n\(talentHint)"),
            L("Grows, whether it works or not:\n\(growthHint)"),
            lockLine(for: hustle),
            L("If it works: \(fame) fame — it makes your next project easier and helps you get \(category.displayName) jobs. Projects don't pay money: they're for fame and skills."),
            lossLine(for: hustle),
        ].compactMap { $0 }.joined(separator: "\n\n")
    }
}

#Preview {
    PrivateProjectsView(
        player: Player(),
        selectedSideHustles: .constant([])
    )
    .padding()
}
