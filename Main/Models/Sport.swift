import Foundation

/// Which tab of the Activities sheet a discipline sits under.
enum ActivityKind: String, CaseIterable, Identifiable {
    case sports = "Sports"
    case artsAndMinds = "Arts & Minds"
    /// School subjects, open while the player is at school. Besides levels and
    /// contests, a year spent here lifts that year's high-school grade (see
    /// `Player.yearGrade(studied:)`).
    case study = "Study"

    var id: String { rawValue }
}

/// How far along a discipline the player is, named from the years practised —
/// the "level" shown on each Activities row.
enum ActivityLevel: String {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"

    /// `nil` before the first year is banked.
    init?(years: Int) {
        switch years {
        case ..<1:  return nil
        case 1:     self = .beginner
        case 2...3: self = .intermediate
        case 4...6: self = .advanced
        default:    self = .expert
        }
    }
}

/// A discipline the player can train in by spending their yearly spare-time
/// slot — athletic, creative, or a contest of the mind. Every one of them
/// **levels up and competes**: that is the bar for being in the Activities
/// sheet at all (pastimes with no ladder — a diary, educational TV — were cut).
/// Each year practised bumps the matching soft skills and adds a year to
/// `Player.sportYears`, which names the level, gates the Competitions tagged
/// with the discipline, and scales the win probability inside them.
///
/// The type keeps its original name, `Sport`, from before the arts and mind
/// disciplines joined; read it as "discipline".
enum Sport: String, CaseIterable, Codable, Hashable, Identifiable {
    // Sports
    case running
    case swimming
    case cycling
    case soccer
    case basketball
    case tennis
    case martialArts
    case gymnastics
    case skateboarding
    case esports
    // Arts & minds
    case music
    case drawing
    case photography
    case cooking
    case dance
    case coding
    case chess
    case debate
    case studentCouncil
    // Study
    case math
    case science
    case literature
    case history
    case languages

    var id: String { rawValue }

    var label: String {
        switch self {
        case .running:      return "Running"
        case .swimming:     return "Swimming"
        case .cycling:      return "Cycling"
        case .soccer:       return "Soccer"
        case .basketball:   return "Basketball"
        case .tennis:       return "Tennis"
        case .martialArts:  return "Martial Arts"
        case .gymnastics:   return "Gymnastics"
        case .skateboarding: return "Skateboarding & BMX"
        case .esports:      return "E-Sports"
        case .music:        return "Music"
        case .drawing:      return "Drawing & Painting"
        case .photography:  return "Photography"
        case .cooking:      return "Cooking"
        case .dance:        return "Dance"
        case .coding:       return "Coding"
        case .chess:        return "Chess"
        case .debate:       return "Debate"
        case .studentCouncil: return "Student Council"
        case .math:         return "Mathematics"
        case .science:      return "Science"
        case .literature:   return "Reading & Writing"
        case .history:      return "History & Geography"
        case .languages:    return "Foreign Languages"
        }
    }

    var pictogram: String {
        switch self {
        case .running:      return "🏃"
        case .swimming:     return "🏊"
        case .cycling:      return "🚴"
        case .soccer:       return "⚽"
        case .basketball:   return "🏀"
        case .tennis:       return "🎾"
        case .martialArts:  return "🥋"
        case .gymnastics:   return "🤸"
        case .skateboarding: return "🛹"
        case .esports:      return "🎮"
        case .music:        return "🎵"
        case .drawing:      return "🎨"
        case .photography:  return "📷"
        case .cooking:      return "🍳"
        case .dance:        return "💃"
        case .coding:       return "💻"
        case .chess:        return "♟️"
        case .debate:       return "🗣️"
        case .studentCouncil: return "🗳️"
        case .math:         return "➗"
        case .science:      return "🔬"
        case .literature:   return "📖"
        case .history:      return "🌍"
        case .languages:    return "🈯"
        }
    }

    var description: String {
        switch self {
        case .running:      return "Track and road running — the foundation of athletic endurance. Cheap to start, but the kilometres add up over years."
        case .swimming:     return "Lap swimming and open water. A full-body endurance sport with low joint impact and a strong calm-under-pressure benefit."
        case .cycling:      return "Road and gravel cycling. Long outdoor sessions build endurance and resilience to weather."
        case .soccer:       return "Team football. A lifelong team sport that builds endurance and the habit of moving in sync with others."
        case .basketball:   return "Five-a-side basketball. Fast-paced team sport rewarding agility, teamwork, and split-second decisions."
        case .tennis:       return "Singles or doubles tennis. A racket sport that drills focus, footwork, and composure in long points."
        case .martialArts:  return "Karate, judo, boxing — disciplines that drill technique, respect, and grit through repetition."
        case .gymnastics:   return "Floor, bars, vault, beam. Years of precision, body control, and strength work build the toolkit of an Olympic-stream athlete."
        case .skateboarding: return "Street and park skating, BMX tricks. An Olympic sport now — falls, balance, and nerve, one trick at a time."
        case .esports:      return "Competitive video gaming. Hours of structured practice on a chosen title sharpen reflexes and tactical reading."
        case .music:        return "Lessons on an instrument, graded exam by exam. Daily practice, and the nerve to perform what you've practised."
        case .drawing:      return "Sketching, painting, and composition. Patient hands and a trained eye, built one piece at a time."
        case .photography:  return "Framing, light, and timing. You learn to see a picture before you take it — and to plan the shoot around it."
        case .cooking:      return "From first recipes to plating under pressure. Precise hands, invention, and cooking for other people."
        case .dance:        return "Ballet, hip-hop, ballroom — technique drilled until it looks effortless, then performed."
        case .coding:       return "Building programs, from block-based puzzles to real software. Logic, precision, and sticking with a bug until it's fixed."
        case .chess:        return "Openings, tactics, endgames. The classic contest of pure calculation and nerve over the board."
        case .debate:       return "Arguing a case against the clock — research it, build it, and persuade a room."
        case .studentCouncil: return "Run for office, then run things: organise events, speak for your class, and get a room of classmates to agree. The one place school teaches leadership."
        case .math:         return "Extra maths beyond the lesson: puzzles, proofs, and problem sets that stretch you."
        case .science:      return "Experiments, lab reports, and a project of your own for the science fair."
        case .literature:   return "Reading widely and writing often — spelling, essays, and stories."
        case .history:      return "Maps, eras, and how the world got this way — the stuff quiz bowls are made of."
        case .languages:    return "Learning another language properly: vocabulary, grammar, and speaking it out loud."
        }
    }

    /// The Activities tab this discipline is listed under.
    var kind: ActivityKind {
        switch self {
        case .running, .swimming, .cycling, .soccer, .basketball, .tennis,
             .martialArts, .gymnastics, .skateboarding, .esports:
            return .sports
        case .music, .drawing, .photography, .cooking, .dance, .coding, .chess, .debate,
             .studentCouncil:
            return .artsAndMinds
        case .math, .science, .literature, .history, .languages:
            return .study
        }
    }

    /// The reputation bucket a competition win in this discipline banks into —
    /// an athlete becomes a name in the spotlight, a pianist in the arts, a
    /// coder in technology.
    var fameCategory: FameCategory {
        switch self {
        case .running, .swimming, .cycling, .soccer, .basketball, .tennis,
             .martialArts, .gymnastics, .skateboarding, .esports:
            return .entertainment
        case .music, .drawing, .photography, .cooking, .dance:
            return .arts
        case .coding:
            return .technology
        case .chess:
            return .science
        case .debate, .studentCouncil:
            return .business
        case .math, .science, .history:
            return .science
        case .literature:
            return .arts
        case .languages:
            return .business
        }
    }

    /// Stages in which the discipline is offered: everything is open from
    /// childhood (kids code in block languages) except competitive gaming.
    var stages: Set<LifeStage> {
        switch self {
        case .esports:      return [.teen, .youngAdult, .adult]
        // School subjects and the student council run while the player is at
        // school (7–17).
        case .math, .science, .literature, .history, .languages, .studentCouncil:
            return [.child, .teen]
        default:            return [.child, .teen, .youngAdult, .adult]
        }
    }

    /// Gear- or coaching-heavy sports that only appear in `.comfortable`
    /// ("Relaxed", well-off family) runs — court fees, club memberships, and
    /// private coaching put them out of reach for average families.
    /// `ActivityListView` hides them on every other difficulty.
    var isElite: Bool {
        switch self {
        case .tennis, .gymnastics: return true
        default:                   return false
        }
    }

    /// Soft-skill bumps applied each year the player trains in this sport.
    /// Applied by `Player.selectSport` when the year is committed.
    var abilities: [WeightedAbility] {
        switch self {
        case .running:
            return [
                .init(keyPath: \.resilienceAndEndurance, weight: 2),
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
            ]
        case .swimming:
            return [
                .init(keyPath: \.resilienceAndEndurance, weight: 2),
                .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
            ]
        case .cycling:
            return [
                .init(keyPath: \.resilienceAndEndurance, weight: 3)
            ]
        case .soccer:
            return [
                .init(keyPath: \.collaborationAndTeamwork, weight: 2),
                .init(keyPath: \.resilienceAndEndurance, weight: 1)
            ]
        case .basketball:
            return [
                .init(keyPath: \.collaborationAndTeamwork, weight: 2),
                .init(keyPath: \.resilienceAndEndurance, weight: 1)
            ]
        case .tennis:
            return [
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                .init(keyPath: \.resilienceAndEndurance, weight: 1),
                .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
            ]
        case .martialArts:
            return [
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
                .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
            ]
        case .gymnastics:
            return [
                .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                .init(keyPath: \.resilienceAndEndurance, weight: 1),
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
            ]
        case .skateboarding:
            return [
                .init(keyPath: \.spacialNavigationAndOrientation, weight: 2),
                .init(keyPath: \.resilienceAndEndurance, weight: 2),
                .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
            ]
        case .esports:
            return [
                .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)
            ]
        case .music:
            return [
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 2),
                .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ]
        case .drawing:
            return [
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
            ]
        case .photography:
            return [
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                .init(keyPath: \.timeManagementAndPlanning, weight: 1),
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1)
            ]
        case .cooking:
            return [
                .init(keyPath: \.tinkeringAndFingerPrecision, weight: 1),
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.empathyAndInterpersonalCare, weight: 1)
            ]
        case .dance:
            return [
                .init(keyPath: \.communicationAndNetworking, weight: 2),
                .init(keyPath: \.resilienceAndEndurance, weight: 1),
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
            ]
        case .coding:
            return [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 2),
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
            ]
        case .chess:
            return [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                .init(keyPath: \.stressResistanceAndEmotionalRegulation, weight: 1)
            ]
        case .debate:
            return [
                .init(keyPath: \.communicationAndNetworking, weight: 3),
                .init(keyPath: \.persuasionAndNegotiation, weight: 1)
            ]
        case .studentCouncil:
            return [
                .init(keyPath: \.leadershipAndInfluence, weight: 2),
                .init(keyPath: \.visionaryThinkingAndAmbition, weight: 1),
                .init(keyPath: \.persuasionAndNegotiation, weight: 1),
                .init(keyPath: \.collaborationAndTeamwork, weight: 1)
            ]
        case .math:
            return [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 2),
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
            ]
        case .science:
            return [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1),
                .init(keyPath: \.timeManagementAndPlanning, weight: 1)
            ]
        case .literature:
            return [
                .init(keyPath: \.communicationAndNetworking, weight: 2),
                .init(keyPath: \.creativityAndInsightfulThinking, weight: 1),
                .init(keyPath: \.carefulnessAndAttentionToDetail, weight: 1)
            ]
        case .history:
            return [
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1),
                .init(keyPath: \.spacialNavigationAndOrientation, weight: 1),
                .init(keyPath: \.communicationAndNetworking, weight: 1),
                .init(keyPath: \.timeManagementAndPlanning, weight: 1)
            ]
        case .languages:
            return [
                .init(keyPath: \.communicationAndNetworking, weight: 2),
                .init(keyPath: \.empathyAndInterpersonalCare, weight: 1),
                .init(keyPath: \.selfDisciplineAndPerseverance, weight: 1)
            ]
        }
    }
}
