# Localisation — status and what is left

The game is localised into **English, German, French, Italian, Japanese and Ukrainian** (Oct 2026). `README.md` explains how it works and how
to keep it that way; `CONVENTIONS.md` is the rule book for writing translatable code; each `translations/<lang>/GLOSSARY.md` is that
language's style guide. This file records what was done and what is *not*.

## Done

* **All user-visible text goes through the String Catalog**: ~1,970 `L("…")` keys (`Localizable.xcstrings`, with CLDR plural forms where a count changes
  the wording), 652 id-keyed catalogue entries — job titles, base titles, rungs, ladders, summaries (`Catalogue.xcstrings`), and the app name
  (`InfoPlist.xcstrings`), each in six languages. `python3 Tools/i18n/i18n.py audit` finds no unlocalized prose; CI runs `check`, `verify` and the
  leaderboard check on every pull request.
* **Ids never shown**: `displayName` / `catalogueTitle` / `displaySummary` for every id-valued enum and for jobs (`DisplayNames.swift`); awards have a
  stable `key` and a stored `title`; events carry their verb as an enum.
* **Formatting follows the language**: `Fmt` (numbers, percent, lists), `Country.money` (a no-break space before the sign; yen as 万/億 and "円" in
  Japanese, sign first for other currencies in Japanese), sentences joined with no space in Japanese, the country menu sorted by the localized name.
* **The advisor speaks the language**: its rule-based advice is catalog text; free-typed questions are tokenised per language (Japanese segmented) and
  matched against localized and English titles — a role named outright always beats a language-model guess; the on-device model is told to reply
  only in the game's language, and is offered only where `SystemLanguageModel.supportsLocale` says it can; `AdvisorGuard` reads numbers across scripts.
* **Translations**: written per language from a glossary (register, typography, gender policy, term table, job-title rules), reviewed by a second
  pass, adversarially verified, checked for terminology and job-title consistency across the whole corpus, then played on a device in every language
  (two passes) and polished.
* **Game Center**: one board per country (18), each named in all six languages — `Tools/GameCenter/leaderboards.py`.

## Not done / decisions for the product owner

1. **Native-speaker review.** Everything was produced and reviewed by the same family of model and tested on a simulator; a native reader per language
   will still find taste issues. Each GLOSSARY lists the choices worth confirming (§8/§9): address form (du/tu/ти/です・ます), Fame/Network/Boardroom
   terms, the gender-neutral policy, seniority words kept as English loan words, katakana long-vowel marks, "licence" words.
2. **Game Center boards are not created.** They must be made in App Store Connect — `Tools/GameCenter/leaderboards.py create --apply` does it with an
   App Store Connect API key (not run: no credentials here, and the script has not been exercised against the live API; its dry run prints every request).
3. **Ukrainian and Apple Intelligence.** Apple's on-device model probably does not support Ukrainian, so Ukrainian players get the advisor's standard
   (already translated) advice without free chat. Nothing to translate; revisit when the platform adds the language.
4. **The competition blurb "The Chopin, the Tchaikovsky"** is translated literally; consider a neutral example for the Ukrainian audience.
5. **Country content is still American in places** (licence names, school ages and tracks, the advisor's real-world facts) — a separate, pre-existing
   limitation noted in `Country.swift`; the translators kept those names and glossed them.
6. **Layout** was checked on an iPhone 17 only (popovers now scroll and size to the room they have; ventures wrap). A pass on iPhone SE, iPad and the
   500 pt macOS window with German and Ukrainian is still worth doing. Four-digit amounts are not grouped in Italian/Spanish/Polish (CLDR rule).
7. **Accessibility**: the 43 icon-only ⓘ buttons still have no accessibility labels (in any language).
8. **Status-log lines are stored as finished text**, so they do not re-localize if the language changes mid-game (the language changes only by restarting the app).
9. More languages: see "Adding a language" in `README.md` (Spanish, Brazilian Portuguese, Polish, Korean, Simplified Chinese, Turkish, Swedish and Hindi
   are the obvious next ones for the 18 countries on offer).
