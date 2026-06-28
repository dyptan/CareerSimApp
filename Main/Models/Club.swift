import Foundation

/// A school-era extracurricular: clubs (debate, robotics, Model UN, student
/// council) and academic competitions (science fair, math olympiad).
/// Practising one spends the same yearly spare-time slot as a hobby, sport,
/// certification, or license and bumps the matching soft skills. A few map
/// to a portfolio `Project` so the work produces a hiring signal; others
/// build skill alone.
struct Club {
    let label: String
    let abilities: [WeightedAbility]
    /// Stages in which the club is offered (mirrors `Hobby.stages`).
    let stages: Set<LifeStage>
    /// Fee- or travel-heavy clubs (robotics kits, Model UN conference fees)
    /// that only appear in `.comfortable` ("Relaxed", well-off family) runs.
    /// `ClubsView` hides them on every other difficulty.
    var isElite: Bool = false
}

/// Catalogue of clubs. `ClubsView` filters by life stage; with most options
/// gated to school-era stages, the dialog naturally feels empty in adult
/// years — a deliberate choice that pushes adults toward Events, Side
/// Hustles, and Competitions instead.
let clubs: [Club] = [

    // MARK: - Academic competitions

    // → paper (science fair write-up)
    Club(
        label: "Science Fair",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.creativityAndInsightfulThinking, weight: 1)
        ],
        stages: [.child, .teen]
    ),
    // Skill-building, no portfolio output
    Club(
        label: "Math Olympiad",
        abilities: [
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
        ],
        stages: [.child, .teen]
    ),

    // MARK: - School clubs

    // Skill-building, no portfolio output
    // Elite: kits, parts, and competition travel are pay-to-play.
    Club(
        label: "Robotics Club",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ],
        stages: [.teen, .youngAdult],
        isElite: true
    ),
    // → presentation (debates are structured talks)
    Club(
        label: "Debate Club",
        abilities: [
            .init(keyPath: \.presentationAndStorytelling, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
            .init(keyPath: \.communicationAndNetworking, weight: 1)
        ],
        stages: [.teen, .youngAdult]
    ),
    // Skill-building, no portfolio output
    // Elite: registration fees plus travel to conferences price most families out.
    Club(
        label: "Model UN",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 2)
        ],
        stages: [.teen, .youngAdult],
        isElite: true
    ),
    // Skill-building, no portfolio output
    Club(
        label: "Student Council",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 1),
            .init(keyPath: \.timeManagementAndPlanning, weight: 1),
            .init(keyPath: \.presentationAndStorytelling, weight: 1)
        ],
        stages: [.teen, .youngAdult]
    )
]
