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

        HStack(spacing: 8) {
            Text("\(hustle.icon)  \(hustle.label)")
                .font(.headline)
            Text("🎲 \(oddsPct)%")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Color.forOdds(odds))
            Spacer(minLength: 8)

            // Picking a project is committing the year to it — the sheet
            // closes and the year runs, so there is only ever one pick to hold.
            TakeButton {
                selectedSideHustles = [hustle.id]
                onCommit()
            }

            InfoHint(
                title: "\(hustle.icon) \(hustle.label)",
                message: infoMessage(for: hustle, odds: odds, talentHint: talentHint, growthHint: growthHint)
            )
        }
        .padding(5)
    }

    private func infoMessage(for hustle: SideHustle, odds: Double,
                             talentHint: String, growthHint: String) -> String {
        let intro = hustle.blurb + "\n\n"
        let oddsPct = Int((odds * 100).rounded())
        // The two things the player can move. Naming both, with where they stand
        // now, makes a 0% row read as "not yet" rather than "broken".
        let drivers: String = {
            let career = player.totalExperienceYears
            let field = hustle.experienceCategory.map { player.industryExperience(for: $0) } ?? 0
            var line = "The odds rise with the skills below and with your \(career) yr of work experience."
            if let cat = hustle.experienceCategory {
                let icon = JobCategory.icon(for: cat)
                line += " Your \(field) yr in \(icon) \(cat.rawValue) count double here."
            }
            return line + "\n\n"
        }()
        let experienceNote: String = {
            guard let cat = hustle.experienceCategory else { return "" }
            let icon = JobCategory.icon(for: cat)
            let credited = cat.creditedExperienceCategories
                .map { "\(JobCategory.icon(for: $0)) \($0.rawValue)" }
                .joined(separator: ", ")
            let creditLine = credited.isEmpty
                ? ""
                : " Those years also count toward \(credited) roles."
            return "\n\n📅 A committed year — win or lose — banks a year of \(icon) \(cat.rawValue) work experience.\(creditLine)"
        }()
        let category = hustle.fameCategory
        let stats = "🎲 \(oddsPct)% success · 🌟 \(category.icon) \(category.rawValue) fame\n\n"
        return intro + stats + drivers + "Draws on:\n\n\(talentHint)\n\nA project spends the soft skills you've built for a shot at being noticed. A successful year banks \(category.icon) \(category.rawValue) fame (it only lifts your hiring odds for \(category.rawValue) roles) and grows you the way a hobby can't:\n\n\(growthHint)\n\nThe odds also climb with your existing reputation. A dud year yields nothing." + experienceNote
    }
}

#Preview {
    PrivateProjectsView(
        player: Player(),
        selectedSideHustles: .constant([])
    )
    .padding()
}
