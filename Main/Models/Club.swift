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
    Club(
        label: "Robotics Club",
        abilities: [
            .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
            .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
            .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1),
            .init(keyPath: \.collaborationAndTeamwork, weight: 1)
        ],
        stages: [.teen, .youngAdult]
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
    Club(
        label: "Model UN",
        abilities: [
            .init(keyPath: \.communicationAndNetworking, weight: 2)
        ],
        stages: [.teen, .youngAdult]
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
