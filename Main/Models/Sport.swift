import Foundation

/// A discipline the player can train in by spending their yearly spare-time
/// slot. Each year practiced bumps the matching soft skills (like a hobby)
/// and adds a year to `Player.sportYears`, which gates Competitions tagged
/// with the sport and scales the player's win probability inside them.
enum Sport: String, CaseIterable, Codable, Hashable, Identifiable {
    case running
    case swimming
    case cycling
    case soccer
    case basketball
    case tennis
    case martialArts
    case gymnastics
    case esports

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
        case .esports:      return "E-Sports"
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
        case .esports:      return "🎮"
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
        case .esports:      return "Competitive video gaming. Hours of structured practice on a chosen title sharpen reflexes and tactical reading."
        }
    }

    /// Stages in which the sport is offered. Most sports are open from childhood
    /// onward; a couple (gymnastics, esports) bias to teen/adult availability.
    var stages: Set<LifeStage> {
        switch self {
        case .esports:      return [.teen, .youngAdult, .adult]
        default:            return [.child, .teen, .youngAdult, .adult]
        }
    }

    /// Soft-skill bumps applied each year the player trains in this sport.
    /// Mirrors `Hobby.abilities` so `Player.selectSport` / `deselectSport` can
    /// reuse the bump-and-reverse pattern.
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
                .init(keyPath: \.resilienceAndEndurance, weight: 2),
                .init(keyPath: \.outdoorAndWeatherResilience, weight: 1)
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
        case .esports:
            return [
                .init(keyPath: \.tinkeringAndFingerPrecision, weight: 2),
                .init(keyPath: \.analyticalReasoningAndProblemSolving, weight: 1)
            ]
        }
    }
}
