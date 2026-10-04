import SwiftUI

/// One tab of the Activities sheet: the disciplines of one `ActivityKind` open
/// at the player's age. Every discipline shares the year's single
/// `selectedActivities` slot with certifications and licences, so taking one
/// spends the year. Each year of practice banks into `Player.sportYears`, which
/// (a) names the level shown on the row, (b) escalates the tier of the contest
/// the discipline auto-enters each year and (c) adds a fit bonus to its win
/// probability. Competitions have no menu of their own — they resolve
/// automatically in `Player.advanceYear`.
struct ActivityListView: View {
    @ObservedObject var player: Player
    let kind: ActivityKind
    @Binding var selectedActivities: Set<String>
    @Binding var selectedSports: Set<Sport>
    /// Practising spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    /// The disciplines of `kind` open to this player now: their life stage's,
    /// minus the elite ones in the Simplified tutorial (`Sport.isOffered`).
    /// Shared with `ActivitiesView`, which hides a tab (and the footer its
    /// button) when empty.
    static func offered(to player: Player, kind: ActivityKind) -> [Sport] {
        let stage = LifeStage.forAge(player.age)
        return Sport.allCases.filter {
            $0.kind == kind
                && $0.stages.contains(stage)
                && $0.isOffered(in: player.difficulty)
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
            .map(SkillLine.gain)
            .joined(separator: "\n")

        let years = player.sportYears[sport, default: 0]
        // "Beginner (1 yr)" — one plural key per line, so each language inflects "yr" itself.
        let levelText: String? = ActivityLevel(years: years)
            .map { L("\($0.displayName) (\(years) yrs)") }
        let title = "\(sport.pictogram) \(sport.displayName)"
        let rowTitle = levelText.map { "\(title)  ·  \($0)" } ?? title

        // The contest this discipline would feed *this* year. The year being
        // committed counts as a practised year, so the tier and odds are
        // computed with years + 1 — exactly what `advanceYear` rolls after
        // banking it.
        let enteredYears = years + 1
        let competition = CompetitionCatalog.bestCompetition(
            forSport: sport, stage: currentStage, years: enteredYears
        )
        let competitionOdds = competition.map {
            $0.winProbability(for: player.softSkills, years: enteredYears)
        }

        HStack(spacing: 8) {
            // The contest stays out of the list until the player has kept at
            // the discipline — shown only if it was practised last year. It
            // sits beside the name, not among the buttons, so every row's Take
            // stays in one column.
            HStack(spacing: 6) {
                // Long names and levels wrap onto a second line rather than clip.
                Text(verbatim: rowTitle)
                    .fixedSize(horizontal: false, vertical: true)
                if player.lastYearSports.contains(sport), let competition, let competitionOdds {
                    InfoHint(
                        title: "\(competition.icon) \(competition.name)",
                        message: contestHint(for: competition, sport: sport, odds: competitionOdds),
                        symbol: "trophy"  // i18n:ignore SF Symbol name
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TakeButton {
                player.selectSport(sport, into: &selectedActivities, sports: &selectedSports)
                onCommit()
            }

            InfoHint(
                title: "\(sport.pictogram) \(sport.displayName)",
                message: disciplineHint(for: sport, abilityHint: abilityHint)
            )
        }
        .padding(5)
    }

    /// The 🏆 popover: this year's contest, the odds and the prize.
    private func contestHint(for competition: Competition, sport: Sport, odds: Double) -> String {
        [
            competition.blurb,
            [
                L("🎲 Your chance to win this year: about \(Fmt.percent(odds))"),
                L("🏆 If you win: the “\(competition.achievement)” title and \(sport.fameCategory.displayName) fame."),
            ].joined(separator: "\n"),
            L("Practise it again this year and you're entered automatically."),
        ].joined(separator: "\n\n")
    }

    /// The ⓘ popover: what the discipline is, what a year of it grows, and how its contests work.
    private func disciplineHint(for sport: Sport, abilityHint: String) -> String {
        var paragraphs = [
            sport.description,
            L("Every year you practise, you grow:") + "\n\n" + abilityHint,
            L("While you practise it, you're entered in its biggest contest each year — for free. Your chance to win starts small and grows every year, and bigger contests open up as you get better. Wins make you famous in \(sport.fameCategory.displayName)."),
        ]
        if sport.kind == .study {
            paragraphs.append(L("📝 In high school, a year of study also raises that year's grade — which colleges look at when you apply."))
        }
        return paragraphs.joined(separator: "\n\n")
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
