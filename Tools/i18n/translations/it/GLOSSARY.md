# CareerSimApp — Italian (it): glossary and style guide

Written by the lead translator before any chunk starts. **Every Italian translator follows it exactly.** A term listed here is
rendered exactly as listed (spelling, accents, case) unless the entry says it inflects. If you think an entry is wrong, use it
anyway and say so in your report; do not improvise a second form. Where the file and your taste disagree, the file wins.

Ground rules
1. Translate the *meaning*, not the key. `field.education` and `activity.science` are identifiers; `_context.comment` says what they mean.
2. One key = one Italian string even when the comment lists several contexts joined by " | ". Pick the wording that works in all of
   them; if none does, take the shorter, more general one and name the key in your report.
3. Read `_context.comment`: it says what each argument is ("a list of study fields joined with 'or'", "a percentage").
4. Never translate: *Career Sim*, *Game Center*, *Apple Intelligence*, *iOS*, *macOS*. Keep US/foreign acronyms of credentials (see §7).
5. Do not add or drop facts, emoji, bullets (`•`), `✓`, `ⓘ`, `→`, `×`, `÷`, `≈`, or line breaks (`\n`). Same emoji, same place, one space as in English.
6. Finish with `python3 Tools/i18n/i18n.py check` (placeholders and plural forms are validated).

## 1. Voice and register

* **Reader**: a child of 7 up to an adult. One friendly, direct voice: short sentences, everyday words ("fare", "usare", "avere",
  not "effettuare", "usufruire"). Warm and a little playful, never bureaucratic, never baby talk.
* **Address: informal "tu", everywhere.** Never "Lei", never "voi". Instructions and buttons use the **imperative tu**
  ("Candidati", "Scegli", "Salta", "Ricomincia da capo"), not the infinitive. Hints talk to the player ("Hai…", "Puoi…", "Ti serve…").
* **The advisor** speaks in the first person singular and says "ti" ("Ti consiglio…", "Ho trovato…", "Posso suggerirti…"). It never
  describes itself with an adjective or participle ("sono sicuro"): reword ("su questo non ho le idee chiare"). When it must be
  named: «il tuo consulente di carriera» (see §3).
* **Sentences**: keep the English sentence boundaries (two English sentences stay two). Keep the spaced em dash ` — ` where the
  source has it. Keep "!" and "?" where the source has them; add none. Do not merge, split or reorder bullet lines.
* **Labels and buttons** must stay short: buttons and tabs ≤ ~16 characters, footer buttons ≤ ~12, headers ≤ ~1.3× the English
  length. When two glossary renderings exist, use the short one in a button and the long one in a sentence.
* **Case in UI text is sentence case**: only the first word and proper nouns are capitalised. English Title Case ("Compare Schools",
  "School Sports Day") becomes "Confronta le scuole", "Giornata dello sport a scuola".

## 2. Typography

* **Quotes: «…»** (no inner spaces), replacing English “…” and "…". A quote inside a quote: “…”. Example: il titolo «Junior Champion».
* **Apostrophe: ’ (U+2019)** always, never `'`: «l’anno», «quest’anno», «un’altra mossa» (feminine takes the apostrophe, masculine
  «un altro anno» does not), «un po’» (apocope, apostrophe not accent), «c’è», «dov’è», «po’». Elide where Italian does (l’, un’, all’, dell’, nell’, quest’).
* **Accents**: à è é ì ò ù. Capital accented letters are real (**È**, never `E'`). Acute only in the -ché words (perché, affinché, poiché, benché),
  né and sé; grave elsewhere (è, più, può, già, così, però, città).
* **Dashes and marks**: spaced em dash ` — ` as in the source; en dash without spaces for ranges (`6–10`, `1–5%`); single `…` (U+2026);
  no space before `: ; ? !`. `−` (minus) and `+` pass through. `&` becomes «e» («Salute e benessere»), except inside names/acronyms (A&P).
* **Numbers**: decimal comma, thousands dot («1.500», «2,5×»). Numbers arriving as `%@` or `%lld` are already formatted: never reformat or re-spell them.
  Literal numbers *inside* a translation follow Italian format (`13.90` → `13,90`, `1,500` → `1.500`). Convert a unit only for well-known
  constants: «26.2 miles» → «42,2 km», «5K» → «5 km».
* **Percent**: a `%@` that is a percentage arrives as «73%». A literal percent sign in your text must be written `%%`, with no space
  before it: «fino a +40%%».
* **Currency**: money arrives pre-formatted in `%@` ("45.000 €"). A literal amount in a key (minimum-wage lines) is written
  number first, **no-break space (U+00A0)**, symbol, Italian separators: «13,90 €», «18,15 C$», «12,71 £», «1.121 ¥», «26,44 A$»,
  «1.621 R$», «2.740 CN¥», «315,04 MX$», «4.806 zł», «26.626 kr», «10.320 ₩», «33.030 ₺», «8.647 ₴», «18.456 ₹». Keep the symbols as in the key.
  In prose, currency names are lower case and invariable where Italian says so (see the country table).
* **Per-unit phrases**: «all’anno», «al mese», «al giorno», «all’ora», «alla settimana». «%@/yr» → «%@/anno».
* **Abbreviations**: never abbreviate years: write «anno»/«anni» (not «a.», «aa.»). «yr exp.» → «anni di esperienza» (reword if tight).
  «vs» → «contro», «approx.» → «circa», «e.g.» → «ad esempio». Acronyms stay upper case.
* **Capitalisation of names**: mode names keep a capital after «modalità» (modalità Semplificata, modalità Vita reale). Nationality adjectives, languages,
  months and days are lower case. Job titles: see §6 (capital initial in `job.base/title/rung`, lower case in `job.ladder`).
* **Lists** (`Fmt.list`) arrive as «a, b e c» / «a, b o c» from the system: never add your own «e»/«o» around a `%@` that is a list.

## 3. Gender policy (one policy)

Italian marks gender on participles and adjectives, and the player's gender is unknown.

1. **Sentences about "you": reword so no gendered adjective/participle appears** (no «sei stato promosso», «sei pronto», «benvenuto»).
   Techniques: a verb with *avere/fare/ottenere* («Hai ottenuto una promozione», «Ce l’hai fatta!», «Hai i requisiti»); a noun phrase
   («Assunzione come %@», «Promozione a %@», «Licenziamento da %@»); an impersonal subject («Il lavoro è tuo»); «ti diamo il benvenuto».
2. **When a gendered form is truly unavoidable**: the generic masculine singular. No «-o/a», «/a», schwa (ə), asterisk or «@».
3. **Role nouns, titles and level labels** (job titles, «Studente», «Principiante»/«Esperto», contest titles like «Campione»): prefer an
   epicene word (insegnante, agente, assistente, giornalista, dentista, farmacista, pilota, atleta, estetista, tutor); otherwise the
   masculine generic. English slash pairs of the same job collapse to one title («Waiter/Waitress» → «Cameriere»); pairs of different
   trades stay («Hairdresser/Barber» → «Parrucchiere/Barbiere»).
4. **The advisor** is named with the masculine article only where a name is unavoidable («il tuo consulente»); elsewhere it says «Ti consiglio…».
5. Countries and objects take their own gender: «la classifica tedesca», «il punteggio».

## 4. Placeholders and plurals

* `%@` and `%lld` stay **exactly** as they are (same type, same count). Never `%s`, `%d`, `{0}`. Never alter `\n`.
* **Two or more placeholders in the key → positional in every translation**: `%1$@`, `%2$lld`, … numbered by their order **in the English
  key**, whatever the order in your Italian sentence. Never mix positional and plain. You may reorder, you may not drop one (except as below).
* **Plurals**: a key declared plural is a JSON object `{ "one": "…", "other": "…" }`. Italian needs exactly `one` and `other`; **omit
  `many`** (it only matters from one million). Zero uses `other` («0 anni»). Positional numbers inside both branches still refer to
  the key's order. Write both branches in full.
* **The count placeholder may be absent from a branch.** In `one` you may write the number as a word when it reads better and
  the digit would need an article («ancora un anno», «una mossa», «un altro anno»); the tool allows omitting a placeholder in a plural
  branch. Never omit any other placeholder, and never leave `other` without the count. Where the English `one` and `other` are identical (the
  `yr` abbreviations), Italian still distinguishes «1 anno» / «%lld anni».
* **A count that arrives as pre-formatted `%@` cannot be inflected** (e.g. «role expects %@ yr», «%@ random skill points»: the value may be 1).
  Restructure with a label and colon so the noun is right for any number: «(anni richiesti: %@)», «punti competenza casuali: %@».
* **Never put an article, or a preposition fused with one (il, lo, la, l’, un, del, nel, sul, al, dell’, nell’…), directly before a
  numeric/percent/money placeholder**: «il 8%» is wrong, «l’8%» and «l’80%» are right, «il 7%» is right, and the program cannot know which. Use «da %@ a %@»,
  «circa %@», «fino a %@», «a %@ anni», «all’età di %lld anni», «+%@ alla tua probabilità».
  **A percentage is never the bare subject or object of a sentence, and never follows «pari a»** («paga 40% delle tasse», «una quota pari a 15%», «solo 5% ottiene» are
  wrong: Italian needs «il 40%», «pari al 15%»). Put it after a colon or in brackets instead: «You have a %@ chance» → «Probabilità: %@» / «(%@ di probabilità)»,
  «Only %@ get it» → «solo una piccola parte (%@)», «Your family pays %@» → «la paga in parte la tua famiglia (%@)», «Fees take %@ of the price» → «si prendono una parte del prezzo (%@)».
  Never «una probabilità del %@». Same for rates and shares: «Cresce di 8%» is wrong → «cresce ogni anno (interesse: %@)»; «i primi 40% di stipendio» → «una prima parte dello stipendio (%@)»;
  «12% più difficile» → «più difficile del solito (%@)»; «un tetto di 40%» → «ha un tetto (%@)»; «(prima 40%, poi 70%)» → «(primo anno: %@, secondo anno: %@)».
* **Never put an article (or a fused preposition) directly before a looked-up name** (job, field, country, skill, degree, activity): the
  name's gender and first letter are unknown. Use a construction that needs none: «come %@», «da %@», «di %@», «in %@» (degrees: «laurea in %@»),
  «nel settore %@», «il ruolo di %@», «la competenza %@», «il titolo «%@»», or a colon. Do not inflect, lower-case or capitalise a name.
* A sentence that **starts** with a name placeholder (`%@ is a narrow path`) needs a lead-in: «Il ruolo di %@ è una strada stretta», «Diventare %@ è…».

## 5. Glossary

### 5.1 Game concepts, screens, buttons
| English | Italiano | Note |
|---|---|---|
| Fame | Fama | The reputation pillar. Never «celebrità»/«reputazione». Sentences: «la tua fama nel settore %@»; label: «Fama: %@»; delta «+2 💻 fama» |
| Network | Contatti | Professional contacts. «Network in %@» → «Contatti nel settore %@». Prose may say «rete di contatti» |
| Skill / Skills | Competenza / Competenze | The 15 abilities. Heading «Competenze». Next to a name use apposition: «la competenza %@» |
| Soft-skill match | Affinità delle competenze | «soft skill» appears nowhere else. «%@ match» → «%@ di affinità» |
| Hard requirements | Requisiti obbligatori | «Preferred (helpful)» → «Consigliato (utile)» |
| Credentials / credential | Qualifiche / qualifica | Diplomas, degrees, certificates, licences |
| Certificates & licences | Attestati e abilitazioni | |
| Trophies / Accolades | Trofei / Riconoscimenti | On the Compare-schools card the same thing is «premi e titoli» everywhere (row, popover title, text) so one screen has one name |
| Title (won) | titolo | «il titolo «Junior Champion»» |
| Contest | gara | Generic. Competition → gara/competizione; championship → campionato; tournament → torneo; prize/award → premio; olympiad → olimpiade |
| Chance / odds | probabilità | «Chance to get hired» → «Probabilità di assunzione». Never «possibilità» for a percentage |
| Long shot | tentativo difficile | |
| Score | Punteggio | Real Life header button. Progress (Simplified) → «Progressi» |
| Goal | Obiettivo | |
| Leaderboard | classifica | «classifica di Game Center» |
| Advisor / Advice | Consulente / Consigli | «Advice» is the header button. «career advisor» → «consulente di carriera» |
| Move (one year's choice) | mossa | «%lld more moves» → «ancora %lld mosse» |
| Step (next step) | passo | «Il tuo prossimo passo» |
| Check-in | punto della situazione | |
| Footer: Education / Activities / Jobs / Projects / Ventures / Events | Istruzione / Attività / Lavori / Progetti / Imprese / Eventi | Short forms are fixed |
| Boardroom | Sala del consiglio | Sheet title and footer. If it truncates in the app the owner may switch to «Board» (§9) |
| Executive decision | decisione di vertice | |
| Venture | impresa | A business you found. «Venture launched!» → «Impresa avviata!»; «Launch» → «Avvia»; «Found a company» → «Fonda un’azienda» |
| Project | progetto | Spare-time project that builds fame and skills, pays nothing. (An older name, "side hustle", is gone from the UI) |
| Founder / Founder of %@ | Fondatore / Fondatore di %@ | |
| Founder track record | curriculum da fondatore | |
| Seat (scarce top job) | posto al vertice | Short: «posto». «The seat» → «Il posto al vertice». «Seat chance» → «probabilità di ottenere il posto» |
| C-suite | alta dirigenza | |
| Investment round | round di investimento | «Announce the round» → «Annuncia il round» |
| Stake / vested shares | quota / azioni maturate | «Sell your stake» → «Vendi la tua quota» |
| Exit (successful) | uscita di successo | «Successful Exit» keeps both capitals as a game term; «exited the venture» → «uscita dall’impresa» |
| Prestige (school) | prestigio | «School prestige» → «Prestigio della scuola» |
| Tier | fascia | «school tiers» → «fasce delle scuole» |
| Mode: Simplified / Real Life | Semplificata / Vita reale | Card titles. In sentences «modalità Semplificata», «modalità Vita reale». «Game mode» → «Modalità di gioco». Simplified has no score |
| Ages 7+ · easiest / Teens & up · full challenge | Da 7 anni · il più facile / Adolescenti e adulti · sfida completa | Mode-card chips |
| Age: | Età: | «Age %lld» → «%lld anni»; «Starting age» → «Età di partenza» |
| Life stages | Infanzia / Adolescenza / Giovane adulto / Vita lavorativa | Childhood / Teen Years / Young Adult / Working Life |
| Occupation / Finances / Economy | Occupazione / Finanze / Economia | «Economia» = the macro-economy only |
| Your story | La tua storia | |
| Not working | Senza lavoro | |
| Retire / career over | andare in pensione / carriera finita | «Retired from professional sport at %lld» → «Ritiro dallo sport professionistico a %lld anni» |
| Game Over | Fine del gioco | |

### 5.2 Money and economy
| English | Italiano | Note |
|---|---|---|
| Savings | Risparmi | |
| Net worth | Patrimonio netto | |
| Money earned | Denaro guadagnato | «Money earned: %@» → «Denaro guadagnato: %@» |
| Gross income | Reddito lordo | |
| Pay / salary | stipendio | «paga» only for an hourly wage; «minimum wage» → «salario minimo» |
| Salary ask / Your ask | richiesta di stipendio / La tua richiesta | «Ask for a salary» → «Chiedi uno stipendio» |
| Offer / Offer accepted! | offerta / Offerta accettata! | |
| Pay rise / Merit raise | aumento / Aumento di merito | |
| Layoff / Laid off | licenziamento | Noun, avoids gender. Title «Laid Off» → «Licenziamento» |
| Severance | buonuscita | |
| Living costs | spese quotidiane | rent and food. Never «costo della vita» |
| Tuition | tasse d’iscrizione | Heading «Tasse» |
| Student loan / Venture loan | prestito studentesco / prestito per l’impresa | «owed» → «da restituire» |
| Endorsements | Sponsorizzazioni | |
| Recession / Declared downturn | recessione / Crisi dichiarata | |
| Job market | mercato del lavoro | |
| Industry climate (this year) | andamento del settore | |
| Booming / Growing / Steady / Slowing / Slump | In boom / In crescita / Stabile / In rallentamento / In crisi | «is in a slump» → «è in crisi» |

### 5.3 Jobs and hiring
| English | Italiano | Note |
|---|---|---|
| Job / role | lavoro / ruolo | «%lld roles» → one «%lld ruolo» / other «%lld ruoli» |
| Posting / job listing | annuncio / offerta di lavoro | «Nobody is posting X jobs» → «Nessuno pubblica annunci per il ruolo di X» |
| Application | candidatura | |
| Apply | Candidati | Button/title for jobs and schools |
| Hire / hired | assunzione / assumere | Avoid «assunto». «Hired as %@» → «Assunzione come %@» |
| Promotion / Promoted | promozione / «Hai ottenuto una promozione» | «Promotion odds» → «Probabilità di promozione» |
| Employer | Datore di lavoro | «Employer's industry» → «Settore del datore di lavoro» |
| Industry (sector of the economy) | settore | |
| Field (job category, fame, filter) | settore | «Work or study in %@» → «Lavora o studia nel settore %@» |
| Office / Field / People-facing (filter) | Ufficio / Sul campo / A contatto con le persone | |
| Any (filter) / Only roles I qualify for | Qualsiasi / Solo i ruoli per cui ho i requisiti | First person is correct here |
| Experience / years of experience | esperienza / anni di esperienza | |
| Career ladder | carriera da %@ | «the Teacher ladder» → «la carriera da insegnante»; «top of the %@ ladder» → «in cima alla carriera da %@» |
| Rung / seniority / Standard | livello / livello / Standard | |
| Salary: set amount / ask | stipendio fisso / richiesta | |
| Qualified | «Hai i requisiti» | |
| Missing requirement (job lock, `First: %@.`) | «Prima devi avere: %@.» | Every missing-requirement phrase must read after «devi avere:»: «Reach age 18» → «18 anni di età», «Earn %@» → «%@», «A degree in %@» → «una laurea in %@», «Training: %@» → «la qualifica «%@»», «3 yr as X (…)» → «3 anni come X (anni richiesti: …)» |

### 5.4 Education
| English | Italiano | Note |
|---|---|---|
| Education (screen, field of work, industry) | Istruzione | One shared key |
| Education (degree field, `field.education`) | Pedagogia | «laurea in Pedagogia» |
| Degrees (tab) / Courses (tab) / Licences (tab) | Titoli di studio / Corsi / Abilitazioni | «Degrees» also lists vocational diplomas and school diplomas, so not «Lauree» |
| Degree (generic) / (university) | titolo di studio / laurea | «A degree in %@» → «una laurea in %@» (lower case: it only ever follows «Prima devi avere:») |
| Bachelor('s degree) | laurea | Length-neutral: bachelor rows last 4 years in the game, so never «triennale». «a bachelor's degree» → «una laurea», «Bachelor» → «Laurea», «University — Bachelor's» → «Laurea» |
| Master('s degree) | laurea magistrale | «University — Master's» → «Laurea magistrale» |
| Doctorate / Doctoral Degree / Doctorate+ | dottorato / Dottorato / Post-dottorato | «a doctorate» → «un dottorato» |
| School diploma | diploma | «a school diploma» → «un diploma» |
| Vocational Diploma / vocational | Diploma professionale / professionale | «College / Vocational» (US) → «College / Professionale» |
| Primary / Middle / High school | Scuola primaria / Scuola media / Scuola superiore | Generic stage names |
| College (US/CA/Ukraine) | College | Kept |
| Community College | Community college | Kept (US institution) |
| State University | Università statale | |
| Elite / Ivy League | Élite / Ivy League | Tier: «Scuola d’élite» as a common noun |
| Admission / Admission chance | ammissione / Probabilità di ammissione | |
| Grades / Grade average / GPA | voti / Media dei voti / GPA | «GPA» stays |
| Exam / Board exam / Entrance exam | esame / esame di abilitazione / test d’ingresso | |
| Course / Training / Program | corso / formazione / programma | «Training: %@» → «Formazione: %@» |
| Certificate / Certification | attestato / certificazione | «Teaching Certificate» → «Abilitazione all’insegnamento» (§7) |
| Licence / License (professional) | abilitazione | Plural «abilitazioni». Badge «licence» → «abilitazione» |
| Driver's license / pilot licence | patente di guida / brevetto di pilota | |
| Residency / Resident | specializzazione medica / specializzando | |
| Apprenticeship | apprendistato | |
| Fields of study | Ambiti di studio | |
| Student / Graduated | Studente / Hai finito | Occupation headline; «Graduated — %@» → «Hai finito: %@» (no «laureato/a», no second dash after the age: «A 10 anni — Hai finito: Scuola primaria») |

### 5.5 Fields, categories, industries (each is also a degree field where noted)
Fixed as `English = Italiano`. A name never takes an article from you.

* **Fame / degree fields (shared keys)**: Entertainment = Intrattenimento · Technology = Tecnologia · Arts = Arti · Business = Business ·
  Science = Scienze · Health = Salute · Engineering = Ingegneria · Design = Design · Law = Diritto · Agriculture = Agricoltura ·
  Sports = Sport · Service = Servizi · Education (field) = Pedagogia.
* **Job categories**: Show Business = Spettacolo · Public Services = Servizi pubblici · Construction = Edilizia · Retail = Vendita al dettaglio ·
  Hospitality = Ospitalità · Personal Services = Servizi alla persona · Manufacturing = Manifattura · Entrepreneurship = Imprenditoria ·
  Transportation = Trasporti · Administration = Amministrazione.
* **Industries**: Software & Internet = Software e internet · Computing Hardware = Hardware informatico · Telecoms = Telecomunicazioni ·
  Automotive = Automotive · Aerospace & Defence = Aerospazio e difesa · Energy & Utilities = Energia e servizi pubblici · Banking & Finance = Banche e finanza ·
  Healthcare = Sanità · Pharma & Biotech = Farmaceutica e biotecnologie · Government & Public Sector = Governo e settore pubblico ·
  Retail & Consumer = Commercio e beni di consumo · Hospitality & Tourism = Ospitalità e turismo · Media & Entertainment = Media e intrattenimento ·
  Construction & Property = Edilizia e immobiliare · Agriculture & Food = Agricoltura e alimentare · Transport & Logistics = Trasporti e logistica ·
  Industrial Manufacturing = Industria manifatturiera · Professional Services = Servizi professionali.
* **The 15 abilities** (names are labels, invariable in sentences): Inventor = Inventore · Creator = Creativo ·
  Influencer = Influencer · Persuader = Persuasore · Leader = Leader · Visionary = Visionario · Detective = Detective · Fixer = Aggiustatutto ·
  Navigator = Navigatore · Athlete = Atleta · Zen = Zen · Empath = Empatico · Teamplayer = Team player · Planner = Pianificatore · Champion = Campione.
  Their descriptions are plain sentences; the line labels after each emoji are fixed: Jobs = Lavori · Schools = Scuole · Grades = Voti · Contests = Gare ·
  Build it = Come svilupparla · Promotions = Promozioni · Boardroom = Sala del consiglio · Ventures = Imprese · Projects = Progetti.
* **Levels**: Beginner = Principiante · Intermediate = Intermedio · Advanced = Avanzato · Expert = Esperto.
* **Activity tabs and subjects**: Sports = Sport · Arts & Minds = Arte e mente · Study = Studio · Mathematics = Matematica · Science (school subject) = Scienze ·
  Reading & Writing = Lettura e scrittura · History & Geography = Storia e geografia · Foreign Languages = Lingue straniere.
* **Sports and hobbies**: Running = Corsa · Swimming = Nuoto · Cycling = Ciclismo · Soccer = Calcio · Basketball = Basket · Tennis = Tennis ·
  Martial Arts = Arti marziali · Gymnastics = Ginnastica · Skateboarding & BMX = Skateboard e BMX · E-Sports = E-sport · Music = Musica ·
  Drawing & Painting = Disegno e pittura · Photography = Fotografia · Cooking = Cucina · Dance = Danza · Coding = Coding · Chess = Scacchi ·
  Debate = Dibattito · Student Council = Consiglio degli studenti. «Practise» = «esercitarsi» (a skill) / «praticare» (an activity).
* **Kinds of contest**: Athletic = Sportiva · E-Sports = E-sport · Creative = Creativa · Mind = Mentale · Academic = Scolastica.

### 5.6 Events, contests, phrases that recur
| English | Italiano | Note |
|---|---|---|
| Summit / Expo / Forum / Festival | Summit / Expo / Forum / Festival | Kept |
| Conference / Congress / Symposium / Convention | Conferenza / Congresso / Simposio / Convegno | |
| Event button: Present / Perform / Appear / Speak / Compete / Demo | Presenta / Esibisciti / Partecipa / Intervieni / Gareggia / Mostra | Event names take no article from you, so the name goes behind «evento» in quotes: «Present at %@» → «Presenta all’evento «%@»», «Appear at %@» → «Partecipa all’evento «%@»» |
| Past labels: Presented / Performed / Appeared / Spoke / Competed / Demoed | Presentazione / Esibizione / Partecipazione / Intervento / Gara disputata / Dimostrazione | Nouns, so no gendered participle: «Presented at %@» → «Presentazione all’evento «%@»», «Spoke at %@» → «Intervento all’evento «%@»» |
| Take (button) | Scegli | Activity, training and project rows |
| Take part | partecipare | «Taking part uses up your year» → «Partecipare ti costa un anno» |
| Skip / Skip a year | Salta / Salta un anno | |
| Start over / Restart | Ricomincia da capo / Ricomincia | |
| Keep playing / Try again / Close / Send / OK | Continua a giocare / Riprova / Chiudi / Invia / OK | |
| Launch | Avvia | |
| Start here / Let's go! | Inizia da qui / Andiamo! | |
| Congratulations! / Thanks! | Congratulazioni! / Grazie! | «Welcome to Career Sim! 👋» → «Ti diamo il benvenuto in Career Sim! 👋». The alert title already says «Congratulazioni!»: the graduation body starts at «Hai completato …», never repeats it |
| Tap | Tocca | |
| It uses up your year | ti costa un anno | Recurring: «Picking an activity uses up your year» → «Scegliere un’attività ti costa un anno» |
| Champion / Winner / Medalist | campione / vincitore / medagliato | Contest titles use the masculine generic: «Campione di scacchi» |
| standard advice (no AI) | consigli di base | «you'll get the advisor's standard advice» → «avrai i consigli di base del consulente» |
| Round (contest / funding) | turno / round | «Swiss rounds» → «turni svizzeri»; funding stays «round di investimento» |
| Math Kangaroo / Math Olympiad | Kangourou della Matematica / Olimpiadi della Matematica | Real Italian names; International Math Olympiad → «Olimpiadi Internazionali di Matematica» |
| Spelling Bee / Geography Bee / History Bowl | Gara di ortografia / Gara di geografia / Quiz di storia | US formats explained in plain Italian |
| Grandmaster | Grande maestro | Chess title |
| Science Fair | Fiera della scienza | «Regional Science Fair» → «Fiera della scienza regionale» |
| Class Representative / Student Council Election | Rappresentante di classe / Elezioni del consiglio degli studenti | |

### 5.7 Countries (18). Currency phrases are invariable where noted.
| English | Italiano | Adjective (leaderboard) | "in …" currency |
|---|---|---|---|
| United States | Stati Uniti | statunitense | in dollari |
| Germany | Germania | tedesca | in euro |
| Canada | Canada | canadese | in dollari canadesi |
| United Kingdom | Regno Unito | britannica | in sterline |
| France | Francia | francese | in euro |
| Italy | Italia | italiana | in euro |
| Japan | Giappone | giapponese | in yen |
| Ukraine | Ucraina | ucraina | in grivne |
| Australia | Australia | australiana | in dollari australiani |
| Brazil | Brasile | brasiliana | in real |
| China | Cina | cinese | in yuan |
| India | India | indiana | in rupie |
| Mexico | Messico | messicana | in pesos messicani |
| Poland | Polonia | polacca | in złoty |
| Spain | Spagna | spagnola | in euro |
| Sweden | Svezia | svedese | in corone svedesi |
| Turkey | Turchia | turca | in lire turche |
| South Korea | Corea del Sud | sudcoreana | in won |

Pattern: «Stipendi, prezzi e costi scolastici dell’Italia, in euro.» The country name is typed by you (no placeholder), so use its own article:
«degli Stati Uniti», «della Germania», «del Canada», «del Regno Unito», «della Francia», «dell’Italia», «del Giappone», «dell’Ucraina», «dell’Australia»,
«del Brasile», «della Cina», «dell’India», «del Messico», «della Polonia», «della Spagna», «della Svezia», «della Turchia», «della Corea del Sud».
«Still American for now: …» → «Per ora ancora all’americana: …». Leaderboard bullet: «• I punteggi vanno alla classifica tedesca dedicata.»

### 5.8 English words with two meanings (use the right Italian for the context in `_context.comment`)
| English | Meaning A | Meaning B |
|---|---|---|
| Science | school subject (`activity.science`) → Scienze | field of fame / work / degree → Scienze (same word; «science fair» → «fiera della scienza») |
| Education | screen, job category, industry → Istruzione | degree field (`field.education`) → Pedagogia |
| Pilot | the job → Pilota | the training = private pilot licence → Pilota privato |
| Present | event button (verb) → Presenta | noun/past label → Presentazione |
| Field | jobs filter (hands-on) → Sul campo | field of work, fame, study → settore / ambito di studio |
| Business | field of work, fame, degree → Business | the economy → Economia; a company → azienda / impresa |
| Master | degree stage → laurea magistrale | seniority rung → Maestro (Maestro falegname) |
| Junior | rung → junior | age group of a contest → giovanile («Campionato giovanile») |
| Champion | ability name → Campione | contest title → campione (di …) |
| Title | title won in a contest → titolo | job title → nome del ruolo / titolo professionale |
| Service(s) | degree field → Servizi | «Personal Services» job category → Servizi alla persona |
| License | professional → abilitazione | driving → patente; flying → brevetto |
| Match | skill/school fit → affinità | a sports game → partita |
| Chance | percentage → probabilità | «a chance» to try something → occasione |
| Round | investment/funding → round | chess or contest round → turno |

## 6. Job titles (Catalogue table)

Five key families, each a different job:
* `job.base.X` = the role without seniority, a list heading and used in sentences («Assunzione come %@»). Capital initial, rest lower case.
* `job.title.X` = the full title with its seniority («Insegnante senior»). Same capitalisation. Must be consistent with `job.base.*`
  and `job.rung.*` (same head noun, same rung form, §6.2).
* `job.rung.X` = the seniority word alone, a card headline («Senior»). Capital initial.
* `job.ladder.X` = the role in running prose after «come»/«da»/«in» («5 anni come insegnante»). **Lower case** (acronyms keep caps:
  «UX/UI designer», «TV»), no article, no seniority, same noun as the base. Never starts a sentence.
* `job.summary.X` = one sentence, **third person present** («Crea grafica 3D…»), ends with a full stop, mirrors the English shape (a noun
  phrase stays a noun phrase). The six ventures (Boutique Fitness Studio, Farm-to-Table Restaurant, Indie Game Studio, Property
  Development Firm, SaaS App Startup, Specialty Coffee Roastery) are in the **imperative tu** («Apri…», «Avvia…»).

### 6.1 Rules
* **Italian trade name first.** Keep the English term only where Italian job boards use it for that digital/creative role. Keep (invariable, lower
  case after the first word): Data scientist · Project manager · Office manager · Social media manager · UX/UI designer · Game designer ·
  Level designer · Narrative designer · Cloud architect · Tutor. Everything else is Italian.
* **Gender**: epicene noun if one exists, else masculine (§3). Slash pairs of the same job collapse: Beautician/Cosmetologist → «Estetista»;
  Janitor/Cleaner → «Addetto alle pulizie»; Waiter/Waitress → «Cameriere»; Hairdresser/Barber (two trades) stays «Parrucchiere/Barbiere»;
  Translator/Interpreter stays «Traduttore/Interprete»; Software Tester/QA → «Tester software (QA)»; Stocker/Order Filler → «Scaffalista/Preparatore di ordini».
* **Compound pattern**: noun + «di»/adjective, no article, first word capitalised only: Software Engineer = «Ingegnere del software»;
  Aerospace/Chemical/Civil/Electrical/Mechanical Engineer = «Ingegnere aerospaziale/chimico/civile/elettrico/meccanico»; Business/Financial
  Analyst = «Analista aziendale/finanziario»; Data Analyst = «Analista di dati»; Cybersecurity Analyst = «Analista di cybersecurity»;
  Research Scientist = «Ricercatore»; Systems Administrator = «Amministratore di sistema»; Marketing/Sales Director = «Direttore marketing/vendite»;
  Art Director = «Direttore artistico»; Sales/Store/Operations/Warehouse Manager = «Responsabile vendite/di negozio/operativo/di magazzino»;
  Hotel Manager = «Direttore d’albergo»; Supply Chain Manager = «Responsabile della supply chain»; HR Specialist = «Specialista risorse umane»;
  Marketing Specialist = «Specialista di marketing»; Payroll Specialist = «Addetto alle paghe»; IT Support Specialist = «Tecnico di supporto IT»;
  Lab/Pharmacy Technician = «Tecnico di laboratorio/di farmacia»; HVAC Technician = «Tecnico di climatizzazione»; Aircraft Maintenance Technician =
  «Tecnico di manutenzione aeronautica»; Dental/Medical/Administrative Assistant = «Assistente odontoiatrico/di studio medico/amministrativo»;
  Teaching Assistant = «Assistente didattico»; Customer Service Representative = «Addetto all’assistenza clienti»; Sales Representative = «Agente di vendita»;
  Machine/Forklift/Heavy Equipment Operator = «Operatore di macchinari/Mulettista/Operatore di macchine movimento terra»; Factory Worker = «Operaio di fabbrica»;
  Warehouse Worker = «Magazziniere»; Construction Laborer = «Manovale edile»; Municipal Worker = «Operatore comunale»; Childcare Worker = «Educatore per l’infanzia»;
  Personal Care Aide = «Assistente alla persona»; Nursing Aide = «Operatore socio-sanitario»; Registered Nurse = «Infermiere»; Physician = «Medico»;
  Police Officer = «Agente di polizia»; Firefighter = «Vigile del fuoco»; Flight Attendant = «Assistente di volo»; Real Estate Agent = «Agente immobiliare»;
  Insurance Agent = «Agente assicurativo»; TV Presenter = «Conduttore televisivo»; News Anchor = «Conduttore del telegiornale»; Social Worker = «Assistente sociale».
* **The ladder noun must equal the base noun** (`job.ladder.Teacher` = «insegnante», `job.base.Teacher` = «Insegnante»).
* **Advisor example words** (keys «Type it below (like “nurse” or “game”)» and «Try another word (like “nurse”, “engineer” or “game”)»): use words that
  really occur in your Italian titles so the search finds them: «infermiere», «ingegnere», «game».

### 6.2 Seniority (every translator produces exactly these)
| Rung (`job.rung.*`) | Standalone label | In a title |
|---|---|---|
| Standard (no prefix) | Standard | bare title |
| Junior | Junior | «X junior» (Junior Accountant → «Contabile junior») |
| Senior | Senior | «X senior» (Senior Teacher → «Insegnante senior»; Senior Physician → «Medico senior»; Senior Police Officer → «Agente di polizia senior») |
| Lead | Lead | «X lead» for Game Designer, UX/UI Designer, Project Manager; fixed forms below for the rest |
| Principal | Principal | «X principal» (Principal Software Engineer → «Ingegnere del software principal»; Principal Research Scientist → «Ricercatore principal») |
| Staff | Staff | «Ingegnere del software staff» |
| Head | Capo | Head Chef → «Chef di cucina» |
| Executive / Sous | Executive / Sous | «Executive chef», «Sous chef» |
| Master | Maestro | prefix: «Maestro falegname/elettricista/idraulico» |
| Apprentice | Apprendista | prefix: «Apprendista falegname/elettricista/idraulico» |
| Charge | Coordinatore | Charge Registered Nurse → «Infermiere coordinatore» |
| Resident | Specializzando | Resident Physician → «Medico specializzando» |
| Amateur / Professional / Elite | Dilettante / Professionista / Élite | «Giocatore dilettante/professionista/d’élite» |

### 6.3 Fixed titles (do not vary)
| English | Italiano |
|---|---|
| Chief Executive Officer / CEO | Amministratore delegato / CEO («CEO, %@» stays) |
| Chief Technology Officer / CTO | Direttore tecnologico / CTO |
| Chief Medical Officer / CMO | Direttore sanitario / CMO |
| Editor-in-Chief | Direttore responsabile |
| Managing Partner | Managing partner |
| Airline Captain / First Officer / Airline Pilot (ladder) / Pilot | Comandante di linea / Primo ufficiale / pilota di linea / Pilota |
| Lead Firefighter | Comandante dei vigili del fuoco |
| Lead Police Officer | Commissario di polizia |
| Lead Teacher / Lead Tutor | Insegnante coordinatore / Tutor coordinatore |
| Lead Lab Technician / Lead Municipal Worker | Tecnico di laboratorio coordinatore / Coordinatore dei servizi comunali |
| Lead Game Designer / Lead UX/UI Designer / Lead Project Manager | Lead game designer / UX/UI designer lead / Project manager lead |
| Nurse Practitioner / Licensed Practical Nurse | Infermiere di pratica avanzata / Infermiere pratico |
| Chef / Cook | Chef / Cuoco |
| Boutique Fitness Studio / Indie Game Studio | Studio fitness boutique / Studio di giochi indipendente |
| Farm-to-Table Restaurant / Specialty Coffee Roastery | Ristorante a chilometro zero / Torrefazione di caffè speciali |
| Property Development Firm / SaaS App Startup | Società di sviluppo immobiliare / Startup di app SaaS |

«Chief» exists only in the three Chief titles above (no «Head of …» pattern in this game): do not invent a prefix rule for it.

## 7. Local institutions, credentials, degree titles

* **Names in the country's own language stay unchanged** (Abitur, Baccalauréat, Gymnasium, Grundschule, Matura, Atestat, Ausbildung, ENEM, gaokao, CSAT, ATAR,
  TAFE, A-levels, GPA, SAT, Oxbridge, UW / UJ / SGH …) together with any romanisation in brackets ((shōgakkō)). Do not add a gloss in a label; hints
  that explain them are translated normally. The Italian player reads these in a foreign country, so a label is a proper name, not a concept.
* **English generic parts are translated** and the local word is kept: «Elementary School (shōgakkō)» → «Scuola elementare (shōgakkō)»; «Junior High School (chūgakkō)»
  → «Scuola media (chūgakkō)»; «High School (kōkō)» → «Scuola superiore (kōkō)»; «Provincial/Private/National University» → «Università provinciale/privata/nazionale».
  French mentions (très bien, bien, assez bien, passable) stay French. The German scale (very good / good / satisfactory / sufficient) becomes
  «molto buono / buono / soddisfacente / sufficiente»; the key `%@ (%@)` pattern stays.
* **Italy's own terms** are already Italian: copy those keys unchanged (Scuola primaria, Scuola media, Diploma di maturità, ITS Academy, Università).
  Translate only the English ones: «ITS Diploma» → «Diploma ITS»; «Top private university» → «Università privata d’élite»; «Maturità score» → «Punteggio di maturità».
* **US/UK credentials**: keep the acronym, translate the description, and where Italy has a clean equivalent, use it with the acronym in brackets:
  CNA = «Assistente infermieristico (CNA)»; EMT = «Soccorritore (EMT)»; CPA = «Commercialista (CPA)»; LPN / RN / NP / CDL / ATP / PE / FAA / EPA 608 /
  A&P / NCLEX / USMLE stay as written. Medical License = «Abilitazione alla professione medica»; Dental/Pharmacist/Veterinary/Psychologist/Physical Therapy License =
  «Abilitazione odontoiatrica/farmaceutica/veterinaria/da psicologo/da fisioterapista»; Nurse License = «Abilitazione infermieristica»; Teaching Certificate =
  «Abilitazione all’insegnamento»; Bar Admission = «Abilitazione forense»; Architect Licence = «Abilitazione da architetto»; Cosmetology Licence = «Abilitazione da estetista»;
  Security Guard Licence = «Abilitazione da guardia giurata»; Driver's License = «Patente di guida»; CDL = «Patente professionale (CDL)»;
  Pilot = «Pilota privato»; Commercial Pilot = «Pilota commerciale»; Board Certification = «Certificazione di specialità»; Police Academy = «Accademia di polizia»;
  Journeyman Electrician/Plumber = «Elettricista/Idraulico qualificato». The game models the US system: never invent Italian rules that the key does not state.
  **Course titles written as «course (credential)» never repeat themselves or stack brackets**: «Esame di abilitazione alla professione medica» (not «Esame di abilitazione (Abilitazione alla professione medica)»),
  «Esame di abilitazione infermieristica (RN)», «Corso di infermieristica pratica (LPN)», «Corso per infermiere di pratica avanzata (NP)», «Corso di contabilità (CPA)»; where the course name already says it, no bracket
  («Corso per assistente odontoiatrico», «Formazione per assistenti di volo»). Credential names that come after «Ottieni questa qualifica:» / «Poi:» / «Richiede prima» are put in «…» so their capital letter is natural.
* **Degree titles** use one pattern: Bachelor of/Bachelor of Science in X = «Laurea in X» (never «triennale»: the game's bachelor stage is 4 years); Master of/of Science in X = «Laurea magistrale in X»;
  Doctor of Philosophy in X = «Dottorato di ricerca (PhD) in X»; Doctor of X = «Dottorato in X»; MBA = «Master in Business Administration (MBA)»; Doctor of Medicine (MD)
  = «Dottorato in Medicina (MD)»; Juris Doctor (JD) = «Dottorato in Giurisprudenza (JD)»; Associate of Applied Science in %@ = «Associate degree in scienze applicate: %@».
  Disciplines inside titles: Business Administration = Economia aziendale · Engineering = Ingegneria · Health Sciences = Scienze della salute · Arts = Arti ·
  Science = Scienze · Education = Scienze dell’educazione · Information Technology = Informatica · Agriculture = Agraria · Laws/Law = Giurisprudenza/Diritto ·
  Design = Design · Service Management = Gestione dei servizi · Sports Science = Scienze motorie e sportive · Kinesiology = Scienze motorie.

## 8. Model sentences (calibration)

1. `You have to be %@ for this job — %lld more years.` (plural, two placeholders)
   one → «Per questo lavoro devi avere %1$@ anni — ancora un anno.» · other → «Per questo lavoro devi avere %1$@ anni — ancora %2$lld anni.»
2. `🎯 Your chance to be hired went from %@ to %@.` → «🎯 La tua probabilità di assunzione è passata da %1$@ a %2$@.» (no article before the numbers)
3. `🤝 Your network in %@ grew from %lld to %lld.` → «🤝 I tuoi contatti nel settore %1$@ sono passati da %2$lld a %3$lld.»
4. `You have a %@ chance to get it. It pays %@.` → «Probabilità di ottenerlo: %1$@. Stipendio: %2$@.»
5. `Hired as %@ — %@/year` → «Assunzione come %1$@ — %2$@/anno» · `Promoted to %@ — pay +%@` → «Promozione a %1$@ — stipendio +%2$@» ·
   `You've been promoted to %@ — %@ a year.` → «Hai ottenuto una promozione a %1$@ — %2$@ all’anno.» (no gendered participle)
6. `%@ is a narrow path: even a flawless candidate is hired only about %@ of the years they apply — so it usually takes many attempts.`
   → «Il ruolo di %1$@ è una strada stretta: anche una candidatura perfetta riesce solo in una piccola parte degli anni in cui ti candidi (circa %2$@) — quindi di solito servono molti tentativi.»
7. `Which job are you thinking about? Type it below (like “nurse” or “game”), or pick a field to browse.`
   → «A quale lavoro stai pensando? Scrivilo qui sotto (ad esempio «infermiere» o «game») oppure scegli un settore da esplorare.»
8. `• Your pitch — 💬 Persuader most of all, then vision, talking and leading (+%@ now, up to +40%%)`
   → «• Il tuo discorso — 💬 soprattutto Persuasore, poi visione, comunicazione e guida del gruppo (+%@ ora, fino a +40%%)»
9. `🎲 Skipping %lld years of childhood gives you %@ random skill points. Playing those years yourself builds far more.` (plural; `%@` is a count, cannot be inflected)
   one → «🎲 Saltare un anno di infanzia ti regala punti competenza casuali: %2$@. Giocare quell’anno di persona ne fa guadagnare molti di più.» ·
   other → «🎲 Saltare %1$lld anni di infanzia ti regala punti competenza casuali: %2$@. Giocare quegli anni di persona ne fa guadagnare molti di più.»
10. `Requires %lld+ yrs in %@` (plural, positional) → one «Richiede almeno %1$lld anno nel settore %2$@» · other «Richiede almeno %1$lld anni nel settore %2$@»
11. `🎲 %@ chance they pick you. It goes up with years of work in %@, your %@ skill and your fame there.`
    → «🎲 Probabilità che ti scelgano: %1$@. Sale con gli anni di lavoro nel settore %2$@, con la competenza %3$@ e con la tua fama in quel settore.»
12. `Laid off from %@ — paid about half the year, with severance` → «Licenziamento da %@ — hai ricevuto circa metà dello stipendio dell’anno, più la buonuscita»

## 9. Decisions for the product owner to confirm

1. **Tu, not Lei**, everywhere (§1). Imperative buttons.
2. **Gender**: rewording first, generic masculine only as a last resort; job titles epicene-or-masculine; «Waiter/Waitress» collapsed to «Cameriere» (§3, §6.1).
3. **Quotes «…»** and **typographic apostrophe ’** (the usual Italian UI convention) instead of English “…” and `'`.
4. **Boardroom = «Sala del consiglio»** (long for a footer button; «Board» is the short alternative).
5. **Fame = «Fama», Network = «Contatti», Business = «Business»** (not «Economia», which is reserved for the macro-economy).
6. **Abilities** kept as playful person-names (Inventore, Persuasore, Aggiustatutto…) rather than abstract nouns (Ingegno, Persuasione, Manualità); the latter avoid gender
   entirely but lose the "job title" playfulness.
7. **Seniority** kept as English loan words Junior/Senior/Lead/Principal/Staff, postposed (Ingegnere del software senior) for one uniform rule; Italian-only ranks were rejected.
8. **Licence = «abilitazione»** (state-exam sense), patente for driving, brevetto for flying; US credentials keep their acronyms and are not invented into Italian rules.
9. **Job titles capitalised on the first word** (as list headings); only `job.ladder` is lower case because it is used mid-sentence. An alternative is all lower case in sentences.
10. **Currency in literal amounts** is number-first with a no-break space («13,90 €»), as the system formatter does.
11. The advisor persona takes the masculine article when named («il tuo consulente»).
