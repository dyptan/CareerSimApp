import Foundation
import Combine
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif

// MARK: - The language layer's contract

/// What the language layer is asked to put into words: what the message is
/// about, the facts it may quote, and the plain text the game would show with
/// no model at all. The facts are the only source of numbers — see `AdvisorGuard`.
/// `voice` says who is reading, so a beginner isn't handed a textbook.
struct AdvisorBrief: Equatable {
    let topic: String
    let facts: [String]
    let plain: String
    var voice: AdvisorVoice = .standard
}

/// What a player's typed words ask for.
enum AdvisorIntent: Equatable {
    /// They named a role — always one that exists (a `Job.baseTitle`).
    case chooseRole(String)
    /// They haven't decided what they want to do.
    case undecided
    /// Anything else: a question to answer.
    case question
}

/// Something that can talk. The advisor's *judgement* is `AdvisorCoach`'s; this
/// only reads the player's words and phrases the coach's facts, so a model that
/// is unavailable, slow or wrong costs nothing but warmth — every method may
/// answer nil, and the conversation then falls back to the plain text.
protocol AdvisorLanguage: Sendable {
    /// Whether it can take free-form words right now.
    var isAvailable: Bool { get }
    /// A line for the player when it isn't (Apple Intelligence off, say).
    var note: String? { get }
    /// Gets ready ahead of the first request, to shorten the wait.
    func prewarm()
    /// The brief in the advisor's own voice.
    func narrate(_ brief: AdvisorBrief) async -> String?
    /// What the player's words ask for.
    func interpret(_ text: String) async -> AdvisorIntent?
    /// An answer to a free question, drawn from the brief's facts.
    func answer(_ question: String, brief: AdvisorBrief) async -> String?
}

extension AdvisorLanguage {
    var note: String? { nil }
    func prewarm() {}
}

/// No model: the conversation runs on the coach's plain text and tap-to-answer
/// buttons alone.
struct AdvisorPlainLanguage: AdvisorLanguage {
    var isAvailable: Bool { false }
    var note: String?
    func narrate(_ brief: AdvisorBrief) async -> String? { nil }
    func interpret(_ text: String) async -> AdvisorIntent? { nil }
    func answer(_ question: String, brief: AdvisorBrief) async -> String? { nil }
}

/// Keeps a model honest. A small on-device model is happy to round a chance
/// up, or to "work out" a number it was never given; the advisor quotes odds
/// the player will act on, so a reply is shown only if every number in it
/// appears in the facts it was written from.
///
/// Numbers are compared as *values*, not as strings, and read the way people
/// write them in every language the game ships in:
///
/// * digits of any script, full-width digits (`１２％`), vulgar fractions (`½`);
/// * grouping by comma, point, space, no-break / narrow no-break / thin space or
///   apostrophe (`45,000` `45.000` `45 000` `45’000`) and a decimal comma or point
///   (`12,5` `12.5`) — read from the shape of the number, not the device's locale, so a
///   reply in one language quoting facts in another still compares. A lone mark before
///   exactly three digits (`1.234`) is a thousands mark (the game prints amounts, never
///   three-place decimals); the decimal reading is accepted only if it is itself a fact;
/// * Japanese quantity words (`680万円` is 6,800,000; `1億2000万`, `3千5百`, `三十`);
/// * a scale word after a figure (`68 thousand`, `1,5 Millionen`, `3 тис.`);
/// * spelled-out figures of 20 and over, in any of the game's languages
///   (`sixty-eight thousand`, `achtundsechzigtausend`, `quatre-vingt-dix`,
///   `sessantotto`, `двадцять`) — and a spelled-out number of any size next to a
///   percent word (`twelve percent`, `zwölf Prozent`).
///
/// The percent sign (`73%`, `73 %`, `73 ％`, `73 pour cent`) carries no weight of
/// its own: the value is compared. Small spelled-out counts ("two jobs", `三つ`,
/// `一番`) are ordinary words and are not figures.
enum AdvisorGuard {
    /// One figure found in a text: its value, and — only where the text could be
    /// read two ways ("1.234": a thousand, or one and a bit) — the other reading.
    struct Figure: Hashable {
        let value: Decimal
        let alternative: Decimal?

        init(_ value: Decimal, alternative: Decimal? = nil) {
            self.value = value
            self.alternative = alternative
        }
    }

    // MARK: Reading

    /// The figures in `text`, in order.
    static func figures(in text: String) -> [Figure] {
        let chars = Array(normalised(text))
        var found: [Figure] = []
        var previousWord = ""
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if digit(c) != nil {
                let (figure, next) = arabic(chars, i, allowTail: true)
                found.append(figure)
                previousWord = ""
                i = next
            } else if let fraction = vulgarFraction(c) {
                found.append(Figure(fraction))
                i += 1
            } else if isJapaneseStart(chars, i) {
                let (value, next) = japanese(chars, from: i, seed: nil)
                if value >= 20 || percentFollows(chars, from: next) { found.append(Figure(value)) }
                previousWord = ""
                i = next
            } else if isWordCharacter(c) {
                let end = wordEnd(chars, from: i)
                let word = lowered(chars[i..<end])
                if numberPieces(word) != nil {
                    let (values, next) = spelledRun(chars, from: i, previousWord: previousWord)
                    found += values.map { Figure($0) }
                    previousWord = ""
                    i = next
                } else {
                    previousWord = word
                    i = end
                }
            } else {
                i += 1
            }
        }
        return found
    }

    /// The numbers in `text` as values: "68,000 $" and "68 000 $" and "68.000 $"
    /// (in a locale that groups with points) are all 68000, "12.5%" is 12.5, and
    /// "680万円" is 6800000.
    static func values(in text: String) -> Set<Decimal> {
        Set(figures(in: text).map(\.value))
    }

    /// The same numbers written canonically — "68000", "12.5", never a grouped or
    /// locale-formatted string — for callers that want text.
    static func numbers(in text: String) -> Set<String> {
        Set(values(in: text).map { NSDecimalNumber(decimal: $0).stringValue })
    }

    /// Whether every number in `text` is one of the facts' numbers. An ambiguous
    /// figure ("1.234") passes if either reading is a fact.
    static func isGrounded(_ text: String, in facts: [String]) -> Bool {
        let known = values(in: facts.joined(separator: "\n"))
        return figures(in: text).allSatisfy { figure in
            known.contains(figure.value) || figure.alternative.map(known.contains) == true
        }
    }

    /// A model's reply ready to show, or nil when it isn't fit: empty, rambling,
    /// or quoting numbers the facts don't hold.
    static func accept(_ reply: String, facts: [String], maxLength: Int = 700) -> String? {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= maxLength, isGrounded(text, in: facts) else { return nil }
        return text
    }

    // MARK: Characters

    /// Full-width ASCII (`１２％`, `，`, `．`) becomes plain ASCII — the effect of
    /// `applyingTransform(.fullwidthToHalfwidth)` on digits and punctuation, without
    /// its side effect of turning full-width katakana (`パーセント`) into half-width —
    /// and the Arabic decimal, thousands and percent signs become theirs.
    private static func normalised(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0xFF01...0xFF5E: scalars.append(Unicode.Scalar(scalar.value - 0xFEE0) ?? scalar)
            case 0x3000: scalars.append(" ")
            case 0x066B: scalars.append(".")
            case 0x066C: scalars.append(",")
            case 0x066A: scalars.append("%")
            default: scalars.append(scalar)
            }
        }
        return String(scalars)
    }

    /// The value of a decimal digit of any script (`7`, `٧`, `७`); nil for anything else.
    private static func digit(_ c: Character) -> Int? {
        guard let scalar = c.unicodeScalars.first, scalar.properties.numericType == .decimal,
              let value = scalar.properties.numericValue else { return nil }
        return Int(value)
    }

    private static func vulgarFraction(_ c: Character) -> Decimal? {
        guard c.unicodeScalars.count == 1, let scalar = c.unicodeScalars.first,
              (0x00BC...0x00BE).contains(scalar.value) || (0x2150...0x215F).contains(scalar.value) || scalar.value == 0x2189,
              let value = scalar.properties.numericValue, value > 0, value < 1 else { return nil }
        return Decimal(string: String(value))
    }

    /// What separates thousands besides a comma or a point: a space, a
    /// no-break or narrow no-break space, a thin or figure space, an apostrophe.
    private static let groupSeparators: Set<Character> = [" ", "\u{00A0}", "\u{202F}", "\u{2009}", "\u{2007}", "'", "\u{2019}", "\u{02BC}"]

    private static func isWordCharacter(_ c: Character) -> Bool {
        c.isLetter && !isJapaneseDigit(c)
    }

    private static func wordEnd(_ chars: [Character], from start: Int) -> Int {
        var end = start
        while end < chars.count {
            let c = chars[end]
            if isWordCharacter(c) { end += 1 }
            // An apostrophe inside a word: Ukrainian "п'ять", French "l'un".
            else if isApostrophe(c), end > start, end + 1 < chars.count, isWordCharacter(chars[end + 1]) { end += 1 }
            else { break }
        }
        return end
    }

    private static func isApostrophe(_ c: Character) -> Bool { c == "'" || c == "\u{2019}" || c == "\u{02BC}" }

    private static func lowered(_ slice: ArraySlice<Character>) -> String {
        String(slice).lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{02BC}", with: "'")
    }

    // MARK: Figures written with digits

    /// A number written with digits at `start`: its grouping and decimal marks
    /// resolved, a following scale word or Japanese quantity word applied.
    private static func arabic(_ chars: [Character], _ start: Int, allowTail: Bool) -> (Figure, Int) {
        var i = start
        var integer = ""
        while i < chars.count, let d = digit(chars[i]) { integer.append(String(d)); i += 1 }
        var lastGroup = integer.count      // digits in the latest integer run
        var fraction = ""
        var grouping: Character?           // the mark that groups thousands in this number
        var ambiguous: Character?          // a lone point/comma + exactly three digits

        while i + 1 < chars.count {
            let mark = chars[i]
            guard let first = digit(chars[i + 1]) else { break }
            var run = String(first)
            var j = i + 2
            while j < chars.count, let d = digit(chars[j]) { run.append(String(d)); j += 1 }

            if groupSeparators.contains(mark) {
                // A space (or apostrophe) grouping thousands: "45 000", never inside a fraction.
                guard fraction.isEmpty, ambiguous == nil, run.count == 3, lastGroup <= 3,
                      grouping == nil || grouping == mark else { break }
                grouping = mark
                integer += run
                lastGroup = 3
                i = j
            } else if mark == "," || mark == "." {
                guard fraction.isEmpty, ambiguous == nil else { break }
                if let grouping, grouping == mark {
                    guard run.count == 3 else { break }
                    integer += run
                    lastGroup = 3
                    i = j
                } else if grouping != nil {
                    // "45 000,50": after a group mark, this one is the decimal point.
                    fraction = run
                    i = j
                } else if run.count == 3, lastGroup <= 3, integer != "0", integer.first != "0" {
                    // "1,234" / "1.234": the mark repeated or followed by another mark
                    // is a grouping; alone, only the locale can say.
                    let followedByMark = j + 1 < chars.count && (chars[j] == "," || chars[j] == ".") && digit(chars[j + 1]) != nil
                    if followedByMark {
                        grouping = mark
                        integer += run
                        lastGroup = 3
                        i = j
                    } else {
                        ambiguous = mark
                        fraction = run
                        i = j
                    }
                } else {
                    fraction = run
                    i = j
                }
            } else {
                break
            }
        }

        let plain = Decimal(string: integer) ?? 0
        var value = plain
        var alternative: Decimal?
        if !fraction.isEmpty {
            let withFraction = Decimal(string: integer + "." + fraction) ?? plain
            if ambiguous != nil {
                // "1.234" / "1,234": the game's figures are amounts (45,000), whose thousands
                // marks look exactly like this, and it prints no three-place decimals — so a
                // lone mark before exactly three digits is a thousands mark. The decimal reading
                // is kept as the alternative, to be taken only if it is itself a fact.
                value = Decimal(string: integer + fraction) ?? plain
                alternative = withFraction
            } else {
                value = withFraction
            }
        }

        // A vulgar fraction right behind it: "1½".
        var next = i
        var look = i
        if look < chars.count, groupSeparators.contains(chars[look]), look + 1 < chars.count, vulgarFraction(chars[look + 1]) != nil { look += 1 }
        if look < chars.count, let fractionValue = vulgarFraction(chars[look]) {
            value += fractionValue
            alternative = alternative.map { $0 + fractionValue }
            next = look + 1
            return (Figure(value, alternative: alternative), next)
        }

        guard allowTail else { return (Figure(value, alternative: alternative), next) }

        // Japanese quantity words: 680万円, 1億2000万, 3千5百.
        if next < chars.count, jaUnit(chars[next]) != nil {
            let (total, end) = japanese(chars, from: next, seed: value)
            return (Figure(total), end)
        }
        // A scale word: 68 thousand, 1,5 Millionen, 4 тис., 68k.
        if let (multiplier, end) = scaleWord(chars, after: next) {
            return (Figure(value * multiplier, alternative: alternative.map { $0 * multiplier }), end)
        }
        return (Figure(value, alternative: alternative), next)
    }

    /// "thousand", "million", "k" … directly after a figure (one space allowed).
    private static func scaleWord(_ chars: [Character], after index: Int) -> (Decimal, Int)? {
        var start = index
        if start < chars.count, groupSeparators.contains(chars[start]), chars[start] != "'" { start += 1 }
        guard start < chars.count, chars[start].isLetter, !isJapaneseDigit(chars[start]) else { return nil }
        let end = wordEnd(chars, from: start)
        let word = lowered(chars[start..<end])
        if start == index, word == "k" { return (1_000, end) }
        guard let multiplier = scaleWords[word] else { return nil }
        // "тис." — swallow the abbreviation's point.
        let next = end < chars.count && chars[end] == "." && word.count <= 3 ? end + 1 : end
        return (multiplier, next)
    }

    private static let scaleWords: [String: Decimal] = {
        var words: [String: Decimal] = [:]
        for w in ["thousand", "tausend", "mille", "mila", "тисяча", "тисячі", "тисяч", "тис"] { words[w] = 1_000 }
        for w in ["million", "millions", "millionen", "milione", "milioni", "мільйон", "мільйони", "мільйонів", "млн", "mln"] { words[w] = 1_000_000 }
        for w in ["billion", "billions", "milliard", "milliards", "milliarde", "milliarden", "miliardo", "miliardi", "мільярд", "мільярди", "мільярдів", "млрд", "mld", "mrd"] { words[w] = 1_000_000_000 }
        return words
    }()

    // MARK: Japanese quantities

    private static let japaneseDigits: [Character: Int] = [
        "〇": 0, "零": 0, "一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
    ]

    private static func isJapaneseDigit(_ c: Character) -> Bool { japaneseDigits[c] != nil }

    /// 十 百 千 (small) and 万 億 兆 (large): the multiplier, and whether it closes a group.
    private static func jaUnit(_ c: Character) -> (value: Decimal, isLarge: Bool)? {
        switch c {
        case "十": return (10, false)
        case "百": return (100, false)
        case "千": return (1_000, false)
        case "万", "萬": return (10_000, true)
        case "億", "亿": return (100_000_000, true)
        case "兆": return (1_000_000_000_000, true)
        default: return nil
        }
    }

    /// A run of kanji numerals starts a figure at a digit, or at 十 / 百 when a numeral or
    /// unit follows ("十五", "百万") — never at 千 or a large unit, and not at the 百 of 百貨店
    /// or the 十 of 十分 ("千葉", "万が一" are not numbers either).
    private static func isJapaneseStart(_ chars: [Character], _ index: Int) -> Bool {
        let c = chars[index]
        if isJapaneseDigit(c) { return true }
        guard c == "十" || c == "百", index + 1 < chars.count else { return false }
        let next = chars[index + 1]
        return isJapaneseDigit(next) || jaUnit(next) != nil
    }

    /// A number token inside a Japanese quantity: digits (`680`, `1.5`) or kanji numerals
    /// (`六`, `二〇二五`, written positionally).
    private static func japaneseNumber(_ chars: [Character], _ index: Int) -> (Decimal, Int)? {
        guard index < chars.count else { return nil }
        if digit(chars[index]) != nil {
            let (figure, end) = arabic(chars, index, allowTail: false)
            return (figure.value, end)
        }
        var i = index
        var digits = ""
        while i < chars.count, let d = japaneseDigits[chars[i]] { digits.append(String(d)); i += 1 }
        return digits.isEmpty ? nil : (Decimal(string: digits) ?? 0, i)
    }

    /// The quantity written from `start`: 六百八十万 = 6,800,000, 3千5百 = 3,500,
    /// 1億2000万 = 120,000,000. `seed` is a figure already read (the `680` of `680万`).
    private static func japanese(_ chars: [Character], from start: Int, seed: Decimal?) -> (Decimal, Int) {
        var total: Decimal = 0
        var section: Decimal = 0
        var pending = seed
        var i = start
        if seed == nil, let (value, end) = japaneseNumber(chars, i) {
            pending = value
            i = end
        }
        while i < chars.count, let unit = jaUnit(chars[i]) {
            if unit.isLarge {
                section += pending ?? 0
                total += (section == 0 ? 1 : section) * unit.value
                section = 0
            } else {
                section += (pending ?? 1) * unit.value
            }
            pending = nil
            i += 1
            if let (value, end) = japaneseNumber(chars, i) {
                pending = value
                i = end
            }
        }
        return (total + section + (pending ?? 0), i)
    }

    // MARK: Percent words

    private static let percentMarkers = [
        "%", "percent", "per cent", "per cento", "prozent", "pourcent", "pour cent", "percento", // i18n:ignore percent words in several languages
        "процент", "відсот", "パーセント", "ぱーせんと", "割",
    ]

    /// Whether a percent sign or word comes next (after optional spaces).
    private static func percentFollows(_ chars: [Character], from index: Int) -> Bool {
        var i = index
        while i < chars.count, chars[i].isWhitespace || groupSeparators.contains(chars[i]) { i += 1 }
        guard i < chars.count else { return false }
        let ahead = lowered(chars[i..<min(chars.count, i + 10)])
        return percentMarkers.contains { ahead.hasPrefix($0) }
    }

    // MARK: Spelled-out numbers

    private enum Piece {
        case unit(Int)            // 1…19
        case tens(Int)            // 20…90
        case vingt                // French 20, which is also the 80 of "quatre-vingt"
        case hundred              // multiplies the unit before it, or is 100: hundred, hundert, cento
        case hundreds(Int)        // a word of its own: двісті = 200
        case scale(Int)           // thousand, million, billion
        case connector            // and, und, et — only meaningful inside a number
    }

    /// Words that are whole numbers in themselves.
    private static let wholeWords: [String: Piece] = {
        var words: [String: Piece] = [:]
        func add(_ list: [String], from first: Int, step: Int = 1, as make: (Int) -> Piece) {
            for (offset, word) in list.enumerated() { words[word] = make(first + offset * step) }
        }
        // English
        add(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen",
             "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"], from: 1, as: Piece.unit)
        add(["twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"], from: 20, step: 10, as: Piece.tens)
        words["hundred"] = .hundred; words["thousand"] = .scale(1_000); words["million"] = .scale(1_000_000); words["billion"] = .scale(1_000_000_000)
        words["and"] = .connector
        // German
        add(["ein", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn", "elf", "zwölf", "dreizehn",
             "vierzehn", "fünfzehn", "sechzehn", "siebzehn", "achtzehn", "neunzehn"], from: 1, as: Piece.unit)
        words["eine"] = .unit(1); words["einen"] = .unit(1); words["eins"] = .unit(1)
        add(["zwanzig", "dreißig", "vierzig", "fünfzig", "sechzig", "siebzig", "achtzig", "neunzig"], from: 20, step: 10, as: Piece.tens)
        words["dreissig"] = .tens(30)
        words["hundert"] = .hundred; words["tausend"] = .scale(1_000)
        words["millionen"] = .scale(1_000_000); words["milliarde"] = .scale(1_000_000_000); words["milliarden"] = .scale(1_000_000_000)
        words["und"] = .connector
        // French
        add(["un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf", "dix", "onze", "douze", "treize",
             "quatorze", "quinze", "seize"], from: 1, as: Piece.unit)
        words["une"] = .unit(1)
        words["vingt"] = .vingt; words["vingts"] = .vingt
        words["trente"] = .tens(30); words["quarante"] = .tens(40); words["cinquante"] = .tens(50); words["soixante"] = .tens(60)
        words["septante"] = .tens(70); words["huitante"] = .tens(80); words["nonante"] = .tens(90)
        words["cent"] = .hundred; words["cents"] = .hundred
        words["mille"] = .scale(1_000); words["millions"] = .scale(1_000_000)
        words["milliard"] = .scale(1_000_000_000); words["milliards"] = .scale(1_000_000_000)
        words["et"] = .connector
        // Italian
        add(["uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove", "dieci", "undici", "dodici", "tredici",
             "quattordici", "quindici", "sedici", "diciassette", "diciotto", "diciannove"], from: 1, as: Piece.unit)
        words["una"] = .unit(1); words["tré"] = .unit(3)
        add(["venti", "trenta", "quaranta", "cinquanta", "sessanta", "settanta", "ottanta", "novanta"], from: 20, step: 10, as: Piece.tens)
        words["cento"] = .hundred; words["mila"] = .scale(1_000)
        words["milione"] = .scale(1_000_000); words["milioni"] = .scale(1_000_000)
        words["miliardo"] = .scale(1_000_000_000); words["miliardi"] = .scale(1_000_000_000)
        // Ukrainian
        add(["один", "два", "три", "чотири", "п'ять", "шість", "сім", "вісім", "дев'ять", "десять", "одинадцять", "дванадцять", // i18n:ignore number words
             "тринадцять", "чотирнадцять", "п'ятнадцять", "шістнадцять", "сімнадцять", "вісімнадцять", "дев'ятнадцять"], from: 1, as: Piece.unit) // i18n:ignore number words
        words["одна"] = .unit(1); words["одне"] = .unit(1); words["дві"] = .unit(2)
        add(["двадцять", "тридцять", "сорок", "п'ятдесят", "шістдесят", "сімдесят", "вісімдесят", "дев'яносто"], from: 20, step: 10, as: Piece.tens) // i18n:ignore number words
        add(["сто", "двісті", "триста", "чотириста", "п'ятсот", "шістсот", "сімсот", "вісімсот", "дев'ятсот"], from: 100, step: 100, as: Piece.hundreds) // i18n:ignore number words
        for w in ["тисяча", "тисячі", "тисяч"] { words[w] = .scale(1_000) }
        for w in ["мільйон", "мільйони", "мільйонів"] { words[w] = .scale(1_000_000) }
        for w in ["мільярд", "мільярди", "мільярдів"] { words[w] = .scale(1_000_000_000) }
        return words
    }()

    /// Pieces that German and Italian glue into one word (`achtundsechzigtausend`,
    /// `sessantottomila`). Elided Italian tens (`sessant`) occur only inside a compound.
    private static let compoundPieces: [String: Piece] = {
        var pieces = wholeWords.filter { word, piece in
            if case .hundreds = piece { return false }
            return !["and", "et", "un", "une", "cents", "vingt", "vingts"].contains(word)
        }
        for (word, value) in ["vent": 20, "trent": 30, "quarant": 40, "cinquant": 50, "sessant": 60, "settant": 70, "ottant": 80, "novant": 90] {
            pieces[word] = .tens(value)
        }
        return pieces
    }()
    private static let compoundKeys: [String] = compoundPieces.keys.sorted { $0.count > $1.count }

    /// `word` as number pieces — itself, or a German / Italian compound that is made of
    /// number words from end to end. nil for any other word.
    private static func numberPieces(_ word: String) -> [Piece]? {
        if let piece = wholeWords[word] { return [piece] }
        guard word.count >= 5, word.count <= 40 else { return nil }
        func split(_ rest: Substring) -> [Piece]? {
            if rest.isEmpty { return [] }
            for key in compoundKeys where rest.hasPrefix(key) {
                if let tail = split(rest.dropFirst(key.count)), let piece = compoundPieces[key] { return [piece] + tail }
            }
            return nil
        }
        guard let pieces = split(Substring(word)), pieces.count >= 2 else { return nil }
        return pieces
    }

    /// The numbers spelled out from `start`: consecutive number words, joined by
    /// spaces or hyphens, form one number ("sixty-eight thousand five hundred").
    /// Only a figure of 20 or more — or any size before a percent word — counts;
    /// the small ones are ordinary words ("one of these", "two jobs", "un an").
    private static func spelledRun(_ chars: [Character], from start: Int, previousWord: String) -> ([Decimal], Int) {
        var builder = SpelledNumber()
        var numbers: [Int] = []
        var wordsSeen: [String] = []
        var i = start
        var end = start

        func close() {
            if let value = builder.finish() { numbers.append(value) }
            builder = SpelledNumber()
        }

        while i < chars.count, isWordCharacter(chars[i]) {
            let stop = wordEnd(chars, from: i)
            let word = lowered(chars[i..<stop])
            guard let pieces = numberPieces(word) else { break }
            let isConnector = pieces.allSatisfy { if case .connector = $0 { return true } else { return false } }
            // An "and" opens nothing, and one left hanging at the end belongs to the words after it.
            if isConnector && wordsSeen.isEmpty { return ([], stop) }
            for piece in pieces where !builder.feed(piece) {
                close()
                _ = builder.feed(piece)
            }
            if !isConnector {
                wordsSeen.append(word)
                end = stop
            }
            // Another number word may follow after a space or a hyphen.
            var next = stop
            while next < chars.count, " -\u{00A0}\u{2010}\u{2011}".contains(chars[next]) { next += 1 }
            guard next > stop, next < chars.count, isWordCharacter(chars[next]) else { break }
            i = next
        }
        close()

        // "per cent" / "pour cent" / "per cento" and the cents of money are not a hundred.
        let hundredWords: Set<String> = ["cent", "cents", "cento"]
        if wordsSeen.allSatisfy({ hundredWords.contains($0) }), wordsSeen.count == 1,
           wordsSeen[0] != "cento" || previousWord == "per" || previousWord == "pour" { return ([], end) }

        let percent = percentFollows(chars, from: end)
        let values = numbers.enumerated().compactMap { index, value -> Decimal? in
            value >= 20 || (index == numbers.count - 1 && percent) ? Decimal(value) : nil
        }
        return (values, end)
    }

    /// The number being assembled from spelled-out pieces.
    private struct SpelledNumber {
        private var total = 0
        private var current = 0
        private var lastScale = Int.max
        private var pieces = 0
        private var connectorSeen = false

        /// Adds a piece; false when it can't continue this number (the caller starts a new one).
        mutating func feed(_ piece: Piece) -> Bool {
            let rest = current % 100
            switch piece {
            case .connector:
                connectorSeen = pieces > 0
                return true
            case .unit(let v):
                if rest == 0 {
                    current += v
                } else if rest >= 20 && rest % 10 == 0 && (v < 10 || rest == 60 || rest == 80) {
                    current += v                        // twenty-one; French soixante-douze, quatre-vingt-dix
                } else if rest == 10 && v < 10 {
                    current += v                        // French: dix-sept
                } else {
                    return false
                }
            case .tens(let v):
                if rest == 0 {
                    current += v
                } else if (1...9).contains(rest) && connectorSeen {
                    current += v                        // German: einundzwanzig
                } else {
                    return false
                }
            case .vingt:
                if rest == 4 {
                    current += 76                       // quatre-vingt: 4 + 76 = 80
                } else if rest == 0 {
                    current += 20
                } else {
                    return false
                }
            case .hundred:
                if current == 0 {
                    current = 100
                } else if current < 10 {
                    current *= 100
                } else {
                    return false
                }
            case .hundreds(let v):
                guard current == 0 else { return false }
                current = v
            case .scale(let s):
                guard s < lastScale, current > 0 || (pieces == 0 && total == 0) else { return false }
                total += max(current, 1) * s
                current = 0
                lastScale = s
            }
            pieces += 1
            connectorSeen = false
            return true
        }

        /// The finished number, if any piece was fed.
        func finish() -> Int? { pieces > 0 ? total + current : nil }
    }
}

// MARK: - Roles, in the player's words

/// Finding a role from what the player typed, in the player's language. The coach's
/// own search reads English titles; this adds the titles as the player reads them
/// (`Job.displayBaseTitle`), so "Krankenpfleger" or "看護師" finds the nurse. Ids
/// (`Job.baseTitle`) stay English everywhere; only the matching looks at display names.
enum AdvisorRoles {
    /// The role as the player reads it.
    static func displayName(of family: AdvisorCoach.RoleFamily) -> String {
        family.entry.displayBaseTitle
    }

    /// The role with this id, as the player reads it (the id itself when there is no such role).
    static func displayName(of id: String) -> String {
        AdvisorCoach.family(id).map(displayName(of:)) ?? id
    }

    /// Lower-cased, without accents and with full-width letters narrowed, for matching.
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func words(of text: String) -> [String] {
        text.split { !$0.isLetter && !$0.isNumber }.map(String.init)
    }

    /// Whether `text` is nothing but the role's name — its English id or its display name.
    static func isName(of family: AdvisorCoach.RoleFamily, _ text: String) -> Bool {
        let typed = fold(text)
        return typed == fold(family.baseTitle) || typed == fold(displayName(of: family))
    }

    /// Whether the role is named in `text` — "I want to be a Licensed Practical Nurse".
    static func isNamed(_ family: AdvisorCoach.RoleFamily, in text: String) -> Bool {
        let typed = fold(text)
        return typed.contains(fold(family.baseTitle)) || typed.contains(fold(displayName(of: family)))
    }

    /// The roles a player's words point at, best match first: the coach's search of the
    /// English titles, and — when the game isn't in English — the displayed titles too.
    static func search(_ text: String, limit: Int = 6) -> [AdvisorCoach.RoleFamily] {
        let english = AdvisorCoach.search(text, limit: limit)
        guard L10n.language != .english else { return english }
        let query = fold(text)
        guard !query.isEmpty else { return english }
        let queryWords = words(of: query)

        let local = AdvisorCoach.families
            .compactMap { family -> (family: AdvisorCoach.RoleFamily, score: Int)? in
                let name = fold(displayName(of: family))
                // A role whose name is not translated yet is the English search's.
                guard !name.isEmpty, name != fold(family.baseTitle) else { return nil }
                var score = 0
                if name == query {
                    score = 20
                } else if query.contains(name) || (query.count >= 3 && name.contains(query)) {
                    score = 10
                } else {
                    let nameWords = words(of: name)
                    for word in queryWords where word.count >= 2 {
                        let hit = nameWords.contains { other in
                            other == word || (other.count >= 4 && word.count >= 4 && (other.hasPrefix(word) || word.hasPrefix(other)))
                        }
                        if hit { score += 4 }
                    }
                }
                return score > 0 ? (family, score) : nil
            }
            .sorted { ($0.score, $1.family.baseTitle) > ($1.score, $0.family.baseTitle) }
            .map(\.family)

        var merged = local
        for family in english where !merged.contains(where: { $0.baseTitle == family.baseTitle }) { merged.append(family) }
        return Array(merged.prefix(limit))
    }

    /// Words that carry no information in "I want to become a nurse", per language —
    /// enough to tell a bare job word from a described wish.
    private static let fillerWords: Set<String> = [
        // German
        "ich", "will", "möchte", "moechte", "werden", "ein", "eine", "einen", "als", "arbeiten", "gern", "gerne", "bin", "wäre",
        // French
        "je", "veux", "voudrais", "être", "etre", "devenir", "un", "une", "comme", "travailler", "aimerais",
        // Italian
        "vorrei", "voglio", "fare", "diventare", "essere", "come", "lavorare", "il", "lo", "la",
        // Ukrainian
        "я", "хочу", "бути", "стати", "працювати", "як", "хотів", "хотіла", "би",
        // Japanese
        "なりたい", "したい", "です", "ます", "たい", "という", "として", "の", "仕事",
    ]

    /// How many words of `text` say something. English uses the coach's own count; other
    /// languages are split with the system's word tokenizer (Japanese has no spaces).
    static func contentWordCount(_ text: String) -> Int {
        guard L10n.language != .english else { return AdvisorCoach.contentWords(text).count }
        var tokens: [String] = []
        #if canImport(NaturalLanguage)
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        #else
        tokens = words(of: text)
        #endif
        return tokens.map { $0.lowercased() }.filter { $0.count > 1 && !fillerWords.contains($0) }.count
    }
}

// MARK: - The conversation

struct AdvisorMessage: Identifiable, Equatable {
    enum Speaker: Equatable { case advisor, player }

    let id = UUID()
    let speaker: Speaker
    /// A small line above the text — "📅 Check-in · age 21".
    var heading: String?
    var text: String
    var cards: [AdvisorCard] = []
}

/// A tap-to-answer chip under the conversation.
struct AdvisorReply: Identifiable, Equatable {
    enum Kind: Equatable {
        case haveRole, undecided, changeGoal
        case browse(JobCategory), pickRole(String), backToFields
        case bestMoves
        /// Shows the odds, gates and levers behind the goal.
        case showPath
        /// Shows how the goal works in the real world.
        case realWorld
    }

    let label: String
    let kind: Kind

    var id: String { label }
}

/// The advisor's side of the chat, and the state it needs: what it has said,
/// what the player can answer with, and the flow that connects them.
///
///     first time      →  "Do you have a role in mind, or not decided yet?"
///     a role in mind  →  where the listings are, what skills (and degree,
///                        licences, years) it takes, and which activity builds each
///     not decided     →  different things to try; after a few moves, roles that
///                        use the skills gained
///     every move      →  a review of progress, with corrections
///
/// Every answer works by tapping a chip, so the game is complete without a
/// model. With one (`AdvisorLanguage.isAvailable`) the player can also type —
/// name a role, say they're undecided, or ask anything — and the coach's
/// facts come back in the advisor's own words.
@MainActor
final class AdvisorConversation: ObservableObject {
    @Published private(set) var messages: [AdvisorMessage] = []
    @Published private(set) var replies: [AdvisorReply] = []
    @Published private(set) var isThinking = false
    /// Whether the advisor is waiting for the player to name a role.
    @Published private(set) var choosing = false
    /// The first advisor message of the latest reply — where the view scrolls
    /// to, so a reply of several messages is read from its top.
    @Published private(set) var focusMessageID: UUID?

    private let player: Player
    private let language: AdvisorLanguage
    private var started = false
    /// Set when a reply begins; the first advisor message after it takes the focus.
    private var replyBegins = false

    /// How long the model gets before the plain text is shown instead.
    static let narrationTimeout: Duration = .seconds(12)
    static let answerTimeout: Duration = .seconds(25)

    init(player: Player, language: AdvisorLanguage) {
        self.player = player
        self.language = language
    }

    /// How the advisor speaks to this player (`AdvisorVoice`): read fresh each
    /// time, because a Real Life player grows out of the simple voice.
    private var voice: AdvisorVoice { AdvisorVoice(player) }

    /// A brief for the language layer, always addressed to the right reader.
    private func brief(_ topic: String, facts: [String], plain: String) -> AdvisorBrief {
        AdvisorBrief(topic: topic, facts: facts, plain: plain, voice: voice)
    }

    /// Whether the text box has a use: to name a role, or — with a model — to ask.
    var acceptsText: Bool { choosing || language.isAvailable }
    var languageNote: String? { language.isAvailable ? nil : language.note }

    // MARK: Opening

    /// Opens the conversation: the opening question the first time, a review of
    /// the year when one is waiting, else where things stand.
    func start() async {
        guard !started else { return }
        started = true
        language.prewarm()
        isThinking = true
        replyBegins = true
        defer { isThinking = false }

        let plan = player.advisorPlan
        switch plan.path {
        case .unasked:
            askOpeningQuestion(changing: false)
        case .exploring, .target:
            if plan.unreadCount > 0, let latest = plan.checkIns.last {
                await present(checkIn: latest)
                player.advisorPlan.unreadCount = 0
            } else {
                await presentStatus()
            }
            offerFollowUps()
        }
    }

    // MARK: Taking answers

    /// The player tapped a chip.
    func choose(_ reply: AdvisorReply) async {
        guard !isThinking else { return }
        isThinking = true
        defer { isThinking = false }
        say(player: reply.label)
        replies = []
        replyBegins = true

        switch reply.kind {
        case .haveRole, .backToFields:
            askForRole()
        case .undecided:
            await beginExploring()
        case .changeGoal:
            choosing = false
            askOpeningQuestion(changing: true)
        case .browse(let category):
            browse(category)
        case .pickRole(let title):
            await aim(at: title, lead: L("Great choice!"))
        case .bestMoves:
            await presentBestMoves()
            offerFollowUps()
        case .showPath:
            if let guide = currentGuide() { await presentPathway(guide, forced: true) }
            offerFollowUps()
        case .realWorld:
            if let guide = currentGuide(), let note = AdvisorRealWorld.note(for: guide.focus, player: player) { presentRealWorld(note) }
            offerFollowUps()
        }
    }

    /// The player picked a role from a card — a suggestion, say.
    func aim(at title: String) async {
        guard !isThinking, let family = AdvisorCoach.family(title) else { return }
        isThinking = true
        defer { isThinking = false }
        say(player: L("My goal: \(AdvisorRoles.displayName(of: family))"))
        replies = []
        replyBegins = true
        await aim(at: title, lead: L("Great choice!"))
    }

    /// The player typed something.
    func send(_ text: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        isThinking = true
        defer { isThinking = false }
        say(player: text)
        replies = []
        replyBegins = true

        if choosing {
            await resolveRole(from: text)
            return
        }
        guard language.isAvailable else {
            say(advisor: L("I can only take your answers from the buttons right now — pick one below."))
            offerFollowUps()
            return
        }
        let intent = await withTimeout(Self.narrationTimeout) { await self.language.interpret(text) } ?? .question
        switch intent {
        case .chooseRole(let title) where AdvisorCoach.family(title) != nil:
            await settle(on: title, typed: text)
        case .undecided:
            await beginExploring()
        default:
            await answer(text)
            offerFollowUps()
        }
    }

    // MARK: Flow

    private func askOpeningQuestion(changing: Bool) {
        if changing {
            say(advisor: L("Sure — let's pick a new direction. Do you have a job in mind now, or would you like to explore again?"))
        } else if voice == .simple {
            say(advisor: L("Hi, I'm your career advisor! 👋 Do you already know what job you'd like to do one day — or not yet? Either is fine."))
        } else {
            say(advisor: L("Hi, I'm your career advisor! 👋 Do you already have a job in mind that you'd like to work toward — or haven't you decided yet? Either answer is fine."))
        }
        replies = Self.openingChips
    }

    /// Chips that open every fresh path. Each label is a whole phrase, emoji included.
    private static var openingChips: [AdvisorReply] {
        [
            AdvisorReply(label: String(localized: "🎯 I have a role in mind", comment: "Advisor chat, quick-reply chip: the player already knows which job they want"),
                         kind: .haveRole),
            AdvisorReply(label: String(localized: "🤔 I haven't decided yet", comment: "Advisor chat, quick-reply chip: the player does not know yet what job they want"),
                         kind: .undecided),
        ]
    }

    private static var otherFieldsChip: AdvisorReply {
        AdvisorReply(label: String(localized: "← Other fields", comment: "Advisor chat, quick-reply chip: go back to the list of job fields"),
                     kind: .backToFields)
    }

    private static var fieldChips: [AdvisorReply] {
        AdvisorCoach.fields.map {
            AdvisorReply(label: "\(JobCategory.icon(for: $0)) \($0.displayName)", kind: .browse($0)) // i18n:ignore icon + display name
        }
    }

    private func askForRole() {
        choosing = true
        say(advisor: L("Which job are you thinking about? Type it below (like “nurse” or “game”), or pick a field to browse."))
        replies = Self.fieldChips
    }

    private func browse(_ category: JobCategory) {
        say(advisor: L("Here are the \(category.displayName) jobs. Which one sounds like you?"))
        replies = AdvisorCoach.families(in: category).map(roleChip) + [Self.otherFieldsChip]
    }

    private func roleChip(_ family: AdvisorCoach.RoleFamily) -> AdvisorReply {
        AdvisorReply(label: "\(family.icon) \(AdvisorRoles.displayName(of: family))", kind: .pickRole(family.baseTitle)) // i18n:ignore icon + display name
    }

    /// Reads a typed role: the model first when there is one, the plain search
    /// otherwise — and always the plain search as its backstop.
    private func resolveRole(from text: String) async {
        if language.isAvailable,
           case .chooseRole(let title)? = await withTimeout(Self.narrationTimeout, { await self.language.interpret(text) }),
           AdvisorCoach.family(title) != nil {
            await settle(on: title, typed: text)
            return
        }
        let matches = AdvisorRoles.search(text)
        if let only = matches.first, matches.count == 1 || AdvisorRoles.isName(of: only, text) {
            await aim(at: only.baseTitle, lead: L("Great choice!"))
        } else if matches.isEmpty {
            say(advisor: L("I couldn't find a job like that. Try another word (like “nurse”, “engineer” or “game”), or pick a field."))
            replies = Self.fieldChips
        } else {
            say(advisor: L("A few jobs fit that. Which one do you mean?"))
            replies = matches.map(roleChip) + [Self.otherFieldsChip]
        }
    }

    /// Acts on the model's reading of a typed role. It's trusted for anything
    /// descriptive ("I'd like to spend my days cooking in a restaurant"), but a
    /// word or two that fits several jobs — "nurse" fits four — is the
    /// player's to settle, not the model's to guess.
    private func settle(on title: String, typed text: String) async {
        let candidates = AdvisorRoles.search(text)
        let named = AdvisorCoach.family(title).map { AdvisorRoles.isNamed($0, in: text) } ?? false
        if AdvisorRoles.contentWordCount(text) <= 2, !named, candidates.count > 1, candidates.contains(where: { $0.baseTitle == title }) {
            say(advisor: L("A few jobs fit that. Which one do you mean?"))
            replies = candidates.map(roleChip) + [Self.otherFieldsChip]
            choosing = true
        } else {
            await aim(at: title, lead: L("Great choice!"))
        }
    }

    private func aim(at title: String, lead: String) async {
        choosing = false
        player.advisorPlan = AdvisorCoach.begin(.target(title), for: player)
        await presentGuide(title, lead: lead, full: true)
        offerFollowUps()
    }

    private func beginExploring() async {
        choosing = false
        player.advisorPlan = AdvisorCoach.begin(.exploring, for: player)
        await presentExploration(lead: L("No problem!"))
        offerFollowUps()
    }

    private func offerFollowUps() {
        let bestMoves = AdvisorReply(label: String(localized: "💡 Best moves right now", comment: "Advisor chat, quick-reply chip: ask for the most useful next moves"),
                                     kind: .bestMoves)
        let haveRole = Self.openingChips[0]
        switch player.advisorPlan.path {
        case .unasked:
            replies = Self.openingChips
        case .exploring:
            replies = [haveRole, bestMoves]
        case .target:
            var chips = [
                AdvisorReply(label: String(localized: "🔄 Change my goal", comment: "Advisor chat, quick-reply chip: pick a different target job"),
                             kind: .changeGoal),
                bestMoves,
            ]
            if let guide = currentGuide() {
                if let path = AdvisorPathway.pathway(for: guide, player: player) {
                    chips.append(AdvisorReply(
                        label: path.isNarrow
                            ? String(localized: "🧭 The narrow path", comment: "Advisor chat, quick-reply chip and heading: how few people reach a very competitive job")
                            : String(localized: "🧭 What decides it", comment: "Advisor chat, quick-reply chip: what decides whether the player gets the job"),
                        kind: .showPath))
                }
                if AdvisorRealWorld.note(for: guide.focus, player: player) != nil {
                    chips.append(AdvisorReply(
                        label: voice == .simple
                            ? String(localized: "🌍 How it really works", comment: "Advisor chat, quick-reply chip, simple wording: how the job works in the real world")
                            : String(localized: "🌍 How it works in real life", comment: "Advisor chat, quick-reply chip: how the job works in the real world"),
                        kind: .realWorld))
                }
            }
            replies = chips
        }
    }

    /// The guide for the role the player is working toward, if they've picked one.
    private func currentGuide() -> AdvisorCoach.RoleGuide? {
        player.advisorPlan.target.flatMap { AdvisorCoach.guide(for: $0, player: player) }
    }

    // MARK: Saying things

    /// Whole sentences set one after another: a space between them, except in
    /// Japanese, which doesn't use one.
    private static func sentences(_ parts: [String]) -> String {
        parts.filter { !$0.isEmpty }.joined(separator: L10n.language == .japanese ? "" : " ")
    }

    private func say(player text: String) {
        messages.append(AdvisorMessage(speaker: .player, text: text))
    }

    private func say(advisor text: String, heading: String? = nil, cards: [AdvisorCard] = []) {
        let message = AdvisorMessage(speaker: .advisor, heading: heading, text: text, cards: cards)
        messages.append(message)
        if replyBegins {
            focusMessageID = message.id
            replyBegins = false
        }
    }

    /// Says the brief in the model's words when it has any, else in the plain
    /// text. The cards under it are always the coach's own.
    private func say(_ brief: AdvisorBrief, heading: String? = nil, cards: [AdvisorCard] = []) async {
        var text = brief.plain
        if language.isAvailable,
           let reply = await withTimeout(Self.narrationTimeout, { await self.language.narrate(brief) }),
           let accepted = AdvisorGuard.accept(reply, facts: brief.facts + [brief.plain]) {
            text = accepted
        }
        say(advisor: text, heading: heading, cards: cards)
    }

    /// Runs `work` for at most `limit`; nil if it finishes empty-handed or runs out of time.
    private func withTimeout<T: Sendable>(_ limit: Duration, _ work: @escaping @Sendable () async -> T?) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await work() }
            group.addTask {
                try? await Task.sleep(for: limit)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    // MARK: Presenting

    /// Where the player stands on a role. `full` adds what a first look at a
    /// hard role needs — the narrow path and the real-world view — which the
    /// player can call up again with a chip.
    private func presentGuide(_ title: String, lead: String, full: Bool = false) async {
        guard let guide = AdvisorCoach.guide(for: title, player: player) else { return }
        var parts = [lead, AdvisorCoach.introduction(guide, player: player)]
        if guide.steps.contains(where: { ![.listing, .apply].contains($0.kind) }) {
            parts.append(L("Here's what would help most:"))
        }
        let brief = brief(
            // i18n:ignore instructions to the model
            "The player chose \(AdvisorRoles.displayName(of: title)) as their goal. Tell them where they stand and point them to the steps listed below your message.", // i18n:ignore instruction to the model
            facts: AdvisorCoach.facts(guide, player: player), plain: Self.sentences(parts))
        await say(brief, cards: guide.cards)
        if full {
            await presentPathway(guide, forced: false)
            if let note = AdvisorRealWorld.note(for: guide.focus, player: player) { presentRealWorld(note) }
        }
    }

    /// The odds behind the goal: how narrow it is, the gates, and the levers that
    /// move it. Shown unprompted for a narrow role; on request for any other.
    private func presentPathway(_ guide: AdvisorCoach.RoleGuide, forced: Bool) async {
        guard let path = AdvisorPathway.pathway(for: guide, player: player) else {
            if forced {
                if player.isSimplified {
                    say(advisor: L("There's no luck to worry about here: once you have the right school and enough years of work, the job is yours."))
                } else {
                    say(advisor: L("There's nothing to plan on this one yet — just keep going with school, activities and trying new things."))
                }
            }
            return
        }
        guard forced || path.isNarrow else { return }
        let brief = brief(
            // i18n:ignore instructions to the model
            "The player's goal is \(path.title). Explain how narrow the path is and what decides it; the gates and the levers are listed below your message.", // i18n:ignore instruction to the model
            facts: path.facts, plain: path.headline)
        let heading = String(localized: "🧭 The narrow path", comment: "Advisor chat, quick-reply chip and heading: how few people reach a very competitive job")
        await say(brief, heading: heading, cards: path.gates + path.leverCards)
    }

    /// The curated real-world view of the role, beside what the game does with it.
    private func presentRealWorld(_ note: AdvisorRealWorld.Note) {
        say(advisor: L("Here's how this works in real life — and how the game plays it."),
            heading: "🌍 " + note.title, cards: note.cards) // i18n:ignore emoji + the note's own title
    }

    private func presentExploration(lead: String) async {
        let plan = player.advisorPlan
        let moves = plan.moves(for: player)
        let left = max(0, AdvisorCoach.exploreMoves - moves)
        let ideas = AdvisorCoach.activityIdeas(for: player)
        var parts = [lead, L("The best way to find out what you like is to try different things.")]
        // The facts are for the model, which writes them up in the player's language.
        var facts = ["The player hasn't chosen a role yet and is exploring."] // i18n:ignore model fact
        if ideas.isEmpty {
            parts.append(L("Nothing new is open to you right now — look through the jobs list for something that catches your eye."))
        } else {
            parts.append(L("This year, try one of these:"))
            facts += ideas.map { "\($0.sport.label) builds \(Fmt.list($0.builds))" } // i18n:ignore model fact
        }
        if moves > 0 {
            parts.append(left > 0
                ? L("You're \(moves) moves in — \(Fmt.number(left)) more and I'll suggest jobs that fit you.")
                : L("Once you've tried a couple of different things, I'll suggest jobs that fit you."))
            facts.append("Moves spent exploring so far: \(moves). Moves left before suggestions: \(left).") // i18n:ignore model fact
        } else {
            parts.append(L("After a few moves, I'll suggest jobs that fit the skills you've built."))
            facts.append("After \(AdvisorCoach.exploreMoves) moves the advisor will suggest jobs that fit the skills gained.") // i18n:ignore model fact
        }
        let cards = ideas.map { idea in
            AdvisorCard(icon: idea.sport.pictogram, title: idea.sport.label,
                        detail: L("Builds \(Fmt.list(idea.builds))."),
                        actions: [AdvisorAction(label: L("Open Activities"), effect: .go(.activities(idea.sport.kind)))])
        }
        let brief = brief(
            // i18n:ignore instructions to the model
            "The player hasn't decided on a role. Encourage them to try different activities; the ideas are listed below your message.", // i18n:ignore instruction to the model
            facts: facts, plain: Self.sentences(parts))
        await say(brief, cards: cards)
    }

    /// Where things stand, when there's no new review to read.
    private func presentStatus() async {
        switch player.advisorPlan.path {
        case .target(let title):
            await presentGuide(title, lead: L("Here's where you stand."))
        case .exploring:
            if let latest = player.advisorPlan.checkIns.last, !latest.suggestions.isEmpty {
                await present(checkIn: latest)
            } else {
                await presentExploration(lead: L("Still exploring — good."))
            }
        case .unasked:
            break
        }
    }

    private func present(checkIn: AdvisorCheckIn) async {
        var cards = checkIn.progress.map(Self.progressCard)
        cards += checkIn.corrections
        for title in checkIn.suggestions {
            if let card = suggestionCard(title) { cards.append(card) }
        }
        // i18n:ignore the topic is an instruction to the model
        let topic = checkIn.role.map { "The advisor's yearly review of the player's progress toward \(AdvisorRoles.displayName(of: $0))." } // i18n:ignore instruction to the model
            ?? "The advisor's yearly review of the player's exploring." // i18n:ignore instruction to the model
        let brief = brief(topic, facts: AdvisorCoach.facts(checkIn), plain: checkIn.headline)
        await say(brief, heading: L("📅 Check-in · age \(checkIn.age)"), cards: cards)
    }

    private func suggestionCard(_ title: String) -> AdvisorCard? {
        guard let suggestion = AdvisorCoach.suggestion(title, player: player) else { return nil }
        var details = [L("Uses your \(Fmt.list(suggestion.matches)). Pays \(suggestion.pay).")]
        if !suggestion.needs.isEmpty { details.append(L("It takes \(Fmt.list(suggestion.needs)).")) }
        var actions = [AdvisorAction(label: L("Aim for this"), effect: .aim(title))]
        if player.availableJobs.contains(where: { $0.baseTitle == title }) {
            actions.append(AdvisorAction(label: L("See job listings"), effect: .go(.listing(title))))
        }
        return AdvisorCard(icon: suggestion.icon, title: AdvisorRoles.displayName(of: title), detail: Self.sentences(details), actions: actions)
    }

    /// A review's "🎯 Your chance went from 10% to 20%" line as a card: the
    /// leading pictogram becomes the icon.
    private static func progressCard(_ line: String) -> AdvisorCard {
        guard let first = line.first, !first.isASCII else { return AdvisorCard(icon: "•", detail: line) }
        return AdvisorCard(icon: String(first), detail: line.dropFirst().trimmingCharacters(in: .whitespaces))
    }

    private func presentBestMoves() async {
        let tips = CareerAdvisor.tips(for: player)
        guard !tips.isEmpty else {
            say(advisor: L("Right now, the best move is to keep going! Keep building your skills and check back next year. 👍"))
            return
        }
        let cards = tips.map { tip in
            AdvisorCard(icon: tip.icon, title: tip.title, detail: tip.detail,
                        actions: tip.destination.map { [AdvisorAction(label: $0.buttonLabel, effect: .go($0))] } ?? [])
        }
        say(advisor: L("Here are the moves that pay off most right now, best first:"), cards: cards)
    }

    private func answer(_ question: String) async {
        let brief = brief(
            "The player asked: \(question)", // i18n:ignore instruction to the model
            facts: AdvisorCoach.playerFacts(player), plain: "")
        if let reply = await withTimeout(Self.answerTimeout, { await self.language.answer(question, brief: brief) }) {
            say(advisor: reply)
        } else {
            say(advisor: L("Hmm, I'm not sure about that one. I can tell you about a job, a skill, or what to do next — try asking it that way."))
        }
    }
}
