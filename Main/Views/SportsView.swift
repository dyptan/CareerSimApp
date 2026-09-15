import SwiftUI

/// Lets the player commit this year's spare-time slot to training in a sport.
/// Sports share the same `selectedActivities` slot as hobbies, certifications,
/// and licenses, so picking one displaces any other activity. Each year of
/// practice banks into `Player.sportYears`, which (a) escalates the tier of the
/// competition the sport auto-enters each year and (b) adds a sport-fit bonus to
/// its win probability. Competitions have no menu of their own — they resolve
/// automatically for the trained sport in `Player.advanceYear`; each row here
/// previews the current contest and win odds.
struct SportsView: View {
    @ObservedObject var player: Player
    @Binding var selectedActivities: Set<String>
    @Binding var selectedSports: Set<Sport>
    /// Training a sport spends the year: closes the sheet and runs it.
    var onCommit: () -> Void = {}

    private var currentStage: LifeStage { LifeStage.forAge(player.age) }

    private var stageSports: [Sport] {
        Sport.allCases.filter {
            $0.stages.contains(currentStage)
                && (!$0.isElite || player.difficulty == .comfortable)
        }
    }

    var body: some View {
        // No header strip — see `HobbiesView`: the sheet opens on the sports
        // themselves, and a taken slot shows as dimmed rows.
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(stageSports) { sport in
                        row(for: sport)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func row(for sport: Sport) -> some View {
        // The skills a year of training builds are listed in the info hint —
        // the row itself stays clean.
        let abilityHint: String = sport.abilities
            .map { ability -> String in
                let label = SoftSkills.label(forKeyPath: ability.keyPath) ?? "Skill"
                let pic = SoftSkills.pictogram(forKeyPath: ability.keyPath) ?? ""
                return "\(pic) \(label) (+\(ability.weight))"
            }
            .joined(separator: "\n")

        let years = player.sportYears[sport, default: 0]

        // The contest this sport would feed *this* year. The year being
        // committed counts as a trained year, so the tier and odds are computed
        // with years + 1 — exactly what `advanceYear` rolls after banking it.
        let enteredYears = years + 1
        let competition = CompetitionCatalog.bestCompetition(
            forSport: sport, stage: currentStage, years: enteredYears
        )
        let competitionOdds = competition.map {
            Int(($0.winProbability(for: player.softSkills, years: enteredYears) * 100).rounded())
        }

        let competitionLine: String = {
            guard let competition, let competitionOdds else { return "" }
            return "\n🏅 \(competition.name) · 🎲 ~\(competitionOdds)%"
        }()

        HStack(spacing: 8) {
            Text("\(sport.pictogram) \(sport.label)\(years > 0 ? "  ·  \(years) yr\(years == 1 ? "" : "s") trained" : "")\(competitionLine)")
                .frame(maxWidth: .infinity, alignment: .leading)

            TakeButton {
                player.selectSport(sport, into: &selectedActivities, sports: &selectedSports)
                onCommit()
            }

            InfoHint(
                title: "\(sport.pictogram) \(sport.label)",
                message: "\(sport.description)\n\nEach year of training builds:\n\n\(abilityHint)\n\nWhile you train a sport you automatically compete in its top event each year — no entry fee. Your win odds start low and climb with every year trained (and the skills it builds), unlocking bigger contests along the way."
            )
        }
        .padding(5)
    }
}

#Preview {
    SportsView(
        player: Player(),
        selectedActivities: .constant([]),
        selectedSports: .constant([])
    )
    .padding()
}
