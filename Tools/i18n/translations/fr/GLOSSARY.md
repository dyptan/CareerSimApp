# French (fr) — glossary and style guide

Binding for every fr translator (chunks of `Localizable` and `Catalogue`). The lead owns this file; nobody else edits it. If a term is missing, follow the nearest pattern here and list the new term in your hand-off so it can be added. Precedence: this file > `CONVENTIONS.md` placeholder rules (they agree) > personal taste.

Notation: in this paragraph and in the table of §2, `⍽` stands for a no-break space U+00A0 and `⎵` for a narrow no-break space U+202F, so you can see them. Everywhere else the file contains the real characters (every « », and every space before `? ! ; :`, is a real U+00A0), so you can copy examples as they are.

## 1. Voice and register

* **Reader.** A child of 7+, a teenager or an adult living a career year by year. Two modes: **Simplifié** (tutorial, ages 7+, no money or score) and **Vie réelle** (teens and up, full simulation). The on-screen advisor speaks in the first person (« je ») as a kind, practical guide.
* **Address: always « tu / ton, ta, tes / toi »** — also in Vie réelle and in the adult « real-world » advisor notes. One voice for the whole game. Never « vous », never « on » for « you », when English says « you need », say « il te faut » / « tu dois » (the bare label « Needs: » → « Il faut : » is fine).
* **Tone.** Warm, short, concrete, encouraging. No irony, slang, verlan or text-speak. Keep exclamation marks where English has them; add none. Keep every emoji, bullet and symbol exactly as in the source (same order, same place, same spacing): `• ✓ 🔒 🎲 💼 ⬆️ ⓘ ← → × ÷ ≈ ~`. Do not translate: Career Sim, Game Center, Apple Intelligence, iOS, macOS and the acronyms listed in §4.12.
* **Sentences.** Present tense; short; one idea each. Instructions are the imperative « tu » (« Ouvre Emplois pour en trouver un. ») — not the infinitive. **Buttons, menu items, chips** use the infinitive or a bare noun (« Postuler », « Recommencer », « Fermer », « Envoyer ») — never the imperative. **Titles, labels, chips, card headings** are noun phrases, sentence case, no final period. Full sentences end with a period.
* **Registers in the source.** Strings whose comment says « beginner's or child's words », « tutorial », « Simplified mode » → simplest words, sentences ≤ 18 words, no jargon (« gagner » not « percevoir »; « gens » not « candidats »; « salaire » not « rémunération »). Strings « for adults / general claim » → precise but still « tu » and still short.
* **Length.** French runs 15–25 % longer than English. Targets: button/chip ≤ 16 characters, card title ≤ 30, footer button ≤ 16 (the footer row wraps, but keep it short). Prefer the short forms in §4.
* **Standard French.** The players may be in France, Belgium, Switzerland or Canada: use neutral international French. No regionalisms (no « magasiner », « courriel », « fin de semaine », « septante »), no France-only school slang except where the source itself is about France.
* **Never gender the player.** Avoid être + participle/adjective about the player (« tu es promu / qualifié / prêt / admis / embauché »), and avoid object pronoun + participle (« on t’a embauché »): the participle would have to agree. Rewrite with a verb or a noun:
  * hired → « tu décroches le poste », « embauche : %@ », « chances d’embauche » (not « chances d’être embauché » — the infinitive agrees too)
  * promoted → « tu obtiens une promotion », « Promotion : %@ »
  * qualified / ready → « tu remplis les conditions pour %@ », « tu peux postuler à %@ »
  * accepted → « tu as décroché ta place », « Admission obtenue »
  * laid off → « Licenciement » · retired → « fin de carrière » · Congratulations! → « Bravo ! » · Champion! → « Victoire ! »
  * a role as an attribute without article is neutral: « tu es PDG ».
  Verbs with *avoir* and the object after (« tu as terminé », « tu as gagné ») never agree: use them freely.
* **Never put a preposition/article/possessive in front of a looked-up `%@`.** Its gender and first letter are unknown (a job title, field, school term, competition name): no « du / de la / des / le / la / l’ / d’ / ton / ta » directly before `%@`. Use « pour %@ », « en %@ », « comme %@ », a colon (« Présenter : %@ »), guillemets after a generic noun (« la compétition « %@ » »), or a generic noun + parenthesis (« tes résultats scolaires (%@) »). `%@` may be a percentage, money, a number, a list, or a catalogue name — see §3.

## 2. Typography

| Item | Rule | Example |
|---|---|---|
| No-break space U+00A0 | **Always** before `?` `!` `;` `:` and `»`, after `«`, before `%` / `%%`, between a number and a symbol or unit (`€ $ £ km`). Never a normal space there. Type or paste the real character: the JSON must be UTF-8 without `\u` escapes (`TRANSLATING.md`). | `Bravo⍽!` · `Score⍽: %@` · `40⍽%%` · `13,90⍽€` |
| Narrow no-break space U+202F | Thousands separator in numbers **you type** inside a string. (Numbers that arrive as `%@`/`%lld` are already formatted by the system; never touch them.) | `1⎵500 heures de vol` |
| Guillemets | `«⍽texte⍽»` for titles, names, quoted words. Replace every `“ ”` and `" "` of the source. | `le titre «⍽%@⍽»` |
| Apostrophe | Always typographic `’` (U+2019), never `'`. | `l’année`, `d’expérience` |
| Ellipsis | The single character `…` (U+2026), as in the source; no space before it. | `Je réfléchis…` |
| Dashes | Keep the source's spaced em dash ` — ` (ordinary spaces). Ranges: write words (« de 6 à 10 ans »), not `6–10`. Compound nouns take a hyphen (« sous-chef »). | `… un jour — ou pas encore⍽?` |
| Decimals | Comma. Numbers you type: `13,90` `42,195 km` `2,5×`. | `(13,90⍽€ de l’heure)` |
| Currency you type | Number first, symbol last, no-break space between; keep the symbol the source uses (`C$ A$ R$ CN¥ MX$ zł kr`). `£9,790` → `9⎵790⍽£`; `¥1,121` → `1⎵121⍽¥`; `₺1 million` → `1 million de⍽₺`. Units: metric (« 26.2 miles » → « 42,195⍽km »; « 5K » → « 5⍽km »). | |
| Percent | Fmt gives « 73⍽% » (U+00A0 verified for fr_FR). A literal percent in a key is `%%`: write `⍽%%` and nothing else. Never « pour cent », never a lone `%`. | `jusqu’à +40⍽%%` |
| Per-period | « a year » → « par an »; « a month » → « par mois »; « an hour » → « de l’heure »; « /yr » → « /an ». | |
| Years | `yr`/`yrs` → « an » / « ans » (never « a. »). « y.o. » → « ans ». « exp. » only in the tiniest pills; otherwise « d’expérience ». Number + « ans » is an ordinary space. Use **« an »** after a number and in « par an »; **« année »** for the game's turn (« cette année », « l’année prochaine », « chaque année », « ton année »). | `3 ans`, `Une année = un tour` |
| Capitals | Sentence case for every label, button, title, chip and bullet label (first word, proper nouns and acronyms only). **Looked-up names — job titles, role and seniority words, fields, industries, skills, activities, school terms — keep a capital initial** (« Ingénieur logiciel », « Santé », « Échecs »), also mid-sentence: the same catalogue string is a list row or heading elsewhere (known, accepted glitch; decision C). Ordinary nouns stay lower case (« renommée », « réseau », « un bachelor »). Lower case: months, days, languages, nationality adjectives. Capital for the mode names (« mode Simplifié », « mode Vie réelle ») and for screen names inside a sentence (« ouvre Emplois », « dans la Salle du conseil »). « Jeux olympiques ». | |
| Abbreviations | « US » → « États-Unis » (« Aux États-Unis, … »); « UK » → « Royaume-Uni »; HR → RH; IT → « informatique » (« support informatique »); AI → IA; CEO → **PDG**; « e.g. » → « par ex. »; « vs » → « contre ». Keep: CTO, MBA, PhD, GPA, SAT, NHS, SMIC, MD, JD, QA. | |
| Lists | `Fmt.list` already gives « a, b et c » / « a, b ou c » (no Oxford comma). Never hand-build one. | |
| Layout | Keep `\n`, leading and trailing spaces exactly (e.g. ` (your %lld years…)` starts with a space), and the `Label:\n%@` shape. No double spaces. | |

**Inclusive writing — one policy.** Generic masculine for people and job nouns; no point médian, no « (e) », no doublets. Use the epicene form when it exists (comptable, journaliste, pilote, architecte, dentiste, juge, psychologue, photographe, élève, vétérinaire, kinésithérapeute). The only « / » pairs are those the English itself writes as two alternatives (« Waiter/Waitress » → « Serveur/Serveuse »). Address the player without gender marks (§1).

**Typography self-check before you hand in.** `i18n.py lint` checks keys, placeholders and plural forms but not typography; run this too (any translation file):
```python
import json,re,sys
bad=[r" [?!;:»]", r"(?<=\d) %", r" %%", r"[^\s\u00a0][?!;:»]", r"«(?!\u00a0)", r"[“”\"']"]
for k,v in json.load(open(sys.argv[1]))["strings"].items():
    for t in ([v] if isinstance(v,str) else v.values()):
        for b in bad:
            if re.search(b,t): print("CHECK",b,"|",t)
```
(Every hit is a real bug unless you can justify it; `?!` and `!?` are the usual false alarms.)

## 3. Placeholders and plurals

* `%@` = ready-made text (a formatted number « 45 000 », money « 45 000 € », percent « 73 % », a list « a, b et c », a name from the catalogue). `%lld` = a whole number. Copy them exactly: never `%d`, never add a unit, space or `’` glued to one (`d’%@` is a bug), never translate inside.
* **Two or more placeholders → positional in every translation** (`%1$@ … %2$lld`), numbered by their order **in the English key**, also inside each plural branch. The type must match (`@` object, `lld` integer). Reorder freely.
* **Plurals.** A plural key is a JSON object with exactly **`one` and `other`** (do not add `many`, `zero`, `two`). **French `one` covers 0 and 1**: it must read right for both (« 0 an », « 1 an », « 1 point »). So: never write the number in letters (« un seul ») in `one`; keep the `%lld` in **every** branch; the branch text still differs (« %lld an » / « %lld ans »). If English `one` and `other` are identical (« %lld yr as %@ »), French still writes « an » / « ans ». The only `%lld` of a plural key is the count; other numbers are `%@` strings, so a noun next to a `%@` number takes the plural unless it is always 1 (« %1$@ sur %2$@ points »).
* This is stricter than `TRANSLATING.md` (which lets a branch drop the number): in French `one` also means 0, so « un an » would be wrong for « 0 an ». Keep the digit in both branches.
* Literal `%` in a key is `%%` (only two keys: the 40 % and 25 % bullets). Strings may contain `\n`: keep it.
* Only two keys look like identifiers, and the chunk file shows no English for them: `field.education` is the degree field « Education » (teaching) → « Enseignement »; `activity.science` is the school subject « Science » → « Sciences ».
* JSON shape: `{"table":"Localizable","strings":{ "key": "text", "plural key": {"one":"…","other":"…"} }}`; Catalogue table keys are `job.title.<English id>` etc.

Example (the space before `;` is a real U+00A0):

```json
"This job expects %lld years of experience; you have %@. Working as %@ builds it.": {
  "one":   "Ce poste demande %1$lld an d’expérience ; tu en as %2$@. Travailler comme %3$@ t’en apporte.",
  "other": "Ce poste demande %1$lld ans d’expérience ; tu en as %2$@. Travailler comme %3$@ t’en apporte." }
```

## 4. Glossary

« Note » is guidance, not text to copy. `%@` examples show where the looked-up word goes.

### 4.1 Game concepts

| English | Français | Note |
|---|---|---|
| Fame | renommée (f.) | game term for public name in a field. « %@ fame » → « renommée en %@ ». Not « gloire »/« célébrité ». famous → célèbre |
| Network | réseau (m.) | professional contacts. « Network in %@ » → « Réseau en %@ » ; « People you know » → « Tes contacts » |
| Skill(s) | compétence(s) | the 15 abilities (§4.5) and school skills. Fallback « Skill » → « Compétence ». The UI never says « soft skills »; « Soft-skill match » → « Adéquation des compétences » |
| Hard skills | compétences techniques | not shown in the UI; only if met |
| Requirements | prérequis (m. pl.) | « Requirements not met » → « Prérequis non remplis » |
| Hard requirements | conditions obligatoires | |
| Savings | épargne (f.) | « Savings: %@ » → « Épargne : %@ » |
| Net worth | patrimoine net (m.) | what you own minus what you owe |
| Score | score (m.) | « Your score » → « Ton score » |
| Game Over | Partie terminée | |
| Gross income | revenu brut | |
| Money earned | argent gagné | |
| Living costs | dépenses courantes (f. pl.) | « rent and food » → « loyer et nourriture » |
| Pay (a job's yearly pay) | salaire (m.) | « pay stops growing » → « les salaires stagnent » |
| Salary | salaire | |
| Raise / Merit raise | augmentation / augmentation au mérite | |
| Minimum wage | salaire minimum | France: SMIC (unchanged) |
| Salary ask (« Your ask ») | prétentions salariales (f. pl.) | « Ask for a salary » → « Demander un salaire » ; « Your ask: » → « Tes prétentions : » |
| Offer (job) | offre (f.) | « Offer accepted! » → « Offre acceptée ! » |
| Posting / job listing | offre d’emploi | « no postings » → « aucune offre » ; « See job listings » → « Voir les offres d’emploi » |
| Application | candidature (f.) | |
| Apply (one key for jobs **and** schools) | Postuler | |
| Hire / hired | embauche (n.), embaucher | see §1; « Chance to get hired » → « Chances d’embauche » |
| Job (a position) | poste (m.) | « this job » → « ce poste » ; the kind of work → « métier » ; the list/sheet → « Emplois » ; « get a job » → « trouver un emploi » |
| Promotion | promotion (f.) | « Promoted to %@ » → « Promotion : %@ » |
| Layoff / Laid Off | licenciement (m.) | severance → « indemnité de licenciement » |
| Retire | prendre sa retraite | « career over » → « carrière terminée » |
| Experience (years worked) | expérience (f.) | « work experience » → « expérience professionnelle » |
| Seniority rung | échelon (m.) | |
| Career ladder | filière (f.) | « top of the %@ ladder » → « au sommet de la filière %@ » |
| Founder track record | parcours de fondateur (m.) | scored in points |
| Seat (scarce top job) | place (f.) | « The seat » → « La place » ; « partner seat » → « place d’associé » ; C-suite → « direction générale » |
| Stake / your share | participation (f.) / ta part | « Sell Your Stake » → « Vendre ta participation » |
| Shares, vested shares | actions (f. pl.), actions acquises | |
| Investment round | levée de fonds (f.) | « Announce an Investment Round » → « Annoncer une levée de fonds » |
| Investor | investisseur | |
| Venture (the company you found) | entreprise (f.) | sheet/footer « Ventures » → « Entreprises » ; « Venture launched! » → « Entreprise lancée ! » |
| Venture loan | prêt d’entreprise (m.) | |
| Founder / found / Launch | fondateur / fonder / Lancer | « Founder of %@ » → « Fondateur : %@ » |
| Breakout / hit | décollage (m.) / succès | « broke out » → « a décollé » ; « Breakout role » → « Rôle révélation » ; hit single → « tube » |
| Successful Exit | Sortie réussie | |
| Boardroom | Salle du conseil | never « Conseil » (= advice) |
| Executive decision | décision de direction | |
| Project (spare-time) | projet (m.) | « Projects » sheet → « Projets » |
| Side hustle | activité annexe | not in the UI |
| Contest / Competition (generic) | compétition (f.) | « concours » for arts/academic and in named events ; « your biggest contest » → « ta plus grande compétition » |
| Title (won) | titre (m.) | « the “%@” title » → « le titre « %@ » » |
| Trophies / accolades | trophées / distinctions | |
| Event | événement (m.) | |
| Activity | activité (f.) | |
| Advisor / Advice | conseiller / Conseils | persona: « conseiller d’orientation » ; header button « Advice » → « Conseils » |
| Chance, odds | chances (f. pl.) | always plural: « 73 % de chances », « Tes chances : %@ » |
| Long shot | pari risqué | |
| Industry | secteur (m.) | |
| Economy / recession / downturn | économie / récession | « Declared downturn » → « Récession déclarée » |
| Job market | marché de l’emploi | |
| Field (domain) | domaine (m.) | « Field of study » → « Domaine d’études » ; « Kind of work » → « Type de travail » |
| Level (school) | niveau d’études | « school level » |

### 4.2 Education

| English | Français | Note |
|---|---|---|
| Degree / Diploma | diplôme (m.) | « Degrees » → « Diplômes » |
| a school diploma | un diplôme de fin d’études secondaires | short: « diplôme du secondaire » |
| a college or vocational diploma | un diplôme professionnel ou technique | |
| Bachelor / a bachelor's degree | bachelor (m.) | « un bachelor en %@ ». **Not « licence »**: licence = permit (decision A) |
| Master / a master's degree | master (m.) | |
| Doctorate / Doctoral Degree | doctorat (m.) | |
| Doctorate+ | post-doctorat | |
| X of Y (Bachelor of Y, Master of Y) | Bachelor en y, Master en y | lower-case the field: « Bachelor en sciences de la santé » |
| Doctor of Philosophy in Y | Doctorat (PhD) en y | MD → « Doctorat en médecine (MD) » ; Juris Doctor (JD) unchanged ; MBA unchanged |
| Associate of Applied Science in %@ | Associate degree appliqué en %@ | US two-year degree |
| Trade Certificate | certificat de métier | |
| Vocational Diploma | Diplôme professionnel | |
| Primary / Elementary School | École primaire / École élémentaire | |
| Middle School | Collège | |
| High School | Lycée | |
| University | Université | |
| Education (screen, footer, job field, industry) | Éducation | one key serves all four |
| Education (degree field, `field.education`) | Enseignement | |
| Course / Training | formation (f.) | « Courses » → « Formations » ; « Trainings: » → « Formations : » |
| Certificate | certificat (m.) | |
| Licence / License | licence (f.) | permit to practise (§4.8). **Never** the degree |
| Credentials | qualifications (f. pl.) | |
| Tuition | frais de scolarité (m. pl.) | |
| Student loan | prêt étudiant (m.) | |
| Student (no job) | Élève | « étudiant » only when higher education is explicit |
| Grades, school grade | notes (f. pl.), note | « grade average » → « moyenne » ; « full marks » → « la note maximale » |
| Subject | matière (f.) | |
| Admission / Admission chance | admission / Chances d’admission | « Admission requirement » → « Condition d’admission » |
| Prestige | prestige (m.) | « School prestige » → « Prestige de l’école » |
| Community College | Community college | US tier name kept (§6) |
| State University | Université d’État | |
| Elite / Ivy League | Élite / Ivy League | generic « elite school » → « école d’élite » |
| mainstream school | établissement classique | |
| Prizes and titles | prix et titres | |
| EQF | CEC (Cadre européen des certifications) | not shown in the UI |

### 4.3 Fields, industries, climate

* **Job categories** (also used as « en %@ »): Engineering = Ingénierie · Show Business = Show-business · Public Services = Services publics · Health = Santé · Technology = Technologie · Education = Éducation · Agriculture = Agriculture · Design = Design · Law = Droit · Business = Business · Construction = Construction · Retail = Commerce · Science = Sciences · Hospitality = Hôtellerie-restauration · Personal Services = Soins et beauté · Manufacturing = Fabrication · Entrepreneurship = Entrepreneuriat · Transportation = Transport · Administration = Administration.
* **Fame fields**: Entertainment = Divertissement · Technology = Technologie · Arts = Arts · Business = Business · Science = Sciences · 🌐 General = Général.
* **Degree fields** (same keys as above where shared): Sports = Sports · Service = Services · Education (`field.education`) = Enseignement.
* **Work settings** (jobs filter): Office = Bureau · Field = Terrain · People-facing = Relationnel · Any = Tous.
* **Industries**: Software & Internet = Logiciels et internet · Computing Hardware = Matériel informatique · Telecoms = Télécoms · Automotive = Automobile · Aerospace & Defence = Aérospatiale et défense · Energy & Utilities = Énergie et eau · Banking & Finance = Banque et finance · Healthcare = Soins de santé · Pharma & Biotech = Pharma et biotech · Education = Éducation · Government & Public Sector = Gouvernement et secteur public · Retail & Consumer = Commerce et consommation · Hospitality & Tourism = Hôtellerie et tourisme · Media & Entertainment = Médias et divertissement · Construction & Property = Construction et immobilier · Agriculture & Food = Agriculture et alimentation · Transport & Logistics = Transport et logistique · Industrial Manufacturing = Industrie manufacturière · Professional Services = Services professionnels. « & » → « et » everywhere except fixed names (A&P, R&D, S&P).
* **Industry climate** (label | in a sentence): Booming = En plein essor | est en plein essor · Growing = En croissance | est en croissance · Steady = Stable | est stable · Slowing = En ralentissement | ralentit · Slump = En berne | est en berne. Source quirk: « is slump this year » = « is in a slump » → « est en berne ».
* **Twin words**: Science (field/fame = Sciences ; school subject `activity.science` = Sciences ; « Science Fair » = Concours de sciences) · Pilot (job = Pilote ; licence key `Pilot` = Pilote privé ; `Commercial Pilot` = Pilote professionnel ; ladder « Airline Pilot » = Pilote de ligne) · Business (field = Business ; a company = entreprise) · Master (degree = master ; rung « Master » = Maître) · Doctor (physician = médecin ; doctorate = doctorat) · Field (work setting = Terrain ; domain = domaine) · Staff (rung = Expert ; personnel = personnel) · Principal (rung = Principal) · Course (training = formation ; race course = parcours) · Round (investment = levée de fonds ; chess = ronde ; contest stage = phase) · Present (verb, §4.7) · Standard (rung = Standard ; « standard advice » = conseils habituels).

### 4.4 Countries (picker, score sheet, leaderboard)

« Leaderboard » = classement (m.). « from %country » is written inside each whole-sentence string; use the « de » column.

| English | Français | de + pays | Adjective (leaderboard) | Currency phrase |
|---|---|---|---|---|
| United States | États-Unis | des États-Unis | — | en dollars |
| Germany | Allemagne | d’Allemagne | allemand | en euros |
| Canada | Canada | du Canada | canadien | en dollars canadiens |
| United Kingdom | Royaume-Uni | du Royaume-Uni | britannique | en livres sterling |
| France | France | de France | français | en euros |
| Italy | Italie | d’Italie | italien | en euros |
| Japan | Japon | du Japon | japonais | en yens |
| Ukraine | Ukraine | d’Ukraine | ukrainien | en hryvnias |
| Australia | Australie | d’Australie | australien | en dollars australiens |
| Brazil | Brésil | du Brésil | brésilien | en reais |
| China | Chine | de Chine | chinois | en yuans |
| India | Inde | d’Inde | indien | en roupies |
| Mexico | Mexique | du Mexique | mexicain | en pesos mexicains |
| Poland | Pologne | de Pologne | polonais | en zlotys |
| Spain | Espagne | d’Espagne | espagnol | en euros |
| Sweden | Suède | de Suède | suédois | en couronnes suédoises |
| Turkey | Turquie | de Turquie | turc | en livres turques |
| South Korea | Corée du Sud | de Corée du Sud | sud-coréen | en wons |

### 4.5 The 15 skills (generic masculine; shown with a pictogram, capitalised)

Inventor = Inventeur · Creator = Créateur · Influencer = Influenceur · Persuader = Persuadeur · Leader = Leader · Visionary = Visionnaire · Detective = Détective · Fixer = Artisan · Navigator = Navigateur · Athlete = Athlète · Zen = Zen · Empath = Empathe · Teamplayer = Équipier · Planner = Organisateur · Champion = Champion. Lists « 💼 Jobs: … 🎓 Schools: … 🏅 Contests: … 🌱 Build it: … » keep their emoji and lead word: Jobs = Métiers · Schools = Écoles · Grades = Notes · Contests = Compétitions · Build it = Pour progresser · Promotions = Promotions · Ventures = Entreprises · Boardroom = Salle du conseil · Projects = Projets.

### 4.6 Activities, sports, subjects, stages

* **Tabs**: Sports = Sports · Arts & Minds = Arts et esprit · Study = Études.
* **Disciplines**: Running = Course à pied · Swimming = Natation · Cycling = Cyclisme · Soccer = Football · Basketball = Basket-ball · Tennis = Tennis · Martial Arts = Arts martiaux · Gymnastics = Gymnastique · Skateboarding & BMX = Skateboard et BMX · E-Sports = E-sport · Music = Musique · Drawing & Painting = Dessin et peinture · Photography = Photographie · Cooking = Cuisine · Dance = Danse · Coding = Programmation · Chess = Échecs · Debate = Débat · Student Council = Conseil des élèves.
* **School subjects**: Mathematics = Mathématiques · Science = Sciences · Reading & Writing = Lecture et écriture · History & Geography = Histoire-géographie · Foreign Languages = Langues étrangères.
* **Levels**: Beginner = Débutant · Intermediate = Intermédiaire · Advanced = Avancé · Expert = Expert. **Kinds of contest**: Athletic = Sportif · E-Sports = E-sport · Creative = Créatif · Mind = Réflexion · Academic = Scolaire.
* **Life stages**: Childhood = Enfance · Teen Years = Adolescence · Young Adult = Jeune adulte · Working Life = Vie active.

### 4.7 Events and competitions

* **Event words**: Summit = Sommet · Expo / Show (trade fair) = Salon · Conference = Conférence · Congress = Congrès · Symposium = Symposium · Forum = Forum · Convention = Convention · Week (Design Week) = Semaine · Festival = Festival · Casting = Casting · Pitch = pitch (« Pitch Night » = Soirée pitch) · Hackathon = Hackathon.
* **Event buttons** (verb | past label): Present = Présenter | Présenté · Perform = Jouer | Joué · Appear = Apparaître | Apparu · Speak = Intervenir | Intervenu · Compete = Concourir | Concouru · Demo = Faire une démo | Démo faite. « Present at %@ » → « Présenter : %@ » (colon dodges « au/à la »).
* **Competition words**: Cup = Coupe · Championship = Championnat · Tournament = Tournoi · Olympiad = Olympiade · Olympic Games = Jeux olympiques · Contest = Concours · Recital = Récital · Showcase = Spectacle · Prize / Award = Prix · Winner = Vainqueur · Champion = Champion · Medalist = Médaillé · Laureate = Lauréat · Grandmaster = Grand maître · Class Representative = Délégué de classe · Student Body President = Président du conseil des élèves.
* **Named contests** are adapted to French culture where an equivalent exists: Math Kangaroo = Kangourou des mathématiques · Spelling Bee = Concours d’orthographe · Geography Bee = Concours de géographie · History Bowl = Quiz d’histoire · Science Fair = Concours de sciences · LAN Tournament = Tournoi LAN · Online Ranked Ladder = Classement en ligne · Marathon distance = 42,195 km. Winner/title lines: « School Chess Champion » = Champion d’échecs de l’école · « Sports Day Winner » = Vainqueur de la journée sportive.

### 4.8 UI words, verbs and credentials

* **Buttons and screens**: Start over = Recommencer · Restart = Redémarrer · Keep playing = Continuer à jouer · Take = Choisir · Apply = Postuler · Skip (a year) = Passer · Launch = Lancer · Close = Fermer · Send = Envoyer · OK = OK · Thanks! = Merci ! · Let's go! = C’est parti ! · Compare schools = Comparer les écoles · Open X = « Ouvrir X » with the screen name, no article (« Ouvrir Emplois », « Ouvrir Salle du conseil ») · Tap = « appuie sur » · Thinking… = Je réfléchis… · Standard advice = conseils habituels.
* **Header and panels**: Age: = Âge : · Game mode = Mode de jeu · Goal = Objectif · Progress = Progression · Advisor = Conseiller · Occupation = Situation · Finances = Finances · Economy = Économie · Experience = Expérience · Fame = Renommée · Skills = Compétences · Trophies = Trophées · Credentials = Qualifications · Your story = Ton histoire · Settings = Réglages.
* **Modes**: Simplified = Simplifié · Real Life = Vie réelle · « Ages 7+ » = Dès 7 ans · « Teens & up » = Ados et plus · Make it to the top = Atteindre le sommet · Best score by %lld = Meilleur score à %lld ans.
* **Licences** (US names kept, « Licence de X » pattern, short label): Driver's License = Permis de conduire · Nurse License = Licence d’infirmier · Medical License = Licence de médecin · Dental License = Licence de dentiste · Pharmacist License = Licence de pharmacien · Veterinary License = Licence de vétérinaire · Electrician License = Licence d’électricien · Plumber License = Licence de plombier · Master Electrician / Plumber License = Licence de maître électricien / plombier · Architect Licence = Licence d’architecte · Security Guard Licence = Licence d’agent de sécurité · Psychologist License = Licence de psychologue · Physical Therapy License = Licence de kinésithérapeute · Cosmetology Licence = Licence d’esthétique · Pilot (private) = Pilote privé · Commercial Pilot = Pilote professionnel · Bar Admission = Admission au barreau · Professional Engineer = Ingénieur professionnel (PE) · Board Certification = Certification de spécialité · Pesticide Applicator = Applicateur de pesticides · Police Academy = École de police · Teaching Certificate = Certificat d’enseignement · Dental Assistant = Assistant dentaire · Flight Attendant = Agent de bord · Pharmacy Technician = Préparateur en pharmacie · Nurse Practitioner = Infirmier en pratique avancée · Coding Bootcamp = Bootcamp de programmation · Game Development Program = Programme de développement de jeux · Product Design Certificate = Certificat de design produit · Music Production Certificate = Certificat de production musicale. Exams: board exam = examen d’État · Bar exam = examen du barreau · Residency = internat · Sworn Officer = Policier assermenté.
* **US acronyms stay**, glossed once in running text (not in labels): CNA (aide-soignant certifié) · EMT (ambulancier) · CPA (expert-comptable américain) · CDL (permis poids lourd) · LPN (infirmier auxiliaire) · ATP (pilote de ligne) · A&P (mécanicien aéronautique) · EPA 608 · NCLEX · USMLE · FAA · PE · NP.

### 4.9 Recurring phrases (use these frames so every chunk reads the same)

| English frame | Français |
|---|---|
| this year / next year / every year | cette année / l’année prochaine / chaque année |
| check again next year · Try again next year | reviens voir l’année prochaine · Réessaie l’année prochaine |
| X uses up your year | X prend toute ton année (« Choisir une activité prend toute ton année. ») |
| not yet · for now | pas encore · pour l’instant |
| the job asks for / needs Y | le poste demande Y |
| adds +X to your chance | ajoute +X à tes chances |
| Y counts (for more) | Y compte (davantage) |
| worth about X | vaut environ X |
| builds [skill] · Grow Y from A to B | développe [compétence] · Fais passer Y de A à B |
| Grows either way / whether it works or not | Progresse dans tous les cas |
| If it works / If it doesn't work out | Si ça marche / Si ça ne marche pas · « hit or miss » → « que ça marche ou non » |
| Requires X · Requires age N+ | Nécessite X · À partir de N ans |
| What helps: / What counts: / Needs: / This year: | Ce qui aide : / Ce qui compte : / Il faut : / Cette année : |
| good / bad economy · bad year | bonne / mauvaise conjoncture · mauvaise année |
| no job pays under X a year | aucun poste ne paie moins de X par an |
| ~X chance someone buys | ~X de chances qu’on l’achète (buyers = acheteurs) |
| a lottery · a long shot | une loterie · un pari risqué |
| Earned after … (credentials) | s’obtient après … (no agreement; « State license » → « Licence d’État ») |
| show off (event blurbs) | présentent (« Les ingénieurs présentent leurs nouvelles machines. ») |
| Check-in · age N | Bilan · N ans |
| Try X — it builds Y | Essaie X : ça développe Y |
| Keep building your skills | Continue à développer tes compétences |
| I'll suggest jobs that fit you | Je te proposerai des métiers qui te correspondent |
| the standard advice (fallback) | les conseils habituels |
| In the game: … · the real world | Dans le jeu : … · le monde réel |
| unlock (as you get older) | se débloquent (« Les diplômes se débloquent à mesure que tu grandis. ») |

### 4.10 Labels on the job, school and money panels

Education: = Études : · School: (bullets) = Études : · Experience: = Expérience : · Salary: = Salaire : · Field: %@ = Domaine : %@ · Requirements = Prérequis · Trainings: = Formations : · Licences: all set ✓ / missing = Licences : tout est bon ✓ / manquantes · Preferred (helpful): = Souhaité (utile) : · Breakthrough: = Percée : · Employer = Employeur · Employer's industry = Secteur de l’employeur · Market median = Médiane du marché · Chance to get hired: = Chances d’embauche : · What your chance depends on = Ce dont dépendent tes chances · Your story = Ton histoire · Banked from pay = Épargné sur le salaire · Endorsements = Partenariats · Venture loan owed = Prêt d’entreprise restant dû · Student loan owed = Prêt étudiant restant dû · Total %@ = Total %@ · Asking price = Prix demandé · Admission chance: = Chances d’admission : · Soft-skill match = Adéquation des compétences · Trophies & accolades = Trophées et distinctions · How admission works = Comment fonctionne l’admission · Not hiring right now = Aucune offre pour l’instant.

### 4.11 Frequent verbs and words (from the corpus counts)

build / get a skill = développer · get a job = décrocher un poste (not « obtenir ») · earn money = gagner · earn a credential or title = obtenir · win = gagner / remporter · practise = pratiquer (hobbies) / s’entraîner (sports) · try = essayer · keep (going) = continuer · grow / rise = progresser, augmenter · show off = présenter · help = aider (« aide à » ; a lever that helps = « un coup de pouce ») · own (company) = propre (« ta propre entreprise ») · most = le plus / la plupart · people = gens (generic) / personnes (counted) · national = national · public = public · state (university) = d’État · exam = examen · team = équipe · door (metaphor) = porte (keep « ouvre la porte ») · step / next step = étape / prochaine étape · program = programme · age = âge.

### 4.12 Do not translate

A result equal to the English is a mistake **except** for these intended ones: Design · Business · Tennis · Score · Hackathon · Festival · Forum · Casting · Symposium · Convention · Zen · Leader · Expert · cognates such as Transport, Construction, Administration, Agriculture, Architecte, Dentiste · OK · Game designer / Level designer / Narrative designer / Data scientist / Community manager · Junior · Senior · Amateur · Standard.

Career Sim · Game Center · Apple Intelligence · iOS · macOS · ⓘ · the acronyms in §4.8 and §2 (CTO, MBA, PhD, GPA, SAT, NHS, SMIC, JD, MD, QA, UX/UI, SaaS, HVAC→CVC is translated) · proper names of exams and institutions (Abitur, Ivy League, Oxbridge, Russell Group, Group of Eight, U15, IIT/IIM/AIIMS, SKY, ENEM, CSAT, gaokao, ATAR, A-levels, BTEC, TAFE).

## 5. Job-title policy (catalogue: `job.title.*`, `job.base.*`, `job.ladder.*`, `job.rung.*`, `job.summary.*`)

1. **One French string per role.** `job.base.X`, `job.ladder.X` and `job.title.X` for the same X are **identical** (ladder and base are the plain role: « 5 ans comme Enseignant »). Use the canonical list below verbatim; do not paraphrase.
2. **Form**: generic masculine, first letter capital only (« Technicien de laboratoire »), epicene nouns unchanged. Pairs only where English has two alternatives of gender (« Serveur/Serveuse »). Two real professions joined by « / » in English become the French combined title (« Coiffeur-barbier », « Traducteur-interprète », « Magasinier-préparateur de commandes », « Esthéticien-cosméticien »).
3. **Loan words kept** (lower-case after the first word): Data scientist · Game designer · Level designer · Narrative designer · Designer UX/UI · Community manager · Architecte cloud · Start-up. Translate everything else; do not keep English for a role that has a normal French title.
4. **Seniority prefixes become French words placed after the role**, so every translator gives the same form: Junior X → « X junior » · Senior X → « X senior » · **Lead X → « X référent »** · Principal X → « X principal » · **Staff X → « X expert »**. Examples: « Ingénieur logiciel junior / senior / expert / principal » ; « Chef de projet référent » ; « Technicien de laboratoire référent » ; « Policier senior » ; « Responsable commercial senior ».
5. **Named rungs** (French order and wording are fixed): Apprentice Carpenter/Electrician/Plumber = Apprenti menuisier / électricien / plombier · Master Carpenter/Electrician/Plumber = Maître menuisier / électricien / plombier · Sous Chef = Sous-chef · Head Chef = Chef de cuisine · Executive Chef = Chef exécutif · Charge Registered Nurse = Infirmier coordinateur · Resident Physician = Médecin interne · Amateur / Professional / Elite Player = Joueur amateur / professionnel / d’élite · First Officer = Copilote · Airline Captain = Commandant de bord. **Standalone rung words** (`job.rung.*`): Amateur = Amateur · Apprentice = Apprenti · Charge = Coordinateur · Elite = Élite · Executive = Exécutif · Head = Chef · Junior = Junior · Lead = Référent · Master = Maître · Principal = Principal · Professional = Professionnel · Resident = Interne · Senior = Senior · Sous = Sous-chef · Staff = Expert · Standard = Standard.
6. **Venture names** (the businesses the player founds) are noun phrases, lower-case after the first word: Boutique Fitness Studio = Studio de fitness boutique · Farm-to-Table Restaurant = Restaurant de la ferme à l’assiette · Indie Game Studio = Studio de jeux vidéo indépendant · Property Development Firm = Société de promotion immobilière · SaaS App Startup = Start-up d’application SaaS · Specialty Coffee Roastery = Torréfaction de cafés de spécialité. Their summaries address the player: imperative « tu » (« Lance un petit studio… »).
7. **Summaries**: ordinary roles = third person, present, no subject, one sentence ending with a period, starting with a verb (« Prépare les états financiers. »). Keep the source's « — » clauses. « Top of the X ladder » → « sommet de la filière X ». Do not add or drop information. Expand English jargon French readers do not know: IC → « expert sans poste de manager » ; PMO → « bureau de gestion de projets » ; M&A → « fusions-acquisitions » ; RN → « infirmier diplômé » ; equity partner → « associé détenteur de parts ».
8. **CEO** = « PDG » in prose and « CEO, %@ » → « PDG, %@ » ; the job title « Chief Executive Officer » = « Directeur général ». « Becoming a CTO » → « Devenir CTO » ; title « Chief Technology Officer » = « Directeur technique ».

**Canonical list (English = Français).**
3D Artist = Artiste 3D · Accountant = Comptable · Administrative Assistant = Assistant administratif · Aerospace Engineer = Ingénieur en aérospatiale · Aircraft Maintenance Technician = Technicien de maintenance aéronautique · Airline Pilot = Pilote de ligne · Anesthesiologist = Anesthésiste · Animator = Animateur · Architect = Architecte · Art Director = Directeur artistique · Assembler = Assembleur · Baker = Boulanger · Bank Teller = Employé de banque · Bartender = Barman · Beautician/Cosmetologist = Esthéticien-cosméticien · Bookkeeping Clerk = Aide-comptable · Bus Driver = Conducteur de bus · Business Analyst = Analyste métier · Carpenter = Menuisier · Cashier = Caissier · Chef = Chef cuisinier · Chemical Engineer = Ingénieur en génie chimique · Chief Executive Officer = Directeur général · Chief Medical Officer = Directeur médical · Chief Technology Officer = Directeur technique · Childcare Worker = Auxiliaire de puériculture · Civil Engineer = Ingénieur en génie civil · Cloud Architect = Architecte cloud · Construction Laborer = Ouvrier du bâtiment · Content Writer = Rédacteur de contenu · Cook = Cuisinier · Customer Service Representative = Conseiller clientèle · Cybersecurity Analyst = Analyste en cybersécurité · Data Analyst = Analyste de données · Data Scientist = Data scientist · Delivery Courier = Coursier · Dental Assistant = Assistant dentaire · Dentist = Dentiste · Dishwasher = Plongeur · Dispatcher = Répartiteur · Editor-in-Chief = Rédacteur en chef · Electrical Engineer = Ingénieur en électricité · Electrician = Électricien · Event Planner = Organisateur d’événements · Factory Worker = Ouvrier d’usine · Farmer = Agriculteur · Farmhand = Ouvrier agricole · Fashion Designer = Créateur de mode · Fast Food Worker = Employé de fast-food · Financial Analyst = Analyste financier · Firefighter = Pompier · Fitness Instructor = Instructeur de fitness · Flight Attendant = Agent de bord · Food Preparation Worker = Commis de cuisine · Forklift Operator = Cariste · Game Designer = Game designer · Graphic Artist = Graphiste · Groundskeeper = Jardinier · HVAC Technician = Technicien CVC · Hairdresser/Barber = Coiffeur-barbier · Heavy Equipment Operator = Conducteur d’engins de chantier · Hotel Manager = Directeur d’hôtel · Housekeeper = Employé d’étage · Human Resources Specialist = Chargé de ressources humaines · IT Support Specialist = Technicien support informatique · Insurance Agent = Agent d’assurance · Interior Designer = Architecte d’intérieur · Investment Banker = Banquier d’affaires · Janitor/Cleaner = Agent d’entretien · Journalist = Journaliste · Judge = Juge · Lab Technician = Technicien de laboratoire · Lawyer = Avocat · Level Designer = Level designer · Licensed Practical Nurse = Infirmier auxiliaire · Light Truck Delivery Driver = Chauffeur-livreur · Logistics Coordinator = Coordinateur logistique · Machine Operator = Opérateur de machines · Machinist = Usineur · Maintenance & Repair Worker = Agent de maintenance · Management Consultant = Consultant en management · Managing Partner = Associé gérant · Marketing Director = Directeur marketing · Marketing Specialist = Chargé de marketing · Mechanic = Mécanicien · Mechanical Engineer = Ingénieur en mécanique · Medical Assistant = Assistant médical · Mover = Déménageur · Municipal Worker = Agent municipal · Narrative Designer = Narrative designer · News Anchor = Présentateur du JT · Nurse Practitioner = Infirmier en pratique avancée · Nursing Aide = Aide-soignant · Office Clerk = Employé de bureau · Office Manager = Responsable administratif · Operations Manager = Responsable des opérations · Painter (Construction) = Peintre en bâtiment · Paralegal = Assistant juridique · Paramedic = Ambulancier · Payroll Specialist = Gestionnaire de paie · Personal Care Aide = Aide à domicile · Personal Trainer = Coach sportif · Pharmacist = Pharmacien · Pharmacy Technician = Préparateur en pharmacie · Photographer = Photographe · Physician = Médecin · Physiotherapist = Kinésithérapeute · Pilot = Pilote · Player = Joueur · Plumber = Plombier · Police Officer = Policier · Project Manager = Chef de projet · Psychologist = Psychologue · Quality Control Inspector = Contrôleur qualité · Real Estate Agent = Agent immobilier · Receptionist = Réceptionniste · Registered Nurse = Infirmier diplômé · Research Scientist = Chercheur · Retail Salesperson = Vendeur · Roofer = Couvreur · Sales Director = Directeur commercial · Sales Manager = Responsable commercial · Sales Representative = Attaché commercial · Security Guard = Agent de sécurité · Social Media Manager = Community manager · Social Worker = Travailleur social · Software Engineer = Ingénieur logiciel · Software Tester/QA = Testeur logiciel (QA) · Stocker/Order Filler = Magasinier-préparateur de commandes · Store Manager = Responsable de magasin · Supply Chain Manager = Responsable de la chaîne logistique · Surgeon = Chirurgien · Systems Administrator = Administrateur système · TV Presenter = Présentateur télé · Taxi Driver = Chauffeur de taxi · Teacher = Enseignant · Teaching Assistant = Assistant d’éducation · Translator/Interpreter = Traducteur-interprète · Truck Driver = Chauffeur routier · Tutor = Tuteur · UX/UI Designer = Designer UX/UI · Veterinarian = Vétérinaire · Video Editor = Monteur vidéo · Waiter/Waitress = Serveur/Serveuse · Warehouse Manager = Responsable d’entrepôt · Warehouse Worker = Manutentionnaire · Welder = Soudeur.

## 6. Local institution names (school terms for the 18 countries)

The player may read French in any country and play any of the 18 countries: the names must be understood *and* true to the country.

1. **Already in the country's own language → keep unchanged** (the source already does): Grundschule, Gymnasium, Abitur, Ausbildung, Fachhochschule, Exzellenzuniversität, École primaire, Collège, Baccalauréat, BTS, IUT, Université, Grande école, Scuola media, Diploma di maturità, Ensino Médio, Bachillerato, ESO, Matura, Technikum, Gymnasieexamen, Lise diploması, Promedio… Same for the French mentions « très bien / bien / assez bien / passable ».
2. **English descriptive names → translate the generic words, keep the local word**: Elementary School (shōgakkō) → École élémentaire (shōgakkō) · Junior High School (chūgakkō) → Collège (chūgakkō) · Senior High School (gaozhong) → Lycée (gaozhong) · Vocational College (gaozhi) → Établissement professionnel (gaozhi) · Junior College → Junior college · Private/National/Regional/Provincial University → Université privée / nationale / régionale / provinciale · Basic Secondary School → École secondaire de base · Professional Junior Bachelor → Bachelor professionnel junior · Government Degree College → Government degree college (établissement public) · Senior Secondary Certificate → Senior Secondary Certificate (diplôme de fin de secondaire).
3. **Proper names and acronyms → unchanged**: Ivy League, Oxbridge / Russell Group, Group of Eight, U15, IIT/IIM/AIIMS, SKY, 985/Double First-Class, BTEC, TAFE, A-levels, ATAR, CSAT, ENEM, NMT, gaokao, EPA 608.
4. **Grade names** (`Country.swift` « what the school-leaving grade is called ») get a plain French frame, keeping the local word: GPA → « Moyenne (GPA) » · Grade average → « Moyenne » · A-level grades → « Notes aux A-levels » · Abitur grade → « Note de l’Abitur » · Bac average → « Moyenne du bac » · Maturità score → « Note de maturità » · NMT score → « Score au NMT » · ENEM score → « Note à l’ENEM » · Gaokao score → « Note au gaokao » · Class 12 percentage → « Pourcentage en Class 12 » · Meritvärde, Nota de admisión, Diploma notu, Promedio keep the local word with « Moyenne » or « Note » in front.
5. **Abitur verbal ratings** (not the French bac ones): very good = très bien · good = bien · satisfactory = satisfaisant · sufficient = suffisant.
6. In a sentence, never article + `%@` for a school term: use the pattern of §1 (« tes résultats scolaires (%@) »).
7. « Still American for now » stays true in French: licence names and school ages are US-based in every country; translate them as the American things they are (§4.8), not as French equivalents.

## 7. Ten model sentences (the translations are in backticks; spaces before `? ! ; :` and inside « » are real U+00A0)

1. **Plural + positional.** Key `This job expects %lld years of experience; you have %@. Working as %@ builds it.`
   one: `Ce poste demande %1$lld an d’expérience ; tu en as %2$@. Travailler comme %3$@ t’en apporte.`
   other: `Ce poste demande %1$lld ans d’expérience ; tu en as %2$@. Travailler comme %3$@ t’en apporte.`
   (`one` keeps the digit; no article before `%3$@`; no-break space before `;`.)
2. **Chance, money, no gender.** `You have a %@ chance to get it. It pays %@.` → `Tu as %1$@ de chances de l’obtenir. Ce poste paie %2$@.` · `You can get this job! It pays %@ a year — %@ more than you earn now.` → `Tu peux décrocher ce poste ! Il paie %1$@ par an — soit %2$@ de plus que ce que tu gagnes aujourd’hui.`
3. **Avoiding agreement.** `You're qualified for %@ — now it's a matter of waiting for a posting.` → `Tu remplis toutes les conditions pour %@ — il ne reste qu’à attendre une offre.` · `🎓 You're in!` → `🎓 Tu as décroché ta place !` · `Congratulations! You completed your %@.` → `Bravo ! Tu as terminé : %@.`
4. **Game terms.** `Each point of %@ fame adds +%@ to your chance, up to +%@.` → `Chaque point de renommée en %1$@ ajoute +%2$@ à tes chances, jusqu’à +%3$@.`
5. **Literal `%%`, emoji, bullet.** `• Your pitch — 💬 Persuader most of all, then vision, talking and leading (+%@ now, up to +40%%)` → `• Ton pitch — 💬 Persuadeur avant tout, puis vision, communication et leadership (+%@ aujourd’hui, jusqu’à +40 %%)`
6. **Titles in guillemets, generic noun before the name.** `You won the %@ and earned the “%@” title!` → `Tu as gagné la compétition « %1$@ » et décroché le titre « %2$@ » !`
7. **Event labels (colon dodges « à / au »).** `Present at %@` → `Présenter : %@` · `Presented at %@` → `Présenté : %@` · `Demo` → `Faire une démo`
8. **Advisor voice and short titles.** `Hi, I'm your career advisor! 👋 Do you already know what job you'd like to do one day — or not yet? Either is fine.` → `Salut, je suis ton conseiller d’orientation ! 👋 Tu sais déjà quel métier tu aimerais faire un jour — ou pas encore ? Les deux, c’est très bien.` · `Not hiring right now` → `Aucune offre pour l’instant` · `Your biggest lever` → `Ton plus gros levier`
9. **Country sentence and typed money.** `Pay, prices and school costs from Germany, in euros.` → `Salaires, prix et frais de scolarité d’Allemagne, en euros.` · `The minimum wage (€13.90 an hour)` → `Le salaire minimum (13,90 € de l’heure)` · `• Scores go to their own German leaderboard.` → `• Les scores vont dans un classement allemand à part.`
10. **Summaries.** Role: `Learns carpentry on site under a master carpenter.` → `Apprend la menuiserie sur chantier auprès d’un maître menuisier.` · venture: `Bootstrap a small studio and ship an original game to players.` → `Lance un petit studio avec peu de moyens et sors un jeu original.`

## 8. Decisions the product owner should confirm

* **A. Degree = « bachelor » (not « licence »)**, because « licence » is used 50+ times as « permit to practise ». Reversing it means renaming every permit.
* **B. « tu » everywhere**, including Vie réelle and adult advisor notes.
* **C. Job titles: generic masculine, first letter capital, also mid-sentence** (« Tu travailles comme Enseignant »). French would normally write « enseignant » mid-sentence; lower-casing in the catalogue would break list rows and headings. Alternative for the developers: store lower case and capitalise where a name stands alone (`Fmt.capitalizingFirst` exists); not assumed here.
* **D. Vocabulary calls**: Fame = « renommée » (alt. « notoriété ») · Business kept as « Business » (alt. « Affaires ») · Venture = « entreprise », sheet « Entreprises » (alt. « Entreprendre ») · Boardroom = « Salle du conseil » · Lead = « référent », Staff = « expert » · slump = « en berne » · seat = « place ».
* **E. Cultural adaptation of named contests** (§4.7) and US licence names kept American (§6.7).
* **F. Code side**: `Country.money` writes the number and symbol with an ordinary space (`"\(Fmt.number(amount)) \(currencySymbol)"`); French needs U+00A0 there (a line break before « € » is a typographic error). `Fmt.signedPercent` writes a hyphen-minus. In fr_CH the system writes « 73% » with no space (our literal `%%` strings use U+00A0 — acceptable).
* **G. Source quirks** a translator should write naturally, not literally: `%@ This field is slump this year: %@.` (read: « in a slump ») ; `Leading as %@ %@` (the two `%@` are an emoji and a job title: « Diriger comme 💼 Directeur général » is fine, or reword around them); `'%@ Not this time'`/`'%@ It worked!'` begin with an emoji placeholder; keys `field.education` and `activity.science` show an identifier, not English.
