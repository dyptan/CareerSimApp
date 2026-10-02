# CareerSimApp — 日本語 (ja) Glossary and Style Guide

Shared by every Japanese translator. Read it all once, then use it as a lookup (`grep`). Where it says nothing, follow the *pattern* of the nearest entry.
Precedence: the string's own `comment` / `where` in the chunk file, then this file, then your judgement.
Do not invent a second rendering of a listed term. If you meet a recurring term that is not listed, pick one rendering, use it consistently
and list it at the end of your report as `NEW TERM: English -> 日本語`.

## 1. Voice and register

* **Reader.** A player from about 7 years old to adult, on an iPhone or Mac, who grows from primary school through education, jobs and retirement.
  The English is cheerful, plain and encouraging, with emoji and many "!". Keep that warmth; never sound like a bank or a government form.
* **Speech level: friendly です・ます体 (丁寧体) everywhere.** No plain-form sentences (だ／である／〜する。), no stiff keigo
  (ございます, いただけます, ご〜ください, お〜になる, いらっしゃる), no slang (〜じゃん, 〜だぜ). A softener (〜ましょう, 〜かもしれません, 〜してみましょう) is the way to give advice.
* **Buttons, menu items, titles, chips, list labels**: not sentences. Use a compact noun / サ変名詞 (応募, 出願, 昇進, スキップ) or, if a verb is unavoidable, the dictionary form
  (開く, 始める). Never put ます on a button. No final 。 on a fragment (mirror the English: no period in the source, none in Japanese).
* **Three voices** (the `comment` and `where` tell you which):
  1. **Advisor** (AdvisorCoach / AdvisorConversation / AdvisorPathway / AdvisorRealWorld, chat chips): a warm coach speaking to the player. Conversational です・ます, may use
     〜ですよ, 〜ますね, 〜ましょう, 〜でしょう, a light "！" and the emoji already in the source. First person only when the English has "I": omit the subject, or わたし (hiragana). Never 僕／俺／私（わたくし）.
  2. **System text** (hints behind ⓘ, popovers, country info, rules): neutral, informative です・ます. No sentence-final particles (ね／よ), no exclamations unless the English has one.
  3. **Status log and results** ("Hired as…", "Promoted to…", "Paid off your student loan"): a short polite past, 〜しました, or a noun phrase with the detail in （　）. Same verb every time (採用, 昇進, 完済, 卒業).
* **"Beginner's or child's words" variants** (the comment says so, and Simplified-mode text): shorter sentences, everyday words, more hiragana (see Furigana), no jargon such as 概算, 取得, 該当.
  The "for adults" variant of the same fact may use the standard terms (取締役会, 学位, 実績).
* **You / your.** Drop it. Translate "Your score" as スコア, "You earned X" as Xを獲得しました. Use あなた(の) only to prevent a real ambiguity (opposing "the school's" vs "your"); never 君／お客様.
* **Long English sentences.** Split at the em dash or semicolon into two or three short sentences; keep one idea per sentence and the verb last. Keep every fact and number. Do not add information, and do not drop a caveat.
* **Exclamation marks**: keep where the English has them (！), never add. **Questions**: ？ (full-width) and no space after.
* **Emoji, bullets and symbols stay exactly where they are**: `🎯`, `💵`, `•`, `✓`, `🔒`, `ⓘ`, `→`, `×`, `÷`, `≈`, `🏆`. A leading emoji keeps one half-width space after it, as in the source (`🎯 目標：…`).
* **Length.** Japanese is usually 40-60% shorter than English in characters, but katakana terms can run long. For chips, buttons and footer labels prefer compact kanji compounds
  (4 characters or fewer when the English is one word). Do not drop a word the player needs just to be short.
* **Furigana: none.** The UI cannot show ruby. Instead:
  * Use the ordinary kanji (常用漢字) for names of jobs, schools, subjects and the glossary terms below.
  * Write in **hiragana** the function words and verbs that books for children also write in kana: できる, こと, もの, とき, ため, ほど, ほか, たくさん, ぜひ, すべて, ふつう, だんだん, いっしょに,
    さらに, すでに, まだ, もっと, ずっと, ください, ありがとう, 〜など, 〜ながら, 〜ばかり, 〜ごと, 〜かもしれません. (Not 出来る, 事, 物, 時, 為, 殆ど, 沢山, 全て, 普通, 更に.)
  * In child/beginner variants and in Simplified-mode and tutorial text, also write in kana the verbs and adjectives whose kanji are above about school grade 4, when a plain kana word is natural
    (競う→きそう, 鍛える→きたえる, 到達する→たどりつく, 概要→あらまし). Everyday words (仕事, 学校, 勉強, 難しい) keep their kanji, and so do the glossary terms (昇進, 名声, 人脈, 貯金 …): players learn those from the game.

## 2. Typography

* **Sentence punctuation**: 。 、 ！ ？ (full-width). No half-width `, . ! ?` in Japanese text. A comma between clauses is 、; use 、 sparingly (every 20-25 characters at most).
* **Colon** `:` → `：` (full-width). Semicolon `;` → 。 or 、. Parentheses `( )` → `（ ）` always, even around Latin or digits. Ellipsis `…` stays a single `…`.
* **Quotes**: “title”, "label" → `「…」`; a quote inside a quote `『…』`. Award titles, UI labels, search words ("nurse") all take 「 」.
* **The em dash `—`** is not carried over. By function: an aside or reason → split into a new sentence (。) or use 、; a label separator ("Graduated — %@") → `：`
  ("卒業：%@"); a dash joining a name and its role ("%@ — Speaker") → の ("%@の登壇者"). Use `―` (a long dash) only if the sentence truly needs a break and 。 cannot do it; never `ー` (the katakana bar) as a dash.
* **Hyphen/en dash in ranges** → `〜` (U+301C): `6〜10歳`, `10〜20年`, `3〜7年`. "7+" → `7歳以上`, "3+ yrs" → `3年以上`; "under 18" → `18歳未満`; "up to" → `〜まで`. A signed number (`+20%`, `−5%`) is kept as it arrives.
* **Middle dot `・`**: joins parallel nouns and replaces `&` and `/` between two alternatives: `ソフトウェア・インターネット`, `銀行・金融`, `読み書き`, `美容師・理容師`.
  Keep `&` and `/` only inside names and technical tokens: `A&P`, `M&A`, `R&D`, `UX/UI`, `QA`, `Q&A`. A separator ` · ` between phrases in a status line is kept as in the source (` · `).
* **Spaces.** None between Japanese and Latin letters, digits or placeholders (`Apple Intelligenceをオンに`, `%lld年`, `%@の確率`). Keep a space between two Latin words, between two adjacent
  placeholders if the English has one (`%@ %@`, an emoji and a name), after a leading emoji, and around ` · `. No space after ？！。 or inside （ ）.
* **Digits** are always half-width (`2026`, `18`, `4.4`). Never full-width digits or letters. Thousands separator `,` and decimal `.` as they arrive. Numbers arrive pre-formatted as `%@`; do not reformat them.
  Magnitude words in literal text: million → 100万, "a few hundred" → 数百, "thousands" → 数千, "millions of yen" → 数百万円.
* **Percent**: a literal `%` in a key is `%%` in the key and in your translation (`+40%%`). When the value arrives as `%@` it already contains the sign (`73%`); never write another `%`/`％`.
  Word order: "a %@ chance" → `%@の確率` / `確率は%@`; "%@ of the decision" → `判断の%@`.
* **Money.** `%@` money arrives already formatted by the app: do not add 円 or ¥ or 年収 after it and do not reword the symbol. Literal amounts inside a key (`€13.90 an hour`):
  keep digits and symbol exactly (`€13.90`, `C$18.15`, `£12.71`, `A$26.44`, `R$1,621`, `CN¥2,740`, `₹18,456`, `MX$315.04`, `4,806 zł`, `26,626 kr`, `₺33,030`, `₩10,320`, `₴8,647`),
  only the unit words move: an hour → `時給`, a day → `日給`, a month → `月額`, a year → `年`, "paid in 13 instalments" → `13回に分けて支払い`.
  **Exception: yen** — `¥1,121` becomes `1,121円`. Currency names: dollars ドル, euros ユーロ, pounds ポンド, yen 円, hryvnias フリブニャ, Canadian dollars カナダドル,
  Australian dollars オーストラリアドル, reais レアル, yuan 元 (人民元), rupees ルピー, Mexican pesos メキシコペソ, zloty ズウォティ, Swedish kronor スウェーデンクローナ, Turkish lira トルコリラ, won ウォン.
* **Counters** with `%lld` (the number is a bare integer; the counter is yours): years `%lld年`, age `%lld歳`, times/moves `%lld回`, roles/postings/jobs `%lld件` (roles by kind: `%lld職種`),
  people `%lld人`, industries `%lld業界`, school levels `%lld段階`, points `%lldポイント`, flight hours `%lld時間`. `yr`/`yrs`/`years` is always `年` (use `〜年間` only where the English says "for N years").
  A bare number in English that obviously means years or points gets its counter ("Under %lld you're not considered" → `%lld年未満`).
* **Age** `Age 12` → `12歳`; `age %lld` → `%lld歳`; `Ages 7+` → `7歳以上`; `Teens & up` → `10代以上`; `y.o.` → `歳`; `Age:` (header label) → `年齢：`.
* **Time words**: this year 今年, next year 来年, last year 去年, every year／each year 毎年, one turn = one year `1ターン＝1年`.
* **Katakana.** Full-width only (no half-width katakana). Write v-sounds with バ行, not ヴ (ベンチャー, サービス, ドライバー, ビデオ). Use the modern small-kana sounds ティ ディ ファ フィ ウィ ウェ シェ ジェ チェ (ディレクター, ファッション, シェフ).
  **Long vowel mark ー: write the final ー on -er/-or/-ar and -y words, whatever their length** — the general-purpose standard (newspapers, job boards, Microsoft since 2008): デザイナー, ドライバー, マネージャー,
  ディレクター, ライター, アドバイザー, アニメーター, プランナー, カウンセラー, オペレーター, コンピューター, ヘルパー, ストーリー, ファミリー. Do **not** use the older IT-documentation style that drops it from words of 3+ mora
  (デザイナ, ユーザ, コンピュータ). Words that have no final long vowel anyway stay as they are: エンジニア, カメラマン, アナリスト, ジャーナリスト, コンサルタント, スペシャリスト, パイロット, シェフ, ホテル.
  Do not put `・` inside one compound job title (ソフトウェアエンジニア, データサイエンティスト); use `・` only between separate words of a foreign name (グループ・オブ・エイト, スペリング・ビー).
* **Initialisms.** Keep these Latin ones exactly as in the source: CEO, CTO, COO, CFO, CMO, GPA, MBA, MD, JD, PhD, IT, QA, UX/UI, AI, SaaS, MOOC, PMO, NHS, ATAR, ENEM, CSAT, NMT, TAFE, BTEC, BTS, IUT, ITS, ESO, FP, 3D, eスポーツ, Aレベル. Two are *not* kept: HVAC → 空調設備, HR → 人事.
  A US-only credential acronym stays Latin with a Japanese gloss in （　） the first time it names a thing: `CNA（看護助手）`, `EMT（救急隊員）`, `LPN（准看護師）`, `CDL`, `ATP`, `EPA 608`. Where Japan has an equivalent, use it and keep the acronym in brackets (see §4.4).
  Latin acronym + Japanese word: no space (`GPAの計算`, `CEOに昇進`).
  `EQF` (European Qualifications Framework) occurs only in translator comments, not on screen; don't translate it.
* **Leading/trailing space and newlines.** A key that begins with a space (` (your %lld years…)`) is inserted mid-sentence: drop the leading space, write the （　） flush. `\n` in a key is a real line break: keep it where it is.
* **Brands and system names stay Latin**: Apple Intelligence, Game Center, iOS, macOS, iPhone, Career Sim (the game's title; do not katakana it).

## 3. Placeholders, plurals and special keys

* **Keep every placeholder exactly**: `%@` (a pre-formatted string: a name, a number, a percent, money, a list), `%lld` (a bare integer). Never change the type (`%d`, `%s`), never add or drop one.
* **One placeholder** → write it plainly: `%@`/`%lld`. **Two or more** → *every* placeholder in the translation is positional, numbered by its order in the **English key**:
  `%1$@`, `%2$lld`, `%3$@`. Japanese word order is often the reverse of English, so reorder freely; use each number at least once and never invent a new one.
  Do not mix plain and positional in one string. Positional specifiers keep their type: `%2$lld` not `%2$d`.
* **Plurals.** Japanese has one category, `other`. A plural key arrives as `{"other": ""}`: fill only `other`, and write it to read correctly for *any* count including 1
  (the English `one` form is shown in `_context.english` for reference; ignore the singular/plural difference). `%lld year/years` → `%lld年`. Where the English differs only for 1 ("1 move" / "2 moves"), the Japanese is one sentence with the counter (`%lld回`).
  The `_context.english` forms of a plural with two or more placeholders already use `%1$lld` etc.: reuse those numbers.
* **Lists** (`Fmt.list`) arrive pre-joined in Japanese style: `A、B、C` (and), `A、B、またはC` (or), `AまたはB`. Do not add 、 or と around the placeholder; phrase the sentence so the list works as a noun phrase
  (`%@の学位` → "a degree in Health or Science" = `医療または科学の学位`). Money, percent, age and name placeholders are likewise complete as they arrive.
* **Looked-up names** (job titles, industries, fields, skills, schools) arrive in Japanese already; they can be glued to particles directly (`%@として`, `%@の昇進コース`). Never add 「」 around them unless the English has quotes.
* **Strings that are not English text.** Two keys are identifiers: `field.education` = a degree *subject* → **教育学**; `activity.science` = a school *subject* → **理科**. Their comments say so.
  Strings that are only placeholders or emoji (`%@`, `%@ %@`) are not in the chunk files.
* **Noun phrases embedded by code.** Several keys are fragments that code places inside a sentence: a qualification (`a bachelor's degree in %@`), a minimum-wage noun phrase (`The federal minimum wage`
  that leads `• <this>: no job pays under <amount> a year.`), a climate effect (`30% easier than usual` after a colon), a ladder name after "as". Read the `comment` for the frame, and make your phrase fit it:
  qualification → noun phrase ending in a noun that takes を/が/の (`学士号`); effect → a phrase that can follow `：`; minimum-wage phrase → a noun phrase.
* Do not translate the English key text that appears in `_context`; do not touch the keys.

## 4. Glossary

Tables are `English | 日本語 | note`. "(UI)" = shown as a label or button.

### 4.1 Game concepts and screens

| English | 日本語 | Note |
|---|---|---|
| Career Sim | Career Sim | Title stays Latin |
| Simplified (mode) | かんたん | "Simplified mode" = かんたんモード; the easy tutorial mode, ages 7+ |
| Real Life (mode) | リアルライフ | "Real Life mode" = リアルライフモード |
| Game mode | ゲームモード | (UI) |
| Goal | 目標 | |
| Make it to the top | トップをめざす | Simplified goal name |
| Best score by %lld | %lld歳までのベストスコア | Real Life goal name |
| Score | スコア | Score sheet (Real Life) |
| Progress | 進み具合 | (UI) header button in Simplified, which keeps no score |
| Leaderboard | リーダーボード | Game Center's own word |
| Net worth | 純資産 | "what you own minus what you owe" |
| Game Over | ゲームオーバー | |
| Keep playing | 続ける | button |
| Restart | もう一度あそぶ | button, after the career ended |
| Start over | はじめからやり直す | button, mid-run |
| Skip | スキップ | (UI) header: let this year pass |
| Take | 始める | button on an activity, course or project row |
| Apply (button) | 応募 | ONE shared key `Apply` is both the job button and the school-application title, so it must be 応募. In sentences: a job → 応募する, a school/university → 出願する |
| Launch | 立ち上げる | button: found the business now |
| Send | 送信 | |
| Close | 閉じる | |
| OK / Thanks! | OK／ありがとう！ | |
| Let's go! | はじめましょう！ | |
| How to play | あそびかた | |
| Start here | ここからスタート | |
| Pick your character | キャラクターを選びましょう | no plain-form 選ぼう |
| Starting age | 開始年齢 | |
| Country | 国 | |
| Turn | ターン | "One turn = one year" = 1ターン＝1年 |
| Age: | 年齢： | header label |
| Advice (header button) | アドバイス | noun |
| Advisor / career advisor | アドバイザー／キャリアアドバイザー | |
| standard advice | 基本のアドバイス | what the advisor gives without Apple Intelligence |
| Apple Intelligence | Apple Intelligence | Latin |
| Your story | これまでの歩み | the life-log screen |
| Occupation | 職業 | Skills panel heading |
| Student | 学生 | headline when in school |
| Not working | 仕事なし | |
| Finances | お金 | panel heading |
| Skills (the 15 abilities) | スキル | |
| Hard skills | ハードスキル | code name for licences and courses; rarely on screen |
| Soft skills | ソフトスキル | code name for the 15 abilities; on screen just スキル |
| Fame | 名声 | the reputation pillar; "famous" 有名; "fame points" 名声ポイント; "earned fame" 名を上げた |
| Network | 人脈 | professional contacts; "Network in %@" = %@の人脈 |
| General (fame row) | 全般 | 🌐 全般 |
| Trophies | トロフィー | |
| Credentials | 学歴・資格 | shelf of diplomas, degrees, certificates, licences |
| The economy / Economy | 経済 | heading "Economy" = 経済; the national row inside it, "The economy", = 経済全体 (so the row does not repeat its own heading) |
| Declared downturn | 景気後退 | |
| Recession | 不況 | |
| Experience | 経験 | "work experience" 職務経験; "years of experience" 経験年数 |
| In this role (row label) | この仕事の経験 | value is "N yrs" (3年) |
| Activities (footer) | 活動 | sports, study, hobbies; an *activity* 活動 |
| Events (footer) | イベント | |
| Jobs (footer, sheet) | 仕事 | a *job* in prose 仕事; a *role* 職種 |
| Projects (footer) | プロジェクト | spare-time projects; code calls them side hustles → 副業 (never shown) |
| Ventures (footer, sheet) | 起業 | founding a company; a venture (the business) 事業; venture loan 起業ローン |
| Boardroom | 経営会議 | the executive-decisions sheet |
| Education (footer, screen, job field) | 教育 | one rendering for all; degree *subject* is 教育学 (§3) |
| Degrees / Courses / Licences | 学位／講座／免許 | sections of the Education screen |
| Fields of study | 学ぶ分野 | |
| Compare schools | 学校をくらべる | |
| Likely jobs | 主な仕事 | |
| Hard requirements | 必須条件 | requirements 条件 |
| Preferred | 歓迎 | "Preferred education" 歓迎学歴 |
| Door / Breakthrough (the one required title) | 入り口 | "Get through the door" 入り口をくぐる; "Breakthrough:" 入り口：; "door-opener" 道を開く称号 |
| Lever (advisor) | 要素 | "Your biggest lever" いちばん効く要素 |
| Seat (top position) | ポスト | "the seat" ポスト; "C-suite seat" 経営幹部のポスト; "seat chance" ポストを得る確率 |
| Narrow path | 狭き門 | idiom, use it |
| A long shot | 望みが薄い挑戦 | adj. 望みが薄い |
| Lottery | 運任せ | "not a lottery" 運任せではありません |
| Cap / ceiling | 上限 | |
| Polish (an application) | 磨き込み | "more polish changes nothing" = これ以上アピールを重ねても変わりません |
| Hit or miss | 当たっても外れても | |
| It landed! / didn't land | 成功！／うまくいきませんでした | project outcome title |
| Breakout | 急成長 | a venture that "took off"; in entertainment ("Breakout Role", "Hit") ブレイク／ヒット |
| Bank (verb: "banks +X") | たまる／得る | "Every year it survives banks +X of track record" = 生き残るたびに実績が+X積み上がります |
| Uses up your year | その1年を使います | fixed phrase: "Taking part uses up your year." = 参加するとその1年を使います。 |
| Move (one year's choice, in the advisor's count) | 回 | "%lld more moves of trying new things" = 新しいことに挑戦するあと%lld回 |
| Match (fit of your skills) | 適合度 | "%@ match" = 適合度%@ |
| Gap | 差 | "closes the whole gap" = 差をすべて埋める |
| Check-in (advisor's yearly review) | チェックイン | |
| Plan (advisor card) | プラン | "A plan for your skills" = スキルアッププラン |
| School subject / Hobby / Sport | 教科／趣味／スポーツ | the three kinds of activity |
| Childhood / Teen Years / Young Adult / Working Life | 子ども時代／10代／青年期／社会人時代 | life stages |
| Congratulations! / Champion! (alert titles) | おめでとうございます！／チャンピオン！ | keep the emoji |
| Business Closed (alert title) | 事業終了 📉 | |
| Thinking… / Ask me anything… | 考え中…／なんでも聞いてください… | advisor chat |
| Requirements not met | 条件を満たしていません | |

### 4.2 Money and economy

| English | 日本語 | Note |
|---|---|---|
| Pay (noun) | 給料 | |
| Salary (annual) | 年収 | pay "%@ a year" = 年収%@ (frames in §4.8); the headings "Salary:" / "💵 Salary" = 給与 |
| Gross income | 総収入 | before taxes and living costs |
| Salary ask / "Your ask:" | 希望額：／希望年収 | "Ask for a salary" = 希望給与を伝える |
| Offer | オファー | "🎉 Offer accepted!" 🎉 採用決定！ / "❌ No offer this time." ❌ 今回は不採用です。 |
| Merit raise / pay rise | 昇給 | |
| Savings | 貯金 | |
| Money earned | 稼いだお金 | |
| Banked from pay | 給料から貯金 | |
| Living costs | 生活費 | rent and food |
| Tuition | 授業料 | school costs (the whole bill) 学費 |
| Student loan | 奨学金 | a loan to be repaid; "student loan owed" 奨学金の残り |
| Venture loan | 起業ローン | |
| Paid off | 完済 | |
| Minimum wage | 最低賃金 | "federal minimum wage" 連邦最低賃金 |
| Median | 中央値 | "Market median" 市場の中央値 |
| Severance | 退職金 | |
| Endorsements | スポンサー契約 | brand deals for famous players |
| Investment round | 資金調達ラウンド | "Announce an Investment Round" = 資金調達を発表する |
| Investor | 投資家 | |
| Pitch | ピッチ | the presentation to investors (💬 Persuader skill) |
| Stake (ownership share) | 持ち分 | "Sell Your Stake" 持ち分を売る |
| Stake (money you put in) | 出資額 | verb 出資する; "Nothing to stake yet" 出資できるお金がありません |
| Shares / vested shares | 株式／権利確定済みの株式 | |
| Capital | 資金 | "💰 Target %@" (capital a venture needs) = 💰 必要資金%@ |
| Exit (successful) | エグジット | Fame award "Successful Exit" = エグジット成功 |
| Founder track record | 起業実績 | "track record" 実績 |
| Fold (a business) | 廃業 | "folded" 廃業しました |
| Industry | 業界 | |
| Boom / Booming | 好況 | climate state 1 |
| Growing | 成長 | state 2 |
| Steady | 横ばい | state 3 |
| Slowing | 減速 | state 4 |
| Slump | 不況 | state 5 (industry); the economy-wide "bad economy" 不景気 |
| Layoff / Laid off | 人員削減／解雇 | noun/alert title 人員削減; "laid off from %@" %@を解雇されました |

### 4.3 Hiring, ladders and seniority

| English | 日本語 | Note |
|---|---|---|
| Hired / hire | 採用 | "Hired as %@" %@として採用 |
| Posting | 求人 | "Nobody is posting %@ jobs" = %@の求人はありません |
| Application (noun) | 応募 | school → 出願; "an application spends the year" = 応募するとその1年を使います |
| Chance / odds | 確率 | chance to be hired 採用される確率; admission chance 合格確率; chance to win 優勝確率 |
| Promotion / promoted | 昇進 | "Promotion odds" 昇進確率 |
| Qualified / meets the requirements | 条件を満たしている | |
| Ladder (career ladder) | 昇進コース | "the %@ ladder" = %@の昇進コース |
| Rung / step | 段階 | "next step up" 次のステップ |
| Seniority | 職位 | |
| Standard (the plain role) | 標準 | |
| Top of the ladder | 頂点 | |
| Employer | 勤務先 | |
| Industry's climate | 業界の景気 | |
| Founder | 創業者 | "Founder of %@" %@の創業者; "CEO, %@" %@のCEO |
| Found a company | 起業する | |
| Executive decision | 経営判断 | |
| Board (of directors) | 取締役会 | |
| C-suite | 経営幹部 | |
| Retire / retirement | 引退 | "career over" キャリア終了 |
| Retired from professional sport | プロスポーツを引退 | |
| Career | キャリア | |

### 4.4 Education, credentials and training

| English | 日本語 | Note |
|---|---|---|
| Degree | 学位 | |
| Bachelor('s degree) | 学士 | as an object: 学士号; "University — Bachelor's" 大学（学士） |
| Master('s degree) | 修士 | 修士号; "University — Master's" 大学院（修士） |
| Doctorate / Doctoral | 博士 | 博士号; "Doctorate+" ポスドク |
| Diploma | 卒業資格 | "a school diploma" 高校卒業資格; "a college or vocational diploma" 短大・専門学校の卒業資格 |
| Vocational | 職業 | "Vocational Diploma" 職業ディプロマ; "College / Vocational" 短大・専門 |
| Primary / Elementary School | 小学校 | every country (see §6) |
| Middle School / Junior High / lower secondary | 中学校 | every country (see §6) |
| High School | 高校 | |
| Community College (tier 1, US) | コミュニティカレッジ | open-access college |
| State University (tier 2, US) | 州立大学 | mainstream |
| Elite / Ivy League (tier 3, US) | 名門校（アイビーリーグ） | |
| Tier (of schools) | ランク | "school tiers" 学校のランク |
| open-access / mainstream / elite (generic) | 入りやすい／一般的な／難関 | "an elite university" 難関大学; "the top school" トップ校 |
| College (generic) | カレッジ | |
| University | 大学 | |
| Junior College | 短期大学 | |
| Private / National University | 私立大学／国立大学 | |
| Graduate / graduated | 卒業 | "Graduated — %@" `%@を卒業` (a story-log line, shown after `10歳：`, so it carries no colon of its own) |
| Admission | 入学選考 | "How admission works" 入学選考のしくみ; "Admission requirement" 出願条件 |
| Accepted / "You're in!" | 合格／合格！ | "said no" 不合格 |
| Grades | 成績 | "school grade" 学校の成績; "Soft-skill match" スキルの相性 |
| GPA | GPA | US name of the grade; keep |
| EQF | EQF | translator comments only, never on screen |
| School prestige | 学校のネームバリュー | |
| Prizes and titles | 賞と称号 | "Your accolades" 受賞歴 |
| Course | 講座 | a taught course; programme 課程／プログラム |
| Training | 研修 | "Training: %@" is an unmet requirement shown after 「まず必要なもの：」 / 「まず、…が必要です」, so it is the bare name `%@` |
| Certificate / certification | 資格 | completion certificate 修了証 |
| Licence / License | 免許 | where Japan has no 免許 use 資格 or 登録 (§4.4b) |
| Board exam | 国家試験 | "Medical Board Exam" 医師国家試験 |
| Exam | 試験 | |
| Apprenticeship | 見習い期間 | |
| Bootcamp | ブートキャンプ | "Coding Bootcamp" プログラミング・ブートキャンプ |
| Journeyman | 一人前の職人 | "Journeyman Electrician Exam" 電気工事士試験 |
| Residency | 臨床研修 | "Medical Residency (Board Certification)" 臨床研修（専門医認定） |

**4.4b Credentials (training names).** Pattern `<programme> (<credential>)` → `<programme>（<credential>）`. Fixed credential names:

| English | 日本語 | English | 日本語 |
|---|---|---|---|
| CNA | CNA（看護助手） | EMT | EMT（救急隊員） |
| LPN / Licensed Practical Nurse | 准看護師（LPN） | Nurse License (RN) | 看護師免許（RN） |
| Nurse Practitioner | 診療看護師（NP） | Medical License | 医師免許 |
| Dental License | 歯科医師免許 | Pharmacist License | 薬剤師免許 |
| Veterinary License | 獣医師免許 | Physical Therapy License | 理学療法士免許 |
| Psychologist License | 公認心理師資格 | Board Certification | 専門医認定 |
| Teaching Certificate | 教員免許 | Cosmetology License | 美容師免許 |
| Driver's License (Class D) | 運転免許（普通） | CDL | 大型・商用運転免許（CDL） |
| Pilot (private licence) | 自家用操縦士 | Commercial Pilot | 事業用操縦士 |
| ATP | 定期運送用操縦士（ATP） | A&P Certificate | A&P整備士資格 |
| Electrician License | 電気工事士免許 | Master Electrician License | 熟練電気工事士免許 |
| Plumber License | 配管工免許 | Master Plumber License | 熟練配管工免許 |
| CPA | 公認会計士（CPA） | Bar Admission | 弁護士登録（司法試験合格後） |
| Professional Engineer (PE) | 技術士（PE） | Architect Licence | 建築士免許 |
| Security Guard Licence | 警備員資格 | Pesticide Applicator | 農薬散布者資格 |
| Police Academy | 警察学校 | EPA 608 | EPA 608（冷媒取扱資格） |
| Flight Attendant (cert.) | 客室乗務員資格 | Dental Assistant (cert.) | 歯科助手資格 |
| Pharmacy Technician (cert.) | 調剤助手資格 | Game Development Program | ゲーム開発プログラム |
| Product Design Certificate | プロダクトデザイン修了証 | Music Production Certificate | 音楽制作修了証 |

Degree titles — Bachelor/Master/Doctor of X: `学士（X）`, `修士（X）`, `博士（X）`; subject in Japanese form:
Business Administration 経営学, Engineering 工学, Health Sciences 保健学, Arts 文学 (but "Bachelor of Arts in Arts" 学士（芸術）), Science 理学, Education 教育学, Information Technology 情報技術,
Agriculture 農学, Laws／Law 法学, Design デザイン学, Service Management サービスマネジメント, Sports Science スポーツ科学, Kinesiology 運動科学, Fine Arts 美術 ("Doctor of Philosophy in X" = 博士（X）).
Fixed: Master of Business Administration → 経営学修士（MBA）; Doctor of Medicine (MD) → 医学博士（MD）; Juris Doctor (JD) → 法務博士（JD）; Associate of Applied Science in %@ → 応用科学準学士（%@）; Trade Certificate → 技能修了証.

### 4.5 Fields, categories, industries (shared words — one rendering each)

| English | 日本語 | English | 日本語 |
|---|---|---|---|
| Entertainment (fame) | エンタメ | Show Business (job field) | 芸能 |
| Technology | テクノロジー | Arts | 芸術 |
| Business | ビジネス | Science (field of work/fame/degree) | 科学 |
| Science (school subject, `activity.science`) | 理科 | Engineering | エンジニアリング |
| Health | 医療 | Public Services | 公共サービス |
| Agriculture | 農業 | Design | デザイン |
| Law | 法律 | Construction | 建設 |
| Retail | 小売 | Hospitality | ホスピタリティ |
| Personal Services | 美容サービス | Manufacturing | 製造 |
| Entrepreneurship | 起業・経営 | Transportation | 運輸 |
| Administration | 事務・管理 | Sports (activity/degree) | スポーツ |
| Service (degree subject) | サービス | Education (degree subject) | 教育学 |
| Office (setting) | オフィス | Field (setting: hands-on) | 現場 |
| People-facing (setting) | 対人 | Kind of work / Any | 仕事の種類／すべて |

Industries: Software & Internet ソフトウェア・インターネット; Computing Hardware コンピューター機器; Telecoms 通信; Automotive 自動車; Aerospace & Defence 航空宇宙・防衛;
Energy & Utilities エネルギー・公益事業; Banking & Finance 銀行・金融; Healthcare ヘルスケア; Pharma & Biotech 製薬・バイオ; Government & Public Sector 政府・公共部門; Retail & Consumer 小売・消費財;
Hospitality & Tourism ホスピタリティ・観光; Media & Entertainment メディア・エンタメ; Construction & Property 建設・不動産; Agriculture & Food 農業・食品; Transport & Logistics 運輸・物流;
Industrial Manufacturing 産業製造; Professional Services 専門サービス.

### 4.6 The 15 skills (abilities) — `label` of a skill, with its pictogram

Inventor 発明家 💡 · Creator クリエイター 🎨 · Influencer 発信者 📢 · Persuader 交渉人 💬 · Leader リーダー 👑 · Visionary ビジョナリー 🔭 · Detective 探偵 🔍 · Fixer 職人 🛠️ ·
Navigator ナビゲーター 🧭 · Athlete アスリート 🏃 · Zen 平常心 ☯️ · Empath 共感者 🫶 · Teamplayer チームプレーヤー 🤝 · Planner プランナー 📅 · Champion 努力家 🏆 · "Skill" (fallback) スキル.
In running text always use the skill's own name above (the Boardroom hint "Persuader most of all, then vision, talking and leading" = 交渉人がいちばん大切で、次にビジョナリー、発信者、リーダー).

### 4.7 Activities, sports, contests and events

| English | 日本語 | English | 日本語 |
|---|---|---|---|
| Sports / Arts & Minds / Study (tabs) | スポーツ／アート＆頭脳／勉強 | Beginner / Intermediate / Advanced / Expert | 初級／中級／上級／エキスパート |
| Running / Swimming / Cycling | ランニング／水泳／サイクリング | Soccer / Basketball / Tennis | サッカー／バスケットボール／テニス |
| Martial Arts / Gymnastics | 武道／体操 | Skateboarding & BMX | スケートボード・BMX |
| E-Sports | eスポーツ | Music / Photography / Cooking / Dance | 音楽／写真／料理／ダンス |
| Drawing & Painting | 絵画 | Coding | プログラミング |
| Chess / Debate | チェス／ディベート | Student Council | 生徒会 |
| Mathematics | 数学 | Reading & Writing | 読み書き |
| History & Geography | 歴史・地理 | Foreign Languages | 外国語 |
| Contest (kinds: Athletic/Creative/Mind/Academic) | コンテスト（競技／創作／頭脳／学力） | Competition / Tournament | 大会 |
| Championship | 選手権 | Olympiad | オリンピアード（Math: 数学オリンピック） |
| Title (award) | 称号 | Prize | 賞 |
| Winner / Champion / Medalist | 優勝者／チャンピオン／メダリスト | Prizewinner / Laureate | 入賞者／受賞者 |
| Junior / Youth / Kids' | ジュニア／青少年／こども向け | National / Regional / International | 全国／地域／国際 |
| Event (Summit / Expo / Conference / Forum) | サミット／展示会／カンファレンス／フォーラム | Symposium / Congress / Convention | シンポジウム／学会／大会 |
| Festival / Show / Pitch Night | フェス／ショー／ピッチナイト | Speaker | 登壇者 |
| Present / Presented (button, past) | 発表／発表済み | Perform / Performed | パフォーマンス／パフォーマンス済み |
| Appear / Appeared | 出演／出演済み | Speak / Spoke | 登壇／登壇済み |
| Compete / Competed | 出場／出場済み | Demo / Demoed | デモ／デモ済み |

Event/contest names: translate descriptively, keep real-world proper names in katakana (ショパン, チャイコフスキー, ハッカソン, スペリング・ビー, グランドマスター).
Title suffixes: "X Winner" → `X優勝者`, "X Champion" → `Xチャンピオン`, "X Medalist" → `Xメダリスト`, "X Star" → `Xのスター`, "Young X of the Year" → `今年の若手X`.

### 4.8 Frames that repeat (use these exact shapes)

| English | 日本語 |
|---|---|
| `%lld yr(s)` / `%lld years` | `%lld年` |
| `%@/yr`, `%@ / yr` | `%@/年`, `%@ / 年` |
| `%@ a year` (a pay figure) / any other cost or growth "a year" | `年収%@` / `1年あたり%@` (growth: `年約%@`) |
| `%lld yr as %@` | `%2$@として%1$lld年` |
| `%lld yr in %@` | `%2$@で%1$lld年` |
| `(role expects %@ yr)` / `(you have %@)` | `（目安：%@年）` / `（現在%@年）` |
| `%lld yrs left` | `残り%lld年` |
| `Requires age %lld+` | `%lld歳以上が必要` |
| `Requires %lld+ yrs in %@` | `%2$@で%1$lld年以上が必要` |
| `%lld yr exp.` / `🧭 %lld yr exp expected` | `経験%lld年` / `🧭 経験%lld年が目安` |
| `Open Jobs / Activities / Events / Projects / Ventures / Boardroom / Education` | `仕事を開く／活動を開く／イベントを開く／プロジェクトを開く／起業を開く／経営会議を開く／教育を開く` |
| `%@ chance` (percent) | `%@の確率` |
| `%@ easier than usual` / `%@ harder than usual` (hire, promotion, projects) | `いつもより%@有利` / `いつもより%@不利` (must read after `：` and inside `（　）`) |
| `%@ higher than usual` / `lower than usual` (risk) | `いつもより%@高い` / `いつもより%@低い` |
| `%@ boost` / `cuts your chance to %@ of normal` | `%@アップ` / `確率が通常の%@になります` |
| `no change` / `normal` / `closes this job for now` | `変化なし` / `ふつう` / `今はこの仕事に応募できません` |
| `%@ of 5` (Japan grade scale) | `5段階中%@` |
| `Ages 7+ · easiest` / `Teens & up · full challenge` | `7歳以上 · いちばんかんたん` / `10代以上 · 本格チャレンジ` |

### 4.9 Words with two meanings in the English — the key decides

| English | Meaning A → 日本語 | Meaning B → 日本語 |
|---|---|---|
| Science | field of work / fame / degree subject → 科学 | school subject (`activity.science`) → 理科 |
| Education | screen, footer, job field, industry → 教育 | degree subject (`field.education`) → 教育学 |
| Pilot | the job → パイロット (airline ladder name 旅客機パイロット) | private-pilot licence (training) → 自家用操縦士 |
| Present | event button, always the verb → 発表 (the noun/adjective never occurs) | past "Presented" → 発表済み |
| Master | seniority rung → 熟練 (trade) | degree level → 修士 |
| Field | study / work field → 分野 | job setting "hands-on" → 現場 |
| Title | job title → 職名／役職 | award title → 称号 |
| Staff | seniority rung → スタッフ | employees ("mentoring staff") → 職員 |
| Lead | seniority rung → リード | verb "lead a team" → 率いる |
| Level | skill / activity level → レベル; "school levels below what the job wants" → 学歴の段階 | game job "Level Designer" → レベルデザイナー |
| Round | investment round → 資金調達ラウンド | contest round → 回戦 |
| Service | degree subject → サービス | "years of service" → 勤続年数 |
| Study | activities tab (noun) → 勉強 | advisor "Study for: %@" → `目指す学位：%@` |
| Apply | job → 応募 | school → 出願 (button text is shared, see §4.1) |
| Bar | "the bar" (law), `Bar Admission` → 弁護士登録 | no other use |

## 5. Job titles

**5.1 Policy.** (1) Use the natural title a Japanese job board would use; (2) gender-neutral: no ウェイトレス, 看護婦, 警官 — see the table; (3) imported professions in katakana (データサイエンティスト),
rooted professions in kanji (弁護士, 看護師); (4) slash alternatives "A/B" → one umbrella term or `A・B`; (5) one base title = one Japanese string everywhere:
`job.base.X`, `job.ladder.X` (used after "as", so it must read as a role: `%@として`) and the base part of every `job.title.*` are **identical**; (6) never add 的, 〜者, 〜員 beyond the table.
**Keys.** `job.title.<full>` = the whole title, `job.base.<role>` = the role alone, `job.ladder.<role>` = the role as a ladder (= base), `job.rung.<label>` = the seniority label alone, `job.summary.<full>` = the sentence.

**5.2 Seniority prefixes** — fixed, katakana, glued to the base with no space or dot: **Junior ジュニア · Senior シニア · Lead リード · Staff スタッフ · Principal プリンシパル**.
`Junior Software Engineer` = ジュニアソフトウェアエンジニア, `Senior Teacher` = シニア教師, `Lead Firefighter` = リード消防士, `Staff Software Engineer` = スタッフソフトウェアエンジニア, `Principal Research Scientist` = プリンシパル研究者.
Rung labels (`job.rung.*`, shown alone on the choice card): Junior ジュニア, Senior シニア, Lead リード, Staff スタッフ, Principal プリンシパル, Apprentice 見習い, Master 熟練, Charge 主任, Resident 研修医,
Sous 副料理長, Head 料理長, Executive 総料理長, Amateur アマチュア, Professional プロ, Elite エリート. `Standard` (the plain role) = 標準.
**Irregular full titles** (do not apply the prefix rule): Apprentice Carpenter/Electrician/Plumber 見習い大工／見習い電気工事士／見習い配管工; Master Carpenter/Electrician/Plumber 熟練大工／熟練電気工事士／熟練配管工;
Charge Registered Nurse 主任看護師; Resident Physician 研修医; Senior Physician 指導医; Sous Chef 副料理長; Head Chef 料理長; Executive Chef 総料理長; First Officer 副操縦士; Airline Captain 機長; Pilot パイロット;
Amateur Player アマチュア選手; Professional Player プロ選手; Elite Player エリート選手; Editor-in-Chief 編集長; News Anchor ニュースキャスター; Personal Trainer パーソナルトレーナー;
Supply Chain Manager サプライチェーンマネージャー; Warehouse Manager 倉庫マネージャー. "Chief X Officer": 最高経営責任者（CEO）, 最高医療責任者（CMO）, 最高技術責任者（CTO）; in running text "the CEO" = CEO, "chief executives" = 経営トップ.
Venture/prose "CEO, %@" = `%@のCEO`.

**5.3 Base titles (`job.base.*` and `job.ladder.*`)** — pairs `English = 日本語`:

3D Artist = 3Dアーティスト · Accountant = 会計士 · Administrative Assistant = 事務アシスタント · Aerospace Engineer = 航空宇宙エンジニア · Aircraft Maintenance Technician = 航空整備士 ·
Airline Pilot = 旅客機パイロット · Anesthesiologist = 麻酔科医 · Animator = アニメーター · Architect = 建築士 · Art Director = アートディレクター · Assembler = 組立工 · Baker = パン職人 ·
Bank Teller = 銀行窓口係 · Bartender = バーテンダー · Beautician/Cosmetologist = エステティシャン · Bookkeeping Clerk = 簿記事務員 · Boutique Fitness Studio = 少人数フィットネススタジオ ·
Bus Driver = バス運転手 · Business Analyst = ビジネスアナリスト · Carpenter = 大工 · Cashier = レジ係 · Chef = 料理人 · Chemical Engineer = 化学エンジニア · Chief Executive Officer = 最高経営責任者（CEO） ·
Chief Medical Officer = 最高医療責任者（CMO） · Chief Technology Officer = 最高技術責任者（CTO） · Childcare Worker = 保育士 · Civil Engineer = 土木技術者 · Cloud Architect = クラウドアーキテクト ·
Construction Laborer = 建設作業員 · Content Writer = コンテンツライター · Cook = 調理スタッフ · Customer Service Representative = カスタマーサポート担当 · Cybersecurity Analyst = サイバーセキュリティアナリスト ·
Data Analyst = データアナリスト · Data Scientist = データサイエンティスト · Delivery Courier = 配達員 · Dental Assistant = 歯科助手 · Dentist = 歯科医師 · Dishwasher = 洗い場スタッフ · Dispatcher = 配車係 ·
Electrical Engineer = 電気エンジニア · Electrician = 電気工事士 · Event Planner = イベントプランナー · Factory Worker = 工場作業員 · Farm-to-Table Restaurant = 産地直送レストラン · Farmer = 農家 ·
Farmhand = 農作業員 · Fashion Designer = ファッションデザイナー · Fast Food Worker = ファストフード店員 · Financial Analyst = 財務アナリスト · Firefighter = 消防士 · Fitness Instructor = フィットネスインストラクター ·
Flight Attendant = 客室乗務員 · Food Preparation Worker = 調理補助スタッフ · Forklift Operator = フォークリフト運転手 · Game Designer = ゲームデザイナー · Graphic Artist = グラフィックアーティスト ·
Groundskeeper = 緑地管理員 · HVAC Technician = 空調設備技術者 · Hairdresser/Barber = 美容師・理容師 · Heavy Equipment Operator = 重機オペレーター · Hotel Manager = ホテル支配人 · Housekeeper = 客室清掃員 ·
Human Resources Specialist = 人事担当者 · IT Support Specialist = ITサポート担当 · Indie Game Studio = インディーゲームスタジオ · Insurance Agent = 保険営業 · Interior Designer = インテリアデザイナー ·
Investment Banker = 投資銀行員 · Janitor/Cleaner = 清掃員 · Journalist = 記者 · Judge = 裁判官 · Lab Technician = ラボ技術員 · Lawyer = 弁護士 · Level Designer = レベルデザイナー ·
Licensed Practical Nurse = 准看護師 · Light Truck Delivery Driver = 小型トラック配送ドライバー · Logistics Coordinator = 物流コーディネーター · Machine Operator = 機械オペレーター · Machinist = 機械加工工 ·
Maintenance & Repair Worker = 保守・修理作業員 · Management Consultant = 経営コンサルタント · Managing Partner = 代表パートナー · Marketing Director = マーケティング本部長 · Marketing Specialist = マーケティング担当 ·
Mechanic = 整備士 · Mechanical Engineer = 機械エンジニア · Medical Assistant = 医療アシスタント · Mover = 引っ越しスタッフ · Municipal Worker = 公共サービス職員 · Narrative Designer = ナラティブデザイナー ·
Nurse Practitioner = 診療看護師 · Nursing Aide = 看護助手 · Office Clerk = 事務員 · Office Manager = オフィスマネージャー · Operations Manager = オペレーションマネージャー · Painter (Construction) = 塗装工（建設） ·
Paralegal = パラリーガル · Paramedic = 救急救命士 · Payroll Specialist = 給与計算担当 · Personal Care Aide = 介護ヘルパー · Pharmacist = 薬剤師 · Pharmacy Technician = 調剤助手 · Photographer = カメラマン ·
Physician = 医師 · Physiotherapist = 理学療法士 · Player = 選手 · Plumber = 配管工 · Police Officer = 警察官 · Project Manager = プロジェクトマネージャー · Property Development Firm = 不動産開発会社 ·
Psychologist = 心理士 · Quality Control Inspector = 品質検査員 · Real Estate Agent = 不動産仲介 · Receptionist = 受付係 · Registered Nurse = 看護師 · Research Scientist = 研究者 · Retail Salesperson = 販売員 ·
Roofer = 屋根職人 · SaaS App Startup = SaaSアプリのスタートアップ · Sales Director = 営業本部長 · Sales Manager = 営業マネージャー · Sales Representative = 営業担当 · Security Guard = 警備員 ·
Social Media Manager = SNSマネージャー · Social Worker = ソーシャルワーカー · Software Engineer = ソフトウェアエンジニア · Software Tester/QA = ソフトウェアテスター（QA） ·
Specialty Coffee Roastery = スペシャルティコーヒー焙煎所 · Stocker/Order Filler = 品出し・ピッキング担当 · Store Manager = 店長 · Surgeon = 外科医 · Systems Administrator = システム管理者 ·
TV Presenter = テレビ司会者 · Taxi Driver = タクシー運転手 · Teacher = 教師 · Teaching Assistant = 教育アシスタント · Translator/Interpreter = 翻訳・通訳者 · Truck Driver = トラック運転手 ·
Tutor = 個別指導講師 · UX/UI Designer = UX/UIデザイナー · Veterinarian = 獣医師 · Video Editor = 動画編集者 · Waiter/Waitress = ホールスタッフ · Warehouse Worker = 倉庫作業員 · Welder = 溶接工.

**5.4 Summaries (`job.summary.*`).** One or two sentences, polite present, no subject: "Creates textured, lit 3D art for games and film." → `ゲームや映画のために、質感と照明をつけた3Dアートを作ります。`
Third-person verbs (Designs, Builds, Leads) → `〜します`; imperative ventures ("Open…", "Run…", "Build…") → `〜を開きます／〜を運営します` (describes what the player does, no 〜しましょう). Keep a final 。. Job nouns inside a summary must be the table forms above.

## 6. School systems and foreign institutions

* **Stage names are Japanese everywhere.** Primary/Elementary/Grundschule/École primaire/… → `小学校`; Middle/Secondary/Junior-Secondary/Collège/… → `中学校`; the high-school stage → `高校`.
  Reason: strings like "You'll start in %@" and "(%@ done)" need a plain noun, and a Japanese player in Germany still thinks 小学校/中学校/高校. (Poland "Szkoła podstawowa (klasy 4–8)" → `小学校（4〜8年生）`; Spain "ESO" → `中学校（ESO）`.)
* **Named qualifications, grade names and tiers** keep their local flavour in the forms below (copy exactly). Latin acronyms (GPA, ATAR, ENEM, CSAT, NMT, TAFE, BTEC, BTS, IUT, ITS, UNAM, IIT, KTH …) stay Latin; a descriptor in （　） only where shown.
  Country is in the chunk comments. L = school-leaving qualification, V = vocational, C = open-access college, U = mainstream university, T = top university, G = grade name.

| Country | L | V | C | U | T | G |
|---|---|---|---|---|---|---|
| US | 高校 | 職業ディプロマ | コミュニティカレッジ | 州立大学 | 名門校（アイビーリーグ） | GPA |
| Canada | 高校卒業資格 | カレッジ・ディプロマ | カレッジ | 大学 | 研究大学トップ校（U15） | 成績平均 |
| UK | Aレベル（大学入学資格） | BTECディプロマ | 継続教育カレッジ | 大学 | オックスブリッジ／ラッセル・グループ | Aレベル成績 |
| Germany | アビトゥーア（大学入学資格） | 職業訓練（アウスビルドゥング） | 専門大学（Fachhochschule） | 大学 | エリート大学 | アビトゥーア成績 |
| France | バカロレア（高校卒業資格） | BTS | IUT | 大学 | グランゼコール | バカロレア平均 |
| Italy | マトゥリタ（高校卒業資格） | ITSディプロマ | ITSアカデミー | 大学 | 名門私立大学 | マトゥリタ点数 |
| Japan | 高校 | 専門士 | 短期大学 | 私立大学 | 国立大学 | 評定平均 |
| Ukraine | アテスタート（中等教育修了証） | 職業準学士 | カレッジ | 大学 | トップ大学 | NMTスコア |
| Australia | 高校修了証 | TAFEディプロマ | TAFE／地域の専門機関 | 大学 | グループ・オブ・エイト | ATAR |
| Brazil | エンシーノ・メジオ（高校） | 技術コース | 単科大学（Faculdade） | 公立大学 | Insper／FGV／PUC | ENEMスコア |
| China | 高校 | 職業学校（高職） | 高等職業学院 | 省立大学 | 985／双一流大学 | ガオカオの点数 |
| India | 12年生（高校） | ITI／ポリテクニック・ディプロマ | 公立学位カレッジ | 州立大学 | IIT／IIM／AIIMS | 12年生の得点率 |
| Mexico | バチジェラート（高校） | TSU（技術短大課程） | 技術大学 | 公立大学 | Tec de Monterrey／ITAM | 成績平均 |
| Poland | マトゥーラ（高校卒業資格） | 技術学校 | 専門職大学 | 大学 | UW／UJ／SGH | マトゥーラの成績 |
| Spain | バチジェラート（高校） | 職業訓練（FP） | 上級職業訓練 | 公立大学 | Carlos III／Pompeu Fabra／IE | 入学基準点 |
| Sweden | 高校卒業証書 | 職業専門学校 | 国民高等学校 | 大学 | KTH／Karolinska／Lund | 成績ポイント |
| Turkey | 高校卒業証書 | 準学士（MYO） | 職業短大 | 国立大学 | Bilkent／Koç／Sabancı | 卒業成績 |
| South Korea | 高校 | 短期大学 | 短期大学 | 地方大学 | SKY（ソウル大・高麗大・延世大） | CSAT等級 |

The bracket gloss in the L column (and the descriptor in a few V/C cells) belongs to the entry itself, so it is repeated wherever that key appears; it is never added to composites such as "Abitur grade".
Other school lines: "Elementary School" (Canada/US) 小学校; "Ensino Fundamental I／II" 小学校／中学校; "Secondary School (Class 10)" 中学校（10年生）; "Class 12 (Senior Secondary)" 12年生（高校）.
Grade expressions: `%@/20 (%@)` → `%1$@/20（%2$@）`; `%@ (1 = best)` → `%@（1が最高）`; `%@ of 5` → `5段階中%@`; `%lld/100`, `%lld/200`, `%@/%lld` unchanged.
Abitur verbal ratings: very good とても良い, good 良い, satisfactory まずまず, sufficient 合格ライン; the French mentions (très bien, bien, assez bien, passable) stay in French. SAT and ACT would stay Latin (not in the strings today).
Country names (picker and score sheet): アメリカ, カナダ, イギリス, ドイツ, フランス, イタリア, 日本, ウクライナ, オーストラリア, ブラジル, 中国, インド, メキシコ, ポーランド, スペイン, スウェーデン, トルコ, 韓国.
Country adjectives in "Scores go to their own German leaderboard." → `スコアはドイツ専用のリーダーボードに送られます。` (always `<国名>専用の`). Organisations: NHS stays NHS; HECS-HELP → HECS-HELP（オーストラリアの学費ローン）; gaokao → ガオカオ（高考）; AIIMS, UNAM, ENEM and SMIC stay as in the source.

## 7. Ten model sentences (calibrate your style on these)

| # | English | 日本語 | Why |
|---|---|---|---|
| 1 | You have to be %@ for this job — %lld more years. | この仕事は%1$@歳から。あと%2$lld年待ちましょう。 | 2 placeholders → positional; dash → 。; plural collapsed; counters added; softener in advice |
| 2 | %@ adds +%@ a year — about %lld years. | %1$@で1年に+%2$@ずつ伸びます。約%3$lld年かかります。 | three placeholders keep English order; bare numbers get 年 |
| 3 | This job expects %lld years of experience; you have %@. Working as %@ builds it. | この仕事では経験%1$lld年が求められます（現在は%2$@年）。%3$@として働くと経験が積めます。 | `%3$@` is a ladder role (教師) so `として` fits; "you" dropped |
| 4 | You could apply for %@ now, but it's a long shot (%@) — and an application spends the year. Lift your chances first. | %1$@には今でも応募できますが、望みは薄く（%2$@）、応募するとその1年を使ってしまいます。まずは確率を上げましょう。 | the long sentence stays one sentence; fixed phrase その1年を使う; ましょう for advice |
| 5 | %@ is a narrow path: even a flawless candidate is hired only about %@ of the years they apply (about %@ with a founder's track record) — so it usually takes many attempts. | %1$@は狭き門です。完璧な応募者でも、採用されるのは応募した年の約%2$@（起業実績があれば約%3$@）なので、何度も挑戦するのがふつうです。 | idiom 狭き門; 3 positional; the dash becomes a reason clause |
| 6 | Under %lld you're not considered at all; between %lld and %lld your chance is scaled down; past %lld a veteran gets a small bonus. | %1$lld年未満だと選考の対象外、%2$lld〜%3$lld年は確率が下がり、%4$lld年を超えるとベテランとして少しボーナスがつきます。 | four `%lld`, not a plural; years added; 〜 for the range |
| 7a | There are only a few hundred CEO jobs at the biggest companies, and a board's search can run for a year. | 最大手企業のCEOのポストは数百しかなく、取締役会の人選に1年かかることもあります。 | adult version: standard terms (ポスト, 取締役会) |
| 7b | A CEO is the boss of a whole company. There are only a few hundred CEO jobs at the biggest companies, so many good people never get one. | CEOは、会社ぜんたいをまとめるいちばん上の人です。大きな会社のCEOの席は数百しかないので、がんばってもなれない人がたくさんいます。 | child version: kana, short, no jargon |
| 8 | • 💵 A typical household: the first %@ of pay goes on living costs, and you save %@ of the rest. Your family pays %@ of tuition; you borrow the rest. | • 💵 ふつうの家庭：給料のうち最初の%1$@は生活費にあてられ、残りの%2$@を貯金します。授業料の%3$@は家族が払い、足りない分は借ります。 | bullet and emoji kept; money/percent arrive formatted; no 円 added; `：` for the colon |
| 9 | • %@ %@ is booming this year: %@ | • %1$@ %2$@は今年、好況です（%3$@） | icon + industry + effect phrase in `（　）`; no `：` after a finished です／ます sentence |
| 10 | Present / Presented / Present at %@ / %@ — Speaker (event buttons and award title) | 発表 / 発表済み / %@で発表 / %@の登壇者 | button = compact noun; the dash dropped for の |
| 11 | Hi, I'm your career advisor! 👋 Do you already know what job you'd like to do one day — or not yet? Either is fine. | こんにちは、キャリアアドバイザーです！👋 将来やってみたい仕事はもう決まっていますか？まだでも大丈夫ですよ。 | advisor voice: warm, ですよ; emoji kept with a space after it |
| 12 | The minimum wage (¥1,121 an hour on average) / • %@: no job pays under %@ a year. | 最低賃金（全国平均 時給1,121円） / • %1$@：年収%2$@未満の仕事はありません。 | yen literal → 円 prefix moves to suffix; the first noun phrase is inserted by code, so it ends in a noun |
| 13 | Your character grows a year older each turn. Choosing something — an activity, a course, a job — is how you spend that year, and the year passes as soon as you pick. Nothing you want to do this year? Tap the blue Skip button at the top. | ターンが進むたびに、キャラクターは1つ年をとります。活動・講座・仕事など、何かを選ぶとその1年を使ったことになり、選んだ時点で1年が過ぎます。今年はやりたいことがありませんか？上にある青い「スキップ」ボタンをタップしましょう。 | UI labels in 「」; fixed terms 活動・講座・仕事 |

## 8. Decisions for the product owner to confirm

1. **Long vowel ー.** This guide keeps the final ー on all -er/-or/-ar words (デザイナー). The brief pointed to the JIS-style "drop it on words of 3+ mora" form (デザイナ); I chose the general-purpose form because children's text and job boards use it and デザイナ/ユーザ read as software documentation. If you prefer the JIS form it is a mechanical find-and-replace over the ~45 affected words (§5.3 plus a few in §4–§5).
2. **Names of game concepts:** modes かんたん／リアルライフ; **Fame = 名声** (alternative 知名度); **Network = 人脈**; **Boardroom = 経営会議**; **Student loan = 奨学金**; **Seat = ポスト**; **Ventures = 起業** (the job field "Entrepreneurship" is 起業・経営 to keep them apart); **Offer accepted! = 採用決定！**; **Activities = 活動**.
3. **Seniority prefixes in katakana for every ladder** (ジュニア／シニア／リード／スタッフ／プリンシパル, no space), with the lexical exceptions in §5.2 (機長, 研修医, 主任看護師, 料理長 …). The result is stiff for traditional jobs (シニア教師) but identical in every chunk.
4. **Skill names:** Influencer 発信者 (avoids the social-media sense of インフルエンサー), Persuader 交渉人, Zen 平常心, Champion 努力家 (it is about grit; the trophy icon is kept), Fixer 職人, Inventor 発明家, Empath 共感者.
5. **Money display (code, not translation).** `Country.money` writes `4,380,000 ¥` and `68,000 $` for every language. A Japanese reader expects `4,380,000円` and `$68,000` (and, for big amounts, 万: 438万円). Translators may not add units, so please localise `Country.money` for ja. Likewise `Fmt.list` already gives natural `A、B、またはC`.
6. **School stages** are Japanese (小学校／中学校／高校) for every country; only named qualifications and tiers keep local flavour (table in §6).
7. **One shared key `Apply`** (job button and school-application title) is 応募; schools are 出願 only in sentences. Splitting the key in code (a `comment:` per use is not enough) would let the school screen say 出願.
8. **Voice for Simplified mode and the tutorial** is the same polite です・ます (no plain forms, no ruby); kids are served by kana choices and short sentences only.
