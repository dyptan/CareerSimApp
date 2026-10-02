# German (de) glossary and style guide

Binding for every German translator of CareerSimApp: 1,968 `Localizable` strings and 652 `Catalogue` entries (147 `job.base`, 225 `job.title`, 225 `job.summary`, 40 `job.ladder`, 15 `job.rung`).
If a term is listed here, use it exactly. If not, follow the rules and the closest listed term. Never create a second German word for a listed concept. Open questions go to the lead translator.
How to work and what to deliver: `Tools/i18n/TRANSLATING.md`; before handing in a chunk run `python3 Tools/i18n/i18n.py lint <your files> --chunk <work file>` until it reports 0 problems. Key and placeholder conventions: `Tools/i18n/CONVENTIONS.md`.

* Keys that are already German or another language (`Abitur`, `Grundschule`, `Université`, `Baccalauréat`, `İlkokul`, `Szkoła podstawowa` …), proper names and acronyms (5.2, 5.7) are translated **unchanged**: copy the key as its own value (this overrides the general "identical to English is a mistake" rule). Every key needs a value.
* Two keys are identifiers, not text: `activity.science` -> `Naturwissenschaften` (school subject), `field.education` -> `Pädagogik` (degree field).
* `_context.comment` names the exact meaning (verb vs noun, who speaks, what the argument is). Read it for every short string.
* In this file `<nb>` stands for a NO-BREAK SPACE (U+00A0); the real character is used in the examples.

## 1. Voice and register

* **Reader**: a child of 7 up to an adult. The game talks to the player directly and the advisor is a friendly coach. Tone: warm, clear, encouraging, never babyish, never corporate. Adult "real-world" notes may be a little more factual, but are still in the du-form.
* **Address: informal du-form, always.** Lowercase `du, dich, dir, dein, deine`. Never `Sie`, never `man`-sentences, never `wir`. Hints and instructions use the du-imperative (`Tippe auf ⓘ`, `Wähle …`, `Versuch es nächstes Jahr noch einmal`). The advisor speaks as `ich` (`Ich schlage dir Jobs vor`). Write `Tippe` (touch), never `Klicke`.
* **Buttons, tab labels, titles, chips**: noun or infinitive, no du-imperative, no full stop (`Bewerben`, `Überspringen`, `Neu anfangen`, `Gehaltswunsch nennen`). Card titles that tell the player what to do may use the imperative (`Hol dir den Posten`), as the English does.
* **Sentences**: short (about 20 words at most), present tense, active voice, ordinary words. No Amtsdeutsch, no Genitiv chains, no Konjunktiv beyond `könntest`/`würdest` for a real "could". The child/beginner versions of a fact ("the same fact in a beginner's or child's words") use very simple words, short sentences and no loan words beyond this glossary.
* **Quick-reply chips** in the advisor chat are the *player* speaking: `ich`, `mein`, `meine` (`🎯 Ich habe eine Position im Kopf`, `🤔 Ich weiß es noch nicht`).
* Keep the English energy: where the source has `!`, `…`, a rhetorical question or a joke, keep it; do not add any.
* **Never change**: emoji, bullets `•`, `✓`, `ⓘ`, `·`, `×`, `÷`, `≈`, `~`, `→`, `←`, `+`/`−` signs, `\n` line breaks, the order of bullet lines, and the position of emoji in the line.
* **Length**: German runs 25–35 % longer than English. Buttons, footer labels, header buttons, chips and table headings: aim for 12 characters or fewer and never more than about 16 (`Aktivitäten` 11, `Überspringen` 12). Prefer the short glossary form (`Beratung`, `Punkte`, `Events`). A compound longer than 22 characters in a label: reword or hyphenate.
* **Brand and product names stay**: Career Sim, Game Center, Apple Intelligence, Ivy League, Oxbridge, Russell Group, Group of Eight, U15, IIT/IIM/AIIMS, UNAM, HECS-HELP, NHS, FAA, USMLE, NCLEX-PN, PharmD, MBA, PhD, PMO, SMIC, ENEM, gaokao, CSAT, ATAR, GPA, A-levels, BTEC, TAFE.
* When a string quotes another label of the app ("turn off "Only roles I qualify for"", "tap Score", "the blue Skip button"), use **exactly** the German of that label (5.9).

## 2. Typography and numbers

| Topic | Rule |
|---|---|
| Quotation marks | `„…“` always (also for the English `“…”` and `"…"`). Nested: `‚…‘`. Job titles, titles won and event names inside a sentence go in `„…“` when they cannot be declined (see 3.3). |
| Dashes | Source ` — ` becomes a spaced en dash ` – ` (never an em dash). Ranges are unspaced en dashes: `6–10`, `1–5 %`. Compounds: hyphen. Keep the minus sign `−`. |
| Ellipsis | One character `…`, attached to the previous word exactly as in English (`Ich denke nach…`). |
| Apostrophe | `’` only where unavoidable (`Los geht’s!`). No apostrophe before genitive-s. |
| Numbers inside the English text | Convert to German: decimal comma, thousands point, symbol after the number with NBSP: `€13.90` -> `13,90 €`; `£9,790` -> `9.790 £`; `C$18.15` -> `18,15 C$`; `¥1,121` -> `1.121 ¥`; `4,806 zł` -> `4.806 zł`; `1,500 hours` -> `1.500 Stunden`. `an hour/a month/a day/a year` -> `pro Stunde/Monat/Tag/Jahr`. |
| Pre-formatted `%@` numbers | Arrive ready (`73 %`, `45.000 €`, `+20 %`). Never add or remove symbols or spaces around them: `Deine Chance: %@`, not `%@ %`. |
| Literal percent in a key | Written `%%` in the key. Translate `40%%` as `40 %%` (NBSP before the sign), matching what `Fmt.percent` produces. |
| Units | NBSP between number and unit/abbreviation: `5 km`, `z. B.`, `ca. 3`. Imperial -> metric: `26.2 miles` -> `42,2 km`; `5K` -> `5-km-Lauf`. |
| Lists | Joined by the app (`A, B und C`, `A, B oder C`). Never add a comma before `und`/`oder`. |
| Capitalisation | All nouns capitalised; adjectives and verbs lowercase. Labels and buttons: first letter only (`Gehalt nennen`). No English Title Case. After a colon capitalise only if a full sentence follows. |
| Compounds | Closed (`Karriereleiter`, `Lebenshaltungskosten`). Hyphen with abbreviations, digits, English words and to keep long compounds readable: `IT-Support`, `3D-Künstler`, `Bachelor-Abschluss`, `Social-Media-Manager`, `E-Sport`, `Start-up`, `Lkw-Fahrer`, `Kfz-Mechaniker`, `5-km-Lauf`. Spelling: current German orthography (ß as in `Fußball`), Germany standard. |
| Abbreviations | `yr`/`yrs`/`y.o.` -> `J.` with NBSP (`5 J.`); write `Jahr/Jahre` in running text and wherever there is room. `exp.` -> `Erf.`; `e.g.` -> `z. B.`; `etc.` -> `usw.`; `approx.` -> `ca.`; `vs` -> `vs.`. Keep CEO, CTO, CMO, IT, MBA, PhD, GPA, EQR (= EQF), PMO. `HR` -> `Personalwesen`. `Ages 7+` -> `Ab 7 Jahren`. |
| Countries | `In the US` -> `In den USA`; the country picker uses the full names in 5.8. |

## 3. Placeholders, plurals, grammar traps

### 3.1 Placeholders
* Keep `%@`, `%lld`, `%%` exactly; no spaces inside, nothing translated. Every placeholder of the key appears exactly once, except the one permitted case in 3.2 (the count in a plural branch).
* **Two or more placeholders -> positional specifiers in every translation, even if the order is unchanged**: `%1$@ … %2$lld …`. Index = position in the English key; type must match (`%1$@` for a `%@`, `%2$lld` for a `%lld`). Never mix positional and plain in one string.
* `%@` can be a pre-formatted number, percent or money, a job title, a field, a skill, an activity, an event or country name, a school term, an `A, B und C` list, or a whole noun phrase (`einen Bachelor-Abschluss in Wirtschaft`). The `_context` comment says which.

### 3.2 Plurals (German: `one`, `other`)
* Plural entries are objects `{ "one": "…", "other": "…" }`, nothing else. CLDR `one` = exactly 1; **0 and every other number use `other`** (`0 Jahre`, `2 Jahre`). Each branch is a full, correct sentence (noun, verb and case agree in that branch).
* The count is the only `%lld`. Keep it as digits (`1 Jahr`). **In the `one` branch you may drop the count** when German reads better with `ein/einem/einer` (`in einem Jahr`, `mit einem Jahr Erfahrung`). Only the count may be dropped, and only in a plural branch; every other placeholder stays. In every non-plural string all placeholders stay.
* Abbreviation keys (`%lld yr`/`%lld yrs`) get the same abbreviation in both branches (`%lld J.`).
* Mind the case after prepositions: `nach 1 Jahr` / `nach %lld Jahren` (dative plural), `%lld Jahre` as subject/object.

### 3.3 Never decline or article-ise a looked-up word
The app inserts job titles, field names, skill names, event names, school terms and qualification phrases it looks up; gender and case are unknown. So:

| English pattern | German pattern |
|---|---|
| `as %@`, `working as %@` | `als %@` (bare, nominative) |
| `the %@ job` | `der Job als %@` or `Job: %@`; `Apply for the %@ job` -> `Bewirb dich als %@` |
| `the %@ ladder` | `die Karriereleiter „%@“` |
| `in %@` (field, ladder) | `in %@` with no article (`Ruhm in Wirtschaft`, `Netzwerk in Technologie`) |
| `%@ fame`, `%@ skill` | `Ruhm in %@`, `Fähigkeit: %@` – never `%@-Ruhm` (field names do not compound) |
| a title/award used as a name | `„%@“`, e.g. `der Titel „%@“` |
| adjective/article before `%@` | avoid; if unavoidable use a colon or `von %@` |

* Qualification phrases (`a bachelor's degree`, `a doctorate`, `… in %@`) are used after `Hol dir`, `Du brauchst`, `Du brauchst noch:`: **always the accusative with indefinite article**: `einen Schulabschluss`, `einen Berufs- oder Collegeabschluss`, `einen Bachelor-Abschluss`, `einen Master-Abschluss`, `eine Promotion`; with field `einen Bachelor-Abschluss in %@`. Write the surrounding sentence so that it takes the accusative (`Du brauchst noch: …`, not `Es fehlt …`).
* No `a/an`-style helper exists in German: keep the noun phrase, the app does not add articles.

## 4. Gender and inclusive wording (one policy)

* **"You" is never gendered.** Rewrite any sentence that would need the player's gender (`Du arbeitest als Lehrer`, not `Du bist ein Lehrer`).
* **Occupations, roles and people-nouns: generic masculine** (`Lehrer`, `Ärzte`, `Sieger`, `Partner`), unless an established neutral word exists and reads naturally: `Servicekraft`, `Reinigungskraft`, `Housekeeping-Kraft`. These are listed in 6.1.
* **No** Doppelpunkt, Gendersternchen, Binnen-I or `Kellner/Kellnerin` pairs. Reasons: labels must stay short; the advisor matches typed German words (`Krankenpfleger`) to titles; screen readers; the least intrusive reading for a game for children.
* English slashes that name two different jobs stay a slash (`Übersetzer/Dolmetscher`); those that only pair genders or synonyms collapse to one word (6.1).

## 5. Glossary

### 5.1 Game concepts, money and work
| English | Deutsch | Note |
|---|---|---|
| Fame | Ruhm | The pillar. Adj. `berühmt`, `bekannt` for "well known". `Ruhm in %@`. `🌐 General` -> `🌐 Allgemein` |
| Network | Netzwerk | Professional contacts. "People you know" -> `Kontakte`. `+3 network` -> `+3 Netzwerk` |
| Skill(s) | Fähigkeit(en) | The 15 named abilities in 5.5. `skill points` -> `Fähigkeitspunkte`; fallback "Skill" -> `Fähigkeit` |
| Soft skills / Hard skills | Soft Skills / Fachqualifikationen | Rarely shown. "Soft-skill match" -> `Übereinstimmung der Fähigkeiten`; `%@ match` -> `%@ Übereinstimmung` |
| Credentials | Qualifikationen | Diplomas, degrees, certificates, licences |
| Score | Punktzahl | Header button and plural: `Punkte`. `Your score` -> `Deine Punktzahl` |
| Leaderboard | Bestenliste | Game Center term; `the Game Center leaderboard` -> `die Game-Center-Bestenliste` |
| Progress (button) | Fortschritt | Simplified mode |
| Goal | Ziel | `🎯 Goal: %@` -> `🎯 Ziel: %@` |
| Net worth | Nettovermögen | What you own minus what you owe |
| Savings | Ersparnisse | `💰 Savings: %@` -> `💰 Ersparnisse: %@` |
| Salary / pay (noun) | Gehalt | `pays %@ a year` -> `zahlt %@ pro Jahr`; general "pay" -> `Bezahlung` |
| Income / gross income / money earned | Einkommen / Bruttoeinkommen / Verdientes Geld | "before taxes and living costs" -> `vor Steuern und Lebenshaltungskosten` |
| Minimum wage | Mindestlohn | |
| Raise / merit raise | Gehaltserhöhung | |
| Living costs | Lebenshaltungskosten | "rent and food" -> `Miete und Essen` |
| Tuition / school costs | Studiengebühren / Bildungskosten | School fees below university: `Schulgeld` |
| Student loan / venture loan / loan | Studienkredit / Gründungskredit / Kredit | "owed" -> `offen` |
| Economy / bad economy / recession | Konjunktur / schwache Konjunktur / Rezession | "Declared downturn" -> `Ausgerufener Abschwung` |
| Industry / sector | Branche | "Employer's industry" -> `Branche des Arbeitgebers` |
| Employer / company / firm | Arbeitgeber / Unternehmen / Firma | A law firm is a `Kanzlei` |
| Job / role / occupation / career | Job / Position / Beruf / Karriere | "Jobs" button and screen stay `Jobs`; the Occupation panel is `Beruf` |
| Ladder / rung | Karriereleiter / Karrierestufe | "top rung" -> `oberste Stufe`; "seniority" -> `Dienstalter` |
| Posting / listing | Stellenanzeige / Stellenangebote | `Nobody is posting %@ jobs this year` -> `Dieses Jahr schreibt niemand Stellen als %@ aus`; `See job listings` -> `Stellenangebote ansehen` |
| Application / apply | Bewerbung / bewerben | Button `Bewerben`. "An application spends the year" -> `Eine Bewerbung kostet dich das ganze Jahr` |
| Hire(d) | einstellen / eingestellt | `Einstellungschance` for hiring odds |
| Offer | Angebot | `Offer accepted!` -> `Angebot angenommen!` |
| Ask (salary) | Gehaltswunsch | `Your ask:` -> `Dein Gehaltswunsch:`; `Ask for a salary` -> `Gehaltswunsch nennen` |
| Promotion / promoted | Beförderung / befördert | `Promoted to %@` -> `Befördert: %@` |
| Layoff / laid off / severance | Entlassung / entlassen / Abfindung | |
| Experience / work experience | Erfahrung / Berufserfahrung | `Years of experience` -> `Jahre Erfahrung`; abbr. `Erf.` |
| Requirement / hard requirement | Voraussetzung / feste Voraussetzung | |
| Chance / odds | Chance / Chancen | `a 40 % chance` -> `40 % Chance`; `Promotion odds` -> `Beförderungschancen` |
| Long shot / lottery | Außenseiterchance / Lotterie | |
| Lever | Stellschraube | `Your biggest lever` -> `Deine größte Stellschraube` |
| Seat (scarce top position) | Posten | `The seat` -> `Der Spitzenposten`; `seat chance` -> `Chance auf den Posten`; `C-suite seat` -> `C-Level-Posten`; `win the seat` -> `Hol dir den Posten` |
| Door / gate / door-opener | Tür / Hürde / Türöffner | |
| Narrow path | schmaler Pfad | |
| Track record (founder) | Erfolgsbilanz (Gründer-Erfolgsbilanz) | |
| Founder / found | Gründer / gründen | |
| Venture | Gründung | List and button `Ventures` -> `Gründungen`; the company you run -> `dein Unternehmen`; `Venture launched!` -> `Unternehmen gegründet!` |
| Project (side hustle) | Projekt | Projects earn fame and skills, not money. "Side hustle" is internal; if shown: `Nebenprojekt` |
| Boardroom | Chefetage | Sheet title and footer button |
| Executive decision | Führungsentscheidung | |
| Investment round / investor | Finanzierungsrunde / Investor | `Announce the round` -> `Runde starten` |
| Stake / share (ownership) | Anteil | `Sell Your Stake` -> `Anteil verkaufen`. The money you put in is the `Einsatz` |
| Exit / breakout / hit | Exit / Durchbruch / Hit | `Successful Exit` -> `Erfolgreicher Exit` |
| Contest / competition | Wettbewerb | |
| Championship / tournament / cup | Meisterschaft / Turnier / Pokal | |
| Title (won) | Titel | In `„…“` |
| Winner / champion / medalist / laureate | Sieger / Meister / Medaillengewinner / Preisträger | `Champion! 🏆` (alert) stays `Champion! 🏆` |
| Trophy / accolade / prize / ribbon | Trophäe / Auszeichnung / Preis / Urkunde | |
| Event | Event | Footer `Events`; do not use `Veranstaltung` |
| Summit / congress / symposium / forum | Summit / Kongress / Symposium / Forum | `Summit` is kept as the loan word |
| Expo / conference / convention | Messe / Konferenz / Tagung | `Expo` -> `Messe`; `Legal Bar Convention` -> `Anwaltstagung` |
| Pitch / pitch night / casting | Pitch / Pitch-Abend / Casting | |
| Advisor / advice | Berater / Beratung | Header button `Beratung`; "standard advice" -> `Standard-Tipps` |
| Simplified / Real Life | Vereinfacht / Echtes Leben | Prose: `im vereinfachten Modus`, `im Modus „Echtes Leben“` |
| Goal names | Ganz nach oben / Beste Punktzahl bis %lld | `Make it to the top` / `Best score by %lld` |
| Turn / year / age | Runde / Jahr / Alter | `One turn = one year` -> `Eine Runde = ein Jahr`; `Starting age` -> `Startalter` |
| Uses up your year | verbraucht dein Jahr | Use this wording every time |
| Retire / Retirement / Game Over / career over | in den Ruhestand gehen / Ruhestand / Spiel vorbei / Karriere beendet | `Retired from professional sport at %lld` -> `Mit %lld aus dem Profisport zurückgezogen` |
| Life stages | Kindheit / Teenagerjahre / Junges Erwachsenenalter / Berufsleben | Childhood / Teen Years / Young Adult / Working Life |
| Advisor "check-in" | Zwischenstand | `📅 Check-in · age %lld` -> `📅 Zwischenstand · Alter %lld` |

### 5.2 Education and school systems
| English | Deutsch | Note |
|---|---|---|
| Degree / diploma | Abschluss | Never `Diplom`. `school diploma` -> `Schulabschluss`; `college or vocational diploma` -> `Berufs- oder Collegeabschluss`; `Degrees` -> `Abschlüsse` |
| Bachelor / Master | Bachelor / Master | `Bachelor’s Degree` -> `Bachelor-Abschluss`; `Master’s Degree` -> `Master-Abschluss` |
| Doctorate / doctoral degree / PhD | Promotion / Doktorgrad / PhD | `a doctorate` -> `eine Promotion`; `Doctorate+` -> `Promotion+` |
| Official degree titles | unchanged | `Bachelor of Science`, `Master of Arts`, `Doctor of Medicine (MD)`, `Juris Doctor (JD)` stay. In `… in <subject>` keep the first part, translate the subject: `Bachelor of Arts in Law` -> `Bachelor of Arts in Recht`; `Master of Science in Kinesiology` -> `… in Kinesiologie` |
| Associate of Applied Science in %@ | unchanged + field | US title, `%@` arrives translated |
| Trade Certificate | Gesellenbrief | US name of a trade qualification |
| Vocational (Diploma) | beruflich / Berufsabschluss | `Vocational Diploma in %@` -> `Berufsabschluss in %@`. Local names (`Ausbildung in %@`) unchanged |
| Community College | Community College | US open-admission tier; keep |
| State University | Staatliche Universität | Mainstream tier |
| Elite school / Elite / Ivy League | Eliteuniversität / Elite / Ivy League | Ivy League stays |
| Tier | Kategorie | School tiers -> `Hochschulkategorien` |
| Admission | Zulassung | `Admission chance` -> `Zulassungschance`; `accepted you onto %@` -> `hat dich für %@ angenommen`; `You're in!` -> `Du bist drin!` |
| Grades / grade average | Noten / Notendurchschnitt | `GPA` stays; `NMT score` -> `NMT-Ergebnis`; `A-level grades` -> `A-Level-Noten` |
| Subject / school year | Fach / Schuljahr | |
| Field of study | Studienfach | A field of *work* or fame is a `Bereich` |
| Education (screen, work field, industry) | Bildung | Degree field: `Pädagogik` (key `field.education`) |
| Primary / Elementary School | Grundschule | Romanised brackets stay: `Grundschule (Shōgakkō)` |
| Middle / Secondary / Junior High School | Middle School / Sekundarschule / Junior High School | Established English names stay; romanisation stays |
| High School | Highschool | `High School Diploma` -> `Highschool-Abschluss` |
| College (generic) / University | Hochschule / Universität | In names keep `College`: `College-Abschluss` (College Diploma), `Junior College` |
| Foreign proper names | unchanged | A-levels, BTEC, TAFE, ATAR, ENEM, gaokao, CSAT, GPA, Matura, Atestat, IUT, BTS, ESO, FP, ITS, Oxbridge, Group of Eight … Translate only generic words: Diploma -> `Abschluss`, University -> `Universität`, Private -> `Privat…`, National -> `Staatliche/Nationale`, Top -> `Spitzen…` (`Top private university` -> `Top-Privatuniversität`, `Top university` -> `Spitzenuniversität`) |
| Gymnasium (lower school) | Gymnasium (Sekundarstufe I) | |
| Level (school stage) | Stufe | `school level` -> `Schulstufe` |
| EQF | EQR | Only in comments |
| Course / training / certificate | Kurs / Weiterbildung / Zertifikat | "Training" as the credential type, `Trainings:` -> `Weiterbildungen:` |
| Licence / license | Lizenz | 5.7 for the exceptions |
| Exam / programme | Prüfung / Programm | |
| Student (Occupation headline) | Schüler/Student | Covers school and university |
| Class representative / student body president / student council | Klassensprecher / Schülersprecher / Schülerrat | Official German school roles |

### 5.3 Fields, industries, work settings, climate
| English | Deutsch |
|---|---|
| Entertainment / Technology / Arts / Business / Science | Unterhaltung / Technologie / Kunst / Wirtschaft / Wissenschaft |
| Engineering / Show Business / Public Services / Health / Education | Ingenieurwesen / Showbusiness / Öffentlicher Dienst / Gesundheit / Bildung |
| Agriculture / Design / Law / Construction / Retail | Landwirtschaft / Design / Recht / Bauwesen / Einzelhandel |
| Hospitality / Personal Services / Manufacturing / Entrepreneurship | Gastgewerbe / Persönliche Dienste / Fertigung / Unternehmertum |
| Transportation / Administration / Sports / Service (field of study) | Transport / Verwaltung / Sport / Dienstleistung |
| Office / Field / People-facing (work setting) | Büro / Vor Ort / Mit Menschen |
| Kind of work / Any | Art der Arbeit / Alle |
| Software & Internet / Computing Hardware / Telecoms / Automotive | Software & Internet / Computerhardware / Telekommunikation / Automobilindustrie |
| Aerospace & Defence / Energy & Utilities / Banking & Finance | Luft- & Raumfahrt, Verteidigung / Energie & Versorgung / Banken & Finanzen |
| Healthcare / Pharma & Biotech / Government & Public Sector | Gesundheitswesen / Pharma & Biotechnologie / Staat & Öffentlicher Sektor |
| Retail & Consumer / Hospitality & Tourism / Media & Entertainment | Handel & Konsumgüter / Gastgewerbe & Tourismus / Medien & Unterhaltung |
| Construction & Property / Agriculture & Food / Transport & Logistics | Bau & Immobilien / Landwirtschaft & Ernährung / Transport & Logistik |
| Industrial Manufacturing / Professional Services | Industrielle Fertigung / Beratung & Dienstleistungen |
| Industry climate (heading) | Branchenlage |
| Climate labels: Booming / Growing / Steady / Slowing / Slump | Boomend / Wachsend / Stabil / Abflauend / Krise |
| Climate verbs: is booming / growing / steady / slowing / in a slump | boomt / wächst / ist stabil / flaut ab / steckt in der Krise |

### 5.4 Fame fields and ladders in prose
The field name stays bare after `in`: `Ruhm in Kunst`, `Jahre Arbeit in Gesundheit`, `Jahre Arbeit als Lehrer` (ladder = base title, 6.1).

### 5.5 The 15 abilities (soft skills)
Playful, job-like nouns, generic masculine, same word everywhere (also inside prose such as "💬 Persuader most of all").
| English | Deutsch | English | Deutsch | English | Deutsch |
|---|---|---|---|---|---|
| Inventor | Tüftler | Creator | Kreativkopf | Influencer | Kommunikator |
| Persuader | Überzeuger | Leader | Anführer | Visionary | Visionär |
| Detective | Detektiv | Fixer | Bastler | Navigator | Navigator |
| Athlete | Athlet | Zen | Zen | Empath | Empath |
| Teamplayer | Teamplayer | Planner | Planer | Champion | Durchhalter |

(The skill "Influencer" is `Kommunikator` because the German loan word means a social-media star; the skill "Champion" is `Durchhalter`, while "champion" as a title is `Meister`/`Champion`.)

### 5.6 Activities, subjects, contests
| English | Deutsch | English | Deutsch |
|---|---|---|---|
| Activities / Activity | Aktivitäten / Aktivität | Sports / Arts & Minds / Study (tabs) | Sport / Kunst & Köpfchen / Lernen |
| Beginner / Intermediate / Advanced / Expert | Anfänger / Fortgeschrittener / Könner / Experte | Contest kinds: Athletic / E-Sports / Creative / Mind / Academic | Sport / E-Sport / Kreativ / Denksport / Akademisch |
| Running / Swimming / Cycling | Laufen / Schwimmen / Radfahren | Soccer / Basketball / Tennis | Fußball / Basketball / Tennis |
| Martial Arts / Gymnastics | Kampfsport / Turnen | Skateboarding & BMX / E-Sports | Skateboard & BMX / E-Sport |
| Music / Drawing & Painting | Musik / Zeichnen & Malen | Photography / Cooking / Dance | Fotografie / Kochen / Tanzen |
| Coding / Chess / Debate | Programmieren / Schach / Debattieren | Student Council | Schülerrat |
| Mathematics / Science (subject) | Mathematik / Naturwissenschaften | Reading & Writing / History & Geography | Lesen & Schreiben / Geschichte & Erdkunde |
| Foreign Languages | Fremdsprachen | | |

Contest and event names: translate by pattern, one word order, no English left except proper names.
| Pattern | Deutsch |
|---|---|
| School / Kids' / Junior / Youth | Schul- / Kinder- / Junioren- / Jugend- (`School Chess Tournament` -> `Schul-Schachturnier`) |
| National / Regional / International / World | National(e) / Regional(e) / International(e) / Welt- |
| Winner / Champion / Medalist / Laureate / Star | …sieger / …meister (`Schachmeister`) / …medaillengewinner / …preisträger / …star |
| Young X of the Year | Junger X des Jahres |
| Bee / Bowl / Fair / Cup / Challenge | Wettbewerb (`Spelling Bee` -> `Buchstabierwettbewerb`) / Quiz / Wettbewerb (`Science Fair` -> `Wissenschaftswettbewerb`) / Pokal / Challenge |
| Math Kangaroo / Hackathon / Olympiad / Marathon | Känguru der Mathematik / Hackathon / Olympiade / Marathon |
| School Sports Day / Bake-Off / Cook-Off | Schulsportfest / Backwettbewerb / Kochwettbewerb |
| Event verbs (button / past / "at %@") | Präsentieren / Präsentiert / `Präsentieren bei %@`; Auftreten / Aufgetreten; Mitwirken (Appear on TV) / Mitgewirkt; Sprechen / Gesprochen; Antreten (Compete) / Angetreten; Vorführen (Demo) / Vorgeführt |
| Grandmaster | Großmeister |

### 5.7 Trainings, licences and certificates
Rule: US credentials keep their acronym (CNA, EMT, CPA, CDL, LPN, ATP, PE, NP, EPA 608, A&P); the long course names get the German expansion with the acronym in brackets. `License/Licence` -> `Lizenz`, except the universal ones below. `Journeyman` -> `Gesellen-`, `Board Exam` -> `Prüfung`, `School/Program/Course` -> `…schule/Programm/…kurs`.
| English | Deutsch | English | Deutsch |
|---|---|---|---|
| CNA | CNA (Pflegehelfer-Zertifikat) | LPN | LPN |
| Dental Assistant | Zahnarzthelfer | Nurse License | Pflege-Lizenz |
| Flight Attendant | Flugbegleiter | Nurse Practitioner | Nurse Practitioner |
| Teaching Certificate | Lehrbefähigung | Medical License | Ärztliche Approbation |
| Cosmetology Licence | Kosmetik-Lizenz | Dental License | Zahnärztliche Approbation |
| EMT | EMT (Rettungssanitäter) | Pharmacist License | Apotheker-Approbation |
| CPA | CPA (US-Wirtschaftsprüfer-Lizenz) | Veterinary License | Tierärztliche Approbation |
| Board Certification | Facharzt-Zertifizierung | Electrician License | Elektriker-Lizenz |
| Pharmacy Technician | Pharmazeutisch-technischer Assistent | Plumber License | Klempner-Lizenz |
| Driver's License | Führerschein | Bar Admission | Anwaltszulassung |
| CDL | CDL (Lkw- und Bus-Führerschein) | Professional Engineer | Professional Engineer (PE) |
| Pilot (private licence) | Privatpilot | Architect Licence | Architektenzulassung |
| Commercial Pilot | Berufspilot | Pesticide Applicator | Pflanzenschutz-Sachkunde |
| ATP | ATP (Verkehrspilotenlizenz) | Security Guard Licence | Wachschutz-Lizenz |
| A&P Certificate | A&P-Zertifikat | Master Electrician License | Elektromeister-Lizenz |
| Police Academy | Polizeiakademie | Master Plumber License | Klempnermeister-Lizenz |
| Psychologist License | Psychologen-Lizenz | Physical Therapy License | Physiotherapie-Lizenz |
| EPA 608 | EPA 608 | Coding Bootcamp | Coding-Bootcamp |
| Game Development Program | Programm für Spieleentwicklung | Product Design Certificate | Produktdesign-Zertifikat |
| Music Production Certificate | Musikproduktions-Zertifikat | Medical Residency / Board Exam | Facharztausbildung / Ärztliche Prüfung |
| Journeyman Electrician Exam | Elektriker-Gesellenprüfung | Law Bar Exam | Anwaltsprüfung |
"Pilot" the licence is `Privatpilot`; the job "Pilot" is `Pilot` (6.1).

### 5.8 Countries (country picker, score sheet, leaderboard lines)
United States = Vereinigte Staaten (amerikanisch-) · Germany = Deutschland (deutsch-) · Canada = Kanada (kanadisch-) · United Kingdom = Vereinigtes Königreich (britisch-) · France = Frankreich (französisch-) · Italy = Italien (italienisch-) · Japan = Japan (japanisch-) · Ukraine = Ukraine (ukrainisch-) · Australia = Australien (australisch-) · Brazil = Brasilien (brasilianisch-) · China = China (chinesisch-) · India = Indien (indisch-) · Mexico = Mexiko (mexikanisch-) · Poland = Polen (polnisch-) · Spain = Spanien (spanisch-) · Sweden = Schweden (schwedisch-) · Turkey = Türkei (türkisch-) · South Korea = Südkorea (südkoreanisch-).
The adjective stem takes the ending the sentence needs: `• Scores go to their own German leaderboard.` -> `• Punkte landen in der eigenen deutschen Bestenliste.`
Currencies (`… in euros.`): in Euro · in US-Dollar · in kanadischen Dollar · in Pfund · in Yen · in Hrywnja · in australischen Dollar · in Real · in Yuan · in Rupien · in mexikanischen Peso · in Złoty · in schwedischen Kronen · in türkischer Lira · in Won.

### 5.9 Buttons, verbs, recurring phrases (reuse verbatim when another string quotes them)
| English | Deutsch | Note |
|---|---|---|
| Take (button on an activity/course) | Wählen | Matches "Picking an activity" -> `Wähle eine Aktivität` |
| Take %@ (tip title: course, exam, licence) | %@ absolvieren | `Absolviere %@` |
| Take the %@ job | Nimm den Job als %@ | |
| Apply | Bewerben | Also the school-application screen title |
| Skip / the blue Skip button | Überspringen / der blaue Button „Überspringen“ | |
| Start over / Restart / Keep playing | Neu anfangen / Neustart / Weiterspielen | |
| Launch (business) | Gründen | |
| Open Jobs / Events / Projects / Ventures / Boardroom / Education / Activities | Jobs / Events / Projekte / Gründungen / Chefetage / Bildung / Aktivitäten öffnen | Footer labels are the bare nouns |
| Compare schools | Hochschulen vergleichen | A degree programme is at a `Hochschule`, never a `Schule` (that is school up to the Highschool); tier names (`Universität`, `Community College`) cannot take an article, so write `Universität: Hier zählen …`, not `Universität achtet auf …` |
| Only roles I qualify for | Nur passende Positionen | Toggle label; quote it exactly |
| Requirements not met / Hard requirements not met | Voraussetzungen nicht erfüllt / Feste Voraussetzungen nicht erfüllt | |
| Not yet / Needs / Requires %@ first | Noch nicht / Braucht / Braucht zuerst %@ | |
| ✓ Earned | ✓ Erreicht | |
| Send / Close / OK / Thanks! | Senden / Schließen / OK / Danke! | |
| Let's go! / Start here / How to play | Los geht’s! / Hier starten / Spielanleitung | |
| Pick your character / Starting age / Country | Wähle deine Figur / Startalter / Land | |
| Thinking… / Ask me anything… | Ich denke nach… / Frag mich etwas… | Ellipsis attached to the word |
| This year / next year / right now | Dieses Jahr / nächstes Jahr / gerade jetzt | "check again next year" -> `schau nächstes Jahr wieder nach` |
| It worked! / It didn't land | Es hat geklappt! / Es hat diesmal nicht geklappt | |
| Tap | Tippe auf | |

### 5.10 One English word, two meanings (check `_context.comment`)
| English | Deutsch (meaning 1) | Deutsch (meaning 2) |
|---|---|---|
| Science | Wissenschaft (field of work, fame, degree) | Naturwissenschaften (school subject, key `activity.science`) |
| Education | Bildung (screen, work field, industry) | Pädagogik (degree field, key `field.education`) |
| Pilot | Pilot (job) | Privatpilot (the licence, short name) |
| Present | Präsentieren (event button: give a talk; never `Geschenk`, `gegenwärtig`) | `Präsentieren bei %@` (card title), `Präsentiert` (past) |
| Field | Bereich (field of work or fame) | Studienfach (study) · Vor Ort (work setting filter) |
| Training | Weiterbildung (credential type) | Training (sport practice; verb `trainieren`) |
| Master | Master (degree) | Meister (trade rung: `Master Electrician`) |
| Champion | Meister / Champion (title) | Durchhalter (the ability) |
| Business | Wirtschaft (field) · `Unternehmen` (a business you run) | `Business is great!` -> `Die Geschäfte laufen bestens!` |
| Service | Dienstleistung (field of study) | Servicekraft (waiter) |
| Title | Titel (won in a contest) | Berufsbezeichnung (job title) |
| Round | Finanzierungsrunde (investment) | Runde (of a contest, or one game turn) |
| Ladder | Karriereleiter | `Online Ranked Ladder` -> `Online-Rangliste` |
| Level | Stufe (school stage) · Niveau (activity level) | Level (game level: `Level Designer`) |
| Seat | Posten (scarce top job) | |
| College | Hochschule (generic, US sense) | College (in names: `Community College`, `Junior College`) |

### 5.11 Recurring advisor and real-world phrasing
| English | Deutsch | Note |
|---|---|---|
| ideal / flawless candidate(s) | ideale Bewerber / makellose Bewerbung | `Only 8 % of ideal candidates get it` |
| hit or miss | ob es klappt oder nicht | |
| banks +X / adds +X | bringt +X | `Every year it survives banks +X` -> `Jedes Jahr, das es überlebt, bringt +X` |
| polish (of an application) / the cap | Feinschliff / Obergrenze | `Enough polish` -> `Genug Feinschliff` |
| Closed today / Open | Heute geschlossen / Offen | A job that cannot be applied for / can |
| the board (company) | Aufsichtsrat | `a board's search` -> `die Suche des Aufsichtsrats` |
| C-suite / C-level | C-Level | `C-suite job` -> `C-Level-Job` |
| associate / partner / "up or out" | Associate / Partner / „Aufsteigen oder Ausscheiden“ | Law firms |
| medical school / law school / residency | Medizinstudium / Jurastudium / Facharztausbildung | |
| PhD programme / postdoc | Promotionsstudium / Postdoc-Stelle | |
| start-up / public company | Start-up / börsennotiertes Unternehmen | |
| In the game: … | Im Spiel: … | Always followed by the game's rule |
| audition / showreel / gig / scouts | Vorsprechen / Showreel / Auftritt / Talentscouts | |
| rainmaking | Kundengewinnung („Rainmaking“) | |
| drafted / roster | gedraftet / Kader | |
| sponsor (a senior person who speaks for you) | Förderer | |
| Founder of %@ / %@ — Speaker (award titles) | Gründer von %@ / %@ – Redner | |

### 5.12 Traps
* `move(s)` in the advisor (one action a year) is `Schritt(e)`, never `Zug/Züge` (chess, trains). A bare skill name after an imperative reads oddly (`Steigere Kreativkopf`): write `Verbessere deine Fähigkeit „Kreativkopf“`.
* Strings that the app shows after the label `🎮 Im Spiel:` must not say `im Spiel` / `das Spiel` again. `Graduated — %@` is `Abgeschlossen: %@` (no second dash). Gap items of the lock line read as one infinitive or noun phrase each (`18 Jahre alt werden`, `%@ erwerben`, `%@ absolvieren`).
* After a colon write lower case unless a full sentence or a noun follows (`Auszeichnungen: noch keine`).
* `apply` is `bewerben`, never `anwenden`; `diploma` is `Abschluss`, not `Diplom`; `college` is not `Kolleg`; `actual(ly)` is `tatsächlich`, not `aktuell`; `become` is `werden`, not `bekommen`; `chance` is `Chance`, not `Gelegenheit`; `sensible` is `vernünftig`.
* Leave no English in the German text except the words this file keeps (`Events`, `Jobs`, `Summit`, `Junior/Senior/Lead`, loan job titles, acronyms).
* A string that looks identical in several languages (`Hackathon`, `Expo`) still needs its own German value; copy it when it is correct.

## 6. Job titles (Catalogue table)

Four key families must agree: `job.base.X` (role), `job.title.X` (full title), `job.ladder.X` (role named in prose: after `als`/`in`), `job.rung.R` (seniority word on its own).
* `job.base.X`, `job.ladder.X` and the plain-role `job.title.X` are the **same text** (no article, nominative singular, generic masculine).
* Summaries (`job.summary.X`): keep the English form, a third-person verb phrase without subject and with the full stop, in the present: `Entwirft Flugzeuge, Raumfahrzeuge und Antriebssysteme.` Prefer exact job words over paraphrase; stay within about 1.3× the English length.
* Venture base titles (businesses the player founds; the occupation then reads `CEO, %@`, which stays `CEO, %@`): Boutique Fitness Studio = Boutique-Fitnessstudio · Farm-to-Table Restaurant = Farm-to-Table-Restaurant · Indie Game Studio = Indie-Spielestudio · Property Development Firm = Immobilienentwicklungsfirma · SaaS App Startup = SaaS-App-Start-up · Specialty Coffee Roastery = Spezialitäten-Kaffeerösterei.

### 6.1 Role names
**Keep the English role name** (German job ads use it; the value equals the key, apart from the hyphenation shown): 3D Artist · Art Director · Business Analyst · Cloud Architect · Content Writer · Cybersecurity Analyst · Data Analyst · Data Scientist · Game Designer · Level Designer · Narrative Designer · Managing Partner · Nurse Practitioner · Personal Trainer · Project Manager · Research Scientist · Software Engineer · Supply Chain Manager · UX/UI Designer · Social Media Manager = Social-Media-Manager · the C-level titles Chief Executive Officer · Chief Technology Officer · Chief Medical Officer (abbreviations CEO, CTO, CMO).

**All other base titles in German:**

Accountant = Buchhalter · Administrative Assistant = Verwaltungsassistent · Aerospace Engineer = Luft- und Raumfahrtingenieur · Aircraft Maintenance Technician = Flugzeugmechaniker · Airline Pilot = Linienpilot · Anesthesiologist = Anästhesist · Animator = Animator · Architect = Architekt · Assembler = Monteur · Baker = Bäcker · Bank Teller = Bankangestellter · Bartender = Barkeeper · Beautician/Cosmetologist = Kosmetiker · Bookkeeping Clerk = Buchhaltungsassistent · Bus Driver = Busfahrer · Carpenter = Zimmermann · Cashier = Kassierer · Chef = Koch · Chemical Engineer = Chemieingenieur · Childcare Worker = Erzieher · Civil Engineer = Bauingenieur · Construction Laborer = Bauarbeiter · Cook = Beikoch · Customer Service Representative = Kundenberater · Delivery Courier = Kurier · Dental Assistant = Zahnarzthelfer · Dentist = Zahnarzt · Dishwasher = Spüler · Dispatcher = Disponent · Electrical Engineer = Elektroingenieur · Electrician = Elektriker · Event Planner = Eventplaner · Factory Worker = Fabrikarbeiter · Farmer = Landwirt · Farmhand = Landarbeiter · Fashion Designer = Modedesigner · Fast Food Worker = Fastfood-Mitarbeiter · Financial Analyst = Finanzanalyst · Firefighter = Feuerwehrmann · Fitness Instructor = Fitnesstrainer · Flight Attendant = Flugbegleiter · Food Preparation Worker = Küchenhilfe · Forklift Operator = Staplerfahrer · Graphic Artist = Grafiker · Groundskeeper = Platzwart · Hairdresser/Barber = Friseur · Heavy Equipment Operator = Baumaschinenführer · Hotel Manager = Hotelmanager · Housekeeper = Housekeeping-Kraft · Human Resources Specialist = Personalreferent · HVAC Technician = Heizungs- und Klimatechniker · Insurance Agent = Versicherungsvertreter · Interior Designer = Innenarchitekt · Investment Banker = Investmentbanker · IT Support Specialist = IT-Support-Spezialist · Janitor/Cleaner = Reinigungskraft · Journalist = Journalist · Judge = Richter · Lab Technician = Laborant · Lawyer = Rechtsanwalt · Licensed Practical Nurse = Pflegefachhelfer · Light Truck Delivery Driver = Lieferwagenfahrer · Logistics Coordinator = Logistikkoordinator · Machine Operator = Maschinenbediener · Machinist = Zerspanungsmechaniker · Maintenance & Repair Worker = Wartungs- und Reparaturtechniker · Management Consultant = Unternehmensberater · Marketing Director = Marketingdirektor · Marketing Specialist = Marketingspezialist · Mechanic = Kfz-Mechaniker · Mechanical Engineer = Maschinenbauingenieur · Medical Assistant = Arzthelfer · Mover = Umzugshelfer · Municipal Worker = Kommunalmitarbeiter · News Anchor = Nachrichtensprecher · Nursing Aide = Pflegehelfer · Office Clerk = Büroangestellter · Office Manager = Büroleiter · Operations Manager = Betriebsleiter · Painter (Construction) = Maler und Lackierer · Paralegal = Rechtsfachangestellter · Paramedic = Notfallsanitäter · Payroll Specialist = Lohnbuchhalter · Personal Care Aide = Alltagsbegleiter · Pharmacist = Apotheker · Pharmacy Technician = Pharmazeutisch-technischer Assistent · Photographer = Fotograf · Physician = Arzt · Physiotherapist = Physiotherapeut · Pilot = Pilot · Plumber = Klempner · Player = Spieler · Police Officer = Polizist · Psychologist = Psychologe · Quality Control Inspector = Qualitätsprüfer · Real Estate Agent = Immobilienmakler · Receptionist = Rezeptionist · Registered Nurse = Krankenpfleger · Retail Salesperson = Verkäufer · Roofer = Dachdecker · Sales Director = Vertriebsdirektor · Sales Manager = Vertriebsleiter · Sales Representative = Vertriebsmitarbeiter · Security Guard = Sicherheitsmitarbeiter · Social Worker = Sozialarbeiter · Software Tester/QA = Software-Tester/QA · Stocker/Order Filler = Kommissionierer · Store Manager = Filialleiter · Surgeon = Chirurg · Systems Administrator = Systemadministrator · Taxi Driver = Taxifahrer · Teacher = Lehrer · Teaching Assistant = Unterrichtsassistent · Translator/Interpreter = Übersetzer/Dolmetscher · Truck Driver = Lkw-Fahrer · Tutor = Nachhilfelehrer · TV Presenter = Fernsehmoderator · Veterinarian = Tierarzt · Video Editor = Videoeditor · Waiter/Waitress = Servicekraft · Warehouse Manager = Lagerleiter · Warehouse Worker = Lagerarbeiter · Welder = Schweißer.
Ranks with a real German name: Airline Captain = Flugkapitän · First Officer = Erster Offizier · Charge Registered Nurse = Stationsleiter · Resident Physician = Assistenzarzt · Senior Physician = Oberarzt · Editor-in-Chief = Chefredakteur · Sous Chef = Sous-Chef · Head Chef = Küchenchef · Executive Chef = Executive Chef · Amateur / Professional / Elite Player = Amateurspieler / Profispieler / Elitespieler · Apprentice X = X-Azubi (`Zimmermann-Azubi`, `Elektriker-Azubi`, `Klempner-Azubi`) · Master X = Xmeister (Master Carpenter = Zimmermeister, Master Electrician = Elektromeister, Master Plumber = Klempnermeister).

### 6.2 Seniority prefixes (one rule, so every translator produces the same forms)
* **Junior, Senior, Lead, Principal, Staff stay English** (they are indeclinable, short, and common in German job ads) and attach to the German role with a hyphen, to an English role with a space:
  `Junior Software Engineer`, `Senior Data Analyst`, `Lead Project Manager`, `Principal Research Scientist`, `Staff Software Engineer`, `Junior-Buchhalter`, `Senior-Lehrer`, `Lead-Polizist`, `Senior-Krankenpfleger`, `Senior-Feuerwehrmann`, `Junior-Finanzanalyst`.
* Never use inflected German adjectives for rungs (`Leitender Lehrer`, `Erfahrener Arzt`): the title may sit after `als`/in quotes and would need declension.
* `job.rung.R` standalone (a card headline): Junior = Junior · Senior = Senior · Lead = Lead · Principal = Principal · Staff = Staff · Executive = Executive · Head = Küchenchef · Master = Meister · Charge = Stationsleiter · Resident = Assistenzarzt · Apprentice = Azubi · Amateur = Amateur · Professional = Profi · Elite = Elite · Sous = Sous-Chef · "Standard" = Standard.
* The only exceptions to this rule are the ranks listed at the end of 6.1. Do not invent other German ranks (no `Oberlehrer`, `Polizeihauptmeister`).

### 6.3 Local institution names for a German speaker in another country
The player may be in any of the 18 countries while reading German. Keep the country's own name for a school, exam or grade (Abitur, Baccalauréat, Matura, A-levels, GPA, ENEM, gaokao, ATAR …); never translate a proper name or invent a German equivalent. Translate only generic words (5.2), keep romanisations in brackets, and add a short German gloss only where the English key already has one. In the advisor's real-world notes, US facts stay US facts (`In den USA …`).

## 7. Ten model sentences
1. `You can apply for %@ now — a %@ chance.` -> `Du kannst dich jetzt als %1$@ bewerben – deine Chance liegt bei %2$@.` (title after `als`; percent untouched)
2. Plural, three placeholders: `This job expects %lld years of experience; you have %@. Working as %@ builds it.` -> one: `Dieser Job erwartet %1$lld Jahr Erfahrung, du hast %2$@. Wenn du als %3$@ arbeitest, sammelst du sie.` · other: `Dieser Job erwartet %1$lld Jahre Erfahrung, du hast %2$@. Wenn du als %3$@ arbeitest, sammelst du sie.`
3. Plural, count dropped in `one`: `Keep going for %lld more years.` -> one: `Mach noch ein Jahr weiter.` · other: `Mach noch %lld Jahre weiter.`
4. Qualification phrase (accusative): `Get %@. It's the longest step, so start early.` -> `Hol dir %@. Das ist der längste Schritt – fang also früh an.` (with `a bachelor's degree` -> `einen Bachelor-Abschluss`)
5. Status log, no article: `Laid off from %@ — paid about half the year, with severance` -> `Entlassen als %@ – etwa das halbe Jahr bezahlt, mit Abfindung`
6. Bullet with emoji and three placeholders: `• %@ %@ is in a slump this year: %@` -> `• %1$@ %2$@ steckt dieses Jahr in der Krise: %3$@`
7. Quoted label: `No jobs match these filters. Try another kind of work, or turn off "Only roles I qualify for".` -> `Keine Jobs passen zu diesen Filtern. Probiere eine andere Art von Arbeit aus oder schalte „Nur passende Positionen“ aus.`
8. Embedded money in a noun phrase: key `The minimum wage (€13.90 an hour)` -> `Der Mindestlohn (13,90 € pro Stunde)`; line `• %@: no job pays under %@ a year.` -> `• %1$@: Kein Job zahlt weniger als %2$@ pro Jahr.`
9. Voice of the advisor: `Hi, I'm your career advisor! 👋 Do you already know what job you'd like to do one day — or not yet? Either is fine.` -> `Hallo, ich bin dein Karriereberater! 👋 Weißt du schon, welchen Job du später einmal machen möchtest – oder noch nicht? Beides ist völlig in Ordnung.`
10. Skill description with job plurals and emoji: `💼 Jobs: doctors, lawyers, judges, data scientists, engineers, financial analysts.` -> `💼 Jobs: Ärzte, Anwälte, Richter, Data Scientists, Ingenieure, Finanzanalysten.`

## 8. Decisions the product owner should confirm
1. `Ruhm` for Fame (alternative `Bekanntheit`: longer, more neutral). 2. Mode names `Vereinfacht` / `Echtes Leben` (alternative: keep `Real Life`). 3. Gender policy: generic masculine plus established neutral words, no Doppelpunkt (section 4). 4. Seniority prefixes kept English (`Senior-Lehrer`, `Lead-Polizist`) instead of German ranks. 5. English role names kept for IT, design and C-level jobs (6.1). 6. Playful ability names (5.5): `Tüftler`, `Kreativkopf`, `Kommunikator`, `Überzeuger`, `Anführer`, `Bastler`, `Durchhalter` … 7. Licences: `Approbation`/`Zulassung` for doctors, dentists, pharmacists, vets, lawyers and architects; the US acronyms (CPA, CDL, EMT …) stay. 8. English school-system names kept (`Highschool`, `Community College`, `Junior College`), generic words translated. 9. `Events` (not `Veranstaltungen`) and `Summit` kept. 10. `Posten` for the scarce top "seat", `Chefetage` for Boardroom, `Gründungen` for Ventures. 11. App name `Career Sim` not translated; miles converted to km; spaced en dash instead of em dash. 12. Orthography: Germany standard (ß); Swiss/Austrian variants are not provided.
