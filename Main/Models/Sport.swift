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
/// sheet at all.
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

    /// What the player reads for this discipline — the localized name (`displayName`,
    /// DisplayNames.swift). Kept under its old name for the callers that print it;
    /// `rawValue` is the id and is never shown.
    var label: String { displayName }

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
        case .running:      return L("Track and road running — the foundation of athletic endurance. Cheap to start, but the kilometres add up over years.")
        case .swimming:     return L("Lap swimming and open water. A full-body endurance sport with low joint impact and a strong calm-under-pressure benefit.")
        case .cycling:      return L("Road and gravel cycling. Long outdoor sessions build endurance and resilience to weather.")
        case .soccer:       return L("Team football. A lifelong team sport that builds endurance and the habit of moving in sync with others.")
        case .basketball:   return L("Five-a-side basketball. Fast-paced team sport rewarding agility, teamwork, and split-second decisions.")
        case .tennis:       return L("Singles or doubles tennis. A racket sport that drills focus, footwork, and composure in long points.")
        case .martialArts:  return L("Karate, judo, boxing — disciplines that drill technique, respect, and grit through repetition.")
        case .gymnastics:   return L("Floor, bars, vault, beam. Years of precision, body control, and strength work build the toolkit of an Olympic-stream athlete.")
        case .skateboarding: return L("Street and park skating, BMX tricks. An Olympic sport now — falls, balance, and nerve, one trick at a time.")
        case .esports:      return L("Competitive video gaming. Hours of structured practice on a chosen title sharpen reflexes and tactical reading.")
        case .music:        return L("Lessons on an instrument, graded exam by exam. Daily practice, and the nerve to perform what you've practised.")
        case .drawing:      return L("Sketching, painting, and composition. Patient hands and a trained eye, built one piece at a time.")
        case .photography:  return L("Framing, light, and timing. You learn to see a picture before you take it — and to plan the shoot around it.")
        case .cooking:      return L("From first recipes to plating under pressure. Precise hands, invention, and cooking for other people.")
        case .dance:        return L("Ballet, hip-hop, ballroom — technique drilled until it looks effortless, then performed.")
        case .coding:       return L("Building programs, from block-based puzzles to real software. Logic, precision, and sticking with a bug until it's fixed.")
        case .chess:        return L("Openings, tactics, endgames. The classic contest of pure calculation and nerve over the board.")
        case .debate:       return L("Arguing a case against the clock — research it, build it, and persuade a room.")
        case .studentCouncil: return L("Run for office, then run things: organise events, speak for your class, and get a room of classmates to agree. The one place school teaches leadership.")
        case .math:         return L("Extra maths beyond the lesson: puzzles, proofs, and problem sets that stretch you.")
        case .science:      return L("Experiments, lab reports, and a project of your own for the science fair.")
        case .literature:   return L("Reading widely and writing often — spelling, essays, and stories.")
        case .history:      return L("Maps, eras, and how the world got this way — the stuff quiz bowls are made of.")
        case .languages:    return L("Learning another language properly: vocabulary, grammar, and speaking it out loud.")
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

    /// Gear- or coaching-heavy sports — court fees, club memberships, private
    /// coaching. Real Life offers them; the Simplified tutorial keeps to the
    /// everyday sports (see `isOffered(in:)`).
    var isElite: Bool {
        switch self {
        case .tennis, .gymnastics: return true
        default:                   return false
        }
    }

    /// Whether the activity list offers this sport in `difficulty`: every sport
    /// in Real Life, all but the elite ones in Simplified. The one rule behind
    /// `ActivityListView.offered`.
    func isOffered(in difficulty: Difficulty) -> Bool {
        !isElite || !difficulty.isSimplified
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

// MARK: - Hint lines for the skills an activity, event or project draws on

/// One skill, written for a hint list: its pictogram and its name ("💬 Persuader"), and the
/// same with the points a year of practice adds. Whole lines, so a translation can move the
/// number ("+2") wherever its language puts it.
enum SkillLine {
    /// "💬 Persuader" — the skill's pictogram and (localized) name.
    static func tag(_ keyPath: WritableKeyPath<SoftSkills, Int>) -> String {
        let label = SoftSkills.label(forKeyPath: keyPath)
            ?? String(localized: "Skill", comment: "Fallback name for a soft skill that has no label")  // i18n:ignore translator comment
        let pic = SoftSkills.pictogram(forKeyPath: keyPath) ?? ""
        return "\(pic) \(label)"
    }

    /// "💬 Persuader (+2)" — a list line in the Activities hint.
    static func gain(_ ability: WeightedAbility) -> String {
        L("\(tag(ability.keyPath)) (+\(ability.weight))")
    }

    /// "💬 Persuader +2" — a list line in the Events and Projects hints.
    static func plus(_ ability: WeightedAbility) -> String {
        L("\(tag(ability.keyPath)) +\(ability.weight)")
    }
}

// MARK: - Sorting by displayed name

/// How the catalogue lists order rows that tie: by the name the player reads. English keeps its
/// plain code-point order (what it has always been); other languages sort the way they alphabetise.
enum NameOrder {
    static func before(_ a: String, _ b: String) -> Bool {
        L10n.language == .english ? a < b : a.localizedStandardCompare(b) == .orderedAscending
    }
}
