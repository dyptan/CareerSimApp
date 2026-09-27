import SwiftUI

/// One tab of the Activities sheet: the disciplines of one `ActivityKind` open
/// at the player's age. Every discipline shares the year's single
/// `selectedActivities` slot with certifications and licences, so taking one
/// spends the year. Each year of practice banks into `Player.sportYears`, which
/// (a) names the level shown on the row, (b) escalates the tier of the contest
/// the discipline auto-enters each year and (c) adds a fit bonus to its win
/// probability. Competitions have no menu of their own — they resolve
/// automatically in `Player.advanceYear`. A row keeps this year's contest behind
/// a 🏆 button, shown only for a discipline practised last year.
struct ActivityListView: View {
    @ObservedObject var player: Player
    let kind: ActivityKind
    @Binding var selectedActivities: Set<String>
    @Binding var selectedSports: Set<Sport>
    /// Practising spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    /// The disciplines of `kind` open to this player now: their life stage's,
    /// minus the elite ones outside a well-off (`.comfortable`) run. Shared with
    /// `ActivitiesView`, which hides a tab (and the footer its button) when empty.
    static func offered(to player: Player, kind: ActivityKind) -> [Sport] {
        let stage = LifeStage.forAge(player.age)
        return Sport.allCases.filter {
            $0.kind == kind
                && $0.stages.contains(stage)
                && (!$0.isElite || player.difficulty == .comfortable)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Self.offered(to: player, kind: kind)) { sport in
                    row(for: sport)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func row(for sport: Sport) -> some View {
        // The skills a year of practice builds are listed in the info hint —
        // the row itself stays clean.
        let abilityHint: String = sport.abilities
            .map { ability -> String in
                let label = SoftSkills.label(forKeyPath: ability.keyPath) ?? "Skill"
                let pic = SoftSkills.pictogram(forKeyPath: ability.keyPath) ?? ""
                return "\(pic) \(label) (+\(ability.weight))"
            }
            .joined(separator: "\n")

        let years = player.sportYears[sport, default: 0]
        let levelLine: String = ActivityLevel(years: years)
            .map { "  ·  \($0.rawValue) (\(years) yr\(years == 1 ? "" : "s"))" } ?? ""

        // The contest this discipline would feed *this* year. The year being
        // committed counts as a practised year, so the tier and odds are
        // computed with years + 1 — exactly what `advanceYear` rolls after
        // banking it.
        let enteredYears = years + 1
        let competition = CompetitionCatalog.bestCompetition(
            forSport: sport, stage: currentStage, years: enteredYears
        )
        let competitionOdds = competition.map {
            Int(($0.winProbability(for: player.softSkills, years: enteredYears) * 100).rounded())
        }

        HStack(spacing: 8) {
            // The contest stays out of the list until the player has kept at
            // the discipline — shown only if it was practised last year. It
            // sits beside the name, not among the buttons, so every row's Take
            // stays in one column.
            HStack(spacing: 6) {
                Text("\(sport.pictogram) \(sport.label)\(levelLine)")
                if player.lastYearSports.contains(sport), let competition, let competitionOdds {
                    InfoHint(
                        title: "\(competition.icon) \(competition.name)",
                        message: "\(competition.blurb)\n\n🎲 Your chance to win this year: about \(competitionOdds)%\n🏆 If you win: the “\(competition.achievement)” title and \(sport.fameCategory.rawValue) fame.\n\nPractise it again this year and you're entered automatically.",
                        symbol: "trophy"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TakeButton {
                player.selectSport(sport, into: &selectedActivities, sports: &selectedSports)
                onCommit()
            }

            InfoHint(
                title: "\(sport.pictogram) \(sport.label)",
                message: "\(sport.description)\n\nEvery year you practise, you grow:\n\n\(abilityHint)\n\nWhile you practise it, you're entered in its biggest contest each year — for free. Your chance to win starts small and grows every year, and bigger contests open up as you get better. Wins make you famous in \(sport.fameCategory.rawValue).\(sport.kind == .study ? "\n\n📝 In high school, a year of study also raises that year's grade — which colleges look at when you apply." : "")"
            )
        }
        .padding(5)
    }
}

#Preview {
    ActivityListView(
        player: Player(),
        kind: .sports,
        selectedActivities: .constant([]),
        selectedSports: .constant([])
    )
    .padding()
}
