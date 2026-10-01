import Foundation

// Writes the English text of the job catalogue as a translation table, so the key list is derived from
// the catalogue itself and never hand-written. Run it through `Tools/i18n/dump-catalogue.sh`.
//
//   job.title.<id>          the job's own title            (Job.catalogueTitle)
//   job.base.<baseTitle>    the role without its seniority (Job.displayBaseTitle)
//   job.rung.<label>        the seniority word             (Job.displayRungLabel)
//   job.summary.<id>        what the job is                (Job.displaySummary)
//   job.ladder.<name>       a career ladder named in prose (Job.displayExperienceLadder)
//
// The output is `{"table": "Catalogue", "strings": {key: English}}`, sorted, one key per line.

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Catalogue-jobs.json"

var strings: [String: String] = [:]

func add(_ key: String, _ english: String) {
    if let existing = strings[key], existing != english {
        FileHandle.standardError.write(Data("conflict for \(key): \"\(existing)\" vs \"\(english)\"\n".utf8))
        exit(1)
    }
    strings[key] = english
}

// Every country builds the same jobs (only the money differs); read them all so a country-specific
// difference in the text would be caught rather than silently dropped.
var idsByCountry: [Set<String>] = []
for country in Country.allCases {
    let jobs = JobCatalog.allJobs(in: country)
    idsByCountry.append(Set(jobs.map(\.id)))
    for job in jobs {
        add("job.title.\(job.id)", job.id)
        add("job.base.\(job.baseTitle)", job.baseTitle)
        if !job.rungLabel.isEmpty { add("job.rung.\(job.rungLabel)", job.rungLabel) }
        add("job.summary.\(job.id)", job.summary)
        if let ladder = job.experienceLadder { add("job.ladder.\(ladder)", ladder) }
    }
}
if Set(idsByCountry.map { $0.sorted() }.map { $0.joined(separator: "|") }).count != 1 {
    FileHandle.standardError.write(Data("the countries do not all produce the same job ids\n".utf8))
    exit(1)
}

let document: [String: Any] = ["table": "Catalogue", "strings": strings]
let data = try JSONSerialization.data(withJSONObject: document,
                                      options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
try (data + Data("\n".utf8)).write(to: URL(fileURLWithPath: outPath))
print("wrote \(strings.count) strings to \(outPath)")
