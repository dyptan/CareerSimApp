# Translating a work file

You translate one **work file** (`Tools/i18n/work/chunks/<lang>/<lang>-<Table>-NN.json`) of CareerSimApp, a career-simulation game
for ages ~7 to adult, into one language: `de`, `fr`, `it`, `ja` or `uk`. Other translators do the other files and languages at the
same time, so consistency comes from the shared **GLOSSARY** — read `Tools/i18n/translations/<lang>/GLOSSARY.md` completely first and
follow it to the letter (register, typography, gender policy, term table, job-title rules, plural and declension rules).

## The work file

```json
{ "table": "Localizable",
  "strings": { "Your chance: %@": "", "%lld years": {"one": "", "other": ""}, … },
  "_context": { "Your chance: %@": {"where": "JobView.swift:118", "comment": "…"}, "%lld years": {"english": {"one": "%lld year", "other": "%lld years"}, …} } }
```

* **Key** = the English source text. Translate it; the key must be copied **exactly** into your output (it is the lookup id).
* Empty-string value → give a string. Object value (`one`/`other`/…) → a plural: give every category listed, in your language's forms;
  `_context.<key>.english` shows the English forms. A plural branch may leave out the number (`un anno`) but keeps every other placeholder.
* `_context.where` says which source file and line produced the string — open `Main/…/<file>` at that line when the meaning is not clear
  (what is on screen, who is speaking, whether a word is a verb or a noun). `_context.comment` is the developer's note to you.
* For table `Catalogue` the keys are ids like `job.title.Senior Teacher`, `job.base.Teacher`, `job.rung.Senior`, `job.ladder.Teacher`,
  `job.summary.Cashier`, and `_context.<key>.english` is the text to translate. Follow the glossary's job-title rules so
  `job.title.X`, `job.base.X`, `job.rung.X` and `job.ladder.X` agree with each other.

## Rules for every string

1. **Placeholders**: `%@` (text: a number already formatted, a name, a title) and `%lld` (an integer) must all appear, exactly once each,
   unchanged. A literal percent sign is written `%%` in the key and in your text. **Two or more placeholders → use positional specifiers
   in your translation**: `%1$@`, `%2$lld`, numbered by their order in the *English key*, so you may reorder them freely.
2. **Whole sentence, natural language.** Translate meaning, not words. Do not mirror English word order or its idioms. Names inside
   `%@` are in their *dictionary form* (nominative) — build the sentence around that (glossary has the patterns for languages with cases).
3. Keep **emoji, bullets (`•`), line breaks (`\n`), `✓`, `…`, `→`, `×`, `+`/`−` signs** where they are. Keep the same number of paragraphs/lines.
4. **Length matters**: buttons and labels are short. If the English is 1–3 words, so is yours.
5. **Do not leave English** except proper names, brand names and acronyms the glossary keeps (e.g. CEO, GPA). A translation identical to
   the English is almost always a mistake.
6. Fixed strings that look like they need context: read the source line. Words with two meanings (Science, Education, Pilot, Present,
   Title, Field, Level) — the glossary lists which rendering to use where.
7. Do **not** edit the work file, any other translator's output, or any source code. If a source string is wrong or untranslatable, translate
   it as best you can and mention it in your final report.

## Output

Write your result as `Tools/i18n/translations/<lang>/<Table>-NN.json` (same `NN` as the work file; e.g. `translations/it/Localizable-03.json`):

```json
{ "table": "Localizable", "strings": { "<exact key>": "<translation>", "<plural key>": {"one": "…", "other": "…"} } }
```

No `_context`. Write it in several parts if you like (`Localizable-03a.json`, `Localizable-03b.json`…) — keep each part to ~150–250
keys so a mistake is cheap to fix; the tools merge every file in the folder. Output real UTF-8 (not `\u` escapes). Make sure the JSON is valid
(escape `"` and `\n`).

## Check your work

```
python3 Tools/i18n/i18n.py lint Tools/i18n/translations/<lang>/<your files…> --chunk Tools/i18n/work/chunks/<lang>/<work file>
```

It must report `0 problems`: every key present exactly once and spelled exactly, every placeholder and plural form right. Fix and re-run until clean.
Then reread ten of your own lines against the glossary (register, term choices, gender, typography) and fix drift.

Report in a few lines: the files you wrote, anything in the source you think is wrong, and glossary gaps (terms you had to decide yourself — with your choice).
