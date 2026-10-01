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

extension ActivityKind { var displayName: String { rawValue } }
extension ActivityLevel { var displayName: String { rawValue } }
extension Competition.Discipline { var displayName: String { rawValue } }


// MARK: - Requests from other sections
// Add `extension Type { var displayName: String { … } } // wanted by <section>` here; the owner takes it over.
