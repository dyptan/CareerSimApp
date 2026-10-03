# Localisation

CareerSimApp ships in **English, German, French, Italian, Japanese and Ukrainian**. The game follows the device language
(Settings ▸ General ▸ Language & Region on iOS, per-app language on macOS); numbers, lists and money follow it
(`Fmt`, `Country.money`), and **the advisor speaks it** too (see below). Anything else falls back to English.

## How text gets from the code to the screen

| Piece | What it is |
|---|---|
| `L("…")`, `String(localized:)`, SwiftUI `Text("…")` | Every user-visible English literal. The compiler extracts it as a **key** (interpolations become `%@` / `%lld`). Defined in `Main/Models/L10n.swift`. |
| `Main/Resources/Localizable.xcstrings` | The String Catalog: ~1,970 keys × 6 languages (plural variants where a count changes the wording). |
| `Main/Resources/Catalogue.xcstrings` | Strings known by an English *id*: job titles, base titles, rungs, ladders and summaries (`job.title.<id>`, `job.summary.<id>`, …), looked up by `L10n.catalogue`. |
| `Main/Resources/InfoPlist.xcstrings` | The app's display name. |
| `Main/Models/DisplayNames.swift` | `displayName` for the game's id-valued enums (`JobCategory`, `Industry`, `Training`, `Sport` …) and the `Job` text accessors. **Ids never change; the player reads display names.** Never show `rawValue` / `Job.id`; never `.capitalized` / `.lowercased()` a display name. |
| `L10n` / `Fmt` (`Main/Models/L10n.swift`) | The game's language and locale; `Fmt.number/percent/signedPercent/decimal/list`. English output of `Fmt` is byte-identical to the pre-localisation game. |
| `Tools/i18n/translations/<lang>/*.json` | The translations, one folder per language, any number of files. `translations/en/` declares plural variants (English forms) and the English text of the Catalogue. These JSON files are the **source of truth for translations**; `i18n.py apply` writes them into the catalogs. |
| `Tools/i18n/translations/<lang>/GLOSSARY.md` | Register, typography, gender policy, term table and job-title rules for that language. Read it before touching that language. |

Rules for writing translatable code are in `CONVENTIONS.md` (whole sentences, `Int`/pre-formatted `String` placeholders, plurals with one `%lld`, no "a/an",
ids vs display). `TRANSLATING.md` is the brief given to translators.

## Everyday commands

```
Tools/i18n/compile.sh                        # type-check the app headlessly (~20 s); no Xcode, no actool
python3 Tools/i18n/i18n.py extract           # compile with string extraction (~30 s)
python3 Tools/i18n/i18n.py audit [files]     # English literals that are not localized (should print nothing)
python3 Tools/i18n/i18n.py build             # extract + sync Localizable.xcstrings + apply the translations
python3 Tools/i18n/i18n.py verify            # CI check: every live catalog string has all five translations, placeholders/plurals right
python3 Tools/i18n/i18n.py check [-v]        # validate translations/*.json; with -v list keys a language still lacks
python3 Tools/i18n/i18n.py chunks LANG NL NC DIR   # work files for what LANG still lacks (see "Adding or changing text")
python3 Tools/i18n/i18n.py lint FILE… [--chunk WORK.json]   # validate a translator's output
python3 Tools/i18n/i18n.py pairs FILE…       # English beside translation, for review
Tools/i18n/dump-catalogue.sh                 # regenerate translations/en/Catalogue-jobs.json after changing jobs
Tools/BalanceSim/run-tests.sh                # unit tests, headless (English; the scheme pins tests to English too)
```

## Adding or changing text

1. Write the English in code per `CONVENTIONS.md` (`L("…")`). If a count changes the wording, add the English forms to a `translations/en/plurals-*.json`.
2. `python3 Tools/i18n/i18n.py extract`, then `python3 Tools/i18n/i18n.py check -v` lists the keys each language lacks (and any translation whose key
   no longer exists — delete those entries).
3. Translate: `python3 Tools/i18n/i18n.py chunks de 1 0 /tmp/work` (and `fr it ja uk`) writes work files for the missing keys; fill them following
   `TRANSLATING.md` and the glossary; save as `translations/<lang>/Localizable-NN.json` (strip `_context`); `lint … --chunk` each.
4. `python3 Tools/i18n/i18n.py build` and `verify`. CI runs `check`, `verify` and the leaderboard check on every pull request.

Changing the wording of an *existing* English key makes it a new key: the old translations are then orphaned — remove them from the JSON and translate
the new key. Job titles and summaries live in `translations/<lang>/Catalogue-*.json`; ids come from `translations/en/Catalogue-jobs.json`.

## Adding a language

`knownRegions` in the project, a case in `L10n.Language` (names, plural categories), a folder `translations/<code>/` with a glossary and the translations,
the language in `i18n.py` (`LANGS`, plural tables), the Game Center leaderboard names (`Tools/GameCenter/leaderboards.py`), the advisor's
language handling (`AdvisorLanguages`, `FoundationModelsLanguage`, the search stop-words in `AdvisorCoach`), and a pass over the layout.

## The advisor

* The rule-based advice (`AdvisorCoach`, `AdvisorPathway`, `AdvisorRealWorld`, `CareerAdvisor`) is built from catalog strings, so it speaks the game's language.
* Free-typed questions are read with a language-aware tokenizer (`NLTokenizer`; Japanese is segmented) and matched against the localized and the English
  titles, with per-language stop-words (`AdvisorCoach.search`, `AdvisorRoles`).
* With Apple Intelligence the on-device model phrases and answers: every prompt carries "Reply only in <language>", and the chat is offered only where
  `SystemLanguageModel.supportsLocale` says the language is supported — otherwise the advisor gives its standard advice, already localized, with a localized note.
* `AdvisorGuard` accepts a model reply only if every figure in it is one the coach supplied; it reads numbers across scripts (full-width digits, 万/億, European
  grouping, scale words, spelled-out numbers).

## Looking at the app in another language

```
xcrun simctl launch booted dev.dyptan.carrersim -AppleLanguages "(ja)" -AppleLocale ja_JP
xcrun simctl launch booted dev.dyptan.carrersim -NSDoubleLocalizedStrings YES      # pseudo: text that stays single is still hard-coded English
```

## Game Center

One leaderboard per country (`Country.leaderboardID`, 18 boards), each with a name and score suffix in all six languages.
`Tools/GameCenter/leaderboards.py` holds the table, checks it against `Country.swift`, and creates the boards through the App Store Connect API
(`create --apply`, with an API key in the environment — see the script's docstring). Boards are created as drafts and ship with the next app version.

## Gotchas

* `xcstringstool sync` matches the `.stringsdata` table to the catalog *file name*: keep `Localizable.xcstrings` named so.
* A bare `%` in a key with no placeholders ("30% a year") is fine as written; with placeholders it must be `%%`.
* `String(localized:)` in a `static let` is resolved once; compute display text in a `var`.
* Unit tests assert English: the scheme's test action launches with `-AppleLanguages (en)`; the headless build has no catalog and returns the English default.
* The shared session scratchpad is shared between parallel agents — use a private sub-folder.
