import Foundation
import NaturalLanguage

/// The advisor's coaching — every fact it tells the player, before any words
/// are put around it.
///
/// Where `CareerAdvisor` ranks the best moves *right now*, the coach follows a
/// player over years, and in the way they chose:
///
/// * **A role in mind** — `guide` says what stands between the player and it
///   (skills, degree, licences, years), which activity builds each skill, and
///   where the postings are.
/// * **Not decided** — `activityIdeas` points at different things to try, and
///   after a few moves `suggestions` names roles that use the skills gained.
/// * **Every move** — `checkIn` compares the player with the last review and
///   says what changed and what to correct.
///
/// Like `CareerAdvisor` it introduces no rules of its own: odds, requirements
/// and the activities' yields all come from the game's own formulas, and
/// nothing here mutates a player. The language layer (`AdvisorLanguage`) only
/// ever rephrases what this produces, so a sentence about the game can be
/// checked against the facts it came from.
enum AdvisorCoach {

    // MARK: - Tuning

    /// Moves spent trying things before the advisor names roles.
    static let exploreMoves = 3
    /// Different activities tried before a role can be read from the skills
    /// they built — a single practised skill says little about taste.
    static let minTriedActivities = 2
    /// Skill points gained (by activities, courses or events) that count as
    /// enough signal on their own.
    static let minimumGainedPoints = 3
    static let suggestionCount = 3
    static let activityIdeaCount = 3
    static let maxCheckIns = 12
    /// A fall in hire odds this big is worth a correction; a change this big is
    /// worth a mention.
    static let oddsDropWorthFlagging = 0.08
    static let oddsChangeWorthMentioning = 0.03

    // MARK: - The roles

    /// One role at every seniority level — what the player picks as a goal.
    /// Ventures are left out: they have their own capital-and-grit sheet.
    struct RoleFamily: Identifiable {
        let baseTitle: String
        let icon: String
        let category: JobCategory
        /// Entry rung first, at catalogue pay.
        let rungs: [Job]

        var id: String { baseTitle }
        var entry: Job { rungs[0] }
        /// The role's name in the player's language (`baseTitle` is the English id).
        var displayName: String { entry.displayBaseTitle }
    }

    /// A role's name in the player's language, from its `baseTitle` id; the id itself when it
    /// isn't a role.
    static func displayName(ofRole baseTitle: String) -> String {
        family(baseTitle)?.displayName ?? baseTitle
    }

    /// Every role in the game, by title, priced in `country`'s money. Built
    /// once per country: a rung's requirements and catalogue pay are fixed (only
    /// the employer's sector varies from year to year, and `guide` reads that
    /// off this year's postings).
    private static func buildFamilies(in country: Country) -> [RoleFamily] {
        let jobs = JobCatalog.allJobs(in: country).filter { !$0.isEntrepreneurial }
        return Dictionary(grouping: jobs, by: \.baseTitle)
            .map { title, rungs -> RoleFamily in
                let ordered = rungs.sorted { $0.rung < $1.rung }.map { $0.atBaseSalary() }
                return RoleFamily(baseTitle: title, icon: ordered[0].icon,
                                  category: ordered[0].category, rungs: ordered)
            }
            .sorted { $0.baseTitle < $1.baseTitle }
    }

    private static let familiesByCountry: [Country: [String: RoleFamily]] =
        Dictionary(uniqueKeysWithValues: Country.allCases.map { country in
            (country, Dictionary(uniqueKeysWithValues: buildFamilies(in: country).map { ($0.baseTitle, $0) }))
        })

    /// Every role, in the reference (US) pricing. The roles, rungs and
    /// requirements are the same in every country, so this is the list for
    /// anything about *which* roles exist — search, the fields, the model's
    /// choices. Anything that quotes pay reads `family(_:in:)`.
    static let families: [RoleFamily] = buildFamilies(in: .default)

    /// A role, priced in `country`'s money.
    static func family(_ baseTitle: String, in country: Country = .default) -> RoleFamily? {
        familiesByCountry[country]?[baseTitle]
    }

    /// The fields that have roles to pick from, in alphabetical order.
    static let fields: [JobCategory] =
        Array(Set(families.map(\.category))).sorted { $0.rawValue < $1.rawValue }

    static func families(in category: JobCategory) -> [RoleFamily] {
        families.filter { $0.category == category }
    }

    // MARK: - Finding a role by what the player types

    /// Words that carry no information in "I want to be a nurse", per language,
    /// already folded (see `fold`). English is the original list, unchanged; the others
    /// cover the same ground: "I want to be a …", "I like …", "something with …", "one day".
    /// The active language's list is joined with English's, because a player may type
    /// English words into a German game. Beyond these, a one-letter token never counts
    /// (except a single ideograph, which is a word in Japanese), and, outside English,
    /// a token that fills a large share of the catalogue's own text is dropped too
    /// (`frequentTokens`) — so a language needs no complete list.
    private static let fillerWords: [L10n.Language: Set<String>] = [
        .english: [
            "i", "im", "want", "wanna", "to", "be", "a", "an", "the", "work", "working", "as", "job", "jobs", // i18n:ignore stopword data
            "become", "like", "would", "love", "am", "in", "on", "for", "and", "or", "of", "my", "me", "do", // i18n:ignore stopword data
            "something", "with", "it", "is", "so", "maybe", "think", "really", "one", "day", // i18n:ignore stopword data
        ],
        .german: [
            "ich", "will", "mochte", "moechte", "werden", "sein", "bin", "ein", "eine", "einen", "einem", "einer", "der", "die", // i18n:ignore stopword data
            "das", "den", "dem", "des", "als", "arbeiten", "arbeit", "job", "jobs", "beruf", "gern", "gerne", "mag", "liebe", // i18n:ignore stopword data
            "im", "in", "am", "an", "auf", "fur", "und", "oder", "mit", "von", "zu", "zum", "zur", "mein", "meine", "meinen", // i18n:ignore stopword data
            "etwas", "vielleicht", "denke", "wirklich", "mal", "einmal", "tag", "eines", "ist", "es", "so", "auch", "noch", // i18n:ignore stopword data
        ],
        .french: [
            "je", "veux", "voudrais", "vouloir", "etre", "devenir", "suis", "un", "une", "le", "la", "les", "des", "du", "de", // i18n:ignore stopword data
            "en", "comme", "travailler", "travail", "metier", "job", "jobs", "aimerais", "aime", "adore", "dans", "sur", "pour", // i18n:ignore stopword data
            "et", "ou", "mon", "ma", "mes", "quelque", "chose", "avec", "ca", "est", "donc", "peut", "pense", "vraiment", // i18n:ignore stopword data
            "jour", "moi", "faire", "au", "aux", "ce", "cette", "qui", "que", // i18n:ignore stopword data
        ],
        .italian: [
            "io", "voglio", "vorrei", "vuole", "diventare", "essere", "sono", "un", "uno", "una", "il", "lo", "la", "le", "gli", // i18n:ignore stopword data
            "dei", "di", "da", "come", "lavorare", "lavoro", "mestiere", "job", "jobs", "mi", "piace", "piacerebbe", "amo", // i18n:ignore stopword data
            "in", "su", "per", "ed", "mio", "mia", "miei", "qualcosa", "con", "forse", "penso", "davvero", "giorno", "fare", // i18n:ignore stopword data
            "al", "alla", "allo", "ai", "alle", "del", "della", "dello", "nel", "nella", "che", "ma", "se", "non", "piu", // i18n:ignore stopword data
        ],
        .ukrainian: [
            "хочу", "хотів", "хотіла", "бажаю", "бути", "стати", "працювати", "робота", "роботу", "професія", "як", "та", "або", // i18n:ignore stopword data
            "на", "із", "зі", "до", "для", "про", "мій", "моя", "моє", "мої", "щось", "може", "думаю", "справді", "колись", // i18n:ignore stopword data
            "день", "мені", "подобається", "люблю", "це", "є", "десь", "дуже", // i18n:ignore stopword data
        ],
        .japanese: [
            "を", "が", "は", "に", "の", "で", "と", "も", "へ", "や", "か", "な", "ね", "よ", "て", "し", "たい", "なり", "なる", // i18n:ignore stopword data
            "ない", "です", "ます", "した", "する", "して", "します", "ある", "いる", "なりたい", "たいです", "私", "わたし", // i18n:ignore stopword data
            "僕", "ぼく", "仕事", "しごと", "職業", "好き", "すき", "働き", "働く", "みたい", "ような", "こと", "もの", "など", // i18n:ignore stopword data
            "ので", "から", "まで", "とか", "たら", "いつか", "何か", "なにか", "ほしい", "やりたい", "思う", "思っ", "おもう", // i18n:ignore stopword data
        ],
    ]

    /// A token that fills at least this share of the catalogue's own role text says nothing
    /// about any one role ("work", "people", "Arbeit"). Used outside English only, whose
    /// searches are pinned to the list above.
    static let frequentTokenShare = 0.15

    /// Case-, diacritic- and width-insensitive form of `text` for comparing what the player
    /// typed with what the catalogue says: "Ärztin" = "arztin", "Straße" = "strasse", full-width
    /// "ＡＢＣ" = "abc". Diacritics stay in Ukrainian and Japanese, where they separate
    /// letters (й/и) or carry voicing (か/が) rather than decorate.
    static func fold(_ text: String, language: L10n.Language = L10n.language) -> String {
        var options: String.CompareOptions = [.caseInsensitive, .widthInsensitive]
        if language != .japanese, language != .ukrainian { options.insert(.diacriticInsensitive) }
        return text.folding(options: options, locale: L10n.locale)
    }

    /// The words of `text`, folded, in order — no filtering. Segmented by the system's word
    /// tokenizer for `language`, so Japanese ("看護師になりたい") falls into words even
    /// though it has no spaces; a chunk the tokenizer keeps whole around an apostrophe or
    /// hyphen ("I'm", "d'accord") is split into its letter-and-number runs, as the plain
    /// English search always did.
    static func tokens(_ text: String, language: L10n.Language = L10n.language) -> [String] {
        let folded = fold(text, language: language)
        guard !folded.isEmpty else { return [] }
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = folded
        tokenizer.setLanguage(NLLanguage(rawValue: language.rawValue))
        var words: [String] = []
        tokenizer.enumerateTokens(in: folded.startIndex..<folded.endIndex) { range, _ in
            words += folded[range].split { !$0.isLetter && !$0.isNumber }.map(String.init)
            return true
        }
        return words
    }

    /// Whether `token` is empty of meaning on its own: one letter, or a listed filler word.
    static func isFiller(_ token: String, language: L10n.Language = L10n.language, frequent: Set<String> = []) -> Bool {
        if token.count <= 1 { return !isIdeograph(token) }
        if frequent.contains(token) { return true }
        return (fillerWords[language] ?? []).contains(token) || (fillerWords[.english] ?? []).contains(token)
    }

    private static func isIdeograph(_ token: String) -> Bool {
        token.unicodeScalars.contains { $0.properties.isIdeographic }
    }

    /// The tokens that fill at least `share` of `documents` (each one a role's words), for
    /// a catalogue of more than a few roles. Nothing to learn from a handful.
    static func frequentTokens(in documents: [Set<String>], share: Double = frequentTokenShare) -> Set<String> {
        guard documents.count >= 20 else { return [] }
        var counts: [String: Int] = [:]
        for document in documents { for token in document { counts[token, default: 0] += 1 } }
        let limit = share * Double(documents.count)
        return Set(counts.filter { Double($0.value) >= limit }.keys)
    }

    /// The words of `text` that say something: "I want to be a nurse" → ["nurse"].
    /// `frequent` is the language's high-frequency catalogue tokens, when known.
    static func contentWords(_ text: String, language: L10n.Language, frequent: Set<String> = []) -> [String] {
        tokens(text, language: language).filter { !isFiller($0, language: language, frequent: frequent) }
    }

    /// The words of `text` that say something, in the game's language.
    static func contentWords(_ text: String) -> [String] {
        let language = L10n.language
        return contentWords(text, language: language, frequent: searchIndex(for: language).frequent)
    }

    /// Whether two folded words are the same word for searching: equal, or one starts the
    /// other (at least four letters, allowing two to differ — "nurs" ~ "nurse", "software" ~
    /// "softwares"). German compounds also match on their head ("Krankenpfleger" ~ "pfleger"),
    /// and Japanese words match inside one another ("看護師長" ~ "看護師").
    static func matches(_ a: String, _ b: String, language: L10n.Language = L10n.language) -> Bool {
        if a == b { return true }
        let (short, long) = a.count <= b.count ? (a, b) : (b, a)
        switch language {
        case .japanese where short.count >= 2 && long.contains(short): return true
        case .german where short.count >= 5 && long.hasSuffix(short): return true
        default: break
        }
        guard short.count >= 4 else { return false }
        return long.hasPrefix(short) || short.commonPrefix(with: long).count >= max(4, short.count - 2)
    }

    /// What one role is searched against, in the game's language and in English.
    struct SearchEntry {
        let family: RoleFamily
        /// Whole titles, folded: the role's own and its display name.
        let titles: [String]
        let titleWords: [String]
        /// The words of every rung's name ("junior developer").
        let rungWords: [String]
        /// Field names (and, outside English, the industry's).
        let fields: [String]
        let summaries: [String]
    }

    struct SearchIndex {
        let entries: [SearchEntry]
        let frequent: Set<String>
    }

    private final class SearchCache: @unchecked Sendable {
        private let lock = NSLock()
        private var indexes: [L10n.Language: SearchIndex] = [:]
        func index(_ language: L10n.Language, build: () -> SearchIndex) -> SearchIndex {
            lock.lock(); defer { lock.unlock() }
            if let cached = indexes[language] { return cached }
            let built = build()
            indexes[language] = built
            return built
        }
    }
    private static let searchCache = SearchCache()

    /// The catalogue as the search reads it, built once per language.
    static func searchIndex(for language: L10n.Language) -> SearchIndex {
        searchCache.index(language) { buildSearchIndex(language) }
    }

    private static func buildSearchIndex(_ language: L10n.Language) -> SearchIndex {
        func distinct(_ items: [String]) -> [String] {
            var seen = Set<String>()
            return items.filter { seen.insert($0).inserted }
        }
        let entries = families.map { family -> SearchEntry in
            let entry = family.entry
            let titles = distinct([fold(family.baseTitle, language: language), fold(entry.displayBaseTitle, language: language)])
            let rungNames = family.rungs.flatMap { [$0.id, $0.catalogueTitle] }
            var fields = [family.category.rawValue, family.category.displayName]
            // The industry joins the field outside English only, so the English search stays as it was.
            if language != .english { fields += [entry.industry.rawValue, entry.industry.displayName] }
            return SearchEntry(
                family: family, titles: titles,
                titleWords: distinct(titles.flatMap { tokens($0, language: language) }),
                rungWords: distinct(rungNames.flatMap { tokens($0, language: language) }),
                fields: distinct(fields.map { fold($0, language: language) }),
                summaries: distinct([fold(entry.summary, language: language), fold(entry.displaySummary, language: language)]))
        }
        // High-frequency tokens are a property of the language's own text.
        let frequent: Set<String> = language == .english ? [] : frequentTokens(in: entries.map { entry in
            Set(entry.summaries.flatMap { tokens($0, language: language) } + entry.titleWords)
        })
        return SearchIndex(entries: entries, frequent: frequent)
    }

    /// The words as one phrase, to compare with a whole title. Japanese writes no spaces between
    /// its words ("システム エンジニア" is "システムエンジニア"); a Latin word typed among them keeps one.
    static func phrase(_ words: [String], language: L10n.Language) -> String {
        guard language == .japanese else { return words.joined(separator: " ") }
        var phrase = ""
        for word in words {
            if let last = phrase.last, last.isASCII || word.first?.isASCII == true { phrase += " " }
            phrase += word
        }
        return phrase
    }

    /// The roles a player's words point at, best match first: whole title, then
    /// title words, then a rung's name ("junior developer"), then the field.
    /// Deterministic, so it works — and is what the tests pin — with no language
    /// model at all. The words are read in the game's language (`L10n.language`) and
    /// compared with the roles' names and summaries in that language *and* in English.
    static func search(_ query: String, limit: Int = 6) -> [RoleFamily] {
        search(query, limit: limit, language: L10n.language)
    }

    static func search(_ query: String, limit: Int = 6, language: L10n.Language) -> [RoleFamily] {
        let index = searchIndex(for: language)
        let words = contentWords(query, language: language, frequent: index.frequent)
        guard !words.isEmpty else { return [] }
        let phrase = Self.phrase(words, language: language)

        return index.entries
            .compactMap { entry -> (family: RoleFamily, score: Int)? in
                var score = 0
                if entry.titles.contains(phrase) { score += 20 } else if entry.titles.contains(where: { $0.contains(phrase) }) { score += 10 }
                for word in words {
                    if entry.titleWords.contains(where: { matches(word, $0, language: language) }) { score += 4 }
                    else if entry.rungWords.contains(where: { matches(word, $0, language: language) }) { score += 3 }
                    if entry.fields.contains(where: { $0.contains(word) }) { score += 2 }
                    if entry.summaries.contains(where: { $0.contains(word) }) { score += 1 }
                }
                return score > 0 ? (entry.family, score) : nil
            }
            .sorted { ($0.score, $1.family.baseTitle) > ($1.score, $0.family.baseTitle) }
            .prefix(limit)
            .map(\.family)
    }

    // MARK: - Trying things

    /// Skills gained since the advisor's path began, biggest first.
    struct SkillGain: Equatable {
        let label: String
        let pictogram: String
        let gained: Int
    }

    static func skillGains(_ player: Player) -> [SkillGain] {
        let baseline = player.advisorPlan.baselineSkills
        return SoftSkills.allAxes
            .compactMap { axis -> SkillGain? in
                let gained = player.softSkills[keyPath: axis.keyPath] - baseline[keyPath: axis.keyPath]
                return gained > 0 ? SkillGain(label: axis.label, pictogram: axis.pictogram, gained: gained) : nil
            }
            .sorted { ($0.gained, $1.label) > ($1.gained, $0.label) }
    }

    /// The activities practised at least once since the path began.
    static func triedSince(_ player: Player) -> [Sport] {
        let baseline = player.advisorPlan.baselineSportYears
        return Sport.allCases.filter {
            player.sportYears[$0, default: 0] > baseline[$0, default: 0]
        }
    }

    struct ActivityIdea: Equatable, Identifiable {
        let sport: Sport
        /// What a year of it builds, e.g. "🎨 Creator +2".
        let builds: [String]

        var id: Sport { sport }
    }

    /// Different things to try: activities open to the player that they've
    /// practised least and that build skills the other picks — and the player —
    /// don't already have. Spreading the picks over different skills is the
    /// point: the goal is to find out what the player likes, not to grind one thing.
    static func activityIdeas(for player: Player, limit: Int = activityIdeaCount) -> [ActivityIdea] {
        var pool = CareerAdvisor.offeredActivities(player)
        let tried = Set(triedSince(player))
        var covered = Set<WritableKeyPath<SoftSkills, Int>>()
        var picks: [Sport] = []

        func novelty(_ sport: Sport) -> Double {
            var value = 0.0
            if player.sportYears[sport, default: 0] == 0 { value += 2 }
            if !tried.contains(sport) { value += 1 }
            for ability in sport.abilities where !covered.contains(ability.keyPath) {
                // Skills the player is already good at teach them less.
                let room = player.softSkills[keyPath: ability.keyPath] < 4 ? 1.0 : 0.4
                value += Double(ability.weight) * room
            }
            return value
        }

        while picks.count < limit, !pool.isEmpty {
            guard let best = pool.max(by: { (novelty($0), $1.rawValue) < (novelty($1), $0.rawValue) }) else { break }
            picks.append(best)
            pool.removeAll { $0 == best }
            covered.formUnion(best.abilities.map(\.keyPath))
        }
        return picks.map { sport in
            ActivityIdea(sport: sport, builds: sport.abilities.map { ability in
                let label = SoftSkills.label(forKeyPath: ability.keyPath) ?? "Skill" // i18n:ignore fallback that never shows
                let pictogram = SoftSkills.pictogram(forKeyPath: ability.keyPath) ?? ""
                return "\(pictogram) \(label) +\(ability.weight)"
            })
        }
    }

    // MARK: - Reading the skills

    struct RoleSuggestion: Equatable, Identifiable {
        let baseTitle: String
        let icon: String
        let category: JobCategory
        /// The skills that make it a fit, the ones the player has grown first —
        /// e.g. "🎨 Creator".
        let matches: [String]
        let pay: String
        /// What it would take beyond that: a degree, a licence, years of work.
        let needs: [String]
        let score: Double

        var id: String { baseTitle }
    }

    /// Roles that put the skills the player has *gained* to use. Each role's
    /// score blends how much of its skill ask the player already covers with
    /// how much of what they practised it uses, and how many of its skills they
    /// grew — so a job built on the things they tried outranks one that merely
    /// asks for a lot. One per field first, so the picks aren't five flavours
    /// of the same job.
    static func suggestions(for player: Player, limit: Int = suggestionCount) -> [RoleSuggestion] {
        let reading = SkillReading(player)
        guard reading.totalGain > 0 else { return [] }
        let scored = families
            .compactMap { reading.candidate($0, player: player) }
            .sorted { ($0.score, $1.family.baseTitle) > ($1.score, $0.family.baseTitle) }

        // One per field first, then whatever fills the rest.
        var seen = Set<JobCategory>()
        var picks = scored.filter { seen.insert($0.family.category).inserted }.prefix(limit).map { $0 }
        if picks.count < limit {
            let chosen = Set(picks.map(\.family.baseTitle))
            picks += scored.filter { !chosen.contains($0.family.baseTitle) }.prefix(limit - picks.count)
        }
        return picks
            .sorted { ($0.score, $1.family.baseTitle) > ($1.score, $0.family.baseTitle) }
            .map { suggestion(from: $0, player: player) }
    }

    /// The suggestion for one role, if the skills gained point at it at all.
    static func suggestion(_ baseTitle: String, player: Player) -> RoleSuggestion? {
        guard let family = family(baseTitle, in: player.country),
              let candidate = SkillReading(player).candidate(family, player: player) else { return nil }
        return suggestion(from: candidate, player: player)
    }

    private static func suggestion(from candidate: SkillReading.Candidate, player: Player) -> RoleSuggestion {
        // Picked from the reference list; priced in the player's country.
        let family = Self.family(candidate.family.baseTitle, in: player.country) ?? candidate.family
        return RoleSuggestion(
            baseTitle: candidate.family.baseTitle, icon: candidate.family.icon, category: candidate.family.category,
            matches: candidate.matches, pay: CareerAdvisor.payStory(family.entry, player),
            needs: guide(for: candidate.family.baseTitle, player: player)?.needs ?? [], score: candidate.score)
    }

    /// The skills gained since the path began, ready to be held against a role.
    private struct SkillReading {
        struct Candidate {
            let family: RoleFamily
            let matches: [String]
            let score: Double
        }

        var gained: [WritableKeyPath<SoftSkills, Int>: Int] = [:]
        let totalGain: Int

        init(_ player: Player) {
            let baseline = player.advisorPlan.baselineSkills
            for axis in SoftSkills.allAxes {
                let delta = player.softSkills[keyPath: axis.keyPath] - baseline[keyPath: axis.keyPath]
                if delta > 0 { gained[axis.keyPath] = delta }
            }
            totalGain = gained.values.reduce(0, +)
        }

        /// How well `family`'s entry rung uses what was gained; nil when it
        /// uses none of it.
        func candidate(_ family: RoleFamily, player: Player) -> Candidate? {
            let job = family.entry
            guard totalGain > 0, !CareerAdvisor.lacksBreakthrough(job, player) else { return nil }
            let asked = job.askedSoftSkills
            guard !asked.isEmpty else { return nil }
            var used = 0
            var hits: [(label: String, gained: Int)] = []
            for keyPath in asked {
                guard let grown = gained[keyPath] else { continue }
                used += min(grown, job.requirements.softSkills[keyPath: keyPath])
                let label = SoftSkills.label(forKeyPath: keyPath) ?? "Skill" // i18n:ignore fallback that never shows
                let pictogram = SoftSkills.pictogram(forKeyPath: keyPath) ?? ""
                hits.append((label: "\(pictogram) \(label)", gained: grown))
            }
            guard !hits.isEmpty else { return nil }
            let fit = job.softSkillFit(for: player)
            let coverage = Double(used) / Double(totalGain)
            let precision = Double(hits.count) / Double(asked.count)
            let ranked = hits.sorted { ($0.gained, $1.label) > ($1.gained, $0.label) }.prefix(3).map(\.label)
            return Candidate(family: family, matches: Array(ranked),
                             score: 0.4 * fit + 0.3 * coverage + 0.3 * precision)
        }
    }

    // MARK: - A role in mind

    /// One skill the role asks more of than the player has.
    struct SkillNeed: Equatable, Identifiable {
        let label: String
        let pictogram: String
        let have: Int
        let need: Int
        /// The activity on offer that builds it fastest, and its yearly yield.
        let activity: Sport?
        let perYear: Int?

        var id: String { label }

        /// Years of that activity to close the gap.
        var years: Int? {
            perYear.map { Int((Double(need - have) / Double(max(1, $0))).rounded(.up)) }
        }
    }

    /// One thing between the player and a role, in the order to do it.
    struct Step: Equatable {
        enum Kind: Equatable { case listing, age, education, licence, skill, experience, apply, climb }
        let kind: Kind
        let card: AdvisorCard
    }

    /// What it takes to reach a role, from where the player stands.
    struct RoleGuide {
        let family: RoleFamily
        /// The rung the advice is aimed at: the entry rung — or, for a player
        /// already on the ladder, the one above theirs.
        let focus: Job
        /// Whether that rung is among this year's postings (the Jobs sheet
        /// lists only those).
        let posted: Bool
        /// Whether the player already works this role's ladder.
        let onLadder: Bool
        /// Whether they hold its top rung.
        let atTop: Bool
        /// Hire odds today — nil in Simplified, which hires with certainty
        /// once the requirements are met.
        let odds: Double?
        /// A hard requirement (age, degree, licence, years) is missing, so the
        /// role is closed today.
        let closed: Bool
        let skills: [SkillNeed]
        let steps: [Step]
        /// What it would take, in a phrase each: a degree, licences, years.
        let needs: [String]
        let pay: String

        /// The role's id (`Job.baseTitle`).
        var title: String { family.baseTitle }
        /// The role's name in the player's language.
        var displayTitle: String { family.displayName }
        var cards: [AdvisorCard] { steps.map(\.card) }
        var canApply: Bool { !closed && (odds.map { $0 >= CareerAdvisor.minimumApplyOdds } ?? true) }
        /// Whether the advice is about the next rung up rather than getting in.
        var isPromotion: Bool { onLadder && !atTop }
    }

    /// The rung advice is aimed at: the entry rung — or, on the ladder, the next
    /// one up, or the top rung held.
    private static func focusRung(of family: RoleFamily, player: Player) -> (job: Job, onLadder: Bool, atTop: Bool) {
        guard let current = player.currentOccupation, current.baseTitle == family.baseTitle else {
            return (family.entry, false, false)
        }
        if let next = family.rungs.first(where: { $0.rung == current.rung + 1 }) {
            return (next, true, false)
        }
        return (family.rungs.last ?? family.entry, true, true)
    }

    /// The skills `job` asks more of than the player has, the biggest gap first.
    static func skillNeeds(for job: Job, player: Player) -> [SkillNeed] {
        let activities = CareerAdvisor.offeredActivities(player)
        return job.askedSoftSkills
            .compactMap { keyPath -> SkillNeed? in
                let need = job.requirements.softSkills[keyPath: keyPath]
                let have = player.softSkills[keyPath: keyPath]
                guard have < need, let axis = SoftSkills.allAxes.first(where: { $0.keyPath == keyPath }) else { return nil }
                let best = CareerAdvisor.bestActivity(for: keyPath, among: activities)
                return SkillNeed(label: axis.label, pictogram: axis.pictogram, have: have, need: need,
                                 activity: best?.0, perYear: best?.1)
            }
            .sorted { lhs, rhs in
                let l = Double(lhs.need - lhs.have) / Double(lhs.need)
                let r = Double(rhs.need - rhs.have) / Double(rhs.need)
                return (l, rhs.label) > (r, lhs.label)
            }
    }

    /// The qualification a role's education floor stands for, in words. A noun phrase that
    /// slots in as the object of "get" / "you'll need" / "still missing", so it keeps no
    /// article-dependent case beyond that.
    static func degreePhrase(minEQF: Int) -> String {
        switch minEQF {
        case ..<4: return String(localized: "a school diploma", comment: "A qualification, as the object of 'Get …' / 'You'll need …' / 'Still missing: …' in the career advisor's steps (secondary-school level)")
        case 4: return String(localized: "a college or vocational diploma", comment: "A qualification, as the object of 'Get …' / 'You'll need …' (post-secondary vocational level, EQF 4)")
        case 5: return String(localized: "a bachelor's degree", comment: "A qualification, as the object of 'Get …' / 'You'll need …' (EQF 5)")
        case 6: return String(localized: "a master's degree", comment: "A qualification, as the object of 'Get …' / 'You'll need …' (EQF 6)")
        default: return String(localized: "a doctorate", comment: "A qualification, as the object of 'Get …' / 'You'll need …' (EQF 7)")
        }
    }

    /// What a role asks of education, in words: "a bachelor's degree in Business".
    static func educationPhrase(for job: Job) -> String {
        let edu = job.requirements.education
        let fields = Fmt.list((edu.acceptedProfiles ?? []).map(\.displayName), .or)
        guard !fields.isEmpty else { return degreePhrase(minEQF: edu.minEQF) }
        switch edu.minEQF {
        case ..<4: return String(localized: "a school diploma in \(fields)", comment: "A qualification with its field(s), e.g. 'a school diploma in Health or Science'. The argument is a list of study fields joined with 'or'")
        case 4: return String(localized: "a college or vocational diploma in \(fields)", comment: "A qualification with its field(s). The argument is a list of study fields joined with 'or'")
        case 5: return String(localized: "a bachelor's degree in \(fields)", comment: "A qualification with its field(s). The argument is a list of study fields joined with 'or'")
        case 6: return String(localized: "a master's degree in \(fields)", comment: "A qualification with its field(s). The argument is a list of study fields joined with 'or'")
        default: return String(localized: "a doctorate in \(fields)", comment: "A qualification with its field(s). The argument is a list of study fields joined with 'or'")
        }
    }

    /// What the advisor tells a player who has picked `baseTitle`. Nil for a
    /// title that isn't a role.
    static func guide(for baseTitle: String, player: Player) -> RoleGuide? {
        guard let family = family(baseTitle, in: player.country) else { return nil }
        let (rung, onLadder, atTop) = focusRung(of: family, player: player)
        let posting = player.availableJobs.first { $0.id == rung.id && !$0.isEntrepreneurial }
        let focus = (posting ?? rung).atBaseSalary()
        let simplified = player.isSimplified
        let fit = focus.requirementFit(for: player)
        let odds: Double? = simplified ? nil
            : focus.hireProbability(for: player, requestedSalary: Double(CareerAdvisor.offer(focus, player)))
        let closed = fit.isBlocked

        // Soft skills don't count when Simplified hires — except for the young,
        // for whom they shape admissions.
        let scoresSkills = !simplified || player.age < GameConstants.minimumWorkingAge
        let skills = scoresSkills && !atTop ? skillNeeds(for: focus, player: player) : []

        var steps: [Step] = []
        var needs: [String] = []
        func add(_ kind: Step.Kind, _ icon: String, _ detail: String, title: String = "", _ actions: [AdvisorAction] = []) {
            steps.append(Step(kind: kind, card: AdvisorCard(icon: icon, title: title, detail: detail, actions: actions)))
        }

        let pay = CareerAdvisor.payStory(focus, player)
        let listed = !onLadder && posting != nil
        let roleName = family.displayName
        if !onLadder {
            if listed {
                add(.listing, "🔎", L("See who's hiring for \(roleName) this year."),
                    [AdvisorAction(label: CareerAdvisor.Destination.listing(family.baseTitle).buttonLabel, effect: .go(.listing(family.baseTitle)))])
            } else {
                add(.listing, "🔎", L("Nobody is posting \(roleName) jobs this year — the market changes every year, so check again next year."))
            }
        }

        if atTop { return finish() }

        // Too young.
        if fit.age == 0 {
            let years = max(1, focus.minimumHireAge - player.age)
            add(.age, "🎂", L("You have to be \(String(focus.minimumHireAge)) for this job — \(years) more years."))
        }

        // The degree.
        let edu = focus.requirements.education
        let inSchool = player.currentEducation != nil
        if !focus.educationMet(for: player), edu.minEQF >= 4 || !inSchool {
            let phrase = educationPhrase(for: focus)
            needs.append(phrase)
            if let studying = player.currentEducation, studying.profile != nil,
               studying.eqf >= edu.minEQF,
               (edu.acceptedProfiles ?? []).isEmpty || studying.profile.map({ (edu.acceptedProfiles ?? []).contains($0) }) == true {
                add(.education, "🎓", L("Keep studying — your \(studying.degreeName(in: player.country)) is what this job asks for."))
            } else if CareerAdvisor.canOpenEducation(player) {
                add(.education, "🎓", String(localized: "Get \(phrase). It's the longest step, so start early.", comment: "Advisor step. The argument is a qualification as a noun phrase, e.g. 'a bachelor's degree in Business'"),
                    [AdvisorAction(label: CareerAdvisor.Destination.education.buttonLabel, effect: .go(.education))])
            } else {
                add(.education, "🎓", String(localized: "You'll need \(phrase) — that comes after school.", comment: "Advisor step for a player still at school. The argument is a qualification as a noun phrase, e.g. 'a bachelor's degree in Business'"))
            }
        }

        // The licences.
        for licence in CareerAdvisor.missingCredentials(for: focus, player: player).prefix(2) {
            needs.append(licence.friendlyName)
            switch licence.requirements(player) {
            case .ok:
                add(.licence, "🪪", L("Earn this credential: \(licence.friendlyName) — this job won't hire without it."),
                    [AdvisorAction(label: CareerAdvisor.Destination.education.buttonLabel, effect: .go(.education))])
            case .blocked(let reason):
                add(.licence, "🪪", L("Earn this credential: \(licence.friendlyName) — this job won't hire without it. (\(reason).)"))
            }
        }

        // The skills.
        for need in skills.prefix(3) {
            var detail = L("Grow \(need.label) from \(need.have) to \(need.need).")
            var actions: [AdvisorAction] = []
            if let activity = need.activity, let perYear = need.perYear, let years = need.years {
                detail += AdvisorCoach.sentenceGap + L("\(activity.label) adds +\(String(perYear)) a year — about \(years) years.")
                actions = [AdvisorAction(label: CareerAdvisor.Destination.activities(activity.kind).buttonLabel, effect: .go(.activities(activity.kind)))]
            }
            add(.skill, need.pictogram, detail, actions)
        }

        // The years.
        let wanted = focus.requirements.minYearsExperience
        let years = focus.relevantYears(for: player)
        if wanted > 0, years < wanted {
            needs.append(L("\(wanted) years of experience"))
            let text = focus.displayExperienceLadder.map {
                L("This job expects \(wanted) years of experience; you have \(String(years)). Working as \($0) builds it.")
            } ?? L("This job expects \(wanted) years of experience; you have \(String(years)). Working in \(focus.category.displayName) builds it.")
            add(.experience, "🧭", text,
                [AdvisorAction(label: CareerAdvisor.Destination.jobs(focus.workSetting).buttonLabel, effect: .go(.jobs(focus.workSetting)))])
        }

        // The way in — or up.
        if onLadder {
            if let tip = CareerAdvisor.climbTip(player), tip.job.baseTitle == family.baseTitle {
                add(.climb, "📈", tip.detail, tip.destination.map { [AdvisorAction(label: $0.buttonLabel, effect: .go($0))] } ?? [])
            } else {
                add(.climb, "📈", L("Keep working — the next step up is \(focus.catalogueTitle) (\(pay))."))
            }
        } else if !closed {
            let listingAction = [AdvisorAction(label: CareerAdvisor.Destination.listing(family.baseTitle).buttonLabel, effect: .go(.listing(family.baseTitle)))]
            if listed {
                let shot = odds ?? 1
                let text: String
                if simplified {
                    text = L("You can apply for \(focus.catalogueTitle) now!")
                } else if shot >= CareerAdvisor.minimumApplyOdds {
                    text = L("You can apply for \(focus.catalogueTitle) now — a \(CareerAdvisor.percent(shot)) chance.")
                } else {
                    // Applying spends the whole year, so a long shot is a real cost.
                    text = L("You could apply for \(focus.catalogueTitle) now, but it's a long shot (\(AdvisorPathway.chance(shot))) — and an application spends the year. Lift your chances first.")
                }
                add(.apply, shot >= CareerAdvisor.minimumApplyOdds || simplified ? "✅" : "🎲", text, listingAction)
            } else {
                add(.apply, "✅", L("You could apply for \(focus.catalogueTitle) — but there are no postings this year."))
            }
        }

        return finish()

        func finish() -> RoleGuide {
            RoleGuide(family: family, focus: focus, posted: posting != nil, onLadder: onLadder, atTop: atTop,
                      odds: odds, closed: closed, skills: skills, steps: steps, needs: needs, pay: pay)
        }
    }

    /// The opening line of a guide: the role, its pay and where the player stands.
    static func introduction(_ guide: RoleGuide, player: Player) -> String {
        let focus = guide.focus
        if guide.atTop { return L("You've reached the top of the \(guide.displayTitle) ladder — \(focus.catalogueTitle)! 🏆") }
        if guide.isPromotion, let current = player.currentOccupation {
            return L("You're working as \(current.catalogueTitle). The next step up is \(focus.catalogueTitle): \(guide.pay).")
        }
        // A ladder's entry rung has a name of its own ("First Officer"): say how
        // it relates to the role the player picked ("Airline Pilot").
        var sentences = [focus.id == guide.title
            ? L("\(guide.displayTitle) pays \(guide.pay).")
            : L("\(guide.displayTitle) starts at \(focus.catalogueTitle), which pays \(guide.pay).")]
        if guide.closed {
            sentences.append(L("You can't be hired for it yet."))
        } else if let odds = guide.odds {
            sentences.append(L("Your chance to be hired today is \(CareerAdvisor.percent(odds))."))
        } else {
            sentences.append(L("You can apply for it now!"))
        }
        return guide.family.icon + " " + sentences.joinedAsSentences()
    }

    /// The facts a guide rests on, one per line — what the language layer may
    /// draw numbers from.
    static func facts(_ guide: RoleGuide, player: Player) -> [String] {
        var facts = [introduction(guide, player: player)]
        // Phrased as what is still to do, so a model can't read a suggestion
        // ("Cycling adds +3 a year") as something the player already does.
        facts += guide.steps
            .filter { ![.listing, .apply].contains($0.kind) && !$0.card.detail.isEmpty }
            .prefix(5)
            .map { "Still to do: \($0.card.detail)" } // i18n:ignore model-facing fact, never shown to the player
        return facts
    }

    // MARK: - Every move

    /// Starts (or restarts) a path: fixes the baseline the skills gained and
    /// the progress made are measured from. Returns the plan; the caller stores it.
    static func begin(_ path: AdvisorPlan.Path, for player: Player) -> AdvisorPlan {
        var plan = player.advisorPlan
        plan.path = path
        plan.startedAge = player.age
        plan.baselineSkills = player.softSkills
        plan.baselineSportYears = player.sportYears
        plan.checkIns = []
        plan.unreadCount = 0
        plan.lastMark = mark(for: player, guide: plan.target.flatMap { guide(for: $0, player: player) })
        return plan
    }

    static func mark(for player: Player, guide: RoleGuide?) -> AdvisorPlan.Mark {
        var mark = AdvisorPlan.Mark(age: player.age, skills: player.softSkills, licences: player.hardSkills.trainings,
                                    educationLevel: player.highestEQF,
                                    years: guide?.focus.relevantYears(for: player) ?? 0,
                                    odds: guide?.odds, onLadder: guide?.onLadder ?? false)
        if let job = guide?.focus {
            mark.fame = player.famePoints(for: job.category.fameCategory)
            mark.network = player.networkPoints(for: job.category)
        }
        mark.founderPoints = player.founderTrackRecordPoints
        return mark
    }

    /// The review of the year that has just passed: how the player stands
    /// against the plan, what changed since the last review, and what to change.
    /// Nil when there's nothing to review — the advisor hasn't asked yet, or a
    /// finished goal has already been celebrated.
    static func checkIn(for player: Player) -> (checkIn: AdvisorCheckIn, mark: AdvisorPlan.Mark)? {
        switch player.advisorPlan.path {
        case .unasked: return nil
        case .exploring: return exploringCheckIn(player)
        case .target(let title): return targetCheckIn(title, player)
        }
    }

    private static func exploringCheckIn(_ player: Player) -> (checkIn: AdvisorCheckIn, mark: AdvisorPlan.Mark)? {
        let moves = player.advisorPlan.moves(for: player)
        let tried = triedSince(player)
        let gains = skillGains(player)
        let gainedPoints = gains.reduce(0) { $0 + $1.gained }
        let canPractise = !CareerAdvisor.offeredActivities(player).isEmpty
        let hasSignal = tried.count >= minTriedActivities || gainedPoints >= minimumGainedPoints || !canPractise

        var progress: [String] = []
        if !tried.isEmpty {
            progress.append(L("🧪 You've tried \(Fmt.list(tried.map(\.label)))."))
        }
        if !gains.isEmpty {
            let grown = Fmt.list(gains.prefix(4).map { "\($0.pictogram) \($0.label) +\($0.gained)" })
            progress.append(L("📈 Skills you've grown: \(grown)."))
        }

        let verdict: AdvisorCheckIn.Verdict
        let headline: String
        var suggestions: [String] = []
        var corrections: [AdvisorCard] = []
        let picks = moves >= exploreMoves && hasSignal ? Self.suggestions(for: player) : []
        if !picks.isEmpty {
            verdict = .readyToSuggest
            headline = L("You've tried a few things — I found jobs that might suit you!")
            suggestions = picks.map(\.baseTitle)
        } else {
            verdict = .exploring
            let left = exploreMoves - moves
            headline = left > 0
                ? L("\(left) more moves of trying new things, and I'll suggest jobs that fit you.")
                : L("Try a couple more different things, so I can see what you like.")
            let ideas = activityIdeas(for: player)
            if let idea = ideas.first, canPractise {
                let builds = Fmt.list(idea.builds)
                let open = [AdvisorAction(label: CareerAdvisor.Destination.activities(idea.sport.kind).buttonLabel,
                                          effect: .go(.activities(idea.sport.kind)))]
                if player.lastYearSports.isEmpty {
                    corrections.append(AdvisorCard(
                        icon: idea.sport.pictogram,
                        title: String(localized: "Try something", comment: "Title of an advisor card nudging a player who practised nothing last year to try a new activity"),
                        detail: L("You didn't practise anything last year. This year, try \(idea.sport.label) — it builds \(builds)."),
                        actions: open))
                } else if tried.count == 1, moves >= 2, let first = tried.first {
                    corrections.append(AdvisorCard(
                        icon: idea.sport.pictogram,
                        title: String(localized: "Try something different", comment: "Title of an advisor card nudging a player who has stuck with one activity to try another"),
                        detail: L("You've stuck with \(first.label). To find what you like, try \(idea.sport.label) — it builds \(builds)."),
                        actions: open))
                }
            }
        }
        let check = AdvisorCheckIn(age: player.age, verdict: verdict, role: nil, headline: headline,
                                   progress: progress, corrections: corrections, suggestions: suggestions)
        return (check, mark(for: player, guide: nil))
    }

    private static func targetCheckIn(_ title: String, _ player: Player) -> (checkIn: AdvisorCheckIn, mark: AdvisorPlan.Mark)? {
        guard let guide = guide(for: title, player: player) else { return nil }
        let plan = player.advisorPlan
        let now = mark(for: player, guide: guide)
        let focus = guide.focus

        // What changed since the last review.
        let roleName = guide.displayTitle
        var progress: [String] = []
        var moved = false
        if let before = plan.lastMark {
            if !before.onLadder, now.onLadder {
                progress.append(L("🎉 You got a job on the \(roleName) ladder!"))
                moved = true
            }
            for need in scoredNeeds(of: focus, player: player) {
                let then = before.skills[keyPath: need.keyPath]
                let have = player.softSkills[keyPath: need.keyPath]
                guard have > then else { continue }
                moved = true
                let skill = "\(need.pictogram) \(need.label)"
                progress.append(have >= need.need
                    ? L("✅ \(skill) is now \(have) — the job asks for \(need.need).")
                    : L("📈 \(skill) went from \(then) to \(have) (the job asks for \(need.need))."))
            }
            if now.educationLevel > before.educationLevel, let degree = player.degrees.last {
                moved = true
                progress.append(L("🎓 You earned your \(degree.degreeName(in: player.country))."))
            }
            let earned = now.licences.subtracting(before.licences)
            if !earned.isEmpty {
                moved = true
                progress.append(L("🪪 You earned: \(Fmt.list(earned.map(\.friendlyName).sorted()))."))
            }
            let wanted = focus.requirements.minYearsExperience
            if wanted > 0, now.years > before.years, now.years <= wanted {
                moved = true
                progress.append(L("🧭 Another year of experience: \(now.years) of the \(wanted) this job expects."))
            }
            if let bucket = focus.category.fameCategory, now.fame > before.fame + 0.05 {
                moved = true
                let fame = "\(bucket.icon) \(bucket.displayName)"
                progress.append(L("🌟 Your \(fame) fame went from \(AdvisorPathway.decimal(before.fame)) to \(AdvisorPathway.decimal(now.fame))."))
            }
            if now.network > before.network {
                moved = true
                progress.append(L("🤝 Your network in \(focus.category.displayName) grew from \(before.network) to \(now.network)."))
            }
            if now.founderPoints > before.founderPoints + 0.05, focus.isExecutive {
                moved = true
                let capPoints = GameConstants.executiveTrackRecordCap / GameConstants.executiveTrackRecordPerPoint
                progress.append(L("🏗️ Your founder track record grew from \(AdvisorPathway.decimal(before.founderPoints)) to \(AdvisorPathway.decimal(now.founderPoints)) of \(AdvisorPathway.decimal(capPoints)) — the seat chance is now \(AdvisorPathway.percent(focus.seatChance(for: player)))."))
            }
            if let was = before.odds, let odds = now.odds, abs(odds - was) >= oddsChangeWorthMentioning {
                progress.append(L("🎯 Your chance to be hired went from \(CareerAdvisor.percent(was)) to \(CareerAdvisor.percent(odds))."))
            }
        }

        // Where that leaves them.
        let verdict: AdvisorCheckIn.Verdict
        let headline: String
        if guide.atTop {
            verdict = .goalReached
            headline = L("You made it! You're at the top of the \(roleName) ladder: \(focus.catalogueTitle). 🏆")
            // Celebrated once, not every year after.
            if plan.checkIns.last?.verdict == .goalReached { return nil }
        } else if guide.isPromotion {
            verdict = .onTrack
            headline = L("You're working toward \(focus.catalogueTitle) — the next step up the \(roleName) ladder.")
        } else if guide.canApply && guide.posted {
            verdict = .ready
            headline = guide.odds.map { L("You're ready to apply for \(focus.catalogueTitle) — your chance is \(CareerAdvisor.percent($0)).") }
                ?? L("You're ready to apply for \(focus.catalogueTitle)!")
        } else if guide.canApply {
            // Qualified, but nobody is hiring this year.
            verdict = .onTrack
            headline = L("You're qualified for \(focus.catalogueTitle) — now it's a matter of waiting for a posting.")
        } else if moved {
            verdict = .onTrack
            headline = L("You're getting closer to \(roleName). Nice work!")
        } else {
            verdict = .needsCorrection
            headline = L("This year didn't move you closer to \(roleName).")
        }

        // What to change.
        var corrections: [AdvisorCard] = []
        if !guide.atTop {
            if !guide.posted, !guide.onLadder {
                corrections.append(AdvisorCard(
                    icon: "⏳",
                    title: String(localized: "Not hiring right now", comment: "Title of an advisor card: nobody is posting the player's goal role this year"),
                    detail: L("Nobody is posting \(roleName) jobs this year. Keep building your skills and check again next year.")))
            }
            if let was = plan.lastMark?.odds, let odds = now.odds, was - odds >= oddsDropWorthFlagging {
                var detail = L("Your chance to be hired dropped from \(CareerAdvisor.percent(was)) to \(CareerAdvisor.percent(odds)).")
                if player.climate(for: focus.industry) == .slump {
                    detail += AdvisorCoach.sentenceGap + L("The \(focus.industry.displayName) industry is in a slump, so employers are hiring less. Keep building skills and try again when it recovers.")
                }
                corrections.append(AdvisorCard(
                    icon: "📉",
                    title: String(localized: "Your chances fell", comment: "Title of an advisor card: the player's hire odds for the goal role dropped since the last review"),
                    detail: detail))
            }
            // Where the odds really turn — the levers of a hard-to-reach role.
            let path = AdvisorPathway.pathway(for: guide, player: player)
            if let path {
                if path.odds.strength >= 0.999, !path.cappedLevers.isEmpty {
                    let names = Fmt.list(path.cappedLevers.filter { $0.kind != .seat }.map(\.title))
                    var detail = L("Your application is already at the game's ceiling, so more of these changes nothing for now: \(names).")
                    if let next = path.bestMove { detail += AdvisorCoach.sentenceGap + L("What's left: \(next.lever.title).") }
                    corrections.append(AdvisorCard(
                        icon: "🎯",
                        title: String(localized: "Enough polish", comment: "Title of an advisor card: the application is already as strong as the game counts"),
                        detail: detail, actions: path.bestMove?.source.actions ?? []))
                }
                if !moved, let next = path.bestMove {
                    var detail = L("\(next.lever.title) is worth about +\(AdvisorPathway.points(next.lever.potential)) chance a year.")
                    detail += AdvisorCoach.sentenceGap + L("\(next.source.title): \(next.source.detail)")
                    corrections.append(AdvisorCard(
                        icon: next.lever.icon,
                        title: String(localized: "Your biggest lever", comment: "Title of an advisor card naming the one thing that would raise the player's hire odds most"),
                        detail: detail, actions: next.source.actions))
                }
            }
            if path == nil, !moved, let lead = guide.skills.first, let activity = lead.activity, let perYear = lead.perYear {
                let practised = player.lastYearSports
                let helped = practised.contains { sport in
                    guide.skills.contains { need in sport.abilities.contains { SoftSkills.label(forKeyPath: $0.keyPath) == need.label } }
                }
                if !helped {
                    let detail = practised.isEmpty
                        ? L("Last year didn't build any of the skills this job asks for. Try \(activity.label) — it adds \(lead.label) +\(String(perYear)) a year (you're at \(lead.have), the job asks for \(lead.need)).")
                        : L("Last year you practised \(Fmt.list(practised.map(\.label).sorted())) — good, but it doesn't build what \(roleName) asks for. Try \(activity.label) for \(lead.label) (you're at \(lead.have), the job asks for \(lead.need)).")
                    corrections.append(AdvisorCard(
                        icon: lead.pictogram,
                        title: String(localized: "Practise what the job needs", comment: "Title of an advisor card: last year's activities did not build the skills the goal role asks for"),
                        detail: detail,
                        actions: [AdvisorAction(label: CareerAdvisor.Destination.activities(activity.kind).buttonLabel, effect: .go(.activities(activity.kind)))]))
                }
            }
            // Never leave a stalled year without a next step.
            if verdict == .needsCorrection, corrections.isEmpty,
               let next = guide.steps.first(where: { ![.listing, .apply].contains($0.kind) }) {
                corrections.append(AdvisorCard(
                    icon: next.card.icon,
                    title: String(localized: "Your next step", comment: "Title of an advisor card: the next requirement to work on for the goal role"),
                    detail: next.card.detail, actions: next.card.actions))
            }
        }

        let check = AdvisorCheckIn(age: player.age, verdict: verdict, role: title, headline: headline,
                                   progress: progress, corrections: Array(corrections.prefix(3)), suggestions: [])
        return (check, now)
    }

    /// The soft skills a role asks for, with their pictograms — for reading
    /// what a year changed. Empty where Simplified hiring ignores skills.
    private static func scoredNeeds(of job: Job, player: Player)
        -> [(keyPath: WritableKeyPath<SoftSkills, Int>, label: String, pictogram: String, need: Int)] {
        guard !player.isSimplified || player.age < GameConstants.minimumWorkingAge else { return [] }
        return job.askedSoftSkills.compactMap { keyPath in
            guard let axis = SoftSkills.allAxes.first(where: { $0.keyPath == keyPath }) else { return nil }
            return (keyPath, axis.label, axis.pictogram, job.requirements.softSkills[keyPath: keyPath])
        }
    }

    /// The facts a review rests on, one per line.
    static func facts(_ checkIn: AdvisorCheckIn) -> [String] {
        [checkIn.headline] + checkIn.progress + checkIn.corrections.map(\.detail)
    }

    /// What the advisor knows about the player, one fact per line — what a
    /// free question is answered from.
    ///
    /// These lines are written for the language model, not the player: the model is told
    /// which language to answer in, so its own wrapper sentences stay English. The names and
    /// qualifications inside them are the player's language.
    static func playerFacts(_ player: Player) -> [String] {
        var facts = ["The player is \(player.age) years old."] // i18n:ignore model-facing fact, never shown to the player
        if player.isSimplified {
            // What a model needs to answer "how do I get hired?" correctly here.
            facts.append("They are playing the Simplified mode: getting hired only takes the right school, enough years of work and being old enough. There are no odds, luck, fame or seats to worry about.") // i18n:ignore model-facing fact
        }
        if let job = player.currentOccupation {
            facts.append("They work as \(job.catalogueTitle), earning \(CareerAdvisor.money(job.annualIncome, player)) a year.") // i18n:ignore model-facing fact
        } else {
            facts.append("They have no job right now.") // i18n:ignore model-facing fact
        }
        facts.append("Their best qualification: \(player.degrees.max { $0.eqf < $1.eqf }?.degreeName(in: player.country) ?? "none yet").") // i18n:ignore model-facing fact
        let strongest = SoftSkills.allAxes
            .map { (label: $0.label, value: player.softSkills[keyPath: $0.keyPath]) }
            .filter { $0.value > 0 }
            .sorted { ($0.value, $1.label) > ($1.value, $0.label) }
            .prefix(4)
        if !strongest.isEmpty {
            facts.append("Their strongest skills (out of 10): " + strongest.map { "\($0.label) \($0.value)" }.joined(separator: ", ") + ".") // i18n:ignore model-facing fact
        }
        switch player.advisorPlan.path {
        case .target(let title):
            if let guide = guide(for: title, player: player) {
                facts.append("Their goal is \(guide.displayTitle).") // i18n:ignore model-facing fact
                facts += Self.facts(guide, player: player)
                if let path = AdvisorPathway.pathway(for: guide, player: player) { facts += path.facts }
                if let note = AdvisorRealWorld.note(for: guide.focus, player: player) { facts += note.facts }
            }
        case .exploring:
            facts.append("They haven't chosen a role and are trying different activities to find one.") // i18n:ignore model-facing fact
        case .unasked:
            break
        }
        return facts
    }

    /// Whole sentences set one after another: a space between them, except in Japanese, which
    /// writes no space after a full stop.
    static func sentences(_ parts: [String]) -> String {
        parts.filter { !$0.isEmpty }.joined(separator: sentenceGap)
    }

    /// What goes between two sentences: a space, or nothing in Japanese.
    static var sentenceGap: String { L10n.language == .japanese ? "" : " " }

    /// "a, b and c" — or "a, b or c". A thin forwarder to `Fmt.list`, which follows the game's language.
    static func list(_ items: [String], conjunction: String = "and") -> String {
        Fmt.list(items, conjunction == "or" ? .or : .and)
    }
}

extension AdvisorPlan {
    /// Files a year's review: it becomes the yardstick for the next one and
    /// waits, unread, for the player to open the advisor.
    mutating func record(_ review: (checkIn: AdvisorCheckIn, mark: Mark)) {
        lastMark = review.mark
        checkIns.append(review.checkIn)
        if checkIns.count > AdvisorCoach.maxCheckIns {
            checkIns.removeFirst(checkIns.count - AdvisorCoach.maxCheckIns)
        }
        unreadCount += 1
    }
}

extension Array where Element == String {
    /// The elements as whole sentences one after another (`AdvisorCoach.sentences`).
    func joinedAsSentences() -> String { AdvisorCoach.sentences(self) }
}
