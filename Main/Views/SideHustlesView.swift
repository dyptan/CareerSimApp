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
                return a == b ? $0.label < $1.label : a > b
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
        let oddsPct = Int((odds * 100).rounded())

        let talentHint: String = hustle.talents
            .map { kp -> String in
                let label = SoftSkills.label(forKeyPath: kp) ?? "Skill"
                let pic = SoftSkills.pictogram(forKeyPath: kp) ?? ""
                return "\(pic) \(label)"
            }
            .joined(separator: "\n")

        let growthHint: String = hustle.growth
            .map { boost -> String in
                let label = SoftSkills.label(forKeyPath: boost.keyPath) ?? "Skill"
                let pic = SoftSkills.pictogram(forKeyPath: boost.keyPath) ?? ""
                return "\(pic) \(label) +\(boost.weight)"
            }
            .joined(separator: "\n")

        let locked = !player.canTakeProject(hustle)

        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("\(hustle.icon)  \(hustle.label)")
                        .font(.headline)
                    if !locked {
                        Text("🎲 \(oddsPct)%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Color.forOdds(odds))
                    }
                }
                if let award = hustle.requiresAward, locked {
                    Text("🔒 Needs the “\(award)” title")
                        .font(.caption2)
                        .foregroundStyle(.orange)
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
        guard let award = hustle.requiresAward, !player.canTakeProject(hustle) else { return nil }
        return "🔒 Opens once you hold the “\(award)” title — chase it under Projects."
    }

    /// The project hint, kept to what the player can act on: the blurb, the
    /// odds and what moves them, the fame a win banks (projects pay no money —
    /// they build fame and skills), what the year costs either way. The
    /// mechanic used to be spelled out in full prose, which made every row a
    /// wall of text to read past.
    private func infoMessage(for hustle: SideHustle, odds: Double,
                             talentHint: String, growthHint: String) -> String {
        let oddsPct = Int((odds * 100).rounded())
        let category = hustle.fameCategory
        let fame = "\(category.icon) \(category.rawValue)"

        // Naming the drivers with where the player stands now makes a 0% row
        // read as "not yet" rather than "broken".
        var oddsLine = "Your chance goes up with the skills below, your \(player.totalExperienceYears) years of work"
        if let cat = hustle.experienceCategory {
            let field = player.industryExperience(for: cat)
            oddsLine += " (your \(field) years in \(JobCategory.icon(for: cat)) \(cat.rawValue) count double)"
        }
        oddsLine += ", and the \(fame) fame you already have — being known in a field makes the next project there easier."

        let climate = player.projectClimate(for: hustle)
        let climateLine = climate == .steady
            ? nil
            : "\(climate.icon) This field is \(climate.rawValue.lowercased()) this year: \(SkillsView.easierOrHarder(climate.projectFactor))."

        // Only the fame is at stake — the skill gains and the banked experience
        // land either way, so the loss line says what is actually lost.
        var lossLine = "If it doesn't work out: you just miss the fame — you keep the skills."
        if let cat = hustle.experienceCategory {
            let credited = cat.creditedExperienceCategories
                .map { "\(JobCategory.icon(for: $0)) \($0.rawValue)" }
                .joined(separator: ", ")
            lossLine += " 📅 The year still counts as \(JobCategory.icon(for: cat)) \(cat.rawValue) work experience"
            lossLine += credited.isEmpty ? "." : ", which also helps for \(credited) jobs."
        }

        return [
            hustle.blurb,
            "🎲 \(oddsPct)% chance it works · 🌟 \(fame) fame",
            oddsLine,
            climateLine,
            "Needs:\n\(talentHint)",
            "Grows, whether it works or not:\n\(growthHint)",
            lockLine(for: hustle),
            "If it works: \(fame) fame — it makes your next project easier and helps you get \(category.rawValue) jobs. Projects don't pay money: they're for fame and skills.",
            lossLine,
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
