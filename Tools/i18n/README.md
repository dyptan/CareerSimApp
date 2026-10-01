# Localisation tooling

The app is English-only today. This folder is the groundwork for translating it; `PLAN.md` says what is left and in what order.

## What is set up

* **`Main/Resources/Localizable.xcstrings`** — the String Catalog, source language English, in the app target's Resources.
  Seeded with the strings Xcode extracts from the code unchanged: literal `Text("…")`, `Label`, `Button`, `Section`,
  `navigationTitle`, … (134 entries; the 12 that hold only placeholders, emoji or a symbol are marked *Don't Translate*).
  Nothing is translated yet, so the app behaves exactly as before.
* **Target languages** in the project: `de fr it ja uk` (`knownRegions`). One line each to add or remove one. An entry in the catalog
  only becomes a shipped language once it has translations.
* **`SWIFT_EMIT_LOC_STRINGS = YES`** on the app target, so the compiler extracts strings from `String(localized:)` and every SwiftUI
  call, not just `Text`; **`LOCALIZATION_PREFERS_STRING_CATALOGS = YES`** at project level.
* **`refresh-catalog.sh`** — brings the catalog up to date from the Swift sources without the IDE (see below).

## Refreshing the catalog

Xcode syncs the catalog itself on every build. `xcodebuild` does not, so after adding or changing user-facing strings from the command line:

```
Tools/i18n/refresh-catalog.sh
git diff Main/Resources/Localizable.xcstrings
```

The script builds into a fresh `build/i18n-dd` (a partial build makes `sync` mark live strings stale), then runs
`xcrun xcstringstool sync` over the app target's `.stringsdata` files. With `I18N_SKIP_BUILD=1 I18N_DERIVED_DATA=<dd>` it syncs from a
build you already have. Its sync half is tested: re-running it changes nothing. Its `xcodebuild` line could not be run where this was
written (a sandbox in which `xcodebuild` hangs at the asset compiler); the same build was made through another tool.

The catalog is a single JSON file, so parallel branches will conflict on it. Rebase and re-run the script rather than merging by hand.

`sync` matches the `.stringsdata` table name (`Localizable`) to the catalog's **file name**. Keep the file called `Localizable.xcstrings`:
syncing a copy under another name finds no strings and deletes every entry that has no translation yet. A *Don't Translate* mark and
any translation survive a sync, and a second sync changes nothing.

## Looking at the app in another language

Without translations, use Xcode's pseudo-languages: Edit Scheme → Run → Options → App Language → *Accented*, *Bounded String*,
*Double-Length* or *Right-to-Left*. They show which text is not localised (it stays plain English), how long text breaks layouts,
and how mirroring behaves. From the command line:

```
xcrun simctl launch booted dev.dyptan.carrersim -NSDoubleLocalizedStrings YES
xcrun simctl launch booted dev.dyptan.carrersim -NSForceRightToLeftWritingDirection YES -NSForceRightToLeftLocalizedStrings YES
xcrun simctl launch booted dev.dyptan.carrersim -NSShowNonLocalizedStrings YES      # logs lookups that miss
xcrun simctl launch booted dev.dyptan.carrersim -AppleLanguages "(de)" -AppleLocale de_DE
```

`-NSDoubleLocalizedStrings` is the quickest map of what is done: only text that goes through the catalog doubles ("Career Sim Career Sim").
Anything that stays single is still hard-coded English. On the opening screen that is the mode names and descriptions and the country
name. The flag also garbles placeholders ("Age lld Age 7", "@ @"); that is the flag, not a bug in the catalog.
The right-to-left flags give the same map (catalog text comes out reversed, "miS reeraC") and mirror the layout; the opening screen
mirrors cleanly.

## Exporting for translators

After adding the languages in the project:

```
xcodebuild -exportLocalizations -project CareersApp.xcodeproj -localizationPath build/loc \
  -exportLanguage de -exportLanguage fr -exportLanguage it -exportLanguage ja -exportLanguage uk
xcodebuild -importLocalizations -project CareersApp.xcodeproj -localizationPath <file>.xcloc
```

These two commands are from Apple's documentation and were not run here.

## Two things to know about the catalog

* The 134 seeded entries are the *easy* ones. Most of the app's text is built in code as a `String` and shown verbatim, so it is not
  in the catalog and will not be until it is converted — about 90% of the view text, by the audit. See `PLAN.md`.
* A few entries are bare format strings (`%@`, `%@ %@`) or emoji: views that show only interpolated values. There is nothing to
  translate, so they are marked *Don't Translate*; use `Text(verbatim:)` there when touching those views and delete the stale entry.
  Entries with a `%%` or a `:` stay translatable on purpose: French and German space those differently ("12 %", "Nom : valeur").
