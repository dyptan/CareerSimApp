# Localisation plan

From a six-way audit of the app (views, advisor, game text, catalogues, formatting and grammar, project tooling), September 2026.
Counts come from a Swift-aware lexer plus grep and are exact to within a few lines. **Nothing below is converted yet** except the
groundwork in `README.md`.

## The size of the job

| Area | What is there | What blocks translation |
|---|---|---|
| **Views** (23 files, ~4,900 lines) | 410 English literals, ~3,500 words | Only 127 (**~10% of the words**) sit where Xcode extracts them. 283 are `String`s built in code: 43 `InfoHint` call sites (86 arguments), 9 sheet titles, 53 hint / message builders. ~458 source lines in 22 files need a change; the heaviest are `SkillsView` (121), `JobView` (88), `RootView` (43), `InstitutionTiersView` (41). |
| **Advisor** (7 files) | 631 string literals; 433 prose (~4,980 words); 12 curated notes, 33 points, 113 strings × 5 languages | Everything is a plain `String` drawn with `Text(String)`, so a catalog extracts none of it. 505 source lines block translation. |
| **Catalogues** | 994 distinct strings (~6,450 words): 225 job titles + 225 summaries, 78 trainings, 174 competition strings, 60 side-hustle, 46 event, 30 skill, 63 sector / field | A job's English title *is* its identity (`Job.id`), keyed by 13 dictionaries (316 entries), by `Country.swift` (334 pay pairs) and by ~390 literal occurrences elsewhere. |
| **Formatting and grammar** | 305 source lines | 62 plural sites (42 with no plural handling at all), ~64 sentences assembled from fragments, 7 English `a`/`an` helpers, 18 `.capitalized` / `.lowercased()` on text, 64 enum raw values interpolated into prose. |
| **Tooling** | clean slate | Done in the groundwork: catalog, languages, extraction flag, refresh script. |

The corpus is roughly **15,000 English words** (views ~3,500, advisor ~5,000, catalogues ~6,500) — about 75,000 words to translate into five
languages. That is a real translation project, not a switch to flip.

## Principles

1. **Identity never changes; display is looked up.** Keep the English titles as ids (`Job.id`, `baseTitle`, award titles, enum raw values,
   the `Set<String>` ids of selected activities). Add a display name beside them. Translating a title in place would silently drop a role to
   its category defaults — nothing fails to compile. Nothing is saved to disk today, so there is no data migration.
2. **Whole sentences, not fragments.** A partly wrapped sentence gives half-translated output. Build each sentence from one key with
   arguments; append independent sentences with a locale separator.
3. **English output stays byte-identical** while converting. `String(localized:)` returns its default text, and the headless tools
   (`Tools/BalanceSim`, `run-tests.sh`) compile the model layer without a catalog, so they keep passing as long as the default equals today's text.
4. **Keys.** Short chrome (buttons, titles, labels): English text as the key, extracted for free. Long or dynamic prose and anything shared
   between meanings (15 English strings are shared by different catalogues: Science ×4, Business, Pilot, …): explicit namespaced keys with
   `defaultValue:` and a translator `comment:`.

## Order

0. **Groundwork** — done (this change).
1. **Formatting helpers** (~15 definitions, high leverage): one `Fmt` namespace for percent (73 lines, three formats), decimals (3 locale-blind
   `String(format:)`), money (`Country.money`: symbol position, no-break space), list joining (`AdvisorCoach.list`, 27 call sites) and plural counts.
   Decide the Oxford comma and which locale reads the numbers (the device) versus which supplies the currency (the country).
2. **Plurals** (62 sites). One / other catalog variations; Ukrainian needs one / few / many / other, French and Italian one / many / other,
   Japanese only other. Fixes a live English bug on the way: `"1 years of experience"` is reachable (a job with `minYearsExperience == 1`).
3. **Sentence assembly and grammar** (~100 lines, by hand). Delete `article(for:)` (it is already wrong in English: *"a Abitur"*) and the
   title-plus-"s" pluralisation by rewording; give country names, adjectives and school-leaving names catalog values.
4. **Display names for identity-valued enums**: `TertiaryProfile`, `JobCategory`, `Industry`, `IndustryClimate`, `Training`, `Sport`, `ActivityKind`,
   `ActivityLevel`; a stable id on `FameAward` before its titles are localised. Replace `.capitalized` / `.lowercased()` and the interpolated raw values.
5. **Catalogues** — generate tables keyed by id from the Swift rows with a small script so they cannot drift (`job.title.<id>`, `job.summary.<id>`),
   resolved with `Bundle.main.localizedString(forKey:value:table:)` (English as the value). Struct-literal catalogues (competitions, side hustles, events,
   executive decisions, skills): retype the display fields to `LocalizedStringResource`; the ~118 row literals do not change.
6. **View API**: `InfoHint`, `GameSheet`, `TakeButton`, `Tip`, `RequirementRow`, `CategoryRow` take `String`; give them `LocalizedStringResource` /
   `LocalizedStringKey` overloads (~15 sites, mechanical). Add a `ScrollView` to the popover.
7. **Hand-convert the prose builders** file by file in the order players see them — Root / Header / Footer / Retirement / Coach / alerts first, then
   Jobs and Education, then the long hints. `JobView` and `SkillsView` last, in separate changes.
8. **The advisor's language layer** (below).
9. Accessibility labels (one in the whole UI today; 43 icon-only `InfoHint` buttons have none), then translation, then a layout pass on iPhone SE,
   the fixed 500 pt macOS window and the longest German and Ukrainian strings.

Each step is its own change; land helpers first and convert per file to keep merge conflicts small.

## The advisor needs its own work

* **Free-typed questions are English-only.** The search uses a 38-word English filler list, a tokenizer that cannot segment Japanese, a 4-character
  prefix stemmer that fails on CJK words and German compounds, and matches only four English fields. Someone typing their own word for "nurse" finds
  nothing, and this is the only free-text path when no on-device model is available.
* **The number guard** (`AdvisorGuard.numbers`) reads European digit grouping, but it wrongly rejects CJK numerals (`680万円`, `一番大切`),
  full-width digits (`１２％`) and vulgar fractions, collides `12.5` with `125`, and cannot see spelled-out numbers. Japanese replies would often
  fall back to plain text. Replace it with a parse that reads numbers as numbers.
* **The model**: the persona and instructions are English and name no reply language. `isAvailable` ignores locale support, and Ukrainian is, to our
  knowledge, not an Apple Intelligence language — check `SystemLanguageModel.supportedLanguages` and treat the plain-text path as first-class for `uk`.
* **Curated real-world notes** are data, not code: 33 points × several tellings (adult, beginner, tutorial) × country-specific tails. Move them to an
  id-keyed table, not inline strings.

## Risks

* **Nothing guards the English output.** The 53 hint builders are private `View` members; the tests reference views almost not at all. 114 string
  assertions in the tests cover advisor models, not views. Before rewriting a screen's text, extract the builders into pure types and snapshot the
  current English as a golden test.
* **Tests that assert English** (and ~210 literal job titles in tests) break if source text changes. Pin the test language to English in the scheme
  (Edit Scheme → Test → Options → App Language) when translations land; running tests on a non-English device would fail otherwise.
* Switching a `String` to `LocalizedStringKey` starts Markdown parsing — audit those strings. A lone `%` beside `%lld` needs `%%` in the catalog.
* `String(localized:)` in a `static let` freezes at first read, and ignores SwiftUI's `\.locale` environment; use launch arguments for previews.
* Game Center leaderboard names live in App Store Connect, outside the code: 18 boards × the languages.
* **Which languages?** The project is set up for `de fr it ja uk` (the five the audit planned for). The 18 countries now offered suggest more —
  `es`, `pt-BR`, `pl`, `ko`, `zh-Hans`, `tr`, `sv` — and `hi` for India. That is a product decision; each is one line in `knownRegions`.
