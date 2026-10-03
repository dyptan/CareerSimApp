# CareerSimApp — Ukrainian (uk) glossary and style guide

Binding for every translator of the `uk` edition (tables `Localizable` and `Catalogue`). Where this file and your taste differ, this file wins. If you need a recurring term that is missing, use the most standard Ukrainian dictionary term and list it in your hand-back so the lead can add it here. This file fixes terms, not sentences: translate for meaning, not word by word.

## 1. Voice and register

* **Reader.** Children from 7 (mode «Спрощений»), teens and adults (mode «Реальне життя»), sometimes a parent reading along. Tone: a friendly older sibling or school coach: warm, concrete, encouraging. Never bureaucratic, never babyish, never sarcastic.
* **Address: informal `ти`** throughout (ти, тебе, тобі, твій, твоя, твої), lower case mid-sentence, no reverential capitals. Never `ви`/«Вам». The advisor also says `ти` (and `я`, see §4).
* **Imperative vs infinitive.** Sentences addressed to the player use the singular imperative: Обери, Спробуй, Відкрий, Не здавайся. Buttons, footer/tab names, card titles and section headings use the infinitive or a noun: Подати заявку, Почати спочатку, Пропустити, Освіта. Never the plural imperative («Оберіть»).
* **Sentences.** Short, active, everyday. Keep the English sentence boundaries, punctuation (`!` `?` `…`) and rhetorical shape; do not add or drop exclamation marks. Prefer plain words: зарплата (not «заробітна плата»), робота, вступити, брати участь, бо / тому що / тож. Avoid piles of verbal nouns (-ння, -ння) and officialese. Third-person catalogue summaries copy the English style: present tense, no subject («Проєктує літаки…»).
* **Emoji, bullets, symbols.** Copy emoji, `•`, `✓`, `←`, `→`, `×`, `÷`, `≈`, `ⓘ`, `🎲` exactly as in the source and in the same position, with the same single space after a leading emoji. Never add, remove, swap or "translate" an emoji. Keep every `\n` / `\n\n`, and any leading or trailing space of the source (e.g. `" (your %lld years …)"`).
* **Length.** Ukrainian runs 15–25 % longer than English. Buttons and chips: at most ~1.5× the English length. Shorten by choosing the infinitive, dropping filler words, and using «р.» where English uses «yr/yrs» (§3). Never shorten by dropping information, a placeholder or an emoji.
* **Words that name UI.** When prose points at a button, tab or sheet (Skip, Score, Progress, Advice, Education, Activities, Jobs, Events, Projects, Ventures, Boardroom, Take, Apply, Launch…), use exactly the label from §6 and wrap it in «…»: «торкнись синьої кнопки «Пропустити»». Say «розділ «Освіта»» for a sheet, «кнопка «Подати заявку»» for a button. "Tap" = «торкнись».
* **Skill names are playful titles** (Винахідник, Детектив…, §6). In prose they stay in quotes as names: «навичка «Детектив»».
* **Ukrainian, not Russian.** Orthography: Правопис 2019 (проєкт, не проект; Європа; ґ where standard). Typical russianisms to avoid: вірно → правильно; приймати участь → брати участь; на протязі → протягом; слідуючий → наступний; являється → є; в залежності від → залежно від; відноситься → належить / стосується; співпадати → збігатися; міроприємство → захід; оплата труда → оплата праці. Letters ы э ъ ё never appear; і ї є ґ always do where needed.

## 2. Typography and orthography

* **Quotation marks: «…»**, nested „…“. Convert English `“…”`, `"…"`, `‘…’`. Names, titles, skills, UI labels and placeholders that hold names are quoted when needed for case (§5). In this guide an example is wrapped in «…» only for display, so a name inside it looks nested; in a translation the sentence itself carries no outer quotes, and a name inside it takes plain «…».
* **Apostrophe: ʼ U+02BC** (MODIFIER LETTER APOSTROPHE, the letter-class apostrophe recommended for Ukrainian; it never splits a word at a line break) in every Ukrainian word: карʼєра, мʼякий, звʼязки, здоровʼя, пʼять, обʼєкт, зʼїзд, імʼя. Never U+0027 `'` or U+2019 `’` between Cyrillic letters. English possessives in Latin words you keep (e.g. "Driver's License" as a quoted name) stay as in the source. Self-check: no match for `(?<=[а-яіїєґ])['’](?=[яюєї])`.
* **Dashes.** Em dash with spaces, the space before it a no-break space: `слово — слово` (U+00A0 U+2014 U+0020). En dash without spaces for ranges: `6–10`, `1–3`. Hyphen for compounds: інженер-програміст, 3D-художник, UX/UI-дизайнер, Су-шеф.
* **Ellipsis** `…` (one character), as in the source. **Colon:** the text after it starts lower case unless it is a name, a title or a placeholder.
* **Capitalisation: sentence case everywhere.** English Title Case in buttons, headings, job titles, events, contests becomes «Подати заявку», «Старший вчитель», «Технологічний саміт». Capital only for the first word and proper nouns (Game Center, Apple Intelligence, Career Sim, країни, НМТ). Days/months/languages/nationalities are lower case.
* **Lists** with commas; «і / й / та» sparingly; `or` = «або». No serial comma. Lists built by code (`Fmt.list`) arrive already joined: «Здоровʼя або Наука».
* **Cyrillic only.** Never mix Latin look-alikes into Cyrillic words (Latin i, o, a, e, c, p, x, y, T, H, K, M, B, I): «Україна» must use Cyrillic і (U+0456). Abbreviation **ІТ** (information technology) is written in Cyrillic І and Т; **ТБ** for television; **ШІ** for AI; **США**, **ЄС**. Latin is kept for: CEO, CTO, CMO, HR, QA, UX/UI, 3D, SaaS, MBA, PhD, GPA, SAT, NHS, RN, LPN, NP, CNA, EMT, CPA, CDL, ATP, EPA 608, A&P, HVAC and similar international or US-credential acronyms.
* **Typographic spaces.** No-break space (U+00A0) between a number and its unit or abbreviation (`%lld р.`, `5 км`), before an em dash, and inside amounts you write yourself (`8 647 ₴`).

## 3. Numbers, money, units, abbreviations

* **Numbers arrive pre-formatted** as `%@` (Ukrainian style: `45 000` with a no-break space, `3,5`, `73%` with no space, `+20%`, `-5%`). Never reformat them and never spell them out when the source has a placeholder or digits. Numbers written as **words in the source** ("three to seven years", "ten to twenty") become words in Ukrainian, correctly declined («від трьох до семи років»).
* **Percent.** A placeholder already contains `%`. A literal percent sign in a key is written `%%` and must be kept as `%%` in the translation, with no space before it: `+40%%`. Plain digits in the source (`1,500`, `5K`, `170`, `2.5×`) are rewritten in Ukrainian style: `1 500`, `5 км`, `170`, `2,5×`.
* **Money.** Amounts built by code (`player.money`) arrive as `45 000 ₴`: write the sentence around them. Currency amounts **typed inside a key** (`₴8,647 a month`, `€13.90 an hour`, `C$18.15`, `¥1,121`, `£9,790`, `4,806 zł`, `26,626 kr`, `₺33,030`, `₩10,320`, `R$1,621`, `MX$315.04`, `CN¥2,740`, `₹18,456`, `A$26.44`) are rewritten as number + no-break space + the same symbol or code: `8 647 ₴`, `13,90 €`, `18,15 C$`, `1 121 ¥`, `9 790 £`, `4 806 zł`, `26 626 kr`, `33 030 ₺`, `10 320 ₩`, `1 621 R$`, `315,04 MX$`, `2 740 CN¥`, `18 456 ₹`, `26,44 A$`. Rates: «an hour» → «за годину», «a day» → «на день», «a month» → «на місяць», «a year» → «на рік»; `/yr` → `/рік`.
* **Units.** Metric: miles → km («26.2 miles» → «42,2 км»; `5K` → «5 км»). Keep named US facts (FAA 1,500 hours) but write them in Ukrainian style.
* **Abbreviations.** `yr/yrs`, `y.o.` → **«р.»** (invariant, one form in all four plural branches, no-break space before it: `%lld р.`). `exp.` → «досвід» (`%lld yr exp.` → «досвід: %lld р.»). Where English spells **year(s)** in full, Ukrainian writes рік / роки / років in full (§5). `e.g.` → «наприклад», `etc.` → «тощо», `i.e.` → «тобто», `vs` → «проти». `US` → «США», `UK` → «Велика Британія» (country) / «британський». `%` stays `%`.
* **Ages and stages.** «Ages 7+» → «від 7 років» (literal 7, no declension problem); «Teens & up» → «підлітки й старші»; «Age %lld» → «Вік: %lld».

## 4. Gender policy

The player's gender is unknown. Ukrainian marks gender in past-tense verbs, short adjectives and participles, so:

* **Never address the player with a past-tense verb or an adjective that has a gender** (не «ти здобув/здобула», «готовий/готова», «щасливий»). Use: present tense, the impersonal passive in **-но/-то**, dative constructions («тобі вдалося»), noun phrases with a colon, or the accusative («тебе прийнято»). Do the same for the advisor's first person: **«я» only in present or future** («Я підкажу…», «Я запропоную…»); if the English is "I couldn't find…", rewrite impersonally («Такої роботи не знайдено»). The advisor is grammatically «радник»; if a gendered first-person form is truly unavoidable, use the masculine and tell the lead.
* Patterns (EN → UK): You earned X → «Здобуто: X» / «Ти отримуєш X»; You've reached the top → «Ти на вершині!»; You made it! → «Тобі вдалося!»; You're in! → «Тебе прийнято!»; You've been promoted → «Тебе підвищено»; You were laid off → «Тебе скорочено»; You won X → «Перемога: X»; You've tried X → «Вже спробовано: X»; You're ready to apply → «Можна подавати заявку»; You're qualified for X → «Ти відповідаєш вимогам: X»; You're working as X → «Ти працюєш на посаді «X»»; You're 25 → «Тобі 25»; Congratulations! You finished X → «Вітаємо! Закінчено: X».
* **Job titles and earned titles:** the dictionary **masculine form is the generic default** (Вчитель, Пілот, Переможець, Чемпіон, Призер, Лауреат, Медаліст). **No feminitives** for ordinary titles (they would double every title and every sentence). Exceptions, kept as the established word: **медсестра** family and **покоївка** (feminine in common use); and where the **English source offers both** («Waiter/Waitress» → «Офіціант/офіціантка», «Hairdresser/Barber» → «Перукар/барбер»). Wrapping a title as a position name in quotes after «посаду» (§5) also avoids implying the player's gender.
* Never put an adjective, participle or past verb in a sentence that must agree with a placeholder (a job title may be masculine or feminine); attach it to a fixed noun instead («посада «%@» відкрита», not «%@ відкритий»).

## 5. Placeholders, plurals, case

### 5.1 Placeholders

* Keep `%@` and `%lld` exactly (lower-case `ll`, no spaces, never `%d`, `%s`, `%ld`). Do not add, drop or retype placeholders; do not translate anything inside them. A literal percent is `%%`.
* **Two or more placeholders → positional in every translation**, numbered by their order **in the English key**: `%1$@ … %2$lld`, even if the order does not change. A string with one placeholder may use plain `%@`/`%lld`. Do not mix positional and plain in one string. In a plural key, every branch uses the same positional numbers.
* Placeholders for **names** (job titles, categories, fields, industries, skills, activities, countries, schools, qualifications) always hold the **nominative, capitalised dictionary form**. You cannot decline them, lower-case them or make anything agree with them (§5.3). Placeholders for numbers are strings: you cannot make a noun agree with `%@` (§5.4).
* Language names from the system arrive lower case and feminine («українська», «німецька»).
* Literal words in the key (not placeholders) are ordinary text: decline them freely («Business fame» → «слава в бізнесі»).

### 5.2 Plurals (keys marked as plural: an object with `one`, `few`, `many`, `other`)

| Form | When (integer n) | Examples |
|---|---|---|
| one | n mod 10 = 1 and n mod 100 ≠ 11 | 1, 21, 31, 101 |
| few | n mod 10 in 2–4 and n mod 100 not in 12–14 | 2, 3, 4, 22, 24, 33 |
| many | n mod 10 = 0 or 5–9, or n mod 100 in 11–14 | 0, 5–20, 25–30, 111 |
| other | fractions only (never happens: counts are `Int`) | write the **same text as `many`** |

* **All four forms are required** (`one`, `few`, `many`, `other`). **Every branch keeps the count placeholder** (`%lld`) and every other placeholder: `one` also means 21 and 101, so «один рік» in words is wrong; write «%lld рік» («21 рік»). If the sentence reads better without the figure, restructure so the figure stays; do not drop `%lld` from a branch even where a checker would allow it (the English forms keep it in every branch today). This overrides the generic note in `Tools/i18n/TRANSLATING.md` that lets a plural branch leave out the number: for Ukrainian it never may.
* Words after the count (nominative/accusative): рік / роки / років; хід / ходи / ходів; раз / рази / разів; посада / посади / посад; галузь / галузі / галузей; рівень / рівні / рівнів. **Genitive** after «із, для, до, від, без, протягом…»: рік → **року** / років / років; хід → ходу / ходів / ходів; рівень → рівня / рівнів / рівнів; раз → разу / разів / разів. Adjectives, possessives and verbs agree with the count: «твій %lld рік» / «твої %lld роки» / «твої %lld років».
* Examples: «Keep going for %lld more years.» → one «Продовжуй ще %lld рік.» · few «Продовжуй ще %lld роки.» · many/other «Продовжуй ще %lld років.» — «%lld of %lld» with genitive: «із %2$lld року / років / років».
* **Non-plural keys that contain `%lld`** (no variants): the sentence must read correctly for every number. Do not put a noun that needs agreement after it. Restructure («Вік: %lld», «Бали: %1$lld із %2$lld», «Результат: … ÷ %lld р.») or use the invariant «р.».
* **Two numbers, one plural:** only the `%lld` drives the forms; the other number is a `%@` string. Never write a noun after a `%@` number («%@ points», «%@ years») — put the noun before it («бали навичок: %2$@») or use a unit symbol.

### 5.3 Case: building sentences around a nominative placeholder

A name placeholder cannot be declined. Use one of these **standard restructurings** (listed by preference):

1. **Head noun + quotes** — the quotes freeze the nominative and the head noun carries the case: «на посаду «%@»», «у сфері «%@»», «у галузі «%@»», «навичку «%@»», «заклад «%@»», «за напрямом «%@»», «у країні «%@»», «на етапі «%@»», «за професією «%@»», «програму «%@»».
2. **Label + colon / dash:** «Посада: %@», «Сфера: %@», «Навчання: %@», «%@ — …».
3. **Predicative dash (nominative):** «Ти — %@», «Мета: %@».
4. **Subject position:** start with the placeholder: «%@ платить %@.» Prefer ««%@» платить…» with quotes.
5. **Parenthesis:** «… (%@)».
6. **Qualification phrases** («a bachelor's degree in %@», «a school diploma»): the head word is a **masculine inanimate** noun (ступінь, диплом, атестат), so accusative = nominative and it works after «Здобудь…», «Тобі знадобиться…», «Ще бракує: …». The field/list goes after «за напрямом «…»».
7. **Lists** of fields («Health or Science»): put the whole list inside one pair of quotes after a head noun, or after a colon.
8. **Genitive needed** («years of %@», «years in %@»): «роки роботи у сфері «%@»», «стаж за професією «%@»», or a colon form.

Common frames (EN → UK):

| English frame | Ukrainian frame |
|---|---|
| in/for/at %@ (field) | у сфері «%@» |
| in %@ (industry) | у галузі «%@» |
| as %@ / the %@ job (role) | на посаді «%@» / за професією «%@» · посада «%@» |
| %@ fame (field) | слава у сфері «%@» (label: «Слава: %@») |
| Network in %@ | Звʼязки у сфері «%@» |
| A degree in %@ | Ступінь за напрямом «%@» |
| Training: %@ / Study for: %@ | Курс: %@ / Навчання: %@ |
| the %@ ladder | карʼєрні сходи «%@» |
| "%@" title | титул «%@» |
| Leading as 💼 %@ | Керуєш: 💼 %@ |
| You start as %@ on %@ a year | Стартуєш на посаді «%1$@» із зарплатою %2$@ на рік |
| %@ %@ is booming | %1$@ %2$@ — цього року бум |
| +%@ %@ fame | Слава (%2$@): +%1$@ |
| +%lld network in %@ | Звʼязки (%2$@): +%1$lld |
| %@ of %@ points | Бали: %1$@ із %2$@ |

### 5.4 Other traps

* **Prepositions before a placeholder:** avoid a bare «у/в, з/із/зі, і/й» before a name placeholder (euphony depends on the unknown next letter); put a fixed noun in between (frames above). Before digits `з`/`у` are fine.
* **Agreement with a placeholder** is forbidden (§4). **Articles** do not exist; do not add «цей/ця» to mimic "the".
* **One key, several uses.** A short key such as «Take», «Apply», «Field» is reused in several screens: translate the word that works everywhere (§6) and read the `_context`.
* **Keys that are ids** (`field.education`, `activity.science`) are translated from their comment, not from their text.
* **Nothing to translate** (only placeholders, emoji, a symbol, «OK», an acronym such as «GPA»): copy the key unchanged.
* **Catalogue strings** (`job.title.*`, `job.base.*`, `job.ladder.*`, `job.rung.*`, `job.summary.*`) are plain strings (no plurals, no placeholders), non-empty, sentence case.

## 6. Glossary (English → Ukrainian)

### 6.1 Game concepts
| English | Українська | Note |
|---|---|---|
| Career Sim (app) | Career Sim | brand, keep Latin |
| Simplified (mode) | Спрощений | prose: «у спрощеному режимі» |
| Real Life (mode) | Реальне життя | prose: «у режимі «Реальне життя»» |
| mode / Game mode | режим / Режим гри | |
| tutorial (mode) | навчальний режим | |
| One turn = one year | Один хід = один рік | turn = хід |
| Skip (button) | Пропустити | «Skip a year» = «Пропустити рік» |
| Age | Вік | |
| Score | Результат | net worth ÷ age; «Твій результат» |
| Progress (Simplified) | Прогрес | |
| Leaderboard | Таблиця лідерів | Apple's term |
| Game Center | Game Center | keep |
| Advisor / career advisor | Радник / карʼєрний радник | masc., persona |
| Advice (button, noun) | Поради | «standard advice» = «стандартні поради» |
| Fame | Слава | f., gen. слави; «famous» → відомий; fields: §6.4 |
| Network (contacts) | Звʼязки | plural only |
| Skills (the 15 soft skills) | Навички | |
| Soft skills | Мʼякі навички | «Soft-skill match» = «Збіг мʼяких навичок» |
| Hard skills / credentials | Кваліфікація | schooling + licences + courses |
| Hard requirements | Обовʼязкові вимоги | |
| Requirements | Вимоги | |
| Savings | Заощадження | |
| Net worth | Чистий капітал | what you own minus what you owe |
| Money earned | Зароблено | «Зароблено: %@» |
| Gross income | Дохід до вирахувань | |
| Banked from pay | Відкладено із зарплати | |
| Living costs | Витрати на життя | rent and food: «оренда й харчування» |
| Salary / pay | Зарплата | |
| Minimum wage | Мінімальна зарплата | |
| Salary ask / your ask | Бажана зарплата | «Ask for a salary» = «Назвати зарплату» |
| Offer (job) | Пропозиція | «Offer accepted!» = «Пропозицію прийнято!» |
| Merit raise | Підвищення зарплати за заслуги | |
| Promotion / promoted | Підвищення / підвищено | not for pay only |
| Layoff / laid off | Скорочення / скорочено | severance = вихідна допомога |
| Hire / hired / get hired | Прийняти на роботу / прийнято / отримати роботу | «Chance to be hired» = «Шанс отримати роботу» |
| Application / Apply | Заявка / Подати заявку | for jobs and schools |
| Posting / openings | Вакансія / вакансії | «Nobody is posting» = «вакансій немає» |
| Job | Робота | footer «Jobs» = «Робота» |
| Role (a post on a ladder) | Посада | «%lld roles» = посада/посади/посад |
| Profession | Професія | |
| Career ladder | Карʼєрні сходи | |
| Rung | Щабель | |
| Seniority | Рівень посади | |
| Standard (seniority) | Стандартний | |
| Experience | Досвід | «years of experience» = «років досвіду» |
| Chance / odds | Шанс / шанси | not «ймовірність» |
| Points (stats, skill points) | Бали | бал / бали / балів; «percentage points» = «відсоткові пункти» |
| Long shot | Малоймовірний варіант | |
| Gamble | Ризик | |
| Seat (top post: board, partner) | Крісло | «the seat chance» = «шанс отримати крісло» |
| Lever (advisor) | Важіль | |
| Door (metaphor) | Двері | |
| Narrow path | Вузька стежка | |
| Track record (founder) | Здобутки (засновника) | |
| Founder | Засновник | |
| Venture / Ventures | Бізнес | footer & sheet «Бізнес»; «свій бізнес» in prose |
| Venture loan | Кредит на бізнес | |
| Startup | Стартап | |
| Project / Side hustle | Проєкт | names are infinitives («Вести подкаст») |
| Investment round | Інвестиційний раунд | |
| Investor | Інвестор | |
| Stake / shares | Частка / акції | |
| Exit (sale) | Вихід із бізнесу | |
| Breakout | Прорив | |
| Pitch | Пітч | |
| Boardroom | Правління | footer & sheet |
| Executive decision | Рішення керівника | |
| Asking price | Бажана ціна | |
| Contest / competition | Змагання | creative: конкурс |
| Event (summit, expo, …) | Захід | footer «Events» = «Заходи» |
| Trophy / Title (won) | Трофей / Титул | |
| Accolade / Award / Prize | Відзнака / Нагорода / Приз | |
| Activities (footer) | Заняття | single activity: заняття |
| Practise | Займатися / тренуватися | sport: тренуватися |
| Take (button on a row) | Обрати | |
| Launch (a business) | Запустити | |
| Retire / career over | Вихід на пенсію / Карʼєру завершено | |
| Game Over | Гру завершено | |
| Keep playing | Грати далі | |
| Start over / Restart | Почати спочатку / Перезапустити | |
| Close / OK / Send / Thanks! | Закрити / OK / Надіслати / Дякую! | |
| Let's go! 🚀 / How to play | Поїхали! 🚀 / Як грати | |
| Thinking… | Думаю… | present, no gender |

### 6.2 Economy and industry climate
| English | Українська | Note |
|---|---|---|
| Economy / the economy | Економіка | |
| Industry (sector) | Галузь | |
| Field / category (of work) | Сфера | |
| Booming | Бум | sentence: «переживає бум» |
| Growing | Зростання | «зростає» |
| Steady | Стабільно | sentence: «без змін» |
| Slowing | Сповільнення | «сповільнюється» |
| Slump | Спад | «у спаді» |
| Declared downturn / recession | Оголошений спад / рецесія | |
| Job market / Market median | Ринок праці / Медіана ринку | |
| Demand | Попит | |

### 6.3 Education
| English | Українська | Note |
|---|---|---|
| School (grades 1–11) | Школа | |
| School (any institution you apply to) | Навчальний заклад / заклад | never «школа» for a university |
| School level | Рівень освіти | |
| Schooling / education (level) | Освіта | |
| Tier (of schools) | Категорія закладу | |
| Level (stage name) | Рівень | |
| Prestige | Престиж | |
| Primary School | Початкова школа | all countries |
| Middle School | Середня школа | US-style, ~11–13 |
| Basic Secondary School | Базова середня школа | Ukraine |
| High School / High School Diploma | Старша школа / Атестат про середню освіту | |
| Vocational Diploma | Фаховий диплом | |
| Professional Junior Bachelor | Фаховий молодший бакалавр | Ukraine |
| Atestat | Атестат | Ukraine |
| NMT score | Бал НМТ | National Multisubject Test |
| Community College | Громадський коледж | US, open admission |
| State University | Державний університет | |
| Elite / Ivy League | Елітний / Ліга плюща | |
| College (Ukraine, Canada) | Коледж | |
| University / Top university | Університет / Провідний університет | Ukraine's top tier |
| Tuition | Плата за навчання | |
| School costs | Вартість навчання | |
| Student loan | Студентський кредит | accrues; paid after study |
| Degree | Ступінь | |
| Bachelor / Master | Бакалавр / Магістр | |
| Doctorate / Doctoral Degree | Докторський ступінь | PhD = доктор філософії |
| Doctorate+ (post-doc) | Постдок | |
| Diploma | Диплом | |
| Certificate | Сертифікат | |
| Licence / License | Ліцензія | driver's: «посвідчення водія» |
| Course / Training | Курс | «Trainings:» = «Курси:» |
| Credentials | Кваліфікації | |
| Certificates & licences | Сертифікати та ліцензії | |
| Grades / Grade average | Оцінки / Середній бал | label «GPA» = «Середній бал (GPA)»; «Grade average (hyōtei)» = «Середній бал (hyōtei)» |
| Admission / chance of admission | Вступ / шанс вступити | |
| accepted (school) | зараховано | «Тебе зараховано» |
| Programme | Програма | |
| Field of study | Напрям навчання | |
| EQF | ЄРК | Європейська рамка кваліфікацій |
| Exam / Board exam | Іспит / Ліцензійний іспит | |
| Residency / Board certification | Інтернатура / Сертифікація спеціаліста | US medical; keep «(Board Certification)» |
| Apprenticeship | Навчання на виробництві | |
| Student (occupation panel) | Навчання | not «учень» (may be university) |
| Student council | Учнівська рада | «Student Body President» = «Голова учнівської ради» |
| Class Representative | Староста класу | |

### 6.4 Fields of work, fame, study, industries
Fame fields: Entertainment = Розваги; Technology = Технології; Arts = Мистецтво; Business = Бізнес; Science = Наука; 🌐 General = Загальна.
Job categories: Engineering = Інженерія; Show Business = Шоубізнес; Public Services = Громадські служби; Health = Здоровʼя; Technology = Технології; Education = Освіта; Agriculture = Сільське господарство; Design = Дизайн; Law = Право; Business = Бізнес; Construction = Будівництво; Retail = Роздрібна торгівля; Science = Наука; Hospitality = Гостинність; Personal Services = Особисті послуги; Manufacturing = Виробництво; Entrepreneurship = Підприємництво; Transportation = Транспорт; Administration = Адміністрування.
Work setting (filter header «Kind of work» = «Яка робота»; all options agree with «робота»): Any = Будь-яка; Office = Офісна; Field (hands-on) = Практична; People-facing = З людьми.
Industries: Software & Internet = Програмне забезпечення та інтернет; Computing Hardware = Компʼютерна техніка; Telecoms = Телекомунікації; Automotive = Автомобільна промисловість; Aerospace & Defence = Авіакосмічна галузь і оборона; Energy & Utilities = Енергетика й комунальні послуги; Banking & Finance = Банківська справа та фінанси; Healthcare = Охорона здоровʼя; Pharma & Biotech = Фармацевтика й біотехнології; Government & Public Sector = Уряд і державний сектор; Retail & Consumer = Торгівля й споживчі товари; Hospitality & Tourism = Гостинність і туризм; Media & Entertainment = Медіа та розваги; Construction & Property = Будівництво й нерухомість; Agriculture & Food = Сільське господарство й харчова промисловість; Transport & Logistics = Транспорт і логістика; Industrial Manufacturing = Промислове виробництво; Professional Services = Професійні послуги.
Fields of study (degree): Business = Бізнес; Engineering = Інженерія; Health = Здоровʼя; Arts = Мистецтво; Science = Природничі науки; Technology (IT) = Інформаційні технології; Education (`field.education`) = Педагогіка; Sports = Спорт; Agriculture = Сільське господарство; Law = Право; Design = Дизайн; Service = Сервіс.
**Two meanings:** *Science* = «Наука» (field of work/fame/industry) · «Природничі науки» (degree field) · «Природознавство» (school subject, `activity.science`). *Education* = «Освіта» (screen, footer, job field, industry) · «Педагогіка» (degree field `field.education`). *Pilot* = «Пілот» (job) · «Приватний пілот» (licence, short name; «Commercial Pilot» = «Комерційний пілот»). *Present* = «Презентувати» (event verb; not «теперішній»). *Field* = «Практична» (work setting) · «Сфера» (job field) · «Напрям навчання» (field of study). *Arts* = «Мистецтво» (fame field, degree field). *Service* = «Сервіс» (degree) · «послуги» (job category).

### 6.5 Soft skills (the 15 abilities; playful titles, masculine nouns)
Inventor = Винахідник · Creator = Творець · Influencer = Комунікатор (it is about talking, writing, presenting) · Persuader = Переконувач · Leader = Лідер · Visionary = Візіонер · Detective = Детектив · Fixer = Умілець · Navigator = Навігатор · Athlete = Атлет · Zen = Дзен · Empath = Емпат · Teamplayer = Командний гравець · Planner = Планувальник · Champion = Чемпіон. Fallback «Skill» = «Навичка». Labels in the descriptions: Jobs = Професії, Schools = Навчання, Grades = Оцінки, Contests = Змагання, Build it = Розвивай, Promotions = Підвищення, Boardroom = Правління, Ventures = Бізнес, Projects = Проєкти.

### 6.6 Seniority rungs (`job.rung.*`; used inside titles as masculine nominative adjectives)
Junior = Молодший · Senior = Старший · Lead = Провідний · Staff = Провідний (never on the same ladder as Lead) · Principal = Головний · Head (Head Chef) = Шеф-кухар · Sous = Су-шеф · Executive (Chef) = Бренд-шеф · Apprentice = Учень (titles «Учень електрика/сантехніка/теслі») · Master = Майстер (titles «Майстер-електрик/-сантехнік/-тесля») · Resident = Інтерн · Charge (nurse) = Координатор · Amateur = Аматор · Professional = Професіонал · Elite = Еліта · Standard (bare role) = Стандартний. In a title the adjective is followed by the lower-cased base title, and agrees with its gender («Старший вчитель», «Старша медсестра»).

### 6.7 Activities, sports, subjects
Sports = Спорт · Arts & Minds = Творчість і розум · Study = Навчання · Beginner/Intermediate/Advanced/Expert = Початківець / Середній рівень / Просунутий / Експерт · Running = Біг · Swimming = Плавання · Cycling = Велоспорт · Soccer = Футбол · Basketball = Баскетбол · Tennis = Теніс · Martial Arts = Бойові мистецтва · Gymnastics = Гімнастика · Skateboarding & BMX = Скейтборд і BMX · E-Sports = Кіберспорт · Music = Музика · Drawing & Painting = Малювання й живопис · Photography = Фотографія · Cooking = Кулінарія · Dance = Танці · Coding = Програмування · Chess = Шахи · Debate = Дебати · Mathematics = Математика · Reading & Writing = Читання й письмо · History & Geography = Історія й географія · Foreign Languages = Іноземні мови · kinds of contest: Athletic = Спортивні, E-Sports = Кіберспорт, Creative = Творчі, Mind = Інтелектуальні, Academic = Академічні.

### 6.8 Contest vocabulary (names are translated; pattern «Дитячий кубок», «Шкільний шаховий турнір»)
Cup = Кубок · League = Ліга · Championship = Чемпіонат · Tournament = Турнір · Olympiad = Олімпіада · Competition = Змагання · Contest/Prize (arts) = Конкурс/Премія · Award = Нагорода · Fair (science) = Виставка · Bee/Bowl = Вікторина · Hackathon = Хакатон · Recital = Концерт · Showcase = Показові виступи · Bake-Off = Конкурс випічки · Cook-Off = Кулінарний конкурс · Open = Відкритий турнір · Finals = Фінал · Marathon = Марафон · Race = Забіг · Kids' = Дитячий · Junior = Юніорський · Youth = Молодіжний · National = Національний · Regional = Регіональний · International = Міжнародний · Winner = Переможець · Champion = Чемпіон · Medalist = Призер · Prizewinner = Призер · Laureate = Лауреат · Star = Зірка · Grandmaster = Гросмейстер · «Math Kangaroo» = «Математичний кенгуру».

### 6.9 Event buttons (verb → done-state; both avoid gendered past forms)
| EN verb → past | Ukrainian verb → state | «at %@» form |
|---|---|---|
| Present → Presented | Презентувати → Презентовано | Презентувати: %@ → Презентовано: %@ |
| Perform → Performed | Виступити → Виступ відбувся | Виступити: %@ → Виступ відбувся: %@ |
| Appear → Appeared | Потрапити в ефір → Ефір відбувся | … : %@ |
| Speak → Spoke | Прочитати доповідь → Доповідь прочитано | … : %@ |
| Compete → Competed | Змагатися → Змагання пройдено | … : %@ |
| Demo → Demoed | Показати → Показано | … : %@ |

Events: Summit = Саміт · Expo/Show = Експо / Виставка · Conference = Конференція · Forum = Форум · Symposium = Симпозіум · Congress = Конгрес · Convention = Зʼїзд · Festival = Фестиваль · Pitch Night = Вечір пітчів.

### 6.10 Countries (names, adjectives for «their own … leaderboard», currencies)
| Country | Назва | Adjective (fem., for «таблиця лідерів») | Currency (as written in `Pay … in …`) |
|---|---|---|---|
| United States | США | американська | долари США |
| Germany | Німеччина | німецька | євро |
| Canada | Канада | канадська | канадські долари |
| United Kingdom | Велика Британія | британська | фунти стерлінгів |
| France | Франція | французька | євро |
| Italy | Італія | італійська | євро |
| Japan | Японія | японська | єни |
| Ukraine | Україна | українська | гривні |
| Australia | Австралія | австралійська | австралійські долари |
| Brazil | Бразилія | бразильська | реали |
| China | Китай | китайська | юані |
| India | Індія | індійська | рупії |
| Mexico | Мексика | мексиканська | мексиканські песо |
| Poland | Польща | польська | злоті |
| Spain | Іспанія | іспанська | євро |
| Sweden | Швеція | шведська | шведські крони |
| Turkey | Туреччина | турецька | турецькі ліри |
| South Korea | Південна Корея | південнокорейська | вони |

### 6.11 Recurring phrases (use the same Ukrainian everywhere)
| English | Українська |
|---|---|
| every / each year | щороку |
| this year / last year / next year | цього року / минулого року / наступного року |
| right now / for now | зараз / поки що |
| try again (next year) | спробуй ще раз (наступного року) |
| check back / check again next year | заглянь знову наступного року |
| keep going / keep building your skills | продовжуй / і далі розвивай навички |
| a long shot | малоймовірний варіант |
| the job asks for (needs) X | для цієї роботи потрібно X (nominative); «вимагає» + genitive |
| it pays X a year | зарплата — X на рік / платять X на рік |
| 🔒 Not yet / Not open to you yet | 🔒 Ще недоступно |
| ✓ all set / missing / still missing | ✓ усе гаразд / бракує / ще бракує |
| required / preferred (helpful) / optional | обовʼязково / бажано / за бажанням |
| work experience | досвід роботи |
| own company / own business | власна компанія / власний бізнес |
| a few people / few get it | небагато людей / це вдається лише деяким |
| make your name / get known | здобути славу / про тебе дізнаються |
| hit or miss | вдасться чи ні |
| show off (blurbs) | демонструвати / показувати |
| a hit / viral | хіт / вірусний |
| counts double / counts half | враховується вдвічі / наполовину |
| cap / ceiling / capped at | ліміт / обмежено до |
| goes up / goes down / drops | зростає / знижується / падає |
| helps the most | допомагає найбільше |
| (a company) folds / takes off | закривається / злітає |
| go on stage | вийти на сцену |
| Open [sheet] | Відкрити розділ «[sheet]» |
| See job listings | Переглянути вакансії |
| Compare schools | Порівняти заклади |

## 7. Job-title policy

* **Catalogue titles are translated as full titles**, but all chunks must give the same word to the same role. Use the **canonical base titles below** in `job.base.*`, `job.title.*`, `job.ladder.*` and inside `job.summary.*` (when a summary names another role).
* **Form:** the established Ukrainian profession name, masculine generic, nominative singular, sentence case, no article, no bracketed gloss unless the table gives one. International job names that Ukrainians use as loan words stay (UX/UI-дизайнер, геймдизайнер, SMM-менеджер, арт-директор, бізнес-аналітик). CEO/CTO/CMO get the Ukrainian title + Latin abbreviation in brackets.
* **Seniority:** `rung adjective + lower-cased base title` with the §6.6 word, identical in every title («Молодший бухгалтер», «Старший бухгалтер», «Провідний лаборант», «Головний науковий співробітник»). `Staff` and `Lead` both → «Провідний» (they never meet on one ladder). Special titles: «Executive Chef» = «Бренд-шеф», «Head Chef» = «Шеф-кухар», «Sous Chef» = «Су-шеф», «Charge Registered Nurse» = «Медсестра-координатор», «Resident Physician» = «Лікар-інтерн», «Amateur/Professional/Elite Player» = «Гравець-аматор / Професійний гравець / Елітний гравець».
* **Slash titles** keep both parts when they are different jobs or genders: «Waiter/Waitress» = «Офіціант/офіціантка»; «Hairdresser/Barber» = «Перукар/барбер»; «Beautician/Cosmetologist» = «Косметолог»; «Janitor/Cleaner» = «Прибиральник»; «Translator/Interpreter» = «Перекладач (письмовий і усний)»; «Software Tester/QA» = «Тестувальник програм (QA)»; «Stocker/Order Filler» = «Комплектувальник замовлень».
* **Foreign education systems.** Native-language names of school types, qualifications, exams and institutions of other countries (Grundschule, Abitur, Ausbildung, Fachhochschule, Baccalauréat, Collège, Grande école, Scuola media, Primaria, Bachillerato, Matura, Technikum, İlkokul, Lise diploması, Gaokao …) and their acronyms (A-levels, BTEC, BTS, IUT, ESO, FP, TAFE, ATAR, ENEM, CSAT, SAT, GPA, KTH, UW / UJ / SGH, IIT / IIM / AIIMS, SKY, U15, Group of Eight, Oxbridge / Russell Group) are proper names: **keep them exactly as in the source** (Latin script, diacritics). Translate only the English words around them («Elementary School (shōgakkō)» → «Початкова школа (shōgakkō)»; «Gaokao score» → «Бал Gaokao»; «Matura result» → «Результат Matura»; «Bac average» → «Середній бал Bac»; «Top private university» → «Провідний приватний університет»; «Regional University» → «Регіональний університет»). US generic tier/level names are translated (§6.3). **Ukraine's own system uses Ukrainian terms** (§6.3): НМТ (the current admission test; not the old ЗНО), атестат, ліцей, фаховий молодший бакалавр, бакалавр, магістр, доктор філософії, державне замовлення / контракт («state-funded place» = «бюджетне місце», «paid (contract) place» = «контрактне місце»).
* **US credentials** keep the Latin acronym and gain the Ukrainian descriptive name where the key is a full name: CNA, EMT, CPA, CDL, LPN, ATP, A&P, EPA 608, PE stay; «Medical License» = «Ліцензія лікаря», «Dental License» = «Ліцензія стоматолога», «Pharmacist License» = «Ліцензія фармацевта», «Veterinary License» = «Ліцензія ветеринара», «Electrician License» = «Ліцензія електрика», «Plumber License» = «Ліцензія сантехніка», «Nurse License» = «Ліцензія медсестри (RN)», «Bar Admission» = «Допуск до адвокатури», «Teaching Certificate» = «Педагогічний сертифікат», «Driver's License» = «Посвідчення водія», «Police Academy» = «Поліцейська академія», «Board Certification» = «Сертифікація спеціаліста».
* **Degree names** follow «ступінь + genitive of the subject»: every Bachelor of X / of Science in X / of Arts in X = «Бакалавр з X (genitive)», without the BSc/BA split: «Бакалавр з бізнес-адміністрування», «Бакалавр з інженерії», «Бакалавр з права», plain «Bachelor of Arts» = «Бакалавр з мистецтв», plain «Bachelor of Science» = «Бакалавр з природничих наук»; «Master of …» = «Магістр з …» in the same way; «Doctor of Philosophy in X» = «Доктор філософії з X»; «Doctor of Medicine (MD)» = «Доктор медицини (MD)»; «Juris Doctor (JD)» = «Доктор права (JD)»; «Doctor of Business Administration» = «Доктор бізнес-адміністрування (DBA)»; «Doctor of Fine Arts» = «Доктор мистецтв»; «Doctor of Design» = «Доктор дизайну»; «Doctor of Education» = «Доктор освіти». Subject genitives: бізнес-адміністрування, інженерії, наук про здоровʼя, мистецтв, природничих наук, освіти, інформаційних технологій, сільського господарства, права, дизайну, сервісного менеджменту, спортивних наук, кінезіології.

### Canonical base titles (`job.base.*`; ladders reuse them)
3D Artist = 3D-художник · Accountant = Бухгалтер · Administrative Assistant = Адміністративний асистент · Aerospace Engineer = Інженер-аерокосмічник · Aircraft Maintenance Technician = Технік з обслуговування літаків · Airline Pilot = Пілот авіакомпанії · Anesthesiologist = Анестезіолог · Animator = Аніматор · Architect = Архітектор · Art Director = Арт-директор · Assembler = Складальник · Baker = Пекар · Bank Teller = Касир у банку · Bartender = Бармен · Beautician/Cosmetologist = Косметолог · Bookkeeping Clerk = Помічник бухгалтера · Boutique Fitness Studio = Бутикова фітнес-студія · Bus Driver = Водій автобуса · Business Analyst = Бізнес-аналітик · Carpenter = Тесля · Cashier = Касир · Chef = Кулінар · Chemical Engineer = Інженер-хімік · Chief Executive Officer = Генеральний директор (CEO) · Chief Medical Officer = Медичний директор (CMO) · Chief Technology Officer = Технічний директор (CTO) · Childcare Worker = Вихователь · Civil Engineer = Інженер-будівельник · Cloud Architect = Хмарний архітектор · Construction Laborer = Будівельний робітник · Content Writer = Контент-райтер · Cook = Кухар · Customer Service Representative = Спеціаліст із підтримки клієнтів · Cybersecurity Analyst = Аналітик з кібербезпеки · Data Analyst = Аналітик даних · Data Scientist = Науковець із даних · Delivery Courier = Курʼєр · Dental Assistant = Асистент стоматолога · Dentist = Стоматолог · Dishwasher = Посудомийник · Dispatcher = Диспетчер · Electrical Engineer = Інженер-електрик · Electrician = Електрик · Event Planner = Організатор заходів · Factory Worker = Працівник заводу · Farm-to-Table Restaurant = Ресторан «від ферми до столу» · Farmer = Фермер · Farmhand = Працівник ферми · Fashion Designer = Дизайнер одягу · Fast Food Worker = Працівник фастфуду · Financial Analyst = Фінансовий аналітик · Firefighter = Пожежник · Fitness Instructor = Фітнес-інструктор · Flight Attendant = Бортпровідник · Food Preparation Worker = Помічник кухаря · Forklift Operator = Водій навантажувача · Game Designer = Геймдизайнер · Graphic Artist = Художник-графік · Groundskeeper = Садівник · HVAC Technician = Технік з опалення та кондиціонування (HVAC) · Hairdresser/Barber = Перукар/барбер · Heavy Equipment Operator = Оператор важкої техніки · Hotel Manager = Менеджер готелю · Housekeeper = Покоївка · Human Resources Specialist = HR-спеціаліст · IT Support Specialist = Спеціаліст з ІТ-підтримки · Indie Game Studio = Інді-студія ігор · Insurance Agent = Страховий агент · Interior Designer = Дизайнер інтерʼєрів · Investment Banker = Інвестиційний банкір · Janitor/Cleaner = Прибиральник · Journalist = Журналіст · Judge = Суддя · Lab Technician = Лаборант · Lawyer = Юрист · Level Designer = Левел-дизайнер · Licensed Practical Nurse = Практична медсестра · Light Truck Delivery Driver = Водій малої вантажівки · Logistics Coordinator = Координатор логістики · Machine Operator = Оператор обладнання · Machinist = Токар-верстатник · Maintenance & Repair Worker = Майстер з ремонту й обслуговування · Management Consultant = Консультант з управління · Managing Partner = Керівний партнер · Marketing Director = Директор з маркетингу · Marketing Specialist = Маркетолог · Mechanic = Механік · Mechanical Engineer = Інженер-механік · Medical Assistant = Медичний асистент · Mover = Вантажник · Municipal Worker = Працівник комунальної служби · Narrative Designer = Наративний дизайнер · Nurse Practitioner = Медсестра розширеної практики · Nursing Aide = Молодша медсестра · Office Clerk = Офісний працівник · Office Manager = Офіс-менеджер · Operations Manager = Операційний менеджер · Painter (Construction) = Маляр · Paralegal = Помічник юриста · Paramedic = Парамедик · Payroll Specialist = Спеціаліст із нарахування зарплати · Personal Care Aide = Асистент з догляду · Pharmacist = Фармацевт · Pharmacy Technician = Помічник фармацевта · Photographer = Фотограф · Physician = Лікар · Physiotherapist = Фізіотерапевт · Player = Гравець · Plumber = Сантехнік · Police Officer = Поліцейський · Project Manager = Менеджер проєктів · Property Development Firm = Девелоперська компанія · Psychologist = Психолог · Quality Control Inspector = Контролер якості · Real Estate Agent = Рієлтор · Receptionist = Рецепціоніст · Registered Nurse = Дипломована медсестра · Research Scientist = Науковий співробітник · Retail Salesperson = Продавець · Roofer = Покрівельник · SaaS App Startup = Стартап SaaS-застосунку · Sales Director = Директор з продажів · Sales Manager = Менеджер з продажів · Sales Representative = Торговий представник · Security Guard = Охоронець · Social Media Manager = SMM-менеджер · Social Worker = Соціальний працівник · Software Engineer = Інженер-програміст · Specialty Coffee Roastery = Обсмажувальня спеціальної кави · Store Manager = Директор магазину · Surgeon = Хірург · Systems Administrator = Системний адміністратор · TV Presenter = Телеведучий · Taxi Driver = Водій таксі · Teacher = Вчитель · Teaching Assistant = Асистент вчителя · Truck Driver = Далекобійник · Tutor = Репетитор · UX/UI Designer = UX/UI-дизайнер · Veterinarian = Ветеринар · Video Editor = Відеомонтажер · Warehouse Worker = Складський працівник · Welder = Зварювальник.
Other standalone titles: Airline Captain = Командир літака · First Officer = Другий пілот · Pilot = Пілот · Editor-in-Chief = Головний редактор · News Anchor = Ведучий новин · Personal Trainer = Персональний тренер · Supply Chain Manager = Менеджер ланцюга постачання · Warehouse Manager = Керівник складу.
Gloss for summaries: PMO = офіс управління проєктами (PMO) · IC (individual contributor) = фахівець без підлеглих (IC) · M&A = злиття та поглинання (M&A) · QA = тестування (QA) · RN = дипломована медсестра (RN).

## 8. Model sentences (calibration; copy the structure, not the words)

1. `You've reached the top of the %@ ladder — %@! 🏆` → «Ти на вершині карʼєрних сходів «%1$@» — %2$@! 🏆» (two placeholders → positional; ladder in quotes; the title stands after the dash).
2. `Get %@. It's the longest step, so start early.` (arg: a qualification) → «Здобудь %@. Це найдовший крок, тож починай якомога раніше.» (arg e.g. «ступінь бакалавра за напрямом «Бізнес»»: masculine inanimate, so accusative = nominative.)
3. plural `This job expects %lld years of experience; you have %@. Working as %@ builds it.` →
   one «Для цієї роботи треба мати %1$lld рік досвіду; у тебе — %2$@. Набути його можна на роботі за професією «%3$@».» · few «… %1$lld роки досвіду …» · many = other «… %1$lld років досвіду …».
4. plural `🎲 Skipping %lld years of childhood gives you %@ random skill points. Playing those years yourself builds far more.` → one «🎲 Пропуск %1$lld року дитинства дає випадкові бали навичок: %2$@. Якщо зіграти ці роки в грі, навичок буде набагато більше.» · few/many/other «… %1$lld років …» (genitive after «пропуск»; the noun «бали» is put before the `%@` number).
5. plural `• Experience: %@ of %lld years — %@` → one «• Досвід: %1$@ із %2$lld року — %3$@» · few/many/other «… із %2$lld років …».
6. `Only %@ of the people who qualify get a seat like this each year — however strong the application.` → «Таке крісло щороку отримують лише %@ людей, які відповідають вимогам, — хоч би яка сильна була заявка.»
7. `%@ is a narrow path: even a flawless candidate is hired only about %@ of the years they apply (about %@ with a founder's track record) — so it usually takes many attempts.` → ««%1$@» — вузька стежка: навіть бездоганних кандидатів беруть лише приблизно у %2$@ випадків, коли вони подають заявку (близько %3$@ — зі здобутками засновника), тож зазвичай потрібно багато спроб.»
8. `%@ worked out! You earned the “%@” title.` → ««%1$@» вдалося! Здобуто титул «%2$@».» (impersonal, no gender; project name quoted.)
9. `Laid off from %@ — paid about half the year, with severance` → «Скорочення на посаді «%@»: виплачено зарплату приблизно за півроку та вихідну допомогу»
10. `You didn't practise anything last year. This year, try %@ — it builds %@.` → «Минулого року жодного заняття не було. Цього року спробуй «%1$@» — це розвиває навичку «%2$@».» (no «ти не займався/займалася».)
11. `The advisor's chat isn't available in %@ yet, so you'll get the advisor's standard advice.` (%@ = «українська») → «Мова гри (%@) ще не підтримується в чаті з радником, тому ти отримуєш стандартні поради.»
12. `The minimum wage (₴8,647 a month)` → «Мінімальна зарплата (8 647 ₴ на місяць)»; `• %@: no job pays under %@ a year.` → «• %1$@: жодна робота не платить менше ніж %2$@ на рік.»; `Pay, prices and school costs from Ukraine, in hryvnias.` → «Зарплати, ціни та вартість навчання — як в Україні, у гривнях.»
13. Event: `Present` / `Presented` / `Present at %@` → «Презентувати» / «Презентовано» / «Презентувати: %@».
14. Catalogue: `job.title.Lead Lab Technician` → «Провідний лаборант»; its summary `Runs the lab's daily operations, safety, and quality.` → «Керує щоденною роботою лабораторії, безпекою та якістю.»; `job.title.Resident Physician` → «Лікар-інтерн».
15. `🏅 Score: %@ ÷ %lld y.o. = %@` (not plural) → «🏅 Результат: %1$@ ÷ %2$lld р. = %3$@».

## 9. Decisions for the product owner (defaults in this file; please confirm)

1. `ти` for everyone, including Real Life adults. 2. *Fame* = «Слава» (alternative «Популярність»). 3. *Network* = «Звʼязки» (alternative «Контакти»). 4. *Score* = «Результат» (alternative «Рахунок»). 5. Masculine-generic job titles and skill names, no feminitives; nurses/housekeeper feminine. 6. *Boardroom* = «Правління», *Ventures* footer = «Бізнес». 7. Apostrophe U+02BC. 8. Brand «Career Sim» kept Latin; the store/app display name is outside these files. 9. *Staff* and *Lead* both «Провідний»; chef ladder Кулінар → Су-шеф → Шеф-кухар → Бренд-шеф. 10. «The Chopin, the Tchaikovsky» (International Music Competition blurb) names a Russian composer's competition; for the Ukrainian edition consider swapping the example (e.g. Chopin and Queen Elisabeth); translators translate it literally and flag the string until you decide. 11. «Priced as in peacetime: the war's effects on work and flights aren't in the game.» is sensitive: draft «Ціни — як у мирний час: вплив війни на роботу й перельоти в грі не враховано.»; please review the wording. 12. Foreign institution names are kept in the source script, not transliterated. 13. Ukrainian-system terms follow the post-2019 vocabulary (НМТ, фаховий молодший бакалавр, доктор філософії). 14. *Student loan* = «студентський кредит» (alternative «позика на навчання»).

## 10. Self-check before hand-back

Placeholders identical and positional where ≥ 2; all four plural keys present and each branch has its `%lld`; `%%` preserved; no U+0027/U+2019 between Cyrillic letters; no Latin look-alikes in Cyrillic words; quotes «…»; em dash with spaces; sentence case; emoji, bullets and line breaks unchanged; no `ви`; no past-tense/gendered address of the player; no russianisms; every term matches §6–§7; catalogue values non-empty.
