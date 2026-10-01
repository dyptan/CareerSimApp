import Foundation

// What the player reads for the game's named things.
//
// **Identity never changes; display is looked up.** `JobCategory.rawValue`, `Job.id`, `Training.rawValue`
// … are English ids: dictionary keys, `Set` members, `Codable` values, test fixtures. They are never
// shown in prose, a title, a button or a list. The player reads `displayName` (enums) or
// `displayTitle` / `displaySummary` (jobs), which are looked up in the String Catalog.
//
//     Text(job.displayTitle)                       // not Text(job.id)
//     L("Years in \(category.displayName)")        // not "\(category.rawValue)"
//
// Never `.capitalized`, `.lowercased()` or `+ "s"` on a display name: they are wrong in German,
// French, Ukrainian … Write the sentence so the name needs no change.
//
// Each section is owned by one part of the localisation work; edit only your own. Until a section's
// owner replaces its stub, a name is its English id, so the game behaves exactly as before.

// MARK: - World: jobs, categories, industries (owner: jobs & catalogue)

extension FameCategory { var displayName: String { rawValue } }
extension WorkSetting { var displayName: String { rawValue } }
extension JobCategory { var displayName: String { rawValue } }
extension Industry { var displayName: String { rawValue } }
extension IndustryClimate { var displayName: String { rawValue } }

extension Job {
    /// The job's own title, in the player's language (`id` is the English title). Not the same as
    /// `displayTitle` (Job.swift), which is how an *occupation* reads — "CEO, <venture>" for a venture.
    var catalogueTitle: String { id }
    /// The role without its seniority ("Software Engineer"), in the player's language.
    var displayBaseTitle: String { baseTitle }
    /// The seniority word ("Senior", "Lead") alone — empty for the bare role.
    var displayRungLabel: String { rungLabel }
    /// What the job is, in a sentence or two.
    var displaySummary: String { summary }
    /// The career ladder named in prose ("as a Teacher"), in the player's language; nil when none.
    var displayExperienceLadder: String? { experienceLadder }
}


// MARK: - Education and training (owner: education & training)

extension TertiaryProfile { var displayName: String { rawValue.capitalized } }
extension Training { var displayName: String { rawValue } }


// MARK: - Activities, contests, events (owner: activities)

extension ActivityKind {
    /// The Activities sheet's tab.
    var displayName: String {
        switch self {
        case .sports:       return String(localized: "Sports", comment: "Activities tab: athletic disciplines such as running and soccer")  // i18n:ignore translator comment
        case .artsAndMinds: return String(localized: "Arts & Minds", comment: "Activities tab: creative and mental disciplines such as music, chess and coding")  // i18n:ignore translator comment
        case .study:        return String(localized: "Study", comment: "Activities tab: school subjects such as maths and science")  // i18n:ignore translator comment
        }
    }
}

extension ActivityLevel {
    /// How far along the player is in a discipline, named from the years practised.
    var displayName: String {
        switch self {
        case .beginner:     return String(localized: "Beginner", comment: "Activity level after the first year of practice")  // i18n:ignore translator comment
        case .intermediate: return String(localized: "Intermediate", comment: "Activity level after two to three years of practice")  // i18n:ignore translator comment
        case .advanced:     return String(localized: "Advanced", comment: "Activity level after four to six years of practice")  // i18n:ignore translator comment
        case .expert:       return String(localized: "Expert", comment: "Activity level after seven or more years of practice")  // i18n:ignore translator comment
        }
    }
}

extension Competition.Discipline {
    /// The kind of contest a competition is.
    var displayName: String {
        switch self {
        case .athletic: return String(localized: "Athletic", comment: "Kind of contest: a sports event")  // i18n:ignore translator comment
        case .esports:  return String(localized: "E-Sports", comment: "Kind of contest: a competitive video-gaming tournament")  // i18n:ignore translator comment
        case .creative: return String(localized: "Creative", comment: "Kind of contest: an arts prize")  // i18n:ignore translator comment
        case .mind:     return String(localized: "Mind", comment: "Kind of contest: a contest of the mind such as chess or debate")  // i18n:ignore translator comment
        case .academic: return String(localized: "Academic", comment: "Kind of contest: a school-subject olympiad or fair")  // i18n:ignore translator comment
        }
    }
}

extension Sport {
    /// What the player reads for a discipline ("Martial Arts"); `rawValue` is the id. Also `label`.
    var displayName: String {
        switch self {
        case .running:        return String(localized: "Running", comment: "Sport")  // i18n:ignore translator comment
        case .swimming:       return String(localized: "Swimming", comment: "Sport")  // i18n:ignore translator comment
        case .cycling:        return String(localized: "Cycling", comment: "Sport")  // i18n:ignore translator comment
        case .soccer:         return String(localized: "Soccer", comment: "Sport: team football")  // i18n:ignore translator comment
        case .basketball:     return String(localized: "Basketball", comment: "Sport")  // i18n:ignore translator comment
        case .tennis:         return String(localized: "Tennis", comment: "Sport")  // i18n:ignore translator comment
        case .martialArts:    return String(localized: "Martial Arts", comment: "Sport: karate, judo, boxing")  // i18n:ignore translator comment
        case .gymnastics:     return String(localized: "Gymnastics", comment: "Sport")  // i18n:ignore translator comment
        case .skateboarding:  return String(localized: "Skateboarding & BMX", comment: "Sport")  // i18n:ignore translator comment
        case .esports:        return String(localized: "E-Sports", comment: "Sport: competitive video gaming")  // i18n:ignore translator comment
        case .music:          return String(localized: "Music", comment: "Hobby: learning an instrument")  // i18n:ignore translator comment
        case .drawing:        return String(localized: "Drawing & Painting", comment: "Hobby")  // i18n:ignore translator comment
        case .photography:    return String(localized: "Photography", comment: "Hobby")  // i18n:ignore translator comment
        case .cooking:        return String(localized: "Cooking", comment: "Hobby")  // i18n:ignore translator comment
        case .dance:          return String(localized: "Dance", comment: "Hobby")  // i18n:ignore translator comment
        case .coding:         return String(localized: "Coding", comment: "Hobby: programming")  // i18n:ignore translator comment
        case .chess:          return String(localized: "Chess", comment: "Hobby")  // i18n:ignore translator comment
        case .debate:         return String(localized: "Debate", comment: "Hobby: competitive debating")  // i18n:ignore translator comment
        case .studentCouncil: return String(localized: "Student Council", comment: "School activity: elected pupils' body")  // i18n:ignore translator comment
        case .math:           return String(localized: "Mathematics", comment: "School subject")  // i18n:ignore translator comment
        case .science:        return String(localized: "activity.science", defaultValue: "Science", comment: "School subject (the field of work is a different key)")  // i18n:ignore translator comment
        case .literature:     return String(localized: "Reading & Writing", comment: "School subject")  // i18n:ignore translator comment
        case .history:        return String(localized: "History & Geography", comment: "School subject")  // i18n:ignore translator comment
        case .languages:      return String(localized: "Foreign Languages", comment: "School subject")  // i18n:ignore translator comment
        }
    }
}


// MARK: - Requests from other sections
// Add `extension Type { var displayName: String { … } } // wanted by <section>` here; the owner takes it over.
