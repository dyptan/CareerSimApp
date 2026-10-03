# Making text translatable — the rules

The game ships in **English, German, French, Italian, Japanese and Ukrainian**. Every word a player reads — chrome, hints,
status-log lines, advisor advice, job titles and summaries — must come out of the String Catalog. Translating happens later,
by language, from the keys your code produces; **your job is the code**: turn every user-visible string into a catalog key,
without changing what English players see (one deliberate exception: plural fixes such as "1 years" → "1 year").

## Tools (run from your checkout root; they work inside a git worktree)

| Command | What it does |
|---|---|
| `Tools/i18n/compile.sh` | Type-checks all of `Main/` for iOS in ~20 s. Prints errors, nothing on success. Run it after every file. |
| `python3 Tools/i18n/i18n.py extract` | Compiles with string extraction (~30 s); reports how many catalog keys the sources produce. |
| `python3 Tools/i18n/i18n.py audit Main/Views/JobView.swift …` | Lists string literals that look like user-visible English but are **not** in the catalog. Your goal is an empty list for your files. Run `extract` first if the sources changed. `--words` also lists single words. |
| `Tools/BalanceSim/run-tests.sh` | The 289 unit tests, headless (~30 s). Must stay green. They assert English text, which the headless build returns unchanged. |

You may not run Xcode (`xcodebuild` hangs in this sandbox) — `compile.sh` is your compiler.

## The patterns

**1. A literal becomes `L("…")`** (defined in `Main/Models/L10n.swift`). The compiler extracts the literal as the catalog key, with
interpolations as placeholders: `L("Your chance: \(Fmt.percent(p))")` is the key `Your chance: %@`.
* In SwiftUI, `Text("literal")`, `Label("…", …)`, `Button("…")`, `.navigationTitle("…")` are already localized — leave them.
  `Text(someString)` is **not** localized (it is verbatim): feed it an `L(...)` result, or use `Text(verbatim:)` when it is
  data (a number, a name from the catalogue).
* `String(localized: "…", comment: "…")` is the same thing with a note for the translator. **Add a `comment:`** whenever the English
  is short or ambiguous: a one-word button ("Present" — a verb), a noun that could be two ("Pilot"), a term of the game's own
  ("fame", "network", "tier"), anything where context decides the translation. Say where it appears.

**2. Whole sentences only.** Word order, agreement and punctuation differ between languages, so never build a sentence from
fragments (`L("You earn") + " " + amount`, `"\(a)" + (flag ? " and more" : "")`, `x.joined(...)` of clauses that carry grammar).
* An `if`/ternary that changes a *word* inside a sentence becomes two whole sentences, each its own `L(...)`.
* A hint made of optional lines is a `[String]` of whole lines (each an `L(...)`), joined with `"\n"` or `"\n\n"`.
* A long multi-paragraph hint is better as one `L(...)` per paragraph/bullet than one `L("""…""")` of 120 words: shorter keys
  are translated and reviewed more reliably. Keep bullets (`• `), emoji and `✓` inside the key.
* Placeholders in a translation may be reordered, so a key with **two or more placeholders is translated with positional
  specifiers** — you need do nothing, the translators do. But keep placeholders few and meaningful.

**3. Numbers.** Interpolate an `Int` (becomes `%lld`) or a **pre-formatted `String`** (becomes `%@`) — never a `Double`.
Use `Fmt.number(_:)`, `Fmt.percent(_:)` (0.734 → "73%"), `Fmt.signedPercent(_:)`, `Fmt.decimal(_:digits:)`, `player.money(_:)`,
`Fmt.list(_:_:)` ("a, b and c" / "a, b or c"). Replace `String(format: "%.1f", x)`, `"\(Int((p * 100).rounded()))%"`, hand-rolled
`joined(separator: ", ") + " and "` with them. (`AdvisorCoach.list`/`AdvisorPathway.percent`/`CareerAdvisor.percent` are
yours to turn into thin wrappers of `Fmt` or to replace — their owner decides.)

**4. Plurals.** Anything that varies with a count (`years`, `jobs`, `points`, `yr`/`yrs`, `1 year ago`) is one key with the count as
its **only `Int` placeholder**, and you declare its English forms in a file you own,
`Tools/i18n/translations/en/plurals-<area>.json`:

```json
{ "table": "Localizable",
  "strings": {
    "%lld years": { "one": "%lld year", "other": "%lld years" },
    "Moved up after %lld years in %@": { "one": "Moved up after %lld year in %@", "other": "Moved up after %lld years in %@" }
  } }
```
Write the code as `L("\(n) years")` — no `n == 1 ? "" : "s"`. The key is exactly what `extract` produces (check with
`python3 Tools/i18n/i18n.py extract`; it prints nothing about plurals, so copy the key from the source: `\(n)` → `%lld`, `\(s)` → `%@`).
Other numbers in a plural sentence must be pre-formatted `String`s (`%@`), so there is only one `%lld`. A count that is always ≥ 2
(or always shown as "N/M") needs no plural; a word that is the same in every number needs none. When in doubt, declare it.

**5. Articles and agreement.** No "a"/"an" in front of looked-up words (`CareerAdvisor.article(for:)`, the `article` helpers):
reword so none is needed ("Job: Software Engineer", "Next step: Senior Teacher") or give the whole sentence a form per case. Do not
lowercase/capitalise looked-up words (`.capitalized`, `.lowercased()` on a display name), do not pluralise by adding "s", do not
assume a noun's gender.

**6. Identity vs display.** Ids stay English forever — `Job.id`, `Job.baseTitle`, enum raw values, award titles used as keys, the
strings inside `Set<String>`s and dictionary keys. They are never shown. The player reads `…displayName` (enums) / `catalogueTitle`
(`Job`) etc.; see `Main/Models/DisplayNames.swift` for the contract and for which section is yours. A display name is looked up from
the catalog; an interpolated `\(x.rawValue)` in prose, a `Text(x.rawValue)`, a `.capitalized` is a bug. If you need a display name
for an id you do not own, **use the one in `DisplayNames.swift`**; if there is none, add a stub to its *Requests* section (pass-through
of the id) and use it.

**7. Catalogue structs** (events, competitions, side hustles, trainings … where a row has a separate `id` and display fields like
`name`, `blurb`): keep the init call sites (`name: "RSA Conference"`) unchanged and make the stored field a `LocalizedStringResource`
with a computed `String` of the same name, so no consumer changes:

```swift
struct CareerEvent: Identifiable {
    let id: String
    private let nameResource: LocalizedStringResource
    var name: String { String(localized: nameResource) }          // what the player reads
    var englishName: String { String(nameResource.key) }          // only if the code needs the English text
    init(id: String, name: LocalizedStringResource, …) { …; self.nameResource = name }
}
```
A literal passed to a `LocalizedStringResource` parameter is extracted at the call site, so the row literals need no edits. **Check
every use of such a field**: if it is compared, hashed, used as a dictionary/Set key or concatenated into an id, switch that use to the
`id` (or `englishName`). Interpolated names (`"\(sport) cup"`) are not literals: give them a format key (`L("\(sport) cup")`).

**8. Id-keyed catalogue text** (job titles and summaries — a job's English title *is* its id, so it cannot be a resource):
`L10n.catalogue("job.title.\(id)", english: id)` looks up the `Catalogue` string table. Whoever owns the jobs creates the key lists.

**9. Things that are *not* displayed need no change:** ids, log lines (`print`), SF Symbol names, asset names, `Codable` keys, test
fixtures. Mark an intentionally untouched literal that the audit would flag with `// i18n:ignore` and a few words on the same line.

## Don't

* Edit `Main/Resources/*.xcstrings`, `CareersApp.xcodeproj`, `Main/Models/L10n.swift`, or files outside your area. If you need a change there, say so in your report.
* Add new `.swift` files (the Xcode project lists files explicitly). Put new helpers in a file you own.
* Change game logic, balance, ids, or anything English players see — beyond plural fixes and the "a/an" rewording the rules above call for.
* Translate. Leave translation to the per-language pass; a good `comment:` helps it more than a guess.
* Leave a half-converted sentence: a sentence is either wholly an `L(...)` or untouched.

## When you finish

`Tools/i18n/compile.sh` clean · `Tools/BalanceSim/run-tests.sh` green · `python3 Tools/i18n/i18n.py audit <your files>` empty (or each remaining
hit marked `// i18n:ignore`) · commit on your branch with a clear message. Report: files changed; the new display-name / helper APIs others
should use; every plural key you declared; places you were unsure about; anything you changed in behaviour.
