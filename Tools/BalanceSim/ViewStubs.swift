import Foundation
// Headless stand-ins for the two SwiftUI views whose static helpers the model layer calls.
enum ActivityListView {
    static func offered(to player: Player, kind: ActivityKind) -> [Sport] {
        let stage = LifeStage.forAge(player.age)
        return Sport.allCases.filter {
            $0.kind == kind && $0.stages.contains(stage) && (!$0.isElite || player.difficulty == .comfortable)
        }
    }
}
enum ActivitiesView {
    static func availableTabs(for player: Player) -> [ActivityKind] {
        ActivityKind.allCases.filter { !ActivityListView.offered(to: player, kind: $0).isEmpty }
    }
}
